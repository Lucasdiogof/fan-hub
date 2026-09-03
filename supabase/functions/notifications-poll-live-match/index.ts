// Push Notifications V1 — monitor de partida ao vivo (gol do Goiás + fim de
// jogo). Cole no dashboard do Supabase (nome "notifications-poll-live-match")
// e agende via pg_cron a cada 1 minuto (ver supabase/notifications_cron.sql).
// Roda em Deno.
//
// Sai cedo (sem chamar o Worker) sempre que não há nenhuma partida dentro da
// janela kickoff-5min..ends_at — a imensa maioria das execuções é isso.
// Cadência de 1 min bate com o cache de 60s do Worker: pedir mais rápido não
// traria dado mais novo.
//
// Fingerprint de gol é HEURÍSTICA, não garantia — a OneFootball não dá
// event_id. Ver comentário em `buildGoalDedupeKey` pros casos conhecidos que
// ela não cobre (VAR revertendo o evento, correção de minuto).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { resolveClubServerConfigByClubId } from '../_shared/club_server_config.ts';

const WORKER_BASE_URL = 'https://goias-app.lucasdiogo1234.workers.dev';
const PRE_KICKOFF_BUFFER_MINUTES = 5;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

interface FixtureEvent {
  minute: string;
  side: 'home' | 'away';
  type: 'goal' | 'yellow_card' | 'red_card' | 'substitution' | 'other';
  player: string | null;
  detail: string | null;
}

interface FixtureMatch {
  id: string;
  homeTeam: { id: number; name: string | null };
  awayTeam: { id: number; name: string | null };
  status: string;
  homeScore: number | null;
  awayScore: number | null;
}

interface FixtureResponse {
  match: FixtureMatch;
  events: FixtureEvent[];
}

/** "45+2" -> 4502, "90" -> 9000, "37" -> 3700 — ordenável, nunca muda pro
 * mesmo evento real (não depende de campo mutável como o nome do autor). */
function normalizedMinute(raw: string): number {
  const [base, stoppage] = raw.split('+');
  const baseNum = Number.parseInt(base, 10) || 0;
  const stoppageNum = stoppage ? Number.parseInt(stoppage, 10) || 0 : 0;
  return baseNum * 100 + stoppageNum;
}

/**
 * Reconstrói, a partir do array de eventos ATUAL (nunca incrementalmente),
 * a posição do gol entre os gols do clube ativo e o placar corrido até ali
 * — usando só os eventos de gol de AMBOS os lados, ordenados por minuto
 * normalizado com a posição no array como desempate estável. Enriquecer
 * `player` depois (null -> nome) não muda nenhum desses componentes, então
 * o dedupe_key não muda.
 *
 * `clubCode` entra no dedupe_key (M3.3) — `NOTIFICATION_DEDUPE_KEY_SCOPE_
 * BLOCKED`: `UNIQUE(event_type, dedupe_key)` ainda não inclui `club_id` de
 * verdade (M2.2B resolve isso na chave física), então embutir o código do
 * clube na STRING é a única coisa que evita 2 clubes reais colidindo nessa
 * chave hoje — nunca mais hardcoded `'goias'` pra qualquer clube.
 *
 * Limitações conhecidas e aceitas (não há event_id na fonte pra evitar
 * isso): (1) se a OneFootball reverter um gol por VAR removendo-o do
 * array, esta função nunca vê o evento de novo — a push já enviada não é
 * desfeita; (2) se o provedor corrigir o minuto de um gol já visto, o
 * evento corrigido pode gerar um dedupe_key novo e, em tese, uma push
 * duplicada — risco aceito, não resolvível sem id estável do provedor.
 */
function buildGoalDedupeKey(
  matchId: string,
  events: FixtureEvent[],
  activeClubSide: 'home' | 'away',
  targetIndex: number,
  clubCode: string,
): string {
  const goalEvents = events
    .map((event, index) => ({ event, index }))
    .filter(({ event }) => event.type === 'goal')
    .sort((a, b) => {
      const minuteDiff = normalizedMinute(a.event.minute) - normalizedMinute(b.event.minute);
      return minuteDiff !== 0 ? minuteDiff : a.index - b.index;
    });

  let homeGoals = 0;
  let awayGoals = 0;
  let activeClubOrdinal = 0;
  let scoreAfter = '';

  for (const { event, index } of goalEvents) {
    if (event.side === 'home') homeGoals += 1;
    else awayGoals += 1;
    if (event.side === activeClubSide) activeClubOrdinal += 1;

    if (index === targetIndex) {
      scoreAfter = `${homeGoals}-${awayGoals}`;
      break;
    }
  }

  const target = events[targetIndex];
  return `${matchId}|${clubCode}|${normalizedMinute(target.minute)}|${activeClubOrdinal}|${scoreAfter}`;
}

Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceRoleKey);

    const now = new Date();
    const bufferMs = PRE_KICKOFF_BUFFER_MINUTES * 60 * 1000;

    const { data: sessions, error: sessionsError } = await admin
      .from('match_monitor_sessions')
      .select('*')
      .in('status', ['scheduled', 'active']);

    if (sessionsError) {
      console.error('poll-live-match: falha ao ler sessões', sessionsError.message);
      return jsonResponse({ ok: false }, 500);
    }

    const dueSessions = (sessions ?? []).filter((session) => {
      const kickoff = new Date(session.kickoff).getTime();
      const endsAt = new Date(session.ends_at).getTime();
      return now.getTime() >= kickoff - bufferMs && now.getTime() <= endsAt;
    });

    if (dueSessions.length === 0) {
      // Timeout de segurança: sessões que passaram de `ends_at` sem nunca
      // terem sido encerradas por FULL_TIME.
      const overdue = (sessions ?? []).filter((s) => now.getTime() > new Date(s.ends_at).getTime());
      for (const session of overdue) {
        await admin
          .from('match_monitor_sessions')
          .update({ status: 'timed_out' })
          .eq('match_id', session.match_id)
          .eq('club_id', session.club_id);
        console.warn('match monitor timed out', session.match_id);
      }
      return jsonResponse({ ok: true, polled: 0 }, 200);
    }

    let anyEventCreated = false;

    for (const session of dueSessions) {
      // club_id nunca é opcional — sessão sem clube resolvível (código
      // desconhecido, nunca visto neste registry) é pulada com log, NUNCA
      // tratada como Goiás por omissão (NO_SERVER_CROSS_CLUB_FALLBACK).
      const clubConfig = resolveClubServerConfigByClubId(session.club_id);
      if (!clubConfig) {
        console.error('poll-live-match: club_id desconhecido, sessão pulada', session.match_id, session.club_id);
        continue;
      }

      if (session.status === 'scheduled') {
        await admin
          .from('match_monitor_sessions')
          .update({ status: 'active', started_at: now.toISOString() })
          .eq('match_id', session.match_id)
          .eq('club_id', session.club_id);
        console.log('match monitor started', session.match_id);
      }

      const rawId = session.match_id.startsWith('onef-')
        ? session.match_id.slice('onef-'.length)
        : session.match_id;
      const fixtureRes = await fetch(`${WORKER_BASE_URL}/api/football/fixtures/onef-${rawId}`);
      if (!fixtureRes.ok) {
        console.error('poll-live-match: falha ao consultar fixture', session.match_id, fixtureRes.status);
        continue;
      }
      const fixture = (await fixtureRes.json()) as FixtureResponse;
      const { match, events } = fixture;

      const activeClubSide: 'home' | 'away' | null =
        match.homeTeam.id === clubConfig.oneFootballTeamId
          ? 'home'
          : match.awayTeam.id === clubConfig.oneFootballTeamId
            ? 'away'
            : null;

      if (activeClubSide) {
        const activeClubGoalIndexes = events
          .map((event, index) => ({ event, index }))
          .filter(({ event }) => event.type === 'goal' && event.side === activeClubSide);

        await Promise.all(
          activeClubGoalIndexes.map(async ({ event, index }) => {
            const dedupeKey = buildGoalDedupeKey(session.match_id, events, activeClubSide, index, clubConfig.code);
            const goalPayload = {
              homeTeamName: match.homeTeam.name,
              awayTeamName: match.awayTeam.name,
              homeScore: match.homeScore,
              awayScore: match.awayScore,
              scorer: event.player,
              minute: event.minute,
              activeClubSide,
            };

            const { data: inserted, error } = await admin
              .from('notification_events')
              .upsert(
                {
                  match_id: session.match_id,
                  club_id: session.club_id,
                  event_type: 'goal',
                  dedupe_key: dedupeKey,
                  payload: goalPayload,
                },
                // M3.4: conflict tenant-aware (bridge ne_club_event_dedupe_uidx).
                { onConflict: 'club_id,event_type,dedupe_key', ignoreDuplicates: true },
              )
              .select('id');

            if (error) {
              console.error('poll-live-match: falha ao criar evento goal', error.message);
            } else if (inserted && inserted.length > 0) {
              anyEventCreated = true;
              console.log('goal detected', session.match_id, dedupeKey);
            } else {
              // Já existia (ex.: scorer preenchido depois) — atualiza só o
              // payload, sem tocar em status/detected_at.
              // M3.4: dedupe lookup também tenant-scoped (club_id + event_type
              // + dedupe_key = a bridge física ne_club_event_dedupe_uidx).
              await admin
                .from('notification_events')
                .update({ payload: goalPayload })
                .eq('club_id', session.club_id)
                .eq('event_type', 'goal')
                .eq('dedupe_key', dedupeKey);
            }
          }),
        );
      } else {
        console.warn('poll-live-match: não foi possível identificar o lado do clube ativo', session.match_id);
      }

      if (match.status === 'finished') {
        const { data: inserted, error } = await admin
          .from('notification_events')
          .upsert(
            {
              match_id: session.match_id,
              club_id: session.club_id,
              event_type: 'full_time',
              dedupe_key: `${session.match_id}|${clubConfig.code}`,
              payload: {
                homeTeamName: match.homeTeam.name,
                awayTeamName: match.awayTeam.name,
                homeScore: match.homeScore,
                awayScore: match.awayScore,
                activeClubSide,
              },
            },
            // M3.4: conflict tenant-aware (bridge ne_club_event_dedupe_uidx).
            { onConflict: 'club_id,event_type,dedupe_key', ignoreDuplicates: true },
          )
          .select('id');

        if (error) {
          console.error('poll-live-match: falha ao criar evento full_time', error.message);
        } else if (inserted && inserted.length > 0) {
          anyEventCreated = true;
          console.log('match finished', session.match_id);
        }

        await admin
          .from('match_monitor_sessions')
          .update({ status: 'finished', last_polled_at: now.toISOString() })
          .eq('match_id', session.match_id)
          .eq('club_id', session.club_id);
      } else {
        await admin
          .from('match_monitor_sessions')
          .update({
            last_polled_at: now.toISOString(),
            last_known_score: { homeScore: match.homeScore, awayScore: match.awayScore },
          })
          .eq('match_id', session.match_id)
          .eq('club_id', session.club_id);
      }
    }

    if (anyEventCreated) {
      const functionsBase = supabaseUrl.replace('.supabase.co', '.functions.supabase.co');
      await fetch(`${functionsBase}/notifications-dispatch`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${serviceRoleKey}`, 'Content-Type': 'application/json' },
      }).catch((err) => console.error('poll-live-match: falha ao chamar dispatch', err));
    }

    return jsonResponse({ ok: true, polled: dueSessions.length }, 200);
  } catch (err) {
    console.error('poll-live-match: erro inesperado', err instanceof Error ? err.message : String(err));
    return jsonResponse({ ok: false }, 500);
  }
});

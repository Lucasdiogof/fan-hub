// Push Notifications — monitor de partida ao vivo. Cole no dashboard do
// Supabase (nome "notifications-poll-live-match") e agende via pg_cron a
// cada 1 minuto (ver supabase/notifications_cron.sql). Roda em Deno.
//
// 6 eventos canônicos de partida, todos com placar (ver
// `_shared/live_match_events.ts` pra lógica pura/testável):
//   kickoff | goal | goal_against | half_time | second_half_started | full_time
//
// Sai cedo (sem chamar o Worker) sempre que não há nenhuma partida dentro da
// janela kickoff-5min..ends_at — a imensa maioria das execuções é isso.
// Cadência de 1 min bate com o cache de 60s do Worker: pedir mais rápido não
// traria dado mais novo.
//
// kickoff/half_time/second_half_started nunca são inferidos por horário ou
// minuto — só por TRANSIÇÃO REAL do status normalizado do provider
// (`match_monitor_sessions.last_provider_status`, ver
// `detectStatusTransitionEvents`). Fingerprint de gol é HEURÍSTICA, não
// garantia — a OneFootball não dá event_id (ver comentário em
// `buildGoalDedupeKey` pros casos conhecidos que ela não cobre: VAR
// revertendo o evento, correção de minuto).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { resolveClubServerConfigByClubId, type ClubServerConfig } from '../_shared/club_server_config.ts';
import {
  buildGoalDedupeKey,
  confirmedGoalIndexes,
  detectGoals,
  goalContext,
  detectStatusTransitionEvents,
  type FixtureEvent,
} from '../_shared/live_match_events.ts';
import { rejectUnlessServiceCaller } from '../_shared/service_caller_auth.ts';

const PRE_KICKOFF_BUFFER_MINUTES = 5;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
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

/** Insere o evento (upsert com dedupe por constraint física
 * `ne_club_event_dedupe_uidx`) — mesmo helper pros 6 tipos, nunca 6 blocos
 * de I/O repetidos. `ignoreDuplicates: true` faz o segundo poll pro mesmo
 * evento virar no-op silencioso (o retorno vazio de `.select('id')` é
 * como sabemos que já existia). */
async function upsertNotificationEvent(
  admin: ReturnType<typeof createClient>,
  params: { matchId: string; clubId: string; eventType: string; dedupeKey: string; payload: Record<string, unknown> },
): Promise<boolean> {
  const { data: inserted, error } = await admin
    .from('notification_events')
    .upsert(
      {
        match_id: params.matchId,
        club_id: params.clubId,
        event_type: params.eventType,
        dedupe_key: params.dedupeKey,
        payload: params.payload,
      },
      { onConflict: 'club_id,event_type,dedupe_key', ignoreDuplicates: true },
    )
    .select('id');

  if (error) {
    console.error(`poll-live-match: falha ao criar evento ${params.eventType}`, error.message);
    return false;
  }
  return (inserted ?? []).length > 0;
}

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Só cron/outras functions (service_role). A anon key é pública e o
    // gateway a aceita — ver _shared/service_caller_auth.ts.
    const denied = await rejectUnlessServiceCaller(req, supabaseUrl, serviceRoleKey);
    if (denied) return denied;

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
      const clubConfig: ClubServerConfig | undefined = resolveClubServerConfigByClubId(session.club_id);
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
      const fixtureRes = await fetch(`${clubConfig.workerBaseUrl}/api/football/fixtures/onef-${rawId}`);
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

      const scorePayload = {
        homeTeamName: match.homeTeam.name,
        awayTeamName: match.awayTeam.name,
        homeScore: match.homeScore,
        awayScore: match.awayScore,
        activeClubSide,
      };

      // 1) Transições de status reais — kickoff / intervalo / 2º tempo.
      // Nunca por horário (`currentTime >= scheduledKickoff`) nem por
      // minuto (`minute >= 46`) — só a mudança de status entre este poll
      // e o anterior, persistida em `last_provider_status`.
      const previousStatus: string | null = session.last_provider_status ?? null;
      const statusEvents = detectStatusTransitionEvents(previousStatus, match.status);
      for (const eventType of statusEvents) {
        const created = await upsertNotificationEvent(admin, {
          matchId: session.match_id,
          clubId: session.club_id,
          eventType,
          dedupeKey: `${session.match_id}|${clubConfig.code}`,
          payload: scorePayload,
        });
        if (created) {
          anyEventCreated = true;
          console.log(`${eventType} detected`, session.match_id);
        }
      }

      // 2) Gols — GOAL_FOR e GOAL_AGAINST, generalizado por
      // `activeClubSide` (nunca hardcoded pro time da casa).
      if (activeClubSide) {
        // Só gols que o placar confirma (ver `confirmedGoalIndexes`): um
        // lance listado pela fonte sem o placar subir — ex.: pênalti
        // defendido registrado como gol por alguns minutos — não notifica.
        const confirmed = confirmedGoalIndexes(events, match.homeScore, match.awayScore);
        const goals = detectGoals(events, activeClubSide).filter(({ index }) => confirmed.has(index));
        await Promise.all(
          goals.map(async ({ event, index, eventType }) => {
            const dedupeKey = buildGoalDedupeKey({
              matchId: session.match_id,
              events,
              targetIndex: index,
              clubCode: clubConfig.code,
              confirmed,
            });
            // Placar DAQUELE gol, nunca o placar atual do jogo — antes, o
            // update abaixo reescrevia o gol dos 20' com o 3x0 final.
            const at = goalContext(events, index, confirmed);
            const goalPayload = {
              ...scorePayload,
              homeScore: at.homeScore,
              awayScore: at.awayScore,
              scorer: event.player,
              minute: event.minute,
            };

            const created = await upsertNotificationEvent(admin, {
              matchId: session.match_id,
              clubId: session.club_id,
              eventType,
              dedupeKey,
              payload: goalPayload,
            });
            if (created) {
              anyEventCreated = true;
              console.log(`${eventType} detected`, session.match_id, dedupeKey);
            } else {
              // Já existia (ex.: scorer preenchido depois) — atualiza só o
              // payload, sem tocar em status/detected_at.
              await admin
                .from('notification_events')
                .update({ payload: goalPayload })
                .eq('club_id', session.club_id)
                .eq('event_type', eventType)
                .eq('dedupe_key', dedupeKey);
            }
          }),
        );
      } else {
        console.warn('poll-live-match: não foi possível identificar o lado do clube ativo', session.match_id);
      }

      // 3) Fim de jogo + encerramento da sessão.
      if (match.status === 'finished') {
        const created = await upsertNotificationEvent(admin, {
          matchId: session.match_id,
          clubId: session.club_id,
          eventType: 'full_time',
          dedupeKey: `${session.match_id}|${clubConfig.code}`,
          payload: scorePayload,
        });
        if (created) {
          anyEventCreated = true;
          console.log('match finished', session.match_id);
        }

        await admin
          .from('match_monitor_sessions')
          .update({ status: 'finished', last_polled_at: now.toISOString(), last_provider_status: match.status })
          .eq('match_id', session.match_id)
          .eq('club_id', session.club_id);
      } else {
        await admin
          .from('match_monitor_sessions')
          .update({
            last_polled_at: now.toISOString(),
            last_known_score: { homeScore: match.homeScore, awayScore: match.awayScore },
            last_provider_status: match.status,
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

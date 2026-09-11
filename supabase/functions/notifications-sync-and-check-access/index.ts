// Push Notifications V1 — descoberta de partida + checagem do marco de 48h.
// Cole no dashboard do Supabase (Edge Functions > Create a new function,
// nome "notifications-sync-and-check-access") e agende via pg_cron a cada
// 30 minutos (ver supabase/notifications_cron.sql). Roda em Deno.
//
// Responsabilidade única, POR CLUBE registrado (M3.3: itera
// `SERVER_CLUB_REGISTRY`, hoje só 1 — nunca hardcoded pro Goiás):
// descobrir o próximo jogo (mesma rota pública genérica que o app usa),
// manter `match_monitor_sessions` em dia, e — se `now() >= kickoff - 48h` e
// ainda não existe evento pra essa partida — criar o evento
// `match_access_open` (a mensagem certa por sócio/não-sócio é decidida
// depois, no dispatch, nunca aqui). Cada linha gravada carrega `club_id`
// explícito, nunca depende do DEFAULT Goiás da M2.2A.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { SERVER_CLUB_REGISTRY, type ClubServerConfig } from '../_shared/club_server_config.ts';

const ACCESS_WINDOW_HOURS = 48;
const MONITOR_HORIZON_DAYS = 10;
const MONITOR_DURATION_HOURS = 3;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

interface NextMatch {
  id: string;
  kickoff: string | null;
  homeTeam: { name: string | null };
  awayTeam: { name: string | null };
}

/** Processa a descoberta+sessão+evento de UM clube — nunca assume qual
 * clube é, recebe `clubConfig` resolvido do registry. Retorna um resumo
 * pra agregação no handler principal (nunca lança — erros por clube ficam
 * isolados, um clube com falha no upstream não impede os demais). */
async function syncClub(
  admin: ReturnType<typeof createClient>,
  clubConfig: ClubServerConfig,
): Promise<{ club: string; ok: boolean; matchId?: string; createdEvent: boolean; reason?: string }> {
  const teamRes = await fetch(`${clubConfig.workerBaseUrl}/api/football/team/${clubConfig.oneFootballTeamPath}`);
  if (!teamRes.ok) {
    console.error('sync-and-check-access: falha ao consultar /team', clubConfig.code, teamRes.status);
    return { club: clubConfig.code, ok: false, createdEvent: false, reason: 'upstream_error' };
  }
  const team = (await teamRes.json()) as { nextMatch: NextMatch | null };
  const nextMatch = team.nextMatch;

  if (!nextMatch || !nextMatch.kickoff) {
    return { club: clubConfig.code, ok: true, createdEvent: false, reason: 'no_upcoming_match' };
  }

  // `kickoff` vem "local nu" do Brasil (sem offset) — mesma convenção que
  // o resto do pipeline já usa (ver `InternalMatch.kickoff`). Trata como
  // UTC-3 fixo, igual o Worker já faz.
  const kickoff = new Date(`${nextMatch.kickoff}-03:00`);
  if (Number.isNaN(kickoff.getTime())) {
    console.error('sync-and-check-access: kickoff inválido', clubConfig.code, nextMatch.kickoff);
    return { club: clubConfig.code, ok: false, createdEvent: false, reason: 'invalid_kickoff' };
  }

  const now = new Date();
  const horizonMs = MONITOR_HORIZON_DAYS * 24 * 60 * 60 * 1000;
  if (kickoff.getTime() - now.getTime() <= horizonMs) {
    const endsAt = new Date(kickoff.getTime() + MONITOR_DURATION_HOURS * 60 * 60 * 1000);
    // Nunca sobrescreve uma sessão que já está active/finished/timed_out —
    // só garante que uma sessão 'scheduled' existe com o kickoff em dia.
    // Filtra também por club_id: 2 clubes reais poderiam, em tese, ter o
    // MESMO match_id vindo de fontes diferentes — nunca confiar só em
    // match_id pra decidir "já existe" (mesmo espírito da trava de
    // KEY_SCOPE da M3.2).
    const { data: existing } = await admin
      .from('match_monitor_sessions')
      .select('match_id,status')
      .eq('match_id', nextMatch.id)
      .eq('club_id', clubConfig.canonicalClubId)
      .maybeSingle();

    if (!existing) {
      await admin.from('match_monitor_sessions').insert({
        match_id: nextMatch.id,
        club_id: clubConfig.canonicalClubId,
        kickoff: kickoff.toISOString(),
        home_team_name: nextMatch.homeTeam.name ?? '',
        away_team_name: nextMatch.awayTeam.name ?? '',
        status: 'scheduled',
        ends_at: endsAt.toISOString(),
      });
    } else if (existing.status === 'scheduled') {
      await admin
        .from('match_monitor_sessions')
        .update({
          kickoff: kickoff.toISOString(),
          home_team_name: nextMatch.homeTeam.name ?? '',
          away_team_name: nextMatch.awayTeam.name ?? '',
          ends_at: endsAt.toISOString(),
        })
        .eq('match_id', nextMatch.id)
        .eq('club_id', clubConfig.canonicalClubId);
    }
  }

  const opensAt = new Date(kickoff.getTime() - ACCESS_WINDOW_HOURS * 60 * 60 * 1000);
  let createdEvent = false;
  if (now >= opensAt) {
    const { data: inserted, error } = await admin
      .from('notification_events')
      .upsert(
        {
          match_id: nextMatch.id,
          club_id: clubConfig.canonicalClubId,
          event_type: 'match_access_open',
          dedupe_key: `${nextMatch.id}|${clubConfig.code}`,
          payload: {
            homeTeamName: nextMatch.homeTeam.name,
            awayTeamName: nextMatch.awayTeam.name,
          },
        },
        // M3.4: conflict tenant-aware (bridge ne_club_event_dedupe_uidx).
        { onConflict: 'club_id,event_type,dedupe_key', ignoreDuplicates: true },
      )
      .select('id');

    if (error) {
      console.error('sync-and-check-access: falha ao criar evento match_access_open', clubConfig.code, error.message);
    } else if (inserted && inserted.length > 0) {
      createdEvent = true;
      console.log('match access event detected', clubConfig.code, nextMatch.id);
    }
  }

  return { club: clubConfig.code, ok: true, matchId: nextMatch.id, createdEvent };
}

Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Itera o registry inteiro — hoje só 1 clube, mas nunca hardcoded qual.
    const results = await Promise.all(SERVER_CLUB_REGISTRY.map((clubConfig) => syncClub(admin, clubConfig)));

    const anyEventCreated = results.some((r) => r.createdEvent);
    if (anyEventCreated) {
      // Dispara o envio já — não espera o próximo tick do Cron de
      // segurança, pra latência menor.
      const functionsBase = supabaseUrl.replace('.supabase.co', '.functions.supabase.co');
      await fetch(`${functionsBase}/notifications-dispatch`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${serviceRoleKey}`, 'Content-Type': 'application/json' },
      }).catch((err) => console.error('sync-and-check-access: falha ao chamar dispatch', err));
    }

    return jsonResponse({ ok: results.every((r) => r.ok), results }, 200);
  } catch (err) {
    console.error('sync-and-check-access: erro inesperado', err instanceof Error ? err.message : String(err));
    return jsonResponse({ ok: false }, 500);
  }
});

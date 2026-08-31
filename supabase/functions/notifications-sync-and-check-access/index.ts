// Push Notifications V1 — descoberta de partida + checagem do marco de 48h.
// Cole no dashboard do Supabase (Edge Functions > Create a new function,
// nome "notifications-sync-and-check-access") e agende via pg_cron a cada
// 30 minutos (ver supabase/notifications_cron.sql). Roda em Deno.
//
// Responsabilidade única: descobrir o próximo jogo do Goiás (mesma rota
// pública que o app usa), manter `match_monitor_sessions` em dia, e — se
// `now() >= kickoff - 48h` e ainda não existe evento pra essa partida —
// criar o evento `match_access_open` (a mensagem certa por sócio/não-sócio
// é decidida depois, no dispatch, nunca aqui).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const WORKER_BASE_URL = 'https://goias-app.lucasdiogo1234.workers.dev';
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

Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceRoleKey);

    const teamRes = await fetch(`${WORKER_BASE_URL}/api/football/team/goias`);
    if (!teamRes.ok) {
      console.error('sync-and-check-access: falha ao consultar /team/goias', teamRes.status);
      return jsonResponse({ ok: false, reason: 'upstream_error' }, 502);
    }
    const team = (await teamRes.json()) as { nextMatch: NextMatch | null };
    const nextMatch = team.nextMatch;

    if (!nextMatch || !nextMatch.kickoff) {
      return jsonResponse({ ok: true, reason: 'no_upcoming_match' }, 200);
    }

    // `kickoff` vem "local nu" do Brasil (sem offset) — mesma convenção que
    // o resto do pipeline já usa (ver `InternalMatch.kickoff`). Trata como
    // UTC-3 fixo, igual o Worker já faz.
    const kickoff = new Date(`${nextMatch.kickoff}-03:00`);
    if (Number.isNaN(kickoff.getTime())) {
      console.error('sync-and-check-access: kickoff inválido', nextMatch.kickoff);
      return jsonResponse({ ok: false, reason: 'invalid_kickoff' }, 200);
    }

    const now = new Date();
    const horizonMs = MONITOR_HORIZON_DAYS * 24 * 60 * 60 * 1000;
    if (kickoff.getTime() - now.getTime() <= horizonMs) {
      const endsAt = new Date(kickoff.getTime() + MONITOR_DURATION_HOURS * 60 * 60 * 1000);
      // Nunca sobrescreve uma sessão que já está active/finished/timed_out —
      // só garante que uma sessão 'scheduled' existe com o kickoff em dia.
      const { data: existing } = await admin
        .from('match_monitor_sessions')
        .select('match_id,status')
        .eq('match_id', nextMatch.id)
        .maybeSingle();

      if (!existing) {
        await admin.from('match_monitor_sessions').insert({
          match_id: nextMatch.id,
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
          .eq('match_id', nextMatch.id);
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
            event_type: 'match_access_open',
            dedupe_key: nextMatch.id,
            payload: {
              homeTeamName: nextMatch.homeTeam.name,
              awayTeamName: nextMatch.awayTeam.name,
            },
          },
          { onConflict: 'event_type,dedupe_key', ignoreDuplicates: true },
        )
        .select('id');

      if (error) {
        console.error('sync-and-check-access: falha ao criar evento match_access_open', error.message);
      } else if (inserted && inserted.length > 0) {
        createdEvent = true;
        console.log('match access event detected', nextMatch.id);
      }
    }

    if (createdEvent) {
      // Dispara o envio já — não espera o próximo tick do Cron de
      // segurança, pra latência menor.
      const functionsBase = supabaseUrl.replace('.supabase.co', '.functions.supabase.co');
      await fetch(`${functionsBase}/notifications-dispatch`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${serviceRoleKey}`, 'Content-Type': 'application/json' },
      }).catch((err) => console.error('sync-and-check-access: falha ao chamar dispatch', err));
    }

    return jsonResponse({ ok: true, matchId: nextMatch.id, createdEvent }, 200);
  } catch (err) {
    console.error('sync-and-check-access: erro inesperado', err instanceof Error ? err.message : String(err));
    return jsonResponse({ ok: false }, 500);
  }
});

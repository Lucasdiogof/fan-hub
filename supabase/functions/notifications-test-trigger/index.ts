// M-live — gatilho de teste MANUAL pra dev/staging. Cole no dashboard do
// Supabase (nome "notifications-test-trigger") só se/quando quiser testar
// os 6 eventos de partida sem esperar um jogo real. NUNCA agendado via
// cron, NUNCA chamado pelo app — é uma ferramenta de operador, chamada à
// mão (curl/Postman) contra um device de teste.
//
// SEGURANÇA (leia antes de deployar em qualquer projeto):
//  - Exige o header `x-test-secret` batendo com o secret
//    `NOTIFICATIONS_TEST_SECRET` (Supabase Dashboard > Edge Functions >
//    Secrets). Sem esse secret configurado no projeto, a função SEMPRE
//    responde 403 — nunca "aberta por omissão".
//  - Nunca insere um evento de partida REAL: `match_id` é sempre prefixado
//    com `test-`, nunca aceita um match_id de partida real (evita poluir
//    dados de produção ou confundir com evento genuíno).
//  - dedupe_key inclui um `dedupeSuffix` (default: timestamp em ms) — cada
//    chamada gera um evento novo por padrão; pra testar o dedupe de
//    propósito (garantir que 2 chamadas iguais NÃO duplicam push), passe o
//    MESMO `dedupeSuffix` duas vezes.
//  - Reaproveita o dispatch real (`notifications-dispatch`) — testa a
//    cadeia inteira (preferências, canal, FCM), não um mock separado.
//
// Corpo esperado (JSON):
// {
//   "clubCode": "goias" | "bragantino",
//   "eventType": "kickoff" | "goal" | "goal_against" | "half_time" | "second_half_started" | "full_time",
//   "homeTeamName": "Goiás", "awayTeamName": "Vila Nova",
//   "homeScore": 1, "awayScore": 0,
//   "scorer": "Fulano", "minute": "23",     // só relevante pra goal/goal_against
//   "matchId": "smoke1",                     // opcional — vira "test-smoke1"
//   "dedupeSuffix": "1"                      // opcional — default Date.now()
// }
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { resolveClubServerConfigByCode } from '../_shared/club_server_config.ts';

const VALID_EVENT_TYPES = ['kickoff', 'goal', 'goal_against', 'half_time', 'second_half_started', 'full_time'];

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

Deno.serve(async (req) => {
  try {
    const testSecret = Deno.env.get('NOTIFICATIONS_TEST_SECRET');
    if (!testSecret) {
      // Fail-closed: secret nunca configurado neste projeto = função
      // sempre recusa, mesmo que alguém descubra a URL.
      return jsonResponse({ ok: false, error: 'NOTIFICATIONS_TEST_SECRET não configurado neste projeto' }, 403);
    }
    if (req.headers.get('x-test-secret') !== testSecret) {
      return jsonResponse({ ok: false, error: 'x-test-secret inválido' }, 403);
    }

    const body = await req.json();
    const clubConfig = resolveClubServerConfigByCode(body.clubCode);
    if (!clubConfig) {
      return jsonResponse({ ok: false, error: `clubCode desconhecido: ${body.clubCode}` }, 400);
    }
    if (!VALID_EVENT_TYPES.includes(body.eventType)) {
      return jsonResponse({ ok: false, error: `eventType inválido: ${body.eventType}` }, 400);
    }

    const rawMatchId = String(body.matchId ?? 'smoke').replace(/[^a-zA-Z0-9_-]/g, '');
    const matchId = `test-${rawMatchId}`;
    const dedupeSuffix = String(body.dedupeSuffix ?? Date.now());

    const homeTeamName = body.homeTeamName ?? clubConfig.shortName;
    const awayTeamName = body.awayTeamName ?? 'Adversário de Teste';
    const activeClubSide: 'home' | 'away' = body.activeClubSide === 'away' ? 'away' : 'home';

    const payload = {
      homeTeamName,
      awayTeamName,
      homeScore: body.homeScore ?? 0,
      awayScore: body.awayScore ?? 0,
      activeClubSide,
      scorer: body.scorer ?? null,
      minute: body.minute ?? null,
    };

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceRoleKey);

    const { data: inserted, error } = await admin
      .from('notification_events')
      .upsert(
        {
          match_id: matchId,
          club_id: clubConfig.canonicalClubId,
          event_type: body.eventType,
          dedupe_key: `${matchId}|${clubConfig.code}|${dedupeSuffix}`,
          payload,
        },
        { onConflict: 'club_id,event_type,dedupe_key', ignoreDuplicates: true },
      )
      .select('id');

    if (error) {
      return jsonResponse({ ok: false, error: error.message }, 500);
    }

    const created = (inserted ?? []).length > 0;

    // Dispara o dispatch já, igual o fluxo real faz — testa a cadeia
    // inteira (preferências -> canal -> FCM), não um mock isolado.
    const functionsBase = supabaseUrl.replace('.supabase.co', '.functions.supabase.co');
    await fetch(`${functionsBase}/notifications-dispatch`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${serviceRoleKey}`, 'Content-Type': 'application/json' },
    }).catch((err) => console.error('test-trigger: falha ao chamar dispatch', err));

    return jsonResponse(
      {
        ok: true,
        created,
        note: created
          ? 'Evento de teste criado e dispatch disparado.'
          : 'Já existia um evento com essa dedupe_key (mesmo clubCode+eventType+matchId+dedupeSuffix) — nenhum novo criado, prova que o dedupe funciona. Troque dedupeSuffix pra forçar um evento novo.',
        matchId,
        dedupeKey: `${matchId}|${clubConfig.code}|${dedupeSuffix}`,
      },
      200,
    );
  } catch (err) {
    return jsonResponse({ ok: false, error: err instanceof Error ? err.message : String(err) }, 500);
  }
});

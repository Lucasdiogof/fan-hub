// Push Notifications V1 — envio via FCM HTTP v1. Cole no dashboard do
// Supabase (nome "notifications-dispatch"). Chamada diretamente pelas outras
// duas funções assim que criam um evento novo, e também agendada via
// pg_cron a cada 5 min como rede de segurança (retoma evento que ficou
// 'processing' por queda no meio do envio — ver supabase/notifications_cron.sql).
// Roda em Deno.
//
// Segredos necessários (Supabase Dashboard > Edge Functions > Secrets):
// FCM_SERVICE_ACCOUNT_JSON = conteúdo integral do JSON da service account
// (Firebase Console > Configurações do projeto > Contas de serviço > Gerar
// nova chave privada). Nunca vai pro Flutter, só existe aqui.
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { GoogleAuth } from 'npm:google-auth-library@9';

const STUCK_PROCESSING_MINUTES = 5;
const SEND_CONCURRENCY = 30;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

interface NotificationEvent {
  id: string;
  match_id: string;
  event_type: 'match_access_open' | 'goal' | 'full_time';
  payload: Record<string, unknown>;
}

interface TokenRow {
  id: string;
  user_id: string;
  fcm_token: string;
  platform: 'android' | 'ios';
}

/** Título/body/rota de acordo com o tipo de evento. Pra `match_access_open`,
 * a mensagem depende do status de sócio de CADA destinatário (decidido no
 * momento do envio — nunca client-side), então essa função recebe também se
 * o destinatário é sócio ativo agora. */
function buildMessage(
  event: NotificationEvent,
  opts: { isActiveMember: boolean },
): { title: string; body: string; type: string } {
  const p = event.payload as {
    homeTeamName?: string;
    awayTeamName?: string;
    homeScore?: number;
    awayScore?: number;
    goiasSide?: 'home' | 'away';
  };

  switch (event.event_type) {
    case 'match_access_open': {
      const opponent =
        p.homeTeamName === 'Goiás' ? p.awayTeamName : p.homeTeamName === undefined ? '' : p.homeTeamName;
      if (opts.isActiveMember) {
        return {
          type: 'checkin',
          title: 'Check-in aberto',
          body: `O check-in pra ${opponent ?? 'o próximo jogo'} já está disponível.`,
        };
      }
      return {
        type: 'tickets',
        title: 'Ingressos disponíveis',
        body: `Os ingressos pra ${opponent ?? 'o próximo jogo'} já estão à venda.`,
      };
    }
    case 'goal': {
      return {
        type: 'goal',
        title: 'GOOOOOOL DO GOIÁS! ⚽💚',
        body: `${p.homeTeamName} ${p.homeScore} x ${p.awayScore} ${p.awayTeamName}`,
      };
    }
    case 'full_time': {
      const home = p.homeScore ?? 0;
      const away = p.awayScore ?? 0;
      const goiasScore = p.goiasSide === 'home' ? home : away;
      const opponentScore = p.goiasSide === 'home' ? away : home;
      const title = goiasScore > opponentScore ? 'VITÓRIA DO VERDÃO! 💚' : 'Fim de jogo';
      const suffix = goiasScore > opponentScore ? ' Fim de jogo!' : '.';
      return {
        type: 'full_time',
        title,
        body: `${p.homeTeamName} ${home} x ${away} ${p.awayTeamName}${suffix}`,
      };
    }
  }
}

async function fetchRecipientTokens(
  admin: SupabaseClient,
  eventType: NotificationEvent['event_type'],
): Promise<TokenRow[]> {
  const prefColumn = eventType === 'match_access_open' ? 'tickets_enabled' : 'matches_enabled';

  const { data: optedOutUserIds } = await admin
    .from('user_notification_preferences')
    .select('user_id')
    .eq(prefColumn, false);
  const excluded = new Set((optedOutUserIds ?? []).map((r) => r.user_id as string));

  const { data: tokens, error } = await admin
    .from('user_notification_tokens')
    .select('id,user_id,fcm_token,platform')
    .eq('is_active', true);

  if (error) {
    console.error('dispatch: falha ao ler tokens', error.message);
    return [];
  }

  return (tokens ?? []).filter((t) => !excluded.has(t.user_id));
}

async function isActiveMember(admin: SupabaseClient, userId: string): Promise<boolean> {
  const { count } = await admin
    .from('supporter_memberships')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gt('expires_at', new Date().toISOString());
  return (count ?? 0) > 0;
}

async function getAccessToken(): Promise<{ token: string; projectId: string }> {
  const raw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')!;
  const credentials = JSON.parse(raw);
  const auth = new GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const client = await auth.getClient();
  const accessTokenResponse = await client.getAccessToken();
  return { token: accessTokenResponse.token as string, projectId: credentials.project_id as string };
}

async function sendFcm(
  projectId: string,
  accessToken: string,
  token: string,
  message: { title: string; body: string; type: string },
  matchId: string,
): Promise<{ ok: boolean; invalidToken: boolean; error?: string }> {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: message.title, body: message.body },
        data: { type: message.type, matchId },
        android: { priority: 'high', notification: { channel_id: 'goias_matches' } },
        apns: { payload: { aps: { sound: 'default' } } },
      },
    }),
  });

  if (res.ok) return { ok: true, invalidToken: false };

  const errBody = await res.text();
  const invalidToken = res.status === 404 || errBody.includes('UNREGISTERED') || errBody.includes('NOT_FOUND');
  return { ok: false, invalidToken, error: errBody.slice(0, 300) };
}

async function processEvent(admin: SupabaseClient, event: NotificationEvent, fcmAuth: { token: string; projectId: string }) {
  const recipients = await fetchRecipientTokens(admin, event.event_type);

  if (recipients.length > 0) {
    const rows = recipients.map((r) => ({ event_id: event.id, token_id: r.id }));
    await admin.from('notification_deliveries').upsert(rows, { onConflict: 'event_id,token_id', ignoreDuplicates: true });
  }

  const { data: pending, error } = await admin
    .from('notification_deliveries')
    .select('id,token_id,user_notification_tokens(id,user_id,fcm_token,platform)')
    .eq('event_id', event.id)
    .eq('status', 'pending');

  if (error) {
    console.error('dispatch: falha ao ler deliveries pendentes', event.id, error.message);
    return;
  }

  const memberCache = new Map<string, boolean>();

  const queue = [...(pending ?? [])];
  const worker = async () => {
    while (queue.length > 0) {
      const delivery = queue.shift();
      if (!delivery) break;
      const tokenRow = delivery.user_notification_tokens as unknown as TokenRow | null;
      if (!tokenRow) {
        await admin.from('notification_deliveries').update({ status: 'failed', error: 'token ausente', attempted_at: new Date().toISOString() }).eq('id', delivery.id);
        continue;
      }

      let isMember = false;
      if (event.event_type === 'match_access_open') {
        if (!memberCache.has(tokenRow.user_id)) {
          memberCache.set(tokenRow.user_id, await isActiveMember(admin, tokenRow.user_id));
        }
        isMember = memberCache.get(tokenRow.user_id)!;
      }

      const message = buildMessage(event, { isActiveMember: isMember });
      const result = await sendFcm(fcmAuth.projectId, fcmAuth.token, tokenRow.fcm_token, message, event.match_id);

      if (result.ok) {
        await admin
          .from('notification_deliveries')
          .update({ status: 'sent', attempted_at: new Date().toISOString() })
          .eq('id', delivery.id);
      } else if (result.invalidToken) {
        await admin.from('user_notification_tokens').update({ is_active: false }).eq('id', tokenRow.id);
        await admin
          .from('notification_deliveries')
          .update({ status: 'invalid_token', error: result.error, attempted_at: new Date().toISOString() })
          .eq('id', delivery.id);
      } else {
        console.error('dispatch: falha de envio FCM', tokenRow.id, result.error);
        await admin
          .from('notification_deliveries')
          .update({ status: 'failed', error: result.error, attempted_at: new Date().toISOString() })
          .eq('id', delivery.id);
      }
    }
  };

  await Promise.all(Array.from({ length: SEND_CONCURRENCY }, () => worker()));

  const { count: stillPending } = await admin
    .from('notification_deliveries')
    .select('id', { count: 'exact', head: true })
    .eq('event_id', event.id)
    .eq('status', 'pending');

  if ((stillPending ?? 0) === 0) {
    await admin
      .from('notification_events')
      .update({ status: 'completed', completed_at: new Date().toISOString() })
      .eq('id', event.id);
    console.log(event.event_type === 'goal' ? 'goal notification dispatched' : `${event.event_type} notification dispatched`, event.match_id);
  }
}

Deno.serve(async (_req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Reivindica pending -> processing atomicamente (evita duas execuções
    // sobrepostas processando o mesmo evento). Também repega processing
    // travado há mais de STUCK_PROCESSING_MINUTES (queda no meio do envio).
    const stuckSince = new Date(Date.now() - STUCK_PROCESSING_MINUTES * 60 * 1000).toISOString();

    const { data: pendingEvents } = await admin
      .from('notification_events')
      .update({ status: 'processing' })
      .eq('status', 'pending')
      .select('id,match_id,event_type,payload');

    const { data: stuckEvents } = await admin
      .from('notification_events')
      .select('id,match_id,event_type,payload,detected_at')
      .eq('status', 'processing')
      .lt('detected_at', stuckSince);

    // `stuckEvents` pode incluir uma linha que acabou de ser reivindicada
    // acima (se `detected_at` já era antigo antes de virar 'processing'
    // agora) — dedupe por id pra nunca processar o mesmo evento 2x nesta
    // mesma execução.
    const claimedIds = new Set((pendingEvents ?? []).map((e) => e.id));
    const eventsToProcess = [
      ...(pendingEvents ?? []),
      ...(stuckEvents ?? []).filter((e) => !claimedIds.has(e.id)),
    ] as NotificationEvent[];

    if (eventsToProcess.length === 0) {
      return jsonResponse({ ok: true, processed: 0 }, 200);
    }

    const fcmAuth = await getAccessToken();

    for (const event of eventsToProcess) {
      await processEvent(admin, event, fcmAuth);
    }

    return jsonResponse({ ok: true, processed: eventsToProcess.length }, 200);
  } catch (err) {
    console.error('dispatch: erro inesperado', err instanceof Error ? err.message : String(err));
    return jsonResponse({ ok: false }, 500);
  }
});

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
import { resolveClubServerConfigByClubId, type ClubServerConfig } from '../_shared/club_server_config.ts';
import { buildNotificationMessage, type NotificationEventPayload } from '../_shared/notification_message_builder.ts';
import {
  fetchRecipientTokens as resolveRecipientTokens,
  isActiveMember as resolveIsActiveMember,
  type RecipientEligibilitySource,
  type TokenRow,
} from '../_shared/recipient_eligibility.ts';
import { isInvalidTokenError } from '../_shared/fcm_dispatch_rules.ts';
import { rejectUnlessServiceCaller } from '../_shared/service_caller_auth.ts';

const STUCK_PROCESSING_MINUTES = 5;
const SEND_CONCURRENCY = 30;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

type LiveMatchEventType = 'kickoff' | 'goal' | 'goal_against' | 'half_time' | 'second_half_started' | 'full_time';

interface NotificationEvent {
  id: string;
  match_id: string;
  club_id: string;
  event_type: 'match_access_open' | LiveMatchEventType;
  payload: Record<string, unknown>;
}

const LIVE_MATCH_EVENT_TYPES: readonly LiveMatchEventType[] = [
  'kickoff',
  'goal',
  'goal_against',
  'half_time',
  'second_half_started',
  'full_time',
];

/** Canal Android por tipo: os 6 eventos de partida ao vivo (kickoff, gol a
 * favor/contra, intervalo, 2º tempo, fim) usam um canal PRÓPRIO com
 * `IMPORTANCE_HIGH`/heads-up (`live_match_alerts_v2` — versionado porque o
 * Android nunca atualiza a importância de um canal já criado no aparelho
 * com `IMPORTANCE_DEFAULT`, só um channel_id novo resolve isso). Ingressos/
 * check-in (`match_access_open`) continua no canal antigo
 * (`${code}_matches`, `IMPORTANCE_DEFAULT`) — categoria diferente, nunca
 * precisou de heads-up. Ver `android/app/src/main/kotlin/.../MainActivity.kt`
 * pro canal correspondente sendo criado no client. */
function channelIdFor(eventType: NotificationEvent['event_type'], clubConfig: ClubServerConfig): string {
  return LIVE_MATCH_EVENT_TYPES.includes(eventType as LiveMatchEventType)
    ? `${clubConfig.code}_live_match_alerts_v2`
    : `${clubConfig.code}_matches`;
}

// Adapta o `SupabaseClient` real pra `RecipientEligibilitySource` — a
// LÓGICA de elegibilidade (quem recebe o quê, sem vazar entre clubes) vive
// em `_shared/recipient_eligibility.ts`, testável sem Deno. Aqui é só o
// fiozinho de I/O real.
function supabaseRecipientEligibilitySource(admin: SupabaseClient): RecipientEligibilitySource {
  return {
    async explicitlyEligibleUserIds(clubId, prefColumns) {
      // Todas as colunas pedidas precisam ser `true` (AND) — pros 6 eventos
      // de partida isso é sempre [master, sub-coluna do evento], nunca só
      // uma. Cada `.eq()` encadeado é mais uma condição AND na mesma query.
      let query = admin.from('user_notification_preferences').select('user_id').eq('club_id', clubId);
      for (const column of prefColumns) {
        query = query.eq(column, true);
      }
      const { data, error } = await query;
      if (error) {
        console.error('dispatch: falha ao ler preferências (clube)', error.message);
        return [];
      }
      return (data ?? []).map((r) => r.user_id as string);
    },
    async usersWithAnyPreferenceRow() {
      const { data, error } = await admin
        .from('user_notification_preferences')
        .select('user_id');
      if (error) {
        console.error('dispatch: falha ao ler preferências (qualquer clube)', error.message);
        return [];
      }
      return (data ?? []).map((r) => r.user_id as string);
    },
    async activeTokensForClub(clubId) {
      const { data, error } = await admin
        .from('user_notification_tokens')
        .select('id,user_id,fcm_token,platform,club_id')
        .eq('is_active', true)
        .eq('club_id', clubId);
      if (error) {
        console.error('dispatch: falha ao ler tokens', error.message);
        return [];
      }
      return (data ?? []) as TokenRow[];
    },
    async activeMembershipCount(userId, clubId) {
      const { count } = await admin
        .from('supporter_memberships')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('club_id', clubId)
        .gt('expires_at', new Date().toISOString());
      return count ?? 0;
    },
  };
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
  clubConfig: ClubServerConfig,
  eventType: NotificationEvent['event_type'],
): Promise<{ ok: boolean; invalidToken: boolean; error?: string }> {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: message.title, body: message.body },
        data: { type: message.type, matchId },
        // Canal por clube E por categoria (M-live) — os 6 eventos de
        // partida ao vivo vão no canal HIGH/heads-up, nunca no mesmo canal
        // DEFAULT de ingressos/check-in. Nunca 2 clubes reais
        // compartilhando o mesmo canal Android.
        android: { priority: 'high', notification: { channel_id: channelIdFor(eventType, clubConfig) } },
        apns: { payload: { aps: { sound: 'default' } } },
      },
    }),
  });

  if (res.ok) return { ok: true, invalidToken: false };

  const errBody = await res.text();
  return { ok: false, invalidToken: isInvalidTokenError(res.status, errBody), error: errBody.slice(0, 300) };
}

async function processEvent(admin: SupabaseClient, event: NotificationEvent, fcmAuth: { token: string; projectId: string }) {
  // club_id nunca é opcional — evento com club_id desconhecido (nunca visto
  // no registry) é marcado failed com observability, NUNCA tratado como
  // Goiás por omissão (NO_SERVER_CROSS_CLUB_FALLBACK).
  const clubConfig = resolveClubServerConfigByClubId(event.club_id);
  if (!clubConfig) {
    console.error('dispatch: club_id desconhecido, evento pulado', event.id, event.club_id);
    return;
  }

  const eligibilitySource = supabaseRecipientEligibilitySource(admin);
  const recipients = await resolveRecipientTokens(eligibilitySource, event.club_id, event.event_type);

  if (recipients.length > 0) {
    const rows = recipients.map((r) => ({ event_id: event.id, token_id: r.id }));
    await admin.from('notification_deliveries').upsert(rows, { onConflict: 'event_id,token_id', ignoreDuplicates: true });
  }

  const { data: pending, error } = await admin
    .from('notification_deliveries')
    .select('id,token_id,user_notification_tokens(id,user_id,fcm_token,platform,club_id)')
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
          memberCache.set(
            tokenRow.user_id,
            await resolveIsActiveMember(eligibilitySource, tokenRow.user_id, event.club_id),
          );
        }
        isMember = memberCache.get(tokenRow.user_id)!;
      }

      const message = buildNotificationMessage(
        event.event_type,
        event.payload as NotificationEventPayload,
        clubConfig,
        { isActiveMember: isMember },
      );
      const result = await sendFcm(fcmAuth.projectId, fcmAuth.token, tokenRow.fcm_token, message, event.match_id, clubConfig, event.event_type);

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

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Só cron/outras functions (service_role). A anon key é pública e o
    // gateway a aceita — ver _shared/service_caller_auth.ts.
    const denied = await rejectUnlessServiceCaller(req, supabaseUrl, serviceRoleKey);
    if (denied) return denied;

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Reivindica pending -> processing atomicamente (evita duas execuções
    // sobrepostas processando o mesmo evento). Também repega processing
    // travado há mais de STUCK_PROCESSING_MINUTES (queda no meio do envio).
    const stuckSince = new Date(Date.now() - STUCK_PROCESSING_MINUTES * 60 * 1000).toISOString();

    const { data: pendingEvents } = await admin
      .from('notification_events')
      .update({ status: 'processing' })
      .eq('status', 'pending')
      .select('id,match_id,club_id,event_type,payload');

    const { data: stuckEvents } = await admin
      .from('notification_events')
      .select('id,match_id,club_id,event_type,payload,detected_at')
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

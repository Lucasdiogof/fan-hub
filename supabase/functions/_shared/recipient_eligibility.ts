// M4.1/M4.1c — quem recebe o evento de um clube, sem vazar pra outro.
//
// Extraído de `notifications-dispatch/index.ts` pra virar testável sem
// Deno (0 import Deno-specific, 0 SupabaseClient direto — ver
// `vitest.config.mts` e o mesmo padrão de `notification_message_builder.ts`).
// A Edge Function real fornece um `RecipientEligibilitySource` que fala
// com o Postgres de verdade; o teste fornece um fake com dados fabricados.
//
// Duas camadas complementares, nenhuma sozinha basta:
//
// 1) ELEGIBILIDADE POR USUÁRIO (M4.1, achado da auditoria M4 round 1):
//    `fetchRecipientTokens` buscava TODO token ativo do sistema, sem
//    nenhum filtro de clube. Corrigido usando `user_notification_
//    preferences` (já club_id-scoped desde a M3.2): um usuário é candidato
//    ao evento de `clubId` se (a) tem uma linha de preferência PARA ESSE
//    clube com a coluna habilitada, OU (b) nunca configurou preferência em
//    NENHUM clube ainda (usuário legado/novo — o default continua
//    "notificar", só que agora só pro(s) clube(s) que ele nunca tocou
//    nada). Um usuário que já configurou preferência só de OUTRO clube
//    nunca é elegível por omissão pra este.
//
// 2) ENTREGA POR TOKEN (M4.1c, achado da auditoria M4.1b — a camada acima
//    sozinha NÃO bastava): um token FCM representa uma instalação de app
//    (Firebase App ID = package/bundle id) — nunca compartilhado entre 2
//    apps diferentes. Desde a M4.1c, `user_notification_tokens.club_id`
//    grava isso explicitamente (NOT NULL, sem DEFAULT — toda escrita nova
//    manda o valor). `activeTokensForClub(clubId)` já filtra por clube na
//    origem — a interseção real é "usuário elegível" (camada 1) × "token
//    é deste clube" (camada 2, aplicada aqui na própria query).
//    `fcm_token` continua a única chave de unicidade (nunca (club_id,
//    fcm_token) — o mesmo token físico nunca duplica).

// M-live: preferências granulares por tipo de evento de partida ao vivo,
// atrás de um master toggle único ("Jogos ao vivo"). `match_access_open`
// (Ingressos/Check-in) continua uma categoria totalmente separada, nunca
// misturada com as 6 de partida (mesmo motivo de sempre: são conceitos
// diferentes pro usuário).
export type NotificationEventType =
  | 'match_access_open'
  | 'kickoff'
  | 'goal'
  | 'goal_against'
  | 'half_time'
  | 'second_half_started'
  | 'full_time';

export interface TokenRow {
  id: string;
  user_id: string;
  fcm_token: string;
  platform: 'android' | 'ios';
  club_id: string;
}

export type PreferenceColumn =
  | 'tickets_enabled'
  | 'live_matches_enabled'
  | 'kickoff_enabled'
  | 'goal_for_enabled'
  | 'goal_against_enabled'
  | 'half_time_enabled'
  | 'second_half_started_enabled'
  | 'full_time_enabled';

const LIVE_MATCH_EVENT_COLUMN: Record<Exclude<NotificationEventType, 'match_access_open'>, PreferenceColumn> = {
  kickoff: 'kickoff_enabled',
  goal: 'goal_for_enabled',
  goal_against: 'goal_against_enabled',
  half_time: 'half_time_enabled',
  second_half_started: 'second_half_started_enabled',
  full_time: 'full_time_enabled',
};

/**
 * Colunas que TODAS precisam estar `true` pra um usuário ser elegível a
 * este `eventType`. `match_access_open` só depende de `tickets_enabled`
 * (categoria própria). Qualquer um dos 6 eventos de partida depende do
 * master toggle `live_matches_enabled` E do sub-toggle específico do
 * evento — se o master estiver OFF, nenhum dos 6 é enviado, mesmo que o
 * sub-toggle individual esteja ON (regra explícita do produto).
 */
export function preferenceColumnsFor(eventType: NotificationEventType): PreferenceColumn[] {
  if (eventType === 'match_access_open') return ['tickets_enabled'];
  return ['live_matches_enabled', LIVE_MATCH_EVENT_COLUMN[eventType]];
}

export interface RecipientEligibilitySource {
  /** user_ids com uma linha de preferência PARA este club_id, com TODAS as `prefColumns` habilitadas (AND). */
  explicitlyEligibleUserIds(clubId: string, prefColumns: PreferenceColumn[]): Promise<string[]>;
  /** user_ids com QUALQUER linha de preferência, em qualquer clube. */
  usersWithAnyPreferenceRow(): Promise<string[]>;
  /** tokens ativos JÁ FILTRADOS por club_id — nunca todos os tokens do sistema. */
  activeTokensForClub(clubId: string): Promise<TokenRow[]>;
  /** quantas assinaturas ativas esse usuário tem NESTE clube. */
  activeMembershipCount(userId: string, clubId: string): Promise<number>;
}

export async function fetchRecipientTokens(
  source: RecipientEligibilitySource,
  clubId: string,
  eventType: NotificationEventType,
): Promise<TokenRow[]> {
  const prefColumns = preferenceColumnsFor(eventType);

  const [explicitlyEligibleIds, anyPreferenceIds, tokens] = await Promise.all([
    source.explicitlyEligibleUserIds(clubId, prefColumns),
    source.usersWithAnyPreferenceRow(),
    source.activeTokensForClub(clubId),
  ]);

  const explicitlyEligible = new Set(explicitlyEligibleIds);
  const hasAnyPreferenceRow = new Set(anyPreferenceIds);

  return tokens.filter(
    (t) => explicitlyEligible.has(t.user_id) || !hasAnyPreferenceRow.has(t.user_id),
  );
}

export async function isActiveMember(
  source: RecipientEligibilitySource,
  userId: string,
  clubId: string,
): Promise<boolean> {
  return (await source.activeMembershipCount(userId, clubId)) > 0;
}

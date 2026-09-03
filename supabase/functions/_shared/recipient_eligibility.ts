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

export type NotificationEventType = 'match_access_open' | 'goal' | 'full_time';

export interface TokenRow {
  id: string;
  user_id: string;
  fcm_token: string;
  platform: 'android' | 'ios';
  club_id: string;
}

export type PreferenceColumn = 'matches_enabled' | 'tickets_enabled';

export function preferenceColumnFor(eventType: NotificationEventType): PreferenceColumn {
  return eventType === 'match_access_open' ? 'tickets_enabled' : 'matches_enabled';
}

export interface RecipientEligibilitySource {
  /** user_ids com uma linha de preferência PARA este club_id, com a coluna do evento habilitada. */
  explicitlyEligibleUserIds(clubId: string, prefColumn: PreferenceColumn): Promise<string[]>;
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
  const prefColumn = preferenceColumnFor(eventType);

  const [explicitlyEligibleIds, anyPreferenceIds, tokens] = await Promise.all([
    source.explicitlyEligibleUserIds(clubId, prefColumn),
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

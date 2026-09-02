// M3.3 — registry mínimo de config de clube pro lado das Edge Functions
// (Deno). O `ClubConfig` do Flutter não existe aqui (runtime separado) —
// este é o equivalente mínimo, só com os campos que as Edge Functions
// realmente usam pra propagar `club_id` explícito em
// `match_monitor_sessions`/`notification_events` e resolver o time real no
// Worker. Nunca duplica a config inteira do Flutter, nunca guarda secret
// (FCM/service role continuam só em Deno.env, nunca aqui).
//
// Hoje só `'goias'` está registrado — nenhum 2º clube real
// (SECOND_CLUB_BLOCKED). Um `club_id`/`clubCode` desconhecido NUNCA cai pro
// Goiás por omissão — quem chama `resolveClubServerConfigByClubId`/
// `resolveClubServerConfigByCode` trata `undefined` como fail-closed
// (loga e pula a sessão/evento, nunca assume Goiás).

export interface ClubServerConfig {
  code: string;
  /** Mesmo UUID de `goiasClubConfig.identity.canonicalClubId` no Flutter
   * (`lib/core/club/goias_club_config.dart`) e de
   * `src/football/_lib/club_server_config.ts` no Worker — os 3 nunca devem
   * divergir (ver `audit_multiclub_runtime_hardcodes.mjs`, checagem de
   * drift). É este UUID que casa com `match_monitor_sessions.club_id`/
   * `notification_events.club_id` (ambos `uuid references public.clubs`,
   * adicionados na M2.2A). */
  canonicalClubId: string;
  /** Mesmo id de `ClubIntegrations.oneFootballTeamId` no Flutter — usado
   * pra decidir de qual lado (casa/fora) o clube está numa partida ao
   * vivo, substituindo o antigo `GOIAS_TEAM_ID = 1863` hardcoded. */
  oneFootballTeamId: number;
  /** Mesmo `ClubIdentity.code` no Flutter — usado pra montar a rota
   * genérica `/api/football/team/:clubCode` no Worker. */
  oneFootballTeamPath: string;
  /** Nome curto do clube (`ClubIdentity.shortName`) — só pra comparação
   * "esse homeTeamName é o clube ativo?" no dispatch, nunca pra decisão de
   * fluxo/roteamento. */
  shortName: string;
  /**
   * Rodada de hardening (revisão do usuário, 2026-09-02): o título de GOL
   * é "GOOOOOOL DO <NOME DO CLUBE>!" — pro Goiás, "GOOOOOOL DO GOIÁS!",
   * NUNCA "...DO ESMERALDINO!" (esse foi um bug real da 1ª rodada,
   * reutilizando `fanDemonym`/torcedor pra um campo que semanticamente é
   * "nome do clube na notificação de gol" — 2 conceitos diferentes,
   * removido daqui). Campo SERVER-ONLY-PRESENTATION — Flutter não precisa
   * ter o equivalente (nunca consome essa copy), então não faz parte do
   * drift check de identidade (`SHARED_IDENTITY_FIELDS`, ver
   * `audit_multiclub_runtime_hardcodes.mjs`).
   */
  notificationGoalClubName: string;
  /**
   * O título de VITÓRIA é "VITÓRIA DO <APELIDO>!" — pro Goiás, "VITÓRIA DO
   * VERDÃO!" (apelido do time em si, NUNCA o gentílico do torcedor —
   * "Verdão" ≠ "Esmeraldino" ≠ "Goiás", 3 conceitos diferentes, cada um só
   * usado onde semanticamente correto). Mesmo motivo do campo acima: nunca
   * reusar `fanDemonym` pra isso.
   */
  notificationVictoryNickname: string;
}

const GOIAS_SERVER_CONFIG: ClubServerConfig = {
  code: 'goias',
  canonicalClubId: '4c16340d-300c-5ab2-903f-17519db9b146',
  oneFootballTeamId: 1863,
  oneFootballTeamPath: 'goias',
  shortName: 'Goiás',
  notificationGoalClubName: 'Goiás',
  notificationVictoryNickname: 'Verdão',
};

/** Todo registro real hoje — SECOND_CLUB_BLOCKED, nunca um 2º clube real
 * sem autorização explícita separada (mesma regra do `clubRegistry` do
 * Flutter e de `SERVER_CLUB_CODES` do Worker). */
export const SERVER_CLUB_REGISTRY: readonly ClubServerConfig[] = [GOIAS_SERVER_CONFIG];

export function resolveClubServerConfigByClubId(clubId: string): ClubServerConfig | undefined {
  return SERVER_CLUB_REGISTRY.find((c) => c.canonicalClubId === clubId);
}

export function resolveClubServerConfigByCode(code: string): ClubServerConfig | undefined {
  return SERVER_CLUB_REGISTRY.find((c) => c.code === code);
}

// M3.3 — registry mínimo de config de clube pro lado das Edge Functions
// (Deno). O `ClubConfig` do Flutter não existe aqui (runtime separado) —
// este é o equivalente mínimo, só com os campos que as Edge Functions
// realmente usam pra propagar `club_id` explícito em
// `match_monitor_sessions`/`notification_events` e resolver o time real no
// Worker. Nunca duplica a config inteira do Flutter, nunca guarda secret
// (FCM/service role continuam só em Deno.env, nunca aqui).
//
// M-live: Bragantino registrado (2ª entrada real), mesmos dados de
// `lib/core/club/bragantino_club_config.dart` — nunca inventados aqui. Um
// `club_id`/`clubCode` desconhecido continua NUNCA caindo pro Goiás por
// omissão — quem chama `resolveClubServerConfigByClubId`/
// `resolveClubServerConfigByCode` trata `undefined` como fail-closed
// (loga e pula a sessão/evento, nunca assume Goiás).
//
// IMPORTANTE (deploy multi-projeto): Goiás e Bragantino são projetos
// Supabase SEPARADOS (`yonozsdgyrhgqrvydbnr` vs `yrgyzkaaudyzmsqwzecj` —
// ver `lib/core/club/*_club_config.dart` e `infra/supabase/clubs/README.md`),
// cada um com seu próprio `public.clubs` (1 linha só). Ter os 2 clubes
// neste registry deixa o CÓDIGO pronto pros dois, mas cada Edge Function
// só enxerga o banco do projeto onde está deployada — pra Bragantino
// receber notificações de verdade, este mesmo código (supabase/functions/)
// precisa ser deployado TAMBÉM no projeto Bragantino (com seu próprio
// cron, sua própria FCM_SERVICE_ACCOUNT_JSON), igual ao Worker já é
// deployado 2x (`wrangler.toml` vs `wrangler.bragantino.toml`). Rodar o
// mesmo código nos 2 projetos é seguro (o clube que não pertence ao
// projeto atual simplesmente falha ao gravar por FK ausente em `clubs`,
// erro isolado e logado por clube — nunca derruba o outro).

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
  /** Mesmo `ClubIntegrations.workerBaseUrl` do Flutter — substitui o
   * antigo `WORKER_BASE_URL` hardcoded (sempre o do Goiás) em
   * `notifications-poll-live-match`/`notifications-sync-and-check-access`.
   * Nunca inferido a partir do `code`; sempre o valor real do clube. */
  workerBaseUrl: string;
}

/**
 * Rodada de hardening (revisão do usuário): gol/vitória usam SEMPRE
 * `shortName` — nunca um apelido separado (o antigo
 * `notificationVictoryNickname` chegou a valer "Verdão" pro Goiás; foi
 * removido de propósito nesta rodada, era exatamente o tipo de coisa que
 * gerou o bug real de reusar `fanDemonym`/apelido de torcida onde devia
 * ser o nome do clube). Um único campo (`shortName`) pra "GOOOOOOL DO
 * GOIÁS!" e "VITÓRIA DO GOIÁS!" elimina esse risco de vez — nunca mais um
 * 2º campo pra manter sincronizado nem apelido hardcoded por clube.
 */
const GOIAS_SERVER_CONFIG: ClubServerConfig = {
  code: 'goias',
  canonicalClubId: '4c16340d-300c-5ab2-903f-17519db9b146',
  oneFootballTeamId: 1863,
  oneFootballTeamPath: 'goias',
  shortName: 'Goiás',
  workerBaseUrl: 'https://goias-app.lucasdiogo1234.workers.dev',
};

// Mesmos valores reais de `lib/core/club/bragantino_club_config.dart`
// (canonicalClubId/oneFootballTeamId/workerBaseUrl já confirmados lá,
// nunca reinventados aqui).
const BRAGANTINO_SERVER_CONFIG: ClubServerConfig = {
  code: 'bragantino',
  canonicalClubId: '51683d2a-ea1d-57c6-8014-996146f242e7',
  oneFootballTeamId: 4734,
  oneFootballTeamPath: 'bragantino',
  shortName: 'Bragantino',
  workerBaseUrl: 'https://bragantino-app.lucasdiogo1234.workers.dev',
};

// Mesmos valores reais de `lib/core/club/vilanova_club_config.dart`
// (canonicalClubId = `goias-app:multiclub:club:3`, oneFootballTeamId 2865 e
// workerBaseUrl confirmados lá, nunca reinventados aqui).
const VILANOVA_SERVER_CONFIG: ClubServerConfig = {
  code: 'vilanova',
  canonicalClubId: '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e',
  oneFootballTeamId: 2865,
  oneFootballTeamPath: 'vilanova',
  shortName: 'Vila Nova',
  workerBaseUrl: 'https://vilanova-app.lucasdiogo1234.workers.dev',
};

/** Todo registro real hoje — Goiás, Bragantino e Vila Nova. Um 4º clube real
 * precisa da mesma autorização explícita já dada aqui (mesma regra do
 * `clubRegistry` do Flutter e de `SERVER_CLUB_CODES` do Worker). */
export const SERVER_CLUB_REGISTRY: readonly ClubServerConfig[] = [
  GOIAS_SERVER_CONFIG,
  BRAGANTINO_SERVER_CONFIG,
  VILANOVA_SERVER_CONFIG,
];

export function resolveClubServerConfigByClubId(clubId: string): ClubServerConfig | undefined {
  return SERVER_CLUB_REGISTRY.find((c) => c.canonicalClubId === clubId);
}

export function resolveClubServerConfigByCode(code: string): ClubServerConfig | undefined {
  return SERVER_CLUB_REGISTRY.find((c) => c.code === code);
}

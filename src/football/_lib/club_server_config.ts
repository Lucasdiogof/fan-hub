// M3.3 -> auditoria Matches/football multiclube: registry de config de
// clube pro lado do servidor (Worker). O `ClubConfig` do Flutter não existe
// aqui (runtimes diferentes) — este é o equivalente mínimo, só com os
// campos que o Worker realmente usa. Nunca duplica a config inteira do
// Flutter, nunca guarda secret (as credenciais continuam só em env/wrangler
// secrets, nunca aqui).
//
// Modelo: 1 Worker deploy POR CLUBE, mesmo código-fonte (`src/index.ts`
// nunca muda por clube). Cada deploy carrega seu próprio `CLUB_CODE` (env
// var, ver `config.ts`) — o allowlist de "qual clube este deploy serve" É
// essa env var, não mais uma lista hardcoded no código. Um `clubCode`
// pedido que não bata com o `CLUB_CODE` do PRÓPRIO deploy NUNCA cai pro
// clube deste deploy por omissão: lança `UnknownClubError`, erro
// controlado (ver NO_SERVER_CROSS_CLUB_FALLBACK no relatório da M3.3) — o
// Worker do Goiás rejeita `bragantino`, o Worker do Bragantino rejeita
// `goias`, sem exceção.
import type { Env } from './config';
import { ConfigError, loadConfig, requireTeamOneFootballSlug } from './config';

export interface ClubServerConfig {
  code: string;
  /** Slug do time no OneFootball (path `/pt-br/time/<slug>`) — único dado
   * de clube que os handlers de futebol realmente leem hoje. */
  oneFootballSlug: string;
}

export class UnknownClubError extends Error {
  constructor(clubCode: string) {
    super(`unknown club code: ${clubCode}`);
    this.name = 'UnknownClubError';
  }
}

/** Resolve [requestedClubCode] contra o `CLUB_CODE` deste deploy — nunca
 * uma lista de múltiplos clubes num Worker só. `requestedClubCode` fora do
 * `CLUB_CODE` do próprio deploy (ou `CLUB_CODE` ausente/mal configurado)
 * sempre lança, nunca resolve silenciosamente pro clube deste deploy. */
export function resolveClubServerConfig(requestedClubCode: string, env: Env): ClubServerConfig {
  const config = loadConfig(env);
  if (!config.clubCode) {
    throw new ConfigError('CLUB_CODE não configurado neste deploy.');
  }
  if (requestedClubCode !== config.clubCode) {
    throw new UnknownClubError(requestedClubCode);
  }
  return {
    code: config.clubCode,
    oneFootballSlug: requireTeamOneFootballSlug(config),
  };
}

// News/Social (raspagem do site oficial + redes sociais) — achado da
// auditoria M4: eram 100% hardcoded, sem NENHUMA dimensão de clube. Fora
// do escopo da auditoria Matches/football desta rodada (não tocado aqui);
// continuam com o próprio `'goias'` fixo até uma rodada dedicada.
export const NEWS_SOCIAL_CONFIGURED_CLUB_CODE = 'goias';

/** `clubCode` explícito da request (`?club=<code>`) — ausente = o único
 * clube que este Worker já serve hoje (mesma regra de compat do
 * `APP_CLUB` ausente no Flutter: nunca um valor mágico, só o comportamento
 * de sempre quando nada é dito). */
export function resolveRequestedClubCode(request: Request): string {
  return new URL(request.url).searchParams.get('club') ?? NEWS_SOCIAL_CONFIGURED_CLUB_CODE;
}

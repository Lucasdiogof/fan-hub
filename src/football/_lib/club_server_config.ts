// M3.3 — registry mínimo de config de clube pro lado do servidor (Worker).
// O `ClubConfig` do Flutter não existe aqui (runtimes diferentes) — este é
// o equivalente mínimo, só com os campos que o Worker realmente usa. Nunca
// duplica a config inteira do Flutter, nunca guarda secret (as credenciais
// continuam só em env/wrangler secrets, nunca aqui).
//
// Hoje só `'goias'` está registrado — nenhum 2º clube real. Um `clubCode`
// desconhecido NUNCA cai pro Goiás por omissão: lança `UnknownClubError`,
// erro controlado (ver NO_SERVER_CROSS_CLUB_FALLBACK no relatório da M3.3).
import type { Env } from './config';

export interface ClubServerConfig {
  code: string;
  /** Mesmo UUID de `goiasClubConfig.identity.canonicalClubId` no Flutter
   * (`lib/core/club/goias_club_config.dart`) — usado pra propagar `club_id`
   * em `match_monitor_sessions`/`notification_events`. Testado por
   * `club_server_config_drift.test.ts` que os 2 lados nunca divergem. */
  canonicalClubId: string;
  /** Substitui `Team.goiasId`/`ClubIntegrations.oneFootballTeamId` do lado
   * do servidor — mesmo id (1863 pro Goiás), usado pra decidir de qual lado
   * (casa/fora) o clube está numa partida ao vivo. */
  oneFootballTeamId: number;
  oneFootballSlug: string;
  oneFootballCompetitionSlug: string;
}

export class UnknownClubError extends Error {
  constructor(clubCode: string) {
    super(`unknown club code: ${clubCode}`);
    this.name = 'UnknownClubError';
  }
}

const GOIAS_CANONICAL_CLUB_ID = '4c16340d-300c-5ab2-903f-17519db9b146';
const GOIAS_ONEFOOTBALL_TEAM_ID = 1863;

/** Todo `clubCode` que o Worker sabe resolver hoje — SECOND_CLUB_BLOCKED:
 * nenhum 2º clube real deve ser adicionado aqui sem autorização explícita
 * separada (mesma regra do `clubRegistry` do Flutter). */
export const SERVER_CLUB_CODES = ['goias'] as const;

/** Lança `UnknownClubError` pra qualquer código fora de `SERVER_CLUB_CODES`
 * — nunca resolve silenciosamente pro Goiás. As env vars continuam sendo a
 * fonte real do valor (nada duplicado no código além do registry/lookup em
 * si), então o `wrangler.toml` não precisa mudar. */
export function resolveClubServerConfig(clubCode: string, env: Env): ClubServerConfig {
  if (clubCode !== 'goias') {
    throw new UnknownClubError(clubCode);
  }
  const oneFootballSlug = env.GOIAS_ONEFOOTBALL_SLUG;
  const oneFootballCompetitionSlug = env.ONEFOOTBALL_COMPETITION_SLUG;
  if (!oneFootballSlug) {
    throw new Error('GOIAS_ONEFOOTBALL_SLUG não configurado no wrangler.toml.');
  }
  if (!oneFootballCompetitionSlug) {
    throw new Error('ONEFOOTBALL_COMPETITION_SLUG não configurado no wrangler.toml.');
  }
  return {
    code: 'goias',
    canonicalClubId: GOIAS_CANONICAL_CLUB_ID,
    oneFootballTeamId: GOIAS_ONEFOOTBALL_TEAM_ID,
    oneFootballSlug,
    oneFootballCompetitionSlug,
  };
}

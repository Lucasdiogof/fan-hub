import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { ProviderError } from './_lib/providerError';
import { fetchMatchDetail } from './providers/onefootball_provider';
import { normalizeOneFootballMatchScore } from './normalize/match';
import { normalizeOneFootballMatchEvent } from './normalize/match_event';
import { normalizeOneFootballMatchLineups } from './normalize/match_lineup';

const CACHE_TTL_SECONDS = 30 * 60;
const COMPETITION_NAME = 'Brasileirão Série B';

/** `id` vem prefixado (`onef-<id>`) — o próprio Flutter nunca precisa
 * entender o prefixo, só devolve o que recebeu. */
export async function handleFixtureDetails(request: Request, env: Env, rawId: string): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);

    if (rawId.startsWith('onef-')) {
      return handleOneFootballFixture(request, config.cacheVersion, rawId.slice('onef-'.length));
    }

    throw new ProviderError('Id de partida inválido.', 400, 'internal');
  });
}

async function handleOneFootballFixture(request: Request, cacheVersion: string, matchId: string): Promise<Response> {
  return cacheFirst(request, CACHE_TTL_SECONDS, 'football.fixtures.details.onefootball', cacheVersion, async () => {
    const detail = await fetchMatchDetail(matchId);
    if (!detail) {
      throw new ProviderError('Partida não encontrada.', 404, 'onefootball');
    }
    return {
      competition: { name: COMPETITION_NAME, season: null },
      match: normalizeOneFootballMatchScore(matchId, detail.score, detail.stadium),
      events: detail.events.map(normalizeOneFootballMatchEvent),
      lineups: detail.lineup ? normalizeOneFootballMatchLineups(detail.lineup) : null,
    };
  });
}

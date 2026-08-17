import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { apiFootballGet, ApiFootballError } from './_lib/client';
import { cacheFirst } from './_lib/cache';
import { normalizeFixture } from './_lib/normalize';
import { withErrorHandling } from './_lib/handleErrors';

const CACHE_TTL_SECONDS = 30 * 60;

export async function handleFixtureDetails(
  request: Request,
  env: Env,
  fixtureId: string,
): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.fixtures.details', async () => {
      const raw = await apiFootballGet(config, '/fixtures', {
        id: fixtureId,
        timezone: 'America/Sao_Paulo',
      });

      const item = raw.response?.[0];
      if (!item) {
        throw new ApiFootballError('Partida não encontrada.', 404);
      }

      return {
        competition: {
          id: config.leagueId,
          name: item.league?.name ?? 'Brasileirão Série B',
          season: config.season,
        },
        match: normalizeFixture(item),
      };
    });
  });
}

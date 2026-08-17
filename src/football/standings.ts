import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchBrasileiraoStandings } from './providers/brasileirao_provider';
import { normalizeStandingEntry } from './normalize/standing';

const CACHE_TTL_SECONDS = 45 * 60;

export const onRequestGet = handleStandings;

export async function handleStandings(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.standings', config.cacheVersion, async () => {
      const { competition, table } = await fetchBrasileiraoStandings(config.serieCode);

      return {
        competition: {
          name: competition.name,
          season: competition.season,
        },
        standings: table.entries.map((entry) => normalizeStandingEntry(entry, config.goias.brasileiraoId)),
      };
    });
  });
}

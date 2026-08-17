import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { apiFootballGet } from './_lib/client';
import { cacheFirst } from './_lib/cache';
import { normalizeStanding } from './_lib/normalize';
import { withErrorHandling } from './_lib/handleErrors';

const CACHE_TTL_SECONDS = 45 * 60;

export async function handleStandings(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.standings', async () => {
      const raw = await apiFootballGet(config, '/standings', {
        league: config.leagueId,
        season: config.season,
      });

      const leagueBlock = raw.response?.[0]?.league;
      const groups = leagueBlock?.standings ?? [];
      const standings = (groups[0] ?? []).map(normalizeStanding);

      return {
        competition: {
          id: config.leagueId,
          name: leagueBlock?.name ?? 'Brasileirão Série B',
          season: config.season,
        },
        standings,
      };
    });
  });
}

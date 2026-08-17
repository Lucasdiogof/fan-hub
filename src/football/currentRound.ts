import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchBrasileiraoCurrentRound } from './providers/brasileirao_provider';
import { normalizeBrasileiraoMatch } from './normalize/match';

const CACHE_TTL_SECONDS = 20 * 60;

export const onRequestGet = handleCurrentRound;

export async function handleCurrentRound(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.current_round', config.cacheVersion, async () => {
      const { competition, round } = await fetchBrasileiraoCurrentRound(config.serieCode);

      return {
        competition: {
          name: competition.name,
          season: competition.season,
        },
        round: {
          number: round.number,
          label: round.label,
        },
        matches: round.matches.map((match) => normalizeBrasileiraoMatch(match, round.label)),
      };
    });
  });
}

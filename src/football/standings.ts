import type { Env } from './_lib/config';
import { loadConfig, requireGoiasOneFootballSlug, requireOneFootballCompetitionSlug } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchCompetitionStandings } from './providers/onefootball_provider';
import { normalizeStandingEntry } from './normalize/standing';

const CACHE_TTL_SECONDS = 45 * 60;
const COMPETITION_NAME = 'Brasileirão Série B';

export const onRequestGet = handleStandings;

export async function handleStandings(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const competitionSlug = requireOneFootballCompetitionSlug(config);
    // O slug do time (`goias-1863`) já carrega o id — evita manter um id
    // numérico separado só pra essa comparação.
    const goiasId = Number(requireGoiasOneFootballSlug(config).match(/-(\d+)$/)?.[1]) || null;

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.standings', config.cacheVersion, async () => {
      const rows = await fetchCompetitionStandings(competitionSlug);

      return {
        competition: { name: COMPETITION_NAME, season: null },
        standings: rows.map((row) => normalizeStandingEntry(row, goiasId)),
      };
    });
  });
}

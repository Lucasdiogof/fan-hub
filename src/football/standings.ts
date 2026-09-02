import type { Env } from './_lib/config';
import { loadConfig, requireOneFootballCompetitionSlug } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchCompetitionStandings } from './providers/onefootball_provider';
import { normalizeStandingEntry } from './normalize/standing';

const CACHE_TTL_SECONDS = 45 * 60;
const COMPETITION_NAME = 'Brasileirão Série B';

// A classificação inteira do campeonato é a MESMA pra qualquer clube que
// dispute a mesma competição — nunca precisou saber "qual é o clube ativo"
// (M3.3: removido o cálculo de `goiasId`/`isGoias` que só existia pra isso;
// "esse time da tabela é o meu clube?" agora é decidido só no Flutter via
// `Team.matchesClub(ClubConfig)`, comparando o `team.id` que já vinha na
// resposta).
export const onRequestGet = handleStandings;

export async function handleStandings(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const competitionSlug = requireOneFootballCompetitionSlug(config);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.standings', config.cacheVersion, async () => {
      const rows = await fetchCompetitionStandings(competitionSlug);

      return {
        competition: { name: COMPETITION_NAME, season: null },
        standings: rows.map((row) => normalizeStandingEntry(row)),
      };
    });
  });
}

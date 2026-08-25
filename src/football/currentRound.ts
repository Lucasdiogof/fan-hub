import type { Env } from './_lib/config';
import { loadConfig, requireOneFootballCompetitionSlug } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchCompetitionMatchLists } from './providers/onefootball_provider';
import type { OneFootballMatchList } from './providers/onefootball_provider';
import { normalizeOneFootballMatchCard } from './normalize/match';

const CACHE_TTL_SECONDS = 20 * 60;
const COMPETITION_NAME = 'Brasileirão Série B';

export const onRequestGet = handleCurrentRound;

export async function handleCurrentRound(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const competitionSlug = requireOneFootballCompetitionSlug(config);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.current_round', config.cacheVersion, async () => {
      const lists = await fetchCompetitionMatchLists(competitionSlug);
      const current = pickCurrentRound(lists);

      return {
        competition: { name: COMPETITION_NAME, season: null },
        round: { number: null, label: current?.sectionHeader?.subtitle ?? null },
        matches: (current?.matchCards ?? []).map((card) => normalizeOneFootballMatchCard(card)),
      };
    });
  });
}

/** As listas vêm em ordem cronológica ("Rodada 24", "25", "26"...) — a
 * rodada atual é a primeira que ainda tem algum jogo não terminado. Se
 * todas já terminaram (fim de temporada), cai pra última — a mais recente
 * concluída — em vez de devolver vazio. */
export function pickCurrentRound(lists: OneFootballMatchList[]): OneFootballMatchList | null {
  for (const list of lists) {
    const hasUnfinished = list.matchCards.some((card) => card.period !== 'FULL_TIME');
    if (hasUnfinished) return list;
  }
  return lists[lists.length - 1] ?? null;
}

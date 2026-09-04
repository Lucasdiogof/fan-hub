import type { Env } from './_lib/config';
import {
  loadConfig,
  requirePrimaryCompetitionDisplayName,
  requirePrimaryCompetitionSlug,
} from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchCompetitionMatchLists } from './providers/onefootball_provider';
import type { OneFootballMatchList } from './providers/onefootball_provider';
import { normalizeOneFootballMatchCard } from './normalize/match';

const CACHE_TTL_SECONDS = 20 * 60;

export const onRequestGet = handleCurrentRound;

export async function handleCurrentRound(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const competitionSlug = requirePrimaryCompetitionSlug(config);
    const competitionName = requirePrimaryCompetitionDisplayName(config);
    const offset = parseOffset(new URL(request.url).searchParams.get('offset'));

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.current_round', config.cacheVersion, async () => {
      const lists = await fetchCompetitionMatchLists(competitionSlug);
      const currentIndex = pickCurrentRoundIndex(lists);
      const targetIndex = currentIndex + offset;
      const target = lists[targetIndex] ?? null;

      return {
        competition: { name: competitionName, season: null },
        round: { number: null, label: target?.sectionHeader?.subtitle ?? null },
        matches: (target?.matchCards ?? []).map((card) => normalizeOneFootballMatchCard(card)),
        hasPrevious: targetIndex > 0,
        hasNext: targetIndex >= 0 && targetIndex < lists.length - 1,
      };
    });
  });
}

/** `?offset=` é relativo à rodada atual (0), negativo pra anteriores —
 * qualquer valor ausente/inválido cai em 0 em vez de quebrar a rota. */
function parseOffset(raw: string | null): number {
  if (raw == null) return 0;
  const parsed = Number.parseInt(raw, 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}

/** As listas vêm em ordem cronológica ("Rodada 24", "25", "26"...) — a
 * rodada atual é a primeira que ainda tem algum jogo não terminado. Se
 * todas já terminaram (fim de temporada), cai pra última — a mais recente
 * concluída — em vez de devolver vazio. */
export function pickCurrentRoundIndex(lists: OneFootballMatchList[]): number {
  for (let i = 0; i < lists.length; i++) {
    const hasUnfinished = lists[i].matchCards.some((card) => card.period !== 'FULL_TIME');
    if (hasUnfinished) return i;
  }
  return lists.length - 1;
}

export function pickCurrentRound(lists: OneFootballMatchList[]): OneFootballMatchList | null {
  return lists[pickCurrentRoundIndex(lists)] ?? null;
}

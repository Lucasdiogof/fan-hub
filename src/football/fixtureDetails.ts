import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { ProviderError } from './_lib/providerError';
import { fetchMatchDetail } from './providers/onefootball_provider';
import { normalizeOneFootballMatchScore } from './normalize/match';
import { normalizeOneFootballMatchEvent } from './normalize/match_event';
import { normalizeOneFootballMatchLineups } from './normalize/match_lineup';
import { normalizeOneFootballMatchStat } from './normalize/match_stat';

// Era 30 min — baixado por causa do mesmo motivo do team.ts: a Central da
// partida agora faz polling nesta rota enquanto o jogo do clube ativo está
// ao vivo (ver `MatchDetailsCubit`), então 30 min deixaria o placar/minuto/
// estatísticas presos na primeira leitura por boa parte do jogo.
const CACHE_TTL_SECONDS = 60;

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
    // REGRA ABSOLUTA (auditoria Matches/football): esta partida pode ser de
    // QUALQUER competição que o clube dispute — jamais usar
    // PRIMARY_COMPETITION_DISPLAY_NAME aqui, nem como fallback. Só a
    // competição REAL encontrada no payload (`detail.score.competition`,
    // confirmada presente ao vivo) ou string vazia — nunca um campeonato
    // inventado. `''` é a mesma convenção de "desconhecida" já usada em
    // `getSeasonFixtures` no Flutter (`competitionName: ''`).
    return {
      competition: { name: detail.score.competition?.name ?? '', season: null },
      match: normalizeOneFootballMatchScore(matchId, detail.score, detail.stadium),
      events: detail.events.map(normalizeOneFootballMatchEvent),
      lineups: detail.lineup ? normalizeOneFootballMatchLineups(detail.lineup) : null,
      stats: detail.stats.map(normalizeOneFootballMatchStat),
    };
  });
}

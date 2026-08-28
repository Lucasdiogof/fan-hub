import type { Env } from './_lib/config';
import { loadConfig, requireGoiasOneFootballSlug } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchTeamMatchLists, fetchMatchDetail } from './providers/onefootball_provider';
import { normalizeOneFootballMatchCard } from './normalize/match';

// Era 30 min — baixado pra caber o card "ao vivo" da Home/Jogos, que faz
// polling desta MESMA rota a cada ~45s enquanto o jogo do Goiás está
// rolando (ver `LiveMatchPoller` no Flutter). O cache do Worker ainda
// protege o OneFootball de qualquer coisa: com N usuários acompanhando ao
// mesmo tempo, o upstream só é chamado uma vez a cada 60s (cache
// compartilhado na borda), nunca uma vez por usuário/poll.
const CACHE_TTL_SECONDS = 60;
const COMPETITION_NAME = 'Brasileirão Série B';

/**
 * Só existe `/team/goias` por enquanto — o app tem um único time de
 * interesse. Se um dia precisar de outros times, o path vira `/team/:slug`
 * sem quebrar esse contrato.
 */
export const onRequestGet = handleGoiasTeam;

export async function handleGoiasTeam(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const teamSlug = requireGoiasOneFootballSlug(config);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.team.goias', config.cacheVersion, async () => {
      const [upcomingLists, resultLists] = await Promise.all([
        fetchTeamMatchLists(teamSlug, 'jogos'),
        fetchTeamMatchLists(teamSlug, 'resultados'),
      ]);

      const upcoming = upcomingLists.flatMap((list) => list.matchCards);
      const recent = resultLists.flatMap((list) => list.matchCards);

      const nextCard = upcoming[0];
      // Só busca o estádio da próxima partida (a mais visível na UI) — não
      // vale a pena um fetch extra por item pros resultados recentes.
      const nextStadium = nextCard ? (await fetchMatchDetail(nextCard.matchId))?.stadium ?? null : null;

      return {
        competition: { name: COMPETITION_NAME, season: null },
        nextMatch: nextCard ? normalizeOneFootballMatchCard(nextCard, nextStadium) : null,
        recentResults: recent.map((card) => normalizeOneFootballMatchCard(card)),
      };
    });
  });
}

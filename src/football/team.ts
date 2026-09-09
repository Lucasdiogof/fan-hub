import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { resolveClubServerConfig } from './_lib/club_server_config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchTeamMatchLists, fetchMatchDetail } from './providers/onefootball_provider';
import { normalizeOneFootballMatchCardWithCompetition } from './normalize/match';

// Era 30 min — baixado pra caber o card "ao vivo" da Home/Jogos, que faz
// polling desta MESMA rota a cada ~45s enquanto o jogo do clube ativo está
// rolando (ver `LiveMatchPoller` no Flutter). O cache do Worker ainda
// protege o OneFootball de qualquer coisa: com N usuários acompanhando ao
// mesmo tempo, o upstream só é chamado uma vez a cada 60s por clube (cache
// compartilhado na borda, chave inclui `clubCode`), nunca uma vez por
// usuário/poll.
const CACHE_TTL_SECONDS = 60;

/**
 * M3.3 — rota genérica `/api/football/team/:clubCode`. `/team/goias`
 * continua existindo em `index.ts` como alias legacy pro app já publicado
 * (nunca removido só porque o runtime novo usa o path genérico) —
 * resolvido pelo MESMO `clubCode='goias'`, nunca uma implementação
 * duplicada.
 */
export async function handleTeam(request: Request, env: Env, clubCode: string): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const clubConfig = resolveClubServerConfig(clubCode, env);
    const teamSlug = clubConfig.oneFootballSlug;

    return cacheFirst(request, CACHE_TTL_SECONDS, `football.team.${clubConfig.code}`, config.cacheVersion, async () => {
      const [upcomingLists, resultLists] = await Promise.all([
        fetchTeamMatchLists(teamSlug, 'jogos'),
        fetchTeamMatchLists(teamSlug, 'resultados'),
      ]);

      const upcoming = upcomingLists.flatMap((list) => list.matchCards);
      const recent = resultLists.flatMap((list) => list.matchCards);

      // PARTE 2 (auditoria multi-competição 2026-09-09): as listas do
      // OneFootball vêm em ordem por competição/rodada, NUNCA garantida
      // cronológica entre competições diferentes — um clube disputando
      // Brasileirão + Copa do Brasil na mesma janela podia ter o próximo
      // jogo de uma competição aparecendo depois do de outra na resposta
      // bruta, e `[0]` pegava o card errado. Ordena por kickoff ascendente
      // antes de escolher; card sem kickoff válido (data a confirmar) vai
      // pro fim, nunca inventa horário nem descarta a partida.
      const sortedUpcoming = [...upcoming].sort((a, b) => {
        const aTime = Date.parse(a.kickoff);
        const bTime = Date.parse(b.kickoff);
        const aValid = !Number.isNaN(aTime);
        const bValid = !Number.isNaN(bTime);
        if (aValid && bValid) return aTime - bTime;
        if (aValid) return -1;
        if (bValid) return 1;
        return 0;
      });

      const nextCard = sortedUpcoming[0];
      // Só busca o estádio da próxima partida (a mais visível na UI) — não
      // vale a pena um fetch extra por item pros resultados recentes.
      const nextStadium = nextCard ? (await fetchMatchDetail(nextCard.matchId))?.stadium ?? null : null;

      // REGRA ABSOLUTA (auditoria Matches/football): `/team/:clubCode` NÃO
      // é uma operação de competição principal — o time pode estar
      // disputando Brasileirão, Copa do Brasil, torneio continental etc.
      // na mesma janela. `competition` no nível da resposta nunca usa
      // PRIMARY_COMPETITION_DISPLAY_NAME (isso é só pra `standings`/
      // `current-round`, que SÃO operações da competição principal) — cada
      // partida carrega a própria competição real
      // (`card.competitionName`, ver `normalizeOneFootballMatchCardWithCompetition`);
      // `''` é só o valor de "desconhecida" quando nem a partida tem o dado.
      return {
        competition: { name: '', season: null },
        nextMatch: nextCard ? normalizeOneFootballMatchCardWithCompetition(nextCard, nextStadium) : null,
        recentResults: recent.map((card) => normalizeOneFootballMatchCardWithCompetition(card)),
      };
    });
  });
}

import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { resolveClubServerConfig } from './_lib/club_server_config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchTeamSeasonMatchCards } from './providers/onefootball_provider';
import { normalizeOneFootballMatchCardWithCompetition } from './normalize/match';

// A temporada muda pouco — só quando um jogo agendado ganha data/horário
// confirmado, ou quando um jogo termina. Bem mais longo que os outros
// endpoints (que cobrem janela curta/ao vivo) de propósito: o calendário
// não precisa de dado fresco ao segundo.
const CACHE_TTL_SECONDS = 1200;

/**
 * Todos os jogos do clube ativo na temporada (todas as competições juntas —
 * cada partida já carrega o próprio nome de competição, diferente dos
 * outros endpoints que têm UM `competition` no nível da resposta). Sem
 * estádio: buscar isso pra ~50 partidas de uma vez custaria uma chamada
 * extra por partida — o calendário não mostra estádio por dia (só escudo +
 * casa/fora, por design), e a tela de detalhes de cada jogo já busca o
 * estádio à parte quando o usuário toca numa partida.
 *
 * M3.3 — rota genérica `/api/football/team/:clubCode/season`;
 * `/team/goias/season` continua como alias legacy em `index.ts`.
 */
export async function handleTeamSeason(request: Request, env: Env, clubCode: string): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const clubConfig = resolveClubServerConfig(clubCode, env);
    const teamSlug = clubConfig.oneFootballSlug;

    return cacheFirst(
      request,
      CACHE_TTL_SECONDS,
      `football.team.${clubConfig.code}.season`,
      config.cacheVersion,
      async () => {
        const cards = await fetchTeamSeasonMatchCards(teamSlug);
        const matches = cards
          .map((card) => normalizeOneFootballMatchCardWithCompetition(card))
          .sort((a, b) => (a.kickoff ?? '').localeCompare(b.kickoff ?? ''));
        return { matches };
      },
    );
  });
}

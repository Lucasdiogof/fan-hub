import type { Env } from './_lib/config';
import {
  loadConfig,
  requirePrimaryCompetitionDisplayName,
  requirePrimaryCompetitionSlug,
} from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { isRequestedClubServed } from './_lib/club_server_config';
import { jsonResponse } from './_lib/respond';
import { fetchCompetitionStandings } from './providers/onefootball_provider';
import { normalizeStandingEntry } from './normalize/standing';

const CACHE_TTL_SECONDS = 45 * 60;

// A classificação inteira do campeonato é a MESMA pra qualquer clube que
// dispute a mesma competição — nunca precisou saber "qual é o clube ativo"
// (M3.3: removido o cálculo de `goiasId`/`isGoias` que só existia pra isso;
// "esse time da tabela é o meu clube?" agora é decidido só no Flutter via
// `Team.matchesClub(ClubConfig)`, comparando o `team.id` que já vinha na
// resposta).
//
// O gate de `?club=` (2026-09-09, auditoria multi-competição) é diferente:
// não é sobre "de quem é a tabela", é sobre nunca responder 200 com o dado
// de UM clube quando o app pediu o de OUTRO — sem isso, um app apontando
// pro Worker errado (visto ao vivo: `API_BASE_URL` de dev vazando pra
// build de outro clube) recebia a Série B do Goiás travestida de "a
// classificação" dentro do app do Bragantino, sem nenhum sinal de erro.
// Mesmo padrão de `isRequestedClubServed` já usado em `/api/news`/
// `/api/social/feed` — `?club=` ausente cai no comportamento de sempre
// (nunca quebra clientes antigos que ainda não mandam o parâmetro).
export const onRequestGet = handleStandings;

export async function handleStandings(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    if (!isRequestedClubServed(request, env)) {
      return jsonResponse({ error: 'unknown club code' }, { status: 404 });
    }
    const config = loadConfig(env);
    const competitionSlug = requirePrimaryCompetitionSlug(config);
    const competitionName = requirePrimaryCompetitionDisplayName(config);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.standings', config.cacheVersion, async () => {
      const rows = await fetchCompetitionStandings(competitionSlug);

      return {
        competition: { name: competitionName, season: null },
        standings: rows.map((row) => normalizeStandingEntry(row)),
      };
    });
  });
}

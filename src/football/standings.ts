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
import { fetchCompetitionGroupStandings, fetchCompetitionStandings } from './providers/onefootball_provider';
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
    const requestedCompetitionId = new URL(request.url).searchParams.get('competition');

    // `?competition=` ausente ou igual a "primary" -> comportamento de
    // sempre (nunca quebra cliente antigo que não manda o parâmetro).
    // Qualquer outro valor precisa bater com uma entrada de
    // `SECONDARY_COMPETITIONS` deste deploy — nunca aceita um slug cru do
    // cliente (só os slugs confirmados na config do próprio Worker).
    const secondary =
      requestedCompetitionId && requestedCompetitionId !== 'primary'
        ? config.secondaryCompetitions.find((c) => c.id === requestedCompetitionId)
        : undefined;
    if (requestedCompetitionId && requestedCompetitionId !== 'primary' && !secondary) {
      return jsonResponse({ error: 'unknown competition id' }, { status: 404 });
    }

    const competitionSlug = secondary?.slug ?? requirePrimaryCompetitionSlug(config);
    const competitionName = secondary?.name ?? requirePrimaryCompetitionDisplayName(config);
    const format = secondary?.format ?? 'LEAGUE_TABLE';
    const cacheKey = `football.standings.${secondary?.id ?? 'primary'}`;

    return cacheFirst(request, CACHE_TTL_SECONDS, cacheKey, config.cacheVersion, async () => {
      if (format === 'GROUP_STAGE') {
        const groups = await fetchCompetitionGroupStandings(competitionSlug);
        return {
          competition: { name: competitionName, season: null, format },
          groups: groups.map((group) => ({
            title: group.title,
            standings: group.rows.map((row) => normalizeStandingEntry(row)),
          })),
        };
      }
      const rows = await fetchCompetitionStandings(competitionSlug);
      return {
        competition: { name: competitionName, season: null, format },
        standings: rows.map((row) => normalizeStandingEntry(row)),
      };
    });
  });
}

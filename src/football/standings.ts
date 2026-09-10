import type { Env } from './_lib/config';
import {
  loadConfig,
  requirePrimaryCompetitionDisplayName,
  requirePrimaryCompetitionSlug,
} from './_lib/config';
import { findCatalogCompetition } from './_lib/competition_catalog';
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
    // sempre: a competição principal DESTE clube (env do próprio deploy).
    // Qualquer outro valor resolve contra o catálogo GLOBAL (ver
    // `competition_catalog.ts`) — independente do clube. `club` continua
    // sendo só o gate de segurança/flavor (`isRequestedClubServed` acima),
    // NUNCA restringe quais `competition=` são aceitos: consultar uma
    // competição que o clube não disputa é uma operação válida (spec
    // multi-competição, item 21), não é cross-club fallback.
    const catalogEntry =
      requestedCompetitionId && requestedCompetitionId !== 'primary'
        ? findCatalogCompetition(requestedCompetitionId)
        : undefined;
    if (requestedCompetitionId && requestedCompetitionId !== 'primary' && !catalogEntry) {
      return jsonResponse({ error: 'unknown competition id' }, { status: 404 });
    }

    const competitionId = catalogEntry?.id ?? 'primary';
    const competitionSlug = catalogEntry?.slug ?? requirePrimaryCompetitionSlug(config);
    const competitionName = catalogEntry?.name ?? requirePrimaryCompetitionDisplayName(config);
    const format = catalogEntry?.format ?? 'LEAGUE_TABLE';
    const cacheKey = `football.standings.${competitionId}`;

    return cacheFirst(request, CACHE_TTL_SECONDS, cacheKey, config.cacheVersion, async () => {
      if (format === 'KNOCKOUT') {
        // Sem renderer ainda (Fase C da rearquitetura multi-competição) —
        // DATA_GAP explícito, nunca um erro de rede nem uma tabela vazia
        // sem explicação (spec multi-competição, item 29).
        return {
          competition: { name: competitionName, season: null, format },
          standings: [],
          groups: [],
          dataGap: true,
        };
      }
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

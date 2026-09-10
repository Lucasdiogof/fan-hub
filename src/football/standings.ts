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
import {
  fetchCompetitionGroupStandings,
  fetchCompetitionMatchLists,
  fetchCompetitionStandings,
} from './providers/onefootball_provider';
import { normalizeStandingEntry } from './normalize/standing';
import {
  buildKnockoutRounds,
  selectKnockoutSections,
  tableSectionLabel,
  tableWindowFrom,
  type KnockoutRoundOut,
} from './_lib/knockout';

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

type StageOut = {
  id: string;
  name: string;
  order: number;
  type: 'LEAGUE_TABLE' | 'GROUP_STAGE' | 'KNOCKOUT';
  status: 'UPCOMING' | 'ACTIVE' | 'COMPLETED';
  isCurrent: boolean;
  standings: ReturnType<typeof normalizeStandingEntry>[];
  groups: { title: string; standings: ReturnType<typeof normalizeStandingEntry>[] }[];
  rounds: KnockoutRoundOut[];
};

function knockoutStage(rounds: KnockoutRoundOut[], order: number): StageOut {
  return {
    id: 'knockout',
    // "Mata-mata" é um rótulo genérico do domínio (nunca aparece como
    // string literal em nenhum payload do provider) — não é config por
    // competição, é o mesmo nome pra qualquer competição que tenha essa
    // fase (spec 2026-09-11, item 6/9).
    name: 'Mata-mata',
    order,
    type: 'KNOCKOUT',
    status: 'ACTIVE',
    isCurrent: true,
    standings: [],
    groups: [],
    rounds,
  };
}

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
        // Copa do Brasil: NUNCA existe fase de tabela (`tableWindow` sempre
        // `null` aqui), então toda seção reconhecida como mata-mata é
        // aceita — comportamento intacto desde 2026-09-10, só reescrito em
        // cima da descoberta genérica (`selectKnockoutSections`) em vez de
        // uma função dedicada por formato.
        const lists = await fetchCompetitionMatchLists(competitionSlug);
        const knockoutLists = selectKnockoutSections(lists, null);
        const rounds = buildKnockoutRounds(knockoutLists);
        const stages: StageOut[] = rounds.length > 0 ? [knockoutStage(rounds, 0)] : [];
        return {
          competition: { name: competitionName, season: null, format },
          standings: [],
          groups: [],
          dataGap: stages.length === 0,
          season: { id: competitionId, label: competitionName, stages },
        };
      }

      // LEAGUE_TABLE/GROUP_STAGE: busca a tabela normal E, na mesma
      // resposta, tenta descobrir se a temporada JÁ tem uma fase de
      // mata-mata real depois dela (spec 2026-09-11, item 1/2) — sem saber
      // o nome da competição, só pelo formato real do payload de jogos/
      // resultados (`_lib/knockout.ts`). Uma chamada extra por competição a
      // cada 45min de cache (`cacheFirst` envolve o handler inteiro),
      // nunca por usuário/request — não é N+1 (spec item 11).
      const matchLists = await fetchCompetitionMatchLists(competitionSlug);
      const tableWindow = tableWindowFrom(matchLists);
      const knockoutLists = selectKnockoutSections(matchLists, tableWindow);
      const knockoutRounds = buildKnockoutRounds(knockoutLists);
      // Fase de tabela COMPLETED quando a temporada já avançou pro
      // mata-mata (spec item 12) — nunca todas as fases artificialmente
      // "active"; sem mata-mata descoberto, a fase de tabela é sempre a
      // atual (comportamento de toda competição LEAGUE_TABLE/GROUP_STAGE
      // hoje, incluindo Champions e as ligas principais dos dois clubes).
      const tableIsCurrent = knockoutRounds.length === 0;

      if (format === 'GROUP_STAGE') {
        const groups = await fetchCompetitionGroupStandings(competitionSlug);
        const normalizedGroups = groups.map((group) => ({
          title: group.title,
          standings: group.rows.map((row) => normalizeStandingEntry(row)),
        }));
        const groupsStage: StageOut = {
          id: 'main',
          name: competitionName,
          order: 0,
          type: 'GROUP_STAGE',
          status: tableIsCurrent ? 'ACTIVE' : 'COMPLETED',
          isCurrent: tableIsCurrent,
          standings: [],
          groups: normalizedGroups,
          rounds: [],
        };
        const stages: StageOut[] =
          knockoutRounds.length > 0 ? [groupsStage, knockoutStage(knockoutRounds, 1)] : [groupsStage];
        return {
          competition: { name: competitionName, season: null, format },
          groups: normalizedGroups,
          season: { id: competitionId, label: competitionName, stages },
        };
      }

      const rows = await fetchCompetitionStandings(competitionSlug);
      const standings = rows.map((row) => normalizeStandingEntry(row));
      // Nome real da fase quando o provider expõe um rótulo distintivo
      // (ex.: "Fase de liga" na Champions atual) — cai pro nome da
      // competição quando a seção só usa "Rodada N" (ligas simples de
      // pontos corridos, ex.: Brasileirão), que não é um nome de fase.
      const stageName = tableSectionLabel(matchLists) ?? competitionName;
      const leagueStage: StageOut = {
        id: 'main',
        name: stageName,
        order: 0,
        type: 'LEAGUE_TABLE',
        status: tableIsCurrent ? 'ACTIVE' : 'COMPLETED',
        isCurrent: tableIsCurrent,
        standings,
        groups: [],
        rounds: [],
      };
      const stages: StageOut[] =
        knockoutRounds.length > 0 ? [leagueStage, knockoutStage(knockoutRounds, 1)] : [leagueStage];
      return {
        competition: { name: competitionName, season: null, format },
        standings,
        season: { id: competitionId, label: competitionName, stages },
      };
    });
  });
}

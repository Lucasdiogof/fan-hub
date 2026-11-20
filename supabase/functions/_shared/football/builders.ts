// Builders de snapshot: OneFootball -> JSON do contrato do Fan-Hub, IDÊNTICO
// ao que os handlers do Worker (src/football/{team,teamSeason,currentRound,
// standings,competitions,fixtureDetails}.ts) devolviam. Sem cache/Response:
// quem persiste é `refresh.ts`. Um módulo, uma função por `kind`.
import type { ClubServerConfig } from '../club_server_config.ts';
import { GLOBAL_COMPETITION_CATALOG, competitionIdsForClub, findCatalogCompetition } from './catalog.ts';
import { ProviderError } from './errors.ts';
import {
  buildKnockoutRounds,
  hasAnyDecidedMatch,
  selectKnockoutSections,
  tableSectionLabel,
  tableWindowFrom,
  type KnockoutRoundOut,
} from './knockout.ts';
import {
  normalizeOneFootballMatchCard,
  normalizeOneFootballMatchCardWithCompetition,
  normalizeOneFootballMatchEvent,
  normalizeOneFootballMatchLineups,
  normalizeOneFootballMatchScore,
  normalizeOneFootballMatchStat,
  normalizeStandingEntry,
} from './normalize.ts';
import {
  fetchCompetitionGroupStandings,
  fetchCompetitionLogoUrl,
  fetchCompetitionMatchLists,
  fetchCompetitionStandings,
  fetchMatchDetail,
  fetchTeamMatchLists,
  fetchTeamSeasonMatchCards,
} from './provider.ts';
import type { OneFootballMatchList } from './provider.ts';

// ---- team (Home + push) ----

export async function buildTeamSnapshot(club: ClubServerConfig) {
  const [upcomingLists, resultLists] = await Promise.all([
    fetchTeamMatchLists(club.oneFootballSlug, 'jogos'),
    fetchTeamMatchLists(club.oneFootballSlug, 'resultados'),
  ]);
  const upcoming = upcomingLists.flatMap((list) => list.matchCards);
  const recent = resultLists.flatMap((list) => list.matchCards);

  // As listas do OneFootball não são cronológicas entre competições; ordena
  // por kickoff (sem horário válido vai pro fim, nunca é descartado).
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
  const nextStadium = nextCard ? ((await fetchMatchDetail(nextCard.matchId))?.stadium ?? null) : null;

  // `competition` do nível da resposta é sempre vazio: cada partida carrega
  // a própria competição real (ver comentário no Worker original).
  return {
    competition: { name: '', season: null },
    nextMatch: nextCard ? normalizeOneFootballMatchCardWithCompetition(nextCard, nextStadium) : null,
    recentResults: recent.map((card) => normalizeOneFootballMatchCardWithCompetition(card)),
  };
}

// ---- season ----

export async function buildSeasonSnapshot(club: ClubServerConfig) {
  const cards = await fetchTeamSeasonMatchCards(club.oneFootballSlug);
  const matches = cards
    .map((card) => normalizeOneFootballMatchCardWithCompetition(card))
    .sort((a, b) => (a.kickoff ?? '').localeCompare(b.kickoff ?? ''));
  return { matches };
}

// ---- current_round ----

const STALLED_PERIODS = new Set(['POSTPONED', 'CANCELLED', 'CANCELED', 'SUSPENDED', 'ABANDONED']);

/** Rodada atual = primeira com algum jogo realmente em aberto (nunca
 * FULL_TIME nem adiado/cancelado/suspenso); fim de temporada cai pra última. */
export function pickCurrentRoundIndex(lists: OneFootballMatchList[]): number {
  for (let i = 0; i < lists.length; i++) {
    const hasOpenMatch = lists[i].matchCards.some(
      (card) => card.period !== 'FULL_TIME' && !STALLED_PERIODS.has(card.period),
    );
    if (hasOpenMatch) return i;
  }
  return lists.length - 1;
}

export function buildCurrentRoundPayload(lists: OneFootballMatchList[], offset: number, competitionName: string) {
  const targetIndex = pickCurrentRoundIndex(lists) + offset;
  const target = lists[targetIndex] ?? null;
  return {
    competition: { name: competitionName, season: null },
    round: { number: null, label: target?.sectionHeader?.subtitle ?? null },
    matches: (target?.matchCards ?? []).map((card) => normalizeOneFootballMatchCard(card)),
    hasPrevious: targetIndex > 0,
    hasNext: targetIndex >= 0 && targetIndex < lists.length - 1,
  };
}

/** Uma busca só gera o snapshot de TODA rodada (chave `offset:N`, N relativo
 * à rodada atual) — o app navega entre rodadas sem nova ida ao provider. */
export async function buildCurrentRoundSnapshots(club: ClubServerConfig): Promise<Map<number, unknown>> {
  const lists = await fetchCompetitionMatchLists(club.primaryCompetitionSlug);
  const current = pickCurrentRoundIndex(lists);
  const out = new Map<number, unknown>();
  if (lists.length === 0) {
    out.set(0, buildCurrentRoundPayload(lists, 0, club.primaryCompetitionDisplayName));
    return out;
  }
  for (let i = 0; i < lists.length; i++) {
    out.set(i - current, buildCurrentRoundPayload(lists, i - current, club.primaryCompetitionDisplayName));
  }
  return out;
}

// ---- standings ----

type Entry = ReturnType<typeof normalizeStandingEntry>;
type StageOut = {
  id: string;
  name: string;
  order: number;
  type: 'LEAGUE_TABLE' | 'GROUP_STAGE' | 'KNOCKOUT';
  status: 'UPCOMING' | 'ACTIVE' | 'COMPLETED';
  isCurrent: boolean;
  standings: Entry[];
  groups: { title: string; standings: Entry[] }[];
  rounds: KnockoutRoundOut[];
};

function knockoutStage(rounds: KnockoutRoundOut[], order: number): StageOut {
  return {
    id: 'knockout',
    name: 'Eliminatórias',
    order,
    type: 'KNOCKOUT',
    status: 'ACTIVE',
    isCurrent: true,
    standings: [],
    groups: [],
    rounds,
  };
}

/** `competitionId` = `'primary'` (competição principal do clube) ou um id do
 * catálogo global. Lança `ProviderError(404)` pra id desconhecido. */
export async function buildStandingsSnapshot(club: ClubServerConfig, competitionId: string) {
  const catalogEntry = competitionId !== 'primary' ? findCatalogCompetition(competitionId) : undefined;
  if (competitionId !== 'primary' && !catalogEntry) {
    throw new ProviderError('unknown competition id', 404, 'internal');
  }
  const id = catalogEntry?.id ?? 'primary';
  const competitionSlug = catalogEntry?.slug ?? club.primaryCompetitionSlug;
  const competitionName = catalogEntry?.name ?? club.primaryCompetitionDisplayName;
  const format = catalogEntry?.format ?? 'LEAGUE_TABLE';

  const logoUrl = await fetchCompetitionLogoUrl(competitionSlug);

  if (format === 'KNOCKOUT') {
    const lists = await fetchCompetitionMatchLists(competitionSlug);
    const rounds = buildKnockoutRounds(selectKnockoutSections(lists, null));
    const stages: StageOut[] = hasAnyDecidedMatch(rounds) ? [knockoutStage(rounds, 0)] : [];
    return {
      competition: { name: competitionName, season: null, format, logoUrl },
      standings: [],
      groups: [],
      dataGap: stages.length === 0,
      season: { id, label: competitionName, stages },
    };
  }

  const matchLists = await fetchCompetitionMatchLists(competitionSlug);
  const tableWindow = tableWindowFrom(matchLists);
  const knockoutRounds = buildKnockoutRounds(selectKnockoutSections(matchLists, tableWindow));
  const hasRealKnockout = hasAnyDecidedMatch(knockoutRounds);
  const tableIsCurrent = !hasRealKnockout;

  if (format === 'GROUP_STAGE') {
    const groups = await fetchCompetitionGroupStandings(competitionSlug);
    const normalizedGroups = groups.map((group) => ({
      title: group.title,
      standings: group.rows.map((row) => normalizeStandingEntry(row)),
    }));
    const groupsStage: StageOut = {
      id: 'main',
      name: hasRealKnockout ? 'Fase de Grupos' : competitionName,
      order: 0,
      type: 'GROUP_STAGE',
      status: tableIsCurrent ? 'ACTIVE' : 'COMPLETED',
      isCurrent: tableIsCurrent,
      standings: [],
      groups: normalizedGroups,
      rounds: [],
    };
    const stages: StageOut[] = hasRealKnockout ? [groupsStage, knockoutStage(knockoutRounds, 1)] : [groupsStage];
    return {
      competition: { name: competitionName, season: null, format, logoUrl },
      groups: normalizedGroups,
      season: { id, label: competitionName, stages },
    };
  }

  const rows = await fetchCompetitionStandings(competitionSlug);
  const standings = rows.map((row) => normalizeStandingEntry(row));
  const leagueStage: StageOut = {
    id: 'main',
    name: tableSectionLabel(matchLists) ?? competitionName,
    order: 0,
    type: 'LEAGUE_TABLE',
    status: tableIsCurrent ? 'ACTIVE' : 'COMPLETED',
    isCurrent: tableIsCurrent,
    standings,
    groups: [],
    rounds: [],
  };
  const stages: StageOut[] = hasRealKnockout ? [leagueStage, knockoutStage(knockoutRounds, 1)] : [leagueStage];
  return {
    competition: { name: competitionName, season: null, format, logoUrl },
    standings,
    season: { id, label: competitionName, stages },
  };
}

/** Ids de `standings` que valem refresh pro clube: a principal + as que ele disputa. */
export function standingsKeysForClub(club: ClubServerConfig): string[] {
  return ['primary', ...competitionIdsForClub(club.code)];
}

// ---- competitions (estático, sem provider) ----

export function buildCompetitionsSnapshot(club: ClubServerConfig) {
  const participating = new Set(competitionIdsForClub(club.code));
  return {
    competitions: GLOBAL_COMPETITION_CATALOG.map((c) => ({
      id: c.id,
      name: c.name,
      region: c.region,
      format: c.format,
      isClubParticipating: participating.has(c.id),
    })),
  };
}

// ---- fixture (detalhe: eventos/escalação/estatísticas) ----

/** `fixtureId` = `onef-<id>` (mesmo id que o app já usa). */
export async function buildFixtureSnapshot(fixtureId: string) {
  if (!fixtureId.startsWith('onef-')) throw new ProviderError('Id de partida inválido.', 400, 'internal');
  const matchId = fixtureId.slice('onef-'.length);
  const detail = await fetchMatchDetail(matchId);
  if (!detail) throw new ProviderError('Partida não encontrada.', 404, 'onefootball');
  return {
    competition: { name: detail.score.competition?.name ?? '', season: null },
    match: normalizeOneFootballMatchScore(matchId, detail.score, detail.stadium),
    events: detail.events.map(normalizeOneFootballMatchEvent),
    lineups: detail.lineup ? normalizeOneFootballMatchLineups(detail.lineup) : null,
    stats: detail.stats.map(normalizeOneFootballMatchStat),
  };
}

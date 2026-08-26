import { ProviderError } from '../_lib/providerError';

const PROVIDER = 'onefootball';
const BASE_URL = 'https://api.onefootball.com/web-experience/pt-br';

export interface OneFootballTeamRef {
  name: string;
  score?: string;
  imageObject: { path: string };
}

export interface OneFootballMatchCard {
  matchId: string;
  link: string;
  competitionName?: string;
  kickoff: string;
  period: string;
  homeTeam: OneFootballTeamRef;
  awayTeam: OneFootballTeamRef;
}

export interface OneFootballMatchList {
  matchCards: OneFootballMatchCard[];
  sectionHeader?: { title?: string; subtitle?: string };
}

export interface OneFootballMatchScore {
  kickoff: { utcTimestamp: string };
  period: string;
  homeTeam: { name: string; score: string; imageObject: { path: string } };
  awayTeam: { name: string; score: string; imageObject: { path: string } };
}

interface OneFootballMatchInfoEntry {
  title: string;
  subtitle?: string;
}

export interface OneFootballMatchEvent {
  teamSide?: string;
  name: string;
  timeline: string;
  goal?: { type?: string; scorer?: { name: string } };
  card?: { player?: { name: string } };
  substitution?: { playerIn?: { name: string }; playerOut?: { name: string } };
}

export interface OneFootballLineupPlayer {
  name: string;
  jerseyNumber: number;
  image: { path: string };
}

export interface OneFootballLineupRow {
  players: OneFootballLineupPlayer[];
}

export interface OneFootballTeamLineup {
  teamName: string;
  formation: { rows: OneFootballLineupRow[] };
}

export interface OneFootballMatchLineup {
  homeTeam: OneFootballTeamLineup;
  awayTeam: OneFootballTeamLineup;
}

export interface OneFootballMatchDetail {
  score: OneFootballMatchScore;
  stadium: string | null;
  events: OneFootballMatchEvent[];
  lineup: OneFootballMatchLineup | null;
}

export interface OneFootballStandingRow {
  position: number;
  teamName: string;
  imageObject: { path: string };
  playedMatchesCount: number;
  wonMatchesCount: number;
  drawnMatchesCount: number;
  lostMatchesCount: number;
  goalsDiff: number;
  points: number;
  teamPath: string;
}

/**
 * A resposta é uma árvore de "containers" tipados por `$case` (o mesmo
 * componente serve pra anúncio, título, tabs, lista de jogos etc.) — em vez
 * de modelar a árvore inteira, procura pela primeira ocorrência de uma
 * chave em qualquer profundidade. Funciona porque cada chave que usamos
 * (`matchCardsListsAppender`, `matchScore`, `matchInfo`) só aparece uma vez
 * por página.
 */
function findNode<T>(root: unknown, key: string): T | null {
  if (root === null || typeof root !== 'object') return null;
  if (Array.isArray(root)) {
    for (const item of root) {
      const found = findNode<T>(item, key);
      if (found !== null) return found;
    }
    return null;
  }
  const obj = root as Record<string, unknown>;
  if (key in obj) return obj[key] as T;
  for (const value of Object.values(obj)) {
    const found = findNode<T>(value, key);
    if (found !== null) return found;
  }
  return null;
}

async function getContainers(path: string): Promise<unknown> {
  let response: Response;
  try {
    response = await fetch(`${BASE_URL}/${path}`, {
      headers: { accept: 'application/json' },
    });
  } catch (err) {
    throw new ProviderError(
      `Não foi possível conectar ao OneFootball (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
  if (!response.ok) {
    throw new ProviderError(
      `OneFootball retornou status ${response.status}.`,
      response.status === 429 ? 429 : 502,
      PROVIDER,
    );
  }
  const data = (await response.json()) as { containers?: unknown };
  return data.containers ?? data;
}

/** `tab` é `jogos` (agenda futura) ou `resultados` (jogos já encerrados). */
export async function fetchTeamMatchLists(
  teamSlug: string,
  tab: 'jogos' | 'resultados',
): Promise<OneFootballMatchList[]> {
  try {
    const containers = await getContainers(`time/${teamSlug}/${tab}`);
    const appender = findNode<{ lists: OneFootballMatchList[] }>(containers, 'matchCardsListsAppender');
    return appender?.lists ?? [];
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar os jogos do time (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

/** Extrai o número da rodada de um subtitle tipo "Rodada 25" — `null`
 * quando não há dígito (a lista é mantida, só fica de fora da ordenação). */
export function roundNumberFromSubtitle(subtitle?: string): number | null {
  if (!subtitle) return null;
  const match = subtitle.match(/(\d+)/);
  return match ? Number.parseInt(match[1], 10) : null;
}

async function fetchCompetitionTab(
  competitionSlug: string,
  tab: 'jogos' | 'resultados',
): Promise<OneFootballMatchList[]> {
  const containers = await getContainers(`competicao/${competitionSlug}/${tab}`);
  const appender = findNode<{ lists: OneFootballMatchList[] }>(containers, 'matchCardsListsAppender');
  return appender?.lists ?? [];
}

/** Junta rodadas de várias origens numa lista única, em ordem crescente de
 * rodada. A rodada em andamento pode aparecer nas duas abas (parte já
 * encerrada em `resultados`, parte a jogar em `jogos`), então rodadas de
 * mesmo número viram uma só, com os jogos deduplicados por `matchId` e
 * ordenados por horário. Listas sem número de rodada vão pro fim, na ordem
 * em que chegaram. */
function mergeRoundLists(groups: OneFootballMatchList[][]): OneFootballMatchList[] {
  const byRound = new Map<
    number,
    { subtitle?: string; title?: string; cards: Map<string, OneFootballMatchCard> }
  >();
  const unnumbered: OneFootballMatchList[] = [];
  for (const group of groups) {
    for (const list of group) {
      const number = roundNumberFromSubtitle(list.sectionHeader?.subtitle);
      if (number == null) {
        unnumbered.push(list);
        continue;
      }
      let entry = byRound.get(number);
      if (!entry) {
        entry = {
          subtitle: list.sectionHeader?.subtitle,
          title: list.sectionHeader?.title,
          cards: new Map(),
        };
        byRound.set(number, entry);
      }
      for (const card of list.matchCards) entry.cards.set(card.matchId, card);
    }
  }
  const merged = [...byRound.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([, entry]) => ({
      sectionHeader: { title: entry.title, subtitle: entry.subtitle },
      matchCards: [...entry.cards.values()].sort((a, b) => a.kickoff.localeCompare(b.kickoff)),
    }));
  return [...merged, ...unnumbered];
}

/**
 * Jogos de TODOS os times da competição, agrupados por rodada e em ordem
 * crescente. O OneFootball separa em duas abas — `resultados` (rodadas já
 * encerradas, da mais recente pra mais antiga) e `jogos` (as próximas) — então
 * busca as duas e mescla; sem isso não dá pra ir pra rodadas passadas, que nem
 * aparecem em `jogos`. Se uma aba falhar (ex.: começo de temporada sem
 * resultados), usa a outra; só estoura se as duas falharem.
 */
export async function fetchCompetitionMatchLists(competitionSlug: string): Promise<OneFootballMatchList[]> {
  const [resultados, jogos] = await Promise.allSettled([
    fetchCompetitionTab(competitionSlug, 'resultados'),
    fetchCompetitionTab(competitionSlug, 'jogos'),
  ]);
  if (resultados.status === 'rejected' && jogos.status === 'rejected') {
    const reason = resultados.reason;
    if (reason instanceof ProviderError) throw reason;
    throw new ProviderError(
      `Não foi possível consultar a rodada atual (${reason instanceof Error ? reason.message : String(reason)}).`,
      502,
      PROVIDER,
    );
  }
  return mergeRoundLists([
    resultados.status === 'fulfilled' ? resultados.value : [],
    jogos.status === 'fulfilled' ? jogos.value : [],
  ]);
}

/** A tabela só traz saldo de gols, não gols pró/contra separados. */
export async function fetchCompetitionStandings(competitionSlug: string): Promise<OneFootballStandingRow[]> {
  try {
    const containers = await getContainers(`competicao/${competitionSlug}/tabela`);
    const standings = findNode<{ rows: OneFootballStandingRow[] }>(containers, 'standings');
    return standings?.rows ?? [];
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a classificação (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

/**
 * `matchInfo.entries` traz um item com `title: "Estádio"` quando o dado
 * existe (nem toda partida tem) — e o mesmo payload já traz
 * `matchEvents.events` (gols/cartões/substituições) e `matchLineup.lineup`
 * (só titulares — banco/técnico não aparecem em lugar nenhum do payload),
 * sem requisição extra.
 */
export async function fetchMatchDetail(matchId: string): Promise<OneFootballMatchDetail | null> {
  try {
    const containers = await getContainers(`match/${matchId}`);
    const score = findNode<OneFootballMatchScore>(containers, 'matchScore');
    if (!score) return null;
    const matchInfo = findNode<{ entries: OneFootballMatchInfoEntry[] }>(containers, 'matchInfo');
    const stadiumEntry = matchInfo?.entries.find((entry) => entry.title === 'Estádio');
    const matchEvents = findNode<{ events: OneFootballMatchEvent[] }>(containers, 'matchEvents');
    const matchLineup = findNode<{ lineup: OneFootballMatchLineup }>(containers, 'matchLineup');
    return {
      score,
      stadium: stadiumEntry?.subtitle ?? null,
      events: matchEvents?.events ?? [],
      lineup: matchLineup?.lineup ?? null,
    };
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a partida (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

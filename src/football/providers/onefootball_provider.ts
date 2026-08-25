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

export interface OneFootballMatchDetail {
  score: OneFootballMatchScore;
  stadium: string | null;
  events: OneFootballMatchEvent[];
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

/**
 * Jogos de TODOS os times da competição, agrupados por rodada —
 * `sectionHeader.subtitle` de cada lista vem como "Rodada N".
 */
export async function fetchCompetitionMatchLists(competitionSlug: string): Promise<OneFootballMatchList[]> {
  try {
    const containers = await getContainers(`competicao/${competitionSlug}/jogos`);
    const appender = findNode<{ lists: OneFootballMatchList[] }>(containers, 'matchCardsListsAppender');
    return appender?.lists ?? [];
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a rodada atual (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
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
 * `matchEvents.events` (gols/cartões/substituições), sem requisição extra.
 */
export async function fetchMatchDetail(matchId: string): Promise<OneFootballMatchDetail | null> {
  try {
    const containers = await getContainers(`match/${matchId}`);
    const score = findNode<OneFootballMatchScore>(containers, 'matchScore');
    if (!score) return null;
    const matchInfo = findNode<{ entries: OneFootballMatchInfoEntry[] }>(containers, 'matchInfo');
    const stadiumEntry = matchInfo?.entries.find((entry) => entry.title === 'Estádio');
    const matchEvents = findNode<{ events: OneFootballMatchEvent[] }>(containers, 'matchEvents');
    return { score, stadium: stadiumEntry?.subtitle ?? null, events: matchEvents?.events ?? [] };
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a partida (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

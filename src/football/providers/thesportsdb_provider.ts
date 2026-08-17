import { ProviderError } from '../_lib/providerError';

const PROVIDER = 'thesportsdb';
const BASE_URL = 'https://www.thesportsdb.com/api/v1/json';

/**
 * Key pública de teste do TheSportsDB (documentada oficialmente, o valor é
 * literalmente "3") — não é um segredo, por isso não precisa de secret do
 * Cloudflare. Free tier: resultados limitados, ~30 req/min.
 */
const FREE_TEST_KEY = '3';

export interface TheSportsDbEvent {
  idEvent: string;
  strHomeTeam: string;
  strAwayTeam: string;
  idHomeTeam: string;
  idAwayTeam: string;
  strHomeTeamBadge: string | null;
  strAwayTeamBadge: string | null;
  dateEventLocal: string | null;
  strTimeLocal: string | null;
  strVenue: string | null;
  strStatus: string | null;
  intHomeScore: string | null;
  intAwayScore: string | null;
  intRound: string | null;
  strLeague: string | null;
  strSeason: string | null;
}

interface EventsResponse {
  events: TheSportsDbEvent[] | null;
}

interface ResultsResponse {
  results: TheSportsDbEvent[] | null;
}

async function get<T>(path: string): Promise<T> {
  const response = await fetch(`${BASE_URL}/${FREE_TEST_KEY}/${path}`);
  if (!response.ok) {
    throw new ProviderError(`TheSportsDB retornou status ${response.status}.`, 502, PROVIDER);
  }
  return response.json() as Promise<T>;
}

export async function fetchTeamNextEvents(teamId: string): Promise<TheSportsDbEvent[]> {
  try {
    const data = await get<EventsResponse>(`eventsnext.php?id=${teamId}`);
    return data.events ?? [];
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar os próximos jogos (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

export async function fetchEventById(eventId: string): Promise<TheSportsDbEvent | null> {
  try {
    const data = await get<EventsResponse>(`lookupevent.php?id=${eventId}`);
    return data.events?.[0] ?? null;
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a partida (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

export async function fetchTeamLastEvents(teamId: string): Promise<TheSportsDbEvent[]> {
  try {
    const data = await get<ResultsResponse>(`eventslast.php?id=${teamId}`);
    return data.results ?? [];
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar os últimos resultados (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

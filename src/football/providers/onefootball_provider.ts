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
  /** Minuto em andamento pronto pra exibir (ex.: "37'", "45+2'") — só
   * presente enquanto a partida está ao vivo/intervalo. */
  timePeriod?: string;
  homeTeam: OneFootballTeamRef;
  awayTeam: OneFootballTeamRef;
}

export interface OneFootballMatchList {
  matchCards: OneFootballMatchCard[];
  sectionHeader?: { title?: string; subtitle?: string };
}

export interface OneFootballMatchScore {
  /** Confirmado ao vivo (GET .../match/<id>): o node `matchScore` já traz
   * a competição REAL dessa partida (ex.: um jogo de torneio continental
   * do RB Bragantino veio com `competition.name: "CONMEBOL Sudamericana"`)
   * — nunca assumir que toda partida é da competição principal do clube. */
  competition?: { name: string };
  kickoff: { utcTimestamp: string };
  period: string;
  /** Mesmo campo de `OneFootballMatchCard.timePeriod` — ver ali. */
  timePeriod?: string;
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

/** Uma linha de `matchStats` — `home`/`away` ficam ausentes quando a fonte
 * ainda não tem dado pra essa estatística (ex.: "chutes" no início do
 * jogo), nunca um 0 inventado. */
export interface OneFootballMatchStat {
  title: string;
  unit?: string;
  home?: number;
  away?: number;
}

export interface OneFootballMatchDetail {
  score: OneFootballMatchScore;
  stadium: string | null;
  events: OneFootballMatchEvent[];
  lineup: OneFootballMatchLineup | null;
  stats: OneFootballMatchStat[];
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

/**
 * Igual a `findNode`, mas coleta TODAS as ocorrências da chave (nunca para
 * na primeira) — não desce pra dentro de um nó já encontrado (o valor de
 * uma chave-alvo nunca contém outra ocorrência da mesma chave nas páginas
 * que já vimos, e descer criaria duplicata/nó parcial). Usada só quando a
 * mesma chave aparece mais de uma vez na árvore por design (um `standings`
 * por grupo numa competição com fase de grupos, ver
 * `fetchCompetitionGroupStandings`).
 */
function findAllNodes<T>(root: unknown, key: string): T[] {
  const results: T[] = [];
  const visit = (node: unknown) => {
    if (node === null || typeof node !== 'object') return;
    if (Array.isArray(node)) {
      for (const item of node) visit(item);
      return;
    }
    const obj = node as Record<string, unknown>;
    if (key in obj) {
      results.push(obj[key] as T);
      return;
    }
    for (const value of Object.values(obj)) visit(value);
  };
  visit(root);
  return results;
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

/** `tab` é `jogos` (agenda futura) ou `resultados` (jogos já encerrados).
 * `loadMore` pega a página do resto (mesma paginação `?loadmore=1` que
 * `fetchCompetitionTab` já usa pra competição — confirmado funcionando
 * igual pro endpoint de time: `time/<slug>/<tab>?loadmore=1` devolve o
 * payload achatado `{ lists: [...] }`, sem `containers`). */
export async function fetchTeamMatchLists(
  teamSlug: string,
  tab: 'jogos' | 'resultados',
  loadMore = false,
): Promise<OneFootballMatchList[]> {
  try {
    const suffix = loadMore ? '?loadmore=1' : '';
    const containers = await getContainers(`time/${teamSlug}/${tab}${suffix}`);
    const flatLists = (containers as { lists?: unknown } | null)?.lists;
    if (Array.isArray(flatLists)) return flatLists as OneFootballMatchList[];
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

/** Temporada inteira do time (todas as competições juntas, já que é "os
 * jogos desse time") — mesmas 4 páginas de `fetchCompetitionMatchLists`,
 * mas aqui cada lista já vem agrupada por MÊS pela própria OneFootball
 * (não por rodada), então não faz sentido reaproveitar `mergeRoundLists`
 * (tentaria extrair "rodada" de um subtitle tipo "outubro 2026" e erraria).
 * Só achata tudo e dedupe por `matchId` — quem agrupa por dia pro
 * calendário é o Flutter. Confirmado contra a API real (2026): as 4
 * páginas juntas cobrem de janeiro a novembro sem sobreposição nem buraco
 * perceptível. */
export async function fetchTeamSeasonMatchCards(teamSlug: string): Promise<OneFootballMatchCard[]> {
  const settled = await Promise.allSettled([
    fetchTeamMatchLists(teamSlug, 'resultados'),
    fetchTeamMatchLists(teamSlug, 'resultados', true),
    fetchTeamMatchLists(teamSlug, 'jogos'),
    fetchTeamMatchLists(teamSlug, 'jogos', true),
  ]);
  if (settled.every((result) => result.status === 'rejected')) {
    const reason = (settled[0] as PromiseRejectedResult).reason;
    if (reason instanceof ProviderError) throw reason;
    throw new ProviderError(
      `Não foi possível consultar a temporada do time (${reason instanceof Error ? reason.message : String(reason)}).`,
      502,
      PROVIDER,
    );
  }
  const byId = new Map<string, OneFootballMatchCard>();
  for (const result of settled) {
    if (result.status !== 'fulfilled') continue;
    for (const list of result.value) {
      for (const card of list.matchCards) byId.set(card.matchId, card);
    }
  }
  return [...byId.values()];
}

/** Extrai o número da rodada de um subtitle tipo "Rodada 25" — `null`
 * quando não há dígito (a lista é mantida, só fica de fora da ordenação). */
export function roundNumberFromSubtitle(subtitle?: string): number | null {
  if (!subtitle) return null;
  const match = subtitle.match(/(\d+)/);
  return match ? Number.parseInt(match[1], 10) : null;
}

/** Cada aba do OneFootball é paginada e só devolve uma janela: `resultados`
 * traz as últimas rodadas encerradas e `jogos` as próximas. O botão "Mostrar
 * todos" do site chama a MESMA URL com `?loadmore=1`, que devolve o restante
 * (resultados: rodadas mais antigas; jogos: rodadas mais distantes, incluindo
 * fases como "Repescagem"). As duas páginas são complementares, não
 * cumulativas — então pra cobrir a temporada inteira buscamos as duas de
 * cada aba. `loadMore` verdadeiro pega a página do resto.
 *
 * As duas páginas têm formatos DIFERENTES (confirmado contra a API real, não
 * só suposição): a base vem dentro da árvore de `containers` de sempre
 * (`containers[].../matchCardsListsAppender.lists`), mas `?loadmore=1`
 * devolve um payload achatado, só `{ lists: [...] }` no nível raiz, sem
 * `containers` nem `matchCardsListsAppender` nenhum. Sem tratar essa forma
 * separadamente, `findNode` nunca encontrava nada ali e a página do resto
 * sempre virava `[]` silenciosamente — não porque a API não tivesse dado (ela
 * tem, confirmado: ~21 rodadas passadas e ~12 futuras/repescagem numa consulta
 * real do Brasileirão Série B), mas porque o parser só sabia ler o formato da
 * primeira página. Era essa a causa real de só aparecerem poucas rodadas perto
 * da atual, não a suposição antiga de que a API só devolvia uma janela curta. */
async function fetchCompetitionTab(
  competitionSlug: string,
  tab: 'jogos' | 'resultados',
  loadMore = false,
): Promise<OneFootballMatchList[]> {
  const suffix = loadMore ? '?loadmore=1' : '';
  const containers = await getContainers(`competicao/${competitionSlug}/${tab}${suffix}`);
  const flatLists = (containers as { lists?: unknown } | null)?.lists;
  if (Array.isArray(flatLists)) return flatLists as OneFootballMatchList[];
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
  // 4 páginas: janela recente + resto de cada aba (ver fetchCompetitionTab).
  // Início de temporada pode não ter `resultados`/`?loadmore=1` — por isso
  // `allSettled`: basta UMA página vir pra montar a lista; só estoura se
  // todas falharem.
  const settled = await Promise.allSettled([
    fetchCompetitionTab(competitionSlug, 'resultados'),
    fetchCompetitionTab(competitionSlug, 'resultados', true),
    fetchCompetitionTab(competitionSlug, 'jogos'),
    fetchCompetitionTab(competitionSlug, 'jogos', true),
  ]);
  if (settled.every((result) => result.status === 'rejected')) {
    const reason = (settled[0] as PromiseRejectedResult).reason;
    if (reason instanceof ProviderError) throw reason;
    throw new ProviderError(
      `Não foi possível consultar a rodada atual (${reason instanceof Error ? reason.message : String(reason)}).`,
      502,
      PROVIDER,
    );
  }
  return mergeRoundLists(
    settled.map((result) => (result.status === 'fulfilled' ? result.value : [])),
  );
}

/** Escudo/logo da própria competição — `entityTitle.imageObject.path`, o
 * mesmo node que dá título à página (`tabela`, mas confirmado presente
 * também em `jogos`/`resultados`, inclusive competições só de mata-mata
 * como a Copa do Brasil, que não têm tabela de pontos mas têm a mesma
 * página). Puramente decorativo — nunca derruba a resposta inteira se
 * faltar ou a rede falhar aqui, só volta `null` (Flutter cai pro ícone
 * genérico). */
export async function fetchCompetitionLogoUrl(competitionSlug: string): Promise<string | null> {
  try {
    const containers = await getContainers(`competicao/${competitionSlug}/tabela`);
    const entityTitle = findNode<{ imageObject?: { path?: string } }>(containers, 'entityTitle');
    return entityTitle?.imageObject?.path ?? null;
  } catch {
    return null;
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

export interface OneFootballGroupStanding {
  title: string;
  rows: OneFootballStandingRow[];
}

/**
 * Competições com fase de grupos (confirmado ao vivo 2026-09-09:
 * `conmebol-sudamericana-102/tabela`) trazem VÁRIOS nós `standings` na
 * mesma página, um por grupo (`{title: "Grupo A", rows: [...]}`,
 * `"Grupo B"`...) — `findNode` (singular) só acharia o primeiro. Usada só
 * pra competições marcadas `GROUP_STAGE` na config; `LEAGUE_TABLE` continua
 * em `fetchCompetitionStandings` (um `standings` só, sem grupo).
 */
export async function fetchCompetitionGroupStandings(competitionSlug: string): Promise<OneFootballGroupStanding[]> {
  try {
    const containers = await getContainers(`competicao/${competitionSlug}/tabela`);
    return findAllNodes<OneFootballGroupStanding>(containers, 'standings').filter(
      (group) => Array.isArray(group.rows) && group.rows.length > 0,
    );
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a classificação por grupos (${err instanceof Error ? err.message : String(err)}).`,
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
    const matchStats = findNode<{ stats: OneFootballMatchStat[] }>(containers, 'matchStats');
    return {
      score,
      stadium: stadiumEntry?.subtitle ?? null,
      events: matchEvents?.events ?? [],
      lineup: matchLineup?.lineup ?? null,
      stats: matchStats?.stats ?? [],
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

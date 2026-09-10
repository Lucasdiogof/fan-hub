import type { OneFootballMatchCard, OneFootballMatchList } from '../providers/onefootball_provider';
import { mapOneFootballStatus } from '../normalize/onefootball_status_mapper';
import { normalizeTeamName } from '../normalize/team_name';
import { isKnockoutSection, parseSectionSubtitle } from './phase_name';

/**
 * Chaveamento real de mata-mata, construído a partir do MESMO endpoint que
 * `fetchCompetitionMatchLists` já usa pra rodada atual/calendário
 * (`competicao/<slug>/jogos` + `/resultados`) — nunca precisou de outro
 * endpoint nem payload novo (investigação 2026-09-10/11, Copa do Brasil +
 * CONMEBOL Sudamericana + UEFA Champions League, ver `phase_name.ts` pro
 * detalhe de cada string real observada).
 *
 * DESCOBERTA GENÉRICA (spec item 4/5, rearquitetura 2026-09-11): nada aqui
 * sabe o nome/slug de nenhuma competição específica. `selectKnockoutSections`
 * decide se existe uma fase de mata-mata usando só 2 sinais, os dois
 * extraídos do próprio payload:
 *   1. vocabulário controlado de nome de rodada (`phase_name.ts`);
 *   2. JANELA CRONOLÓGICA relativa à fase de tabela (liga/grupos) da MESMA
 *      resposta — essencial porque a palavra "Repescagem" aparece em duas
 *      competições com posições cronológicas OPOSTAS: na Sudamericana vem
 *      DEPOIS da fase de grupos (é mata-mata de verdade, dessa temporada);
 *      na Champions atual vem ANTES da fase de liga (é fase classificatória
 *      de uma etapa anterior à temporada corrente, não deve aparecer como
 *      "a fase eliminatória atual"). Sem esse filtro, a Champions ganharia
 *      um "Mata-mata" fantasma sempre que a UEFA reaproveitar nomes de fase
 *      classificatória parecidos com os de mata-mata.
 */

export type KnockoutLegType = 'SINGLE' | 'FIRST' | 'SECOND';

export interface KnockoutTeamOut {
  id: number;
  name: string;
  logo: string;
}

export interface KnockoutLegOut {
  legType: KnockoutLegType;
  kickoff: string;
  status: string;
  homeScore: number | null;
  awayScore: number | null;
}

export interface KnockoutTieOut {
  homeTeam: KnockoutTeamOut;
  awayTeam: KnockoutTeamOut;
  legs: KnockoutLegOut[];
  aggregateHome: number | null;
  aggregateAway: number | null;
  penaltyHome: number | null;
  penaltyAway: number | null;
}

export interface KnockoutRoundOut {
  id: string;
  name: string;
  order: number;
  status: 'UPCOMING' | 'ACTIVE' | 'COMPLETED';
  isCurrent: boolean;
  ties: KnockoutTieOut[];
}

/** `1863` embutido em `.../icons/teams/164/1863.png` — mesma extração de
 * `normalize/match.ts`, duplicada aqui (função pura, sem estado) pra não
 * criar um acoplamento desnecessário entre os dois módulos por uma linha. */
function teamIdFromCrest(path: string): number {
  const match = path.match(/\/teams\/\d+\/(\d+)\.\w+$/i);
  return match ? Number(match[1]) : 0;
}

function parseScore(score: string | undefined): number | null {
  if (!score || score === '-') return null;
  const parsed = Number(score);
  return Number.isNaN(parsed) ? null : parsed;
}

const LEG_ORDER: Record<KnockoutLegType, number> = { FIRST: 0, SINGLE: 0, SECOND: 1 };

/**
 * Pênaltis: NÃO encontrei, na investigação 2026-09-11, nenhuma partida real
 * acessível via `/jogos`, `/resultados` ou `match/<id>` (`matchScore`) que
 * tivesse ido a pênaltis pra confirmar o nome/formato do campo (nenhum dos
 * jogos de mata-mata reais observados — Copa do Brasil, Sudamericana — foi
 * decidido assim; todos os agregados encontrados terminaram sem empate).
 * `matchScore` real só confirmou `aggregatedScore` (usado abaixo), nunca um
 * campo de pênaltis. Por isso [penaltyHome]/[penaltyAway] SEMPRE saem
 * `null` aqui — nunca deduzidos de um agregado empatado, nunca um "vencedor
 * heurístico". Documentado também no relatório final; véu essa função como
 * o único lugar a atualizar se/quando uma partida real de pênaltis for
 * localizada.
 */
function extractPenalties(_legs: { card: OneFootballMatchCard }[]): {
  penaltyHome: number | null;
  penaltyAway: number | null;
} {
  return { penaltyHome: null, penaltyAway: null };
}

/**
 * Agregado calculado LOCALMENTE, somando o placar de cada perna — decisão
 * consciente (spec item 11), não esquecimento. A investigação 2026-09-11
 * confirmou que `matchScore` (endpoint de detalhe de UMA partida,
 * `match/<id>`) também expõe `aggregatedScore` já calculado pela própria
 * OneFootball, mas usar isso exigiria uma requisição EXTRA por confronto
 * (N ties = N requests) só pra pegar um número que já dá pra somar com o
 * dado que a lista de jogos/resultados já trouxe de graça. Trade-off
 * rejeitado (spec: "não introduza N+1 requests só pra buscar agregado").
 * Reavaliar isso SÓ se aparecer um caso real de regra de desempate que a
 * soma simples não capture (esta função não aplica gol fora de casa — spec
 * item 10 proíbe isso sem confirmação explícita do provider).
 */
function buildTie(cards: { leg: KnockoutLegType; card: OneFootballMatchCard }[]): KnockoutTieOut {
  const legs = [...cards].sort((a, b) => LEG_ORDER[a.leg] - LEG_ORDER[b.leg]);
  const firstCard = legs[0].card;
  const homeId = teamIdFromCrest(firstCard.homeTeam.imageObject.path);

  let aggregateHome = 0;
  let aggregateAway = 0;
  let hasAnyScore = false;

  const legsOut: KnockoutLegOut[] = legs.map(({ leg, card }) => {
    const homeScore = parseScore(card.homeTeam.score);
    const awayScore = parseScore(card.awayTeam.score);
    if (homeScore != null && awayScore != null) {
      hasAnyScore = true;
      const cardHomeId = teamIdFromCrest(card.homeTeam.imageObject.path);
      if (cardHomeId === homeId) {
        aggregateHome += homeScore;
        aggregateAway += awayScore;
      } else {
        // mandante trocou entre ida/volta (o normal) — soma invertido pro
        // lado certo do confronto, sempre relativo ao mandante do 1º jogo.
        aggregateHome += awayScore;
        aggregateAway += homeScore;
      }
    }
    return { legType: leg, kickoff: card.kickoff, status: mapOneFootballStatus(card.period), homeScore, awayScore };
  });

  const homeRef = firstCard.homeTeam;
  const awayRef = firstCard.awayTeam;
  const { penaltyHome, penaltyAway } = extractPenalties(legs);

  return {
    homeTeam: { id: homeId, name: normalizeTeamName(homeRef.name), logo: homeRef.imageObject.path },
    awayTeam: {
      id: teamIdFromCrest(awayRef.imageObject.path),
      name: normalizeTeamName(awayRef.name),
      logo: awayRef.imageObject.path,
    },
    legs: legsOut,
    aggregateHome: hasAnyScore ? aggregateHome : null,
    aggregateAway: hasAnyScore ? aggregateAway : null,
    penaltyHome,
    penaltyAway,
  };
}

/** Uma fase está "ativa" quando pelo menos um confronto dela ainda não
 * terminou (tem perna sem placar, ou `status` diferente de `finished`);
 * "completed" quando todas as pernas já têm placar; nunca hardcoded por
 * nome de fase. */
function statusOf(tie: KnockoutTieOut): 'UPCOMING' | 'ACTIVE' | 'COMPLETED' {
  const allFinished = tie.legs.every((leg) => leg.status === 'finished');
  if (allFinished) return 'COMPLETED';
  const noneStarted = tie.legs.every((leg) => leg.status === 'scheduled' || leg.status === 'postponed');
  return noneStarted ? 'UPCOMING' : 'ACTIVE';
}

function kickoffRange(cards: OneFootballMatchCard[]): { min: number; max: number } | null {
  let min = Number.POSITIVE_INFINITY;
  let max = Number.NEGATIVE_INFINITY;
  for (const card of cards) {
    const ms = Date.parse(card.kickoff);
    if (Number.isNaN(ms)) continue;
    if (ms < min) min = ms;
    if (ms > max) max = ms;
  }
  return Number.isFinite(min) ? { min, max } : null;
}

/**
 * Agrupa listas JÁ FILTRADAS como "de mata-mata" (ver `selectKnockoutSections`)
 * em fases (rodadas), cada uma com seus confrontos — nunca recebe uma lista
 * de fase de tabela aqui, quem filtra isso é a função de descoberta.
 */
/** OneFootball usa "Home"/"Guest" como nome literal do time em confrontos
 * futuros cujos participantes ainda não foram decididos (confirmado ao
 * vivo 2026-09-11: Repescagem da Série B, ainda sem os classificados do
 * 3º-6º/4º-5º lugar) — e reaproveita o MESMO escudo genérico pra qualquer
 * confronto TBD da rodada, então dois confrontos DIFERENTES (ex.: 3ºx6º e
 * 4ºx5º) vêm com `homeTeam`/`awayTeam` idênticos. Agrupar esses por
 * time (como faz `buildTie` pra confrontos decididos) fundiria as duas
 * pernas de UM confronto com as pernas do OUTRO confronto sem querer. */
function isPlaceholderTeamName(name: string): boolean {
  return name === 'Home' || name === 'Guest';
}

export function buildKnockoutRounds(lists: OneFootballMatchList[]): KnockoutRoundOut[] {
  const rounds = new Map<string, { leg: KnockoutLegType; card: OneFootballMatchCard }[]>();
  const seenMatchIds = new Set<string>();
  for (const list of lists) {
    const parsed = parseSectionSubtitle(list.sectionHeader?.subtitle);
    if (!parsed) continue;
    const bucket = rounds.get(parsed.round) ?? [];
    for (const card of list.matchCards) {
      // A rodada em andamento pode aparecer em `jogos` E `resultados` ao
      // mesmo tempo (mesmo fenômeno já documentado pra ligas em
      // `mergeRoundLists`) — sem dedupe aqui, o mesmo confronto vira 2
      // pernas idênticas e o agregado sai dobrado (confirmado ao vivo
      // 2026-09-11: Sudamericana Santos 2x0 Atlético-MG virava "4x0" na
      // tela porque o jogo aparecia em `jogos` e `resultados` ao mesmo
      // tempo).
      if (seenMatchIds.has(card.matchId)) continue;
      seenMatchIds.add(card.matchId);
      bucket.push({ leg: parsed.leg, card });
    }
    rounds.set(parsed.round, bucket);
  }

  const built = [...rounds.entries()].map(([name, cards]) => {
    const tieMap = new Map<string, { leg: KnockoutLegType; card: OneFootballMatchCard }[]>();
    for (const entry of cards) {
      const { homeTeam, awayTeam } = entry.card;
      // Confronto TBD -> chave única por partida (nunca mesclado com
      // outro TBD da mesma rodada, ver `isPlaceholderTeamName` acima).
      // Confronto decidido -> chave por par de times, ida/volta com
      // mandante trocado ainda caem na mesma chave.
      const key =
        isPlaceholderTeamName(homeTeam.name) || isPlaceholderTeamName(awayTeam.name)
          ? `match-${entry.card.matchId}`
          : [teamIdFromCrest(homeTeam.imageObject.path), teamIdFromCrest(awayTeam.imageObject.path)]
              .sort((a, b) => a - b)
              .join('-');
      const bucket = tieMap.get(key) ?? [];
      bucket.push(entry);
      tieMap.set(key, bucket);
    }
    const ties = [...tieMap.values()].map(buildTie);
    const range = kickoffRange(cards.map((c) => c.card));
    return { name, ties, sortKey: range?.min ?? Number.POSITIVE_INFINITY };
  });

  built.sort((a, b) => a.sortKey - b.sortKey);

  const roundStatuses = built.map((round) =>
    round.ties.every((tie) => statusOf(tie) === 'COMPLETED')
      ? ('COMPLETED' as const)
      : round.ties.every((tie) => statusOf(tie) === 'UPCOMING')
        ? ('UPCOMING' as const)
        : ('ACTIVE' as const),
  );
  // Fase atual = a primeira que não está totalmente completa; se todas já
  // terminaram, a última (spec item 8: ativa > última com dado).
  let currentIndex = roundStatuses.findIndex((status) => status !== 'COMPLETED');
  if (currentIndex === -1) currentIndex = built.length - 1;

  return built.map((round, index) => ({
    id: `round-${index}`,
    name: round.name,
    order: index,
    status: roundStatuses[index],
    isCurrent: index === currentIndex,
    ties: round.ties,
  }));
}

/**
 * `false` quando TODOS os confrontos encontrados ainda são "Home"/"Guest"
 * (chaveamento existe no calendário, mas os classificados ainda não foram
 * decididos — ex.: Repescagem da Série B antes do fim da fase de pontos
 * corridos). Decisão do usuário 2026-09-11: enquanto a fase de mata-mata
 * não tiver NENHUM confronto real, nem mostra a aba — evita a confusão de
 * uma "Mata-mata" cheia de times "Home"/"Guest" pra uma competição que,
 * na prática, ainda está inteira na fase de tabela.
 */
export function hasAnyDecidedMatch(rounds: KnockoutRoundOut[]): boolean {
  return rounds.some((round) =>
    round.ties.some((tie) => !isPlaceholderTeamName(tie.homeTeam.name) && !isPlaceholderTeamName(tie.awayTeam.name)),
  );
}

export interface TableWindow {
  /** Nome real da fase de tabela encontrada na MESMA janela de jogos/
   * resultados (ex.: "Fase de liga") — `null` quando nenhuma seção de
   * tabela aparece na janela atual (ex.: Sudamericana, cuja fase de grupos
   * já saiu da paginação de `jogos`/`resultados` há meses). */
  earliestKickoffMs: number;
}

/**
 * Decide quais listas são REALMENTE a fase de mata-mata atual da temporada,
 * separando sinal (rodada eliminatória desta edição) de ruído (rodada
 * classificatória de uma etapa anterior que usa nome parecido — ver
 * cabeçalho do arquivo). Sem [tableWindow] (nenhuma fase de tabela visível
 * na janela atual — caso Sudamericana), aceita todas as seções
 * reconhecidas como mata-mata. Com [tableWindow], só aceita seções cuja
 * janela de jogos não termina inteiramente ANTES do início da fase de
 * tabela — isso é o que exclui a "Repescagem"/"3a Fase" pré-temporada da
 * Champions sem precisar saber que "Champions" existe.
 */
export function selectKnockoutSections(
  allLists: OneFootballMatchList[],
  tableWindow: TableWindow | null,
): OneFootballMatchList[] {
  return allLists.filter((list) => {
    const parsed = parseSectionSubtitle(list.sectionHeader?.subtitle);
    if (!parsed || !isKnockoutSection(parsed)) return false;
    if (!tableWindow) return true;
    const range = kickoffRange(list.matchCards);
    if (!range) return true;
    return range.max >= tableWindow.earliestKickoffMs;
  });
}

/** Extrai a janela de [TableWindow] das listas classificadas como fase de
 * tabela (nem knockout) na mesma resposta — `null` se nenhuma tiver jogo
 * com kickoff válido (não há fase de tabela visível nessa janela). */
export function tableWindowFrom(allLists: OneFootballMatchList[]): TableWindow | null {
  let earliest = Number.POSITIVE_INFINITY;
  for (const list of allLists) {
    const parsed = parseSectionSubtitle(list.sectionHeader?.subtitle);
    if (!parsed || isKnockoutSection(parsed)) continue;
    const range = kickoffRange(list.matchCards);
    if (range && range.min < earliest) earliest = range.min;
  }
  return Number.isFinite(earliest) ? { earliestKickoffMs: earliest } : null;
}

/** Nome real da(s) seção(ões) de fase de tabela encontrada(s) na janela
 * atual (ex.: "Fase de liga") — usado só como um label mais preciso que o
 * nome genérico da competição quando disponível; `null` quando nenhuma
 * seção de tabela aparece (a maioria dos casos hoje: ligas simples usam
 * "Rodada N", que não é um nome distintivo, e por isso não conta aqui). */
export function tableSectionLabel(allLists: OneFootballMatchList[]): string | null {
  for (const list of allLists) {
    const parsed = parseSectionSubtitle(list.sectionHeader?.subtitle);
    if (!parsed || isKnockoutSection(parsed)) continue;
    if (/^rodada\s+\d+$/i.test(parsed.round)) continue;
    return parsed.round;
  }
  return null;
}

import type {
  OneFootballLineupPlayer,
  OneFootballMatchCard,
  OneFootballMatchEvent,
  OneFootballMatchLineup,
  OneFootballMatchScore,
  OneFootballMatchStat,
  OneFootballStandingRow,
  OneFootballTeamLineup,
} from './provider.ts';

// Normalização OneFootball -> contrato estável do Fan-Hub (JSON idêntico ao
// que o Worker devolvia). Portado de src/football/normalize/*.ts.

// ---- team_name ----
/**
 * OneFootball às vezes acrescenta um desambiguador ao nome do time (ex.:
 * "SJ" de São João del-Rei, pra não confundir com outro "Athletic") que deixa
 * o nome longo demais pra UI. Mapa exato (nunca uma regra genérica de
 * "cortar a última palavra") — cada entrada precisa ser conferida antes de
 * entrar aqui, senão corre o risco de cortar um sufixo que faz parte do nome
 * de verdade de outro time (ex.: "... FC"/"... EC").
 */
const TEAM_NAME_OVERRIDES: Record<string, string> = {
  'Athletic Club SJ': 'Athletic Club',
};

export function normalizeTeamName(name: string): string {
  return TEAM_NAME_OVERRIDES[name] ?? name;
}

// ---- onefootball_status_mapper ----
/**
 * Só `PRE_MATCH` e `FULL_TIME` foram confirmados observando partidas reais
 * (nenhum jogo ao vivo do Goiás durante essa investigação) — os demais
 * são o vocabulário típico desse tipo de API, prováveis mas não
 * confirmados. Se o app mostrar "unknown" durante uma partida ao vivo,
 * comece por aqui.
 */
export function mapOneFootballStatus(period: string): string {
  switch (period) {
    case 'PRE_MATCH':
      return 'scheduled';
    case 'FULL_TIME':
      return 'finished';
    case 'FIRST_HALF':
    case 'SECOND_HALF':
    case 'EXTRA_TIME':
    case 'PENALTY_SHOOTOUT':
    case 'LIVE':
      return 'live';
    case 'HALF_TIME':
      return 'halftime';
    case 'POSTPONED':
      return 'postponed';
    case 'CANCELLED':
    case 'CANCELED':
      return 'cancelled';
    case 'SUSPENDED':
    case 'ABANDONED':
      return 'suspended';
    default:
      return 'unknown';
  }
}

// ---- match_lineup ----
export interface LineupPlayerJson {
  name: string;
  jerseyNumber: number;
  photo: string;
  /** ID do jogador no OneFootball (vínculo estável com o jogador real; o nome
   * varia). `null` quando o link não vem ou não tem o formato esperado.
   * Opcional no tipo: campo ADITIVO — clientes e fixtures antigos seguem válidos. */
  playerId?: number | null;
}

/** `/pt-br/jogador/tadeu-48597` -> `48597`. Só aceita o padrão `/jogador/<slug>-<id>`. */
export function playerIdFromLink(urlPath: string | undefined): number | null {
  const match = urlPath?.match(/\/jogador\/[^/?#]*-(\d+)\/?(?:[?#].*)?$/);
  return match ? Number(match[1]) : null;
}

export interface TeamLineupJson {
  teamName: string;
  rows: LineupPlayerJson[][];
}

export interface MatchLineupsJson {
  home: TeamLineupJson;
  away: TeamLineupJson;
}

function normalizePlayer(player: OneFootballLineupPlayer): LineupPlayerJson {
  return {
    name: player.name,
    jerseyNumber: player.jerseyNumber,
    photo: player.image?.path ?? '',
    playerId: playerIdFromLink(player.link?.urlPath),
  };
}

function normalizeTeamLineup(team: OneFootballTeamLineup): TeamLineupJson {
  return {
    teamName: team.teamName,
    rows: team.formation.rows.map((row) => row.players.map(normalizePlayer)),
  };
}

export function normalizeOneFootballMatchLineups(lineup: OneFootballMatchLineup): MatchLineupsJson {
  return {
    home: normalizeTeamLineup(lineup.homeTeam),
    away: normalizeTeamLineup(lineup.awayTeam),
  };
}

// ---- match_event ----
export interface MatchEventJson {
  minute: string;
  side: 'home' | 'away';
  type: 'goal' | 'yellow_card' | 'red_card' | 'substitution' | 'other';
  player: string | null;
  detail: string | null;
  /** Só em substituição, e só quando o provedor mandar o link do jogador (hoje não manda:
   * o evento traz apenas o nome). Aditivo — ausente/null = sem ID, o cliente cai no nome. */
  playerInId?: number | null;
  playerOutId?: number | null;
}

/**
 * `teamSide` some do JSON pro time da casa (codificação proto3 típica — o
 * valor padrão do enum não é serializado) — só aparece explícito como
 * "TEAM_SIDE_AWAY" pro visitante. Confirmado observando partidas reais.
 *
 * O tipo do evento é decidido pela CHAVE presente (`goal`/`card`/
 * `substitution`), não pelo rótulo em português (`name`) — mais estável.
 * Cor do cartão é a exceção: só existe como texto ("Cartão amarelo"/
 * "Cartão vermelho"), não há campo estruturado pra isso.
 */
export function normalizeOneFootballMatchEvent(event: OneFootballMatchEvent): MatchEventJson {
  const side = event.teamSide === 'TEAM_SIDE_AWAY' ? 'away' : 'home';
  const minute = event.timeline;

  if (event.goal) {
    const detail =
      event.goal.type === 'PENALTY_GOAL' ? 'Pênalti' : event.goal.type === 'OWN_GOAL' ? 'Contra' : null;
    return { minute, side, type: 'goal', player: event.goal.scorer?.name ?? null, detail };
  }

  if (event.card) {
    const isRed = /vermelho/i.test(event.name);
    return {
      minute,
      side,
      type: isRed ? 'red_card' : 'yellow_card',
      player: event.card.player?.name ?? null,
      detail: null,
    };
  }

  if (event.substitution) {
    return {
      minute,
      side,
      type: 'substitution',
      player: event.substitution.playerIn?.name ?? null,
      detail: event.substitution.playerOut?.name ?? null,
      playerInId: playerIdFromLink(event.substitution.playerIn?.link?.urlPath),
      playerOutId: playerIdFromLink(event.substitution.playerOut?.link?.urlPath),
    };
  }

  return { minute, side, type: 'other', player: null, detail: event.name };
}

// ---- match_stat ----
export interface MatchStatJson {
  title: string;
  unit: 'percent' | 'count';
  home: number | null;
  away: number | null;
}

/** `home`/`away` ficam `null` quando a fonte ainda não tem essa estatística
 * pra essa partida (comum bem no início do jogo) — nunca inventa um 0. */
export function normalizeOneFootballMatchStat(stat: OneFootballMatchStat): MatchStatJson {
  return {
    title: stat.title,
    unit: stat.unit === 'PERCENT' ? 'percent' : 'count',
    home: stat.home ?? null,
    away: stat.away ?? null,
  };
}

// ---- standing ----
/** `1863` embutido em `.../pt-br/time/goias-1863` — mesma ideia do id de
 * time extraído do escudo nas partidas, só que aqui vem do path do time. */
function extractTeamIdFromPath(teamPath: string): number {
  const match = teamPath.match(/-(\d+)$/);
  return match ? Number(match[1]) : 0;
}

/**
 * Entrada crua do OneFootball → JSON interno simples. M3.3: não decide mais
 * "é o clube ativo" aqui (era `isGoias`, calculado no servidor comparando
 * id) — essa comparação virou responsabilidade só do Flutter
 * (`Team.matchesClub(ClubConfig)`, mesma função usada em qualquer outro
 * lugar do app que precisa saber se um `Team` é o clube ativo). O Worker
 * devolve só o id do time; nunca mais precisa saber qual é "o clube ativo"
 * pra montar a classificação, então nunca fica desatualizado se um 2º clube
 * for registrado no futuro.
 *
 * Só saldo de gols, não gols pró/contra separados — é tudo que o
 * OneFootball dá, e é tudo que a UI já mostrava (coluna "SG").
 *
 * Observado em produção: pelo menos um time (saldo 0) veio sem a chave
 * `goalsDiff` de vez em quando — cada número aqui cai pra 0 se faltar, em
 * vez de deixar `undefined` vazar pro Flutter e quebrar o parse da lista
 * inteira por causa de uma linha.
 */
export function normalizeStandingEntry(entry: OneFootballStandingRow) {
  const teamId = extractTeamIdFromPath(entry.teamPath);
  return {
    position: entry.position,
    team: {
      id: teamId,
      name: normalizeTeamName(entry.teamName),
      shortName: null,
      logo: entry.imageObject.path,
    },
    points: entry.points ?? 0,
    played: entry.playedMatchesCount ?? 0,
    wins: entry.wonMatchesCount ?? 0,
    draws: entry.drawnMatchesCount ?? 0,
    losses: entry.lostMatchesCount ?? 0,
    goalDifference: entry.goalsDiff ?? 0,
    form: null,
  };
}

// ---- match ----
/**
 * Formato interno de partida — o Flutter nunca sabe de onde veio. `id`
 * carrega o prefixo `onef-` só pra `/fixtures/:id` saber que é do
 * OneFootball; fora isso é opaco pro app.
 *
 * `kickoff` é sempre string local do Brasil sem offset (ver
 * `utcToNaiveBrazilLocal` abaixo) — o resto do pipeline (Dart faz
 * `DateTime.parse` direto, sem `.toLocal()`) espera exatamente esse
 * formato.
 */
export interface InternalMatch {
  id: string;
  round: string | null;
  homeTeam: { id: number; name: string | null; shortName: string | null; logo: string | null };
  awayTeam: { id: number; name: string | null; shortName: string | null; logo: string | null };
  kickoff: string | null;
  venue: string | null;
  status: string;
  homeScore: number | null;
  awayScore: number | null;
  /** Minuto ao vivo pronto pra exibir (ex.: "37'"), vindo direto de
   * `timePeriod` — nunca calculado a partir do kickoff. `null` fora de
   * partida ao vivo/intervalo (a fonte só manda esse campo nesses casos). */
  minute: string | null;
}

/** OneFootball manda o horário em UTC de verdade (com `Z`) — converte pro
 * formato "local nu" (sem offset) que o resto do pipeline sempre esperou. */
function utcToNaiveBrazilLocal(utcIso: string): string {
  const utcMs = new Date(utcIso).getTime();
  const brazilMs = utcMs - 3 * 60 * 60 * 1000;
  return new Date(brazilMs).toISOString().replace('Z', '');
}

/** `1863` embutido em `.../icons/teams/164/1863.png` — o card de partida do
 * OneFootball não traz id de time em nenhum outro campo. */
function extractTeamIdFromCrest(path: string): number {
  const match = path.match(/\/teams\/\d+\/(\d+)\.\w+$/i);
  return match ? Number(match[1]) : 0;
}

function parseOneFootballScore(score: string | undefined): number | null {
  if (!score || score === '-') return null;
  const parsed = Number(score);
  return Number.isNaN(parsed) ? null : parsed;
}

export function normalizeOneFootballMatchCard(card: OneFootballMatchCard, venue: string | null = null): InternalMatch {
  return {
    id: `onef-${card.matchId}`,
    round: null,
    homeTeam: {
      id: extractTeamIdFromCrest(card.homeTeam.imageObject.path),
      name: normalizeTeamName(card.homeTeam.name),
      shortName: null,
      logo: card.homeTeam.imageObject.path,
    },
    awayTeam: {
      id: extractTeamIdFromCrest(card.awayTeam.imageObject.path),
      name: normalizeTeamName(card.awayTeam.name),
      shortName: null,
      logo: card.awayTeam.imageObject.path,
    },
    kickoff: utcToNaiveBrazilLocal(card.kickoff),
    venue,
    status: mapOneFootballStatus(card.period),
    homeScore: parseOneFootballScore(card.homeTeam.score),
    awayScore: parseOneFootballScore(card.awayTeam.score),
    minute: card.timePeriod ?? null,
  };
}

/** Mesma normalização acima, mas com a competição REAL dessa partida
 * específica anexada (`card.competitionName`, confirmado presente em todo
 * card real de `/time/<slug>/<tab>` — ver auditoria Matches/football
 * multiclube). Um time pode disputar várias competições ao mesmo tempo
 * (Brasileirão, Copa do Brasil, torneio continental...) — nunca rotular
 * TODOS os jogos do time com a competição principal do clube; o Flutter
 * (`MatchDto.toEntity`) já sabe preferir este campo por partida e só cair
 * pro nome de competição do nível da resposta quando ele vier `null`. */
export function normalizeOneFootballMatchCardWithCompetition(
  card: OneFootballMatchCard,
  venue: string | null = null,
): InternalMatch & { competition: string | null } {
  return {
    ...normalizeOneFootballMatchCard(card, venue),
    competition: card.competitionName ?? null,
  };
}

export function normalizeOneFootballMatchScore(
  matchId: string,
  score: OneFootballMatchScore,
  venue: string | null,
): InternalMatch {
  return {
    id: `onef-${matchId}`,
    round: null,
    homeTeam: {
      id: extractTeamIdFromCrest(score.homeTeam.imageObject.path),
      name: normalizeTeamName(score.homeTeam.name),
      shortName: null,
      logo: score.homeTeam.imageObject.path,
    },
    awayTeam: {
      id: extractTeamIdFromCrest(score.awayTeam.imageObject.path),
      name: normalizeTeamName(score.awayTeam.name),
      shortName: null,
      logo: score.awayTeam.imageObject.path,
    },
    kickoff: utcToNaiveBrazilLocal(score.kickoff.utcTimestamp),
    venue,
    status: mapOneFootballStatus(score.period),
    homeScore: parseOneFootballScore(score.homeTeam.score),
    awayScore: parseOneFootballScore(score.awayTeam.score),
    minute: score.timePeriod ?? null,
  };
}

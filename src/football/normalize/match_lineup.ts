import type {
  OneFootballLineupPlayer,
  OneFootballMatchLineup,
  OneFootballTeamLineup,
} from '../providers/onefootball_provider';

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

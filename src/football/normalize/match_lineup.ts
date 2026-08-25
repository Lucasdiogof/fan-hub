import type {
  OneFootballLineupPlayer,
  OneFootballMatchLineup,
  OneFootballTeamLineup,
} from '../providers/onefootball_provider';

export interface LineupPlayerJson {
  name: string;
  jerseyNumber: number;
  photo: string;
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

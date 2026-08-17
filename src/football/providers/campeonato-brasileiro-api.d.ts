// O pacote não publica tipos — declaro só o que a gente realmente usa.
declare module 'campeonato-brasileiro-api' {
  export interface RawTeam {
    id: number | null;
    name: string | null;
    shortName: string | null;
    badge: string | null;
  }

  export interface RawStandingEntry {
    position: number | null;
    team: RawTeam;
    points: number | null;
    matches: number | null;
    wins: number | null;
    draws: number | null;
    losses: number | null;
    goalsFor: number | null;
    goalsAgainst: number | null;
    goalDifference: number | null;
    recentForm: string[];
  }

  export interface RawTable {
    id: string;
    name: string;
    round: { number: number | null; total: number | null; label: string | null };
    entries: RawStandingEntry[];
  }

  export interface RawScore {
    home: number | null;
    away: number | null;
    penalties: { home: number | null; away: number | null } | null;
  }

  export interface RawMatch {
    id: number;
    round: number | null;
    totalRounds: number | null;
    dateTime: string | null;
    date: string | null;
    time: string | null;
    started: boolean;
    status: 'scheduled' | 'live' | 'finished' | string;
    statusCode: string | null;
    venue: string | null;
    homeTeam: RawTeam;
    awayTeam: RawTeam;
    score: RawScore;
  }

  export interface RawRound {
    id: string;
    groupId: string | number | null;
    groupName: string | null;
    number: number | null;
    total: number | null;
    label: string | null;
    matches: RawMatch[];
  }

  export interface RawCompetitionMeta {
    code: string;
    slug: string;
    name: string;
    season: number | null;
  }

  export interface RawCompetition {
    competition: RawCompetitionMeta;
    grouped: boolean;
    tables: RawTable[];
    rounds: RawRound[];
  }

  export function getCompetition(serie: string): Promise<RawCompetition>;
  export function getStandings(
    serie: string,
  ): Promise<{ competition: RawCompetitionMeta; tables: RawTable[] }>;
  export function getRounds(
    serie: string,
  ): Promise<{ competition: RawCompetitionMeta; grouped: boolean; rounds: RawRound[] }>;
}

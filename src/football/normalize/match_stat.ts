import type { OneFootballMatchStat } from '../providers/onefootball_provider';

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

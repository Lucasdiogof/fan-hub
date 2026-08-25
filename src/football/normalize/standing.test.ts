import { describe, expect, it } from 'vitest';
import { normalizeStandingEntry } from './standing';
import type { OneFootballStandingRow } from '../providers/onefootball_provider';

const goiasRow: OneFootballStandingRow = {
  position: 10,
  teamName: 'Goiás',
  imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1863.png' },
  playedMatchesCount: 24,
  wonMatchesCount: 9,
  drawnMatchesCount: 6,
  lostMatchesCount: 9,
  goalsDiff: -6,
  points: 33,
  teamPath: '/pt-br/time/goias-1863',
};

describe('normalizeStandingEntry', () => {
  it('extracts the team id from the trailing digits in teamPath', () => {
    const entry = normalizeStandingEntry(goiasRow, 1863);
    expect(entry.team.id).toBe(1863);
  });

  it('flags isGoias only when the extracted id matches the configured one', () => {
    expect(normalizeStandingEntry(goiasRow, 1863).isGoias).toBe(true);
    expect(normalizeStandingEntry(goiasRow, 999).isGoias).toBe(false);
    expect(normalizeStandingEntry(goiasRow, null).isGoias).toBe(false);
  });

  it('maps goalsDiff straight through as goalDifference — no goalsFor/goalsAgainst split available', () => {
    expect(normalizeStandingEntry(goiasRow, 1863).goalDifference).toBe(-6);
  });

  it('always sets form to null (OneFootball\'s table has no recent-results string)', () => {
    expect(normalizeStandingEntry(goiasRow, 1863).form).toBeNull();
  });
});

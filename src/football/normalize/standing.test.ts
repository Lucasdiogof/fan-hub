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
    const entry = normalizeStandingEntry(goiasRow);
    expect(entry.team.id).toBe(1863);
  });

  it('never decides "is the active club" server-side (M3.3: that comparison moved to Flutter, Team.matchesClub)', () => {
    const entry = normalizeStandingEntry(goiasRow);
    expect(entry).not.toHaveProperty('isGoias');
    expect(entry).not.toHaveProperty('isActiveClub');
  });

  it('maps goalsDiff straight through as goalDifference — no goalsFor/goalsAgainst split available', () => {
    expect(normalizeStandingEntry(goiasRow).goalDifference).toBe(-6);
  });

  it('always sets form to null (OneFootball\'s table has no recent-results string)', () => {
    expect(normalizeStandingEntry(goiasRow).form).toBeNull();
  });

  it('defaults any missing numeric field to 0 instead of leaking undefined — seen in production for one team', () => {
    const rowMissingGoalsDiff = { ...goiasRow };
    // @ts-expect-error simulating a field OneFootball actually omitted in production
    delete rowMissingGoalsDiff.goalsDiff;
    const entry = normalizeStandingEntry(rowMissingGoalsDiff);
    expect(entry.goalDifference).toBe(0);
  });
});

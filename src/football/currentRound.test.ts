import { describe, expect, it } from 'vitest';
import { pickCurrentRound } from './currentRound';
import type { OneFootballMatchCard, OneFootballMatchList } from './providers/onefootball_provider';

function card(period: string): OneFootballMatchCard {
  return {
    matchId: '1',
    link: '/pt-br/match/1',
    kickoff: '2026-01-01T00:00:00Z',
    period,
    homeTeam: { name: 'A', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
    awayTeam: { name: 'B', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
  };
}

function round(label: string, periods: string[]): OneFootballMatchList {
  return { matchCards: periods.map(card), sectionHeader: { subtitle: label } };
}

describe('pickCurrentRound', () => {
  it('picks the first round that still has an unfinished match', () => {
    const lists = [
      round('Rodada 24', ['FULL_TIME', 'FULL_TIME']),
      round('Rodada 25', ['FULL_TIME', 'PRE_MATCH']),
      round('Rodada 26', ['PRE_MATCH', 'PRE_MATCH']),
    ];
    expect(pickCurrentRound(lists)?.sectionHeader?.subtitle).toBe('Rodada 25');
  });

  it('falls back to the last round when every round is fully finished (end of season)', () => {
    const lists = [round('Rodada 24', ['FULL_TIME']), round('Rodada 25', ['FULL_TIME'])];
    expect(pickCurrentRound(lists)?.sectionHeader?.subtitle).toBe('Rodada 25');
  });

  it('picks the first round when every round is still upcoming (season not started)', () => {
    const lists = [round('Rodada 1', ['PRE_MATCH']), round('Rodada 2', ['PRE_MATCH'])];
    expect(pickCurrentRound(lists)?.sectionHeader?.subtitle).toBe('Rodada 1');
  });

  it('returns null for an empty list instead of throwing', () => {
    expect(pickCurrentRound([])).toBeNull();
  });
});

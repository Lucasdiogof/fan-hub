import { describe, expect, it } from 'vitest';
import { normalizeOneFootballMatchCard, normalizeOneFootballMatchScore } from './match';
import type { OneFootballMatchCard, OneFootballMatchScore } from '../providers/onefootball_provider';

const scheduledCard: OneFootballMatchCard = {
  matchId: '2669472',
  link: '/pt-br/match/2669472',
  competitionName: 'Brasileirão Série B Superbet',
  kickoff: '2026-08-28T22:30:00Z',
  period: 'PRE_MATCH',
  homeTeam: { name: 'Goiás', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1863.png' } },
  awayTeam: {
    name: 'São Bernardo FC',
    imageObject: { path: 'https://images.onefootball.com/icons/teams/164/4728.png' },
  },
};

const finishedCard: OneFootballMatchCard = {
  matchId: '2669470',
  link: '/pt-br/match/2669470',
  kickoff: '2026-08-22T21:30:00Z',
  period: 'FULL_TIME',
  homeTeam: {
    name: 'Cuiabá',
    score: '1',
    imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2704.png' },
  },
  awayTeam: {
    name: 'Goiás',
    score: '1',
    imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1863.png' },
  },
};

describe('normalizeOneFootballMatchCard', () => {
  it('extracts the team id embedded in the crest URL', () => {
    const match = normalizeOneFootballMatchCard(scheduledCard);
    expect(match.homeTeam.id).toBe(1863);
    expect(match.awayTeam.id).toBe(4728);
  });

  it('converts the UTC kickoff to naive Brazil-local (UTC-3), matching what the rest of the pipeline expects', () => {
    const match = normalizeOneFootballMatchCard(scheduledCard);
    expect(match.kickoff).toBe('2026-08-28T19:30:00.000');
  });

  it('prefixes the id with onef- and leaves round null (OneFootball has no round concept)', () => {
    const match = normalizeOneFootballMatchCard(scheduledCard);
    expect(match.id).toBe('onef-2669472');
    expect(match.round).toBeNull();
  });

  it('treats a missing score as null, not a parse error', () => {
    const match = normalizeOneFootballMatchCard(scheduledCard);
    expect(match.homeScore).toBeNull();
    expect(match.awayScore).toBeNull();
    expect(match.status).toBe('scheduled');
  });

  it('parses real scores on a finished match', () => {
    const match = normalizeOneFootballMatchCard(finishedCard);
    expect(match.homeScore).toBe(1);
    expect(match.awayScore).toBe(1);
    expect(match.status).toBe('finished');
  });

  it('passes through the venue when supplied, defaults to null otherwise', () => {
    expect(normalizeOneFootballMatchCard(scheduledCard).venue).toBeNull();
    expect(normalizeOneFootballMatchCard(scheduledCard, 'Estádio de Hailé Pinheiro').venue).toBe(
      'Estádio de Hailé Pinheiro',
    );
  });
});

describe('normalizeOneFootballMatchScore', () => {
  const score: OneFootballMatchScore = {
    kickoff: { utcTimestamp: '2026-08-28T22:30:00Z' },
    period: 'PRE_MATCH',
    homeTeam: { name: 'Goiás', score: '-', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1863.png' } },
    awayTeam: {
      name: 'São Bernardo FC',
      score: '-',
      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/4728.png' },
    },
  };

  it('treats "-" (OneFootball\'s placeholder for an unplayed match) as null, not a literal score', () => {
    const match = normalizeOneFootballMatchScore('2669472', score, 'Estádio de Hailé Pinheiro');
    expect(match.homeScore).toBeNull();
    expect(match.awayScore).toBeNull();
    expect(match.id).toBe('onef-2669472');
    expect(match.venue).toBe('Estádio de Hailé Pinheiro');
  });
});

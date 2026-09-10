import { describe, expect, it } from 'vitest';
import { loadConfig } from './config';
import type { Env } from './config';

function fakeEnv(overrides: Partial<Env> = {}): Env {
  return {
    CLUB_CODE: 'bragantino',
    TEAM_ONEFOOTBALL_SLUG: 'rb-bragantino-4734',
    PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
    PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
    CACHE_VERSION: 'test',
    ASSETS: {} as Fetcher,
    ...overrides,
  };
}

describe('loadConfig', () => {
  it('carrega os campos básicos do Env', () => {
    const config = loadConfig(fakeEnv());
    expect(config.clubCode).toBe('bragantino');
    expect(config.teamOneFootballSlug).toBe('rb-bragantino-4734');
    expect(config.primaryCompetitionSlug).toBe('brasileirao-betano-16');
    expect(config.primaryCompetitionDisplayName).toBe('Brasileirão Série A');
  });

  it('CACHE_VERSION ausente cai em "1"', () => {
    const config = loadConfig(fakeEnv({ CACHE_VERSION: '' }));
    expect(config.cacheVersion).toBe('1');
  });
});

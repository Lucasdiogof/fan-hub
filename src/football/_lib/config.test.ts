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

describe('loadConfig — SECONDARY_COMPETITIONS (auditoria multi-competição 2026-09-09)', () => {
  it('ausente -> lista vazia, nunca lança (a maioria dos clubes só tem a principal)', () => {
    const config = loadConfig(fakeEnv());
    expect(config.secondaryCompetitions).toEqual([]);
  });

  it('JSON malformado -> lista vazia, nunca derruba o Worker', () => {
    const config = loadConfig(fakeEnv({ SECONDARY_COMPETITIONS: '{not valid json' }));
    expect(config.secondaryCompetitions).toEqual([]);
  });

  it('entrada sem "format" válido é descartada, o resto da lista sobrevive', () => {
    const config = loadConfig(
      fakeEnv({
        SECONDARY_COMPETITIONS: JSON.stringify([
          { id: 'sudamericana', name: 'CONMEBOL Sudamericana', slug: 'conmebol-sudamericana-102', format: 'GROUP_STAGE' },
          { id: 'quebrado', name: 'X', slug: 'x', format: 'BRACKET_INVENTADO' },
        ]),
      }),
    );
    expect(config.secondaryCompetitions).toEqual([
      { id: 'sudamericana', name: 'CONMEBOL Sudamericana', slug: 'conmebol-sudamericana-102', format: 'GROUP_STAGE' },
    ]);
  });

  it('confirmado real (Bragantino): CONMEBOL Sudamericana parseada certinho', () => {
    const config = loadConfig(
      fakeEnv({
        SECONDARY_COMPETITIONS:
          '[{"id":"sudamericana","name":"CONMEBOL Sudamericana","slug":"conmebol-sudamericana-102","format":"GROUP_STAGE"}]',
      }),
    );
    expect(config.secondaryCompetitions).toHaveLength(1);
    expect(config.secondaryCompetitions[0].slug).toBe('conmebol-sudamericana-102');
  });
});

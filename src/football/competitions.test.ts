import { describe, expect, it } from 'vitest';
import { handleCompetitions } from './competitions';
import type { Env } from './_lib/config';

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

describe('handleCompetitions', () => {
  it('clube só com a principal -> lista de 1 item, isPrimary true', async () => {
    const request = new Request('https://example.com/api/football/competitions?club=bragantino');
    const response = await handleCompetitions(request, fakeEnv());
    const body = (await response.json()) as {
      competitions: Array<{ id: string; name: string; format: string; isPrimary: boolean }>;
    };

    expect(body.competitions).toEqual([
      { id: 'primary', name: 'Brasileirão Série A', format: 'LEAGUE_TABLE', isPrimary: true },
    ]);
  });

  it('Bragantino real: Série A + CONMEBOL Sudamericana, nesta ordem', async () => {
    const bragantinoEnv = fakeEnv({
      SECONDARY_COMPETITIONS:
        '[{"id":"sudamericana","name":"CONMEBOL Sudamericana","slug":"conmebol-sudamericana-102","format":"GROUP_STAGE"}]',
    });
    const request = new Request('https://example.com/api/football/competitions?club=bragantino');
    const response = await handleCompetitions(request, bragantinoEnv);
    const body = (await response.json()) as {
      competitions: Array<{ id: string; name: string; format: string; isPrimary: boolean }>;
    };

    expect(body.competitions).toEqual([
      { id: 'primary', name: 'Brasileirão Série A', format: 'LEAGUE_TABLE', isPrimary: true },
      { id: 'sudamericana', name: 'CONMEBOL Sudamericana', format: 'GROUP_STAGE', isPrimary: false },
    ]);
  });

  it('?club= de outro clube -> 404', async () => {
    const request = new Request('https://example.com/api/football/competitions?club=goias');
    const response = await handleCompetitions(request, fakeEnv());

    expect(response.status).toBe(404);
  });
});

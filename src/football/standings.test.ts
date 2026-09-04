import { afterEach, describe, expect, it, vi } from 'vitest';
import { handleStandings } from './standings';
import type { Env } from './_lib/config';

function fakeEnv(overrides: Partial<Env> = {}): Env {
  return {
    CLUB_CODE: 'goias',
    TEAM_ONEFOOTBALL_SLUG: 'goias-1863',
    PRIMARY_COMPETITION_SLUG: 'brasileirao-serie-b-superbet-119',
    PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série B',
    CACHE_VERSION: 'test',
    ASSETS: {} as Fetcher,
    ...overrides,
  };
}

function mockStandingsFetch(competitionSlug: string) {
  global.fetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input.toString();
    if (url.endsWith(`/competicao/${competitionSlug}/tabela`)) {
      return new Response(
        JSON.stringify({
          containers: [
            {
              component: {
                standings: {
                  rows: [
                    {
                      position: 1,
                      teamName: 'Time A',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' },
                      playedMatchesCount: 10,
                      wonMatchesCount: 8,
                      drawnMatchesCount: 1,
                      lostMatchesCount: 1,
                      goalsDiff: 12,
                      points: 25,
                      teamPath: '/pt-br/time/time-a-1',
                    },
                  ],
                },
              },
            },
          ],
        }),
        { status: 200 },
      );
    }
    throw new Error(`URL não mockada: ${url}`);
  }) as unknown as typeof fetch;
}

describe('handleStandings — SEMPRE a competição principal do deploy (operação legítima de PRIMARY COMPETITION)', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('Goiás: classificação continua "Brasileirão Série B"', async () => {
    mockStandingsFetch('brasileirao-serie-b-superbet-119');

    const request = new Request('https://example.com/api/football/standings?_t=goias');
    const response = await handleStandings(request, fakeEnv());
    const body = (await response.json()) as { competition: { name: string } };

    expect(body.competition.name).toBe('Brasileirão Série B');
  });

  it('Bragantino (fabricado): classificação continua "Brasileirão Série A"', async () => {
    mockStandingsFetch('brasileirao-betano-16');
    const bragantinoEnv = fakeEnv({
      CLUB_CODE: 'bragantino',
      TEAM_ONEFOOTBALL_SLUG: 'rb-bragantino-4734',
      PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
      PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
    });

    const request = new Request('https://example.com/api/football/standings?_t=bragantino');
    const response = await handleStandings(request, bragantinoEnv);
    const body = (await response.json()) as { competition: { name: string } };

    expect(body.competition.name).toBe('Brasileirão Série A');
  });
});

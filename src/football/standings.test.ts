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

describe('handleStandings — gate de ?club= (auditoria multi-competição 2026-09-09)', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('?club= de OUTRO clube -> 404, nunca a tabela deste deploy', async () => {
    mockStandingsFetch('brasileirao-serie-b-superbet-119');
    const request = new Request('https://example.com/api/football/standings?club=bragantino');
    const response = await handleStandings(request, fakeEnv());

    expect(response.status).toBe(404);
  });

  it('?club= do PRÓPRIO clube -> 200, comportamento normal', async () => {
    mockStandingsFetch('brasileirao-serie-b-superbet-119');
    const request = new Request('https://example.com/api/football/standings?club=goias');
    const response = await handleStandings(request, fakeEnv());

    expect(response.status).toBe(200);
  });

  it('sem ?club= nenhum -> 200, nunca quebra cliente antigo que ainda não manda o parâmetro', async () => {
    mockStandingsFetch('brasileirao-serie-b-superbet-119');
    const request = new Request('https://example.com/api/football/standings');
    const response = await handleStandings(request, fakeEnv());

    expect(response.status).toBe(200);
  });
});

describe('handleStandings — ?competition= (auditoria multi-competição 2026-09-09)', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  const bragantinoEnv = () =>
    fakeEnv({
      CLUB_CODE: 'bragantino',
      TEAM_ONEFOOTBALL_SLUG: 'rb-bragantino-4734',
      PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
      PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
      SECONDARY_COMPETITIONS:
        '[{"id":"sudamericana","name":"CONMEBOL Sudamericana","slug":"conmebol-sudamericana-102","format":"GROUP_STAGE"}]',
    });

  it('sem ?competition= (ou "primary") -> continua LEAGUE_TABLE da principal, mesma resposta de sempre', async () => {
    mockStandingsFetch('brasileirao-betano-16');
    const request = new Request('https://example.com/api/football/standings?club=bragantino');
    const response = await handleStandings(request, bragantinoEnv());
    const body = (await response.json()) as { competition: { name: string; format: string } };

    expect(body.competition).toEqual({ name: 'Brasileirão Série A', season: null, format: 'LEAGUE_TABLE' });
  });

  it('?competition=sudamericana -> GROUP_STAGE, vem em "groups" (nunca "standings" achatado)', async () => {
    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input.toString();
      if (url.endsWith('/competicao/conmebol-sudamericana-102/tabela')) {
        return new Response(
          JSON.stringify({
            containers: [
              {
                grid: {
                  items: [
                    {
                      components: [
                        {
                          standings: {
                            title: 'Grupo H',
                            rows: [
                              {
                                position: 2,
                                teamName: 'RB Bragantino',
                                imageObject: { path: 'https://images.onefootball.com/icons/teams/164/4734.png' },
                                playedMatchesCount: 6,
                                wonMatchesCount: 3,
                                drawnMatchesCount: 1,
                                lostMatchesCount: 2,
                                goalsDiff: 7,
                                points: 10,
                                teamPath: '/pt-br/time/rb-bragantino-4734',
                              },
                            ],
                          },
                        },
                      ],
                    },
                  ],
                },
              },
            ],
          }),
          { status: 200 },
        );
      }
      throw new Error(`URL não mockada: ${url}`);
    }) as unknown as typeof fetch;

    const request = new Request('https://example.com/api/football/standings?club=bragantino&competition=sudamericana');
    const response = await handleStandings(request, bragantinoEnv());
    const body = (await response.json()) as {
      competition: { name: string; format: string };
      groups: Array<{ title: string; standings: Array<{ team: { name: string } }> }>;
    };

    expect(body.competition).toEqual({ name: 'CONMEBOL Sudamericana', season: null, format: 'GROUP_STAGE' });
    expect(body.groups).toHaveLength(1);
    expect(body.groups[0].title).toBe('Grupo H');
    expect(body.groups[0].standings[0].team.name).toBe('RB Bragantino');
  });

  it('?competition= com id desconhecido -> 404, nunca inventa/cai pra principal silenciosamente', async () => {
    const request = new Request('https://example.com/api/football/standings?club=bragantino&competition=libertadores');
    const response = await handleStandings(request, bragantinoEnv());

    expect(response.status).toBe(404);
  });
});

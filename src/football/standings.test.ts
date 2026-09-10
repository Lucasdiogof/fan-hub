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
    // Desde 2026-09-11 toda LEAGUE_TABLE/GROUP_STAGE também busca
    // jogos/resultados pra descobrir uma eventual fase de mata-mata (ver
    // `standings.ts`) — sem nenhuma seção reconhecível aqui, o resultado é
    // sempre "sem mata-mata" (`tableWindowFrom`/`selectKnockoutSections`
    // devolvem vazio), que é o comportamento que estes testes esperam.
    if (url.includes(`/competicao/${competitionSlug}/jogos`) || url.includes(`/competicao/${competitionSlug}/resultados`)) {
      return new Response(JSON.stringify({ lists: [] }), { status: 200 });
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

describe('handleStandings — ?competition= resolve contra o catálogo GLOBAL (rearquitetura 2026-09-10)', () => {
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
      if (url.includes('/competicao/conmebol-sudamericana-102/jogos') || url.includes('/competicao/conmebol-sudamericana-102/resultados')) {
        return new Response(JSON.stringify({ lists: [] }), { status: 200 });
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
    const request = new Request('https://example.com/api/football/standings?club=bragantino&competition=id-que-nao-existe');
    const response = await handleStandings(request, bragantinoEnv());

    expect(response.status).toBe(404);
  });

  it('?competition=copa-do-brasil (KNOCKOUT) sem nenhuma fase reconhecível -> dataGap: true, nunca erro de rede nem tabela vazia sem explicação', async () => {
    global.fetch = vi.fn(async () => new Response(JSON.stringify({ containers: [] }), { status: 200 })) as unknown as typeof fetch;

    const request = new Request(
      'https://example.com/api/football/standings?club=bragantino&competition=copa-do-brasil&_t=empty',
    );
    const response = await handleStandings(request, bragantinoEnv());
    const body = (await response.json()) as {
      standings: unknown[];
      groups: unknown[];
      dataGap?: boolean;
      season: { stages: unknown[] };
    };

    expect(response.status).toBe(200);
    expect(body.dataGap).toBe(true);
    expect(body.standings).toEqual([]);
    expect(body.groups).toEqual([]);
    expect(body.season.stages).toEqual([]);
  });

  it('?competition=copa-do-brasil (KNOCKOUT) com chaveamento real -> season.stages traz as fases, nunca dataGap (2026-09-10)', async () => {
    const matchCard = (overrides: {
      matchId: string;
      home: { name: string; id: number; score?: string };
      away: { name: string; id: number; score?: string };
      kickoff: string;
      period: string;
    }) => ({
      matchId: overrides.matchId,
      link: `/pt-br/match/${overrides.matchId}`,
      kickoff: overrides.kickoff,
      period: overrides.period,
      homeTeam: {
        name: overrides.home.name,
        score: overrides.home.score,
        imageObject: { path: `https://images.onefootball.com/icons/teams/164/${overrides.home.id}.png` },
      },
      awayTeam: {
        name: overrides.away.name,
        score: overrides.away.score,
        imageObject: { path: `https://images.onefootball.com/icons/teams/164/${overrides.away.id}.png` },
      },
    });

    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input.toString();
      // `?loadmore=1` é a página do resto (ver `fetchCompetitionTab`) — sem
      // dado extra pra esse teste, devolve lista vazia pra não duplicar as
      // pernas já mockadas na página base.
      if (url.includes('loadmore=1')) {
        return new Response(JSON.stringify({ lists: [] }), { status: 200 });
      }
      if (url.includes('/competicao/copa-betano-do-brasil-137/resultados')) {
        return new Response(
          JSON.stringify({
            lists: [
              {
                sectionHeader: { subtitle: 'Semifinais - Jogo de ida' },
                matchCards: [
                  matchCard({
                    matchId: '1',
                    home: { name: 'Grêmio', id: 1670, score: '1' },
                    away: { name: 'Palmeiras', id: 1693, score: '0' },
                    kickoff: '2026-08-20T23:00:00Z',
                    period: 'FULL_TIME',
                  }),
                ],
              },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes('/competicao/copa-betano-do-brasil-137/jogos')) {
        return new Response(
          JSON.stringify({
            lists: [
              {
                sectionHeader: { subtitle: 'Semifinais - Jogo de volta' },
                matchCards: [
                  matchCard({
                    matchId: '2',
                    home: { name: 'Palmeiras', id: 1693, score: '1' },
                    away: { name: 'Grêmio', id: 1670, score: '0' },
                    kickoff: '2026-08-27T23:00:00Z',
                    period: 'FULL_TIME',
                  }),
                ],
              },
            ],
          }),
          { status: 200 },
        );
      }
      throw new Error(`URL não mockada: ${url}`);
    }) as unknown as typeof fetch;

    const request = new Request(
      'https://example.com/api/football/standings?club=bragantino&competition=copa-do-brasil&_t=bracket',
    );
    const response = await handleStandings(request, bragantinoEnv());
    const body = (await response.json()) as {
      dataGap?: boolean;
      season: {
        stages: Array<{
          name: string;
          isCurrent: boolean;
          rounds: Array<{
            name: string;
            isCurrent: boolean;
            ties: Array<{
              homeTeam: { name: string };
              awayTeam: { name: string };
              legs: unknown[];
              aggregateHome: number | null;
              aggregateAway: number | null;
              penaltyHome: number | null;
              penaltyAway: number | null;
            }>;
          }>;
        }>;
      };
    };

    expect(response.status).toBe(200);
    expect(body.dataGap).toBe(false);
    expect(body.season.stages).toHaveLength(1);
    const stage = body.season.stages[0];
    expect(stage.name).toBe('Mata-mata');
    expect(stage.isCurrent).toBe(true);
    expect(stage.rounds).toHaveLength(1);
    const round = stage.rounds[0];
    expect(round.name).toBe('Semifinais');
    expect(round.isCurrent).toBe(true);
    expect(round.ties).toHaveLength(1);
    expect(round.ties[0].legs).toHaveLength(2);
    // Agregado: Grêmio 1x0 na ida (mandante) + 0x1 fora na volta = 1x1.
    expect(round.ties[0].aggregateHome).toBe(1);
    expect(round.ties[0].aggregateAway).toBe(1);
    expect(round.ties[0].penaltyHome).toBeNull();
    expect(round.ties[0].penaltyAway).toBeNull();
  });

  it('Champions atual (Fase de liga, sem mata-mata ainda) -> UMA fase só, nenhum mata-mata inventado (spec 2026-09-11)', async () => {
    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input.toString();
      if (url.includes('loadmore=1')) {
        return new Response(JSON.stringify({ lists: [] }), { status: 200 });
      }
      if (url.endsWith('/competicao/uefa-liga-dos-campeoes-5/tabela')) {
        return new Response(
          JSON.stringify({
            containers: [
              {
                component: {
                  standings: {
                    rows: [
                      {
                        position: 1,
                        teamName: 'PSG',
                        imageObject: { path: 'https://images.onefootball.com/icons/teams/164/263.png' },
                        playedMatchesCount: 1,
                        wonMatchesCount: 1,
                        drawnMatchesCount: 0,
                        lostMatchesCount: 0,
                        goalsDiff: 5,
                        points: 3,
                        teamPath: '/pt-br/time/psg-263',
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
      if (url.includes('/competicao/uefa-liga-dos-campeoes-5/resultados')) {
        return new Response(
          JSON.stringify({
            lists: [
              {
                sectionHeader: { subtitle: '3a Fase - volta' },
                matchCards: [
                  {
                    matchId: 'q1',
                    link: '/pt-br/match/q1',
                    kickoff: '2026-08-11T15:00:00Z',
                    period: 'FULL_TIME',
                    homeTeam: {
                      name: 'X',
                      score: '1',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' },
                    },
                    awayTeam: {
                      name: 'Y',
                      score: '0',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' },
                    },
                  },
                ],
              },
              {
                sectionHeader: { subtitle: 'Fase de liga' },
                matchCards: [
                  {
                    matchId: 'l1',
                    link: '/pt-br/match/l1',
                    kickoff: '2026-09-08T16:45:00Z',
                    period: 'FULL_TIME',
                    homeTeam: {
                      name: 'PSG',
                      score: '4',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/263.png' },
                    },
                    awayTeam: {
                      name: 'Barcelona',
                      score: '1',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/5.png' },
                    },
                  },
                ],
              },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes('/competicao/uefa-liga-dos-campeoes-5/jogos')) {
        return new Response(JSON.stringify({ lists: [] }), { status: 200 });
      }
      throw new Error(`URL não mockada: ${url}`);
    }) as unknown as typeof fetch;

    const request = new Request(
      'https://example.com/api/football/standings?club=bragantino&competition=champions-league&_t=champions',
    );
    const response = await handleStandings(request, bragantinoEnv());
    const body = (await response.json()) as {
      season: { stages: Array<{ name: string; type: string; isCurrent: boolean; status: string }> };
    };

    expect(response.status).toBe(200);
    // Nunca inventa Mata-mata a partir da "3a Fase" classificatória, que
    // aconteceu ANTES da "Fase de liga" (ver knockout.test.ts) — só a fase
    // de tabela real aparece.
    expect(body.season.stages).toHaveLength(1);
    expect(body.season.stages[0].type).toBe('LEAGUE_TABLE');
    expect(body.season.stages[0].name).toBe('Fase de liga');
    expect(body.season.stages[0].isCurrent).toBe(true);
    expect(body.season.stages[0].status).toBe('ACTIVE');
  });

  it('Sudamericana no mata-mata (grupos fora da janela) -> híbrida: Fase de Grupos completed + Mata-mata active (spec 2026-09-11)', async () => {
    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input.toString();
      if (url.includes('loadmore=1')) {
        return new Response(JSON.stringify({ lists: [] }), { status: 200 });
      }
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
                                position: 1,
                                teamName: 'RB Bragantino',
                                imageObject: { path: 'https://images.onefootball.com/icons/teams/164/4734.png' },
                                playedMatchesCount: 6,
                                wonMatchesCount: 4,
                                drawnMatchesCount: 1,
                                lostMatchesCount: 1,
                                goalsDiff: 8,
                                points: 13,
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
      if (url.includes('/competicao/conmebol-sudamericana-102/resultados')) {
        return new Response(
          JSON.stringify({
            lists: [
              {
                sectionHeader: { subtitle: 'Oitavas de final - Jogo de ida' },
                matchCards: [
                  {
                    matchId: 'o1',
                    link: '/pt-br/match/o1',
                    kickoff: '2026-08-11T22:00:00Z',
                    period: 'FULL_TIME',
                    homeTeam: {
                      name: 'RB Bragantino',
                      score: '2',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/4734.png' },
                    },
                    awayTeam: {
                      name: 'Rival',
                      score: '1',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/999.png' },
                    },
                  },
                ],
              },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes('/competicao/conmebol-sudamericana-102/jogos')) {
        return new Response(
          JSON.stringify({
            lists: [
              {
                sectionHeader: { subtitle: 'Quartas de final - Jogo de ida' },
                matchCards: [
                  {
                    matchId: 'q1',
                    link: '/pt-br/match/q1',
                    kickoff: '2026-09-08T22:00:00Z',
                    period: 'PRE_MATCH',
                    homeTeam: {
                      name: 'RB Bragantino',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/4734.png' },
                    },
                    awayTeam: {
                      name: 'Outro Rival',
                      imageObject: { path: 'https://images.onefootball.com/icons/teams/164/998.png' },
                    },
                  },
                ],
              },
            ],
          }),
          { status: 200 },
        );
      }
      throw new Error(`URL não mockada: ${url}`);
    }) as unknown as typeof fetch;

    const request = new Request(
      'https://example.com/api/football/standings?club=bragantino&competition=sudamericana&_t=sudhybrid',
    );
    const response = await handleStandings(request, bragantinoEnv());
    const body = (await response.json()) as {
      season: {
        stages: Array<{
          name: string;
          type: string;
          status: string;
          isCurrent: boolean;
          groups?: Array<{ title: string }>;
          rounds?: Array<{ name: string; isCurrent: boolean }>;
        }>;
      };
    };

    expect(response.status).toBe(200);
    expect(body.season.stages).toHaveLength(2);
    const [groupsStage, knockout] = body.season.stages;
    expect(groupsStage.type).toBe('GROUP_STAGE');
    expect(groupsStage.status).toBe('COMPLETED');
    expect(groupsStage.isCurrent).toBe(false);
    expect(groupsStage.groups?.[0]?.title).toBe('Grupo H');
    expect(knockout.name).toBe('Mata-mata');
    expect(knockout.status).toBe('ACTIVE');
    expect(knockout.isCurrent).toBe(true);
    expect(knockout.rounds?.map((r) => r.name)).toEqual(['Oitavas de final', 'Quartas de final']);
    expect(knockout.rounds?.find((r) => r.name === 'Quartas de final')?.isCurrent).toBe(true);
  });
});

describe('handleStandings — consultar competição que o clube NÃO disputa é válido, não é cross-club fallback (spec item 21/23)', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('Worker do Goiás + club=goias + competition=bundesliga -> 200, tabela normal da Bundesliga', async () => {
    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input.toString();
      if (url.endsWith('/competicao/bundesliga-1/tabela')) {
        return new Response(
          JSON.stringify({
            containers: [
              {
                component: {
                  standings: {
                    rows: [
                      {
                        position: 1,
                        teamName: 'Bayern de Munique',
                        imageObject: { path: 'https://images.onefootball.com/icons/teams/164/13.png' },
                        playedMatchesCount: 5,
                        wonMatchesCount: 5,
                        drawnMatchesCount: 0,
                        lostMatchesCount: 0,
                        goalsDiff: 15,
                        points: 15,
                        teamPath: '/pt-br/time/bayern-13',
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
      if (url.includes('/competicao/bundesliga-1/jogos') || url.includes('/competicao/bundesliga-1/resultados')) {
        return new Response(JSON.stringify({ lists: [] }), { status: 200 });
      }
      throw new Error(`URL não mockada: ${url}`);
    }) as unknown as typeof fetch;

    const request = new Request('https://example.com/api/football/standings?club=goias&competition=bundesliga');
    const response = await handleStandings(request, fakeEnv({ CLUB_CODE: 'goias' }));
    const body = (await response.json()) as { competition: { name: string }; standings: Array<{ team: { name: string } }> };

    expect(response.status).toBe(200);
    expect(body.competition.name).toBe('Bundesliga');
    expect(body.standings[0].team.name).toBe('Bayern de Munique');
  });

  it('Worker do Goiás + club=bragantino (gate de flavor) -> continua 404, isso NÃO muda', async () => {
    const request = new Request('https://example.com/api/football/standings?club=bragantino&competition=bundesliga');
    const response = await handleStandings(request, fakeEnv({ CLUB_CODE: 'goias' }));

    expect(response.status).toBe(404);
  });
});

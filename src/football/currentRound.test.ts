import { afterEach, describe, expect, it, vi } from 'vitest';
import { handleCurrentRound, pickCurrentRound } from './currentRound';
import type { OneFootballMatchCard, OneFootballMatchList } from './providers/onefootball_provider';
import type { Env } from './_lib/config';

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

/** As 4 páginas que `fetchCompetitionMatchLists` busca em paralelo — vazias
 * por padrão, só a passada em `withData` (`resultados` sem loadmore) tem
 * conteúdo, já que `pickCurrentRoundIndex` só precisa de 1 rodada real. */
function mockCurrentRoundFetch(competitionSlug: string) {
  global.fetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input.toString();
    const base = `/competicao/${competitionSlug}`;
    if (url.endsWith(`${base}/resultados`)) {
      return new Response(
        JSON.stringify({
          containers: [
            {
              component: {
                matchCardsListsAppender: {
                  lists: [
                    {
                      sectionHeader: { subtitle: 'Rodada 1' },
                      matchCards: [
                        {
                          matchId: '1',
                          link: '/pt-br/match/1',
                          kickoff: '2026-01-01T00:00:00Z',
                          period: 'FULL_TIME',
                          homeTeam: { name: 'A', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
                          awayTeam: { name: 'B', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
                        },
                      ],
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
    if (url.endsWith('?loadmore=1') || url.endsWith(`${base}/jogos`)) {
      return new Response(JSON.stringify({ lists: [] }), { status: 200 });
    }
    throw new Error(`URL não mockada: ${url}`);
  }) as unknown as typeof fetch;
}

describe('handleCurrentRound — SEMPRE a competição principal do deploy (operação legítima de PRIMARY COMPETITION)', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('Goiás: rodada atual continua "Brasileirão Série B"', async () => {
    mockCurrentRoundFetch('brasileirao-serie-b-superbet-119');

    const request = new Request('https://example.com/api/football/current-round?_t=goias');
    const response = await handleCurrentRound(request, fakeEnv());
    const body = (await response.json()) as { competition: { name: string } };

    expect(body.competition.name).toBe('Brasileirão Série B');
  });

  it('Bragantino (fabricado): rodada atual continua "Brasileirão Série A"', async () => {
    mockCurrentRoundFetch('brasileirao-betano-16');
    const bragantinoEnv = fakeEnv({
      CLUB_CODE: 'bragantino',
      TEAM_ONEFOOTBALL_SLUG: 'rb-bragantino-4734',
      PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
      PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
    });

    const request = new Request('https://example.com/api/football/current-round?_t=bragantino');
    const response = await handleCurrentRound(request, bragantinoEnv);
    const body = (await response.json()) as { competition: { name: string } };

    expect(body.competition.name).toBe('Brasileirão Série A');
  });
});

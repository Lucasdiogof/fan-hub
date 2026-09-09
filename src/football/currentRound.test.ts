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

  it('REGRESSÃO 2026-09-09: jogo ADIADO nunca ancora a rodada atual (Bragantino tinha Atlético-MG adiado sem nova data preso na Rodada 21 de julho, escondendo a Rodada de setembro com o próximo jogo real, Botafogo)', () => {
    const lists = [
      round('Rodada 20', ['FULL_TIME', 'FULL_TIME']),
      round('Rodada 21', ['POSTPONED']),
      round('Rodada 22', ['FULL_TIME']),
      round('Rodada 23', ['PRE_MATCH']),
    ];
    expect(pickCurrentRound(lists)?.sectionHeader?.subtitle).toBe('Rodada 23');
  });

  it('CANCELLED/SUSPENDED/ABANDONED também nunca ancoram a rodada atual, mesmo padrão do adiado', () => {
    for (const period of ['CANCELLED', 'CANCELED', 'SUSPENDED', 'ABANDONED']) {
      const lists = [round('Rodada 1', [period]), round('Rodada 2', ['PRE_MATCH'])];
      expect(pickCurrentRound(lists)?.sectionHeader?.subtitle).toBe('Rodada 2');
    }
  });

  it('rodada só com jogo adiado no fim da temporada cai pra última rodada, não trava vazio', () => {
    const lists = [round('Rodada 1', ['FULL_TIME']), round('Rodada 2', ['POSTPONED'])];
    expect(pickCurrentRound(lists)?.sectionHeader?.subtitle).toBe('Rodada 2');
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

/** Mock com N rodadas reais (não só 1) — precisa pra provar que a
 * navegação cobre a TEMPORADA INTEIRA, não uma janela fixa. Achado
 * histórico do produto: a aba Jogos só deixava ver ~3 rodadas passadas +
 * atual + ~3 futuras — aqui provamos que `hasPrevious`/`hasNext` refletem
 * os limites REAIS da lista completa (`lists.length`), nunca um limite
 * artificial menor. */
function mockSeasonWithRounds(competitionSlug: string, roundCount: number, currentIndex: number) {
  const lists = Array.from({ length: roundCount }, (_, i) => ({
    sectionHeader: { subtitle: `Rodada ${i + 1}` },
    matchCards: [
      {
        matchId: String(i + 1),
        link: `/pt-br/match/${i + 1}`,
        kickoff: '2026-01-01T00:00:00Z',
        // Rodadas antes de `currentIndex` já terminaram; a de `currentIndex`
        // em diante ainda não -- reproduz exatamente o critério real de
        // `pickCurrentRoundIndex` (primeira rodada com jogo não-FULL_TIME).
        period: i < currentIndex ? 'FULL_TIME' : 'PRE_MATCH',
        homeTeam: { name: 'A', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
        awayTeam: { name: 'B', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
      },
    ],
  }));
  global.fetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input.toString();
    const base = `/competicao/${competitionSlug}`;
    if (url.endsWith(`${base}/resultados`)) {
      return new Response(JSON.stringify({ containers: [{ component: { matchCardsListsAppender: { lists } } }] }), { status: 200 });
    }
    if (url.endsWith('?loadmore=1') || url.endsWith(`${base}/jogos`)) {
      return new Response(JSON.stringify({ lists: [] }), { status: 200 });
    }
    throw new Error(`URL não mockada: ${url}`);
  }) as unknown as typeof fetch;
}

describe('handleCurrentRound — navegação cobre a TEMPORADA INTEIRA, nunca uma janela fixa (regressão do "3 anteriores + atual + 3 futuras")', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('temporada com 20 rodadas, atual = índice 10: consegue navegar até a Rodada 1 (10 offsets pra trás, muito além de "3 anteriores")', async () => {
    mockSeasonWithRounds('brasileirao-serie-b-superbet-119', 20, 10);
    for (let offset = 0; offset >= -10; offset--) {
      const request = new Request(`https://example.com/api/football/current-round?offset=${offset}&_t=back`);
      const response = await handleCurrentRound(request, fakeEnv());
      const body = (await response.json()) as { round: { label: string | null }; hasPrevious: boolean };
      expect(body.round.label).toBe(`Rodada ${10 + offset + 1}`);
      expect(body.hasPrevious).toBe(offset > -10);
    }
  });

  it('temporada com 20 rodadas, atual = índice 10: consegue navegar até a Rodada 20 (9 offsets pra frente, muito além de "3 futuras")', async () => {
    mockSeasonWithRounds('brasileirao-serie-b-superbet-119', 20, 10);
    for (let offset = 0; offset <= 9; offset++) {
      const request = new Request(`https://example.com/api/football/current-round?offset=${offset}&_t=fwd`);
      const response = await handleCurrentRound(request, fakeEnv());
      const body = (await response.json()) as { round: { label: string | null }; hasNext: boolean };
      expect(body.round.label).toBe(`Rodada ${10 + offset + 1}`);
      expect(body.hasNext).toBe(offset < 9);
    }
  });

  it('na primeira rodada da temporada, hasPrevious=false (nunca deixa navegar pra antes do início)', async () => {
    mockSeasonWithRounds('brasileirao-serie-b-superbet-119', 20, 0);
    const request = new Request('https://example.com/api/football/current-round?_t=first-round');
    const response = await handleCurrentRound(request, fakeEnv());
    const body = (await response.json()) as { hasPrevious: boolean; round: { label: string | null } };
    expect(body.round.label).toBe('Rodada 1');
    expect(body.hasPrevious).toBe(false);
  });

  it('na última rodada da temporada, hasNext=false (nunca deixa navegar pra depois do fim)', async () => {
    mockSeasonWithRounds('brasileirao-serie-b-superbet-119', 20, 19);
    const request = new Request('https://example.com/api/football/current-round?_t=last-round');
    const response = await handleCurrentRound(request, fakeEnv());
    const body = (await response.json()) as { hasNext: boolean; round: { label: string | null } };
    expect(body.round.label).toBe('Rodada 20');
    expect(body.hasNext).toBe(false);
  });

  it('offset além dos limites da lista (ex.: -100) nunca quebra a rota — target vira null, matches vazio', async () => {
    mockSeasonWithRounds('brasileirao-serie-b-superbet-119', 20, 10);
    const request = new Request('https://example.com/api/football/current-round?offset=-100&_t=out-of-range');
    const response = await handleCurrentRound(request, fakeEnv());
    const body = (await response.json()) as { matches: unknown[]; round: { label: string | null } };
    expect(body.matches).toEqual([]);
    expect(body.round.label).toBeNull();
  });
});

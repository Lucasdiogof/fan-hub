import { afterEach, describe, expect, it, vi } from 'vitest';
import { handleTeam } from './team';
import type { Env } from './_lib/config';

// FABRICADO — mesmo padrão de `club_server_config.test.ts`: `Env` construído
// à mão pra não depender de um Worker real no ar. `ASSETS` nunca é lido por
// `handleTeam`, só existe pra satisfazer o tipo.
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

function card(matchId: string, competitionName: string) {
  return {
    matchId,
    link: `/pt-br/match/${matchId}`,
    competitionName,
    kickoff: '2026-01-01T00:00:00Z',
    period: 'FULL_TIME',
    homeTeam: { name: 'A', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
    awayTeam: { name: 'B', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
  };
}

/** Mesma coisa, mas sem `competitionName` — simula o card real do
 * OneFootball quando esse campo (opcional na interface) não vem. */
function cardWithoutCompetition(matchId: string) {
  return {
    matchId,
    link: `/pt-br/match/${matchId}`,
    kickoff: '2026-01-01T00:00:00Z',
    period: 'FULL_TIME',
    homeTeam: { name: 'A', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
    awayTeam: { name: 'B', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
  };
}

function mockFetchByUrl(responses: Record<string, unknown>) {
  global.fetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input.toString();
    for (const [suffix, body] of Object.entries(responses)) {
      if (url.endsWith(suffix)) {
        return new Response(JSON.stringify(body), { status: 200 });
      }
    }
    // `fetchMatchDetail` (estádio do próximo jogo) não é o foco destes
    // testes — devolve "não encontrado" pra qualquer /match/<id> não mockado
    // explicitamente, em vez de estourar.
    if (url.includes('/match/')) {
      return new Response(JSON.stringify({ containers: [] }), { status: 200 });
    }
    throw new Error(`URL não mockada: ${url}`);
  }) as unknown as typeof fetch;
}

describe('handleTeam — competição por partida, nunca a principal do clube pra tudo', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it(
    'BUG PREVENIDO: jogo do Goiás na Copa do Brasil aparece como "Copa do Brasil", ' +
      'NUNCA como "Brasileirão Série B" (a competição principal)',
    async () => {
      mockFetchByUrl({
        '/time/goias-1863/jogos': {
          containers: [{ component: { matchCardsListsAppender: { lists: [] } } }],
        },
        '/time/goias-1863/resultados': {
          containers: [
            {
              component: {
                matchCardsListsAppender: {
                  lists: [{ matchCards: [card('copa-1', 'Copa do Brasil')] }],
                },
              },
            },
          ],
        },
      });

      const request = new Request('https://example.com/api/football/team/goias?_t=copa-do-brasil');
      const response = await handleTeam(request, fakeEnv(), 'goias');
      const body = (await response.json()) as {
        recentResults: Array<{ competition: string | null }>;
      };

      expect(body.recentResults).toHaveLength(1);
      expect(body.recentResults[0].competition).toBe('Copa do Brasil');
      expect(body.recentResults[0].competition).not.toBe('Brasileirão Série B');
    },
  );

  it(
    'FABRICADO (cenário do audit): RB Bragantino jogando CONMEBOL Sudamericana ' +
      'NUNCA aparece como "Brasileirão Série A"',
    async () => {
      const bragantinoEnv = fakeEnv({
        CLUB_CODE: 'bragantino',
        TEAM_ONEFOOTBALL_SLUG: 'rb-bragantino-4734',
        PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
        PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
      });
      mockFetchByUrl({
        '/time/rb-bragantino-4734/jogos': {
          containers: [{ component: { matchCardsListsAppender: { lists: [] } } }],
        },
        '/time/rb-bragantino-4734/resultados': {
          containers: [
            {
              component: {
                matchCardsListsAppender: {
                  lists: [{ matchCards: [card('sula-1', 'CONMEBOL Sudamericana')] }],
                },
              },
            },
          ],
        },
      });

      const request = new Request('https://example.com/api/football/team/bragantino?_t=sudamericana');
      const response = await handleTeam(request, bragantinoEnv, 'bragantino');
      const body = (await response.json()) as {
        recentResults: Array<{ competition: string | null }>;
      };

      expect(body.recentResults[0].competition).toBe('CONMEBOL Sudamericana');
      expect(body.recentResults[0].competition).not.toBe('Brasileirão Série A');
    },
  );

  it('lista com competições MISTAS: cada partida mantém a própria, nenhuma é "achatada" pra principal', async () => {
    mockFetchByUrl({
      '/time/goias-1863/jogos': {
        containers: [{ component: { matchCardsListsAppender: { lists: [] } } }],
      },
      '/time/goias-1863/resultados': {
        containers: [
          {
            component: {
              matchCardsListsAppender: {
                lists: [
                  {
                    matchCards: [
                      card('b-1', 'Brasileirão Série B'),
                      card('cb-1', 'Copa do Brasil'),
                      card('go-1', 'Goiano'),
                    ],
                  },
                ],
              },
            },
          },
        ],
      },
    });

    const request = new Request('https://example.com/api/football/team/goias?_t=mixed');
    const response = await handleTeam(request, fakeEnv(), 'goias');
    const body = (await response.json()) as {
      recentResults: Array<{ id: string; competition: string | null }>;
    };

    const byId = Object.fromEntries(body.recentResults.map((m) => [m.id, m.competition]));
    expect(byId['onef-b-1']).toBe('Brasileirão Série B');
    expect(byId['onef-cb-1']).toBe('Copa do Brasil');
    expect(byId['onef-go-1']).toBe('Goiano');
  });

  it(
    'REGRA ABSOLUTA (Goiás): card sem competitionName -> nome vazio/desconhecido, ' +
      'NUNCA "Brasileirão Série B" só por ser a competição principal',
    async () => {
      mockFetchByUrl({
        '/time/goias-1863/jogos': {
          containers: [{ component: { matchCardsListsAppender: { lists: [] } } }],
        },
        '/time/goias-1863/resultados': {
          containers: [
            {
              component: {
                matchCardsListsAppender: {
                  lists: [{ matchCards: [cardWithoutCompetition('sem-comp-1')] }],
                },
              },
            },
          ],
        },
      });

      const request = new Request('https://example.com/api/football/team/goias?_t=sem-competicao-goias');
      const response = await handleTeam(request, fakeEnv(), 'goias');
      const body = (await response.json()) as {
        competition: { name: string };
        recentResults: Array<{ competition: string | null }>;
      };

      expect(body.recentResults[0].competition).toBeNull();
      expect(body.competition.name).toBe('');
      expect(body.competition.name).not.toBe('Brasileirão Série B');
    },
  );

  it(
    'REGRA ABSOLUTA (Bragantino, fabricado): card sem competitionName -> nome vazio/desconhecido, ' +
      'NUNCA "Brasileirão Série A" só por ser a competição principal DESTE deploy',
    async () => {
      const bragantinoEnv = fakeEnv({
        CLUB_CODE: 'bragantino',
        TEAM_ONEFOOTBALL_SLUG: 'rb-bragantino-4734',
        PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
        PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
      });
      mockFetchByUrl({
        '/time/rb-bragantino-4734/jogos': {
          containers: [{ component: { matchCardsListsAppender: { lists: [] } } }],
        },
        '/time/rb-bragantino-4734/resultados': {
          containers: [
            {
              component: {
                matchCardsListsAppender: {
                  lists: [{ matchCards: [cardWithoutCompetition('sem-comp-2')] }],
                },
              },
            },
          ],
        },
      });

      const request = new Request('https://example.com/api/football/team/bragantino?_t=sem-competicao-bragantino');
      const response = await handleTeam(request, bragantinoEnv, 'bragantino');
      const body = (await response.json()) as {
        competition: { name: string };
        recentResults: Array<{ competition: string | null }>;
      };

      expect(body.recentResults[0].competition).toBeNull();
      expect(body.competition.name).toBe('');
      expect(body.competition.name).not.toBe('Brasileirão Série A');
    },
  );
});

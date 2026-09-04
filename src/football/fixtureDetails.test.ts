import { afterEach, describe, expect, it, vi } from 'vitest';
import { handleFixtureDetails } from './fixtureDetails';
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

function matchScore(competitionName: string | undefined) {
  return {
    ...(competitionName ? { competition: { name: competitionName } } : {}),
    kickoff: { utcTimestamp: '2026-01-01T00:00:00Z' },
    period: 'FULL_TIME',
    homeTeam: { name: 'A', score: '1', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
    awayTeam: { name: 'B', score: '0', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
  };
}

function mockMatchFetch(matchId: string, score: unknown) {
  global.fetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input.toString();
    if (url.endsWith(`/match/${matchId}`)) {
      return new Response(
        JSON.stringify({ containers: [{ component: { matchScore: score } }] }),
        { status: 200 },
      );
    }
    throw new Error(`URL não mockada: ${url}`);
  }) as unknown as typeof fetch;
}

describe('handleFixtureDetails — competição REAL da partida, nunca a principal do clube', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it(
    'BUG PREVENIDO: partida do Goiás pela Copa Verde aparece como "Copa Verde", ' +
      'NUNCA como "Brasileirão Série B"',
    async () => {
      mockMatchFetch('copaverde-1', matchScore('Copa Verde'));

      const request = new Request('https://example.com/api/football/fixtures/onef-copaverde-1');
      const response = await handleFixtureDetails(request, fakeEnv(), 'onef-copaverde-1');
      const body = (await response.json()) as { competition: { name: string } };

      expect(body.competition.name).toBe('Copa Verde');
      expect(body.competition.name).not.toBe('Brasileirão Série B');
    },
  );

  it(
    'FABRICADO (cenário do audit): partida do RB Bragantino pela CONMEBOL Sudamericana ' +
      'NUNCA aparece como "Brasileirão Série A"',
    async () => {
      mockMatchFetch('sula-2', matchScore('CONMEBOL Sudamericana'));
      const bragantinoEnv = fakeEnv({
        CLUB_CODE: 'bragantino',
        PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
        PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
      });

      const request = new Request('https://example.com/api/football/fixtures/onef-sula-2');
      const response = await handleFixtureDetails(request, bragantinoEnv, 'onef-sula-2');
      const body = (await response.json()) as { competition: { name: string } };

      expect(body.competition.name).toBe('CONMEBOL Sudamericana');
      expect(body.competition.name).not.toBe('Brasileirão Série A');
    },
  );

  it(
    'REGRA ABSOLUTA: sem competition no payload (caso raro) -> nome vazio/desconhecido, ' +
      'NUNCA a competição principal do clube (nem Goiás, nem Bragantino)',
    async () => {
      mockMatchFetch('sem-competicao-1', matchScore(undefined));

      const request = new Request('https://example.com/api/football/fixtures/onef-sem-competicao-1');
      const response = await handleFixtureDetails(request, fakeEnv(), 'onef-sem-competicao-1');
      const body = (await response.json()) as { competition: { name: string } };

      expect(body.competition.name).toBe('');
      expect(body.competition.name).not.toBe('Brasileirão Série B');
      expect(body.competition.name).not.toBe('Brasileirão Série A');
    },
  );

  it(
    'REGRA ABSOLUTA (Bragantino, fabricado): sem competition no payload -> nunca ' +
      '"Brasileirão Série A" só porque é a competição principal DESTE deploy',
    async () => {
      mockMatchFetch('bra-sem-competicao-1', matchScore(undefined));
      const bragantinoEnv = fakeEnv({
        CLUB_CODE: 'bragantino',
        PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
        PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
      });

      const request = new Request('https://example.com/api/football/fixtures/onef-bra-sem-competicao-1');
      const response = await handleFixtureDetails(request, bragantinoEnv, 'onef-bra-sem-competicao-1');
      const body = (await response.json()) as { competition: { name: string } };

      expect(body.competition.name).toBe('');
      expect(body.competition.name).not.toBe('Brasileirão Série A');
    },
  );

  it('id inválido (sem prefixo onef-) -> 400, nunca tenta resolver competição', async () => {
    const request = new Request('https://example.com/api/football/fixtures/xyz');
    const response = await handleFixtureDetails(request, fakeEnv(), 'xyz');
    expect(response.status).toBe(400);
  });
});

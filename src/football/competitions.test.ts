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

type CompetitionEntry = {
  id: string;
  name: string;
  region: string;
  format: string;
  isClubParticipating: boolean;
};

describe('handleCompetitions — catálogo GLOBAL (rearquitetura multi-competição 2026-09-10)', () => {
  it('devolve o catálogo INTEIRO, não só o que o clube disputa', async () => {
    const request = new Request('https://example.com/api/football/competitions?club=goias');
    const response = await handleCompetitions(request, fakeEnv({ CLUB_CODE: 'goias' }));
    const body = (await response.json()) as { competitions: CompetitionEntry[] };

    // Goiás só disputa a Série B, mas o catálogo continua trazendo TUDO —
    // Bundesliga/Champions/etc. incluídas, nunca escondidas por
    // participação (spec multi-competição, item 21).
    const ids = body.competitions.map((c) => c.id);
    expect(ids).toContain('bundesliga');
    expect(ids).toContain('champions-league');
    expect(ids).toContain('brasileirao-serie-b');
    expect(ids.length).toBeGreaterThanOrEqual(12);
  });

  it('Goiás: só Série B marcada isClubParticipating, resto false (Bundesliga inclusive)', async () => {
    const request = new Request('https://example.com/api/football/competitions?club=goias');
    const response = await handleCompetitions(request, fakeEnv({ CLUB_CODE: 'goias' }));
    const body = (await response.json()) as { competitions: CompetitionEntry[] };

    const serieB = body.competitions.find((c) => c.id === 'brasileirao-serie-b');
    const bundesliga = body.competitions.find((c) => c.id === 'bundesliga');
    expect(serieB?.isClubParticipating).toBe(true);
    expect(bundesliga?.isClubParticipating).toBe(false);
  });

  it('Bragantino: Série A e Sudamericana marcadas, resto false', async () => {
    const request = new Request('https://example.com/api/football/competitions?club=bragantino');
    const response = await handleCompetitions(request, fakeEnv());
    const body = (await response.json()) as { competitions: CompetitionEntry[] };

    const serieA = body.competitions.find((c) => c.id === 'brasileirao-serie-a');
    const sudamericana = body.competitions.find((c) => c.id === 'sudamericana');
    const serieB = body.competitions.find((c) => c.id === 'brasileirao-serie-b');
    expect(serieA?.isClubParticipating).toBe(true);
    expect(sudamericana?.isClubParticipating).toBe(true);
    expect(serieB?.isClubParticipating).toBe(false);
  });

  it('?club= de outro clube -> 404', async () => {
    const request = new Request('https://example.com/api/football/competitions?club=goias');
    const response = await handleCompetitions(request, fakeEnv());

    expect(response.status).toBe(404);
  });
});

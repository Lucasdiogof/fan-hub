import { afterEach, describe, expect, it, vi } from 'vitest';
import { PLACEHOLDER_SHA1, isPlaceholderPhoto, stripPlaceholderPhotos } from './lineupPhotos';
import { handleFixtureDetails } from './fixtureDetails';
import type { Env } from './_lib/config';

const BASE = 'https://images.onefootball.com/players/180';

// Bytes cujo SHA-1 começa com PLACEHOLDER_SHA1 não dá pra fabricar; o teste
// de "é placeholder" usa a imagem real do OneFootball quando acessível e, sem
// rede, cobre só os ramos que não dependem dela.
async function realPlaceholder(): Promise<ArrayBuffer | null> {
  try {
    const r = await fetch(`${BASE}/213759.jpg`);
    return r.status === 200 ? await r.arrayBuffer() : null;
  } catch {
    return null;
  }
}

describe('isPlaceholderPhoto', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('silhueta real do OneFootball (6004 B, hash conhecido) é placeholder', async () => {
    const bytes = await realPlaceholder();
    if (!bytes) return; // sem rede: não dá pra afirmar nada
    expect(bytes.byteLength).toBe(6004);
    global.fetch = vi.fn(async () => new Response(bytes, { status: 200 })) as unknown as typeof fetch;
    expect(await isPlaceholderPhoto(`${BASE}/t-placeholder-1.jpg`)).toBe(true);
    expect(PLACEHOLDER_SHA1).toHaveLength(8);
  });

  it('foto real (tamanho/hash diferentes) NÃO é placeholder', async () => {
    global.fetch = vi.fn(async () => new Response(new Uint8Array(9654), { status: 200 })) as unknown as typeof fetch;
    expect(await isPlaceholderPhoto(`${BASE}/t-real-1.jpg`)).toBe(false);
  });

  it('mesmo tamanho (6004 B) mas hash diferente NÃO é placeholder', async () => {
    global.fetch = vi.fn(async () => new Response(new Uint8Array(6004), { status: 200 })) as unknown as typeof fetch;
    expect(await isPlaceholderPhoto(`${BASE}/t-samesize-1.jpg`)).toBe(false);
  });

  it('erro de rede ou status != 200 mantém a foto', async () => {
    global.fetch = vi.fn(async () => {
      throw new Error('rede');
    }) as unknown as typeof fetch;
    expect(await isPlaceholderPhoto(`${BASE}/t-err-1.jpg`)).toBe(false);

    global.fetch = vi.fn(async () => new Response('x', { status: 503 })) as unknown as typeof fetch;
    expect(await isPlaceholderPhoto(`${BASE}/t-503-1.jpg`)).toBe(false);
  });

  it('host fora do OneFootball nunca é buscado', async () => {
    const spy = vi.fn();
    global.fetch = spy as unknown as typeof fetch;
    expect(await isPlaceholderPhoto('https://evil.example.com/players/1.jpg')).toBe(false);
    expect(spy).not.toHaveBeenCalled();
  });

  it('subrequests: 1 fetch por foto única e respeita o teto (nunca estoura o limite)', async () => {
    const spy = vi.fn(async () => new Response(new Uint8Array(10), { status: 200 }));
    global.fetch = spy as unknown as typeof fetch;
    const players = Array.from({ length: 60 }, (_, i) => ({ name: 'J' + i, jerseyNumber: i, photo: `${BASE}/cap-${i}.jpg` }));
    const dup = { name: 'D', jerseyNumber: 99, photo: `${BASE}/cap-0.jpg` };
    const out = await stripPlaceholderPhotos({
      home: { teamName: 'A', rows: [[...players, dup]] },
      away: { teamName: 'B', rows: [] },
    });
    expect(spy.mock.calls.length).toBeLessThanOrEqual(36);
    expect(out.home.rows[0]).toHaveLength(61);
    expect(out.home.rows[0][59].photo).toBe(`${BASE}/cap-59.jpg`);
  });
});

describe('stripPlaceholderPhotos', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('preserva nome, número e ordem; só limpa photo vazia/placeholder; não toca foto real', async () => {
    const placeholder = await realPlaceholder();
    if (!placeholder) return;
    global.fetch = vi.fn(async (input: RequestInfo | URL) =>
      String(input).includes('ph-')
        ? new Response(placeholder, { status: 200 })
        : new Response(new Uint8Array(9654), { status: 200 }),
    ) as unknown as typeof fetch;
    const out = await stripPlaceholderPhotos({
      home: {
        teamName: 'A',
        rows: [
          [{ name: 'Sem', jerseyNumber: 9, photo: `${BASE}/ph-1.jpg` }],
          [
            { name: 'Com', jerseyNumber: 10, photo: `${BASE}/real-1.jpg` },
            { name: 'Vazio', jerseyNumber: 7, photo: '' },
          ],
        ],
      },
      away: { teamName: 'B', rows: [] },
    });
    expect(out.home.rows[0][0]).toEqual({ name: 'Sem', jerseyNumber: 9, photo: '' });
    expect(out.home.rows[1][0].photo).toBe(`${BASE}/real-1.jpg`);
    expect(out.home.rows[1][1].photo).toBe('');
    expect(out.away.rows).toEqual([]);
  });
});

describe('handleFixtureDetails com escalação', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('erro ao checar foto nunca derruba o detalhe: foto é mantida', async () => {
    const env = {
      CLUB_CODE: 'goias',
      TEAM_ONEFOOTBALL_SLUG: 'goias-1863',
      PRIMARY_COMPETITION_SLUG: 'x',
      PRIMARY_COMPETITION_DISPLAY_NAME: 'x',
      CACHE_VERSION: 'photo-test',
      ASSETS: {} as Fetcher,
    } as Env;
    const photo = `${BASE}/t-handler-1.jpg`;
    const team = (n: string) => ({
      teamName: n,
      formation: { rows: [{ players: [{ name: 'J', jerseyNumber: 1, image: { path: photo } }] }] },
    });
    global.fetch = vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input);
      if (url.includes('/match/lp-1')) {
        return new Response(
          JSON.stringify({
            containers: [
              {
                matchScore: {
                  kickoff: { utcTimestamp: '2026-01-01T00:00:00Z' },
                  period: 'FULL_TIME',
                  homeTeam: { name: 'A', score: '1', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/1.png' } },
                  awayTeam: { name: 'B', score: '0', imageObject: { path: 'https://images.onefootball.com/icons/teams/164/2.png' } },
                },
                matchLineup: { lineup: { homeTeam: team('A'), awayTeam: team('B') } },
              },
            ],
          }),
          { status: 200 },
        );
      }
      throw new Error('rede');
    }) as unknown as typeof fetch;
    const res = await handleFixtureDetails(new Request('https://x.test/api/football/fixtures/onef-lp-1'), env, 'onef-lp-1');
    const body = (await res.json()) as { lineups: { home: { rows: { photo: string }[][] } } };
    expect(res.status).toBe(200);
    expect(body.lineups.home.rows[0][0].photo).toBe(photo);
  });
});

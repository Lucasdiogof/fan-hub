import { describe, expect, it, vi } from 'vitest';
import * as lineup from './lineup_photos';
import { collectImageUrls, imagePath, materializeImages, rewriteImageUrls, type ImageDeps } from './images';

const A = 'https://images.onefootball.com/icons/teams/164/1863.png';
const B = 'https://images.onefootball.com/players/180/123.jpg';
const COMP = 'https://images.onefootball.com/icons/leagueColoredCompetition/1.png';
const NEWS = 'https://images.onefootball.com/news/x.jpg'; // fora do escopo
const C = 'https://images.onefootball.com/icons/teams/164/4831.png';
const OUT = 'https://evil.example.com/x.png';
const BASE = 'https://proj.supabase.co/storage/v1/object/public/football-images';

function setup(opts: { existing?: string[]; respond?: (url: string) => Response } = {}) {
  const stored = new Map<string, ArrayBuffer>();
  const existing = new Set(opts.existing ?? []);
  const fetched: string[] = [];
  const deps: ImageDeps = {
    publicBase: BASE,
    fetch: (async (url: string) => {
      fetched.push(String(url));
      return opts.respond
        ? opts.respond(String(url))
        : new Response(new Uint8Array([1, 2, 3]), { headers: { 'content-type': 'image/png' } });
    }) as unknown as typeof fetch,
    storage: {
      exists: async (p) => existing.has(p) || stored.has(p),
      upload: async (p, bytes) => void stored.set(p, bytes),
    },
  };
  return { deps, stored, fetched };
}

describe('collect / path / rewrite', () => {
  it('coleta escudo, competição e jogador (host permitido), em qualquer profundidade', () => {
    const urls = collectImageUrls({ a: [A, { b: B, c: C, k: COMP }], c: OUT, d: 'texto', n: 3, w: NEWS });
    expect([...urls].sort()).toEqual([A, B, C, COMP].sort());
  });
  it('querystring/hash não mudam a chave (sem crescimento por URL variável)', async () => {
    expect(await imagePath(A + '?v=2#x')).toBe(await imagePath(A));
    expect(await imagePath(A + '?v=3')).toBe(await imagePath(A + '?v=4'));
  });
  it('path = categoria/sha256 estável + extensão; categorias não colidem', async () => {
    const p = await imagePath(A);
    expect(p).toMatch(/^teams\/[0-9a-f]{64}\.png$/);
    expect(await imagePath(A)).toBe(p);
    expect(await imagePath(B)).toMatch(/^players\/[0-9a-f]{64}\.jpg$/);
    expect(await imagePath(COMP)).toMatch(/^competitions\//);
    // mesmo nome de arquivo em categorias diferentes -> pastas diferentes
    expect(await imagePath('https://images.onefootball.com/players/1.png')).not.toBe(
      await imagePath('https://images.onefootball.com/icons/teams/1.png'),
    );
  });
  it('reescreve só o que está no mapa', () => {
    expect(rewriteImageUrls({ x: [A, OUT], y: 1 }, new Map([[A, 'N']]))).toEqual({ x: ['N', OUT], y: 1 });
  });
});

describe('materializeImages', () => {
  it('escudo, competição e jogador vão pro Storage; fora do escopo fica intacto', async () => {
    const { deps, stored, fetched } = setup();
    const out = await materializeImages({ logo: A, comp: COMP, photo: B, other: OUT, news: NEWS }, deps);
    expect(out.logo).toBe(BASE + '/' + (await imagePath(A)));
    expect(out.comp).toBe(BASE + '/' + (await imagePath(COMP)));
    expect(out.photo).toBe(BASE + '/' + (await imagePath(B)));
    expect(out.other).toBe(OUT);
    expect(out.news).toBe(NEWS);
    expect(stored.size).toBe(3);
    expect(fetched.sort()).toEqual([A, B, COMP].sort());
  });
  it('silhueta: NÃO vira foto no Storage, só um marcador; 1 download; 2ª execução e querystring = 0 download', async () => {
    vi.spyOn(lineup, 'isPlaceholderPhoto').mockResolvedValueOnce(true);
    const { deps, stored, fetched } = setup({
      respond: () => new Response(new Uint8Array(6004), { headers: { 'content-type': 'image/png' } }),
    });
    const out = await materializeImages({ photo: B }, deps);
    expect(out.photo).toBe('');
    expect([...stored.keys()]).toHaveLength(1);
    expect([...stored.keys()][0]).toMatch(/^markers\/[0-9a-f]{64}\.none$/);
    expect([...stored.keys()].some((k) => k.startsWith('players/'))).toBe(false);
    expect(fetched).toEqual([B]);
    // mesma URL (e com querystring diferente): decisão conhecida, sem novo download
    const again = await materializeImages({ a: B, b: B + '?v=9' }, deps);
    expect(again).toEqual({ a: '', b: '' });
    expect(fetched).toEqual([B]);
  });
  it('falha temporária de download NÃO vira cache negativo; URL nova do jogador é reavaliada', async () => {
    let fail = true;
    const { deps, stored } = setup({
      respond: () => {
        if (fail) throw new Error('rede');
        return new Response(new Uint8Array([1, 2]), { headers: { 'content-type': 'image/jpeg' } });
      },
    });
    expect(await materializeImages({ photo: B }, deps)).toEqual({ photo: B });
    expect(stored.size).toBe(0);
    fail = false;
    const ok = await materializeImages({ photo: B }, deps);
    expect(ok.photo).toBe(`${BASE}/${await imagePath(B)}`);
    const B2 = 'https://images.onefootball.com/players/180/999.jpg';
    expect((await materializeImages({ photo: B2 }, deps)).photo).toBe(`${BASE}/${await imagePath(B2)}`);
  });
  it('escudo legado na raiz do bucket é reaproveitado (sem baixar nem duplicar)', async () => {
    const legacy = (await imagePath(A)).split('/')[1];
    const { deps, fetched, stored } = setup({ existing: [legacy] });
    const out = await materializeImages({ logo: A }, deps);
    expect(out.logo).toBe(`${BASE}/${legacy}`);
    expect(fetched).toHaveLength(0);
    expect(stored.size).toBe(0);
  });
  it('sob o teto, escudo e competição têm prioridade sobre jogadores', async () => {
    const players = Array.from({ length: 70 }, (_, i) => `https://images.onefootball.com/players/180/${i}.jpg`);
    const { deps } = setup();
    const out = await materializeImages({ players, logo: A, comp: COMP }, deps);
    expect(out.logo.startsWith(BASE)).toBe(true);
    expect(out.comp.startsWith(BASE)).toBe(true);
    expect(out.players.filter((u) => u.startsWith(BASE))).toHaveLength(58);
  });
  it('mesma imagem com querystring diferente: 1 download, 1 arquivo, as duas URLs reescritas', async () => {
    const { deps, stored, fetched } = setup();
    const out = await materializeImages({ x: A + '?a=1', y: A + '?a=2' }, deps);
    expect(stored.size).toBe(1);
    expect(fetched).toEqual([A]);
    expect(out.x).toBe(out.y);
    expect(out.x.startsWith(BASE)).toBe(true);
  });
  it('escudo do próprio clube (skipTeamId) não é baixado: o app usa o asset oficial', async () => {
    const { deps, fetched } = setup();
    const out = await materializeImages({ own: A, rival: C }, { ...deps, skipTeamId: 1863 });
    expect(out.own).toBe(A);
    expect(out.rival).toBe(BASE + '/' + (await imagePath(C)));
    expect(fetched).toEqual([C]);
  });
  it('reaproveita o que já existe (não baixa de novo)', async () => {
    const { deps, fetched } = setup({ existing: [await imagePath(A)] });
    const out = await materializeImages({ logo: A }, deps);
    expect(out.logo).toBe(`${BASE}/${await imagePath(A)}`);
    expect(fetched).toHaveLength(0);
  });
  it('falha de rede / status ruim / não-imagem / vazio / grande: mantém a original', async () => {
    const cases: Record<string, (u: string) => Response> = {
      status: () => new Response('x', { status: 500, headers: { 'content-type': 'image/png' } }),
      html: () => new Response('<html>', { headers: { 'content-type': 'text/html' } }),
      empty: () => new Response(new Uint8Array(0), { headers: { 'content-type': 'image/png' } }),
      big: () => new Response(new Uint8Array(2 * 1024 * 1024 + 1), { headers: { 'content-type': 'image/png' } }),
      throws: () => {
        throw new Error('rede');
      },
    };
    for (const respond of Object.values(cases)) {
      const { deps, stored } = setup({ respond });
      expect(await materializeImages({ logo: A }, deps)).toEqual({ logo: A });
      expect(stored.size).toBe(0);
    }
  });
  it('falha de upload mantém a original e não lança', async () => {
    const { deps } = setup();
    deps.storage.upload = async () => {
      throw new Error('storage fora');
    };
    expect(await materializeImages({ logo: A }, deps)).toEqual({ logo: A });
  });
  it('teto por execução: o excedente fica com a URL original', async () => {
    const urls = Array.from({ length: 70 }, (_, i) => `https://images.onefootball.com/icons/teams/164/${i}.png`);
    const { deps, stored } = setup();
    const out = await materializeImages({ urls }, deps);
    expect(stored.size).toBe(60);
    expect(out.urls.filter((u) => u.startsWith(BASE))).toHaveLength(60);
    expect(out.urls.filter((u) => u.startsWith('https://images.onefootball.com'))).toHaveLength(10);
  });
  it('payload sem imagens volta idêntico', async () => {
    const { deps } = setup();
    const p = { a: 1 };
    expect(await materializeImages(p, deps)).toBe(p);
  });
});

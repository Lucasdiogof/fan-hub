import { describe, expect, it, vi } from 'vitest';
import { scrapeNewsArticle, scrapeNewsList } from '../../../../src/news/scraper';
import { parseBragantinoNewsList as oldBragantinoList } from '../../../../src/news/bragantino_parser';
import { parseVilaNovaNewsList as oldVilaList } from '../../../../src/news/vilanova_parser';
import { SERVER_CLUB_REGISTRY, resolveClubServerConfigByCode } from '../club_server_config';
import type { ImageDeps } from '../football/images';
import { getNewsArticle } from './article';
import { materializeCovers } from './images';
import { isAllowedHttpsUrl, parseNewsList, sanitizeBlocks } from './parsers';
import { refreshNews, type FailurePatch, type NewsRow, type NewsStore } from './refresh';
import type { NewsItem } from './types';
import goiasHtml from './__fixtures__/goias_list_2026-11-20.html?raw';
import goiasWorker from './__fixtures__/goias_worker_list_2026-11-20.json';
import vilaHtml from './__fixtures__/vilanova_list_2026-11-20.html?raw';
import bragRaw from './__fixtures__/bragantino_list_2026-11-20.json?raw';

const goias = resolveClubServerConfigByCode('goias')!;
const vila = resolveClubServerConfigByCode('vilanova')!;
const brag = resolveClubServerConfigByCode('bragantino')!;
const NOW = new Date('2026-11-21T12:00:00Z');

describe('parsers (fixtures reais sanitizadas, sem corpo de matéria)', () => {
  it('Goiás: 15 itens idênticos ao JSON que o Worker devolveu (id, título, data, url, imagem, categoria)', () => {
    const items = parseNewsList(goiasHtml, goias.news!);
    expect(items).toHaveLength(15);
    expect(items).toEqual(goiasWorker.items);
  });

  it('Goiás: paridade com o parser atual do Worker (HTMLRewriter) sobre o MESMO HTML', async () => {
    const old = await scrapeNewsList(goiasHtml, goias.news!.siteOrigin);
    expect(parseNewsList(goiasHtml, goias.news!)).toEqual(old);
  });

  it('Vila: 6 itens, categoria vazia, paridade com o parser atual', () => {
    const items = parseNewsList(vilaHtml, vila.news!);
    expect(items).toHaveLength(6);
    expect(items.every((i) => i.category === '' && i.publishedAt !== '' && i.imageUrl !== '')).toBe(true);
    expect(items).toEqual(oldVilaList(vilaHtml, vila.news!.siteOrigin));
  });

  it('Vila: dedupe de slug repetido', () => {
    const one = vilaHtml.match(/<a\s+href="[^"]*\/noticias\/[^"]+"\s+class="card-news">[\s\S]*?<\/a>/)![0];
    expect(parseNewsList(`${one}${one}`, vila.news!)).toHaveLength(1);
  });

  it('Bragantino: 20 itens, categoria vazia, data em horário do Brasil, paridade com o parser atual', () => {
    const items = parseNewsList(bragRaw, brag.news!);
    expect(items).toHaveLength(20);
    expect(items.every((i) => i.category === '')).toBe(true);
    expect(items).toEqual(oldBragantinoList(bragRaw));
    const raw = JSON.parse(bragRaw).data[0];
    const utc = new Date(raw.datePublished).getTime() - 3 * 3600 * 1000;
    expect(items[0].publishedAt).toBe(new Date(utc).toISOString().slice(0, 10));
  });

  it('lixo/HTML vazio vira lista vazia, sem lançar', () => {
    expect(parseNewsList('<html></html>', goias.news!)).toEqual([]);
    expect(parseNewsList('not json', brag.news!)).toEqual([]);
  });
});

describe('config única e isolamento de clube', () => {
  it('cada clube tem fonte própria e hosts que não se cruzam', () => {
    const hosts = SERVER_CLUB_REGISTRY.map((c) => [...c.news!.allowedHosts, ...c.news!.imageHosts]);
    const flat = hosts.flat();
    // Vila usa o mesmo host para página e imagem; fora isso nada se repete entre clubes.
    for (const c of SERVER_CLUB_REGISTRY) {
      for (const other of SERVER_CLUB_REGISTRY.filter((o) => o !== c)) {
        expect(c.news!.allowedHosts.some((h) => other.news!.allowedHosts.includes(h))).toBe(false);
      }
    }
    expect(flat.every((h) => !h.includes('/'))).toBe(true);
  });

  it('isAllowedHttpsUrl: https + host exato', () => {
    const hosts = ['www.vilanovafc.com.br'];
    expect(isAllowedHttpsUrl('https://www.vilanovafc.com.br/noticias/1-a', hosts)).toBe(true);
    expect(isAllowedHttpsUrl('http://www.vilanovafc.com.br/noticias/1-a', hosts)).toBe(false);
    expect(isAllowedHttpsUrl('https://www.vilanovafc.com.br.evil.com/x', hosts)).toBe(false);
    expect(isAllowedHttpsUrl('https://evil.com/www.vilanovafc.com.br', hosts)).toBe(false);
    expect(isAllowedHttpsUrl('javascript:alert(1)', hosts)).toBe(false);
    expect(isAllowedHttpsUrl('not a url', hosts)).toBe(false);
  });
});

function fakeStore(prev: { next_refresh_at: string | null; consecutive_failures: number } | null = null) {
  const upserts: NewsRow[] = [];
  const failures: FailurePatch[] = [];
  const store: NewsStore = {
    state: async () => prev,
    upsert: async (r) => void upserts.push(r),
    markFailure: async (_id, patch) => {
      failures.push(patch);
      return prev !== null;
    },
  };
  return { store, upserts, failures };
}
const okFetch = (body: string) => vi.fn(async () => new Response(body, { status: 200 })) as unknown as typeof fetch;

describe('refreshNews', () => {
  it('sucesso: grava a lista com next_refresh_at +10min e expiração de 7 dias', async () => {
    const { store, upserts } = fakeStore();
    const r = await refreshNews(vila, { store, fetch: okFetch(vilaHtml), images: null, now: () => NOW });
    expect(r).toMatchObject({ ok: true, items: 6 });
    expect(upserts).toHaveLength(1);
    expect(upserts[0]).toMatchObject({
      club_id: vila.canonicalClubId,
      consecutive_failures: 0,
      last_error: null,
      next_refresh_at: new Date(NOW.getTime() + 10 * 60_000).toISOString(),
      expires_at: new Date(NOW.getTime() + 7 * 86_400_000).toISOString(),
    });
    expect(upserts[0].payload.items).toHaveLength(6);
  });

  it('ainda não vencido: não busca a fonte', async () => {
    const f = okFetch(vilaHtml);
    const { store, upserts } = fakeStore({ next_refresh_at: new Date(NOW.getTime() + 60_000).toISOString(), consecutive_failures: 0 });
    const r = await refreshNews(vila, { store, fetch: f, images: null, now: () => NOW });
    expect(r.skipped).toBe(true);
    expect(f).not.toHaveBeenCalled();
    expect(upserts).toHaveLength(0);
  });

  it('erro upstream (HTTP 500): preserva o payload, registra falha e backoff', async () => {
    const { store, upserts, failures } = fakeStore({ next_refresh_at: NOW.toISOString(), consecutive_failures: 1 });
    const f = vi.fn(async () => new Response('x', { status: 500 })) as unknown as typeof fetch;
    const r = await refreshNews(vila, { store, fetch: f, images: null, now: () => NOW });
    expect(r.ok).toBe(false);
    expect(upserts).toHaveLength(0); // nunca sobrescreve a última lista boa
    expect(failures[0]).toMatchObject({ consecutive_failures: 2, last_error: 'source responded 500' });
    expect(failures[0].next_refresh_at).toBe(new Date(NOW.getTime() + 10 * 60_000).toISOString());
  });

  it('rede caindo (fetch lança): mesmo tratamento', async () => {
    const { store, upserts, failures } = fakeStore({ next_refresh_at: null, consecutive_failures: 0 });
    const f = vi.fn(async () => {
      throw new Error('network down');
    }) as unknown as typeof fetch;
    await refreshNews(vila, { store, fetch: f, images: null, now: () => NOW });
    expect(upserts).toHaveLength(0);
    expect(failures[0]).toMatchObject({ consecutive_failures: 1, last_error: 'network down' });
  });

  it('fonte responde 200 mas sem itens (layout mudou): trata como falha, não apaga a lista', async () => {
    const { store, upserts, failures } = fakeStore({ next_refresh_at: null, consecutive_failures: 0 });
    await refreshNews(vila, { store, fetch: okFetch('<html>manutenção</html>'), images: null, now: () => NOW });
    expect(upserts).toHaveLength(0);
    expect(failures[0].last_error).toBe('no items parsed');
  });

  it('backoff cresce e limita em 60 min', async () => {
    const { store, failures } = fakeStore({ next_refresh_at: null, consecutive_failures: 9 });
    const f = vi.fn(async () => new Response('', { status: 503 })) as unknown as typeof fetch;
    await refreshNews(vila, { store, fetch: f, images: null, now: () => NOW });
    expect(failures[0].next_refresh_at).toBe(new Date(NOW.getTime() + 60 * 60_000).toISOString());
  });

  it('descarta item cuja URL não é https/host do clube', async () => {
    const evil = JSON.stringify({
      data: [
        { headline: 'ok', url: 'https://www.redbullbragantino.com/br-pt/noticias/a', datePublished: '2026-11-20T10:00:00Z', image: { url: '' } },
        { headline: 'http', url: 'http://www.redbullbragantino.com/br-pt/noticias/b', datePublished: '', image: { url: '' } },
        { headline: 'outro host', url: 'https://evil.example/br-pt/noticias/c', datePublished: '', image: { url: '' } },
      ],
    });
    const { store, upserts } = fakeStore();
    await refreshNews(brag, { store, fetch: okFetch(evil), images: null, now: () => NOW });
    expect(upserts[0].payload.items.map((i) => i.id)).toEqual(['a']);
  });

  it('clube sem fonte de notícias: falha controlada', async () => {
    const { store } = fakeStore();
    const r = await refreshNews({ code: 'x', canonicalClubId: 'x' }, { store, fetch: okFetch(''), images: null });
    expect(r.ok).toBe(false);
  });

  it('capas: materializa para o Storage e a falha de uma imagem não derruba a lista', async () => {
    const stored = new Set<string>();
    const deps: ImageDeps = {
      publicBase: 'https://p.supabase.co/storage/v1/object/public/news-images',
      storage: { exists: async (p) => stored.has(p), upload: async (p) => void stored.add(p) },
      fetch: vi.fn(async (url: string) =>
        String(url).includes('imgs/370/210/images/venda-de-ingressos-vila-nova-x-atletico')
          ? new Response('', { status: 404 })
          : new Response(new Uint8Array([1, 2, 3]), { status: 200, headers: { 'content-type': 'image/png' } }),
      ) as unknown as typeof fetch,
    };
    const { store, upserts } = fakeStore();
    const r = await refreshNews(vila, { store, fetch: okFetch(vilaHtml), images: deps, now: () => NOW });
    expect(r.ok).toBe(true);
    expect(r.covers!.failed).toBe(1);
    const items = upserts[0].payload.items;
    expect(items).toHaveLength(6);
    expect(items.filter((i) => i.imageUrl.startsWith(deps.publicBase + '/covers/'))).toHaveLength(5);
    expect(items.filter((i) => i.imageUrl.startsWith('https://www.vilanovafc.com.br/'))).toHaveLength(1);
  });
});

describe('materializeCovers', () => {
  const mk = (imageUrl: string, id = 'a'): NewsItem => ({ id, title: 't', category: '', publishedAt: '', imageUrl, url: 'https://x/y' });
  const png = () => new Response(new Uint8Array([1]), { status: 200, headers: { 'content-type': 'image/png' } });
  function deps(fetchImpl: typeof fetch) {
    const stored = new Set<string>();
    const d: ImageDeps = {
      publicBase: 'https://p/storage/news-images',
      fetch: fetchImpl,
      storage: { exists: async (p) => stored.has(p), upload: async (p) => void stored.add(p) },
    };
    return { d, stored };
  }

  it('dedupe: mesma imagem (querystring diferente) = 1 download; 2ª rodada reutiliza', async () => {
    const f = vi.fn(async () => png()) as unknown as typeof fetch;
    const { d } = deps(f);
    const items = [mk('https://img.a/x.png?w=1', '1'), mk('https://img.a/x.png?w=2', '2')];
    const first = await materializeCovers(items, d, ['img.a']);
    expect(f).toHaveBeenCalledTimes(1);
    expect(first.items[0].imageUrl).toBe(first.items[1].imageUrl);
    const second = await materializeCovers(items, d, ['img.a']);
    expect(f).toHaveBeenCalledTimes(1);
    expect(second.stats).toMatchObject({ reused: 1, downloaded: 0 });
  });

  it('host fora da allowlist e http não são baixados', async () => {
    const f = vi.fn(async () => png()) as unknown as typeof fetch;
    const { d } = deps(f);
    const out = await materializeCovers([mk('https://evil.com/x.png'), mk('http://img.a/y.png')], d, ['img.a']);
    expect(f).not.toHaveBeenCalled();
    expect(out.items[0].imageUrl).toBe('https://evil.com/x.png');
  });

  it('só image/* e até 2 MB; redirect não é seguido; falha mantém a URL original', async () => {
    const html = vi.fn(async () => new Response('<html>', { status: 200, headers: { 'content-type': 'text/html' } })) as unknown as typeof fetch;
    const big = vi.fn(async () => new Response(new Uint8Array(2 * 1024 * 1024 + 1), { status: 200, headers: { 'content-type': 'image/png' } })) as unknown as typeof fetch;
    const redirect = vi.fn(async () => new Response('', { status: 302, headers: { location: 'https://internal/' } })) as unknown as typeof fetch;
    for (const f of [html, big, redirect]) {
      const out = await materializeCovers([mk('https://img.a/x.png')], deps(f).d, ['img.a']);
      expect(out.items[0].imageUrl).toBe('https://img.a/x.png');
      expect(out.stats.failed).toBe(1);
    }
    expect((redirect as unknown as ReturnType<typeof vi.fn>).mock.calls[0][1]).toMatchObject({ redirect: 'manual' });
  });
});

describe('getNewsArticle', () => {
  const item: NewsItem = {
    id: '555-evento',
    title: 'Evento',
    category: '',
    publishedAt: '2026-11-04',
    imageUrl: 'https://p.supabase.co/storage/v1/object/public/news-images/covers/abc.png',
    url: 'https://www.vilanovafc.com.br/noticias/555-evento',
  };
  const page = (body: string) =>
    `<article class="news-details"><h1 class="news-details_title">Evento</h1><span class="news-details_date">Postado em: 04/11/2026</span>` +
    `<figure class="news-details_img"><img src="x.png"></figure><div class="single-details">${body}</div><div class="news-share"></div></article>`;
  const f = (html: string, status = 200) => vi.fn(async () => new Response(html, { status })) as unknown as typeof fetch;

  it('id conhecido: busca a URL do snapshot e devolve o artigo com a capa do Storage', async () => {
    const fx = f(page('<p>Texto do jogo.</p>'));
    const r = await getNewsArticle(vila.news!, item.id, [item], fx);
    expect(r.available).toBe(true);
    if (r.available) {
      expect(r.article.content).toEqual([{ type: 'paragraph', text: 'Texto do jogo.' }]);
      // Imagem PRÓPRIA da matéria (sem Storage ligado = URL original do site).
      expect(r.article.imageUrl).toBe('https://www.vilanovafc.com.br/x.png');
    }
    expect((fx as unknown as ReturnType<typeof vi.fn>).mock.calls[0][0]).toBe(item.url);
  });

  it('id inexistente na lista: available:false, url null e ZERO fetch', async () => {
    const fx = f('x');
    expect(await getNewsArticle(vila.news!, 'qualquer', [item], fx)).toEqual({ available: false, url: null });
    expect(await getNewsArticle(vila.news!, item.id, null, fx)).toEqual({ available: false, url: null });
    expect(fx).not.toHaveBeenCalled();
  });

  it('URL do snapshot não-https ou de host não permitido: sem fetch', async () => {
    for (const url of ['http://www.vilanovafc.com.br/noticias/555-evento', 'https://evil.example/noticias/555-evento']) {
      const fx = f('x');
      const r = await getNewsArticle(vila.news!, item.id, [{ ...item, url }], fx);
      expect(r).toEqual({ available: false, url: null });
      expect(fx).not.toHaveBeenCalled();
    }
  });

  it('fonte fora do ar / sem corpo: available:false preservando o link externo', async () => {
    expect(await getNewsArticle(vila.news!, item.id, [item], f('', 500))).toEqual({ available: false, url: item.url });
    expect(await getNewsArticle(vila.news!, item.id, [item], f('<html></html>'))).toEqual({ available: false, url: item.url });
    const boom = vi.fn(async () => {
      throw new Error('timeout');
    }) as unknown as typeof fetch;
    expect(await getNewsArticle(vila.news!, item.id, [item], boom)).toEqual({ available: false, url: item.url });
  });

  it('link do corpo que não é https é removido; https permanece', async () => {
    const body = '<p>Antes <a href="javascript:alert(1)">ruim</a> <a href="http://x.com/a">http</a> <a href="https://ok.com/a">bom</a></p>';
    const r = await getNewsArticle(vila.news!, item.id, [item], f(page(body)));
    expect(r.available).toBe(true);
    if (r.available) {
      const links = r.article.content.filter((b) => b.type === 'link');
      expect(links).toEqual([{ type: 'link', text: 'bom', url: 'https://ok.com/a' }]);
    }
    expect(sanitizeBlocks([{ type: 'link', text: 'x', url: 'data:text/html,1' }])).toEqual([]);
  });

  it('isolamento: item de outro clube (host do Goiás) é recusado no Vila', async () => {
    const fx = f('x');
    const alien = { ...item, url: 'https://www.goiasec.com.br/noticias/555-evento' };
    expect(await getNewsArticle(vila.news!, item.id, [alien], fx)).toEqual({ available: false, url: null });
    expect(fx).not.toHaveBeenCalled();
  });

  describe('imagem própria do artigo', () => {
    const gItem: NewsItem = {
      ...item,
      id: 'guia',
      url: 'https://www.goiasec.com.br/noticias/guia',
      imageUrl: 'https://p/storage/news-images/covers/lista.jpeg',
    };
    const OWN = 'https://static.goiasec.com.br/upload/noticia/propria.jpeg';
    const goiasPage =
      '<html><h1>Guia da Partida</h1><span>Profissional</span><span class="font-bold">14 nov. 2026</span>' +
      `<img alt="" src="${OWN}"/>` +
      '<div class="desc-post-interno">Já está disponível o Press Kit.<br/><a href="https://ok.com/kit">Kit</a></div></div></html>';
    const png = () => new Response(new Uint8Array([1, 2]), { status: 200, headers: { 'content-type': 'image/png' } });
    function imgDeps(fetchImpl: typeof fetch) {
      const stored = new Set<string>();
      const d: ImageDeps = {
        publicBase: 'https://p/storage/news-images',
        fetch: fetchImpl,
        storage: { exists: async (p) => stored.has(p), upload: async (p) => void stored.add(p) },
      };
      return { d, stored };
    }
    const pageFetch = (html: string) => vi.fn(async () => new Response(html, { status: 200 })) as unknown as typeof fetch;

    it('paridade Goiás: sem Storage, a imagem do artigo é a MESMA do Worker atual (própria, não a capa da lista)', async () => {
      const old = scrapeNewsArticle(goiasPage, gItem.url, goias.news!.siteOrigin)!;
      const r = await getNewsArticle(goias.news!, gItem.id, [gItem], pageFetch(goiasPage));
      expect(old.imageUrl).toBe(OWN);
      expect(r.available && r.article.imageUrl).toBe(old.imageUrl);
    });

    it('com Storage: materializa a imagem própria, devolve a URL do Storage e deduplica na 2ª leitura', async () => {
      const imgFetch = vi.fn(async () => png()) as unknown as typeof fetch;
      const { d, stored } = imgDeps(imgFetch);
      const r1 = await getNewsArticle(goias.news!, gItem.id, [gItem], pageFetch(goiasPage), d);
      expect(r1.available && r1.article.imageUrl.startsWith('https://p/storage/news-images/covers/')).toBe(true);
      expect(stored.size).toBe(1);
      expect((imgFetch as unknown as ReturnType<typeof vi.fn>).mock.calls[0][1]).toMatchObject({ redirect: 'manual' });
      const r2 = await getNewsArticle(goias.news!, gItem.id, [gItem], pageFetch(goiasPage), d);
      expect(imgFetch).toHaveBeenCalledTimes(1);
      expect(r2.available && r2.article.imageUrl).toBe(r1.available && r1.article.imageUrl);
    });

    it('falha da imagem (404, não-imagem, >2MB) não derruba o artigo: mantém a URL própria original', async () => {
      const bad = [
        vi.fn(async () => new Response('', { status: 404 })),
        vi.fn(async () => new Response('<html>', { status: 200, headers: { 'content-type': 'text/html' } })),
        vi.fn(async () => new Response(new Uint8Array(2 * 1024 * 1024 + 1), { status: 200, headers: { 'content-type': 'image/png' } })),
      ];
      for (const b of bad) {
        const r = await getNewsArticle(goias.news!, gItem.id, [gItem], pageFetch(goiasPage), imgDeps(b as unknown as typeof fetch).d);
        expect(r.available).toBe(true);
        if (r.available) {
          expect(r.article.imageUrl).toBe(OWN);
          expect(r.article.content.length).toBeGreaterThan(0);
        }
      }
    });

    it('sem imagem própria, host fora da allowlist ou http: cai na capa da lista e não baixa nada', async () => {
      const imgFetch = vi.fn(async () => png()) as unknown as typeof fetch;
      const variants = [
        goiasPage.replace(`<img alt="" src="${OWN}"/>`, ''),
        goiasPage.replace('https://static.goiasec.com.br', 'https://evil.example'),
        goiasPage.replace('https://static.goiasec.com.br', 'http://static.goiasec.com.br'),
      ];
      for (const html of variants) {
        const r = await getNewsArticle(goias.news!, gItem.id, [gItem], pageFetch(html), imgDeps(imgFetch).d);
        expect(r.available && r.article.imageUrl).toBe(gItem.imageUrl);
      }
      expect(imgFetch).not.toHaveBeenCalled();
    });
  });

  it('Bragantino: duas chamadas, ambas no host oficial', async () => {
    const bItem: NewsItem = { ...item, id: 'braga-visita', url: 'https://www.redbullbragantino.com/br-pt/noticias/braga-visita' };
    const meta = JSON.stringify({ data: [{ headline: 'Braga', url: bItem.url, datePublished: '2026-11-20T10:00:00Z', image: { url: 'https://img.redbullbragantino.com/a.jpg' } }] });
    const body = JSON.stringify({ data: { items: [{ type: 'paragraph', elements: [{ text: 'Texto.' }] }] } });
    const calls: string[] = [];
    const fx = vi.fn(async (u: string) => {
      calls.push(String(u));
      return new Response(String(u).includes('/query/') ? body : meta, { status: 200 });
    }) as unknown as typeof fetch;
    const r = await getNewsArticle(brag.news!, bItem.id, [bItem], fx);
    expect(r.available).toBe(true);
    expect(calls).toHaveLength(2);
    expect(calls.every((c) => c.startsWith('https://www.redbullbragantino.com/'))).toBe(true);
  });
});

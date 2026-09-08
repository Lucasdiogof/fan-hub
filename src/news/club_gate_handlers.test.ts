import { afterEach, describe, expect, it, vi } from 'vitest';
import { handleNewsList } from './list';
import { handleNewsArticle } from './article';
import { handleSocialFeed } from '../social/feed';
import type { Env } from '../football/_lib/config';
import type { SocialEnv } from '../social/config';

/** Bragantino tem fonte de notícias real (API JSON) desde 2026-09-08 — os
 * testes que passam pelo gate e chegam a buscar de verdade precisam mockar
 * `fetch`, mesmo padrão de `football/standings.test.ts`, pra nunca bater no
 * site de verdade num teste unitário. */
function mockBragantinoNewsFetch() {
  global.fetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input.toString();
    if (url.includes('rb3Schema=v1:structuredData') && url.includes('filter[uriSlug]')) {
      return new Response(
        JSON.stringify({
          data: [
            {
              headline: 'Manchete de teste',
              description: 'Resumo de teste',
              image: { url: 'https://img.redbullbragantino.com/x.jpg' },
              datePublished: '2026-09-04T23:18:15Z',
              url: 'https://www.redbullbragantino.com/br-pt/noticias/n',
            },
          ],
        }),
        { status: 200 },
      );
    }
    if (url.includes('rb3Schema=v1:structuredData')) {
      return new Response(
        JSON.stringify({
          data: [
            {
              headline: 'Manchete de teste',
              description: 'Resumo de teste',
              image: { url: 'https://img.redbullbragantino.com/x.jpg' },
              datePublished: '2026-09-04T23:18:15Z',
              url: 'https://www.redbullbragantino.com/br-pt/noticias/n',
            },
          ],
        }),
        { status: 200 },
      );
    }
    if (url.includes('rb3Schema=v1:inlineContent')) {
      return new Response(
        JSON.stringify({
          data: { items: [{ type: 'paragraph', elements: [{ variant: 'text', text: 'Corpo de teste' }] }] },
        }),
        { status: 200 },
      );
    }
    throw new Error(`URL não mockada: ${url}`);
  }) as unknown as typeof fetch;
}

// Gate de clube por `env.CLUB_CODE`: as 3 rotas devolvem "unavailable" ANTES
// de qualquer fetch/cache quando o `?club=` não bate com o clube DESTE deploy
// (ou quando o clube não tem a fonte configurada). Envs mínimos (sem KV/secret
// real) bastam pra provar o short-circuit do gate. `club-b` é sintético.
const goiasEnv = { CLUB_CODE: 'goias', CACHE_VERSION: '1' } as Env;
const bragantinoEnv = { CLUB_CODE: 'bragantino', CACHE_VERSION: '1' } as Env;
const goiasSocialEnv = { CLUB_CODE: 'goias', CACHE_VERSION: '1' } as SocialEnv;
const bragantinoSocialEnv = { CLUB_CODE: 'bragantino', CACHE_VERSION: '1' } as SocialEnv;

async function body(res: Response): Promise<unknown> {
  return res.json().catch(() => null);
}

describe('Gate por env.CLUB_CODE — deploy do Goiás', () => {
  it('?club=club-b -> 404 unavailable, nunca a lista real do Goiás', async () => {
    const res = await handleNewsList(new Request('https://x/api/news?club=club-b'), goiasEnv);
    expect(res.status).toBe(404);
    expect(await body(res)).toEqual({ items: [], available: false });
  });

  it('CROSS-CLUB: ?club=bragantino no Worker do Goiás -> 404, nunca conteúdo do Goiás', async () => {
    const list = await handleNewsList(new Request('https://x/api/news?club=bragantino'), goiasEnv);
    expect(list.status).toBe(404);
    expect(await body(list)).toEqual({ items: [], available: false });

    const article = await handleNewsArticle(new Request('https://x/api/news/n?club=bragantino'), goiasEnv, 'n');
    expect(article.status).toBe(404);
    expect(await body(article)).toEqual({ available: false, url: null });

    const feed = await handleSocialFeed(new Request('https://x/api/social/feed?club=bragantino'), goiasSocialEnv);
    expect(feed.status).toBe(404);
    expect(await body(feed)).toEqual({ posts: [], available: false });
  });

  it('?club=goias (implícito e explícito) passa pelo gate (não é 404 do gate)', async () => {
    for (const url of ['https://x/api/news/n', 'https://x/api/news/n?club=goias']) {
      const res = await handleNewsArticle(new Request(url), goiasEnv, 'n').catch(() => null);
      if (res) expect(res.status).not.toBe(404);
    }
  });
});

describe('Gate por env.CLUB_CODE — deploy do Bragantino', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('CROSS-CLUB: ?club=goias no Worker do Bragantino -> 404, nunca conteúdo do outro clube', async () => {
    const list = await handleNewsList(new Request('https://x/api/news?club=goias'), bragantinoEnv);
    expect(list.status).toBe(404);
    expect(await body(list)).toEqual({ items: [], available: false });

    const feed = await handleSocialFeed(new Request('https://x/api/social/feed?club=goias'), bragantinoSocialEnv);
    expect(feed.status).toBe(404);
    expect(await body(feed)).toEqual({ posts: [], available: false });
  });

  it('news do Bragantino (fonte real desde 2026-09-08) -> lista e artigo passam pelo gate e vêm da API própria, NUNCA de goiasec', async () => {
    mockBragantinoNewsFetch();

    const list = await handleNewsList(new Request('https://x/api/news?club=bragantino'), bragantinoEnv);
    expect(list.status).toBe(200);
    const listBody = (await body(list)) as { items: { id: string; title: string; url: string }[] };
    expect(listBody.items).toHaveLength(1);
    expect(listBody.items[0].url).toContain('redbullbragantino.com');

    const article = await handleNewsArticle(new Request('https://x/api/news/n?club=bragantino'), bragantinoEnv, 'n');
    expect(article.status).toBe(200);
    const articleBody = (await body(article)) as { available: boolean; article?: { content: unknown[] } };
    expect(articleBody.available).toBe(true);
    expect(articleBody.article?.content.length).toBeGreaterThan(0);
  });

  it('social do Bragantino -> feed vazio (sem KV/task), NUNCA posts do Goiás', async () => {
    const feed = await handleSocialFeed(
      new Request('https://x/api/social/feed?club=bragantino'),
      bragantinoSocialEnv,
    ).catch(() => null);
    if (feed) {
      const b = (await body(feed)) as { posts?: unknown[] };
      expect(b?.posts ?? []).toEqual([]);
    }
  });
});

import { describe, expect, it, vi } from 'vitest';
import { resolveClubServerConfigByCode } from '../club_server_config';
import { handleNewsArticle, type NewsArticleHandlerDeps } from './handler';
import type { NewsItem } from './types';

const vila = resolveClubServerConfigByCode('vilanova')!;
const item: NewsItem = {
  id: '555-evento',
  title: 'Evento',
  category: '',
  publishedAt: '2026-11-04',
  imageUrl: 'https://p/storage/news-images/covers/a.png',
  url: 'https://www.vilanovafc.com.br/noticias/555-evento',
};
const page =
  '<article class="news-details"><h1 class="news-details_title">Evento</h1><span class="news-details_date">Postado em: 04/11/2026</span>' +
  '<div class="single-details"><p>Texto.</p></div><div class="news-share"></div></article>';

function setup(list: NewsItem[] | null = [item], validTokens = ['user-jwt']) {
  const fetchMock = vi.fn(async () => new Response(page, { status: 200 }));
  const deps: NewsArticleHandlerDeps = {
    verifyUser: async (t) => validTokens.includes(t),
    clubs: async () => [vila],
    readList: async () => list,
    images: null,
    fetch: fetchMock as unknown as typeof fetch,
  };
  const call = (body: unknown, auth?: string) =>
    handleNewsArticle(
      new Request('https://x/news-article', {
        method: 'POST',
        headers: auth ? { authorization: auth, 'content-type': 'application/json' } : { 'content-type': 'application/json' },
        body: JSON.stringify(body),
      }),
      deps,
    );
  return { call, fetchMock };
}

describe('news-article: autenticação', () => {
  it('sem Authorization -> 401 e nenhum fetch', async () => {
    const { call, fetchMock } = setup();
    const res = await call({ id: item.id });
    expect(res.status).toBe(401);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('token inválido (inclui publishable/service role vindas do cliente) -> 401', async () => {
    const { call, fetchMock } = setup();
    for (const auth of ['Bearer sb_publishable_abc', 'Bearer service-role-jwt', 'Bearer ', 'Basic xyz']) {
      expect((await call({ id: item.id }, auth)).status).toBe(401);
    }
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('falha ao verificar o token (Auth fora do ar) -> 401, nunca libera', async () => {
    const { call } = setup();
    const res = await handleNewsArticle(
      new Request('https://x', { method: 'POST', headers: { authorization: 'Bearer user-jwt' }, body: '{}' }),
      {
        verifyUser: async () => {
          throw new Error('auth down');
        },
        clubs: async () => [vila],
        readList: async () => [item],
        images: null,
        fetch,
      },
    );
    expect(res.status).toBe(401);
    expect(call).toBeDefined();
  });

  it('usuário autenticado: artigo normal (busca a URL do snapshot)', async () => {
    const { call, fetchMock } = setup();
    const res = await call({ id: item.id, club: 'vilanova' }, 'Bearer user-jwt');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.available).toBe(true);
    expect(body.article.content).toEqual([{ type: 'paragraph', text: 'Texto.' }]);
    expect((fetchMock.mock.calls[0] as unknown[])[0]).toBe(item.url);
  });

  it('autenticado + id inexistente: available:false, url null, sem fetch', async () => {
    const { call, fetchMock } = setup();
    const res = await call({ id: 'nao-existe' }, 'Bearer user-jwt');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ available: false, url: null });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('validações de https/host inalteradas: URL do snapshot fora do host do clube não é buscada', async () => {
    const { call, fetchMock } = setup([{ ...item, url: 'https://evil.example/noticias/555-evento' }]);
    expect(await (await call({ id: item.id }, 'Bearer user-jwt')).json()).toEqual({ available: false, url: null });
    const http = setup([{ ...item, url: 'http://www.vilanovafc.com.br/noticias/555-evento' }]);
    expect(await (await http.call({ id: item.id }, 'Bearer user-jwt')).json()).toEqual({ available: false, url: null });
    expect(fetchMock).not.toHaveBeenCalled();
    expect(http.fetchMock).not.toHaveBeenCalled();
  });

  it('clube pedido diferente do clube do projeto: recusado sem fetch', async () => {
    const { call, fetchMock } = setup();
    expect(await (await call({ id: item.id, club: 'goias' }, 'Bearer user-jwt')).json()).toEqual({ available: false, url: null });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

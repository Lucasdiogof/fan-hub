import { afterEach, describe, expect, it, vi } from 'vitest';
import { bragantinoArticleMetadataUrl, parseBragantinoArticle, parseBragantinoNewsList } from './bragantino_parser';

// Regressão: a URL real tem `/v3` DUAS vezes (`/v3/api/graphql/v1/v3/feed`),
// uma vez como raiz da API e outra como parte do próprio endpoint — um bug
// real (só 1 `/v3`) devolvia 500 da API de verdade, mas passava batido nos
// testes mockados acima porque o mock casa por substring, não a URL exata.
// Achado só testando contra o site real (nunca reproduzido por fixture).
describe('bragantinoArticleMetadataUrl — a URL exata bate com o endpoint real confirmado navegando o site', () => {
  it('tem os dois segmentos /v3, filtro por slug e o schema certo', () => {
    const url = bragantinoArticleMetadataUrl('exemplo-de-slug');
    expect(url).toBe(
      'https://www.redbullbragantino.com/v3/api/graphql/v1/v3/feed/pt-BR' +
        '?filter[type]=stories&filter[uriSlug]=exemplo-de-slug' +
        '&page[limit]=1&disableUsageRestrictions=true&rb3Locale=br-pt&rb3Schema=v1:structuredData',
    );
  });
});

const STRUCTURED_DATA_LIST = JSON.stringify({
  data: [
    {
      headline: 'Título de teste',
      description: 'Resumo de teste',
      image: { url: 'https://img.redbullbragantino.com/foo.jpg' },
      // 23:18 UTC de 04/09 -> 20:18 no Brasil, mesmo dia calendário.
      datePublished: '2026-09-04T23:18:15Z',
      url: 'https://www.redbullbragantino.com/br-pt/noticias/titulo-de-teste',
    },
    {
      // Sem título -> descartado, nunca vira um item com título vazio.
      headline: '',
      url: 'https://www.redbullbragantino.com/br-pt/noticias/sem-titulo',
    },
  ],
});

describe('parseBragantinoNewsList — mapeia schema.org/NewsArticle pro NewsItem do app', () => {
  it('extrai id (slug da URL)/título/data/imagem/url', () => {
    const items = parseBragantinoNewsList(STRUCTURED_DATA_LIST);
    expect(items).toHaveLength(1);
    expect(items[0]).toEqual({
      id: 'titulo-de-teste',
      title: 'Título de teste',
      category: '',
      publishedAt: '2026-09-04',
      imageUrl: 'https://img.redbullbragantino.com/foo.jpg',
      url: 'https://www.redbullbragantino.com/br-pt/noticias/titulo-de-teste',
    });
  });

  it('data cruzando meia-noite UTC -> vira o dia anterior em horário do Brasil', () => {
    const json = JSON.stringify({
      data: [
        {
          headline: 'Late night',
          datePublished: '2026-09-08T01:00:00Z', // 22:00 do dia 07 no Brasil
          url: 'https://www.redbullbragantino.com/br-pt/noticias/late-night',
        },
      ],
    });
    const items = parseBragantinoNewsList(json);
    expect(items[0].publishedAt).toBe('2026-09-07');
  });

  it('JSON inválido -> lista vazia, nunca lança', () => {
    expect(parseBragantinoNewsList('not json')).toEqual([]);
  });

  it('sem data.data -> lista vazia', () => {
    expect(parseBragantinoNewsList('{}')).toEqual([]);
  });
});

describe('parseBragantinoArticle — metadados (já buscados) + corpo (busca própria, mockada)', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  const metadataRaw = JSON.stringify({
    data: [
      {
        headline: 'Manchete completa',
        image: { url: 'https://img.redbullbragantino.com/capa.jpg' },
        datePublished: '2026-09-04T23:18:15Z',
        url: 'https://www.redbullbragantino.com/br-pt/noticias/manchete-completa',
      },
    ],
  });

  function mockInlineContent(items: unknown[]) {
    global.fetch = vi.fn(async () =>
      new Response(JSON.stringify({ data: { items } }), { status: 200 }),
    ) as unknown as typeof fetch;
  }

  it('busca o corpo na URL certa (2 segmentos /v3, filtro por slug, schema inlineContent)', async () => {
    mockInlineContent([]);
    await parseBragantinoArticle(metadataRaw, 'manchete-completa');
    expect(global.fetch).toHaveBeenCalledWith(
      'https://www.redbullbragantino.com/v3/api/graphql/v1/v3/query/pt-BR' +
        '?filter[type]=stories&filter[uriSlug]=manchete-completa' +
        '&page[limit]=1&rb3Locale=br-pt&rb3Schema=v1:inlineContent',
      expect.anything(),
    );
  });

  it('paragraph simples -> um bloco paragraph', async () => {
    mockInlineContent([
      { type: 'paragraph', elements: [{ variant: 'text', text: 'Olá mundo.' }] },
    ]);
    const article = await parseBragantinoArticle(metadataRaw, 'manchete-completa');
    expect(article?.content).toEqual([{ type: 'paragraph', text: 'Olá mundo.' }]);
  });

  it('link no meio do parágrafo -> quebra em paragraph + link + paragraph, preservando o href', async () => {
    mockInlineContent([
      {
        type: 'paragraph',
        elements: [
          { variant: 'text', text: 'Saiba mais: ' },
          { variant: 'link', text: 'clique aqui', href: 'https://exemplo.test/x' },
          { variant: 'text', text: ' e veja.' },
        ],
      },
    ]);
    const article = await parseBragantinoArticle(metadataRaw, 'manchete-completa');
    expect(article?.content).toEqual([
      { type: 'paragraph', text: 'Saiba mais:' },
      { type: 'link', text: 'clique aqui', url: 'https://exemplo.test/x' },
      { type: 'paragraph', text: 'e veja.' },
    ]);
  });

  it('enumeration -> vira parágrafos com marcador "• ", nunca um tipo novo', async () => {
    mockInlineContent([
      {
        type: 'enumeration',
        enumerationType: 'bullet',
        items: [
          { elements: [{ variant: 'text', text: 'Item 1' }] },
          { elements: [{ variant: 'text', text: 'Item 2' }] },
        ],
      },
    ]);
    const article = await parseBragantinoArticle(metadataRaw, 'manchete-completa');
    expect(article?.content).toEqual([
      { type: 'paragraph', text: '• Item 1' },
      { type: 'paragraph', text: '• Item 2' },
    ]);
  });

  it('bloco image inline do corpo -> descartado (capa continua vindo por fora, no NewsItem)', async () => {
    mockInlineContent([
      { type: 'paragraph', elements: [{ variant: 'text', text: 'Antes.' }] },
      { type: 'image', image: { id: 'x' } },
      { type: 'paragraph', elements: [{ variant: 'text', text: 'Depois.' }] },
    ]);
    const article = await parseBragantinoArticle(metadataRaw, 'manchete-completa');
    expect(article?.content).toEqual([
      { type: 'paragraph', text: 'Antes.' },
      { type: 'paragraph', text: 'Depois.' },
    ]);
    expect(article?.imageUrl).toBe('https://img.redbullbragantino.com/capa.jpg');
  });

  it('corpo vazio -> null (nunca publica artigo sem conteúdo)', async () => {
    mockInlineContent([]);
    const article = await parseBragantinoArticle(metadataRaw, 'manchete-completa');
    expect(article).toBeNull();
  });

  it('metadados sem headline -> null, sem sequer buscar o corpo', async () => {
    const fetchSpy = vi.fn();
    global.fetch = fetchSpy as unknown as typeof fetch;
    const article = await parseBragantinoArticle('{"data":[{}]}', 'x');
    expect(article).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});

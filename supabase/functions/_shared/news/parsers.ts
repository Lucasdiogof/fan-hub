// Dispatcher de parsers de notícias + validação de URL. Cada site tem formato
// próprio; o `switch` exaustivo garante que nenhum parser fica sem caso.
import type { ClubNewsSource } from '../club_server_config.ts';
import { bragantinoArticleMetadataUrl, parseBragantinoArticle, parseBragantinoNewsList } from './bragantino.ts';
import { parseGoiasArticle, parseGoiasNewsList } from './goias.ts';
import { parseVilaNovaArticle, parseVilaNovaNewsList } from './vilanova.ts';
import type { NewsArticle, NewsContentBlock, NewsItem } from './types.ts';

/** Só `https` e host exatamente na allowlist do clube. */
export function isAllowedHttpsUrl(value: string, hosts: readonly string[]): boolean {
  try {
    const u = new URL(value);
    return u.protocol === 'https:' && hosts.includes(u.host);
  } catch {
    return false;
  }
}

export function parseNewsList(raw: string, source: ClubNewsSource): NewsItem[] {
  switch (source.parser) {
    case 'goias':
      return parseGoiasNewsList(raw, source.siteOrigin);
    case 'bragantino':
      return parseBragantinoNewsList(raw);
    case 'vilanova':
      return parseVilaNovaNewsList(raw, source.siteOrigin);
  }
}

/** URL a buscar para o conteúdo principal do artigo, a partir do item JÁ
 * conhecido (nunca de entrada do cliente). */
export function articleFetchUrl(source: ClubNewsSource, item: NewsItem): string {
  return source.parser === 'bragantino' ? bragantinoArticleMetadataUrl(source.siteOrigin, item.id) : item.url;
}

export function parseNewsArticle(
  raw: string,
  item: NewsItem,
  source: ClubNewsSource,
  fetchImpl: typeof fetch,
): Promise<NewsArticle | null> {
  switch (source.parser) {
    case 'goias':
      return Promise.resolve(parseGoiasArticle(raw, item.url, source.siteOrigin));
    case 'bragantino':
      return parseBragantinoArticle(raw, item.id, source.siteOrigin, fetchImpl);
    case 'vilanova':
      return Promise.resolve(parseVilaNovaArticle(raw, item.url, source.siteOrigin));
  }
}

function isHttpsUrl(value: string): boolean {
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

/** Links do corpo só passam com `https` (qualquer host: é só navegação do
 * usuário, nada é buscado pelo servidor); o resto é descartado. */
export function sanitizeBlocks(blocks: NewsContentBlock[]): NewsContentBlock[] {
  return blocks.filter((b) => b.type !== 'link' || isHttpsUrl(b.url));
}

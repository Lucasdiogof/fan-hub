// Dispatcher de parser de notícias por clube. O HTML de cada site oficial é
// diferente, então cada clube tem (ou terá) o SEU parser — nunca se reusa o
// parser do Goiás às cegas pra outro site. Ponto único de extensão: quando a
// fonte oficial de um novo clube for confirmada, adiciona-se o id em
// `NewsParserId` (`club_media_config.ts`) + o `case` aqui + o arquivo do
// parser novo. O `switch` exaustivo garante, em tempo de compilação, que
// nenhum parser fica sem implementação.
import { scrapeNewsList, scrapeNewsArticle } from './scraper';
import { bragantinoArticleMetadataUrl, parseBragantinoArticle, parseBragantinoNewsList } from './bragantino_parser';
import { parseVilaNovaArticle, parseVilaNovaNewsList } from './vilanova_parser';
import type { ClubNewsConfig, NewsParserId } from '../social/club_media_config';
import type { NewsArticle, NewsItem } from './types';

export function parseNewsList(
  raw: string,
  parser: NewsParserId,
  siteOrigin: string,
): Promise<NewsItem[]> {
  switch (parser) {
    case 'goias':
      return scrapeNewsList(raw, siteOrigin);
    case 'bragantino':
      // `raw` aqui é o corpo JSON da API (o site é uma SPA, sem HTML
      // raspável) — `news.sourceUrl` já é a URL completa da listagem, ver
      // `club_media_config.ts` e `bragantino_parser.ts`.
      return Promise.resolve(parseBragantinoNewsList(raw));
    case 'vilanova':
      return Promise.resolve(parseVilaNovaNewsList(raw, siteOrigin));
  }
}

/**
 * URL a buscar pra obter o conteúdo PRINCIPAL de um artigo — pra o Goiás é a
 * própria página HTML; pra o Bragantino é o endpoint de metadados da API
 * (o corpo, que exige uma 2ª chamada, é buscado dentro de
 * `parseNewsArticle`/`parseBragantinoArticle`). Ponto único de extensão,
 * mesmo raciocínio do `switch` exaustivo dos parsers.
 */
export function newsArticlePrimaryUrl(news: ClubNewsConfig, slug: string): string {
  switch (news.parser) {
    case 'goias':
      return `${news.siteOrigin}${news.articlePathPrefix}/${slug}`;
    case 'bragantino':
      return bragantinoArticleMetadataUrl(slug);
    case 'vilanova':
      return `${news.siteOrigin}${news.articlePathPrefix}/${slug}`;
  }
}

export function parseNewsArticle(
  raw: string,
  pageUrl: string,
  parser: NewsParserId,
  siteOrigin: string,
  slug: string,
): Promise<NewsArticle | null> {
  switch (parser) {
    case 'goias':
      return Promise.resolve(scrapeNewsArticle(raw, pageUrl, siteOrigin));
    case 'bragantino':
      return parseBragantinoArticle(raw, slug);
    case 'vilanova':
      return Promise.resolve(parseVilaNovaArticle(raw, pageUrl, siteOrigin));
  }
}

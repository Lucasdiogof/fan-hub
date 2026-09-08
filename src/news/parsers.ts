// Dispatcher de parser de notícias por clube. O HTML de cada site oficial é
// diferente, então cada clube tem (ou terá) o SEU parser — nunca se reusa o
// parser do Goiás às cegas pra outro site. Ponto único de extensão: quando a
// fonte oficial de um novo clube for confirmada, adiciona-se o id em
// `NewsParserId` (`club_media_config.ts`) + o `case` aqui + o arquivo do
// parser novo. O `switch` exaustivo garante, em tempo de compilação, que
// nenhum parser fica sem implementação.
import { scrapeNewsList, scrapeNewsArticle } from './scraper';
import type { NewsParserId } from '../social/club_media_config';
import type { NewsArticle, NewsItem } from './types';

export function parseNewsList(
  html: string,
  parser: NewsParserId,
  siteOrigin: string,
): Promise<NewsItem[]> {
  switch (parser) {
    case 'goias':
      return scrapeNewsList(html, siteOrigin);
  }
}

export function parseNewsArticle(
  html: string,
  pageUrl: string,
  parser: NewsParserId,
  siteOrigin: string,
): NewsArticle | null {
  switch (parser) {
    case 'goias':
      return scrapeNewsArticle(html, pageUrl, siteOrigin);
  }
}

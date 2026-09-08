import { cacheFirst } from '../football/_lib/cache';
import type { Env } from '../football/_lib/config';
import { jsonResponse, errorResponse } from '../football/_lib/respond';
import { isRequestedClubServed } from '../football/_lib/club_server_config';
import { clubMediaConfig } from '../social/club_media_config';
import { parseNewsList } from './parsers';

/**
 * A fonte (URL + parser) vem da config de Mídia do clube deste deploy.
 * Clube sem `news` configurado (ex.: Bragantino hoje — fonte oficial ainda
 * não determinada) devolve vazio/controlado, NUNCA raspa o site do Goiás.
 * O site do Goiás não pagina — sempre devolve as ~15 mais recentes.
 */
export async function handleNewsList(request: Request, env: Env): Promise<Response> {
  const cacheVersion = env.CACHE_VERSION || '1';

  // Gate por deploy + fonte por clube.
  if (!isRequestedClubServed(request, env)) {
    return jsonResponse({ items: [], available: false }, { status: 404 });
  }
  const news = clubMediaConfig(env.CLUB_CODE)?.news;
  if (!news) {
    return jsonResponse({ items: [], available: false }, { status: 404 });
  }

  try {
    return await cacheFirst(request, 600, 'news.list', cacheVersion, async () => {
      const response = await fetch(news.sourceUrl, {
        headers: { 'user-agent': 'Mozilla/5.0 (compatible; FanHubBot/1.0)' },
      });
      if (!response.ok) {
        throw new Error(`${news.siteOrigin} respondeu ${response.status}`);
      }
      const html = await response.text();
      const items = await parseNewsList(html, news.parser, news.siteOrigin);
      return { items };
    });
  } catch (error) {
    console.log(`news.list.error: ${error}`);
    return errorResponse('Erro ao carregar as notícias.');
  }
}

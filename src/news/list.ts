import { cacheFirst } from '../football/_lib/cache';
import type { Env } from '../football/_lib/config';
import { jsonResponse, errorResponse } from '../football/_lib/respond';
import { NEWS_SOCIAL_CONFIGURED_CLUB_CODE, resolveRequestedClubCode } from '../football/_lib/club_server_config';
import { scrapeNewsList } from './scraper';

const NEWS_LIST_URL = 'https://www.goiasec.com.br/noticias';

/**
 * O site oficial não pagina — `/noticias`, `?page=2` e as páginas de
 * categoria retornam sempre as mesmas ~15 notícias mais recentes. Não tem
 * arquivo histórico pra raspar, então a listagem sempre devolve o que der.
 */
export async function handleNewsList(request: Request, env: Env): Promise<Response> {
  const cacheVersion = env.CACHE_VERSION || '1';

  // Achado da auditoria M4: esta rota nunca teve dimensão de clube — sempre
  // servia o site do Goiás pra qualquer chamador. Um `?club=` explícito e
  // diferente do único integrado hoje nunca cai pro conteúdo do Goiás.
  const clubCode = resolveRequestedClubCode(request);
  if (clubCode !== NEWS_SOCIAL_CONFIGURED_CLUB_CODE) {
    return jsonResponse({ items: [], available: false }, { status: 404 });
  }

  try {
    return await cacheFirst(request, 600, 'news.list', cacheVersion, async () => {
      const response = await fetch(NEWS_LIST_URL, {
        headers: { 'user-agent': 'Mozilla/5.0 (compatible; GoiasAppBot/1.0)' },
      });
      if (!response.ok) {
        throw new Error(`goiasec.com.br respondeu ${response.status}`);
      }
      const html = await response.text();
      const items = await scrapeNewsList(html);
      return { items };
    });
  } catch (error) {
    console.log(`news.list.error: ${error}`);
    return errorResponse('Erro ao carregar as notícias.');
  }
}

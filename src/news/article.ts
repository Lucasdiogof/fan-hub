import { cacheFirst } from '../football/_lib/cache';
import type { Env } from '../football/_lib/config';
import { jsonResponse } from '../football/_lib/respond';
import { isRequestedClubServed } from '../football/_lib/club_server_config';
import { clubMediaConfig } from '../social/club_media_config';
import { parseNewsArticle } from './parsers';
import type { NewsArticleResult } from './types';

/**
 * Devolve sempre 200 — `available: false` é uma resposta válida, não um
 * erro, e é exatamente o sinal que o app usa pra abrir a URL original no
 * lugar do leitor nativo (falha de rede, página fora do ar, ou o template
 * do site mudou e a extração parou de bater). Mesmo contrato reusado pro
 * gate de clube: `?club=` diferente do `CLUB_CODE` deste deploy, ou clube
 * sem fonte de notícias configurada, também vira `available: false` com
 * `url: null` — nunca uma URL/conteúdo de outro clube.
 */
export async function handleNewsArticle(
  request: Request,
  env: Env,
  slug: string,
): Promise<Response> {
  const cacheVersion = env.CACHE_VERSION || '1';

  if (!isRequestedClubServed(request, env)) {
    return jsonResponse({ available: false, url: null }, { status: 404 });
  }
  const news = clubMediaConfig(env.CLUB_CODE)?.news;
  if (!news) {
    // Clube sem fonte de notícias (ex.: Bragantino hoje) — `url: null`
    // deixa claro que não há nem conteúdo nem link de fallback.
    return jsonResponse({ available: false, url: null }, { status: 404 });
  }

  const pageUrl = `${news.siteOrigin}${news.articlePathPrefix}/${slug}`;

  try {
    return await cacheFirst(request, 3600, 'news.article', cacheVersion, async () => {
      const response = await fetch(pageUrl, {
        headers: { 'user-agent': 'Mozilla/5.0 (compatible; FanHubBot/1.0)' },
      });
      if (!response.ok) {
        const fallback: NewsArticleResult = { available: false, url: pageUrl };
        return fallback;
      }
      const html = await response.text();
      const article = parseNewsArticle(html, pageUrl, news.parser, news.siteOrigin);
      const result: NewsArticleResult = article
        ? { available: true, article }
        : { available: false, url: pageUrl };
      return result;
    });
  } catch (error) {
    console.log(`news.article.error: ${error}`);
    const fallback: NewsArticleResult = { available: false, url: pageUrl };
    return jsonResponse(fallback);
  }
}

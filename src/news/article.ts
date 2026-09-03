import { cacheFirst } from '../football/_lib/cache';
import type { Env } from '../football/_lib/config';
import { jsonResponse } from '../football/_lib/respond';
import { NEWS_SOCIAL_CONFIGURED_CLUB_CODE, resolveRequestedClubCode } from '../football/_lib/club_server_config';
import { scrapeNewsArticle } from './scraper';
import type { NewsArticleResult } from './types';

const SITE_ORIGIN = 'https://www.goiasec.com.br';

/**
 * Devolve sempre 200 — `available: false` é uma resposta válida, não um
 * erro, e é exatamente o sinal que o app usa pra abrir a URL original no
 * lugar do leitor nativo (falha de rede, página fora do ar, ou o template
 * do site mudou e a extração parou de bater). Mesmo contrato reusado pro
 * gate de clube (achado M4): `?club=` diferente do único integrado hoje
 * também vira `available: false`, nunca conteúdo do Goiás.
 */
export async function handleNewsArticle(
  request: Request,
  env: Env,
  slug: string,
): Promise<Response> {
  const cacheVersion = env.CACHE_VERSION || '1';

  const clubCode = resolveRequestedClubCode(request);
  if (clubCode !== NEWS_SOCIAL_CONFIGURED_CLUB_CODE) {
    // Nunca monta uma URL do site do Goiás pra um clube sem integração —
    // `url: null` deixa claro que não há nem conteúdo nem link de fallback.
    return jsonResponse({ available: false, url: null }, { status: 404 });
  }

  const pageUrl = `${SITE_ORIGIN}/noticias/${slug}`;

  try {
    return await cacheFirst(request, 3600, 'news.article', cacheVersion, async () => {
      const response = await fetch(pageUrl, {
        headers: { 'user-agent': 'Mozilla/5.0 (compatible; GoiasAppBot/1.0)' },
      });
      if (!response.ok) {
        const fallback: NewsArticleResult = { available: false, url: pageUrl };
        return fallback;
      }
      const html = await response.text();
      const article = scrapeNewsArticle(html, pageUrl);
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

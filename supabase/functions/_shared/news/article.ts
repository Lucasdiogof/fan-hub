// Artigo sob demanda. O cliente manda SÓ o `id`; a URL vem da lista do
// snapshot (já validada no refresh) e é revalidada aqui (https + host do
// clube). Id fora da lista conhecida = zero fetch. Sem persistência.
import type { ClubNewsSource } from '../club_server_config.ts';
import type { ImageDeps } from '../football/images.ts';
import { materializeCovers } from './images.ts';
import { articleFetchUrl, isAllowedHttpsUrl, parseNewsArticle, sanitizeBlocks } from './parsers.ts';
import type { NewsArticleResult, NewsItem } from './types.ts';

export async function getNewsArticle(
  source: ClubNewsSource,
  id: string,
  list: NewsItem[] | null,
  fetchImpl: typeof fetch,
  images: ImageDeps | null = null,
): Promise<NewsArticleResult> {
  const item = list?.find((it) => it.id === id);
  if (!item) return { available: false, url: null };
  const fallback: NewsArticleResult = { available: false, url: item.url };
  if (!isAllowedHttpsUrl(item.url, source.allowedHosts)) return { available: false, url: null };

  const target = articleFetchUrl(source, item);
  if (!isAllowedHttpsUrl(target, source.allowedHosts)) return fallback;
  try {
    const res = await fetchImpl(target, {
      headers: { 'user-agent': 'Mozilla/5.0 (compatible; FanHubBot/1.0)' },
      redirect: 'manual',
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) return fallback;
    const article = await parseNewsArticle(await res.text(), item, source, fetchImpl);
    if (!article) return fallback;
    const content = sanitizeBlocks(article.content);
    if (content.length === 0) return fallback;
    const imageUrl = await articleImage(article.imageUrl, item, source, images);
    return { available: true, article: { ...article, imageUrl, url: item.url, content } };
  } catch {
    return fallback;
  }
}

/** Imagem PRÓPRIA da matéria (como o Worker sempre devolveu): https + host de
 * imagem do clube; com Storage ligado vira URL do Storage (mesmo dedupe da
 * lista). Sem imagem própria válida cai na capa da lista. Falha de imagem
 * nunca derruba o artigo: mantém a URL original. */
async function articleImage(
  own: string,
  item: NewsItem,
  source: ClubNewsSource,
  images: ImageDeps | null,
): Promise<string> {
  if (!isAllowedHttpsUrl(own, source.imageHosts)) return item.imageUrl;
  if (!images) return own;
  try {
    const out = await materializeCovers([{ ...item, imageUrl: own }], images, source.imageHosts);
    return out.items[0].imageUrl;
  } catch {
    return own;
  }
}

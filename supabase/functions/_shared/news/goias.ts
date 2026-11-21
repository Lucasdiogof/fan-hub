// Parser de notícias do site oficial do Goiás (Next.js, HTML renderizado no
// servidor). Sem HTMLRewriter (só existe no Cloudflare): regex por bloco
// `<article>`, mesma estratégia do Vila. Os dados estruturados do Next (flight
// data) foram avaliados e descartados: formato interno, instável e com data em
// outro formato; o HTML visível é o que o Worker sempre leu (paridade 1:1).
import { parsePortugueseDate } from './dateParser.ts';
import { cleanText, decodeEntities, stripTags } from './htmlText.ts';
import type { NewsArticle, NewsContentBlock, NewsItem } from './types.ts';

function resolveUrl(href: string, siteOrigin: string): string {
  if (/^https?:\/\//i.test(href)) return href;
  // Outro esquema (javascript:, data:, mailto:...) nunca vira link: '' é descartado depois.
  if (/^[a-z][a-z0-9+.-]*:/i.test(href)) return '';
  return `${siteOrigin}${href.startsWith('/') ? '' : '/'}${href}`;
}

function slugFromUrl(url: string): string {
  return url.split('/').filter(Boolean).pop() ?? '';
}

/** Listagem: cada notícia é um `<article>` cujo `<a>` filho direto envolve a
 * imagem (URL da matéria); categoria = link `/categorias/`, título = `<h2>`,
 * data = `<time>`. */
export function parseGoiasNewsList(html: string, siteOrigin: string): NewsItem[] {
  const result: NewsItem[] = [];
  for (const match of html.matchAll(/<article\b[^>]*>([\s\S]*?)<\/article>/g)) {
    const body = match[1];
    // `article > a`: primeiro <a> do bloco (o que envolve a imagem).
    const href = body.match(/^\s*<a\b[^>]*\shref="([^"]+)"/)?.[1];
    const title = cleanText(body.match(/<h2\b[^>]*>([\s\S]*?)<\/h2>/)?.[1] ?? '');
    if (!href || !title) continue;
    const slug = slugFromUrl(href);
    if (!slug) continue;
    const category = cleanText(body.match(/<a\b[^>]*href="[^"]*\/categorias\/[^"]*"[^>]*>([\s\S]*?)<\/a>/)?.[1] ?? '');
    const time = body.match(/<time\b[^>]*>([\s\S]*?)<\/time>/)?.[1];
    const img = body.match(/<img\b[^>]*\ssrc="([^"]+)"/)?.[1];
    result.push({
      id: slug,
      title,
      category,
      publishedAt: time ? (parsePortugueseDate(cleanText(time)) ?? '') : '',
      imageUrl: img ?? '',
      url: resolveUrl(href, siteOrigin),
    });
  }
  return result;
}

function parseBodyBlocks(rawHtml: string, siteOrigin: string): NewsContentBlock[] {
  const blocks: NewsContentBlock[] = [];
  for (const segment of rawHtml.split(/<br\s*\/?>/i)) {
    const trimmed = segment.trim();
    if (!trimmed) continue;
    const linkMatch = trimmed.match(/^<a\s+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>$/i);
    if (linkMatch) {
      const text = decodeEntities(stripTags(linkMatch[2])).trim();
      if (text) blocks.push({ type: 'link', text, url: resolveUrl(linkMatch[1], siteOrigin) });
      continue;
    }
    const text = cleanText(trimmed);
    if (text) blocks.push({ type: 'paragraph', text });
  }
  return blocks;
}

/** Página individual (template diferente da listagem). Retorna null se a
 * extração falhar — quem chama cai no link externo, nunca inventa conteúdo. */
export function parseGoiasArticle(html: string, pageUrl: string, siteOrigin: string): NewsArticle | null {
  const h1Match = html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/);
  if (!h1Match || h1Match.index === undefined) return null;
  const title = cleanText(h1Match[1]);
  if (!title) return null;

  const afterH1 = html.slice(h1Match.index + h1Match[0].length);
  const categoryMatch = afterH1.match(/<span[^>]*>([^<]*)<\/span>/);
  const category = categoryMatch ? cleanText(categoryMatch[1]) : '';
  const dateMatch = afterH1.match(/<span class="font-bold">([^<]+)<\/span>/);
  const publishedAt = dateMatch ? (parsePortugueseDate(dateMatch[1]) ?? '') : '';
  const imageUrl = afterH1.match(/<img[^>]*\ssrc="([^"]+)"/)?.[1] ?? '';

  const bodyMarkerIdx = html.indexOf('desc-post-interno');
  if (bodyMarkerIdx < 0) return null;
  const divOpenStart = html.lastIndexOf('<div', bodyMarkerIdx);
  const divOpenEnd = html.indexOf('>', bodyMarkerIdx);
  if (divOpenStart < 0 || divOpenEnd < 0) return null;
  const divCloseStart = html.indexOf('</div>', divOpenEnd);
  if (divCloseStart < 0) return null;

  const content = parseBodyBlocks(html.slice(divOpenEnd + 1, divCloseStart), siteOrigin);
  if (content.length === 0) return null;
  return { id: slugFromUrl(pageUrl), title, category, publishedAt, imageUrl, url: pageUrl, content };
}

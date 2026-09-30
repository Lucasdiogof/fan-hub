// Parser de notícias do site oficial do Vila Nova (vilanovafc.com.br).
// Confirmado em 2026-09-30: CMS próprio, HTML renderizado no servidor (sem
// API JSON). A listagem `/noticias` traz os 6 cards mais recentes no HTML
// (o "Carregar Mais" é AJAX, não usado aqui); a notícia individual fica em
// `/noticias/<id>-<slug>`. Imagens usam lazy-load: o `src` é um GIF de 1px
// e a URL real está em `data-src` (relativa ao site).
//
// O site não publica categoria; `category` sai vazia (nunca inventada).
import { cleanText, decodeEntities, stripTags } from './htmlText';
import type { NewsArticle, NewsContentBlock, NewsItem } from './types';

export const VILANOVA_SITE_ORIGIN = 'https://www.vilanovafc.com.br';

function resolveUrl(href: string, siteOrigin: string): string {
  if (href.startsWith('http')) return href;
  return `${siteOrigin}${href.startsWith('/') ? '' : '/'}${href}`;
}

function slugFromUrl(url: string): string {
  return url.split('?')[0].split('/').filter(Boolean).pop() ?? '';
}

/** "Postado em: 20/09/2026 às 09h25" -> "2026-09-20". Null se não bater. */
export function parseVilaNovaDate(raw: string): string | null {
  const match = raw.match(/(\d{2})\/(\d{2})\/(\d{4})/);
  if (!match) return null;
  const [, day, month, year] = match;
  const d = Number(day);
  const m = Number(month);
  if (d < 1 || d > 31 || m < 1 || m > 12) return null;
  return `${year}-${month}-${day}`;
}

/** URL real da imagem (lazy-load em `data-src`, cai pro `src` se não for
 * o placeholder `data:`). */
function imageFrom(imgTag: string, siteOrigin: string): string {
  const dataSrc = imgTag.match(/\sdata-src="([^"]+)"/);
  if (dataSrc) return resolveUrl(dataSrc[1], siteOrigin);
  const src = imgTag.match(/\ssrc="([^"]+)"/);
  if (src && !src[1].startsWith('data:')) return resolveUrl(src[1], siteOrigin);
  return '';
}

export function parseVilaNovaNewsList(html: string, siteOrigin: string): NewsItem[] {
  const result: NewsItem[] = [];
  const seen = new Set<string>();
  const cardPattern = /<a\s+href="([^"]*\/noticias\/[^"]+)"\s+class="card-news">([\s\S]*?)<\/a>/g;

  for (const match of html.matchAll(cardPattern)) {
    const url = resolveUrl(match[1], siteOrigin);
    const body = match[2];
    const slug = slugFromUrl(url);
    if (!slug || seen.has(slug)) continue;

    const titleMatch = body.match(/<h3 class="card-news_title">([\s\S]*?)<\/h3>/);
    const title = titleMatch ? cleanText(titleMatch[1]) : '';
    if (!title) continue;

    const imgMatch = body.match(/<img[^>]*>/);
    const dateMatch = body.match(/<span class="card-news_date">([\s\S]*?)<\/span>/);

    seen.add(slug);
    result.push({
      id: slug,
      title,
      category: '',
      publishedAt: dateMatch ? (parseVilaNovaDate(dateMatch[1]) ?? '') : '',
      imageUrl: imgMatch ? imageFrom(imgMatch[0], siteOrigin) : '',
      url,
    });
  }
  return result;
}

/** Cada `<p>` vira um ou mais blocos: quebras `<br>` separam parágrafos, e
 * um `<a>` vira bloco de link (o texto antes dele, se houver, vira
 * parágrafo). */
function parseBodyBlocks(bodyHtml: string, siteOrigin: string): NewsContentBlock[] {
  const blocks: NewsContentBlock[] = [];
  const paragraphs = bodyHtml.split(/<\/p>/i);

  for (const paragraph of paragraphs) {
    for (const segment of paragraph.split(/<br\s*\/?>/i)) {
      let rest = segment;
      const linkPattern = /<a\s+[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/i;
      let link = rest.match(linkPattern);
      while (link && link.index !== undefined) {
        const before = cleanText(rest.slice(0, link.index));
        if (before) blocks.push({ type: 'paragraph', text: before });
        const text = decodeEntities(stripTags(link[2])).replace(/\s+/g, ' ').trim();
        if (text) blocks.push({ type: 'link', text, url: resolveUrl(link[1], siteOrigin) });
        rest = rest.slice(link.index + link[0].length);
        link = rest.match(linkPattern);
      }
      const text = cleanText(rest);
      if (text) blocks.push({ type: 'paragraph', text });
    }
  }
  return blocks;
}

/**
 * Página individual: `<article class="news-details">` com a data em
 * `news-details_date`, o título no `<h1 class="news-details_title">`, a
 * imagem em `<figure class="news-details_img">` e o corpo em
 * `<div class="single-details">`. Retorna null se título ou corpo faltarem
 * (quem chama cai pro link externo, nunca inventa conteúdo).
 */
export function parseVilaNovaArticle(html: string, pageUrl: string, siteOrigin: string): NewsArticle | null {
  const articleStart = html.indexOf('class="news-details');
  if (articleStart < 0) return null;
  const scope = html.slice(articleStart);

  const titleMatch = scope.match(/<h1 class="news-details_title">([\s\S]*?)<\/h1>/);
  const title = titleMatch ? cleanText(titleMatch[1]) : '';
  if (!title) return null;

  const dateMatch = scope.match(/<span class="news-details_date">([\s\S]*?)<\/span>/);
  const figureMatch = scope.match(/<figure class="news-details_img">([\s\S]*?)<\/figure>/);
  const imgMatch = figureMatch ? figureMatch[1].match(/<img[^>]*>/) : null;

  const bodyStart = scope.indexOf('<div class="single-details">');
  if (bodyStart < 0) return null;
  const bodyOpenEnd = scope.indexOf('>', bodyStart) + 1;
  const shareIdx = scope.indexOf('class="news-share"', bodyOpenEnd);
  const bodyEndLimit = shareIdx > 0 ? shareIdx : scope.length;
  const bodyClose = scope.lastIndexOf('</div>', bodyEndLimit);
  if (bodyClose <= bodyOpenEnd) return null;

  const content = parseBodyBlocks(scope.slice(bodyOpenEnd, bodyClose), siteOrigin);
  if (content.length === 0) return null;

  return {
    id: slugFromUrl(pageUrl),
    title,
    category: '',
    publishedAt: dateMatch ? (parseVilaNovaDate(dateMatch[1]) ?? '') : '',
    imageUrl: imgMatch ? imageFrom(imgMatch[0], siteOrigin) : '',
    url: pageUrl,
    content,
  };
}

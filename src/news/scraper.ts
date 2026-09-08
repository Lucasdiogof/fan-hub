import { parsePortugueseDate } from './dateParser';
import { cleanText, stripTags, decodeEntities } from './htmlText';
import type { NewsArticle, NewsContentBlock, NewsItem } from './types';

function resolveUrl(href: string, siteOrigin: string): string {
  if (href.startsWith('http')) return href;
  return `${siteOrigin}${href.startsWith('/') ? '' : '/'}${href}`;
}

function slugFromUrl(url: string): string {
  return url.split('/').filter(Boolean).pop() ?? '';
}

interface RawListItem {
  url?: string;
  imageUrl?: string;
  category?: string;
  title?: string;
  dateLabel?: string;
}

/**
 * Listagem (`/noticias`) é renderizada no servidor (Next.js App Router) —
 * cada notícia é um `<article>` com um `<a>` filho direto envolvendo a
 * imagem (único filho-`a` direto, o link de categoria e o link do título
 * ficam um nível mais fundo dentro de uma `<div>`), então `article > a`
 * identifica a URL da notícia sem ambiguidade.
 */
export async function scrapeNewsList(html: string, siteOrigin: string): Promise<NewsItem[]> {
  const items: RawListItem[] = [];
  let current: RawListItem | null = null;

  const rewriter = new HTMLRewriter()
    .on('article', {
      element() {
        current = {};
        items.push(current);
      },
    })
    .on('article > a', {
      element(el) {
        if (current && !current.url) {
          current.url = el.getAttribute('href') ?? undefined;
        }
      },
    })
    .on('article img', {
      element(el) {
        if (current && !current.imageUrl) {
          current.imageUrl = el.getAttribute('src') ?? undefined;
        }
      },
    })
    .on('article a[href*="/categorias/"]', {
      text(chunk) {
        if (current) current.category = (current.category ?? '') + chunk.text;
      },
    })
    .on('article h2', {
      text(chunk) {
        if (current) current.title = (current.title ?? '') + chunk.text;
      },
    })
    .on('article time', {
      text(chunk) {
        if (current) current.dateLabel = (current.dateLabel ?? '') + chunk.text;
      },
    });

  const transformed = rewriter.transform(new Response(html));
  await transformed.text();

  const result: NewsItem[] = [];
  for (const raw of items) {
    if (!raw.url || !raw.title) continue;
    const slug = slugFromUrl(raw.url);
    if (!slug) continue;
    result.push({
      id: slug,
      title: raw.title.trim(),
      category: (raw.category ?? '').trim(),
      publishedAt: raw.dateLabel ? (parsePortugueseDate(raw.dateLabel) ?? '') : '',
      imageUrl: raw.imageUrl ?? '',
      url: resolveUrl(raw.url, siteOrigin),
    });
  }
  return result;
}

function parseBodyBlocks(rawHtml: string, siteOrigin: string): NewsContentBlock[] {
  const blocks: NewsContentBlock[] = [];
  const segments = rawHtml.split(/<br\s*\/?>/i);

  for (const segment of segments) {
    const trimmed = segment.trim();
    if (!trimmed) continue;

    const linkMatch = trimmed.match(/^<a\s+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>$/i);
    if (linkMatch) {
      const url = resolveUrl(linkMatch[1], siteOrigin);
      const text = decodeEntities(stripTags(linkMatch[2])).trim();
      if (text) blocks.push({ type: 'link', text, url });
      continue;
    }

    const text = cleanText(trimmed);
    if (text) blocks.push({ type: 'paragraph', text });
  }

  return blocks;
}

/**
 * Página individual usa um template diferente da listagem — a categoria
 * aqui NÃO é um link, é uma `<div>` com classes Tailwind em colchetes
 * (`bg-[#004C1B]`), que o seletor CSS do HTMLRewriter não lida bem. Em vez
 * de depender de nomes de classe, ancora em marcadores de texto estáveis
 * do próprio template ("Publicado", a classe `desc-post-interno`) e extrai
 * por posição — mais robusto a mudanças de estilo do site.
 *
 * Retorna null quando a extração falha (h1 ausente, corpo vazio/não
 * encontrado) — quem chama deve cair pro link externo, nunca inventar
 * conteúdo.
 */
export function scrapeNewsArticle(html: string, pageUrl: string, siteOrigin: string): NewsArticle | null {
  const h1Match = html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/);
  if (!h1Match || h1Match.index === undefined) return null;
  const title = cleanText(h1Match[1]);
  if (!title) return null;

  const afterH1 = html.slice(h1Match.index + h1Match[0].length);

  // Algumas notícias (ex.: "guia da partida") têm um <h2> de subtítulo logo
  // após o h1, antes do bloco categoria+data — não dá pra cortar "tudo até
  // achar 'Publicado'" porque esse subtítulo entra junto. O <span> da
  // categoria é sempre o primeiro span depois do h1 nos dois formatos.
  const categoryMatch = afterH1.match(/<span[^>]*>([^<]*)<\/span>/);
  const category = categoryMatch ? cleanText(categoryMatch[1]) : '';

  const dateMatch = afterH1.match(/<span class="font-bold">([^<]+)<\/span>/);
  const publishedAt = dateMatch ? (parsePortugueseDate(dateMatch[1]) ?? '') : '';

  const imgMatch = afterH1.match(/<img[^>]*\ssrc="([^"]+)"/);
  const imageUrl = imgMatch ? imgMatch[1] : '';

  const bodyMarkerIdx = html.indexOf('desc-post-interno');
  if (bodyMarkerIdx < 0) return null;
  const divOpenStart = html.lastIndexOf('<div', bodyMarkerIdx);
  const divOpenEnd = html.indexOf('>', bodyMarkerIdx);
  if (divOpenStart < 0 || divOpenEnd < 0) return null;
  const divCloseStart = html.indexOf('</div>', divOpenEnd);
  if (divCloseStart < 0) return null;

  const content = parseBodyBlocks(html.slice(divOpenEnd + 1, divCloseStart), siteOrigin);
  if (content.length === 0) return null;

  return {
    id: slugFromUrl(pageUrl),
    title,
    category,
    publishedAt,
    imageUrl,
    url: pageUrl,
    content,
  };
}

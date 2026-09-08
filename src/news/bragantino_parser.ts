import type { NewsArticle, NewsContentBlock, NewsItem } from './types';

// Fonte oficial do Bragantino é uma SPA (Red Bull Media House) sem HTML
// raspável — o parser do Goiás não serve de modelo aqui. A própria SPA
// consome uma API JSON interna pública (sem chave), confirmada navegando o
// site de verdade e inspecionando as chamadas reais. Ver
// `club_media_config.ts` pra onde a URL da listagem é montada.
// O `/v3` aparece DUAS vezes de propósito — uma vez como raiz da API
// (`/v3/api/...`), outra como parte do próprio endpoint de conteúdo
// (`/v1/v3/feed`, `/v1/v3/query`) — confirmado navegando o site de
// verdade, não é digitação duplicada.
const API_BASE = 'https://www.redbullbragantino.com/v3/api/graphql/v1/v3';
const REQUEST_HEADERS = {
  'user-agent': 'Mozilla/5.0 (compatible; FanHubBot/1.0)',
  accept: 'application/json',
};

/** Brasil não observa horário de verão hoje — mesmo offset fixo já usado em
 * `football/normalize/match.ts#utcToNaiveBrazilLocal`. Convertido ANTES de
 * cortar a data (não direto do UTC) porque uma notícia publicada tarde da
 * noite em UTC pode cair no dia seguinte se só cortarmos a string crua. */
function isoDateOnlyBrazilLocal(utcIso: string | undefined): string {
  if (!utcIso) return '';
  const utcMs = new Date(utcIso).getTime();
  if (Number.isNaN(utcMs)) return '';
  const brazilMs = utcMs - 3 * 60 * 60 * 1000;
  return new Date(brazilMs).toISOString().slice(0, 10);
}

function slugFromUrl(url: string): string {
  return url.split('/').filter(Boolean).pop() ?? '';
}

/** Mesmo shape que `schema.org/NewsArticle`, só os campos usados. */
interface StructuredDataItem {
  headline?: string;
  description?: string;
  image?: { url?: string };
  datePublished?: string;
  url?: string;
}

function mapStructuredDataItem(raw: StructuredDataItem): NewsItem | null {
  const title = raw.headline?.trim();
  const url = raw.url;
  if (!title || !url) return null;
  const slug = slugFromUrl(url);
  if (!slug) return null;
  return {
    id: slug,
    title,
    // O endpoint `v1:structuredData` (schema.org puro) não traz categoria —
    // só o `v1:cardList` traz (`content.tag.text`), e cruzar os dois exigiria
    // uma 2ª chamada só pra isso. Categoria vazia é aceitável (mesmo
    // contrato de quando o Goiás não consegue extrair uma).
    category: '',
    publishedAt: isoDateOnlyBrazilLocal(raw.datePublished),
    imageUrl: raw.image?.url ?? '',
    url,
  };
}

/**
 * `raw` já foi buscado por `list.ts` (mesmo fluxo genérico do Goiás: busca a
 * `news.sourceUrl` configurada, que pro Bragantino já é a URL completa da
 * API de listagem — nenhum fetch acontece aqui dentro, ao contrário do
 * artigo individual, que precisa de uma 2ª chamada só pra o corpo).
 */
export function parseBragantinoNewsList(raw: string): NewsItem[] {
  let json: { data?: StructuredDataItem[] };
  try {
    json = JSON.parse(raw) as { data?: StructuredDataItem[] };
  } catch {
    return [];
  }
  const items: NewsItem[] = [];
  for (const item of json.data ?? []) {
    const mapped = mapStructuredDataItem(item);
    if (mapped) items.push(mapped);
  }
  return items;
}

export function bragantinoArticleMetadataUrl(slug: string): string {
  const encoded = encodeURIComponent(slug);
  return (
    `${API_BASE}/feed/pt-BR?filter[type]=stories&filter[uriSlug]=${encoded}` +
    `&page[limit]=1&disableUsageRestrictions=true&rb3Locale=br-pt&rb3Schema=v1:structuredData`
  );
}

function bragantinoArticleBodyUrl(slug: string): string {
  const encoded = encodeURIComponent(slug);
  return (
    `${API_BASE}/query/pt-BR?filter[type]=stories&filter[uriSlug]=${encoded}` +
    `&page[limit]=1&rb3Locale=br-pt&rb3Schema=v1:inlineContent`
  );
}

/** Um elemento de texto dentro de um parágrafo/item de lista — pode ser
 * texto simples, texto com ênfase (`richtext`) ou um link inline. */
interface InlineElement {
  variant?: string;
  text?: string;
  href?: string;
}

interface InlineEnumerationItem {
  elements?: InlineElement[];
}

/** Um bloco do corpo — só 3 tipos observados na API: `paragraph`,
 * `enumeration` (lista com marcadores) e `image` (imagem inline). */
interface InlineBodyItem {
  type?: string;
  elements?: InlineElement[];
  items?: InlineEnumerationItem[];
}

/** Achata uma sequência de elementos (texto simples + `richtext` + `link`)
 * em blocos do schema ATUAL do app (só `paragraph`/`link`, ver
 * `types.ts#NewsContentBlock` — deliberadamente não expandido). Um link no
 * meio do texto quebra o parágrafo em 2-3 blocos em vez de virar texto puro
 * (preserva o link, nunca descarta href). `prefix` é usado só pelos itens de
 * `enumeration`, pra virar "• texto" sem precisar de um tipo `list` novo. */
function elementsToBlocks(elements: InlineElement[] | undefined, prefix = ''): NewsContentBlock[] {
  if (!elements || elements.length === 0) return [];
  const blocks: NewsContentBlock[] = [];
  let buffer = prefix;
  for (const el of elements) {
    if (el.variant === 'link' && el.href && el.text) {
      const text = buffer.trim();
      if (text) blocks.push({ type: 'paragraph', text });
      buffer = '';
      blocks.push({ type: 'link', text: el.text, url: el.href });
      continue;
    }
    if (el.text) buffer += el.text;
  }
  const text = buffer.trim();
  if (text) blocks.push({ type: 'paragraph', text });
  return blocks;
}

/** `enumeration` -> uma sequência de parágrafos com "• " (nunca um tipo
 * `list` novo — decisão explícita: achatar em vez de expandir o schema).
 * `image` inline do corpo é deliberadamente DESCARTADO (perda de conteúdo
 * aceita — a imagem de capa da matéria continua vindo normalmente via
 * `NewsItem.imageUrl`/`NewsArticle.imageUrl`); qualquer outro tipo
 * desconhecido também é ignorado, nunca vira texto quebrado/lixo. */
function inlineItemToBlocks(item: InlineBodyItem): NewsContentBlock[] {
  if (item.type === 'paragraph') {
    return elementsToBlocks(item.elements);
  }
  if (item.type === 'enumeration') {
    const blocks: NewsContentBlock[] = [];
    for (const li of item.items ?? []) {
      blocks.push(...elementsToBlocks(li.elements, '• '));
    }
    return blocks;
  }
  return [];
}

async function fetchBragantinoArticleBody(slug: string): Promise<NewsContentBlock[]> {
  const response = await fetch(bragantinoArticleBodyUrl(slug), { headers: REQUEST_HEADERS });
  if (!response.ok) return [];
  const json = (await response.json()) as { data?: { items?: InlineBodyItem[] } };
  const blocks: NewsContentBlock[] = [];
  for (const item of json.data?.items ?? []) {
    blocks.push(...inlineItemToBlocks(item));
  }
  return blocks;
}

/**
 * `metadataRaw` já foi buscado por quem chama (mesmo padrão do parser do
 * Goiás: o fetch "principal" é feito fora, só o corpo — que exige uma 2ª
 * chamada à API, diferente do Goiás que é 1 página só — é buscado aqui
 * dentro. Retorna `null` (nunca inventa conteúdo) se a matéria não for
 * encontrada ou o corpo vier vazio.
 */
export async function parseBragantinoArticle(
  metadataRaw: string,
  slug: string,
): Promise<NewsArticle | null> {
  let json: { data?: StructuredDataItem[] };
  try {
    json = JSON.parse(metadataRaw) as { data?: StructuredDataItem[] };
  } catch {
    return null;
  }
  const raw = json.data?.[0];
  if (!raw) return null;
  const item = mapStructuredDataItem(raw);
  if (!item) return null;

  const content = await fetchBragantinoArticleBody(slug);
  if (content.length === 0) return null;

  return { ...item, content };
}

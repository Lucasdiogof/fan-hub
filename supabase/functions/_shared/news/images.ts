// Capas de notícias -> Storage (bucket `news-images`). SÓ as capas da lista
// atual, host na allowlist do clube. Mesma ideia do futebol (sha256 da URL
// normalizada, 1 download por imagem), sem categorias/silhueta. Falha de uma
// imagem mantém a URL original e NUNCA derruba a lista.
import { fileName, normalizeImageUrl, type ImageDeps } from '../football/images.ts';
import type { NewsItem } from './types.ts';

export const NEWS_IMAGE_BUCKET = 'news-images';
const MAX_BYTES = 2 * 1024 * 1024;
// Lista tem ≤20 itens; o teto só protege contra surpresa da fonte.
const MAX_NEW_PER_RUN = 30;
const CONCURRENCY = 4;

export interface CoverStats {
  total: number;
  reused: number;
  downloaded: number;
  failed: number;
}

async function materializeOne(
  url: string,
  deps: ImageDeps,
  canDownload: () => boolean,
): Promise<{ path: string; outcome: 'reused' | 'downloaded' } | null> {
  const normalized = normalizeImageUrl(url);
  const path = `covers/${await fileName(url)}`;
  if (await deps.storage.exists(path)) return { path, outcome: 'reused' };
  if (!canDownload()) return null;
  // redirect manual: um 3xx nunca leva o servidor a um host fora da allowlist.
  const res = await deps.fetch(normalized, { headers: { accept: 'image/*' }, redirect: 'manual' });
  const type = res.headers.get('content-type') ?? '';
  if (!res.ok || !type.startsWith('image/')) return null;
  const bytes = await res.arrayBuffer();
  if (bytes.byteLength === 0 || bytes.byteLength > MAX_BYTES) return null;
  await deps.storage.upload(path, bytes, type);
  return { path, outcome: 'downloaded' };
}

/** Troca `imageUrl` das capas pela URL do Storage (sucesso) ou mantém a original. */
export async function materializeCovers(
  items: NewsItem[],
  deps: ImageDeps,
  hosts: readonly string[],
): Promise<{ items: NewsItem[]; stats: CoverStats }> {
  const stats: CoverStats = { total: 0, reused: 0, downloaded: 0, failed: 0 };
  const urls = new Map<string, string>();
  for (const item of items) {
    try {
      const u = new URL(item.imageUrl);
      if (u.protocol === 'https:' && hosts.includes(u.host)) urls.set(normalizeImageUrl(item.imageUrl), item.imageUrl);
    } catch {
      /* sem capa válida: fica como está */
    }
  }
  stats.total = urls.size;
  const result = new Map<string, string>();
  let budget = MAX_NEW_PER_RUN;
  const entries = [...urls.entries()];
  for (let i = 0; i < entries.length; i += CONCURRENCY) {
    await Promise.all(
      entries.slice(i, i + CONCURRENCY).map(async ([normalized, original]) => {
        try {
          const done = await materializeOne(original, deps, () => budget-- > 0);
          if (!done) return void stats.failed++;
          stats[done.outcome]++;
          result.set(normalized, `${deps.publicBase}/${done.path}`);
        } catch {
          stats.failed++;
        }
      }),
    );
  }
  return {
    items: items.map((it) => {
      try {
        return { ...it, imageUrl: result.get(normalizeImageUrl(it.imageUrl)) ?? it.imageUrl };
      } catch {
        return it;
      }
    }),
    stats,
  };
}

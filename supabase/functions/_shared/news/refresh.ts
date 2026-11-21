// Refresh da lista de notícias de UM clube. Puro: fetch/store/imagens injetados.
// Regra de ouro: falha upstream (HTTP, parse, lista vazia) NUNCA troca um
// payload válido — só registra falha e empurra `next_refresh_at` (backoff).
import type { ClubNewsSource } from '../club_server_config.ts';
import type { ImageDeps } from '../football/images.ts';
import { materializeCovers, type CoverStats } from './images.ts';
import { isAllowedHttpsUrl, parseNewsList } from './parsers.ts';
import type { NewsItem } from './types.ts';

export const NEWS_CONTRACT_VERSION = 1;
export const REFRESH_INTERVAL_MS = 10 * 60 * 1000;
// Equivalente ao cache offline de 7 dias do app: lista antiga ainda é útil.
export const EXPIRES_AFTER_MS = 7 * 24 * 60 * 60 * 1000;
const MAX_ITEMS = 20;
const MAX_BACKOFF_MIN = 60;

export interface NewsRow {
  club_id: string;
  payload: { items: NewsItem[] };
  contract_version: number;
  source: string;
  fetched_at: string;
  next_refresh_at: string;
  expires_at: string;
  consecutive_failures: number;
  last_error: null;
  last_error_at: null;
}

export interface FailurePatch {
  consecutive_failures: number;
  last_error: string;
  last_error_at: string;
  next_refresh_at: string;
}

export interface NewsStore {
  /** Estado atual (sem payload) ou null se nunca houve refresh. */
  state(clubId: string): Promise<{ next_refresh_at: string | null; consecutive_failures: number } | null>;
  upsert(row: NewsRow): Promise<void>;
  /** false = linha inexistente (nada a marcar). */
  markFailure(clubId: string, patch: FailurePatch): Promise<boolean>;
}

export interface NewsRefreshDeps {
  store: NewsStore;
  fetch: typeof fetch;
  images: ImageDeps | null;
  now?: () => Date;
}

export interface NewsRefreshResult {
  ok: boolean;
  skipped?: boolean;
  items?: number;
  covers?: CoverStats;
  error?: string;
}

export async function refreshNews(
  club: { code: string; canonicalClubId: string; news?: ClubNewsSource },
  deps: NewsRefreshDeps,
  force = false,
): Promise<NewsRefreshResult> {
  const source = club.news;
  if (!source) return { ok: false, error: 'club without news source' };
  const now = (deps.now ?? (() => new Date()))();
  const prev = await deps.store.state(club.canonicalClubId);
  if (!force && prev?.next_refresh_at && new Date(prev.next_refresh_at) > now) return { ok: true, skipped: true };

  try {
    const res = await deps.fetch(source.sourceUrl, {
      headers: { 'user-agent': 'Mozilla/5.0 (compatible; FanHubBot/1.0)', accept: 'text/html,application/json' },
      signal: AbortSignal.timeout(15000),
    });
    if (!res.ok) throw new Error(`source responded ${res.status}`);
    const parsed = parseNewsList(await res.text(), source)
      // URL da matéria tem de ser https no host do clube: é ela que `news-article` vai buscar.
      .filter((it) => isAllowedHttpsUrl(it.url, source.allowedHosts))
      .slice(0, MAX_ITEMS);
    if (parsed.length === 0) throw new Error('no items parsed');

    let items = parsed;
    let covers: CoverStats | undefined;
    if (deps.images) {
      const out = await materializeCovers(parsed, deps.images, source.imageHosts);
      items = out.items;
      covers = out.stats;
    }
    await deps.store.upsert({
      club_id: club.canonicalClubId,
      payload: { items },
      contract_version: NEWS_CONTRACT_VERSION,
      source: 'official-site',
      fetched_at: now.toISOString(),
      next_refresh_at: new Date(now.getTime() + REFRESH_INTERVAL_MS).toISOString(),
      expires_at: new Date(now.getTime() + EXPIRES_AFTER_MS).toISOString(),
      consecutive_failures: 0,
      last_error: null,
      last_error_at: null,
    });
    return { ok: true, items: items.length, covers };
  } catch (err) {
    const failures = (prev?.consecutive_failures ?? 0) + 1;
    const backoffMin = Math.min(MAX_BACKOFF_MIN, 5 * 2 ** (failures - 1));
    const message = (err instanceof Error ? err.message : String(err)).slice(0, 300);
    await deps.store.markFailure(club.canonicalClubId, {
      consecutive_failures: failures,
      last_error: message,
      last_error_at: now.toISOString(),
      next_refresh_at: new Date(now.getTime() + backoffMin * 60 * 1000).toISOString(),
    });
    return { ok: false, error: message };
  }
}

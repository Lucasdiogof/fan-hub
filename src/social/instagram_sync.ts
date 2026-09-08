/**
 * Sincronização do Instagram do Goiás via Apify → Workers KV.
 *
 * Só o Cron Trigger (e a rota admin protegida) chamam `syncInstagram`. O feed
 * lido pelo app NUNCA dispara o Apify — ele apenas lê o KV (ver
 * `readInstagramFromKv` e o `InstagramProvider`). Assim a frequência de scrape
 * é fixa (3x/dia pelo Cron), independente de acesso de usuário.
 */

import { clubMediaConfig, instagramKvKey } from './club_media_config';

/** Post já normalizado, no formato exato guardado no KV. */
export interface StoredInstagramPost {
  id: string;
  platform: 'instagram';
  author: string;
  username: string;
  caption: string;
  mediaType: string; // "Image" | "Video" | "Sidecar" (cru do Apify)
  mediaUrl: string;
  permalink: string;
  publishedAt: string;
}

export interface InstagramKvValue {
  updatedAt: string;
  lastSuccessfulSyncAt: string;
  posts: StoredInstagramPost[];
}

/** Campos do dataset do Apify Instagram Post Scraper que usamos. */
interface ApifyInstagramItem {
  shortCode?: string;
  type?: string;
  caption?: string;
  timestamp?: string;
  url?: string;
  displayUrl?: string;
  ownerFullName?: string;
  ownerUsername?: string;
}

export interface InstagramSyncEnv {
  /** Clube deste deploy — decide a chave de KV (`instagram:<code>:latest`),
   * pra o Cron do Bragantino NUNCA escrever na chave do Goiás. */
  CLUB_CODE: string;
  SOCIAL_FEED_KV: KVNamespace;
  APIFY_TOKEN?: string;
  APIFY_INSTAGRAM_TASK_ID?: string;
}

const MAX_POSTS = 5;
const APIFY_TIMEOUT_MS = 170_000;

export async function readInstagramFromKv(
  env: InstagramSyncEnv,
  kvKey: string,
): Promise<InstagramKvValue | null> {
  const raw = await env.SOCIAL_FEED_KV.get(kvKey);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as InstagramKvValue;
    if (!Array.isArray(parsed.posts)) return null;
    return parsed;
  } catch {
    return null;
  }
}

export interface SyncOutcome {
  status: 'updated' | 'kept-previous' | 'no-op';
  received: number;
  persisted: number;
  durationMs: number;
  reason?: string;
}

/**
 * Roda a Task do Apify, normaliza e persiste no KV. Em QUALQUER falha (Apify
 * fora, HTTP erro, JSON inválido, lista vazia, timeout, campo faltando) NÃO
 * sobrescreve o KV — mantém o último dataset válido, pra uma falha temporária
 * do Apify nunca derrubar o feed.
 */
export async function syncInstagram(env: InstagramSyncEnv): Promise<SyncOutcome> {
  const startedAt = Date.now();
  const duration = () => Date.now() - startedAt;
  console.log('instagram.sync.started');

  if (!env.CLUB_CODE) {
    console.log('instagram.sync.failed reason=missing_club_code');
    return { status: 'no-op', received: 0, persisted: 0, durationMs: duration(), reason: 'missing_club_code' };
  }
  // Chave do PRÓPRIO clube deste deploy — nunca a de outro.
  const kvKey = instagramKvKey(env.CLUB_CODE);

  if (!env.APIFY_TOKEN || !env.APIFY_INSTAGRAM_TASK_ID) {
    console.log('instagram.sync.failed reason=missing_config');
    return { status: 'no-op', received: 0, persisted: 0, durationMs: duration(), reason: 'missing_config' };
  }

  let items: ApifyInstagramItem[];
  try {
    items = await fetchApifyItems(env.APIFY_TOKEN, env.APIFY_INSTAGRAM_TASK_ID);
  } catch (err) {
    const reason = err instanceof Error ? err.message : String(err);
    console.log(`instagram.sync.failed reason=apify_fetch: ${reason}`);
    return keepPrevious(reason, duration());
  }

  const instagramConfig = clubMediaConfig(env.CLUB_CODE)?.instagram;
  const authorOverride =
    instagramConfig?.authorName && instagramConfig?.authorHandle
      ? { name: instagramConfig.authorName, handle: instagramConfig.authorHandle }
      : undefined;
  const posts = normalize(items, authorOverride);
  console.log(`instagram.sync.received count=${items.length} valid=${posts.length}`);

  if (posts.length === 0) {
    // Retorno vazio/ inválido não pode apagar o que já temos.
    console.log('instagram.sync.failed reason=empty_result');
    return keepPrevious('empty_result', duration());
  }

  const now = new Date().toISOString();
  const value: InstagramKvValue = {
    updatedAt: now,
    lastSuccessfulSyncAt: now,
    posts,
  };
  await env.SOCIAL_FEED_KV.put(kvKey, JSON.stringify(value));
  console.log(`instagram.sync.succeeded persisted=${posts.length} durationMs=${duration()}`);
  return { status: 'updated', received: items.length, persisted: posts.length, durationMs: duration() };
}

function keepPrevious(reason: string, durationMs: number): SyncOutcome {
  return { status: 'kept-previous', received: 0, persisted: 0, durationMs, reason };
}

async function fetchApifyItems(token: string, taskId: string): Promise<ApifyInstagramItem[]> {
  // `run-sync-get-dataset-items`: executa a Task e devolve o dataset na mesma
  // requisição — funciona mesmo sem run anterior/schedule.
  const url =
    `https://api.apify.com/v2/actor-tasks/${encodeURIComponent(taskId)}` +
    `/run-sync-get-dataset-items?clean=true&limit=${MAX_POSTS}`;

  const response = await fetch(url, {
    headers: { accept: 'application/json', authorization: `Bearer ${token}` },
    signal: AbortSignal.timeout(APIFY_TIMEOUT_MS),
  });
  if (!response.ok) {
    throw new Error(`Apify status ${response.status}`);
  }
  const data: unknown = await response.json();
  if (!Array.isArray(data)) {
    throw new Error('Apify não devolveu uma lista');
  }
  return data as ApifyInstagramItem[];
}

/** Identidade fixa a estampar em todo post, no lugar do owner cru do Apify
 * (ver doc de `ClubInstagramConfig.authorName`/`authorHandle`). */
export interface AuthorOverride {
  name: string;
  handle: string;
}

/** Mapeia + valida + ordena (mais recente primeiro) + limita a 5.
 *
 * [authorOverride] SÓ deve vir preenchido pra clube cuja Task raspa posts
 * colaborativos (ver `ClubInstagramConfig`) — sem ele (undefined, o caso do
 * Goiás, nunca alterado), author/username seguem crus do Apify, byte a byte,
 * como sempre foi. */
export function normalize(
  items: ApifyInstagramItem[],
  authorOverride?: AuthorOverride,
): StoredInstagramPost[] {
  return items
    .map((item): StoredInstagramPost | null => {
      const id = item.shortCode;
      const publishedAt = item.timestamp;
      const permalink = item.url;
      if (!id || !publishedAt || !permalink) return null;
      return {
        id,
        platform: 'instagram',
        // Sem fallback de clube cravado — sem override, o autor/handle vem
        // do próprio dado do Apify (a conta configurada na task DESTE
        // deploy). Ausente -> string vazia, nunca o nome/handle de um clube
        // específico.
        author: authorOverride?.name ?? item.ownerFullName ?? '',
        username: authorOverride?.handle ?? item.ownerUsername ?? '',
        caption: item.caption ?? '',
        mediaType: item.type ?? 'Image',
        mediaUrl: item.displayUrl ?? '',
        permalink,
        publishedAt,
      };
    })
    .filter((post): post is StoredInstagramPost => post !== null)
    .sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime())
    .slice(0, MAX_POSTS);
}

/**
 * Posts do X guardados no Workers KV (em vez do bundle estático
 * `data/<clube>/x_posts.json`). Criado em 2026-09-30 pro Vila Nova: o
 * GitHub Action (`sync_x_posts.yml`) coleta os posts e faz POST direto pro
 * Worker do clube, sem commit no repo — cada commit disparava builds do
 * Cloudflare nos Workers ligados ao Git.
 *
 * O feed lido pelo app só LÊ o KV (ver `XProvider`); quem escreve é
 * exclusivamente a rota admin `POST /api/social/x/sync`, protegida por
 * `X_SYNC_KEY`.
 */

import type { RawXPost } from './providers/x_provider';

export const MAX_X_POSTS = 20;

export interface XKvValue {
  updatedAt: string;
  posts: RawXPost[];
}

/** Nome da chave de KV do X por clube — `x:<code>:latest`. */
export function xKvKey(clubCode: string): string {
  return `x:${clubCode}:latest`;
}

function isRawXPost(value: unknown): value is RawXPost {
  if (!value || typeof value !== 'object') return false;
  const post = value as Record<string, unknown>;
  return (
    typeof post.tweet_id === 'string' &&
    post.tweet_id.length > 0 &&
    typeof post.timestamp === 'string' &&
    !Number.isNaN(Date.parse(post.timestamp)) &&
    typeof post.tweet_url === 'string' &&
    typeof post.text === 'string'
  );
}

/** Valida o corpo do POST (lista de posts no formato do `sync_x_posts.py`).
 * Devolve null se não for uma lista ou se nenhum item for válido — nesse
 * caso o KV anterior é mantido, nunca sobrescrito com lixo/vazio. */
export function parseXSyncBody(body: unknown, expectedHandle: string): RawXPost[] | null {
  if (!Array.isArray(body)) return null;
  const handle = expectedHandle.toLowerCase();
  const posts = body
    .filter(isRawXPost)
    // Só posts da conta oficial do clube deste deploy.
    .filter((p) => (p.user_screen_name ?? '').toLowerCase() === handle)
    .map((p) => ({ ...p, image_links: Array.isArray(p.image_links) ? p.image_links : [] }))
    .sort((a, b) => Date.parse(b.timestamp) - Date.parse(a.timestamp))
    .slice(0, MAX_X_POSTS);
  return posts.length > 0 ? posts : null;
}

export async function readXFromKv(kv: KVNamespace, kvKey: string): Promise<RawXPost[]> {
  const raw = await kv.get(kvKey);
  if (!raw) return [];
  try {
    const value = JSON.parse(raw) as XKvValue;
    return Array.isArray(value.posts) ? value.posts : [];
  } catch {
    return [];
  }
}

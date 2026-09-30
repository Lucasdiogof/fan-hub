import type { Env } from '../football/_lib/config';
import type { SocialProvider } from './types';
import type { ClubMediaConfig, XDataFileId } from './club_media_config';
import { YouTubeProvider } from './providers/youtube_provider';
import { InstagramProvider } from './providers/instagram_provider';
import { XProvider, type RawXPost } from './providers/x_provider';
import goiasXPosts from './data/goias/x_posts.json';
import bragantinoXPosts from './data/bragantino/x_posts.json';
import { readXFromKv } from './x_sync';

export interface SocialEnv extends Env {
  YOUTUBE_API_KEY?: string;
  /** KV persistente do feed (Instagram). Binding `SOCIAL_FEED_KV`. */
  SOCIAL_FEED_KV: KVNamespace;
  /** Secret do Worker — nunca no wrangler.toml, no Flutter ou na resposta. */
  APIFY_TOKEN?: string;
  /** Id da Task do Instagram Post Scraper (pode ficar em [vars]). */
  APIFY_INSTAGRAM_TASK_ID?: string;
  /** Secret que protege a rota admin de sync manual. */
  INSTAGRAM_SYNC_KEY?: string;
  /** Secret da rota admin `POST /api/social/x/sync` (clubes com X em KV). */
  X_SYNC_KEY?: string;
}

/** Bundle estático dos posts do X por clube — cada deploy só serve o do
 * próprio clube (a seleção é por `dataFile`, o gate garante o clube). */
function xDataFor(dataFile: XDataFileId): RawXPost[] {
  switch (dataFile) {
    case 'goias':
      return goiasXPosts as RawXPost[];
    case 'bragantino':
      return bragantinoXPosts as RawXPost[];
  }
}

/** Monta os providers a partir da config de Mídia do clube DESTE deploy.
 * Cada rede só entra se o clube a configura E (quando aplicável) o secret
 * do deploy existe. Rede sem config simplesmente não aparece no feed —
 * nunca cai pro dado de outro clube, e a ausência de uma não derruba as
 * outras (o `handleSocialFeed` já usa `Promise.allSettled`). */
export function loadSocialProviders(env: SocialEnv, media: ClubMediaConfig): SocialProvider[] {
  const providers: SocialProvider[] = [];

  if (media.youtube && env.YOUTUBE_API_KEY) {
    providers.push(
      new YouTubeProvider({
        apiKey: env.YOUTUBE_API_KEY,
        channelHandle: media.youtube.channelHandle,
        channelId: media.youtube.channelId,
        authorName: media.youtube.authorName,
        authorHandle: media.youtube.authorHandle,
      }),
    );
  }

  // Instagram lê SÓ a chave de KV do próprio clube (atualizada pelo Cron
  // deste deploy) — nunca chama o Apify aqui, nunca lê a chave de outro clube.
  if (media.instagram && env.SOCIAL_FEED_KV) {
    providers.push(new InstagramProvider(env, media.instagram.kvKey));
  }

  if (media.x?.dataFile) {
    providers.push(new XProvider(xDataFor(media.x.dataFile)));
  } else if (media.x?.kvKey && env.SOCIAL_FEED_KV) {
    const kvKey = media.x.kvKey;
    providers.push(new XProvider(() => readXFromKv(env.SOCIAL_FEED_KV, kvKey)));
  }

  return providers;
}

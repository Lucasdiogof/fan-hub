import type { Env } from '../football/_lib/config';
import type { SocialProvider } from './types';
import { YouTubeProvider } from './providers/youtube_provider';
import { InstagramProvider } from './providers/instagram_provider';
import { XProvider } from './providers/x_provider';

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
}

export function loadSocialProviders(env: SocialEnv): SocialProvider[] {
  const providers: SocialProvider[] = [];

  if (env.YOUTUBE_API_KEY) {
    providers.push(new YouTubeProvider({ apiKey: env.YOUTUBE_API_KEY }));
  }

  // Instagram lê só do KV (atualizado pelo Cron) — nunca chama o Apify aqui.
  providers.push(new InstagramProvider(env));
  providers.push(new XProvider());

  return providers;
}

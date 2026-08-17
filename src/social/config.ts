import type { Env } from '../football/_lib/config';
import type { SocialProvider } from './types';
import { YouTubeProvider } from './providers/youtube_provider';
import { InstagramProvider } from './providers/instagram_provider';
import { XProvider } from './providers/x_provider';

export interface SocialEnv extends Env {
  YOUTUBE_API_KEY?: string;
  META_ACCESS_TOKEN?: string;
  X_BEARER_TOKEN?: string;
}

export function loadSocialProviders(env: SocialEnv): SocialProvider[] {
  const providers: SocialProvider[] = [];

  if (env.YOUTUBE_API_KEY) {
    providers.push(new YouTubeProvider({ apiKey: env.YOUTUBE_API_KEY }));
  }

  providers.push(new InstagramProvider(env.META_ACCESS_TOKEN ?? null));
  providers.push(new XProvider(env.X_BEARER_TOKEN ?? null));

  return providers;
}

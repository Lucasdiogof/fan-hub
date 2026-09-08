import { cacheFirst } from '../football/_lib/cache';
import { jsonResponse, errorResponse } from '../football/_lib/respond';
import { isRequestedClubServed } from '../football/_lib/club_server_config';
import type { SocialEnv } from './config';
import { loadSocialProviders } from './config';
import { clubMediaConfig } from './club_media_config';
import type { SocialPost } from './types';

export async function handleSocialFeed(request: Request, env: SocialEnv): Promise<Response> {
  const url = new URL(request.url);
  const platformFilter = url.searchParams.get('platform');
  const cacheVersion = env.CACHE_VERSION || '1';

  // Gate por deploy: `?club=` diferente do `CLUB_CODE` deste Worker devolve
  // feed vazio explícito, NUNCA posts de outro clube. Cada provider é
  // montado a partir da config de Mídia do PRÓPRIO clube (redes sem config
  // simplesmente não entram no feed, sem derrubar as outras).
  if (!isRequestedClubServed(request, env)) {
    return jsonResponse({ posts: [], available: false }, { status: 404 });
  }
  const media = clubMediaConfig(env.CLUB_CODE);
  if (!media) {
    return jsonResponse({ posts: [], available: false }, { status: 404 });
  }

  try {
    return await cacheFirst(
      request,
      600,
      'social.feed',
      cacheVersion,
      async () => {
        const providers = loadSocialProviders(env, media);
        const activeProviders = platformFilter
          ? providers.filter(p => p.name === platformFilter)
          : providers;

        const results = await Promise.allSettled(
          activeProviders.map(p => p.fetch()),
        );

        const posts: SocialPost[] = [];
        for (const result of results) {
          if (result.status === 'fulfilled') {
            posts.push(...result.value);
          } else {
            console.log(`social.provider.error: ${result.reason}`);
          }
        }

        posts.sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime());

        return { posts };
      },
    );
  } catch (error) {
    console.log(`social.feed.error: ${error}`);
    return errorResponse('Erro ao carregar o feed social.');
  }
}

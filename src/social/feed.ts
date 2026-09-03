import { cacheFirst } from '../football/_lib/cache';
import { jsonResponse, errorResponse } from '../football/_lib/respond';
import { NEWS_SOCIAL_CONFIGURED_CLUB_CODE, resolveRequestedClubCode } from '../football/_lib/club_server_config';
import type { SocialEnv } from './config';
import { loadSocialProviders } from './config';
import type { SocialPost } from './types';

export async function handleSocialFeed(request: Request, env: SocialEnv): Promise<Response> {
  const url = new URL(request.url);
  const platformFilter = url.searchParams.get('platform');
  const cacheVersion = env.CACHE_VERSION || '1';

  // Achado da auditoria M4: os providers (Instagram/YouTube/TikTok/
  // Facebook/X) eram instanciados sem NENHUM parâmetro de clube — sempre o
  // feed do Goiás pra qualquer chamador. `?club=` diferente do único
  // integrado hoje devolve feed vazio explícito, nunca posts do Goiás.
  const clubCode = resolveRequestedClubCode(request);
  if (clubCode !== NEWS_SOCIAL_CONFIGURED_CLUB_CODE) {
    return jsonResponse({ posts: [], available: false }, { status: 404 });
  }

  try {
    return await cacheFirst(
      request,
      600,
      'social.feed',
      cacheVersion,
      async () => {
        const providers = loadSocialProviders(env);
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

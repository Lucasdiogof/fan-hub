import type { SocialPost, SocialProvider } from '../types';
import type { InstagramSyncEnv, StoredInstagramPost } from '../instagram_sync';
import { readInstagramFromKv } from '../instagram_sync';

/**
 * Fonte do Instagram no feed agregado. Lê SOMENTE o Workers KV — nunca chama o
 * Apify. Quem atualiza o KV é o Cron Trigger (ver `syncInstagram`), então
 * nenhum acesso de usuário dispara ou espera o scraper.
 */
export class InstagramProvider implements SocialProvider {
  name = 'instagram';

  /** [kvKey] é a chave do PRÓPRIO clube (`instagram:<code>:latest`, vinda da
   * `ClubMediaConfig`) — o provider nunca lê a chave de outro clube. */
  constructor(
    private readonly env: InstagramSyncEnv | null,
    private readonly kvKey: string,
  ) {}

  async fetch(): Promise<SocialPost[]> {
    if (!this.env?.SOCIAL_FEED_KV) return [];
    const stored = await readInstagramFromKv(this.env, this.kvKey);
    if (!stored) return [];
    return stored.posts.map(mapStoredToSocialPost);
  }
}

function mapStoredToSocialPost(post: StoredInstagramPost): SocialPost {
  const image = post.mediaUrl || undefined;
  return {
    id: `instagram-${post.id}`,
    platform: 'instagram',
    authorName: post.author,
    authorHandle: post.username,
    text: post.caption || undefined,
    mediaType: mapMediaType(post.mediaType),
    imageUrl: image,
    thumbnailUrl: image,
    publishedAt: post.publishedAt,
    permalink: post.permalink,
  };
}

function mapMediaType(type: string): SocialPost['mediaType'] {
  switch (type.toLowerCase()) {
    case 'video':
      return 'video';
    case 'sidecar':
    case 'carousel':
      return 'carousel';
    default:
      return 'image';
  }
}

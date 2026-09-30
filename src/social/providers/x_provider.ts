import type { SocialPost, SocialProvider } from '../types';

export interface RawXPost {
  tweet_id: string;
  text: string;
  timestamp: string;
  tweet_url: string;
  image_links: string[];
  user_screen_name: string;
  user_name: string;
  likes: number;
  retweets: number;
  comments: number;
}

export class XProvider implements SocialProvider {
  name = 'x';

  /** [rawPosts] é o arquivo de dados do PRÓPRIO clube (selecionado por
   * `ClubMediaConfig.x.dataFile` em `config.ts`) — o provider nunca importa
   * o arquivo de outro clube nem cai num handle fixo. Também aceita uma
   * função assíncrona — é como o Vila lê os posts do KV do próprio clube
   * (ver `x_sync.ts`). */
  constructor(private readonly source: RawXPost[] | (() => Promise<RawXPost[]>)) {}

  async fetch(): Promise<SocialPost[]> {
    const rawPosts = typeof this.source === 'function' ? await this.source() : this.source;
    return rawPosts
      .filter(post => post.tweet_id && post.timestamp)
      .map((post): SocialPost => {
        const image = post.image_links?.[0];
        return {
          id: `x-${post.tweet_id}`,
          platform: 'x',
          // Sem fallback de clube: autor/handle vêm do próprio dado (a conta
          // do clube deste deploy), ausente -> vazio, nunca "Goiás".
          authorName: post.user_name || '',
          authorHandle: post.user_screen_name || '',
          text: post.text || undefined,
          mediaType: image ? 'image' : 'text',
          imageUrl: image,
          publishedAt: post.timestamp,
          permalink: post.tweet_url,
          likes: post.likes,
          comments: post.comments,
          reposts: post.retweets,
        };
      });
  }
}

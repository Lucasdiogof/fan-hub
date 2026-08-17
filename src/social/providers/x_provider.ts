import type { SocialPost, SocialProvider } from '../types';
import rawPosts from '../data/x_posts.json';

interface RawXPost {
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

  async fetch(): Promise<SocialPost[]> {
    const posts = rawPosts as RawXPost[];
    return posts
      .filter(post => post.tweet_id && post.timestamp)
      .map((post): SocialPost => {
        const image = post.image_links?.[0];
        return {
          id: `x-${post.tweet_id}`,
          platform: 'x',
          authorName: post.user_name || 'Goiás Esporte Clube',
          authorHandle: post.user_screen_name || 'goiasoficial',
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

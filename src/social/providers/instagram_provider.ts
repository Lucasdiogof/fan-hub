import type { SocialPost, SocialProvider } from '../types';
import instagramData from '../data/instagram_posts.json';

interface RawInstagramPost {
  shortcode: string;
  caption: string;
  timestamp: string;
  permalink: string;
  media_type: 'image' | 'video' | 'carousel';
  image_url: string;
}

interface InstagramSnapshot {
  generatedAt: string | null;
  items: RawInstagramPost[];
}

export class InstagramProvider implements SocialProvider {
  name = 'instagram';

  async fetch(): Promise<SocialPost[]> {
    const { items } = instagramData as InstagramSnapshot;
    return items
      .filter(post => post.shortcode && post.timestamp)
      .map((post): SocialPost => {
        const image = post.image_url || undefined;
        return {
          id: `instagram-${post.shortcode}`,
          platform: 'instagram',
          authorName: 'Goiás Esporte Clube',
          authorHandle: 'goiasoficial',
          text: post.caption || undefined,
          mediaType: post.media_type,
          imageUrl: image,
          thumbnailUrl: image,
          publishedAt: post.timestamp,
          permalink: post.permalink,
        };
      });
  }
}

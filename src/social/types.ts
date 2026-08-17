export interface SocialPost {
  id: string;
  platform: 'youtube' | 'instagram' | 'x';
  authorName: string;
  authorHandle: string;
  authorAvatarUrl?: string;
  title?: string;
  text?: string;
  mediaType: 'text' | 'image' | 'video' | 'carousel';
  imageUrl?: string;
  thumbnailUrl?: string;
  publishedAt: string;
  permalink: string;
  likes?: number;
  comments?: number;
  views?: number;
  reposts?: number;
}

export interface SocialProvider {
  name: string;
  fetch(): Promise<SocialPost[]>;
}

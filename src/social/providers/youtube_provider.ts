import type { SocialPost, SocialProvider } from '../types';

const TV_GOIAS_HANDLE = '@TVGoias';
const YOUTUBE_API_BASE = 'https://www.googleapis.com/youtube/v3';

interface YouTubeConfig {
  apiKey: string;
}

export class YouTubeProvider implements SocialProvider {
  name = 'youtube';
  private apiKey: string;

  constructor(config: YouTubeConfig) {
    this.apiKey = config.apiKey;
  }

  async fetch(): Promise<SocialPost[]> {
    const channelId = await this.resolveChannelId();
    if (!channelId) return [];

    const uploadsPlaylistId = await this.getUploadsPlaylistId(channelId);
    if (!uploadsPlaylistId) return [];

    return this.getRecentVideos(uploadsPlaylistId);
  }

  private async resolveChannelId(): Promise<string | null> {
    const url = `${YOUTUBE_API_BASE}/channels?forHandle=${encodeURIComponent(TV_GOIAS_HANDLE)}&part=id,snippet,contentDetails&key=${this.apiKey}`;
    const response = await globalThis.fetch(url);
    if (!response.ok) {
      console.log(`youtube.resolveChannelId.error: ${response.status}`);
      return null;
    }
    const data = await response.json() as any;
    return data.items?.[0]?.id ?? null;
  }

  private async getUploadsPlaylistId(channelId: string): Promise<string | null> {
    const url = `${YOUTUBE_API_BASE}/channels?id=${channelId}&part=contentDetails&key=${this.apiKey}`;
    const response = await globalThis.fetch(url);
    if (!response.ok) return null;
    const data = await response.json() as any;
    return data.items?.[0]?.contentDetails?.relatedPlaylists?.uploads ?? null;
  }

  private async getRecentVideos(playlistId: string): Promise<SocialPost[]> {
    const url = `${YOUTUBE_API_BASE}/playlistItems?playlistId=${playlistId}&part=snippet,contentDetails&maxResults=15&key=${this.apiKey}`;
    const response = await globalThis.fetch(url);
    if (!response.ok) {
      console.log(`youtube.getRecentVideos.error: ${response.status}`);
      return [];
    }
    const data = await response.json() as any;
    const items: any[] = data.items ?? [];

    const videoIds = items.map((item: any) => item.contentDetails?.videoId).filter(Boolean);
    const stats = videoIds.length > 0 ? await this.getVideoStats(videoIds) : {};

    return items
      .filter((item: any) => item.snippet?.title !== 'Private video')
      .map((item: any): SocialPost => {
        const snippet = item.snippet;
        const videoId = item.contentDetails?.videoId;
        const videoStats = stats[videoId];
        const thumbnails = snippet.thumbnails;
        const thumbnail = thumbnails?.maxres?.url ?? thumbnails?.high?.url ?? thumbnails?.medium?.url ?? thumbnails?.default?.url;

        return {
          id: `yt-${videoId}`,
          platform: 'youtube',
          authorName: snippet.channelTitle ?? 'TV Goiás',
          authorHandle: 'TVGoias',
          title: snippet.title,
          text: snippet.description ? snippet.description.slice(0, 200) : undefined,
          mediaType: 'video',
          thumbnailUrl: thumbnail,
          publishedAt: snippet.publishedAt,
          permalink: `https://www.youtube.com/watch?v=${videoId}`,
          views: videoStats?.viewCount ? Number(videoStats.viewCount) : undefined,
          likes: videoStats?.likeCount ? Number(videoStats.likeCount) : undefined,
          comments: videoStats?.commentCount ? Number(videoStats.commentCount) : undefined,
        };
      });
  }

  private async getVideoStats(videoIds: string[]): Promise<Record<string, any>> {
    const url = `${YOUTUBE_API_BASE}/videos?id=${videoIds.join(',')}&part=statistics&key=${this.apiKey}`;
    const response = await globalThis.fetch(url);
    if (!response.ok) return {};
    const data = await response.json() as any;
    const result: Record<string, any> = {};
    for (const item of (data.items ?? [])) {
      result[item.id] = item.statistics;
    }
    return result;
  }
}

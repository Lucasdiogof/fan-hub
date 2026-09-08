import type { SocialPost, SocialProvider } from '../types';

const YOUTUBE_API_BASE = 'https://www.googleapis.com/youtube/v3';

interface YouTubeConfig {
  apiKey: string;
  /** Handle público do canal do clube (ex.: `@TVGoias`) — vem da
   * `ClubMediaConfig`, nunca cravado no provider. */
  channelHandle: string;
  authorName: string;
  authorHandle: string;
}

export class YouTubeProvider implements SocialProvider {
  name = 'youtube';
  private apiKey: string;
  private channelHandle: string;
  private authorName: string;
  private authorHandle: string;

  constructor(config: YouTubeConfig) {
    this.apiKey = config.apiKey;
    this.channelHandle = config.channelHandle;
    this.authorName = config.authorName;
    this.authorHandle = config.authorHandle;
  }

  async fetch(): Promise<SocialPost[]> {
    const uploadsPlaylistId = await this.resolveUploadsPlaylistId();
    if (!uploadsPlaylistId) return [];

    return this.getRecentVideos(uploadsPlaylistId);
  }

  // A resposta de /channels?forHandle já inclui contentDetails com a
  // playlist de uploads — não precisa de uma segunda chamada por
  // channels?id= só pra buscar a mesma coisa de novo (isso dobrava a
  // cadeia sequencial de requests e, na hora do cache expirar, às vezes
  // estourava o timeout do app).
  private async resolveUploadsPlaylistId(): Promise<string | null> {
    const url = `${YOUTUBE_API_BASE}/channels?forHandle=${encodeURIComponent(this.channelHandle)}&part=contentDetails&key=${this.apiKey}`;
    const response = await globalThis.fetch(url);
    if (!response.ok) {
      console.log(`youtube.resolveUploadsPlaylistId.error: ${response.status}`);
      return null;
    }
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
          authorName: snippet.channelTitle ?? this.authorName,
          authorHandle: this.authorHandle,
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

import { afterEach, describe, expect, it, vi } from 'vitest';
import { YouTubeProvider } from './youtube_provider';

function mockYouTubeApi({
  channelsRespondsTo,
  uploadsPlaylistId,
  videoIds,
}: {
  /** 'id' ou 'forHandle' — qual param a URL de /channels deve usar. */
  channelsRespondsTo: 'id' | 'forHandle';
  uploadsPlaylistId: string;
  videoIds: string[];
}) {
  global.fetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = typeof input === 'string' ? input : input.toString();
    if (url.includes('/channels?')) {
      const hasRightParam = channelsRespondsTo === 'id' ? url.includes('id=') : url.includes('forHandle=');
      const hasWrongParam = channelsRespondsTo === 'id' ? url.includes('forHandle=') : url.includes('&id=');
      if (!hasRightParam || hasWrongParam) {
        throw new Error(`URL de /channels não bate com o esperado (${channelsRespondsTo}): ${url}`);
      }
      return new Response(
        JSON.stringify({
          items: [{ contentDetails: { relatedPlaylists: { uploads: uploadsPlaylistId } } }],
        }),
        { status: 200 },
      );
    }
    if (url.includes('/playlistItems?')) {
      return new Response(
        JSON.stringify({
          items: videoIds.map((id, i) => ({
            snippet: {
              title: `Vídeo ${i + 1}`,
              description: 'Descrição de teste',
              channelTitle: 'Canal de Teste',
              publishedAt: `2026-09-0${i + 1}T12:00:00Z`,
              thumbnails: { high: { url: `https://i.ytimg.com/vi/${id}/hqdefault.jpg` } },
            },
            contentDetails: { videoId: id },
          })),
        }),
        { status: 200 },
      );
    }
    if (url.includes('/videos?')) {
      return new Response(
        JSON.stringify({
          items: videoIds.map((id) => ({ id, statistics: { viewCount: '10', likeCount: '2', commentCount: '1' } })),
        }),
        { status: 200 },
      );
    }
    throw new Error(`URL não mockada: ${url}`);
  }) as unknown as typeof fetch;
}

describe('YouTubeProvider — resolução da playlist de uploads por id (quando presente) ou por handle', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it('com channelId configurado, resolve por /channels?id= (nunca forHandle)', async () => {
    mockYouTubeApi({
      channelsRespondsTo: 'id',
      uploadsPlaylistId: 'UUxxxbragantino',
      videoIds: ['v1', 'v2', 'v3'],
    });
    const provider = new YouTubeProvider({
      apiKey: 'k',
      channelHandle: '@MassaBrutaTV',
      channelId: 'UC0x9Ypk2Z1lUdR4a88jMC2Q',
      authorName: 'Massa Bruta TV',
      authorHandle: 'MassaBrutaTV',
    });
    const posts = await provider.fetch();
    expect(posts).toHaveLength(3);
    expect(posts[0].platform).toBe('youtube');
    expect(posts[0].permalink).toBe('https://www.youtube.com/watch?v=v1');
  });

  it('sem channelId, cai pro comportamento de sempre (/channels?forHandle=) — Goiás intacto', async () => {
    mockYouTubeApi({
      channelsRespondsTo: 'forHandle',
      uploadsPlaylistId: 'UUxxxgoias',
      videoIds: ['g1', 'g2'],
    });
    const provider = new YouTubeProvider({
      apiKey: 'k',
      channelHandle: '@TVGoias',
      authorName: 'TV Goiás',
      authorHandle: 'TVGoias',
    });
    const posts = await provider.fetch();
    expect(posts).toHaveLength(2);
  });

  it('mapeia videoId/title/publishedAt/thumbnail/channelTitle corretamente', async () => {
    mockYouTubeApi({ channelsRespondsTo: 'id', uploadsPlaylistId: 'UUx', videoIds: ['abc123'] });
    const provider = new YouTubeProvider({
      apiKey: 'k',
      channelHandle: '@MassaBrutaTV',
      channelId: 'UC0x9Ypk2Z1lUdR4a88jMC2Q',
      authorName: 'Massa Bruta TV',
      authorHandle: 'MassaBrutaTV',
    });
    const [post] = await provider.fetch();
    expect(post.id).toBe('yt-abc123');
    expect(post.title).toBe('Vídeo 1');
    expect(post.publishedAt).toBe('2026-09-01T12:00:00Z');
    expect(post.thumbnailUrl).toBe('https://i.ytimg.com/vi/abc123/hqdefault.jpg');
    expect(post.authorName).toBe('Canal de Teste');
  });

  it('/channels sem uploads playlist -> lista vazia, nunca lança', async () => {
    global.fetch = vi.fn(async () => new Response(JSON.stringify({ items: [] }), { status: 200 })) as unknown as typeof fetch;
    const provider = new YouTubeProvider({
      apiKey: 'k',
      channelHandle: '@MassaBrutaTV',
      channelId: 'UC0x9Ypk2Z1lUdR4a88jMC2Q',
      authorName: 'Massa Bruta TV',
      authorHandle: 'MassaBrutaTV',
    });
    expect(await provider.fetch()).toEqual([]);
  });
});

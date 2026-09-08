import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  normalize,
  readInstagramFromKv,
  syncInstagram,
  type InstagramKvValue,
  type InstagramSyncEnv,
} from './instagram_sync';
import { instagramKvKey } from './club_media_config';
import { InstagramProvider } from './providers/instagram_provider';

const GK = instagramKvKey('goias');

interface ApifyRaw {
  shortCode?: string;
  type?: string;
  caption?: string;
  timestamp?: string;
  url?: string;
  displayUrl?: string;
  ownerFullName?: string;
  ownerUsername?: string;
}

function apifyItem(overrides: Partial<ApifyRaw> = {}): ApifyRaw {
  return {
    shortCode: 'DchQQ0OP5hp',
    type: 'Image',
    caption: 'Trabalho feito',
    timestamp: '2026-08-26T22:14:37.000Z',
    url: 'https://www.instagram.com/p/DchQQ0OP5hp/',
    displayUrl: 'https://cdn/img.jpg',
    ownerFullName: 'Goiás Esporte Clube | Oficial',
    ownerUsername: 'goiasoficial',
    ...overrides,
  };
}

/** KV em memória com inspeção do que foi persistido. */
function makeKv(initial?: InstagramKvValue, clubCode = 'goias') {
  let store: string | null = initial ? JSON.stringify(initial) : null;
  let lastPutKey: string | null = null;
  const kv = {
    get: async (_key: string) => store,
    put: async (key: string, value: string) => {
      lastPutKey = key;
      store = value;
    },
  };
  return {
    env: { CLUB_CODE: clubCode, SOCIAL_FEED_KV: kv } as unknown as InstagramSyncEnv,
    current: () => (store ? (JSON.parse(store) as InstagramKvValue) : null),
    raw: () => store,
    lastPutKey: () => lastPutKey,
  };
}

function stubFetch(handler: () => Promise<Response> | Response) {
  const fn = vi.fn(handler);
  vi.stubGlobal('fetch', fn);
  return fn;
}

afterEach(() => vi.unstubAllGlobals());

describe('normalize', () => {
  it('maps every Apify field to the stored shape', () => {
    const [post] = normalize([apifyItem()]);
    expect(post).toEqual({
      id: 'DchQQ0OP5hp',
      platform: 'instagram',
      author: 'Goiás Esporte Clube | Oficial',
      username: 'goiasoficial',
      caption: 'Trabalho feito',
      mediaType: 'Image',
      mediaUrl: 'https://cdn/img.jpg',
      permalink: 'https://www.instagram.com/p/DchQQ0OP5hp/',
      publishedAt: '2026-08-26T22:14:37.000Z',
    });
  });

  it('sorts by publishedAt, most recent first', () => {
    const posts = normalize([
      apifyItem({ shortCode: 'old', timestamp: '2026-08-01T00:00:00.000Z' }),
      apifyItem({ shortCode: 'new', timestamp: '2026-08-26T00:00:00.000Z' }),
      apifyItem({ shortCode: 'mid', timestamp: '2026-08-10T00:00:00.000Z' }),
    ]);
    expect(posts.map(p => p.id)).toEqual(['new', 'mid', 'old']);
  });

  it('keeps at most 5 posts', () => {
    const items = Array.from({ length: 9 }, (_, i) =>
      apifyItem({ shortCode: `p${i}`, timestamp: `2026-08-${10 + i}T00:00:00.000Z` }),
    );
    expect(normalize(items)).toHaveLength(5);
  });

  it('drops items missing shortCode, timestamp or url', () => {
    const posts = normalize([
      apifyItem({ shortCode: undefined }),
      apifyItem({ shortCode: 'a', timestamp: undefined }),
      apifyItem({ shortCode: 'b', url: undefined }),
      apifyItem({ shortCode: 'ok' }),
    ]);
    expect(posts.map(p => p.id)).toEqual(['ok']);
  });
});

describe('syncInstagram', () => {
  const env = (kvEnv: InstagramSyncEnv): InstagramSyncEnv => ({
    ...kvEnv,
    APIFY_TOKEN: 'secret',
    APIFY_INSTAGRAM_TASK_ID: 'task123',
  });

  it('writes the KV on a successful scrape and stamps the timestamps', async () => {
    const kv = makeKv();
    stubFetch(() => new Response(JSON.stringify([apifyItem()]), { status: 200 }));

    const outcome = await syncInstagram(env(kv.env));

    expect(outcome.status).toBe('updated');
    expect(outcome.persisted).toBe(1);
    const stored = kv.current()!;
    expect(stored.posts).toHaveLength(1);
    expect(stored.updatedAt).toBeTruthy();
    expect(stored.lastSuccessfulSyncAt).toBe(stored.updatedAt);
  });

  it('keeps the previous KV when Apify returns an HTTP error', async () => {
    const previous: InstagramKvValue = {
      updatedAt: '2026-01-01T00:00:00.000Z',
      lastSuccessfulSyncAt: '2026-01-01T00:00:00.000Z',
      posts: [
        {
          id: 'kept',
          platform: 'instagram',
          author: 'a',
          username: 'goiasoficial',
          caption: 'c',
          mediaType: 'Image',
          mediaUrl: 'u',
          permalink: 'https://insta/p/kept/',
          publishedAt: '2026-01-01T00:00:00.000Z',
        },
      ],
    };
    const kv = makeKv(previous);
    stubFetch(() => new Response('boom', { status: 500 }));

    const outcome = await syncInstagram(env(kv.env));

    expect(outcome.status).toBe('kept-previous');
    expect(kv.current()).toEqual(previous); // não sobrescreveu
  });

  it('does not overwrite the KV when Apify returns an empty list', async () => {
    const kv = makeKv();
    stubFetch(() => new Response('[]', { status: 200 }));

    const outcome = await syncInstagram(env(kv.env));

    expect(outcome.status).toBe('kept-previous');
    expect(outcome.reason).toBe('empty_result');
    expect(kv.raw()).toBeNull(); // nada foi escrito
  });

  it('keeps the previous KV when Apify returns invalid JSON', async () => {
    const kv = makeKv();
    stubFetch(() => new Response('not json', { status: 200 }));

    const outcome = await syncInstagram(env(kv.env));

    expect(outcome.status).toBe('kept-previous');
    expect(kv.raw()).toBeNull();
  });

  it('is a no-op without config (token/task id)', async () => {
    const kv = makeKv();
    const fetchFn = stubFetch(() => new Response('[]'));

    const outcome = await syncInstagram(kv.env); // sem APIFY_*

    expect(outcome.status).toBe('no-op');
    expect(fetchFn).not.toHaveBeenCalled();
  });
});

describe('readInstagramFromKv', () => {
  it('returns the parsed value', async () => {
    const value: InstagramKvValue = {
      updatedAt: 'x',
      lastSuccessfulSyncAt: 'x',
      posts: [],
    };
    const kv = makeKv(value);
    expect(await readInstagramFromKv(kv.env, GK)).toEqual(value);
  });

  it('returns null when the KV is empty or holds invalid JSON', async () => {
    expect(await readInstagramFromKv(makeKv().env, GK)).toBeNull();
    const bad = {
      env: { SOCIAL_FEED_KV: { get: async () => '{oops' } } as unknown as InstagramSyncEnv,
    };
    expect(await readInstagramFromKv(bad.env, GK)).toBeNull();
  });
});

describe('InstagramProvider', () => {
  it('reads the KV, maps to the feed shape and never calls Apify', async () => {
    const value: InstagramKvValue = {
      updatedAt: 'x',
      lastSuccessfulSyncAt: 'x',
      posts: [
        {
          id: 'abc',
          platform: 'instagram',
          author: 'Goiás',
          username: 'goiasoficial',
          caption: 'legenda',
          mediaType: 'Video',
          mediaUrl: 'https://cdn/v.jpg',
          permalink: 'https://insta/p/abc/',
          publishedAt: '2026-08-26T00:00:00.000Z',
        },
      ],
    };
    const kv = makeKv(value);
    const fetchFn = stubFetch(() => new Response('[]'));

    const posts = await new InstagramProvider(kv.env, GK).fetch();

    expect(fetchFn).not.toHaveBeenCalled(); // feed NUNCA chama o Apify
    expect(posts).toEqual([
      {
        id: 'instagram-abc',
        platform: 'instagram',
        authorName: 'Goiás',
        authorHandle: 'goiasoficial',
        text: 'legenda',
        mediaType: 'video',
        imageUrl: 'https://cdn/v.jpg',
        thumbnailUrl: 'https://cdn/v.jpg',
        publishedAt: '2026-08-26T00:00:00.000Z',
        permalink: 'https://insta/p/abc/',
      },
    ]);
  });

  it('returns an empty list when the KV is empty (no crash)', async () => {
    expect(await new InstagramProvider(makeKv().env, GK).fetch()).toEqual([]);
  });
});

describe('KV key por clube — isolamento cross-club', () => {
  it('a chave é sempre instagram:<code>:latest', () => {
    expect(instagramKvKey('goias')).toBe('instagram:goias:latest');
    expect(instagramKvKey('bragantino')).toBe('instagram:bragantino:latest');
  });

  it('CROSS-CLUB: o Cron do Bragantino escreve SÓ em instagram:bragantino:latest, NUNCA na chave do Goiás', async () => {
    const kv = makeKv(undefined, 'bragantino');
    stubFetch(() => new Response(JSON.stringify([apifyItem()]), { status: 200 }));
    const outcome = await syncInstagram({
      ...kv.env,
      APIFY_TOKEN: 'secret',
      APIFY_INSTAGRAM_TASK_ID: 'task123',
    });
    expect(outcome.status).toBe('updated');
    expect(kv.lastPutKey()).toBe('instagram:bragantino:latest');
    expect(kv.lastPutKey()).not.toBe('instagram:goias:latest');
  });

  it('sem CLUB_CODE o sync é no-op (nunca escreve numa chave de clube errado)', async () => {
    const kv = makeKv(undefined, '');
    const outcome = await syncInstagram({
      ...kv.env,
      APIFY_TOKEN: 'secret',
      APIFY_INSTAGRAM_TASK_ID: 'task123',
    });
    expect(outcome.status).toBe('no-op');
    expect(kv.lastPutKey()).toBeNull();
  });
});

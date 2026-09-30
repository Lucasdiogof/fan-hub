import { describe, expect, it } from 'vitest';
import { clubMediaConfig } from './club_media_config';
import { MAX_X_POSTS, parseXSyncBody, xKvKey } from './x_sync';

function post(id: string, timestamp: string, handle = 'vilanovafc') {
  return {
    tweet_id: id,
    text: `post ${id}`,
    timestamp,
    tweet_url: `https://x.com/${handle}/status/${id}`,
    image_links: [],
    user_screen_name: handle,
    user_name: 'Vila Nova F.C.',
    likes: 1,
    retweets: 0,
    comments: 0,
  };
}

describe('parseXSyncBody', () => {
  it('ordena do mais recente pro mais antigo', () => {
    const posts = parseXSyncBody(
      [post('1', '2026-09-28T10:00:00+00:00'), post('2', '2026-09-29T10:00:00+00:00')],
      'vilanovafc',
    );
    expect(posts!.map((p) => p.tweet_id)).toEqual(['2', '1']);
  });

  it('descarta post de outra conta (nunca mistura clube) e compara handle sem caixa', () => {
    const posts = parseXSyncBody(
      [post('1', '2026-09-29T10:00:00+00:00', 'VilaNovaFC'), post('2', '2026-09-29T11:00:00+00:00', 'goiasoficial')],
      'vilanovafc',
    );
    expect(posts!.map((p) => p.tweet_id)).toEqual(['1']);
  });

  it(`limita a ${MAX_X_POSTS}`, () => {
    const many = Array.from({ length: 30 }, (_, i) =>
      post(String(i), new Date(Date.UTC(2026, 8, 1, i)).toISOString()),
    );
    expect(parseXSyncBody(many, 'vilanovafc')).toHaveLength(MAX_X_POSTS);
  });

  it('corpo inválido ou sem post válido -> null (KV anterior é mantido)', () => {
    expect(parseXSyncBody({ posts: [] }, 'vilanovafc')).toBeNull();
    expect(parseXSyncBody([], 'vilanovafc')).toBeNull();
    expect(parseXSyncBody([{ tweet_id: '1' }], 'vilanovafc')).toBeNull();
    expect(parseXSyncBody([post('1', 'não é data')], 'vilanovafc')).toBeNull();
  });
});

describe('X do Vila Nova vem do KV do próprio clube', () => {
  it('config usa kvKey x:vilanova:latest com o handle oficial, nunca bundle de outro clube', () => {
    const x = clubMediaConfig('vilanova')?.x;
    expect(x).toEqual({ kvKey: xKvKey('vilanova'), handle: 'vilanovafc' });
    expect(x?.dataFile).toBeUndefined();
  });

  it('Goiás e Bragantino continuam no bundle estático de sempre', () => {
    expect(clubMediaConfig('goias')?.x).toEqual({ dataFile: 'goias' });
    expect(clubMediaConfig('bragantino')?.x).toEqual({ dataFile: 'bragantino' });
  });
});

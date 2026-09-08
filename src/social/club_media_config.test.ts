import { describe, expect, it } from 'vitest';
import { CLUB_MEDIA_CONFIG, clubMediaConfig, instagramKvKey } from './club_media_config';
import { loadSocialProviders, type SocialEnv } from './config';

describe('CLUB_MEDIA_CONFIG — resolução central por clube, sem fallback cross-club', () => {
  it('clube desconhecido -> null (NUNCA cai pro Goiás)', () => {
    expect(clubMediaConfig('club-b')).toBeNull();
    expect(clubMediaConfig('')).toBeNull();
    expect(clubMediaConfig('inter')).toBeNull();
  });

  it('Goiás tem as 4 fontes com dado real', () => {
    const g = clubMediaConfig('goias')!;
    expect(g.news?.sourceUrl).toBe('https://www.goiasec.com.br/noticias');
    expect(g.news?.parser).toBe('goias');
    expect(g.youtube?.channelHandle).toBe('@TVGoias');
    expect(g.instagram?.kvKey).toBe('instagram:goias:latest');
    expect(g.x?.dataFile).toBe('goias');
  });

  it('Bragantino: news real (API JSON própria, confirmada 2026-09-08); youtube/x seguem WAITING', () => {
    const b = clubMediaConfig('bragantino')!;
    expect(b.news?.parser).toBe('bragantino');
    expect(b.news?.siteOrigin).toBe('https://www.redbullbragantino.com');
    expect(b.news?.articlePathPrefix).toBe('/br-pt/noticias');
    expect(b.news?.sourceUrl).toContain('redbullbragantino.com');
    expect(b.youtube).toBeUndefined(); // canal não confirmado -> nunca @TVGoias
    expect(b.x).toBeUndefined(); // handle/pipeline não configurado
    expect(b.instagram?.kvKey).toBe('instagram:bragantino:latest');
  });

  it('NENHUMA config de Bragantino contém string do Goiás', () => {
    const json = JSON.stringify(CLUB_MEDIA_CONFIG.bragantino);
    for (const termo of ['goias', 'goiasec', 'goiasoficial', 'TVGoias']) {
      expect(json.toLowerCase()).not.toContain(termo.toLowerCase());
    }
  });

  it('instagramKvKey é sempre instagram:<code>:latest', () => {
    expect(instagramKvKey('goias')).toBe('instagram:goias:latest');
    expect(instagramKvKey('bragantino')).toBe('instagram:bragantino:latest');
  });
});

describe('loadSocialProviders — providers montados por clube', () => {
  const withSecrets = (code: string): SocialEnv =>
    ({
      CLUB_CODE: code,
      CACHE_VERSION: '1',
      YOUTUBE_API_KEY: 'k',
      SOCIAL_FEED_KV: {} as KVNamespace,
    }) as SocialEnv;
  const noSecrets = (code: string): SocialEnv =>
    ({ CLUB_CODE: code, CACHE_VERSION: '1' }) as SocialEnv;

  it('Goiás com secrets -> youtube + instagram + x', () => {
    const names = loadSocialProviders(withSecrets('goias'), clubMediaConfig('goias')!).map(p => p.name);
    expect(names.sort()).toEqual(['instagram', 'x', 'youtube']);
  });

  it('Goiás sem secrets -> só x (youtube exige API key, instagram exige KV)', () => {
    const names = loadSocialProviders(noSecrets('goias'), clubMediaConfig('goias')!).map(p => p.name);
    expect(names).toEqual(['x']);
  });

  it('Bragantino: com KV -> só instagram; sem KV -> nenhum. NUNCA youtube(@TVGoias)/x(goias)', () => {
    const comKv = loadSocialProviders(withSecrets('bragantino'), clubMediaConfig('bragantino')!).map(p => p.name);
    expect(comKv).toEqual(['instagram']); // youtube/x ausentes na config -> nunca entram
    const semKv = loadSocialProviders(noSecrets('bragantino'), clubMediaConfig('bragantino')!).map(p => p.name);
    expect(semKv).toEqual([]);
  });
});

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

  it('Bragantino: news + youtube reais (confirmados 2026-09-08); x segue WAITING', () => {
    const b = clubMediaConfig('bragantino')!;
    expect(b.news?.parser).toBe('bragantino');
    expect(b.news?.siteOrigin).toBe('https://www.redbullbragantino.com');
    expect(b.news?.articlePathPrefix).toBe('/br-pt/noticias');
    expect(b.news?.sourceUrl).toContain('redbullbragantino.com');
    expect(b.x).toBeUndefined(); // handle/pipeline não configurado
    expect(b.instagram?.kvKey).toBe('instagram:bragantino:latest');
  });

  it('Bragantino: youtube é @MassaBrutaTV, com channelId real confirmado — nunca @TVGoias', () => {
    const b = clubMediaConfig('bragantino')!;
    expect(b.youtube?.channelHandle).toBe('@MassaBrutaTV');
    expect(b.youtube?.channelId).toBe('UC0x9Ypk2Z1lUdR4a88jMC2Q');
    expect(b.youtube?.authorHandle).toBe('MassaBrutaTV');
    expect(b.youtube?.channelHandle).not.toBe('@TVGoias');
    expect(b.youtube?.authorName).not.toContain('Goiás');
  });

  it('Goiás mantém o youtube exatamente como antes (sem channelId, comportamento intocado)', () => {
    const g = clubMediaConfig('goias')!;
    expect(g.youtube?.channelHandle).toBe('@TVGoias');
    expect(g.youtube?.channelId).toBeUndefined();
    expect(g.youtube?.authorName).toBe('TV Goiás');
    expect(g.youtube?.authorHandle).toBe('TVGoias');
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

  it('Bragantino: com secrets -> youtube + instagram (x ausente na config); sem secrets -> nenhum', () => {
    const comSecrets = loadSocialProviders(withSecrets('bragantino'), clubMediaConfig('bragantino')!).map(p => p.name);
    expect(comSecrets.sort()).toEqual(['instagram', 'youtube']);
    const semSecrets = loadSocialProviders(noSecrets('bragantino'), clubMediaConfig('bragantino')!).map(p => p.name);
    expect(semSecrets).toEqual([]); // WAITING_EXTERNAL_SECRET: sem YOUTUBE_API_KEY/KV, nenhum provider entra
  });

  it('Bragantino sem YOUTUBE_API_KEY (estado real de produção hoje) -> youtube nunca entra, mas instagram (com KV) sim', () => {
    const soComKv: SocialEnv = {
      CLUB_CODE: 'bragantino',
      CACHE_VERSION: '1',
      SOCIAL_FEED_KV: {} as KVNamespace,
    } as SocialEnv;
    const names = loadSocialProviders(soComKv, clubMediaConfig('bragantino')!).map(p => p.name);
    expect(names).toEqual(['instagram']);
  });

  it('feed agregado nunca derruba quando só 1 provider está de pé (allSettled tolera provider ausente)', () => {
    // loadSocialProviders já é o que decide quais entram — aqui só provamos
    // que passar env com 1 secret só (o cenário real do Bragantino hoje: só
    // KV do Instagram, sem YOUTUBE_API_KEY) nunca lança nem exige os outros.
    const env: SocialEnv = { CLUB_CODE: 'bragantino', CACHE_VERSION: '1', SOCIAL_FEED_KV: {} as KVNamespace } as SocialEnv;
    expect(() => loadSocialProviders(env, clubMediaConfig('bragantino')!)).not.toThrow();
  });
});

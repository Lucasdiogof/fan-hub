import { describe, expect, it } from 'vitest';
import { CLUB_MEDIA_CONFIG, clubMediaConfig, instagramKvKey } from './club_media_config';
import { loadSocialProviders, type SocialEnv } from './config';
import { XProvider } from './providers/x_provider';

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
    expect(g.instagram?.authorName).toBeUndefined();
    expect(g.instagram?.authorHandle).toBeUndefined();
    expect(g.x?.dataFile).toBe('goias');
  });

  it('Bragantino: news + youtube + x reais (confirmados 2026-09-08)', () => {
    const b = clubMediaConfig('bragantino')!;
    expect(b.news?.parser).toBe('bragantino');
    expect(b.news?.siteOrigin).toBe('https://www.redbullbragantino.com');
    expect(b.news?.articlePathPrefix).toBe('/br-pt/noticias');
    expect(b.news?.sourceUrl).toContain('redbullbragantino.com');
    expect(b.x?.dataFile).toBe('bragantino');
    expect(b.instagram?.kvKey).toBe('instagram:bragantino:latest');
  });

  it('Bragantino: instagram tem authorOverride (redbullbragantino) pra corrigir posts colaborativos — Goiás nunca tem isso', () => {
    const b = clubMediaConfig('bragantino')!;
    expect(b.instagram?.authorName).toBe('Red Bull Bragantino');
    expect(b.instagram?.authorHandle).toBe('redbullbragantino');
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

  it('Bragantino: com secrets -> youtube + instagram + x; sem secrets -> só x (dado estático, sem secret nenhum)', () => {
    const comSecrets = loadSocialProviders(withSecrets('bragantino'), clubMediaConfig('bragantino')!).map(p => p.name);
    expect(comSecrets.sort()).toEqual(['instagram', 'x', 'youtube']);
    const semSecrets = loadSocialProviders(noSecrets('bragantino'), clubMediaConfig('bragantino')!).map(p => p.name);
    // X é bundle estático — não depende de YOUTUBE_API_KEY nem de
    // SOCIAL_FEED_KV, então é o único que sobrevive sem nenhum secret.
    expect(semSecrets).toEqual(['x']);
  });

  it('Bragantino sem YOUTUBE_API_KEY (estado real de produção até o X) -> youtube nunca entra, instagram (com KV) e x sim', () => {
    const soComKv: SocialEnv = {
      CLUB_CODE: 'bragantino',
      CACHE_VERSION: '1',
      SOCIAL_FEED_KV: {} as KVNamespace,
    } as SocialEnv;
    const names = loadSocialProviders(soComKv, clubMediaConfig('bragantino')!).map(p => p.name);
    expect(names.sort()).toEqual(['instagram', 'x']);
  });

  it('X: cada clube resolve SÓ o próprio arquivo de dados — zero fallback cross-club', async () => {
    const goiasProvider = loadSocialProviders(noSecrets('goias'), clubMediaConfig('goias')!).find(
      p => p.name === 'x',
    )!;
    const bragantinoProvider = loadSocialProviders(noSecrets('bragantino'), clubMediaConfig('bragantino')!).find(
      p => p.name === 'x',
    )!;
    expect(goiasProvider).toBeInstanceOf(XProvider);
    expect(bragantinoProvider).toBeInstanceOf(XProvider);

    const goiasPosts = await goiasProvider.fetch();
    const bragantinoPosts = await bragantinoProvider.fetch();

    expect(goiasPosts.length).toBeGreaterThan(0);
    expect(bragantinoPosts.length).toBeGreaterThan(0);

    // Nenhum post do Goiás aparece no feed do Bragantino, e vice-versa —
    // provado pelo handle do autor, não só pela contagem.
    expect(goiasPosts.every(p => p.authorHandle !== 'RedBullBraga')).toBe(true);
    expect(bragantinoPosts.every(p => p.authorHandle === 'RedBullBraga')).toBe(true);
    expect(bragantinoPosts.every(p => p.authorName === 'Red Bull Bragantino')).toBe(true);
    expect(bragantinoPosts.some(p => p.authorHandle === 'goiasoficial')).toBe(false);

    const bragantinoBlob = JSON.stringify(bragantinoPosts).toLowerCase();
    for (const termo of ['goiasoficial', 'goiás', 'goias esporte', 'esmeraldin']) {
      expect(bragantinoBlob).not.toContain(termo.toLowerCase());
    }
  });

  it('feed agregado nunca derruba quando só 1 provider está de pé (allSettled tolera provider ausente)', () => {
    // loadSocialProviders já é o que decide quais entram — aqui só provamos
    // que passar env com 1 secret só (o cenário real do Bragantino hoje: só
    // KV do Instagram, sem YOUTUBE_API_KEY) nunca lança nem exige os outros.
    const env: SocialEnv = { CLUB_CODE: 'bragantino', CACHE_VERSION: '1', SOCIAL_FEED_KV: {} as KVNamespace } as SocialEnv;
    expect(() => loadSocialProviders(env, clubMediaConfig('bragantino')!)).not.toThrow();
  });
});

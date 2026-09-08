import { describe, expect, it } from 'vitest';
import { env as rawEnv } from 'cloudflare:test';
import type { Env } from './config';
import {
  resolveClubServerConfig,
  UnknownClubError,
  isRequestedClubServed,
  resolveRequestedClubCode,
} from './club_server_config';

// `cloudflare:test`'s `env` é populado do `wrangler.toml` (Goiás, ver
// vitest.config.mts) pelo vitest-pool-workers — é o deploy REAL do Goiás,
// não um mock.
const goiasEnv = rawEnv as unknown as Env;

// FABRICADO — não existe um 2º pool do vitest-pool-workers pro
// `wrangler.bragantino.toml` nesta rodada (0 deploy, 0 infra nova); como
// `resolveClubServerConfig` é uma função PURA (só lê o `Env` que recebe,
// nunca `cloudflare:test` internamente), um objeto `Env` construído à mão
// representando "se este fosse o deploy do Bragantino" prova exatamente o
// mesmo comportamento sem precisar de um Worker de verdade no ar.
const fakeBragantinoEnv: Env = {
  CLUB_CODE: 'bragantino',
  TEAM_ONEFOOTBALL_SLUG: 'rb-bragantino-4734',
  PRIMARY_COMPETITION_SLUG: 'brasileirao-betano-16',
  PRIMARY_COMPETITION_DISPLAY_NAME: 'Brasileirão Série A',
  CACHE_VERSION: '1',
  ASSETS: goiasEnv.ASSETS,
};

describe('resolveClubServerConfig — deploy do Goiás (wrangler.toml real)', () => {
  it("'goias' resolve com sucesso, lendo TEAM_ONEFOOTBALL_SLUG real do wrangler.toml", () => {
    const config = resolveClubServerConfig('goias', goiasEnv);
    expect(config.code).toBe('goias');
    expect(config.oneFootballSlug).toBe(goiasEnv.TEAM_ONEFOOTBALL_SLUG);
    expect(config.oneFootballSlug).toBe('goias-1863');
  });

  it('clubCode desconhecido lança UnknownClubError — NUNCA cai pro Goiás por omissão', () => {
    expect(() => resolveClubServerConfig('club-b', goiasEnv)).toThrow(UnknownClubError);
    expect(() => resolveClubServerConfig('juventude', goiasEnv)).toThrow(UnknownClubError);
    expect(() => resolveClubServerConfig('', goiasEnv)).toThrow(UnknownClubError);
  });

  it('CROSS-CLUB: o Worker do Goiás rejeita "bragantino" (nunca resolve pro Goiás por engano)', () => {
    expect(() => resolveClubServerConfig('bragantino', goiasEnv)).toThrow(UnknownClubError);
    expect(() => resolveClubServerConfig('bragantino', goiasEnv)).toThrow('unknown club code: bragantino');
  });
});

describe('resolveClubServerConfig — FABRICADO: deploy do Bragantino (Env construído à mão)', () => {
  it("'bragantino' resolve com sucesso contra o CLUB_CODE do próprio deploy", () => {
    const config = resolveClubServerConfig('bragantino', fakeBragantinoEnv);
    expect(config.code).toBe('bragantino');
    expect(config.oneFootballSlug).toBe('rb-bragantino-4734');
  });

  it('CROSS-CLUB: o Worker do Bragantino rejeita "goias" (nunca resolve pro Bragantino por engano)', () => {
    expect(() => resolveClubServerConfig('goias', fakeBragantinoEnv)).toThrow(UnknownClubError);
    expect(() => resolveClubServerConfig('goias', fakeBragantinoEnv)).toThrow('unknown club code: goias');
  });

  it('CLUB_CODE ausente/vazio nunca resolve silenciosamente — lança ConfigError', () => {
    const misconfigured: Env = { ...fakeBragantinoEnv, CLUB_CODE: '' };
    expect(() => resolveClubServerConfig('bragantino', misconfigured)).toThrow();
    expect(() => resolveClubServerConfig('', misconfigured)).toThrow();
  });
});

describe('TEAM vs PRIMARY COMPETITION — dados por clube nunca se confundem', () => {
  it('Goiás: oneFootballSlug (TEAM) != competitionSlug (PRIMARY COMPETITION), cada um com sua env var própria', () => {
    expect(goiasEnv.TEAM_ONEFOOTBALL_SLUG).toBe('goias-1863');
    expect(goiasEnv.PRIMARY_COMPETITION_SLUG).toBe('brasileirao-serie-b-superbet-119');
    expect(goiasEnv.PRIMARY_COMPETITION_DISPLAY_NAME).toBe('Brasileirão Série B');
  });

  it('Bragantino (fabricado): TEAM = rb-bragantino-4734, PRIMARY COMPETITION = Série A — nunca a Série B do Goiás', () => {
    expect(fakeBragantinoEnv.TEAM_ONEFOOTBALL_SLUG).toBe('rb-bragantino-4734');
    expect(fakeBragantinoEnv.PRIMARY_COMPETITION_SLUG).toBe('brasileirao-betano-16');
    expect(fakeBragantinoEnv.PRIMARY_COMPETITION_DISPLAY_NAME).toBe('Brasileirão Série A');
    expect(fakeBragantinoEnv.PRIMARY_COMPETITION_SLUG).not.toBe(goiasEnv.PRIMARY_COMPETITION_SLUG);
    expect(fakeBragantinoEnv.PRIMARY_COMPETITION_DISPLAY_NAME).not.toBe(goiasEnv.PRIMARY_COMPETITION_DISPLAY_NAME);
  });

  it('resolveClubServerConfig só expõe TEAM (oneFootballSlug) — PRIMARY COMPETITION nunca vaza pra dentro do ClubServerConfig', () => {
    // `/team/:clubCode` e `/team/:clubCode/season` (handlers que chamam
    // resolveClubServerConfig) são endpoints orientados a TIME — nunca
    // assumem qual campeonato o time está jogando, por isso devolvem jogos
    // de QUALQUER competição que o time participa. `standings`/
    // `current-round` são os únicos orientados a competição, e leem
    // PRIMARY_COMPETITION_SLUG direto do config, nunca via
    // ClubServerConfig.
    const config = resolveClubServerConfig('goias', goiasEnv);
    const configAsRecord = config as unknown as Record<string, unknown>;
    expect(configAsRecord.primaryCompetitionSlug).toBeUndefined();
    expect(configAsRecord.oneFootballCompetitionSlug).toBeUndefined();
  });
});

describe('gate de News/Social por env.CLUB_CODE (sem mais a constante NEWS_SOCIAL_CONFIGURED_CLUB_CODE)', () => {
  it('sem ?club= -> resolve pro CLUB_CODE do PRÓPRIO deploy, nunca um "goias" mágico cravado', () => {
    expect(resolveRequestedClubCode(new Request('https://x/api/news'), goiasEnv)).toBe('goias');
    expect(resolveRequestedClubCode(new Request('https://x/api/news'), fakeBragantinoEnv)).toBe('bragantino');
  });

  it('?club= explícito -> resolve o código pedido, nunca reescreve por conta própria', () => {
    expect(resolveRequestedClubCode(new Request('https://x/api/news?club=club-b'), goiasEnv)).toBe('club-b');
  });

  it('CROSS-CLUB: cada deploy só SERVE o próprio clube (goias<->bragantino nos dois sentidos)', () => {
    // Worker do Goiás: serve goias (com ou sem ?club=), rejeita bragantino.
    expect(isRequestedClubServed(new Request('https://x/api/news?club=goias'), goiasEnv)).toBe(true);
    expect(isRequestedClubServed(new Request('https://x/api/news'), goiasEnv)).toBe(true);
    expect(isRequestedClubServed(new Request('https://x/api/news?club=bragantino'), goiasEnv)).toBe(false);
    // Worker do Bragantino: serve bragantino, rejeita goias.
    expect(isRequestedClubServed(new Request('https://x/api/news?club=bragantino'), fakeBragantinoEnv)).toBe(true);
    expect(isRequestedClubServed(new Request('https://x/api/news?club=goias'), fakeBragantinoEnv)).toBe(false);
  });

  it('CLUB_CODE ausente/vazio nunca serve — config quebrada vira vazio, nunca cross-club', () => {
    const broken: Env = { ...goiasEnv, CLUB_CODE: '' };
    expect(isRequestedClubServed(new Request('https://x/api/news?club=goias'), broken)).toBe(false);
    expect(isRequestedClubServed(new Request('https://x/api/news'), broken)).toBe(false);
  });
});

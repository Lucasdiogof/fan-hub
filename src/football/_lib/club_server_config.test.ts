import { describe, expect, it } from 'vitest';
import { env as rawEnv } from 'cloudflare:test';
import type { Env } from './config';
import { resolveClubServerConfig, UnknownClubError, SERVER_CLUB_CODES } from './club_server_config';

// `cloudflare:test`'s `env` é tipado pelo `Env` global gerado por
// `wrangler types` — este projeto não gera esse arquivo, então o tipo
// exportado é genérico. As vars REAIS vêm certas em runtime (populadas do
// `wrangler.toml` pelo próprio vitest-pool-workers) — só o cast é preciso
// pra bater com o tipo `Env` real do módulo sob teste.
const env = rawEnv as unknown as Env;

describe('resolveClubServerConfig', () => {
  it("'goias' resolve com sucesso, lendo o slug real do wrangler.toml (env.GOIAS_ONEFOOTBALL_SLUG)", () => {
    const config = resolveClubServerConfig('goias', env);
    expect(config.code).toBe('goias');
    expect(config.canonicalClubId).toBe('4c16340d-300c-5ab2-903f-17519db9b146');
    expect(config.oneFootballTeamId).toBe(1863);
    expect(config.oneFootballSlug).toBe(env.GOIAS_ONEFOOTBALL_SLUG);
  });

  it('clubCode desconhecido lança UnknownClubError — NUNCA cai pro Goiás por omissão', () => {
    expect(() => resolveClubServerConfig('club-b', env)).toThrow(UnknownClubError);
    expect(() => resolveClubServerConfig('juventude', env)).toThrow(UnknownClubError);
    expect(() => resolveClubServerConfig('', env)).toThrow(UnknownClubError);
  });

  it('SERVER_CLUB_CODES tem exatamente 1 código (goias) — SECOND_CLUB_BLOCKED', () => {
    expect(SERVER_CLUB_CODES).toEqual(['goias']);
  });
});

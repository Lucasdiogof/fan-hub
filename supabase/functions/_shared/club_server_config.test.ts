import { describe, expect, it } from 'vitest';
import { resolveClubServerConfigByClubId, resolveClubServerConfigByCode, SERVER_CLUB_REGISTRY } from './club_server_config';

const GOIAS_CANONICAL_CLUB_ID = '4c16340d-300c-5ab2-903f-17519db9b146';

describe('resolveClubServerConfigByClubId', () => {
  it('UUID real do Goiás resolve pra config do Goiás', () => {
    const config = resolveClubServerConfigByClubId(GOIAS_CANONICAL_CLUB_ID);
    expect(config?.code).toBe('goias');
    expect(config?.oneFootballTeamId).toBe(1863);
    expect(config?.shortName).toBe('Goiás');
  });

  it('UUID desconhecido — falha controlada (undefined), NUNCA cai pro Goiás', () => {
    const config = resolveClubServerConfigByClubId('deadbeef-0000-0000-0000-000000000000');
    expect(config).toBeUndefined();
  });

  it('string vazia/malformada também falha controlado, nunca lança nem resolve Goiás', () => {
    expect(resolveClubServerConfigByClubId('')).toBeUndefined();
    expect(resolveClubServerConfigByClubId('not-a-uuid')).toBeUndefined();
  });
});

describe('resolveClubServerConfigByCode', () => {
  it("code 'goias' resolve pra config do Goiás", () => {
    const config = resolveClubServerConfigByCode('goias');
    expect(config?.canonicalClubId).toBe(GOIAS_CANONICAL_CLUB_ID);
    expect(config?.oneFootballTeamPath).toBe('goias');
  });

  it('code desconhecido — falha controlada (undefined), NUNCA cai pro Goiás', () => {
    expect(resolveClubServerConfigByCode('club-b')).toBeUndefined();
    expect(resolveClubServerConfigByCode('juventude')).toBeUndefined();
    expect(resolveClubServerConfigByCode('')).toBeUndefined();
  });
});

describe('SERVER_CLUB_REGISTRY — Goiás + Bragantino + Vila Nova, nenhum 4º clube sem autorização', () => {
  it('tem exatamente 3 entradas: goias, bragantino e vilanova', () => {
    expect(SERVER_CLUB_REGISTRY).toHaveLength(3);
    expect(SERVER_CLUB_REGISTRY.map((c) => c.code).sort()).toEqual(['bragantino', 'goias', 'vilanova']);
  });

  it('cada clube tem workerBaseUrl PRÓPRIO — nunca os 2 apontando pro mesmo Worker', () => {
    const urls = SERVER_CLUB_REGISTRY.map((c) => c.workerBaseUrl);
    expect(new Set(urls).size).toBe(SERVER_CLUB_REGISTRY.length);
  });
});

describe('resolveClubServerConfigByClubId/ByCode — Bragantino', () => {
  const BRAGANTINO_CANONICAL_CLUB_ID = '51683d2a-ea1d-57c6-8014-996146f242e7';

  it('UUID real do Bragantino resolve pra config do Bragantino, nunca a do Goiás', () => {
    const config = resolveClubServerConfigByClubId(BRAGANTINO_CANONICAL_CLUB_ID);
    expect(config?.code).toBe('bragantino');
    expect(config?.oneFootballTeamId).toBe(4734);
    expect(config?.workerBaseUrl).toBe('https://bragantino-app.lucasdiogo1234.workers.dev');
  });

  it("code 'bragantino' resolve pra config do Bragantino", () => {
    const config = resolveClubServerConfigByCode('bragantino');
    expect(config?.canonicalClubId).toBe(BRAGANTINO_CANONICAL_CLUB_ID);
  });
});

describe('resolveClubServerConfigByClubId/ByCode — Vila Nova', () => {
  const VILANOVA_CANONICAL_CLUB_ID = '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e';

  it('UUID real do Vila Nova resolve pra config do Vila, nunca a do Goiás', () => {
    const config = resolveClubServerConfigByClubId(VILANOVA_CANONICAL_CLUB_ID);
    expect(config?.code).toBe('vilanova');
    expect(config?.oneFootballTeamId).toBe(2865);
    expect(config?.shortName).toBe('Vila Nova');
    expect(config?.workerBaseUrl).toBe('https://vilanova-app.lucasdiogo1234.workers.dev');
  });

  it("code 'vilanova' resolve pra config do Vila Nova", () => {
    const config = resolveClubServerConfigByCode('vilanova');
    expect(config?.canonicalClubId).toBe(VILANOVA_CANONICAL_CLUB_ID);
    expect(config?.oneFootballTeamPath).toBe('vilanova');
  });
});

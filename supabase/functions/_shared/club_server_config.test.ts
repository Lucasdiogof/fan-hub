import { describe, expect, it } from 'vitest';
import { resolveClubServerConfigByClubId, resolveClubServerConfigByCode, SERVER_CLUB_REGISTRY } from './club_server_config';

const GOIAS_CANONICAL_CLUB_ID = '4c16340d-300c-5ab2-903f-17519db9b146';

describe('resolveClubServerConfigByClubId', () => {
  it('UUID real do Goiás resolve pra config do Goiás', () => {
    const config = resolveClubServerConfigByClubId(GOIAS_CANONICAL_CLUB_ID);
    expect(config?.code).toBe('goias');
    expect(config?.oneFootballTeamId).toBe(1863);
    expect(config?.notificationGoalClubName).toBe('Goiás');
    expect(config?.notificationVictoryNickname).toBe('Verdão');
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

describe('SERVER_CLUB_REGISTRY — SECOND_CLUB_BLOCKED', () => {
  it('tem exatamente 1 entrada (goias) — nenhum 2º clube real registrado', () => {
    expect(SERVER_CLUB_REGISTRY).toHaveLength(1);
    expect(SERVER_CLUB_REGISTRY[0].code).toBe('goias');
  });
});

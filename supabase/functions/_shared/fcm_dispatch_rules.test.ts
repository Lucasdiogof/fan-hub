import { describe, expect, it } from 'vitest';
import { isInvalidTokenError, isStuckProcessing } from './fcm_dispatch_rules';

describe('isInvalidTokenError', () => {
  it('404 -> token inválido', () => {
    expect(isInvalidTokenError(404, '')).toBe(true);
  });

  it('corpo contém UNREGISTERED -> token inválido', () => {
    expect(isInvalidTokenError(400, '{"error":{"details":[{"errorCode":"UNREGISTERED"}]}}')).toBe(true);
  });

  it('corpo contém NOT_FOUND -> token inválido', () => {
    expect(isInvalidTokenError(400, '{"error":{"status":"NOT_FOUND"}}')).toBe(true);
  });

  it('erro transitório (500, quota, rede) -> NUNCA marca token como inválido', () => {
    expect(isInvalidTokenError(500, 'internal error')).toBe(false);
    expect(isInvalidTokenError(429, 'quota exceeded')).toBe(false);
    expect(isInvalidTokenError(400, 'INVALID_ARGUMENT')).toBe(false);
  });
});

describe('isStuckProcessing', () => {
  const now = new Date('2026-09-11T12:00:00Z');

  it('detected_at há mais de threshold minutos -> travado, reclama', () => {
    const sixMinutesAgo = new Date(now.getTime() - 6 * 60 * 1000).toISOString();
    expect(isStuckProcessing(sixMinutesAgo, now, 5)).toBe(true);
  });

  it('detected_at há menos de threshold minutos -> ainda processando normalmente, NUNCA rouba', () => {
    const twoMinutesAgo = new Date(now.getTime() - 2 * 60 * 1000).toISOString();
    expect(isStuckProcessing(twoMinutesAgo, now, 5)).toBe(false);
  });

  it('exatamente no limite -> não travado ainda (só depois do threshold)', () => {
    const exactlyFiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000).toISOString();
    expect(isStuckProcessing(exactlyFiveMinutesAgo, now, 5)).toBe(false);
  });
});

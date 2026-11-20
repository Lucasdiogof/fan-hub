import { describe, expect, it } from 'vitest';
import { computeBackoff, computeRefresh } from './policy';

const MIN = 60_000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;
// 20/11/2026 20:00 no Brasil (UTC-3) = 23:00Z
const NOW = new Date('2026-11-20T23:00:00Z');
const kick = (offsetMs: number) => {
  // kickoff "naive" em horário do Brasil, deslocado do NOW
  const d = new Date(NOW.getTime() + offsetMs - 3 * HOUR);
  return d.toISOString().slice(0, 19);
};
const team = (status: string, offsetMs: number) => ({ nextMatch: { status, kickoff: kick(offsetMs) }, recentResults: [] });
const dNext = (p: { nextRefreshAt: Date | null }) => (p.nextRefreshAt ? p.nextRefreshAt.getTime() - NOW.getTime() : null);
const dExp = (p: { expiresAt: Date }) => p.expiresAt.getTime() - NOW.getTime();

describe('computeRefresh — team', () => {
  it('ao vivo / intervalo: +60s, expira em 5min', () => {
    for (const s of ['live', 'halftime']) {
      const p = computeRefresh('team', team(s, -30 * MIN), NOW);
      expect(dNext(p)).toBe(60_000);
      expect(dExp(p)).toBe(5 * MIN);
    }
  });
  it('kickoff em < 2h: +5min, expira em 6h', () => {
    const p = computeRefresh('team', team('scheduled', 90 * MIN), NOW);
    expect(dNext(p)).toBe(5 * MIN);
    expect(dExp(p)).toBe(6 * HOUR);
  });
  it('encerrado há pouco (< 3h após o fim): +10min', () => {
    const p = computeRefresh('team', team('finished', -3 * HOUR), NOW);
    expect(dNext(p)).toBe(10 * MIN);
    expect(dExp(p)).toBe(7 * DAY);
  });
  it('encerrado antigo: +60min, expira em 7d (não 24h fixo)', () => {
    const p = computeRefresh('team', team('finished', -2 * DAY), NOW);
    expect(dNext(p)).toBe(HOUR);
    expect(dExp(p)).toBe(7 * DAY);
  });
  it('agendado distante: +60min, expira em 6h', () => {
    const p = computeRefresh('team', team('scheduled', 3 * DAY), NOW);
    expect(dNext(p)).toBe(HOUR);
    expect(dExp(p)).toBe(6 * HOUR);
  });
  it('"agendado" com kickoff já passado conta como ao vivo (até 3h)', () => {
    expect(dNext(computeRefresh('team', team('scheduled', -20 * MIN), NOW))).toBe(60_000);
    expect(dNext(computeRefresh('team', team('scheduled', -4 * HOUR), NOW))).toBe(HOUR);
  });
  it('adiado/cancelado: cadência lenta', () => {
    for (const s of ['postponed', 'cancelled']) expect(dNext(computeRefresh('team', team(s, DAY), NOW))).toBe(HOUR);
  });
  it('vence o estado mais urgente entre nextMatch e último resultado', () => {
    const p = computeRefresh(
      'team',
      { nextMatch: { status: 'scheduled', kickoff: kick(3 * DAY) }, recentResults: [{ status: 'live', kickoff: kick(-MIN) }] },
      NOW,
    );
    expect(dNext(p)).toBe(60_000);
  });
  it('payload vazio não quebra', () => {
    const p = computeRefresh('team', { nextMatch: null, recentResults: [] }, NOW);
    expect(dNext(p)).toBe(HOUR);
  });
});

describe('computeRefresh — demais kinds', () => {
  it('fixture encerrada antiga: nunca mais busca, expira em 30d', () => {
    const p = computeRefresh('fixture', { match: { status: 'finished', kickoff: kick(-5 * DAY) } }, NOW);
    expect(p.nextRefreshAt).toBeNull();
    expect(dExp(p)).toBe(30 * DAY);
  });
  it('fixture ao vivo: +60s', () => {
    expect(dNext(computeRefresh('fixture', { match: { status: 'live', kickoff: kick(-MIN) } }, NOW))).toBe(60_000);
  });
  it('current_round: ao vivo 2min/30min; senão 30min/7d', () => {
    const live = computeRefresh('current_round', { matches: [{ status: 'live', kickoff: kick(-MIN) }] }, NOW);
    expect([dNext(live), dExp(live)]).toEqual([2 * MIN, 30 * MIN]);
    const calm = computeRefresh('current_round', { matches: [{ status: 'scheduled', kickoff: kick(2 * DAY) }] }, NOW);
    expect([dNext(calm), dExp(calm)]).toEqual([30 * MIN, 7 * DAY]);
  });
  it('season 30min/7d, standings 1h/7d, competitions nunca/365d', () => {
    const s = computeRefresh('season', {}, NOW);
    expect([dNext(s), dExp(s)]).toEqual([30 * MIN, 7 * DAY]);
    const st = computeRefresh('standings', {}, NOW);
    expect([dNext(st), dExp(st)]).toEqual([HOUR, 7 * DAY]);
    const c = computeRefresh('competitions', {}, NOW);
    expect([c.nextRefreshAt, dExp(c)]).toEqual([null, 365 * DAY]);
  });
  it('nenhum kind expira em exatamente 24h', () => {
    for (const k of ['team', 'season', 'standings', 'current_round'] as const) {
      expect(dExp(computeRefresh(k, { matches: [], nextMatch: null }, NOW))).not.toBe(DAY);
    }
  });
});

describe('computeBackoff', () => {
  it('5, 10, 20, 40, 60 (teto) minutos', () => {
    const mins = [1, 2, 3, 4, 5, 6, 20].map((n) => (computeBackoff(n, NOW).getTime() - NOW.getTime()) / MIN);
    expect(mins).toEqual([5, 10, 20, 40, 60, 60, 60]);
  });
});

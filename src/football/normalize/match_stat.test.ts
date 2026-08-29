import { describe, expect, it } from 'vitest';
import { normalizeOneFootballMatchStat } from './match_stat';

describe('normalizeOneFootballMatchStat', () => {
  it('maps PERCENT unit and passes through home/away', () => {
    const stat = normalizeOneFootballMatchStat({ title: 'Posse de bola', unit: 'PERCENT', home: 20, away: 80 });
    expect(stat).toEqual({ title: 'Posse de bola', unit: 'percent', home: 20, away: 80 });
  });

  it('defaults to count unit when the source has none', () => {
    const stat = normalizeOneFootballMatchStat({ title: 'Escanteios', home: 3, away: 1 });
    expect(stat.unit).toBe('count');
  });

  it('treats a missing home/away as null, never a 0 the source never sent', () => {
    const stat = normalizeOneFootballMatchStat({ title: 'Total de chutes' });
    expect(stat.home).toBeNull();
    expect(stat.away).toBeNull();
  });
});

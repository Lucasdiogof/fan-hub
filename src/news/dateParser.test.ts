import { describe, expect, it } from 'vitest';
import { parsePortugueseDate } from './dateParser';

describe('parsePortugueseDate', () => {
  it('parses the listing page format ("18 de agosto 2026")', () => {
    expect(parsePortugueseDate('18 de agosto 2026')).toBe('2026-08-18');
  });

  it('parses the article page format ("18 ago. 2026")', () => {
    expect(parsePortugueseDate('18 ago. 2026')).toBe('2026-08-18');
  });

  it('strips a leading "Publicado" label', () => {
    expect(parsePortugueseDate('Publicado 22 ago. 2026')).toBe('2026-08-22');
  });

  it('pads single-digit days and months', () => {
    expect(parsePortugueseDate('5 de março 2026')).toBe('2026-03-05');
  });

  it('is case-insensitive', () => {
    expect(parsePortugueseDate('5 DE MARÇO 2026')).toBe('2026-03-05');
  });

  it('handles every month abbreviation used by the site', () => {
    const cases: Array<[string, string]> = [
      ['1 jan. 2026', '2026-01-01'],
      ['1 fev. 2026', '2026-02-01'],
      ['1 mar. 2026', '2026-03-01'],
      ['1 abr. 2026', '2026-04-01'],
      ['1 mai. 2026', '2026-05-01'],
      ['1 jun. 2026', '2026-06-01'],
      ['1 jul. 2026', '2026-07-01'],
      ['1 ago. 2026', '2026-08-01'],
      ['1 set. 2026', '2026-09-01'],
      ['1 out. 2026', '2026-10-01'],
      ['1 nov. 2026', '2026-11-01'],
      ['1 dez. 2026', '2026-12-01'],
    ];
    for (const [input, expected] of cases) {
      expect(parsePortugueseDate(input)).toBe(expected);
    }
  });

  it('returns null for unrecognizable text', () => {
    expect(parsePortugueseDate('data desconhecida')).toBeNull();
  });

  it('returns null for an empty string', () => {
    expect(parsePortugueseDate('')).toBeNull();
  });

  it('returns null for an unknown month name', () => {
    expect(parsePortugueseDate('18 de xisde 2026')).toBeNull();
  });
});

import { describe, expect, it } from 'vitest';
import {
  isKnockoutRoundLabel,
  isKnockoutSection,
  normalizeLegLabel,
  parseSectionSubtitle,
} from './phase_name';

describe('normalizeLegLabel', () => {
  it.each([
    ['Jogo de ida', 'FIRST'],
    ['jogo de ida', 'FIRST'],
    ['Ida', 'FIRST'],
    ['Jogo de volta', 'SECOND'],
    ['Volta', 'SECOND'],
  ] as const)('%s -> %s', (raw, expected) => {
    expect(normalizeLegLabel(raw)).toBe(expected);
  });

  it('rótulo desconhecido -> null, nunca chuta', () => {
    expect(normalizeLegLabel('Prorrogação')).toBeNull();
  });
});

describe('isKnockoutRoundLabel — vocabulário controlado, baseado em strings reais', () => {
  it.each([
    'Playoff',
    'Play-off',
    'Play-offs',
    'Repescagem',
    'Oitavas',
    'Oitavas de final',
    'Quartas',
    'Quartas de final',
    'Semifinal',
    'Semifinais',
    'Final',
    '3a Fase',
    '4a Fase',
  ])('%s é reconhecido como rodada de mata-mata', (label) => {
    expect(isKnockoutRoundLabel(label)).toBe(true);
  });

  it.each(['Fase de liga', 'Fase de Grupos', 'Rodada 12', 'Grupo A', ''])(
    '%s NÃO é rodada de mata-mata (fase de tabela)',
    (label) => {
      expect(isKnockoutRoundLabel(label)).toBe(false);
    },
  );

  it('não classifica qualquer "Fase X" como mata-mata — só o padrão numérico "<dígito>a Fase"', () => {
    expect(isKnockoutRoundLabel('Fase Regular')).toBe(false);
    expect(isKnockoutRoundLabel('Fase de Liga')).toBe(false);
  });
});

describe('parseSectionSubtitle — subtitles reais do OneFootball', () => {
  it('"Final" (Copa do Brasil, jogo único) -> round=Final, leg=SINGLE', () => {
    expect(parseSectionSubtitle('Final')).toEqual({ round: 'Final', leg: 'SINGLE' });
  });

  it('"Semifinais - Jogo de ida" (Copa do Brasil) -> round=Semifinais, leg=FIRST', () => {
    expect(parseSectionSubtitle('Semifinais - Jogo de ida')).toEqual({
      round: 'Semifinais',
      leg: 'FIRST',
    });
  });

  it('"Fase de liga" (Champions, fase de tabela atual) -> round=Fase de liga, leg=SINGLE', () => {
    expect(parseSectionSubtitle('Fase de liga')).toEqual({ round: 'Fase de liga', leg: 'SINGLE' });
  });

  it('"Repescagem - Volta" (Sudamericana) -> round=Repescagem, leg=SECOND', () => {
    expect(parseSectionSubtitle('Repescagem - Volta')).toEqual({
      round: 'Repescagem',
      leg: 'SECOND',
    });
  });

  it('"3a Fase - volta" (Champions, classificatória) -> round=3a Fase, leg=SECOND', () => {
    expect(parseSectionSubtitle('3a Fase - volta')).toEqual({ round: '3a Fase', leg: 'SECOND' });
  });

  it('subtitle ausente -> null', () => {
    expect(parseSectionSubtitle(undefined)).toBeNull();
  });
});

describe('isKnockoutSection', () => {
  it('"Fase de liga" não é seção de mata-mata', () => {
    expect(isKnockoutSection({ round: 'Fase de liga', leg: 'SINGLE' })).toBe(false);
  });

  it('"Final" (sem perna, mas no vocabulário) é seção de mata-mata', () => {
    expect(isKnockoutSection({ round: 'Final', leg: 'SINGLE' })).toBe(true);
  });

  it('qualquer round com perna explícita é seção de mata-mata, mesmo fora do vocabulário', () => {
    expect(isKnockoutSection({ round: 'Repescagem', leg: 'FIRST' })).toBe(true);
  });
});

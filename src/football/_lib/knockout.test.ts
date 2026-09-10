import { describe, expect, it } from 'vitest';
import {
  buildKnockoutRounds,
  hasAnyDecidedMatch,
  selectKnockoutSections,
  tableSectionLabel,
  tableWindowFrom,
} from './knockout';
import type { OneFootballMatchCard, OneFootballMatchList } from '../providers/onefootball_provider';

function card(
  matchId: string,
  home: { name: string; id: number; score?: string },
  away: { name: string; id: number; score?: string },
  kickoff: string,
  period: string,
): OneFootballMatchCard {
  return {
    matchId,
    link: `/pt-br/match/${matchId}`,
    kickoff,
    period,
    homeTeam: {
      name: home.name,
      score: home.score,
      imageObject: { path: `https://images.onefootball.com/icons/teams/164/${home.id}.png` },
    },
    awayTeam: {
      name: away.name,
      score: away.score,
      imageObject: { path: `https://images.onefootball.com/icons/teams/164/${away.id}.png` },
    },
  };
}

describe('buildKnockoutRounds', () => {
  it('ignora listas sem subtitle reconhecível (ex.: sem round/leg nenhum)', () => {
    const lists: OneFootballMatchList[] = [{ matchCards: [card('1', { name: 'A', id: 1 }, { name: 'B', id: 2 }, '2026-01-01T00:00:00Z', 'PRE_MATCH')] }];
    expect(buildKnockoutRounds(lists)).toEqual([]);
  });

  it('jogo único (SINGLE) vira uma fase com uma tie de uma perna só', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Final' },
        matchCards: [
          card('1', { name: 'Grêmio', id: 1670, score: '2' }, { name: 'Internacional', id: 1799, score: '1' }, '2026-12-06T00:00:00Z', 'FULL_TIME'),
        ],
      },
    ];
    const rounds = buildKnockoutRounds(lists);
    expect(rounds).toHaveLength(1);
    expect(rounds[0].name).toBe('Final');
    expect(rounds[0].ties).toHaveLength(1);
    const tie = rounds[0].ties[0];
    expect(tie.legs).toHaveLength(1);
    expect(tie.legs[0].legType).toBe('SINGLE');
    expect(tie.aggregateHome).toBe(2);
    expect(tie.aggregateAway).toBe(1);
    expect(rounds[0].status).toBe('COMPLETED');
    expect(rounds[0].isCurrent).toBe(true);
  });

  it('ida e volta com mandante trocado soma o agregado do lado certo', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Quartas de final - Jogo de ida' },
        matchCards: [card('1', { name: 'Time A', id: 10, score: '1' }, { name: 'Time B', id: 20, score: '0' }, '2026-08-01T00:00:00Z', 'FULL_TIME')],
      },
      {
        sectionHeader: { subtitle: 'Quartas de final - Jogo de volta' },
        matchCards: [card('2', { name: 'Time B', id: 20, score: '2' }, { name: 'Time A', id: 10, score: '2' }, '2026-08-08T00:00:00Z', 'FULL_TIME')],
      },
    ];
    const rounds = buildKnockoutRounds(lists);
    expect(rounds).toHaveLength(1);
    const tie = rounds[0].ties[0];
    expect(tie.legs.map((l) => l.legType)).toEqual(['FIRST', 'SECOND']);
    // Ida: A 1x0 B. Volta: B 2x2 A (mandante trocado). Agregado: A 3x2 B.
    expect(tie.aggregateHome).toBe(3);
    expect(tie.aggregateAway).toBe(2);
    expect(tie.homeTeam.name).toBe('Time A');
    expect(tie.awayTeam.name).toBe('Time B');
  });

  it('confronto futuro sem placar nenhum -> agregado null, nunca 0 inventado', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Oitavas de final - Jogo de ida' },
        matchCards: [card('1', { name: 'Time A', id: 10 }, { name: 'Time B', id: 20 }, '2026-09-20T00:00:00Z', 'PRE_MATCH')],
      },
    ];
    const rounds = buildKnockoutRounds(lists);
    expect(rounds[0].ties[0].aggregateHome).toBeNull();
    expect(rounds[0].ties[0].aggregateAway).toBeNull();
    expect(rounds[0].status).toBe('UPCOMING');
  });

  it('ordena fases pelo kickoff mais antigo, nunca por uma lista fixa de nomes', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Final' },
        matchCards: [card('3', { name: 'C', id: 3 }, { name: 'D', id: 4 }, '2026-12-06T00:00:00Z', 'PRE_MATCH')],
      },
      {
        sectionHeader: { subtitle: 'Semifinais - Jogo de ida' },
        matchCards: [card('1', { name: 'A', id: 1 }, { name: 'B', id: 2 }, '2026-11-01T00:00:00Z', 'PRE_MATCH')],
      },
    ];
    const rounds = buildKnockoutRounds(lists);
    expect(rounds.map((r) => r.name)).toEqual(['Semifinais', 'Final']);
  });

  it('fase atual = a primeira ainda não completa; se tudo terminou, a última', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Oitavas de final' },
        matchCards: [card('1', { name: 'A', id: 1, score: '1' }, { name: 'B', id: 2, score: '0' }, '2026-08-01T00:00:00Z', 'FULL_TIME')],
      },
      {
        sectionHeader: { subtitle: 'Quartas de final' },
        matchCards: [card('2', { name: 'A', id: 1 }, { name: 'C', id: 3 }, '2026-08-15T00:00:00Z', 'PRE_MATCH')],
      },
    ];
    const rounds = buildKnockoutRounds(lists);
    expect(rounds[0].status).toBe('COMPLETED');
    expect(rounds[0].isCurrent).toBe(false);
    expect(rounds[1].status).toBe('UPCOMING');
    expect(rounds[1].isCurrent).toBe(true);
  });

  it('penalties sempre null — nenhuma partida real de pênaltis confirmada na investigação (ver phase_name.ts/relatório)', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Final' },
        matchCards: [
          card('1', { name: 'A', id: 1, score: '1' }, { name: 'B', id: 2, score: '1' }, '2026-08-01T00:00:00Z', 'FULL_TIME'),
        ],
      },
    ];
    const tie = buildKnockoutRounds(lists)[0].ties[0];
    expect(tie.penaltyHome).toBeNull();
    expect(tie.penaltyAway).toBeNull();
  });
});

// Fixtures abaixo espelham as janelas REAIS observadas ao vivo em 2026-09-11
// (ver cabeçalho de `knockout.ts`/`phase_name.ts`): Champions com "Fase de
// liga" começando DEPOIS da "Repescagem"/"3a Fase" classificatória;
// Sudamericana sem nenhuma seção de fase de tabela na janela atual (grupos
// já fora da paginação), só seções de mata-mata em sequência cronológica.
describe('tableWindowFrom / selectKnockoutSections — filtro cronológico (spec item 1/2)', () => {
  const championsLists: OneFootballMatchList[] = [
    {
      sectionHeader: { subtitle: '3a Fase - volta' },
      matchCards: [card('q1', { name: 'X', id: 1 }, { name: 'Y', id: 2 }, '2026-08-11T15:00:00Z', 'FULL_TIME')],
    },
    {
      sectionHeader: { subtitle: 'Repescagem - Ida' },
      matchCards: [card('q2', { name: 'X', id: 1 }, { name: 'Z', id: 3 }, '2026-08-18T19:00:00Z', 'FULL_TIME')],
    },
    {
      sectionHeader: { subtitle: 'Repescagem - Volta' },
      matchCards: [card('q3', { name: 'Z', id: 3 }, { name: 'X', id: 1 }, '2026-08-25T16:45:00Z', 'FULL_TIME')],
    },
    {
      sectionHeader: { subtitle: 'Fase de liga' },
      matchCards: [card('l1', { name: 'PSG', id: 263 }, { name: 'Barcelona', id: 5 }, '2026-09-08T16:45:00Z', 'FULL_TIME')],
    },
  ];

  it('Champions: fase de tabela detectada = "Fase de liga", começando em 2026-09-08', () => {
    const window = tableWindowFrom(championsLists);
    expect(window).not.toBeNull();
    expect(new Date(window!.earliestKickoffMs).toISOString()).toBe('2026-09-08T16:45:00.000Z');
    expect(tableSectionLabel(championsLists)).toBe('Fase de liga');
  });

  it('Champions: "Repescagem"/"3a Fase" (ANTES da fase de liga) são excluídas — nenhuma fase de mata-mata inventada', () => {
    const window = tableWindowFrom(championsLists);
    const knockout = selectKnockoutSections(championsLists, window);
    expect(knockout).toEqual([]);
  });

  const sudamericanaLists: OneFootballMatchList[] = [
    {
      sectionHeader: { subtitle: 'Repescagem - Volta' },
      matchCards: [card('r1', { name: 'A', id: 10 }, { name: 'B', id: 20 }, '2026-07-28T22:00:00Z', 'FULL_TIME')],
    },
    {
      sectionHeader: { subtitle: 'Oitavas de final - Jogo de ida' },
      matchCards: [card('o1', { name: 'C', id: 30 }, { name: 'D', id: 40 }, '2026-08-11T22:00:00Z', 'FULL_TIME')],
    },
    {
      sectionHeader: { subtitle: 'Quartas de final - Jogo de ida' },
      matchCards: [card('q1', { name: 'E', id: 50 }, { name: 'F', id: 60 }, '2026-09-08T22:00:00Z', 'PRE_MATCH')],
    },
  ];

  it('Sudamericana: sem fase de tabela na janela atual (grupos fora da paginação) -> tableWindow nulo', () => {
    expect(tableWindowFrom(sudamericanaLists)).toBeNull();
    expect(tableSectionLabel(sudamericanaLists)).toBeNull();
  });

  it('Sudamericana: sem tableWindow, TODAS as seções de mata-mata são aceitas (Repescagem inclusa — é pós-grupos aqui, não pré-temporada)', () => {
    const knockout = selectKnockoutSections(sudamericanaLists, null);
    expect(knockout).toHaveLength(3);
    const rounds = buildKnockoutRounds(knockout);
    expect(rounds.map((r) => r.name)).toEqual(['Repescagem', 'Oitavas de final', 'Quartas de final']);
  });

  it('Copa do Brasil (sem nenhuma seção de tabela): comportamento intacto, todas as seções viram mata-mata', () => {
    const copaLists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Semifinais - Jogo de ida' },
        matchCards: [card('s1', { name: 'A', id: 1 }, { name: 'B', id: 2 }, '2026-11-01T12:00:00Z', 'PRE_MATCH')],
      },
    ];
    expect(tableWindowFrom(copaLists)).toBeNull();
    expect(selectKnockoutSections(copaLists, null)).toHaveLength(1);
  });
});

// Bugs reais achados testando ao vivo 2026-09-11 (ver relatório): o mesmo
// confronto aparecendo em `jogos` E `resultados` ao mesmo tempo dobrava o
// agregado (Sudamericana Santos 2x0 Atlético-MG virava "4x0" na tela); dois
// confrontos DIFERENTES de uma rodada ainda não decidida (Repescagem da
// Série B, "Home"/"Guest") tinham o MESMO escudo genérico e se fundiam
// numa tie só de 4 pernas em vez de 2 ties de 2 pernas cada.
describe('buildKnockoutRounds — bugs reais 2026-09-11', () => {
  it('mesmo matchId em jogos+resultados -> dedupe, nunca dobra o agregado', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Quartas de final - Jogo de ida' },
        matchCards: [card('2730019', { name: 'Santos', id: 1 }, { name: 'Atlético-MG', id: 2, score: '0' }, '2026-09-08T22:00:00Z', 'FULL_TIME')],
      },
    ];
    // Duplica a MESMA lista (era exatamente isso que `jogos`+`resultados`
    // devolviam pro mesmo matchId).
    const duplicated = [...lists, ...lists].map((l) => ({
      ...l,
      matchCards: l.matchCards.map((c) => ({ ...c, homeTeam: { ...c.homeTeam, score: '2' } })),
    }));
    const rounds = buildKnockoutRounds(duplicated);
    expect(rounds).toHaveLength(1);
    expect(rounds[0].ties).toHaveLength(1);
    expect(rounds[0].ties[0].legs).toHaveLength(1);
    expect(rounds[0].ties[0].aggregateHome).toBe(2);
    expect(rounds[0].ties[0].aggregateAway).toBe(0);
  });

  it('dois confrontos "Home"/"Guest" (times ainda não decididos) NUNCA se fundem numa tie só', () => {
    const placeholderCard = (matchId: string, kickoff: string) =>
      card(matchId, { name: 'Home', id: 57744 }, { name: 'Guest', id: 57745 }, kickoff, 'PRE_MATCH');
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Repescagem - Ida' },
        matchCards: [placeholderCard('1', '2026-11-21T12:00:00Z'), placeholderCard('2', '2026-11-21T12:00:00Z')],
      },
      {
        sectionHeader: { subtitle: 'Repescagem - Volta' },
        matchCards: [placeholderCard('3', '2026-11-28T12:00:00Z'), placeholderCard('4', '2026-11-28T12:00:00Z')],
      },
    ];
    const rounds = buildKnockoutRounds(lists);
    expect(rounds).toHaveLength(1);
    // 4 confrontos distintos (matchId 1,2,3,4), nunca mesclados em 2 —
    // cada um vira sua própria tie de 1 perna só (não dá pra saber qual
    // "ida" placeholder corresponde a qual "volta" placeholder).
    expect(rounds[0].ties).toHaveLength(4);
    for (const tie of rounds[0].ties) {
      expect(tie.legs).toHaveLength(1);
    }
  });

  it('confrontos DECIDIDOS (times reais) continuam se fundindo normalmente em ida+volta', () => {
    const lists: OneFootballMatchList[] = [
      {
        sectionHeader: { subtitle: 'Oitavas de final - Jogo de ida' },
        matchCards: [card('1', { name: 'A', id: 10, score: '1' }, { name: 'B', id: 20, score: '0' }, '2026-08-01T00:00:00Z', 'FULL_TIME')],
      },
      {
        sectionHeader: { subtitle: 'Oitavas de final - Jogo de volta' },
        matchCards: [card('2', { name: 'B', id: 20, score: '1' }, { name: 'A', id: 10, score: '1' }, '2026-08-08T00:00:00Z', 'FULL_TIME')],
      },
    ];
    const rounds = buildKnockoutRounds(lists);
    expect(rounds[0].ties).toHaveLength(1);
    expect(rounds[0].ties[0].legs).toHaveLength(2);
  });
});

describe('hasAnyDecidedMatch — gate "só mostra mata-mata quando começou de verdade" (decisão do usuário 2026-09-11)', () => {
  it('rounds só com "Home"/"Guest" -> false (Repescagem da Série B antes de decidir os classificados)', () => {
    const placeholderCard = (matchId: string) =>
      card(matchId, { name: 'Home', id: 57744 }, { name: 'Guest', id: 57745 }, '2026-11-21T12:00:00Z', 'PRE_MATCH');
    const rounds = buildKnockoutRounds([
      { sectionHeader: { subtitle: 'Repescagem - Ida' }, matchCards: [placeholderCard('1')] },
    ]);
    expect(hasAnyDecidedMatch(rounds)).toBe(false);
  });

  it('pelo menos um confronto com os dois times reais -> true', () => {
    const rounds = buildKnockoutRounds([
      {
        sectionHeader: { subtitle: 'Oitavas de final - Jogo de ida' },
        matchCards: [card('1', { name: 'A', id: 10 }, { name: 'B', id: 20 }, '2026-08-01T00:00:00Z', 'PRE_MATCH')],
      },
    ]);
    expect(hasAnyDecidedMatch(rounds)).toBe(true);
  });

  it('nenhuma rodada -> false', () => {
    expect(hasAnyDecidedMatch([])).toBe(false);
  });
});

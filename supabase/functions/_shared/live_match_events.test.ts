import { describe, expect, it } from 'vitest';
import {
  buildGoalDedupeKey,
  detectGoals,
  detectStatusTransitionEvents,
  normalizedMinute,
  type FixtureEvent,
} from './live_match_events';

function goalEvent(side: 'home' | 'away', minute: string, player: string | null = null): FixtureEvent {
  return { minute, side, type: 'goal', player, detail: null };
}

describe('normalizedMinute', () => {
  it('"90" -> 9000, "45+2" -> 4502, "37" -> 3700', () => {
    expect(normalizedMinute('90')).toBe(9000);
    expect(normalizedMinute('45+2')).toBe(4502);
    expect(normalizedMinute('37')).toBe(3700);
  });
});

describe('detectGoals — GOAL_FOR vs GOAL_AGAINST, nunca por home/away isolado', () => {
  it('Goiás mandante: gol home é GOAL_FOR, gol away é GOAL_AGAINST', () => {
    const events = [goalEvent('home', '10'), goalEvent('away', '20')];
    const detected = detectGoals(events, 'home');
    expect(detected.map((d) => d.eventType)).toEqual(['goal', 'goal_against']);
  });

  it('Goiás visitante (Vila Nova 0 x 1 Goiás): gol away é GOAL_FOR, gol home é GOAL_AGAINST — nunca decidido só pelo lado home/away', () => {
    const events = [goalEvent('away', '10'), goalEvent('home', '20')];
    const detected = detectGoals(events, 'away');
    expect(detected.map((d) => d.eventType)).toEqual(['goal', 'goal_against']);
  });

  it('nenhum gol -> lista vazia', () => {
    expect(detectGoals([], 'home')).toEqual([]);
  });

  it('ignora eventos que não são gol (cartão, substituição)', () => {
    const events: FixtureEvent[] = [
      { minute: '5', side: 'home', type: 'yellow_card', player: 'X', detail: null },
      goalEvent('home', '10'),
    ];
    expect(detectGoals(events, 'home')).toHaveLength(1);
  });
});

describe('buildGoalDedupeKey — dedupe determinístico, robusto a scorer nulo->preenchido', () => {
  it('placar parcial correto: Goiás 1x0 depois 1x1 gera scoreAfter distinto', () => {
    const events = [goalEvent('home', '10'), goalEvent('away', '30')];
    const firstKey = buildGoalDedupeKey({ matchId: 'm1', events, targetIndex: 0, clubCode: 'goias' });
    const secondKey = buildGoalDedupeKey({ matchId: 'm1', events, targetIndex: 1, clubCode: 'goias' });
    expect(firstKey).toContain('1-0');
    expect(secondKey).toContain('1-1');
    expect(firstKey).not.toBe(secondKey);
  });

  it('scorer null -> depois preenchido: dedupe_key NÃO muda (nunca duplica a mesma push)', () => {
    const eventsBefore = [goalEvent('home', '10', null)];
    const eventsAfter = [goalEvent('home', '10', 'Fulano')];
    const keyBefore = buildGoalDedupeKey({ matchId: 'm1', events: eventsBefore, targetIndex: 0, clubCode: 'goias' });
    const keyAfter = buildGoalDedupeKey({ matchId: 'm1', events: eventsAfter, targetIndex: 0, clubCode: 'goias' });
    expect(keyBefore).toBe(keyAfter);
  });

  it('2 clubes reais nunca colidem na mesma key (clubCode embutido)', () => {
    const events = [goalEvent('home', '10')];
    const goiasKey = buildGoalDedupeKey({ matchId: 'm1', events, targetIndex: 0, clubCode: 'goias' });
    const bragantinoKey = buildGoalDedupeKey({ matchId: 'm1', events, targetIndex: 0, clubCode: 'bragantino' });
    expect(goiasKey).not.toBe(bragantinoKey);
  });

  it('ordinal por lado: 2º gol do mesmo lado tem ordinal diferente do 1º', () => {
    const events = [goalEvent('home', '10'), goalEvent('home', '50')];
    const key1 = buildGoalDedupeKey({ matchId: 'm1', events, targetIndex: 0, clubCode: 'goias' });
    const key2 = buildGoalDedupeKey({ matchId: 'm1', events, targetIndex: 1, clubCode: 'goias' });
    expect(key1).not.toBe(key2);
  });
});

describe('detectStatusTransitionEvents — kickoff/intervalo/2º tempo por transição real, nunca por horário/minuto', () => {
  it('scheduled -> live => KICKOFF', () => {
    expect(detectStatusTransitionEvents('scheduled', 'live')).toEqual(['kickoff']);
  });

  it('null -> live (1ª leitura já ao vivo) => KICKOFF', () => {
    expect(detectStatusTransitionEvents(null, 'live')).toEqual(['kickoff']);
  });

  it('live -> live (mesmo status, poll repetido) => nenhum evento novo', () => {
    expect(detectStatusTransitionEvents('live', 'live')).toEqual([]);
  });

  it('live -> halftime => HALF_TIME', () => {
    expect(detectStatusTransitionEvents('live', 'halftime')).toEqual(['half_time']);
  });

  it('halftime -> halftime (poll repetido) => nenhum evento novo (nunca 5 notificações de intervalo)', () => {
    expect(detectStatusTransitionEvents('halftime', 'halftime')).toEqual([]);
  });

  it('halftime -> live => SECOND_HALF_STARTED (nunca confunde com kickoff)', () => {
    expect(detectStatusTransitionEvents('halftime', 'live')).toEqual(['second_half_started']);
  });

  it('jogo atrasado ainda scheduled -> nenhum evento (nunca dispara kickoff só por horário)', () => {
    expect(detectStatusTransitionEvents('scheduled', 'scheduled')).toEqual([]);
  });

  it('finished não gera kickoff/half_time/second_half (full_time é tratado à parte, por outro caminho)', () => {
    expect(detectStatusTransitionEvents('live', 'finished')).toEqual([]);
  });
});

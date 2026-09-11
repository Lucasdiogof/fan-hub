// M-live — lógica pura de detecção dos 6 eventos de partida ao vivo,
// extraída de notifications-poll-live-match/index.ts pra ser testável sem
// Deno (0 import Deno-specific, 0 fetch/I/O) — mesmo padrão de
// notification_message_builder.ts/recipient_eligibility.ts.

export interface FixtureEvent {
  minute: string;
  side: 'home' | 'away';
  type: 'goal' | 'yellow_card' | 'red_card' | 'substitution' | 'other';
  player: string | null;
  detail: string | null;
}

/** "45+2" -> 4502, "90" -> 9000, "37" -> 3700 — ordenável, nunca muda pro
 * mesmo evento real (não depende de campo mutável como o nome do autor). */
export function normalizedMinute(raw: string): number {
  const [base, stoppage] = raw.split('+');
  const baseNum = Number.parseInt(base, 10) || 0;
  const stoppageNum = stoppage ? Number.parseInt(stoppage, 10) || 0 : 0;
  return baseNum * 100 + stoppageNum;
}

export interface GoalDedupeInput {
  matchId: string;
  events: FixtureEvent[];
  targetIndex: number;
  clubCode: string;
}

/**
 * Dedupe key HEURÍSTICA (a OneFootball não dá event_id) — reconstrói, a
 * partir do array de eventos ATUAL (nunca incrementalmente), a posição do
 * gol entre os gols do MESMO lado de `events[targetIndex]` e o placar
 * corrido até ali. Funciona igual pra gol a favor e gol contra — quem
 * chama decide o `event_type` (goal/goal_against) comparando o lado do
 * evento com o lado do clube ativo; esta função nem sabe nem precisa saber
 * qual side é o clube ativo, só devolve uma chave estável por gol.
 *
 * `clubCode` entra na chave (M3.3) — `NOTIFICATION_DEDUPE_KEY_SCOPE_
 * BLOCKED`: `UNIQUE(event_type, dedupe_key)` sozinho não inclui `club_id`
 * de verdade na chave física (a bridge real é `ne_club_event_dedupe_uidx`,
 * `UNIQUE(club_id, event_type, dedupe_key)`), então embutir o código do
 * clube na STRING é defesa em profundidade, nunca hardcoded pra um clube
 * só. Enriquecer `player` depois (null -> nome) não muda nenhum componente
 * da key, então a mesma correção nunca gera outro evento (nunca duplica).
 *
 * Limitações conhecidas e aceitas (sem event_id estável na fonte): (1) gol
 * revertido por VAR e removido do array nunca é "desfeito" — a push já
 * mandada continua valendo; (2) minuto corrigido depois pode gerar key
 * nova e, em tese, uma push duplicada — risco aceito, documentado, não
 * escondido.
 */
export function buildGoalDedupeKey({ matchId, events, targetIndex, clubCode }: GoalDedupeInput): string {
  const goalEvents = events
    .map((event, index) => ({ event, index }))
    .filter(({ event }) => event.type === 'goal')
    .sort((a, b) => {
      const minuteDiff = normalizedMinute(a.event.minute) - normalizedMinute(b.event.minute);
      return minuteDiff !== 0 ? minuteDiff : a.index - b.index;
    });

  const targetSide = events[targetIndex].side;
  let homeGoals = 0;
  let awayGoals = 0;
  let sideOrdinal = 0;
  let scoreAfter = '';

  for (const { event, index } of goalEvents) {
    if (event.side === 'home') homeGoals += 1;
    else awayGoals += 1;
    if (event.side === targetSide) sideOrdinal += 1;

    if (index === targetIndex) {
      scoreAfter = `${homeGoals}-${awayGoals}`;
      break;
    }
  }

  return `${matchId}|${clubCode}|${targetSide}|${normalizedMinute(events[targetIndex].minute)}|${sideOrdinal}|${scoreAfter}`;
}

export interface DetectedGoal {
  index: number;
  event: FixtureEvent;
  eventType: 'goal' | 'goal_against';
}

/** Generaliza pra QUALQUER clube ativo (nunca hardcoded pro time da casa):
 * um gol é GOAL_FOR se o `side` do evento é o mesmo lado do clube ativo
 * naquela partida (`activeClubSide`, já resolvido comparando
 * home/awayTeam.id com `clubConfig.oneFootballTeamId`), GOAL_AGAINST caso
 * contrário. Nunca decide isso comparando nome de time ou olhando só
 * `side === 'home'`. */
export function detectGoals(events: FixtureEvent[], activeClubSide: 'home' | 'away'): DetectedGoal[] {
  return events
    .map((event, index) => ({ event, index }))
    .filter(({ event }) => event.type === 'goal')
    .map(({ event, index }) => ({
      index,
      event,
      eventType: (event.side === activeClubSide ? 'goal' : 'goal_against') as 'goal' | 'goal_against',
    }));
}

export type StatusTransitionEvent = 'kickoff' | 'half_time' | 'second_half_started';

/**
 * Status normalizado do provider (`mapOneFootballStatus` no Worker):
 * 'scheduled' | 'live' | 'halftime' | 'finished' | 'postponed' |
 * 'cancelled' | 'suspended' | 'unknown'. Nunca inferido por horário ou
 * minuto (`currentTime >= scheduledKickoff` geraria falso positivo em jogo
 * atrasado; `minute >= 46` é frágil a acréscimos/VAR) — só transição real
 * de status entre 2 polls consecutivos.
 *
 *  - previousStatus null/'scheduled' -> 'live'  => KICKOFF (1ª entrada ao vivo)
 *  - previousStatus 'halftime'        -> 'live'  => SECOND_HALF_STARTED
 *  - previousStatus != 'halftime'     -> 'halftime' => HALF_TIME
 *
 * Cada chamada decide só as transições deste poll — quem chama persiste
 * `last_provider_status` e confia no dedupe_key (`matchId|clubCode`) com
 * constraint única do banco pra nunca inserir o mesmo evento 2x, mesmo se
 * esta função for chamada de novo com o mesmo par de status.
 */
export function detectStatusTransitionEvents(
  previousStatus: string | null,
  currentStatus: string,
): StatusTransitionEvent[] {
  const events: StatusTransitionEvent[] = [];

  if (currentStatus === 'live') {
    if (previousStatus === null || previousStatus === 'scheduled') {
      events.push('kickoff');
    } else if (previousStatus === 'halftime') {
      events.push('second_half_started');
    }
  } else if (currentStatus === 'halftime' && previousStatus !== 'halftime') {
    events.push('half_time');
  }

  return events;
}

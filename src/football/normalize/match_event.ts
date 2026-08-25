import type { OneFootballMatchEvent } from '../providers/onefootball_provider';

export interface MatchEventJson {
  minute: string;
  side: 'home' | 'away';
  type: 'goal' | 'yellow_card' | 'red_card' | 'substitution' | 'other';
  player: string | null;
  detail: string | null;
}

/**
 * `teamSide` some do JSON pro time da casa (codificação proto3 típica — o
 * valor padrão do enum não é serializado) — só aparece explícito como
 * "TEAM_SIDE_AWAY" pro visitante. Confirmado observando partidas reais.
 *
 * O tipo do evento é decidido pela CHAVE presente (`goal`/`card`/
 * `substitution`), não pelo rótulo em português (`name`) — mais estável.
 * Cor do cartão é a exceção: só existe como texto ("Cartão amarelo"/
 * "Cartão vermelho"), não há campo estruturado pra isso.
 */
export function normalizeOneFootballMatchEvent(event: OneFootballMatchEvent): MatchEventJson {
  const side = event.teamSide === 'TEAM_SIDE_AWAY' ? 'away' : 'home';
  const minute = event.timeline;

  if (event.goal) {
    const detail =
      event.goal.type === 'PENALTY_GOAL' ? 'Pênalti' : event.goal.type === 'OWN_GOAL' ? 'Contra' : null;
    return { minute, side, type: 'goal', player: event.goal.scorer?.name ?? null, detail };
  }

  if (event.card) {
    const isRed = /vermelho/i.test(event.name);
    return {
      minute,
      side,
      type: isRed ? 'red_card' : 'yellow_card',
      player: event.card.player?.name ?? null,
      detail: null,
    };
  }

  if (event.substitution) {
    return {
      minute,
      side,
      type: 'substitution',
      player: event.substitution.playerIn?.name ?? null,
      detail: event.substitution.playerOut?.name ?? null,
    };
  }

  return { minute, side, type: 'other', player: null, detail: event.name };
}

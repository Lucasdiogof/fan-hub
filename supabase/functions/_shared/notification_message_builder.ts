// M3.3 (rodada de hardening) — extraído de notifications-dispatch/index.ts
// pra ser puro e testável (0 import Deno-specific, 0 I/O) — permite provar
// via vitest, sem precisar do runtime Deno, que a copy de notificação do
// Goiás nunca mudou e que um clube sintético produz sua própria copy,
// nunca "Goiás"/"Verdão".
import type { ClubServerConfig } from './club_server_config.ts';

export interface NotificationEventPayload {
  homeTeamName?: string;
  awayTeamName?: string;
  homeScore?: number;
  awayScore?: number;
  activeClubSide?: 'home' | 'away';
  /** Só presente em goal/goal_against, e só quando o provider já informou (M-live). */
  scorer?: string | null;
  minute?: string;
}

export type NotificationEventTypeInput =
  | 'match_access_open'
  | 'kickoff'
  | 'goal'
  | 'goal_against'
  | 'half_time'
  | 'second_half_started'
  | 'full_time';

export interface NotificationMessage {
  title: string;
  body: string;
  type: string;
}

/** Título/body/rota de acordo com o tipo de evento. Pra `match_access_open`,
 * a mensagem depende do status de sócio de CADA destinatário (decidido no
 * momento do envio — nunca client-side), então essa função recebe também se
 * o destinatário é sócio ativo agora. `clubConfig` resolvido do
 * `event.club_id` pelo caller — nunca mais compara `homeTeamName ===
 * 'Goiás'` por string nem hardcoda "GOIÁS"/"VERDÃO" pra qualquer clube; usa
 * `activeClubSide` (já vem no payload, ver `notifications-poll-live-
 * match`) pra saber de qual lado o clube ativo estava.
 *
 * `notificationGoalClubName`/`notificationVictoryNickname` são 2 campos
 * DISTINTOS de propósito (rodada de hardening) — "GOOOOOOL DO GOIÁS!" usa
 * o NOME do clube, "VITÓRIA DO VERDÃO!" usa o APELIDO do time (nunca o
 * gentílico do torcedor, "Esmeraldino" — 3 conceitos diferentes, nunca
 * misturados só pra reduzir a quantidade de campos). */
export function buildNotificationMessage(
  eventType: NotificationEventTypeInput,
  payload: NotificationEventPayload,
  clubConfig: ClubServerConfig,
  opts: { isActiveMember: boolean },
): NotificationMessage {
  const p = payload;

  switch (eventType) {
    case 'kickoff': {
      return {
        type: 'kickoff',
        title: '⚽ Começou!',
        body: `${p.homeTeamName} ${p.homeScore ?? 0} x ${p.awayScore ?? 0} ${p.awayTeamName}`,
      };
    }
    case 'goal_against': {
      const opponentName = p.activeClubSide === 'home' ? p.awayTeamName : p.homeTeamName;
      return {
        type: 'goal_against',
        title: `⚽ Gol do ${opponentName ?? 'adversário'}`,
        body: `${p.homeTeamName} ${p.homeScore ?? 0} x ${p.awayScore ?? 0} ${p.awayTeamName}`,
      };
    }
    case 'half_time': {
      return {
        type: 'half_time',
        title: '⏸ Intervalo',
        body: `${p.homeTeamName} ${p.homeScore ?? 0} x ${p.awayScore ?? 0} ${p.awayTeamName}`,
      };
    }
    case 'second_half_started': {
      return {
        type: 'second_half_started',
        title: '▶️ Começou o segundo tempo',
        body: `${p.homeTeamName} ${p.homeScore ?? 0} x ${p.awayScore ?? 0} ${p.awayTeamName}`,
      };
    }
    case 'match_access_open': {
      // Ternário de 3 vias preservado EXATAMENTE como no código pré-M3.3
      // (`git show 7316afc:supabase/functions/notifications-dispatch/
      // index.ts`) — inclusive o caso `homeTeamName === undefined → ''`,
      // que na prática nunca acontece (sempre vem populado por quem grava
      // o evento), mas trocar por só 2 vias mudaria o comportamento no
      // caso teórico (`undefined ?? '...'` cai no fallback, `'' ?? '...'`
      // NÃO cai — 2 resultados de body diferentes).
      const opponent =
        p.homeTeamName === clubConfig.shortName ? p.awayTeamName : p.homeTeamName === undefined ? '' : p.homeTeamName;
      if (opts.isActiveMember) {
        return {
          type: 'checkin',
          title: 'Check-in aberto',
          body: `O check-in pra ${opponent ?? 'o próximo jogo'} já está disponível.`,
        };
      }
      return {
        type: 'tickets',
        title: 'Ingressos disponíveis',
        body: `Os ingressos pra ${opponent ?? 'o próximo jogo'} já estão à venda.`,
      };
    }
    case 'goal': {
      return {
        type: 'goal',
        title: `GOOOOOOL DO ${clubConfig.notificationGoalClubName.toUpperCase()}! ⚽💚`,
        body: `${p.homeTeamName} ${p.homeScore} x ${p.awayScore} ${p.awayTeamName}`,
      };
    }
    case 'full_time': {
      const home = p.homeScore ?? 0;
      const away = p.awayScore ?? 0;
      const activeClubScore = p.activeClubSide === 'home' ? home : away;
      const opponentScore = p.activeClubSide === 'home' ? away : home;
      const title =
        activeClubScore > opponentScore
          ? `VITÓRIA DO ${clubConfig.notificationVictoryNickname.toUpperCase()}! 💚`
          : 'Fim de jogo';
      const suffix = activeClubScore > opponentScore ? ' Fim de jogo!' : '.';
      return {
        type: 'full_time',
        title,
        body: `${p.homeTeamName} ${home} x ${away} ${p.awayTeamName}${suffix}`,
      };
    }
  }
}

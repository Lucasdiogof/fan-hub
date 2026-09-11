// M3.3 (rodada de hardening) — extraído de notifications-dispatch/index.ts
// pra ser puro e testável (0 import Deno-specific, 0 I/O) — permite provar
// via vitest, sem precisar do runtime Deno, que a copy de notificação de
// um clube sintético nunca reusa nome/emoji de outro clube.
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

/**
 * Nome do adversário no evento ativo, calculado SEMPRE por
 * `activeClubSide` (nunca assumindo que o clube do flavor é mandante) —
 * usado tanto em GOAL_AGAINST quanto em `match_access_open`. `undefined`
 * só quando `activeClubSide` também não veio (nunca deveria acontecer pro
 * poll-live-match, que sempre resolve o lado antes de gravar o evento).
 */
function adversaryName(p: NotificationEventPayload): string | undefined {
  return p.activeClubSide === 'home' ? p.awayTeamName : p.homeTeamName;
}

/**
 * Placar corrido — `{homeTeam} {homeScore} x {awayScore} {awayTeam}` —
 * comum aos 5 eventos que já têm placar conhecido (goal/goal_against/
 * half_time/second_half_started/full_time). Kickoff é o único sem placar
 * (`{homeTeam} x {awayTeam}`, sem "0 x 0" — ver caso próprio abaixo).
 */
function scoreLine(p: NotificationEventPayload): string {
  return `${p.homeTeamName} ${p.homeScore ?? 0} x ${p.awayScore ?? 0} ${p.awayTeamName}`;
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
 * GOL e VITÓRIA usam SEMPRE `clubConfig.shortName` (nunca um apelido
 * separado tipo "Verdão" — removido de propósito, era fonte de bug real
 * reusando gentílico de torcida onde devia ser o nome do clube). Nunca
 * emoji de cor/identidade (💚/❤️/🟢/🔴) em nenhum título — só emoji
 * neutro de contexto esportivo, igual pros 2 clubes. */
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
        title: 'Começou! ⚽',
        body: `${p.homeTeamName} x ${p.awayTeamName}`,
      };
    }
    case 'goal_against': {
      // Sem emoji de propósito — só o gol A FAVOR e os marcos temporais
      // (kickoff/intervalo/2º tempo/fim) levam um emoji neutro; gol do
      // adversário fica só com o nome, sem destaque visual extra.
      return {
        type: 'goal_against',
        title: `Gol do ${adversaryName(p) ?? 'adversário'}`,
        body: scoreLine(p),
      };
    }
    case 'half_time': {
      return {
        type: 'half_time',
        title: 'Intervalo ⏸️',
        body: scoreLine(p),
      };
    }
    case 'second_half_started': {
      return {
        type: 'second_half_started',
        title: 'Começou o segundo tempo ▶️',
        body: scoreLine(p),
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
      // Nunca 💚/❤️/🟢/🔴 nem qualquer emoji de cor/identidade — a
      // identidade do clube vem do NOME (`clubConfig.shortName`), do
      // ícone do app e do branding do flavor, nunca de um emoji de cor
      // aqui. Só ⚽, neutro, igual pros 2 clubes.
      return {
        type: 'goal',
        title: `GOOOOOOL DO ${clubConfig.shortName.toUpperCase()}! ⚽`,
        body: scoreLine(p),
      };
    }
    case 'full_time': {
      const home = p.homeScore ?? 0;
      const away = p.awayScore ?? 0;
      const activeClubScore = p.activeClubSide === 'home' ? home : away;
      const opponentScore = p.activeClubSide === 'home' ? away : home;
      // Resultado calculado SEMPRE por `activeClubSide` — nunca assume
      // que o clube do flavor é mandante. Vitória usa o mesmo
      // `shortName` do gol (nunca apelido separado); empate/derrota caem
      // no mesmo "Fim de jogo 🏁" genérico — nenhum emoji de cor em
      // nenhum dos 2 casos.
      const title =
        activeClubScore > opponentScore
          ? `VITÓRIA DO ${clubConfig.shortName.toUpperCase()}! 🏁`
          : 'Fim de jogo 🏁';
      return {
        type: 'full_time',
        title,
        body: scoreLine(p),
      };
    }
  }
}

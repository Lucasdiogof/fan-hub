// Política de atualização/expiração dos snapshots — pura (recebe `now`).
// `next_refresh_at` = quando buscar de novo; `expires_at` = até quando o app
// deve confiar no dado (conceitos separados). `null` em nextRefreshAt = nada
// a atualizar (partida antiga encerrada, catálogo estático).
import type { SnapshotKind } from './contract.ts';

const SEC = 1000;
const MIN = 60 * SEC;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;

/** Horário só de parede do Brasil, sem offset (UTC-3 fixo, igual ao resto do pipeline). */
const kickoffMs = (kickoff: string | null | undefined): number | null => {
  if (!kickoff) return null;
  const ms = Date.parse(`${kickoff}-03:00`);
  return Number.isNaN(ms) ? null : ms;
};

/** Sem horário real de término: considera ~2h de jogo e `RECENT_FINISH` depois. */
const GAME_DURATION = 2 * HOUR;
const RECENT_FINISH = 3 * HOUR;

interface MatchLike {
  status?: string;
  kickoff?: string | null;
}
type MatchState = 'live' | 'near' | 'recent_finish' | 'scheduled' | 'finished' | 'none';

function matchState(match: MatchLike | null | undefined, now: number): MatchState {
  if (!match) return 'none';
  const k = kickoffMs(match.kickoff);
  switch (match.status) {
    case 'live':
    case 'halftime':
      return 'live';
    case 'finished':
      return k !== null && now < k + GAME_DURATION + RECENT_FINISH ? 'recent_finish' : 'finished';
    case 'scheduled':
      if (k === null) return 'scheduled';
      // Kickoff já passou mas o provider ainda não virou pra "ao vivo":
      // tratar como ao vivo por até 3h, nunca esperar +60min.
      if (k <= now) return now < k + RECENT_FINISH ? 'live' : 'scheduled';
      return k - now < 2 * HOUR ? 'near' : 'scheduled';
    default:
      return 'scheduled';
  }
}

const PRIORITY: MatchState[] = ['live', 'near', 'recent_finish', 'scheduled', 'finished', 'none'];
const strongest = (states: MatchState[]): MatchState =>
  PRIORITY.find((s) => states.includes(s)) ?? 'none';

export interface RefreshPlan {
  nextRefreshAt: Date | null;
  expiresAt: Date;
}

const plan = (now: number, nextMs: number | null, expiresMs: number): RefreshPlan => ({
  nextRefreshAt: nextMs === null ? null : new Date(now + nextMs),
  expiresAt: new Date(now + expiresMs),
});

/** Tabela de cadência/validade por estado (ms). */
const BY_STATE: Record<MatchState, { next: number | null; expires: number }> = {
  live: { next: 60 * SEC, expires: 5 * MIN },
  near: { next: 5 * MIN, expires: 6 * HOUR },
  recent_finish: { next: 10 * MIN, expires: 7 * DAY },
  scheduled: { next: HOUR, expires: 6 * HOUR },
  finished: { next: HOUR, expires: 7 * DAY },
  none: { next: HOUR, expires: 7 * DAY },
};

interface TeamPayload {
  nextMatch?: MatchLike | null;
  recentResults?: MatchLike[];
}
interface FixturePayload {
  match?: MatchLike;
}
interface RoundPayload {
  matches?: MatchLike[];
}

export function computeRefresh(kind: SnapshotKind, payload: unknown, nowDate: Date): RefreshPlan {
  const now = nowDate.getTime();
  switch (kind) {
    case 'team': {
      const p = payload as TeamPayload;
      // O "próximo jogo" do OneFootball pode já vir encerrado (acabou de
      // terminar), então avalia ele + o resultado mais recente juntos.
      const state = strongest([matchState(p.nextMatch, now), matchState(p.recentResults?.[0], now)]);
      const cfg = BY_STATE[state];
      // Só o resultado antigo e nenhum jogo futuro: nada agendado, validade longa.
      return plan(now, cfg.next, cfg.expires);
    }
    case 'fixture': {
      const state = matchState((payload as FixturePayload).match, now);
      const cfg = BY_STATE[state];
      // Partida antiga encerrada não muda mais: não precisa nova busca.
      return plan(now, state === 'finished' ? null : cfg.next, state === 'finished' ? 30 * DAY : cfg.expires);
    }
    case 'current_round': {
      const live = ((payload as RoundPayload).matches ?? []).some((m) => matchState(m, now) === 'live');
      return live ? plan(now, 2 * MIN, 30 * MIN) : plan(now, 30 * MIN, 7 * DAY);
    }
    case 'season':
      return plan(now, 30 * MIN, 7 * DAY);
    case 'standings':
      return plan(now, HOUR, 7 * DAY);
    case 'competitions':
      return plan(now, null, 365 * DAY);
  }
}

/** Backoff de falha: 5min, 10, 20, 40, 60 (teto). `failures` = contador JÁ incrementado (>=1). */
export function computeBackoff(failures: number, nowDate: Date): Date {
  const ms = Math.min(5 * MIN * 2 ** Math.max(0, failures - 1), HOUR);
  return new Date(nowDate.getTime() + ms);
}


import type { RawMatch } from 'campeonato-brasileiro-api';
import { mapBrasileiraoStatus } from './brasileirao_status_mapper';
import { mapTheSportsDbStatus } from './thesportsdb_status_mapper';
import type { TheSportsDbEvent } from '../providers/thesportsdb_provider';

/**
 * Formato interno de partida — o mesmo pros dois providers, então o Flutter
 * nunca precisa saber de onde veio. `id` é prefixado por provider
 * (`cbapi-...`/`tsdb-...`) só pra `/fixtures/:id` saber pra onde rotear;
 * fora isso é opaco pro app.
 *
 * `kickoff` continua como veio da fonte (string local do Brasil, sem
 * offset) — NUNCA passar por conversão de fuso aqui: a página de origem já
 * mostra horário de Brasília "cru", sem indicar UTC. Tentar converter via
 * instante absoluto (ex.: pacote `timezone`) sem um offset real na entrada
 * pode deslocar o horário errado dependendo de onde o parsing acontecer.
 */
export interface InternalMatch {
  id: string;
  round: string | null;
  homeTeam: { id: number | string; name: string | null; shortName: string | null; logo: string | null };
  awayTeam: { id: number | string; name: string | null; shortName: string | null; logo: string | null };
  kickoff: string | null;
  venue: string | null;
  status: string;
  homeScore: number | null;
  awayScore: number | null;
}

export function normalizeBrasileiraoMatch(raw: RawMatch, roundLabel: string | null): InternalMatch {
  return {
    id: `cbapi-${raw.id}`,
    round: roundLabel,
    homeTeam: {
      id: raw.homeTeam.id ?? 0,
      name: raw.homeTeam.name,
      shortName: raw.homeTeam.shortName,
      logo: raw.homeTeam.badge,
    },
    awayTeam: {
      id: raw.awayTeam.id ?? 0,
      name: raw.awayTeam.name,
      shortName: raw.awayTeam.shortName,
      logo: raw.awayTeam.badge,
    },
    kickoff: raw.dateTime,
    venue: raw.venue,
    status: mapBrasileiraoStatus(raw.status),
    homeScore: raw.score?.home ?? null,
    awayScore: raw.score?.away ?? null,
  };
}

export function normalizeTheSportsDbEvent(raw: TheSportsDbEvent): InternalMatch {
  const kickoff = raw.dateEventLocal && raw.strTimeLocal ? `${raw.dateEventLocal}T${raw.strTimeLocal}` : null;

  return {
    id: `tsdb-${raw.idEvent}`,
    round: raw.intRound ?? null,
    homeTeam: {
      id: raw.idHomeTeam,
      name: raw.strHomeTeam,
      shortName: null,
      logo: raw.strHomeTeamBadge,
    },
    awayTeam: {
      id: raw.idAwayTeam,
      name: raw.strAwayTeam,
      shortName: null,
      logo: raw.strAwayTeamBadge,
    },
    kickoff,
    venue: raw.strVenue,
    status: mapTheSportsDbStatus(raw.strStatus),
    homeScore: raw.intHomeScore != null ? Number(raw.intHomeScore) : null,
    awayScore: raw.intAwayScore != null ? Number(raw.intAwayScore) : null,
  };
}

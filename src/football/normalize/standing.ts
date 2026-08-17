import type { RawStandingEntry } from 'campeonato-brasileiro-api';

/**
 * Entrada crua do provider → JSON interno simples. `isGoias` é decidido
 * aqui, comparando id contra o id confirmado (nunca por nome) — o Flutter
 * só recebe um booleano, sem saber de qual provider veio o id.
 */
export function normalizeStandingEntry(entry: RawStandingEntry, goiasBrasileiraoId: number | null) {
  return {
    position: entry.position,
    team: {
      id: entry.team.id,
      name: entry.team.name,
      shortName: entry.team.shortName,
      logo: entry.team.badge,
    },
    isGoias: goiasBrasileiraoId != null && entry.team.id === goiasBrasileiraoId,
    points: entry.points,
    played: entry.matches,
    wins: entry.wins,
    draws: entry.draws,
    losses: entry.losses,
    goalsFor: entry.goalsFor,
    goalsAgainst: entry.goalsAgainst,
  };
}

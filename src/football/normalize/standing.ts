import type { OneFootballStandingRow } from '../providers/onefootball_provider';

/** `1863` embutido em `.../pt-br/time/goias-1863` — mesma ideia do id de
 * time extraído do escudo nas partidas, só que aqui vem do path do time. */
function extractTeamIdFromPath(teamPath: string): number {
  const match = teamPath.match(/-(\d+)$/);
  return match ? Number(match[1]) : 0;
}

/**
 * Entrada crua do OneFootball → JSON interno simples. `isGoias` é decidido
 * aqui, comparando id contra o id confirmado (nunca por nome) — o Flutter
 * só recebe um booleano, sem saber de qual provider veio o id.
 *
 * Só saldo de gols, não gols pró/contra separados — é tudo que o
 * OneFootball dá, e é tudo que a UI já mostrava (coluna "SG").
 */
export function normalizeStandingEntry(entry: OneFootballStandingRow, goiasId: number | null) {
  const teamId = extractTeamIdFromPath(entry.teamPath);
  return {
    position: entry.position,
    team: {
      id: teamId,
      name: entry.teamName,
      shortName: null,
      logo: entry.imageObject.path,
    },
    isGoias: goiasId != null && teamId === goiasId,
    points: entry.points,
    played: entry.playedMatchesCount,
    wins: entry.wonMatchesCount,
    draws: entry.drawnMatchesCount,
    losses: entry.lostMatchesCount,
    goalDifference: entry.goalsDiff,
    form: null,
  };
}

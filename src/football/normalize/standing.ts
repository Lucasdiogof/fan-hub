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
 *
 * Observado em produção: pelo menos um time (saldo 0) veio sem a chave
 * `goalsDiff` de vez em quando — cada número aqui cai pra 0 se faltar, em
 * vez de deixar `undefined` vazar pro Flutter e quebrar o parse da lista
 * inteira por causa de uma linha.
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
    points: entry.points ?? 0,
    played: entry.playedMatchesCount ?? 0,
    wins: entry.wonMatchesCount ?? 0,
    draws: entry.drawnMatchesCount ?? 0,
    losses: entry.lostMatchesCount ?? 0,
    goalDifference: entry.goalsDiff ?? 0,
    form: null,
  };
}

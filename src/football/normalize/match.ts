import { mapOneFootballStatus } from './onefootball_status_mapper';
import { normalizeTeamName } from './team_name';
import type { OneFootballMatchCard, OneFootballMatchScore } from '../providers/onefootball_provider';

/**
 * Formato interno de partida — o Flutter nunca sabe de onde veio. `id`
 * carrega o prefixo `onef-` só pra `/fixtures/:id` saber que é do
 * OneFootball; fora isso é opaco pro app.
 *
 * `kickoff` é sempre string local do Brasil sem offset (ver
 * `utcToNaiveBrazilLocal` abaixo) — o resto do pipeline (Dart faz
 * `DateTime.parse` direto, sem `.toLocal()`) espera exatamente esse
 * formato.
 */
export interface InternalMatch {
  id: string;
  round: string | null;
  homeTeam: { id: number; name: string | null; shortName: string | null; logo: string | null };
  awayTeam: { id: number; name: string | null; shortName: string | null; logo: string | null };
  kickoff: string | null;
  venue: string | null;
  status: string;
  homeScore: number | null;
  awayScore: number | null;
}

/** OneFootball manda o horário em UTC de verdade (com `Z`) — converte pro
 * formato "local nu" (sem offset) que o resto do pipeline sempre esperou. */
function utcToNaiveBrazilLocal(utcIso: string): string {
  const utcMs = new Date(utcIso).getTime();
  const brazilMs = utcMs - 3 * 60 * 60 * 1000;
  return new Date(brazilMs).toISOString().replace('Z', '');
}

/** `1863` embutido em `.../icons/teams/164/1863.png` — o card de partida do
 * OneFootball não traz id de time em nenhum outro campo. */
function extractTeamIdFromCrest(path: string): number {
  const match = path.match(/\/teams\/\d+\/(\d+)\.\w+$/i);
  return match ? Number(match[1]) : 0;
}

function parseOneFootballScore(score: string | undefined): number | null {
  if (!score || score === '-') return null;
  const parsed = Number(score);
  return Number.isNaN(parsed) ? null : parsed;
}

export function normalizeOneFootballMatchCard(card: OneFootballMatchCard, venue: string | null = null): InternalMatch {
  return {
    id: `onef-${card.matchId}`,
    round: null,
    homeTeam: {
      id: extractTeamIdFromCrest(card.homeTeam.imageObject.path),
      name: normalizeTeamName(card.homeTeam.name),
      shortName: null,
      logo: card.homeTeam.imageObject.path,
    },
    awayTeam: {
      id: extractTeamIdFromCrest(card.awayTeam.imageObject.path),
      name: normalizeTeamName(card.awayTeam.name),
      shortName: null,
      logo: card.awayTeam.imageObject.path,
    },
    kickoff: utcToNaiveBrazilLocal(card.kickoff),
    venue,
    status: mapOneFootballStatus(card.period),
    homeScore: parseOneFootballScore(card.homeTeam.score),
    awayScore: parseOneFootballScore(card.awayTeam.score),
  };
}

export function normalizeOneFootballMatchScore(
  matchId: string,
  score: OneFootballMatchScore,
  venue: string | null,
): InternalMatch {
  return {
    id: `onef-${matchId}`,
    round: null,
    homeTeam: {
      id: extractTeamIdFromCrest(score.homeTeam.imageObject.path),
      name: normalizeTeamName(score.homeTeam.name),
      shortName: null,
      logo: score.homeTeam.imageObject.path,
    },
    awayTeam: {
      id: extractTeamIdFromCrest(score.awayTeam.imageObject.path),
      name: normalizeTeamName(score.awayTeam.name),
      shortName: null,
      logo: score.awayTeam.imageObject.path,
    },
    kickoff: utcToNaiveBrazilLocal(score.kickoff.utcTimestamp),
    venue,
    status: mapOneFootballStatus(score.period),
    homeScore: parseOneFootballScore(score.homeTeam.score),
    awayScore: parseOneFootballScore(score.awayTeam.score),
  };
}

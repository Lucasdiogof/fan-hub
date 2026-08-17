import type { Env } from './_lib/config';
import { loadConfig, requireGoiasTheSportsDbId } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchTeamNextEvents, fetchTeamLastEvents } from './providers/thesportsdb_provider';
import { normalizeTheSportsDbEvent } from './normalize/match';

const CACHE_TTL_SECONDS = 30 * 60;

/**
 * Só existe `/team/goias` por enquanto — o app tem um único time de
 * interesse. Se um dia precisar de outros times, o path vira `/team/:slug`
 * sem quebrar esse contrato.
 */
export const onRequestGet = handleGoiasTeam;

export async function handleGoiasTeam(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const teamId = requireGoiasTheSportsDbId(config);

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.team.goias', async () => {
      const [nextEvents, lastEvents] = await Promise.all([
        fetchTeamNextEvents(teamId),
        fetchTeamLastEvents(teamId),
      ]);

      return {
        nextMatch: nextEvents.length > 0 ? normalizeTheSportsDbEvent(nextEvents[0]) : null,
        recentResults: lastEvents.map(normalizeTheSportsDbEvent),
      };
    });
  });
}

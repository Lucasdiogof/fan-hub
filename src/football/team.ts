import type { Env } from './_lib/config';
import { loadConfig, requireGoiasTheSportsDbId } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { fetchTeamNextEvents, fetchTeamLastEvents } from './providers/thesportsdb_provider';
import type { TheSportsDbEvent } from './providers/thesportsdb_provider';
import { normalizeTheSportsDbEvent } from './normalize/match';

const CACHE_TTL_SECONDS = 30 * 60;

/**
 * Nome canônico em português — nunca o `strLeague` cru do TheSportsDB
 * ("Brazilian Serie B", em inglês). Os outros endpoints (standings,
 * current-round) já mostram esse mesmo nome via campeonato-brasileiro-api;
 * usar a fonte errada aqui faria o app exibir dois nomes diferentes pro
 * mesmo campeonato dependendo de qual partida o usuário abrisse.
 */
const COMPETITION_NAME = 'Campeonato Brasileiro Série B';

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

    return cacheFirst(request, CACHE_TTL_SECONDS, 'football.team.goias', config.cacheVersion, async () => {
      const [nextEvents, lastEvents] = await Promise.all([
        fetchTeamNextEvents(teamId),
        fetchTeamLastEvents(teamId),
      ]);

      const anyEvent = nextEvents[0] ?? lastEvents[0];
      const season = competitionSeason(anyEvent);

      return {
        competition: {
          name: season ? `${COMPETITION_NAME} ${season}` : COMPETITION_NAME,
          season,
        },
        nextMatch: nextEvents.length > 0 ? normalizeTheSportsDbEvent(nextEvents[0]) : null,
        recentResults: lastEvents.map(normalizeTheSportsDbEvent),
      };
    });
  });
}

function competitionSeason(event: TheSportsDbEvent | undefined): number | null {
  if (!event?.strSeason) return null;
  const parsed = Number(event.strSeason);
  return Number.isNaN(parsed) ? null : parsed;
}

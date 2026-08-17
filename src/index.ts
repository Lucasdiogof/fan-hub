import type { Env } from './football/_lib/config';
import { handleStandings } from './football/standings';
import { handleCurrentRound } from './football/currentRound';
import { handleGoiasTeam } from './football/team';
import { handleFixtureDetails } from './football/fixtureDetails';
import { handleDiscover } from './football/discover';

const FIXTURE_DETAILS_PATTERN = /^\/api\/football\/fixtures\/([^/]+)\/?$/;

/**
 * Entry point único do Worker: roteia `/api/football/*` pros handlers e
 * delega tudo mais (o app Flutter Web) pro binding de assets estáticos. O
 * Flutter só conhece essas rotas — nunca fala com campeonato-brasileiro-api
 * ou TheSportsDB diretamente.
 */
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;

    if (pathname === '/api/football/standings') {
      return handleStandings(request, env);
    }

    if (pathname === '/api/football/current-round') {
      return handleCurrentRound(request, env);
    }

    if (pathname === '/api/football/team/goias') {
      return handleGoiasTeam(request, env);
    }

    const fixtureMatch = pathname.match(FIXTURE_DETAILS_PATTERN);
    if (fixtureMatch) {
      return handleFixtureDetails(request, env, decodeURIComponent(fixtureMatch[1]));
    }

    if (pathname === '/api/football/discover') {
      return handleDiscover(request, env);
    }

    return env.ASSETS.fetch(request);
  },
};

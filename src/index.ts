import type { Env } from './football/_lib/config';
import { handleStandings } from './football/standings';
import { handleFixtures } from './football/fixtures';
import { handleFixtureDetails } from './football/fixtureDetails';
import { handleDiscover } from './football/discover';

const FIXTURE_DETAILS_PATTERN = /^\/api\/football\/fixtures\/(\d+)\/?$/;

/**
 * Entry point único do Worker: roteia `/api/football/*` pros handlers e
 * delega tudo mais (o app Flutter Web) pro binding de assets estáticos.
 * O Flutter nunca fala com a API-Football — só com essas rotas, no mesmo
 * domínio do site.
 */
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;

    if (pathname === '/api/football/standings') {
      return handleStandings(request, env);
    }

    if (pathname === '/api/football/fixtures') {
      return handleFixtures(request, env);
    }

    if (pathname === '/api/football/discover') {
      return handleDiscover(request, env);
    }

    const fixtureMatch = pathname.match(FIXTURE_DETAILS_PATTERN);
    if (fixtureMatch) {
      return handleFixtureDetails(request, env, fixtureMatch[1]);
    }

    return env.ASSETS.fetch(request);
  },
};

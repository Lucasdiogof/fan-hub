import type { SocialEnv } from './social/config';
import { handleStandings } from './football/standings';
import { handleCurrentRound } from './football/currentRound';
import { handleGoiasTeam } from './football/team';
import { handleFixtureDetails } from './football/fixtureDetails';
import { handleDiscover } from './football/discover';
import { handleSocialFeed } from './social/feed';

const FIXTURE_DETAILS_PATTERN = /^\/api\/football\/fixtures\/([^/]+)\/?$/;

export default {
  async fetch(request: Request, env: SocialEnv): Promise<Response> {
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

    if (pathname === '/api/social/feed') {
      return handleSocialFeed(request, env);
    }

    return env.ASSETS.fetch(request);
  },
};

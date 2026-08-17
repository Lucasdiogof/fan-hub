import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { apiFootballGet } from './_lib/client';
import { cacheFirst } from './_lib/cache';
import { normalizeFixture } from './_lib/normalize';
import { withErrorHandling } from './_lib/handleErrors';

const UPCOMING_STATUSES = new Set(['TBD', 'NS']);
const FINISHED_STATUSES = new Set(['FT', 'AET', 'PEN', 'AWD', 'WO']);

function cacheTtlFor(scope: string): number {
  if (scope === 'results') return 6 * 60 * 60;
  return 45 * 60;
}

export async function handleFixtures(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);
    const url = new URL(request.url);
    const scope = url.searchParams.get('scope') ?? 'all';

    return cacheFirst(request, cacheTtlFor(scope), `football.fixtures.${scope}`, async () => {
      const raw = await apiFootballGet(config, '/fixtures', {
        league: config.leagueId,
        season: config.season,
        team: config.teamId,
        timezone: 'America/Sao_Paulo',
      });

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let matches = (raw.response ?? []).map(normalizeFixture);

      if (scope === 'upcoming') {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        matches = matches.filter((m: any) => UPCOMING_STATUSES.has(m.status));
      } else if (scope === 'results') {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        matches = matches.filter((m: any) => FINISHED_STATUSES.has(m.status));
      }

      const leagueBlock = raw.response?.[0]?.league;

      return {
        competition: {
          id: config.leagueId,
          name: leagueBlock?.name ?? 'Brasileirão Série B',
          season: config.season,
        },
        matches,
      };
    });
  });
}

import type { Env } from './_lib/config';
import { jsonResponse, errorResponse } from './_lib/respond';

/**
 * Endpoint de setup, não de uso normal do app: ajuda a confirmar os IDs
 * reais da liga e do time direto na API-Football antes de preencher
 * `SERIE_B_LEAGUE_ID` / `GOIAS_TEAM_ID` no `wrangler.toml`. Sem cache —
 * roda só algumas vezes durante a configuração inicial.
 *
 * GET /api/football/discover?search=Serie B
 * GET /api/football/discover?search=Goias
 */
export async function handleDiscover(request: Request, env: Env): Promise<Response> {
  const apiKey = env.API_FOOTBALL_KEY;
  if (!apiKey) {
    return errorResponse('API_FOOTBALL_KEY não configurada. Configure o secret antes de usar o discover.', 503);
  }

  const url = new URL(request.url);
  const search = url.searchParams.get('search');
  if (!search) {
    return errorResponse('Use ?search=Serie B (para a liga) ou ?search=Goias (para o time).', 400);
  }

  const season = env.SEASON || '2026';
  const baseUrl = 'https://v3.football.api-sports.io';
  const headers = { 'x-apisports-key': apiKey };

  try {
    const [leaguesRes, teamsRes] = await Promise.all([
      fetch(`${baseUrl}/leagues?country=Brazil&season=${season}&search=${encodeURIComponent(search)}`, { headers }),
      fetch(`${baseUrl}/teams?season=${season}&search=${encodeURIComponent(search)}`, { headers }),
    ]);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const leagues = (await leaguesRes.json()) as any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const teams = (await teamsRes.json()) as any;

    return jsonResponse({
      leagues: (leagues.response ?? []).map(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (item: any) => ({
          id: item.league.id,
          name: item.league.name,
          type: item.league.type,
          country: item.country?.name,
        }),
      ),
      teams: (teams.response ?? []).map(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (item: any) => ({
          id: item.team.id,
          name: item.team.name,
          country: item.team.country,
        }),
      ),
    });
  } catch (err) {
    console.error('football.discover.error', err instanceof Error ? err.message : String(err));
    return errorResponse('Erro ao consultar a API-Football.', 502);
  }
}

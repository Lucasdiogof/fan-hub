import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { jsonResponse, errorResponse } from './_lib/respond';
import { fetchBrasileiraoStandings } from './providers/brasileirao_provider';

/**
 * Endpoint de setup, não de uso normal do app: lista os times da Série B
 * com seus ids reais na campeonato-brasileiro-api, pra confirmar o id do
 * Goiás antes de preencher `GOIAS_BRASILEIRAO_ID` no wrangler.toml. Sem
 * cache — roda só durante a configuração inicial.
 *
 * Pra achar o id do Goiás no TheSportsDB, use direto (sem passar pela nossa
 * API, já que é só consulta pública de setup):
 * https://www.thesportsdb.com/api/v1/json/3/searchteams.php?t=Goias
 *
 * GET /api/football/discover
 */
export const onRequestGet = handleDiscover;

export async function handleDiscover(request: Request, env: Env): Promise<Response> {
  const config = loadConfig(env);

  try {
    const { competition, table } = await fetchBrasileiraoStandings(config.serieCode);
    return jsonResponse({
      competition: { name: competition.name, season: competition.season },
      teams: table.entries.map((entry) => ({
        id: entry.team.id,
        name: entry.team.name,
        shortName: entry.team.shortName,
      })),
      note: 'Para o id do TheSportsDB, consulte searchteams.php?t=<nome> diretamente (ver comentário no código).',
    });
  } catch (err) {
    console.error('football.discover.error', err instanceof Error ? err.message : String(err));
    return errorResponse('Erro ao consultar a campeonato-brasileiro-api.', 502);
  }
}

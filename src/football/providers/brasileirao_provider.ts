import { getStandings, getRounds } from 'campeonato-brasileiro-api';
import type { RawCompetitionMeta, RawRound, RawTable } from 'campeonato-brasileiro-api';
import { ProviderError } from '../_lib/providerError';

const PROVIDER = 'brasileirao';

/**
 * Fonte principal de dados esportivos: lê a página ao vivo do ge.globo.com
 * (via a lib `campeonato-brasileiro-api`) e devolve classificação completa +
 * a rodada atual (todos os times). Não existe "próximos jogos" nem
 * "resultados antigos" nessa fonte — só o que está na página agora.
 */
export async function fetchBrasileiraoStandings(
  serieCode: string,
): Promise<{ competition: RawCompetitionMeta; table: RawTable }> {
  try {
    const result = await getStandings(serieCode);
    const table = result.tables[0];
    if (!table) {
      throw new ProviderError('Classificação não disponível no momento.', 502, PROVIDER);
    }
    return { competition: result.competition, table };
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a classificação (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

export async function fetchBrasileiraoCurrentRound(
  serieCode: string,
): Promise<{ competition: RawCompetitionMeta; round: RawRound }> {
  try {
    const result = await getRounds(serieCode);
    const round = result.rounds[0];
    if (!round) {
      throw new ProviderError('Rodada atual não disponível no momento.', 502, PROVIDER);
    }
    return { competition: result.competition, round };
  } catch (err) {
    if (err instanceof ProviderError) throw err;
    throw new ProviderError(
      `Não foi possível consultar a rodada atual (${err instanceof Error ? err.message : String(err)}).`,
      502,
      PROVIDER,
    );
  }
}

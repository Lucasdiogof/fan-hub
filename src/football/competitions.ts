import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { isRequestedClubServed } from './_lib/club_server_config';
import { GLOBAL_COMPETITION_CATALOG, competitionIdsForClub } from './_lib/competition_catalog';
import { jsonResponse } from './_lib/respond';
import { withErrorHandling } from './_lib/handleErrors';

/**
 * Lista o catálogo GLOBAL de competições (ver `competition_catalog.ts`) —
 * NUNCA só as que o clube ativo disputa. `isClubParticipating` é a única
 * coisa que muda por clube; a existência/formato/dado de cada competição é
 * a mesma pra qualquer deploy (spec multi-competição, itens 3/16/21: "não
 * exigir participação para consultar").
 */
export const onRequestGet = handleCompetitions;

export async function handleCompetitions(request: Request, env: Env): Promise<Response> {
  return withErrorHandling(async () => {
    if (!isRequestedClubServed(request, env)) {
      return jsonResponse({ error: 'unknown club code' }, { status: 404 });
    }
    const config = loadConfig(env);
    // `isRequestedClubServed` já garante que `?club=` (quando presente) bate
    // com `env.CLUB_CODE` deste deploy — o clube realmente servido é sempre
    // `config.clubCode`, nunca o que veio (ou não) na query string.
    const participating = new Set(competitionIdsForClub(config.clubCode ?? ''));

    return jsonResponse({
      competitions: GLOBAL_COMPETITION_CATALOG.map((c) => ({
        id: c.id,
        name: c.name,
        region: c.region,
        format: c.format,
        isClubParticipating: participating.has(c.id),
      })),
    });
  });
}

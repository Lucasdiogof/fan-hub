import type { Env } from './_lib/config';
import { loadConfig } from './_lib/config';
import { cacheFirst } from './_lib/cache';
import { withErrorHandling } from './_lib/handleErrors';
import { ProviderError } from './_lib/providerError';
import { fetchBrasileiraoCurrentRound } from './providers/brasileirao_provider';
import { fetchEventById } from './providers/thesportsdb_provider';
import { normalizeBrasileiraoMatch, normalizeTheSportsDbEvent } from './normalize/match';

const CACHE_TTL_SECONDS = 30 * 60;

/**
 * `id` vem prefixado por provider (`cbapi-<id>` / `tsdb-<id>`) — o próprio
 * Flutter nunca precisa entender o prefixo, só devolve o que recebeu.
 */
export async function handleFixtureDetails(request: Request, env: Env, rawId: string): Promise<Response> {
  return withErrorHandling(async () => {
    const config = loadConfig(env);

    if (rawId.startsWith('cbapi-')) {
      return handleBrasileiraoFixture(request, config, rawId.slice('cbapi-'.length));
    }

    if (rawId.startsWith('tsdb-')) {
      return handleTheSportsDbFixture(request, config.cacheVersion, rawId.slice('tsdb-'.length));
    }

    throw new ProviderError('Id de partida inválido.', 400, 'internal');
  });
}

async function handleBrasileiraoFixture(
  request: Request,
  config: ReturnType<typeof loadConfig>,
  fixtureId: string,
): Promise<Response> {
  return cacheFirst(request, CACHE_TTL_SECONDS, 'football.fixtures.details.brasileirao', config.cacheVersion, async () => {
    // Fonte não tem lookup por id — a rodada atual (já cacheada por si só)
    // é o único lugar de onde emitimos ids `cbapi-`, então procurar nela é
    // suficiente e evita mais uma chamada externa.
    const { competition, round } = await fetchBrasileiraoCurrentRound(config.serieCode);
    const match = round.matches.find((m) => String(m.id) === fixtureId);
    if (!match) {
      throw new ProviderError('Partida não encontrada na rodada atual.', 404, 'brasileirao');
    }
    return {
      competition: { name: competition.name, season: competition.season },
      match: normalizeBrasileiraoMatch(match, round.label),
    };
  });
}

async function handleTheSportsDbFixture(request: Request, cacheVersion: string, eventId: string): Promise<Response> {
  return cacheFirst(request, CACHE_TTL_SECONDS, 'football.fixtures.details.thesportsdb', cacheVersion, async () => {
    const event = await fetchEventById(eventId);
    if (!event) {
      throw new ProviderError('Partida não encontrada.', 404, 'thesportsdb');
    }
    return {
      competition: { name: event.strLeague, season: event.strSeason ? Number(event.strSeason) : null },
      match: normalizeTheSportsDbEvent(event),
    };
  });
}

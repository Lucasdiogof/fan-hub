// Paridade: os builders novos == os handlers ANTIGOS do Worker (src/football),
// alimentados pelas MESMAS páginas capturadas do OneFootball (sem internet).
// Compara o JSON byte a byte (JSON.stringify), que é o contrato do Flutter.
import { afterEach, beforeAll, describe, expect, it } from 'vitest';
import { handleCompetitions } from '../../../../src/football/competitions';
import { handleCurrentRound } from '../../../../src/football/currentRound';
import { handleFixtureDetails } from '../../../../src/football/fixtureDetails';
import { handleStandings } from '../../../../src/football/standings';
import { handleTeam } from '../../../../src/football/team';
import { handleTeamSeason } from '../../../../src/football/teamSeason';
import { resolveClubServerConfigByCode } from '../club_server_config';
import {
  buildCompetitionsSnapshot,
  buildCurrentRoundSnapshots,
  buildFixtureSnapshot,
  buildSeasonSnapshot,
  buildStandingsSnapshot,
  buildTeamSnapshot,
} from './builders';
import { fakeFetch, PAGES } from './__fixtures__/fake_onefootball';
import { setFetcher } from './provider';

const realFetch = globalThis.fetch;
let seq = 0;

// O Worker antigo usa o `fetch` global; o novo usa `setFetcher`.
beforeAll(() => {
  const fake = fakeFetch();
  globalThis.fetch = fake;
  setFetcher(fake);
});
afterEach(() => undefined);

const envFor = (code: string) => {
  const c = resolveClubServerConfigByCode(code)!;
  return {
    CLUB_CODE: c.code,
    TEAM_ONEFOOTBALL_SLUG: c.oneFootballSlug,
    PRIMARY_COMPETITION_SLUG: c.primaryCompetitionSlug,
    PRIMARY_COMPETITION_DISPLAY_NAME: c.primaryCompetitionDisplayName,
    CACHE_VERSION: `parity-${++seq}`, // chave de cache única -> nunca reaproveita resposta
    ASSETS: {} as Fetcher,
  };
};
const old = async (res: Response) => {
  expect(res.status).toBe(200);
  return res.json();
};
const req = (path: string) =>
  new Request(`https://parity.test${path}${path.includes('?') ? '&' : '?'}n=${++seq}`);
const same = (a: unknown, b: unknown) => expect(JSON.stringify(a)).toBe(JSON.stringify(b));

describe.each(['goias', 'vilanova', 'bragantino'])('paridade com o Worker antigo — %s', (code) => {
  const club = resolveClubServerConfigByCode(code)!;

  it('team', async () => {
    same(await buildTeamSnapshot(club), await old(await handleTeam(req(`/api/football/team/${code}`), envFor(code), code)));
  });

  it('season', async () => {
    same(
      await buildSeasonSnapshot(club),
      await old(await handleTeamSeason(req(`/api/football/team/${code}/season`), envFor(code), code)),
    );
  });

  it('current_round: toda rodada materializada == resposta antiga (offsets em alcance)', async () => {
    const rounds = await buildCurrentRoundSnapshots(club);
    expect(rounds.has(0)).toBe(true);
    for (const [offset, payload] of rounds) {
      const expected = await old(
        await handleCurrentRound(req(`/api/football/current-round?offset=${offset}`), envFor(code)),
      );
      same(payload, expected);
    }
    // Fora de alcance não há snapshot: o app só navega quando hasPrevious/hasNext.
    const offsets = [...rounds.keys()];
    expect(rounds.has(Math.min(...offsets) - 1)).toBe(false);
    expect(rounds.has(Math.max(...offsets) + 1)).toBe(false);
  });

  it('standings (competição principal)', async () => {
    same(
      await buildStandingsSnapshot(club, 'primary'),
      await old(await handleStandings(req('/api/football/standings'), envFor(code))),
    );
  });

  it('competitions', async () => {
    same(buildCompetitionsSnapshot(club), await old(await handleCompetitions(req('/api/football/competitions'), envFor(code))));
  });
});

describe('paridade — fixture (detalhe) e catálogo', () => {
  const matchIds = Object.keys(PAGES)
    .filter((p) => p.startsWith('match/'))
    .map((p) => p.slice('match/'.length));

  it('há detalhes capturados', () => expect(matchIds.length).toBeGreaterThanOrEqual(5));

  it.each(matchIds)('fixture onef-%s', async (id) => {
    const club = resolveClubServerConfigByCode('goias')!;
    void club;
    same(
      await buildFixtureSnapshot(`onef-${id}`),
      await old(await handleFixtureDetails(req(`/api/football/fixtures/onef-${id}`), envFor('goias'), `onef-${id}`)),
    );
  });

  it('standings de competição do catálogo (?competition=)', async () => {
    const club = resolveClubServerConfigByCode('bragantino')!;
    same(
      await buildStandingsSnapshot(club, 'brasileirao-serie-b'),
      await old(
        await handleStandings(req('/api/football/standings?competition=brasileirao-serie-b'), envFor('bragantino')),
      ),
    );
  });
});

// Restaura o fetch real ao final do arquivo.
import { afterAll } from 'vitest';
afterAll(() => {
  globalThis.fetch = realFetch;
});

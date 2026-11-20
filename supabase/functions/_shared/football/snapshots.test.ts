// Normalização/contrato dos snapshots a partir de páginas REAIS do OneFootball
// (capturadas em 2026-11-20) + cenários SINTÉTICOS (marcados) pro que o
// snapshot real não cobre (ao vivo, intervalo, adiado, cancelado, sem estádio).
// Sem internet. Os `toMatchSnapshot` fixam o JSON: mudar o parser vira diff
// explícito no code review.
import { beforeEach, describe, expect, it } from 'vitest';
import { resolveClubServerConfigByCode } from '../club_server_config';
import {
  buildCompetitionsSnapshot,
  buildFixtureSnapshot,
  buildSeasonSnapshot,
  buildStandingsSnapshot,
  buildTeamSnapshot,
  pickCurrentRoundIndex,
} from './builders';
import { fakeFetch, visitAll } from './__fixtures__/fake_onefootball';
import { setFetcher } from './provider';
import type { OneFootballMatchList } from './provider';

const club = (code: string) => resolveClubServerConfigByCode(code)!;
const STATUSES = ['scheduled', 'live', 'halftime', 'finished', 'postponed', 'cancelled', 'suspended', 'unknown'];

/** Mesmos campos que `MatchDto.fromJson` (Flutter) lê — contrato estável. */
function expectMatchContract(m: Record<string, any>): void {
  expect(typeof m.id).toBe('string');
  expect(m.id).toMatch(/^onef-\d+$/);
  for (const side of ['homeTeam', 'awayTeam']) {
    expect(typeof m[side].id).toBe('number');
    expect(m[side]).toHaveProperty('name');
    expect(m[side]).toHaveProperty('shortName');
    expect(m[side]).toHaveProperty('logo');
  }
  // Horário "de parede" do Brasil, sem offset/Z.
  expect(m.kickoff === null || /^\d{4}-\d{2}-\d{2}T[\d:.]+$/.test(m.kickoff)).toBe(true);
  expect(STATUSES).toContain(m.status);
  expect(m.homeScore === null || Number.isInteger(m.homeScore)).toBe(true);
  expect(m.awayScore === null || Number.isInteger(m.awayScore)).toBe(true);
  expect(m.venue === null || typeof m.venue === 'string').toBe(true);
  expect(m.minute === null || typeof m.minute === 'string').toBe(true);
}

beforeEach(() => setFetcher(fakeFetch()));

describe.each(['goias', 'vilanova', 'bragantino'])('team — %s', (code) => {
  it('tem o formato esperado pelo Flutter', async () => {
    const t = (await buildTeamSnapshot(club(code))) as any;
    expect(t.competition).toEqual({ name: '', season: null });
    expectMatchContract(t.nextMatch);
    expect(t.nextMatch.competition).toEqual(expect.any(String));
    expect(t.recentResults.length).toBeGreaterThan(0);
    t.recentResults.forEach(expectMatchContract);
    // O clube ativo é identificável pelo id (mandante OU visitante).
    const id = club(code).oneFootballTeamId;
    expect([t.nextMatch.homeTeam.id, t.nextMatch.awayTeam.id]).toContain(id);
  });
});

describe('team — cenários reais', () => {
  it('agendado, com estádio (Vila, visitante)', async () => {
    const t = (await buildTeamSnapshot(club('vilanova'))) as any;
    expect(t.nextMatch.status).toBe('scheduled');
    expect(t.nextMatch.venue).toBe('Estádio Antônio Accioly');
    expect(t.nextMatch.awayTeam.id).toBe(2865); // Vila visitante
    expect(t.nextMatch.homeScore).toBeNull();
  });

  it('agendado como mandante (Bragantino)', async () => {
    const t = (await buildTeamSnapshot(club('bragantino'))) as any;
    expect(t.nextMatch.homeTeam.id).toBe(4734);
  });

  it('encerrado (Goiás visitante) vem como nextMatch com placar', async () => {
    const t = (await buildTeamSnapshot(club('goias'))) as any;
    expect(t.nextMatch.status).toBe('finished');
    expect(t.nextMatch.awayTeam.id).toBe(1863);
    expect(t.nextMatch.homeScore).toBe(3);
    expect(t.nextMatch.awayScore).toBe(0);
  });

  it('golden: Goiás', async () => expect(await buildTeamSnapshot(club('goias'))).toMatchSnapshot());
  it('golden: Vila Nova', async () => expect(await buildTeamSnapshot(club('vilanova'))).toMatchSnapshot());
  it('golden: Bragantino', async () => expect(await buildTeamSnapshot(club('bragantino'))).toMatchSnapshot());
});

// --- SINTÉTICO: o snapshot de 20/11 só tem PRE_MATCH e FULL_TIME ---
describe('team — status SINTÉTICOS (derivados do formato real)', () => {
  const withPeriod = (period: string, extra: Record<string, unknown> = {}) =>
    fakeFetch((path, body) => {
      if (path === 'time/vila-nova-2865/jogos') {
        let done = false;
        visitAll(body, (o) => {
          if (!done && typeof o.matchId === 'string' && o.period === 'PRE_MATCH') {
            done = true;
            Object.assign(o, { period }, extra);
          }
        });
      }
      return body;
    });

  it.each([
    ['FIRST_HALF', 'live'],
    ['SECOND_HALF', 'live'],
    ['HALF_TIME', 'halftime'],
    ['POSTPONED', 'postponed'],
    ['CANCELLED', 'cancelled'],
    ['SUSPENDED', 'suspended'],
    ['ALGO_NOVO', 'unknown'],
  ])('period %s -> %s', async (period, status) => {
    setFetcher(withPeriod(period, { timePeriod: "37'" }));
    const t = (await buildTeamSnapshot(club('vilanova'))) as any;
    expect(t.nextMatch.status).toBe(status);
    expectMatchContract(t.nextMatch);
    expect(t.nextMatch.minute).toBe("37'"); // minuto vem direto da fonte
  });

  it('ao vivo com placar, Vila vencendo como visitante', async () => {
    setFetcher(
      withPeriod('SECOND_HALF', {
        timePeriod: "70'",
        homeTeam: undefined, // preenchido abaixo
      }),
    );
    setFetcher(
      fakeFetch((path, body) => {
        if (path === 'time/vila-nova-2865/jogos') {
          let done = false;
          visitAll(body, (o) => {
            if (!done && typeof o.matchId === 'string' && o.period === 'PRE_MATCH') {
              done = true;
              o.period = 'SECOND_HALF';
              o.timePeriod = "70'";
              (o.homeTeam as any).score = '0';
              (o.awayTeam as any).score = '2';
            }
          });
        }
        return body;
      }),
    );
    const t = (await buildTeamSnapshot(club('vilanova'))) as any;
    expect(t.nextMatch).toMatchObject({ status: 'live', homeScore: 0, awayScore: 2, minute: "70'" });
  });

  it('placar "-" vira null (nunca 0 inventado)', async () => {
    const t = (await buildTeamSnapshot(club('vilanova'))) as any;
    expect(t.nextMatch.homeScore).toBeNull();
    expect(t.nextMatch.awayScore).toBeNull();
  });
});

describe('fixture (detalhe)', () => {
  it('encerrado: eventos, escalação e estatísticas', async () => {
    const f = (await buildFixtureSnapshot('onef-2669610')) as any;
    expectMatchContract(f.match);
    expect(f.match.status).toBe('finished');
    expect(f.competition.name).toBe('Brasileirão Série B');
    const types = new Set(f.events.map((e: any) => e.type));
    expect(types).toContain('goal');
    expect(types).toContain('yellow_card');
    expect(types).toContain('substitution');
    for (const e of f.events) {
      expect(['home', 'away']).toContain(e.side);
      expect(e).toHaveProperty('minute');
    }
    expect(f.lineups.home.rows.length).toBeGreaterThan(0);
    expect(f.lineups.home.rows[0][0]).toEqual(
      expect.objectContaining({ name: expect.any(String), jerseyNumber: expect.any(Number), photo: expect.any(String) }),
    );
    expect(f.stats.length).toBeGreaterThan(0);
    for (const s of f.stats) {
      expect(['percent', 'count']).toContain(s.unit);
      expect(s).toHaveProperty('home');
      expect(s).toHaveProperty('away');
    }
  });

  it('agendado: sem eventos/escalação/estatísticas', async () => {
    const f = (await buildFixtureSnapshot('onef-2669858')) as any;
    expect(f.match.status).toBe('scheduled');
    expect(f.events).toEqual([]);
    expect(f.lineups).toBeNull();
    expect(f.stats).toEqual([]);
  });

  it('SINTÉTICO: sem estádio -> venue null', async () => {
    setFetcher(
      fakeFetch((path, body) => {
        if (path.startsWith('match/')) {
          visitAll(body, (o) => {
            if ('matchInfo' in o) delete o.matchInfo;
          });
        }
        return body;
      }),
    );
    const f = (await buildFixtureSnapshot('onef-2669858')) as any;
    expect(f.match.venue).toBeNull();
  });

  it('SINTÉTICO: estatística sem dado vira null, nunca 0', async () => {
    setFetcher(
      fakeFetch((path, body) => {
        if (path === 'match/2669610') {
          visitAll(body, (o) => {
            if (Array.isArray(o.stats) && o.stats.length) {
              const s = o.stats[0] as Record<string, unknown>;
              delete s.home;
              delete s.away;
            }
          });
        }
        return body;
      }),
    );
    const f = (await buildFixtureSnapshot('onef-2669610')) as any;
    expect(f.stats[0].home).toBeNull();
    expect(f.stats[0].away).toBeNull();
  });

  it('id inválido e partida inexistente falham de forma controlada', async () => {
    await expect(buildFixtureSnapshot('abc')).rejects.toMatchObject({ status: 400 });
    await expect(buildFixtureSnapshot('onef-1')).rejects.toBeDefined();
  });

  it('golden: partida encerrada', async () =>
    expect(await buildFixtureSnapshot('onef-2669610')).toMatchSnapshot());
});

describe('season / standings / competitions', () => {
  it('season: todas as competições, ordenada por horário', async () => {
    const { matches } = (await buildSeasonSnapshot(club('goias'))) as { matches: any[] };
    expect(matches.length).toBeGreaterThan(10);
    matches.forEach(expectMatchContract);
    const kicks = matches.map((m) => m.kickoff ?? '');
    expect([...kicks].sort()).toEqual(kicks);
    const id = 1863;
    expect(matches.some((m) => m.homeTeam.id === id)).toBe(true); // mandante
    expect(matches.some((m) => m.awayTeam.id === id)).toBe(true); // visitante
  });

  it('standings principal: linhas numeradas com time e pontos', async () => {
    const s = (await buildStandingsSnapshot(club('goias'), 'primary')) as any;
    expect(s.competition).toMatchObject({ name: 'Brasileirão Série B', format: 'LEAGUE_TABLE' });
    expect(s.standings).toHaveLength(20);
    expect(s.standings.map((r: any) => r.position)).toEqual([...Array(20).keys()].map((i) => i + 1));
    expect(s.standings[0]).toMatchObject({ points: expect.any(Number), form: null });
    expect(s.standings[0].team.id).toEqual(expect.any(Number));
    expect(s.season.stages[0].isCurrent).toBeDefined();
  });

  it('standings: id de competição inexistente -> 404 controlado', async () => {
    await expect(buildStandingsSnapshot(club('goias'), 'nao-existe')).rejects.toMatchObject({ status: 404 });
  });

  it('competitions: catálogo global + participação por clube', () => {
    const v = buildCompetitionsSnapshot(club('vilanova')).competitions;
    const b = buildCompetitionsSnapshot(club('bragantino')).competitions;
    expect(v.filter((c) => c.isClubParticipating).map((c) => c.id)).toEqual(['brasileirao-serie-b']);
    expect(b.filter((c) => c.isClubParticipating).map((c) => c.id)).toEqual(['brasileirao-serie-a', 'sudamericana']);
  });

  it('pickCurrentRoundIndex: adiado nunca ancora a rodada atual', () => {
    const card = (period: string) => ({ matchCards: [{ period }] }) as unknown as OneFootballMatchList;
    expect(pickCurrentRoundIndex([card('FULL_TIME'), card('POSTPONED'), card('PRE_MATCH')])).toBe(2);
    expect(pickCurrentRoundIndex([card('FULL_TIME'), card('FULL_TIME')])).toBe(1);
  });
});

describe('isolamento multiclube', () => {
  it('config de cada clube aponta só pro próprio slug/competição', () => {
    expect(club('goias').oneFootballSlug).toBe('goias-1863');
    expect(club('vilanova').oneFootballSlug).toBe('vila-nova-2865');
    expect(club('bragantino').oneFootballSlug).toBe('rb-bragantino-4734');
    expect(club('bragantino').primaryCompetitionDisplayName).toBe('Brasileirão Série A');
  });
});

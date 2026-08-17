/**
 * Reduz o payload cru da API-Football para o formato interno simples que a
 * gente devolve pro Flutter. O Flutter não precisa (nem deve) conhecer a
 * resposta inteira da API-Football — só os campos que a UI usa.
 */

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function normalizeFixture(raw: any) {
  return {
    fixtureId: raw.fixture.id,
    round: raw.league.round,
    homeTeam: {
      id: raw.teams.home.id,
      name: raw.teams.home.name,
      logo: raw.teams.home.logo,
    },
    awayTeam: {
      id: raw.teams.away.id,
      name: raw.teams.away.name,
      logo: raw.teams.away.logo,
    },
    kickoff: raw.fixture.date,
    venue: {
      name: raw.fixture.venue?.name ?? null,
      city: raw.fixture.venue?.city ?? null,
    },
    status: raw.fixture.status?.short ?? 'TBD',
    homeScore: raw.goals?.home ?? null,
    awayScore: raw.goals?.away ?? null,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function normalizeStanding(raw: any) {
  return {
    position: raw.rank,
    team: {
      id: raw.team.id,
      name: raw.team.name,
      logo: raw.team.logo,
    },
    points: raw.points,
    played: raw.all.played,
    wins: raw.all.win,
    draws: raw.all.draw,
    losses: raw.all.lose,
    goalsFor: raw.all.goals.for,
    goalsAgainst: raw.all.goals.against,
    form: raw.form ?? null,
  };
}

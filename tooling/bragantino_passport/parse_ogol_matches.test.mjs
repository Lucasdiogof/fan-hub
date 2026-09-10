import test from 'node:test';
import assert from 'node:assert/strict';
import { parseOgolTeamMatches } from './parse_ogol_matches.mjs';

function table(rows) {
  return `<table>${rows.join('\n')}</table>`;
}

function row({ internalId, displayedDate, time='20:00', marker='C', opponentSlug='santos', opponent='Santos', hrefDate=displayedDate, matchSlug='red-bull-bragantino-santos', matchId='8522365', score='0-2', attrs='', competitionSlug='brasileirao', competitionYear='2022', competitionId='162047', competition='Brasileirão 2022', penalty='' }) {
  return `<tr data-lj="h2" id="${internalId}" class="parent"><td class="double">${displayedDate}</td><td>${time}</td><td>(${marker})</td><td><a href="/equipe/${opponentSlug}?epoca_id=151">${opponent}</a></td><td><a ${attrs}href="/jogo/${hrefDate}-${matchSlug}/${matchId}">${score}${penalty}</a></td><td><a href="/edicao/${competitionSlug}-${competitionYear}/${competitionId}">${competition}</a></td></tr>`;
}

test('uses displayed local date while preserving an off-by-one href date', () => {
  const html = table([row({ internalId: '1', displayedDate: '2022-10-17', hrefDate: '2022-10-18' })]);
  const [m] = parseOgolTeamMatches(html, { teamSlug: 'red-bull-bragantino' });
  assert.equal(m.date, '2022-10-17');
  assert.equal(m.source_url_date, '2022-10-18');
  assert.equal(m.date_href_mismatch, true);
  assert.equal(m.source_url, 'https://www.ogol.com.br/jogo/2022-10-18-red-bull-bragantino-santos/8522365');
});

test('keeps home/away score order for away matches', () => {
  const html = table([row({ internalId: '2', marker: 'F', opponentSlug: 'fortaleza', opponent: 'Fortaleza', matchSlug: 'fortaleza-red-bull-bragantino', matchId: '8522419', score: '6-0' })]);
  const [m] = parseOgolTeamMatches(html, { teamSlug: 'red-bull-bragantino' });
  assert.equal(m.club_is_home, false);
  assert.equal(m.home_score, 6);
  assert.equal(m.away_score, 0);
});

test('does not drop rows whose result link has class=prol and parses penalties', () => {
  const html = table([row({ internalId: '3', attrs: 'class="prol" ', score: '1-2', penalty: '<span>(5-4 Pen.)</span>' })]);
  const [m] = parseOgolTeamMatches(html, { teamSlug: 'red-bull-bragantino' });
  assert.equal(m.home_score, 1);
  assert.equal(m.away_score, 2);
  assert.equal(m.penalty_home_score, 5);
  assert.equal(m.penalty_away_score, 4);
});

test('parses the historical Bragantino route that still uses red-bull-bragantino in match hrefs', () => {
  const html = table([row({ internalId: '4', displayedDate: '2000-10-07', time: '16:00', opponentSlug: 'botafogo-sp', opponent: 'Botafogo-SP', hrefDate: '2000-10-07', matchSlug: 'red-bull-bragantino-botafogo-sp', matchId: '1534403', score: '0-2', competitionSlug: 'copa-joao-havelange', competitionYear: '2000', competitionId: '2495', competition: 'Copa João Havelange 2000' })]);
  const [m] = parseOgolTeamMatches(html, { teamSlug: 'red-bull-bragantino' });
  assert.equal(m.club_is_home, true);
  assert.equal(m.competition_display, 'Copa João Havelange 2000');
  assert.equal(m.source_match_id, '1534403');
});

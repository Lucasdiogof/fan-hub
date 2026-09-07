// node --test tooling/bragantino_passport/validate_import.test.mjs
//
// Um validador que só sabe dizer "passou" não vale nada — aqui cada regra
// é exercitada com uma partida DELIBERADAMENTE quebrada, pra provar que
// ela realmente pega o problema.
import test from 'node:test';
import assert from 'node:assert/strict';

import { validate } from './validate_import.mjs';

function baseMatch(overrides = {}) {
  return {
    id: 'pb_ogol_1',
    calendar_year: 2025,
    date: '2025-05-05', // segunda-feira
    competition: 'Brasileirão Série A',
    competition_edition: 'Brasileirão 2025',
    round: null,
    time: '20:00',
    weekday: 'segunda-feira',
    day_type: 'WEEKDAY',
    day_period: 'NIGHT',
    home_team: 'Red Bull Bragantino',
    away_team: 'Mirassol',
    club_is_home: true,
    home_score: 2,
    away_score: 1,
    club_score: 2,
    opponent_score: 1,
    score_display: '2–1',
    score_status: 'FINISHED',
    outcome: 'WIN',
    stadium: 'Estádio Municipal Cícero de Souza Marques',
    stadium_status: 'MATCH_SPECIFIC',
    venue_city: 'Bragança Paulista',
    source_provider: 'oGol (ogol.com.br)',
    source_match_id: '1',
    source_url: 'https://www.ogol.com.br/jogo/x/1',
    ...overrides,
  };
}

function run(matches) {
  return validate([{ file: 'test.json', wrapper: { matches } }]);
}

function checks(result) {
  return new Set(result.problems.map((p) => p.check));
}

test('dataset correto não acusa nada', () => {
  const result = run([baseMatch()]);
  assert.deepEqual(result.problems, []);
  assert.equal(result.total, 1);
});

test('id repetido é pego', () => {
  const result = run([baseMatch(), baseMatch({ source_match_id: '2', date: '2025-05-12' })]);
  assert.ok(checks(result).has('IDS_UNICOS'));
});

test('mesma partida da fonte em 2 registros é pega', () => {
  const result = run([
    baseMatch(),
    baseMatch({ id: 'pb_ogol_2', date: '2025-05-12' }),
  ]);
  assert.ok(checks(result).has('DUPLICATAS'));
});

test('mesmo confronto na mesma data é pego', () => {
  const result = run([
    baseMatch(),
    baseMatch({ id: 'pb_ogol_2', source_match_id: '2' }),
  ]);
  assert.ok(checks(result).has('DUPLICATAS'));
});

test('partida sem o Bragantino em nenhum lado é pega', () => {
  const result = run([
    baseMatch({ home_team: 'Santos', away_team: 'Mirassol' }),
  ]);
  assert.ok(checks(result).has('CLUBE_CORRETO'));
});

test('mando incoerente com os times é pego', () => {
  const result = run([baseMatch({ club_is_home: false })]);
  assert.ok(checks(result).has('MANDO'));
});

test('data inválida e ano fora do lote são pegos', () => {
  assert.ok(checks(run([baseMatch({ date: '2025-13-45' })])).has('DATA_VALIDA'));
  assert.ok(
    checks(run([baseMatch({ calendar_year: 2024 })])).has('DATA_VALIDA'),
  );
});

test('adversário vazio ou igual ao próprio clube é pego', () => {
  // Com o adversário em branco o clube ainda está de um lado só, então
  // quem acusa é a regra do ADVERSARIO, não a do CLUBE_CORRETO.
  assert.ok(checks(run([baseMatch({ away_team: '' })])).has('ADVERSARIO'));
  const selfMatch = run([baseMatch({ away_team: 'Bragantino' })]);
  assert.ok(checks(selfMatch).has('ADVERSARIO'));
});

test('placar incoerente é pego', () => {
  assert.ok(checks(run([baseMatch({ club_score: 5 })])).has('PLACAR'));
  assert.ok(checks(run([baseMatch({ outcome: 'LOSS' })])).has('PLACAR'));
  assert.ok(
    checks(run([baseMatch({ score_status: 'FINISHED', home_score: null })])).has(
      'PLACAR',
    ),
  );
  assert.ok(
    checks(
      run([
        baseMatch({
          score_status: 'SCHEDULED',
          outcome: null,
          club_score: null,
          opponent_score: null,
        }),
      ]),
    ).has('PLACAR'),
    'jogo agendado não pode vir com placar',
  );
});

test('estádio sem evidência específica é pego', () => {
  assert.ok(
    checks(run([baseMatch({ stadium_status: 'NEEDS_SOURCE' })])).has(
      'ESTADIO_EVIDENCIA',
    ),
  );
  assert.ok(
    checks(run([baseMatch({ stadium: null })])).has('ESTADIO_EVIDENCIA'),
  );
  assert.ok(
    checks(run([baseMatch({ source_url: null })])).has('ESTADIO_EVIDENCIA'),
  );
});

test('estádio desconhecido de forma honesta NÃO é erro', () => {
  const result = run([
    baseMatch({ stadium: null, stadium_status: 'NEEDS_SOURCE' }),
  ]);
  assert.deepEqual(result.problems, []);
});

test('período do dia incoerente com o horário é pego', () => {
  assert.ok(
    checks(run([baseMatch({ day_period: 'MORNING' })])).has('PERIODO_DO_DIA'),
  );
  assert.ok(
    checks(run([baseMatch({ time: null })])).has('PERIODO_DO_DIA'),
    'sem horário o período tem que ser UNKNOWN',
  );
});

test('horário desconhecido com UNKNOWN NÃO é erro', () => {
  const result = run([baseMatch({ time: null, day_period: 'UNKNOWN' })]);
  assert.deepEqual(result.problems, []);
});

test('weekday/weekend incoerente com a data é pego', () => {
  const result = run([baseMatch({ day_type: 'WEEKEND' })]);
  assert.ok(checks(result).has('WEEKDAY_WEEKEND'));
});

test('qualquer rastro do Goiás é pego', () => {
  const result = run([baseMatch({ away_team: 'Goiás Esporte Clube' })]);
  assert.ok(checks(result).has('SEM_DADO_DO_GOIAS'));
});

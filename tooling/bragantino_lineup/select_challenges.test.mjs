// node --test tooling/bragantino_lineup/select_challenges.test.mjs
//
// Cobre as regras de publicabilidade e o balanceamento contra um pool
// SINTÉTICO — o pool real hoje tem 0 publicável (falta formação/posição),
// então sem isso a lógica de seleção nunca seria exercitada até a pesquisa
// chegar.
import test from 'node:test';
import assert from 'node:assert/strict';

import {
  evaluateMatch,
  selectBalanced,
  REJECTION,
  CANONICAL_POSITIONS,
} from './select_challenges.mjs';

const POSITIONS_442 = [
  'GOL',
  'LD',
  'ZAG',
  'ZAG',
  'LE',
  'VOL',
  'MC',
  'MEI',
  'MEI',
  'ATA',
  'ATA',
];

function xi(names, positions = POSITIONS_442) {
  return names.map((name, i) => ({
    name,
    number: i + 1,
    position: positions[i],
  }));
}

function match(overrides = {}) {
  const names = Array.from({ length: 11 }, (_, i) => `Jogador ${i + 1}`);
  return {
    source_match_id: 'm1',
    calendar_year: 2025,
    date: '2025-05-05',
    competition: 'Brasileirão Série A',
    opponent: 'Mirassol',
    club_is_home: true,
    formation: '4-4-2',
    starting_xi: xi(names),
    ...overrides,
  };
}

test('partida completa e coerente é publicável', () => {
  const result = evaluateMatch(match());
  assert.equal(result.publishable, true);
  assert.deepEqual(result.reasons, []);
});

test('sem formação não publica', () => {
  const result = evaluateMatch(match({ formation: null }));
  assert.equal(result.publishable, false);
  assert.ok(result.reasons.includes(REJECTION.missingFormation));
});

test('formação fora do catálogo conhecido não publica', () => {
  const result = evaluateMatch(match({ formation: '2-7-1' }));
  assert.ok(result.reasons.includes(REJECTION.unknownFormation));
});

test('jogador sem posição não publica', () => {
  const broken = match();
  broken.starting_xi[3] = { name: 'Sem Posição', number: 4 };
  const result = evaluateMatch(broken);
  assert.ok(result.reasons.includes(REJECTION.missingPositions));
});

test('posição fora do catálogo canônico não publica', () => {
  const broken = match();
  broken.starting_xi[5].position = 'CAMISA_10';
  const result = evaluateMatch(broken);
  assert.ok(result.reasons.includes(REJECTION.invalidPosition));
  assert.ok(!CANONICAL_POSITIONS.includes('CAMISA_10'));
});

test('XI com menos de 11 não publica', () => {
  const broken = match();
  broken.starting_xi = broken.starting_xi.slice(0, 10);
  const result = evaluateMatch(broken);
  assert.ok(result.reasons.includes(REJECTION.notEleven));
});

test('primeiro do XI precisa ser o goleiro (ordem da formação)', () => {
  const broken = match();
  broken.starting_xi[0].position = 'ATA';
  const result = evaluateMatch(broken);
  assert.ok(result.reasons.includes(REJECTION.formationMismatch));
});

test('seleção varia adversário em vez de pegar tudo do mesmo', () => {
  const pool = [];
  for (let i = 0; i < 10; i++) {
    pool.push(
      match({
        source_match_id: `rep-${i}`,
        opponent: 'Palmeiras',
        starting_xi: xi(
          Array.from({ length: 11 }, (_, j) => `Rep ${i}-${j}`),
        ),
      }),
    );
  }
  for (let i = 0; i < 4; i++) {
    pool.push(
      match({
        source_match_id: `var-${i}`,
        opponent: `Adversário ${i}`,
        competition: 'Copa do Brasil',
        starting_xi: xi(
          Array.from({ length: 11 }, (_, j) => `Var ${i}-${j}`),
        ),
      }),
    );
  }

  const selection = selectBalanced(pool, { target: 6 });
  const opponents = new Set(selection.map((m) => m.opponent));
  assert.ok(
    opponents.size >= 4,
    `esperava variedade de adversários, veio ${[...opponents].join(', ')}`,
  );
});

test('escalações quase idênticas não viram dois desafios', () => {
  const base = Array.from({ length: 11 }, (_, i) => `Titular ${i}`);
  const pool = [
    match({ source_match_id: 'a', starting_xi: xi(base) }),
    // mesmo XI, adversário diferente — não pode entrar junto
    match({
      source_match_id: 'b',
      opponent: 'Outro',
      starting_xi: xi(base),
    }),
  ];
  const selection = selectBalanced(pool, { target: 5 });
  assert.equal(selection.length, 1);
});

test('não quebra nem enche com repetição quando o pool é pequeno', () => {
  const selection = selectBalanced([match()], { target: 24 });
  assert.equal(selection.length, 1);
});

test('pool vazio devolve seleção vazia', () => {
  assert.deepEqual(selectBalanced([], { target: 24 }), []);
});

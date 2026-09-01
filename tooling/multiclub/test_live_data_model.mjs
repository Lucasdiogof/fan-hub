// Testes dos 7 cenários pedidos na v3.1, rodando puro em Node (sem
// framework, sem Supabase, sem Flutter) contra live_data_model.mjs — prova
// de conceito ANTES do INSERT/migration real. Rodar: node
// tooling/multiclub/test_live_data_model.mjs
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import {
  classifyAppearance,
  countsAsAppearance,
  AppearanceLedger,
  resolveLiveAppearances,
  validateSpell,
  addPosition,
  allPositions,
  primaryPosition,
  temporalValue,
  canonicalMatchId,
} from './live_data_model.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

let passed = 0;
const failures = [];

function test(name, fn) {
  try {
    fn();
    passed++;
    console.log(`  PASS — ${name}`);
  } catch (err) {
    failures.push({ name, err });
    console.log(`  FAIL — ${name}\n    ${err.message}`);
  }
}

console.log('1) Mesma partida sincronizada 10x não duplica');
test('upsert 10x com a mesma (personId, clubId, matchId) produz 1 linha só', () => {
  const ledger = new AppearanceLedger();
  const matchId = canonicalMatchId({ source: 'onefootball_worker', externalId: 'fixture_555' });
  for (let i = 0; i < 10; i++) {
    ledger.upsert('person_tadeu', 'club_goias', matchId, { status: 'STARTED', minutesPlayed: 90, syncedAt: i });
  }
  assert.strictEqual(ledger.count(), 1, `esperava 1 linha, achou ${ledger.count()}`);
  assert.strictEqual(ledger.countForPerson('person_tadeu', 'club_goias'), 1);
});

console.log('\n2) Reserva que entra conta como aparição');
test('SUBSTITUTE_USED conta como appearance', () => {
  const status = classifyAppearance({ started: false, cameInMinute: 63, wasInSquad: true });
  assert.strictEqual(status, 'SUBSTITUTE_USED');
  assert.strictEqual(countsAsAppearance(status), true);
});

console.log('\n3) Reserva não utilizado NÃO conta como aparição');
test('UNUSED_SUBSTITUTE não conta como appearance', () => {
  const status = classifyAppearance({ started: false, cameInMinute: null, wasInSquad: true });
  assert.strictEqual(status, 'UNUSED_SUBSTITUTE');
  assert.strictEqual(countsAsAppearance(status), false);
});
test('titular (STARTED) conta como appearance', () => {
  const status = classifyAppearance({ started: true, cameInMinute: null, wasInSquad: true });
  assert.strictEqual(countsAsAppearance(status), true);
});

console.log('\n4) Tadeu: baseline 400 + 1 aparição posterior = 401');
test('baseline 400 (as_of 2026-08-28) + 1 nova aparição real = 401', () => {
  const baseline = { appearances: 400, asOfDate: '2026-08-28', asOfMatchId: 'pe_cb52680435343cc4' };
  const ledger = new AppearanceLedger();
  const nextMatchId = canonicalMatchId({ source: 'onefootball_worker', externalId: 'fixture_next' });
  ledger.upsert('person_tadeu', 'club_goias', nextMatchId, { status: 'STARTED' });
  const total = resolveLiveAppearances(baseline, ledger, 'person_tadeu', 'club_goias');
  assert.strictEqual(total, 401, `esperava 401, achou ${total}`);
});
test('sincronizar a MESMA próxima partida 5x não passa de 401 (idempotência + baseline juntos)', () => {
  const baseline = { appearances: 400, asOfDate: '2026-08-28', asOfMatchId: 'pe_cb52680435343cc4' };
  const ledger = new AppearanceLedger();
  const nextMatchId = canonicalMatchId({ source: 'onefootball_worker', externalId: 'fixture_next' });
  for (let i = 0; i < 5; i++) ledger.upsert('person_tadeu', 'club_goias', nextMatchId, { status: 'STARTED' });
  assert.strictEqual(resolveLiveAppearances(baseline, ledger, 'person_tadeu', 'club_goias'), 401);
});

console.log('\n5) Walter: passagem real com 0 jogos é válida, não um erro');
test('spell com appearances=0 e registrationType=permanent é válido', () => {
  const spell = { personId: 'person_walter', clubId: 'club_goias', registrationType: 'permanent', appearances: 0, note: '2019, suspenso antes de reestrear' };
  const { valid, errors } = validateSpell(spell);
  assert.strictEqual(valid, true, `esperava válido, erros: ${JSON.stringify(errors)}`);
});
test('spell com appearances negativo é inválido (sanity check do validador)', () => {
  const { valid } = validateSpell({ personId: 'x', clubId: 'y', registrationType: 'loan', appearances: -1 });
  assert.strictEqual(valid, false);
});

console.log('\n6) Dieguinho: múltiplas posições sem colapsar pra uma só');
test('pessoa com 3 posições registradas mantém todas, só 1 marcada primária', () => {
  let positions = [];
  positions = addPosition(positions, 'person_dieguinho', 'club_goias', 'meio-campo', { isPrimary: true });
  positions = addPosition(positions, 'person_dieguinho', 'club_goias', 'lateral-direito');
  positions = addPosition(positions, 'person_dieguinho', 'club_goias', 'volante');
  assert.deepStrictEqual(
    allPositions(positions, 'person_dieguinho', 'club_goias').sort(),
    ['lateral-direito', 'meio-campo', 'volante'].sort(),
  );
  assert.strictEqual(primaryPosition(positions, 'person_dieguinho', 'club_goias').positionCode, 'meio-campo');
});
test('trocar a posição primária não apaga as secundárias', () => {
  let positions = [];
  positions = addPosition(positions, 'p1', 'c1', 'volante', { isPrimary: true });
  positions = addPosition(positions, 'p1', 'c1', 'lateral-direito', { isPrimary: true });
  assert.strictEqual(primaryPosition(positions, 'p1', 'c1').positionCode, 'lateral-direito');
  assert.strictEqual(allPositions(positions, 'p1', 'c1').length, 2);
});

console.log('\n7) Danilo/Nicolas/Michael: sem colisão errada no dataset canônico real');
test('canonical_people_candidates.json tem Danilo/Nicolas/Michael como pares SEPARADOS', () => {
  const people = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
  for (const pairNames of [
    ['Danilo Cunha da Silva', 'Danilo Gabriel de Andrade'],
    ['Nicolas Vichiatto da Silva', 'Nicolas Godinho Johann'],
    ['Michael Richard Delgado de Oliveira', 'Michael (1999, elenco do acesso à Série A)'],
  ]) {
    const entries = pairNames.map((n) => people.find((p) => p.canonicalName === n));
    assert.ok(entries[0], `não achou "${pairNames[0]}"`);
    assert.ok(entries[1], `não achou "${pairNames[1]}"`);
    assert.notStrictEqual(entries[0].canonicalId, entries[1].canonicalId, `${pairNames[0]} e ${pairNames[1]} têm o MESMO canonicalId — colisão!`);
    // Mesma fonte:sourceId pode aparecer nos dois lados SÓ quando cada lado
    // tem um matchIdFilter distinto e disjunto (ex.: lineup_matches:nicolas
    // dividido por data entre as 2 pessoas) — isso não é colisão, é
    // exatamente o sub-agrupamento que o override pediu. Colisão real só se
    // o mesmo par (source:sourceId) aparecer nos dois lados SEM filtro, ou
    // com filtros que se sobrepõem.
    for (const ma of entries[0].members) {
      for (const mb of entries[1].members) {
        if (ma.source !== mb.source || ma.sourceId !== mb.sourceId) continue;
        if (!ma.matchIdFilter || !mb.matchIdFilter) {
          throw new Error(`${ma.source}:${ma.sourceId} aparece nos dois lados de "${pairNames[0]}" vs "${pairNames[1]}" sem matchIdFilter pra distinguir — colisão real.`);
        }
        const overlap = ma.matchIdFilter.filter((id) => mb.matchIdFilter.includes(id));
        assert.strictEqual(overlap.length, 0, `${ma.source}:${ma.sourceId} tem partidas em COMUM entre os dois lados: ${overlap.join(', ')}`);
      }
    }
  }
});
test('nenhum DISTINCT_PEOPLE sobra sem resolver no dataset canônico', () => {
  const stats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_stats.json'), 'utf8'));
  assert.strictEqual(stats.byIdentity.DISTINCT_PEOPLE_UNRESOLVED, 0);
});

console.log('\n8) Precisão temporal — extra, sanity check do §8 do pedido');
test('YEAR só aceita ano, MONTH exige ano+mês, DAY exige os 3', () => {
  assert.deepStrictEqual(temporalValue('YEAR', { year: 2004 }), { precision: 'YEAR', year: 2004, month: null, day: null });
  assert.deepStrictEqual(temporalValue('MONTH', { year: 2004, month: 5 }), { precision: 'MONTH', year: 2004, month: 5, day: null });
  assert.deepStrictEqual(temporalValue('DAY', { year: 2004, month: 5, day: 12 }), { precision: 'DAY', year: 2004, month: 5, day: 12 });
  assert.throws(() => temporalValue('MONTH', { year: 2004 }));
  assert.throws(() => temporalValue('DAY', { year: 2004, month: 5 }));
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length > 0) {
  console.log('\nFALHAS:');
  for (const f of failures) console.log(` - ${f.name}: ${f.err.message}`);
  process.exit(1);
}

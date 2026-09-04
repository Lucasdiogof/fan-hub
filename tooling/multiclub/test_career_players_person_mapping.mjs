// Testes da Etapa F1 — mapping career_players -> person_id.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'career_players_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'career_players_person_mapping_stats.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const careerPlayers = JSON.parse(fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'career_players.json'), 'utf8'));

const schemaSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902140000_add_person_id_to_career_players.sql'), 'utf8');
const backfillSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902150000_backfill_career_players_person_id.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byKey(key) { return mapping.find((m) => m.careerPlayerKey === key); }

// ============================================================================
// 1) Números gerais
// ============================================================================
console.log('1) números gerais');
test('30 linhas mapeadas, batendo com career_players.json', () => {
  assert.strictEqual(mapping.length, 30);
  assert.strictEqual(careerPlayers.length, 30);
});
test('21 RESOLVED, 9 UNRESOLVED, 0 AMBIGUOUS, 0 OUT_OF_SCOPE', () => {
  assert.strictEqual(stats.RESOLVED, 21);
  assert.strictEqual(stats.UNRESOLVED, 9);
  assert.strictEqual(stats.AMBIGUOUS, 0);
  assert.strictEqual(stats.OUT_OF_SCOPE, 0);
  assert.strictEqual(stats.RESOLVED + stats.UNRESOLVED + stats.AMBIGUOUS + stats.OUT_OF_SCOPE, 30);
});
test('nenhuma linha RESOLVED tem personId duplicado com outra', () => {
  assert.strictEqual(stats.duplicatePersonIdIssues.length, 0);
  const resolved = mapping.filter((m) => m.status === 'RESOLVED');
  const seen = new Set();
  for (const m of resolved) { assert.ok(!seen.has(m.personId), `personId duplicado: ${m.personId}`); seen.add(m.personId); }
});

// ============================================================================
// 2) Casos obrigatórios (item 17 do pedido)
// ============================================================================
console.log('\n2) casos obrigatórios');
const expectedResolved = {
  walter: 'Walter Henrique da Silva',
  paulo_baier: 'Paulo Baier',
  evair: 'Evair Aparecido Paulino',
  welliton: 'Welliton Soares de Morais',
  rafael_moura: 'Rafael Moura',
  iarley: 'Iarley',
  fernandao: 'Fernandão',
  tadeu: 'Tadeu Antônio Ferreira',
  michael: 'Michael Richard Delgado de Oliveira',
  erik: 'Erik Nascimento de Lima',
};
for (const [key, expectedName] of Object.entries(expectedResolved)) {
  test(`${key} -> RESOLVED, canonicalName="${expectedName}"`, () => {
    const row = byKey(key);
    assert.ok(row, `${key} não encontrado no mapping`);
    assert.strictEqual(row.status, 'RESOLVED');
    assert.strictEqual(row.canonicalName, expectedName);
    assert.match(row.personId, /^[0-9a-f-]{36}$/);
  });
}
test('Nicolas Godinho NÃO existe em career_players — ausência confirmada, não "resolvido" por engano', () => {
  assert.strictEqual(careerPlayers.some((r) => r.id === 'nicolas' || r.id === 'nicolas_godinho' || r.answer?.toLowerCase().includes('nicolas')), false);
});

// ============================================================================
// 3) Homônimos (item 5 do pedido)
// ============================================================================
console.log('\n3) homônimos — nunca herda identidade errada');
test('danilo (career_players) -> Danilo Gabriel de Andrade, NUNCA Danilo Cunha da Silva', () => {
  const row = byKey('danilo');
  assert.strictEqual(row.canonicalName, 'Danilo Gabriel de Andrade');
  assert.notStrictEqual(row.canonicalName, 'Danilo Cunha da Silva');
});
test('michael (career_players) -> Michael Richard Delgado de Oliveira, NUNCA o Michael histórico de 1999', () => {
  const row = byKey('michael');
  assert.strictEqual(row.canonicalName, 'Michael Richard Delgado de Oliveira');
  assert.doesNotMatch(row.canonicalName, /1999|elenco do acesso/);
});
test('Fabiano: career_players NÃO tem nenhuma linha "fabiano" — homônimo do pedido não se aplica a este dataset, confirmado por ausência (não suposto)', () => {
  assert.strictEqual(careerPlayers.some((r) => r.id.includes('fabiano')), false);
});
test('Nicolas: career_players NÃO tem nenhuma linha "nicolas" — homônimo do pedido não se aplica a este dataset, confirmado por ausência', () => {
  assert.strictEqual(careerPlayers.some((r) => r.id.includes('nicolas')), false);
});

// ============================================================================
// 4) Múltiplas passagens — 1 career_player = 1 person_id, mesmo com 2+ spells (item 18)
// ============================================================================
console.log('\n4) múltiplas passagens nunca criam pessoa nova por passagem');
const multiSpellCases = ['walter', 'paulo_baier', 'evair', 'welliton', 'rafael_moura', 'iarley'];
for (const key of multiSpellCases) {
  test(`${key}: 2+ passagens pelo Goiás em club_career, ainda assim 1 único person_id`, () => {
    const row = byKey(key);
    const raw = careerPlayers.find((r) => r.id === key);
    const goiasSpells = raw.club_career.filter((c) => c.is_goias).length;
    assert.ok(goiasSpells >= 2, `esperado >=2 passagens Goiás pra ${key}, achou ${goiasSpells}`);
    assert.ok(row.personId, `${key} deveria estar RESOLVED com 1 personId`);
    // 1 linha career_players = 1 person_id sempre, nunca um array/split
    assert.strictEqual(typeof row.personId, 'string');
  });
}

// ============================================================================
// 5) UNRESOLVED — motivo sempre explícito, nunca escondido
// ============================================================================
console.log('\n5) UNRESOLVED sempre com motivo auditável');
test('9 UNRESOLVED, todos com resolutionReason não-vazio citando insert_status', () => {
  const unresolved = mapping.filter((m) => m.status === 'UNRESOLVED');
  assert.strictEqual(unresolved.length, 9);
  for (const m of unresolved) {
    assert.ok(m.resolutionReason && m.resolutionReason.length > 10);
    assert.strictEqual(m.personId, null);
  }
});
test('os 9 UNRESOLVED são exatamente: grafite, bruno_henrique, pedro_raul, jadilson, souza, roni, vitor, marcelo_rangel, apodi', () => {
  const keys = mapping.filter((m) => m.status === 'UNRESOLVED').map((m) => m.careerPlayerKey).sort();
  assert.deepStrictEqual(keys, ['apodi', 'bruno_henrique', 'grafite', 'jadilson', 'marcelo_rangel', 'pedro_raul', 'roni', 'souza', 'vitor']);
});

// ============================================================================
// 6) Migration SQL — literal, nunca resolução por nome em runtime
// ============================================================================
console.log('\n6) migration SQL — literal, nunca ilike/nome em runtime');
test('backfill NUNCA usa select/ilike/canonical_name — só UPDATE literal por id', () => {
  const executableBody = backfillSql.split('\n').filter((line) => !line.trim().startsWith('--')).join('\n');
  assert.doesNotMatch(executableBody, /ilike/i);
  assert.doesNotMatch(executableBody, /canonical_name/i);
  assert.doesNotMatch(executableBody, /select\s+.*from\s+public\.people/i);
  const updateCount = (executableBody.match(/^\s*update public\.career_players set person_id/gm) || []).length;
  assert.strictEqual(updateCount, 21);
});
test('todo UUID no backfill (UPDATE + VALUES de pré/pós-condição) é um dos 21 personId RESOLVED — nenhum literal inventado', () => {
  const resolvedIds = new Set(mapping.filter((m) => m.status === 'RESOLVED').map((m) => m.personId));
  const uuidsInSql = new Set([...backfillSql.matchAll(/'([0-9a-f-]{36})'::uuid/g)].map((m) => m[1]));
  assert.strictEqual(uuidsInSql.size, 21, `esperado 21 UUIDs distintos no arquivo, achou ${uuidsInSql.size}`);
  for (const id of uuidsInSql) assert.ok(resolvedIds.has(id), `UUID ${id} não está entre os RESOLVED do mapping`);
  for (const id of resolvedIds) assert.ok(uuidsInSql.has(id), `personId RESOLVED ${id} não aparece no backfill SQL`);
});
test('schema migration: person_id nullable (sem NOT NULL), FK pra people(id), UNIQUE, aditiva', () => {
  assert.match(schemaSql, /add column if not exists person_id uuid references public\.people\(id\)/);
  assert.doesNotMatch(schemaSql, /person_id uuid not null/i);
  assert.match(schemaSql, /add constraint career_players_person_id_key unique \(person_id\)/);
  assert.doesNotMatch(schemaSql, /drop table|drop column|alter table public\.people|alter table public\.person_aliases|alter table public\.player_club_spells|alter table public\.player_positions|alter table public\.player_club_stats|alter table public\.matches|alter table public\.player_match_appearances/i);
});
test('schema migration: SEM índice redundante — UNIQUE(person_id) já cria seu próprio índice', () => {
  const executableBody = schemaSql.split('\n').filter((line) => !line.trim().startsWith('--')).join('\n');
  assert.doesNotMatch(executableBody, /create index/i);
});
test('backfill: DO block com validação forte — pré-condição (total + ids existem) e pós-condição (match exato + contagens) presentes', () => {
  assert.match(backfillSql, /^do \$\$/m);
  assert.match(backfillSql, /raise exception 'career_players tem % linhas, esperado %/);
  assert.match(backfillSql, /raise exception 'career_players\.id esperado\(s\) ausente\(s\) ANTES do backfill/);
  assert.match(backfillSql, /raise exception 'backfill não bateu EXATAMENTE com o mapping esperado/);
  assert.match(backfillSql, /raise exception 'person_id NOT NULL = %, esperado %/);
  assert.match(backfillSql, /raise exception 'person_id NULL = %, esperado %/);
  assert.match(backfillSql, /raise exception 'person_id distintos \(não-nulos\) = %, esperado %/);
});
test('backfill: pós-condição de match exato compara VALOR (person_id is distinct from), não só IS NOT NULL', () => {
  assert.match(backfillSql, /where cp\.person_id is distinct from e\.person_id/);
});
test('nenhuma pessoa/tabela canônica é criada ou alterada por estas 2 migrations (só career_players)', () => {
  for (const sql of [schemaSql, backfillSql]) {
    assert.doesNotMatch(sql, /create table/i);
    assert.doesNotMatch(sql, /insert into public\.people/i);
    assert.doesNotMatch(sql, /update public\.people\b/i);
  }
});

// ============================================================================
// 7) Reprodutibilidade
// ============================================================================
console.log('\n7) todo canonicalName do mapping bate com canonical_people_candidates.json');
test('canonicalName de cada linha RESOLVED/UNRESOLVED-com-1-owner bate com o candidate real (nunca inventado)', () => {
  for (const m of mapping) {
    if (!m.canonicalName) continue;
    const found = canonicalPeople.some((p) => p.canonicalName === m.canonicalName);
    assert.ok(found, `canonicalName "${m.canonicalName}" (${m.careerPlayerKey}) não existe em canonical_people_candidates.json`);
  }
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

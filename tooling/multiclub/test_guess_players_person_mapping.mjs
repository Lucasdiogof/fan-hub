// Testes da Etapa F3 — mapping guess_players -> person_id.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'guess_players_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'guess_players_person_mapping_stats.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const guessPlayers = JSON.parse(fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'guess_players.json'), 'utf8'));

const schemaSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902160000_add_person_id_to_guess_players.sql'), 'utf8');
const backfillSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902170000_backfill_guess_players_person_id.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byKey(key) { return mapping.find((m) => m.guessPlayerId === key); }

// ============================================================================
// 1) Números gerais
// ============================================================================
console.log('1) números gerais');
test('173 linhas mapeadas, batendo com guess_players.json', () => {
  assert.strictEqual(mapping.length, 173);
  assert.strictEqual(guessPlayers.length, 173);
});
test('92 RESOLVED, 81 UNRESOLVED, 0 AMBIGUOUS, 0 OUT_OF_SCOPE', () => {
  assert.strictEqual(stats.RESOLVED, 92);
  assert.strictEqual(stats.UNRESOLVED, 81);
  assert.strictEqual(stats.AMBIGUOUS, 0);
  assert.strictEqual(stats.OUT_OF_SCOPE, 0);
  assert.strictEqual(stats.RESOLVED + stats.UNRESOLVED + stats.AMBIGUOUS + stats.OUT_OF_SCOPE, 173);
});
test('todo status é um dos 4 valores válidos — RESOLVED tem personId, os outros 3 nunca têm', () => {
  const valid = new Set(['RESOLVED', 'AMBIGUOUS', 'UNRESOLVED', 'OUT_OF_SCOPE']);
  for (const m of mapping) {
    assert.ok(valid.has(m.status), `status inválido: ${m.status}`);
    if (m.status === 'RESOLVED') assert.match(m.personId, /^[0-9a-f-]{36}$/);
    else assert.strictEqual(m.personId, null);
  }
});

// ============================================================================
// 2) Cardinalidade — auditada, não suposta (item 10 do pedido)
// ============================================================================
console.log('\n2) cardinalidade pessoa <-> guess_player');
test('nenhum person_id é reusado por 2+ linhas RESOLVED (1 guess_player = 1 pessoa, hoje)', () => {
  assert.strictEqual(stats.personIdReusedAcrossRows.length, 0);
  const resolved = mapping.filter((m) => m.status === 'RESOLVED');
  const seen = new Set();
  for (const m of resolved) { assert.ok(!seen.has(m.personId), `personId duplicado: ${m.personId}`); seen.add(m.personId); }
  assert.strictEqual(seen.size, stats.distinctPersonIdsAmongResolved);
});
test('nenhuma pessoa canônica tem 2+ members source=guess_players (checagem reversa)', () => {
  for (const p of canonicalPeople) {
    const guessMembers = p.members.filter((m) => m.source === 'guess_players');
    assert.ok(guessMembers.length <= 1, `${p.canonicalName} tem ${guessMembers.length} members guess_players`);
  }
});
test('173 display_name distintos em guess_players.json (0 duplicata) — suporta a premissa de 1 linha = 1 pessoa por desenho da feature', () => {
  const names = guessPlayers.map((r) => r.display_name);
  assert.strictEqual(new Set(names).size, names.length);
});

// ============================================================================
// 3) Casos sensíveis / homônimos (item 6 do pedido)
// ============================================================================
console.log('\n3) homônimos e casos sensíveis');
const expectedResolved = {
  michael: 'Michael Richard Delgado de Oliveira',
  danilo_cunha_da_silva: 'Danilo Cunha da Silva',
  nicolas_vichiatto_da_silva: 'Nicolas Vichiatto da Silva',
  fabiano: 'Fabiano Cézar Viegas',
  walter: 'Walter Henrique da Silva',
  tadeu_antonio_ferreira: 'Tadeu Antônio Ferreira',
  harlei: 'Harlei',
};
for (const [key, expectedName] of Object.entries(expectedResolved)) {
  test(`${key} -> RESOLVED, canonicalName="${expectedName}"`, () => {
    const row = byKey(key);
    assert.ok(row, `${key} não encontrado no mapping`);
    assert.strictEqual(row.status, 'RESOLVED');
    assert.strictEqual(row.canonicalName, expectedName);
  });
}
test('danilo_portugal é uma 3ª pessoa "Danilo" DIFERENTE de Gabriel/Cunha — UNRESOLVED, nunca herda person_id de nenhum dos outros dois', () => {
  const row = byKey('danilo_portugal');
  assert.ok(row);
  assert.strictEqual(row.status, 'UNRESOLVED');
  assert.strictEqual(row.personId, null);
  assert.notStrictEqual(row.canonicalName, 'Danilo Gabriel de Andrade');
  assert.notStrictEqual(row.canonicalName, 'Danilo Cunha da Silva');
});
test('danilo_cunha_da_silva e (futuro) danilo_gabriel nunca compartilham person_id — Danilo Cunha != Danilo Gabriel', () => {
  const cunha = byKey('danilo_cunha_da_silva');
  const gabrielPersonId = 'c628f9d8-6719-5506-acbd-adfb683fcf9b'; // mesmo UUID confirmado na F1/Etapa E
  assert.notStrictEqual(cunha.personId, gabrielPersonId);
});
test('nicolas_vichiatto_da_silva não vaza pro Nicolas Godinho, que nem existe em guess_players (ausência confirmada)', () => {
  assert.strictEqual(guessPlayers.some((r) => r.id.includes('godinho')), false);
  const row = byKey('nicolas_vichiatto_da_silva');
  assert.notStrictEqual(row.canonicalName, 'Nicolas Godinho Johann');
});
test('marcelo_rangel e apodi permanecem UNRESOLVED em guess_players — mesma ambiguidade cross-source da F1, nunca resolvida por engano aqui', () => {
  assert.strictEqual(byKey('marcelo_rangel').status, 'UNRESOLVED');
  assert.strictEqual(byKey('apodi').status, 'UNRESOLVED');
});
test('"dill" não existe em guess_players — ausência confirmada, não suposta', () => {
  assert.strictEqual(guessPlayers.some((r) => r.id === 'dill'), false);
});

// ============================================================================
// 4) UNRESOLVED sempre com motivo auditável
// ============================================================================
console.log('\n4) UNRESOLVED sempre com motivo auditável');
test('81 UNRESOLVED, todos com resolutionReason não-vazio', () => {
  const unresolved = mapping.filter((m) => m.status === 'UNRESOLVED');
  assert.strictEqual(unresolved.length, 81);
  for (const m of unresolved) assert.ok(m.resolutionReason && m.resolutionReason.length > 10);
});

// ============================================================================
// 5) Migration SQL — literal, nunca resolução por nome em runtime
// ============================================================================
console.log('\n5) migration SQL — literal, nunca ilike/nome em runtime');
test('backfill NUNCA usa select/ilike/display_name/aliases pra resolver — só UPDATE literal por id', () => {
  const executableBody = backfillSql.split('\n').filter((line) => !line.trim().startsWith('--')).join('\n');
  assert.doesNotMatch(executableBody, /ilike/i);
  assert.doesNotMatch(executableBody, /\bdisplay_name\b/i);
  assert.doesNotMatch(executableBody, /\baliases\b/i);
  assert.doesNotMatch(executableBody, /select\s+.*from\s+public\.people/i);
  const updateCount = (executableBody.match(/^\s*update public\.guess_players set person_id/gm) || []).length;
  assert.strictEqual(updateCount, 92);
});
test('todo UUID no backfill é um dos 92 personId RESOLVED — nenhum literal inventado', () => {
  const resolvedIds = new Set(mapping.filter((m) => m.status === 'RESOLVED').map((m) => m.personId));
  const uuidsInSql = new Set([...backfillSql.matchAll(/'([0-9a-f-]{36})'::uuid/g)].map((m) => m[1]));
  assert.strictEqual(uuidsInSql.size, 92);
  for (const id of uuidsInSql) assert.ok(resolvedIds.has(id), `UUID ${id} não está entre os RESOLVED do mapping`);
  for (const id of resolvedIds) assert.ok(uuidsInSql.has(id), `personId RESOLVED ${id} não aparece no backfill SQL`);
});
test('backfill: DO block com validação forte — pré-condição e pós-condição presentes (mesma disciplina da F1)', () => {
  assert.match(backfillSql, /^do \$\$/m);
  assert.match(backfillSql, /raise exception 'guess_players tem % linhas, esperado %/);
  assert.match(backfillSql, /raise exception 'guess_players\.id esperado\(s\) ausente\(s\) ANTES do backfill/);
  assert.match(backfillSql, /raise exception 'backfill não bateu EXATAMENTE com o mapping esperado/);
  assert.match(backfillSql, /raise exception 'person_id NOT NULL = %, esperado %/);
  assert.match(backfillSql, /raise exception 'person_id NULL = %, esperado %/);
  assert.match(backfillSql, /raise exception 'person_id distintos \(não-nulos\) = %, esperado %/);
  assert.match(backfillSql, /where gp\.person_id is distinct from e\.person_id/);
});
test('backfill: PRÉ 3 nova — person_id tem que estar 100% vazio ANTES do backfill, nunca sobrescreve silenciosamente', () => {
  assert.match(backfillSql, /select count\(\*\) into v_prefilled_before from public\.guess_players where person_id is not null/);
  assert.match(backfillSql, /raise exception 'guess_players\.person_id já tem % linha\(s\) preenchida\(s\) ANTES do backfill/);
  // a checagem PRÉ 3 acontece ANTES dos UPDATEs no arquivo (ordem importa)
  const preIdx = backfillSql.indexOf('v_prefilled_before from public.guess_players');
  const firstUpdateIdx = backfillSql.indexOf('update public.guess_players set person_id =');
  assert.ok(preIdx > 0 && firstUpdateIdx > 0 && preIdx < firstUpdateIdx, 'PRÉ 3 precisa vir ANTES do primeiro UPDATE');
});
test('schema migration: person_id nullable, FK pra people(id), UNIQUE, SEM índice redundante, aditiva', () => {
  assert.match(schemaSql, /add column if not exists person_id uuid references public\.people\(id\)/);
  assert.doesNotMatch(schemaSql, /person_id uuid not null/i);
  assert.match(schemaSql, /add constraint guess_players_person_id_key unique \(person_id\)/);
  const executableBody = schemaSql.split('\n').filter((line) => !line.trim().startsWith('--')).join('\n');
  assert.doesNotMatch(executableBody, /create index/i);
  assert.doesNotMatch(schemaSql, /drop table|drop column|alter table public\.people|alter table public\.person_aliases|alter table public\.player_club_spells|alter table public\.player_positions|alter table public\.player_club_stats|alter table public\.matches|alter table public\.player_match_appearances|alter table public\.career_players/i);
});
test('nenhuma pessoa/tabela canônica (nem career_players da F1) é criada ou alterada por estas 2 migrations — só guess_players', () => {
  for (const sql of [schemaSql, backfillSql]) {
    assert.doesNotMatch(sql, /create table/i);
    assert.doesNotMatch(sql, /insert into public\.people/i);
    assert.doesNotMatch(sql, /update public\.people\b/i);
  }
});

// ============================================================================
// 6) canonicalName sempre real, nunca inventado
// ============================================================================
console.log('\n6) canonicalName sempre bate com canonical_people_candidates.json');
test('todo canonicalName do mapping existe em canonical_people_candidates.json', () => {
  for (const m of mapping) {
    if (!m.canonicalName) continue;
    assert.ok(canonicalPeople.some((p) => p.canonicalName === m.canonicalName), `canonicalName "${m.canonicalName}" (${m.guessPlayerId}) não existe em canonical_people_candidates.json`);
  }
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

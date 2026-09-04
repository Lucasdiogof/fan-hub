// Testes da Etapa F4 — mapping squad_members -> person_id.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'squad_members_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'squad_members_person_mapping_stats.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const squadMembers = JSON.parse(fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'squad_members.json'), 'utf8'));

const schemaSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902180000_add_person_id_to_squad_members.sql'), 'utf8');
const backfillSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902190000_backfill_squad_members_person_id.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byKey(key) { return mapping.find((m) => m.squadMemberId === key); }

// ============================================================================
// 1) Números gerais
// ============================================================================
console.log('1) números gerais');
test('31 linhas mapeadas, batendo com squad_members.json', () => {
  assert.strictEqual(mapping.length, 31);
  assert.strictEqual(squadMembers.length, 31);
});
test('31 RESOLVED, 0 AMBIGUOUS, 0 UNRESOLVED, 0 OUT_OF_SCOPE — elenco atual 100% já aprovado', () => {
  assert.strictEqual(stats.RESOLVED, 31);
  assert.strictEqual(stats.AMBIGUOUS, 0);
  assert.strictEqual(stats.UNRESOLVED, 0);
  assert.strictEqual(stats.OUT_OF_SCOPE, 0);
});
test('todo status é um dos 4 valores válidos — RESOLVED tem personId, os outros nunca têm', () => {
  const valid = new Set(['RESOLVED', 'AMBIGUOUS', 'UNRESOLVED', 'OUT_OF_SCOPE']);
  for (const m of mapping) {
    assert.ok(valid.has(m.status), `status inválido: ${m.status}`);
    if (m.status === 'RESOLVED') assert.match(m.personId, /^[0-9a-f-]{36}$/);
    else assert.strictEqual(m.personId, null);
  }
});

// ============================================================================
// 2) Cardinalidade — auditada nos 2 sentidos (item 7 do pedido)
// ============================================================================
console.log('\n2) cardinalidade pessoa <-> squad_member');
test('nenhum person_id é reusado por 2+ linhas RESOLVED', () => {
  assert.strictEqual(stats.personIdReusedAcrossRows.length, 0);
  const resolved = mapping.filter((m) => m.status === 'RESOLVED');
  const seen = new Set();
  for (const m of resolved) { assert.ok(!seen.has(m.personId), `personId duplicado: ${m.personId}`); seen.add(m.personId); }
  assert.strictEqual(seen.size, 31);
});
test('nenhuma pessoa canônica tem 2+ members source=squad_members (checagem reversa)', () => {
  assert.strictEqual(stats.reverseMultiMembership.length, 0);
  for (const p of canonicalPeople) {
    const smMembers = p.members.filter((m) => m.source === 'squad_members');
    assert.ok(smMembers.length <= 1, `${p.canonicalName} tem ${smMembers.length} members squad_members`);
  }
});
test('31 nomes completos distintos em squad_members.json (0 duplicata) — elenco atual, 1 linha por atleta', () => {
  const names = squadMembers.map((r) => r.full_name || r.name);
  assert.strictEqual(new Set(names).size, names.length);
});

// ============================================================================
// 3) Casos sensíveis / homônimos (item 6 do pedido)
// ============================================================================
console.log('\n3) homônimos e casos sensíveis');
const expectedResolved = {
  tadeu: 'Tadeu Antônio Ferreira',
  nicolas: 'Nicolas Vichiatto da Silva',
  danilo: 'Danilo Cunha da Silva',
  djalma: 'Djalma Antônio da Silva Filho',
  rodrigo_soares: 'Rodrigo Alves Soares',
  lourenco: 'João Paulo Ferreira Lourenço',
  lucas_rodrigues: 'Lucas Rodrigues Moreira Costa',
  luiz_felipe: 'Luiz Felipe do Nascimento dos Santos',
  murilo_camara: 'Murilo Camara Saquetti Chimelo Pereira',
  murillo_victorio: 'Murillo Carvalho Victorio',
};
for (const [key, expectedName] of Object.entries(expectedResolved)) {
  test(`${key} -> RESOLVED, canonicalName="${expectedName}"`, () => {
    const row = byKey(key);
    assert.ok(row, `${key} não encontrado no mapping`);
    assert.strictEqual(row.status, 'RESOLVED');
    assert.strictEqual(row.canonicalName, expectedName);
  });
}
test('nicolas (squad_members) NUNCA resolve pra Nicolas Godinho Johann', () => {
  assert.notStrictEqual(byKey('nicolas').canonicalName, 'Nicolas Godinho Johann');
});
test('danilo (squad_members) NUNCA resolve pra Danilo Gabriel de Andrade', () => {
  assert.notStrictEqual(byKey('danilo').canonicalName, 'Danilo Gabriel de Andrade');
});
test('murilo_camara e murillo_victorio são pessoas DIFERENTES — normalização ortográfica nunca os mistura', () => {
  const camara = byKey('murilo_camara');
  const victorio = byKey('murillo_victorio');
  assert.notStrictEqual(camara.personId, victorio.personId);
  assert.notStrictEqual(camara.canonicalName, victorio.canonicalName);
});
test('"Dieguinho" (Jackson Diego Ibraim Fagundes) NÃO está no elenco atual — confirmado por ausência, não suposto', () => {
  assert.strictEqual(squadMembers.some((r) => (r.full_name || r.name || '').toLowerCase().includes('diego') || r.id.includes('dieg')), false);
});

// ============================================================================
// 4) Migration SQL — literal, nunca resolução por nome em runtime
// ============================================================================
console.log('\n4) migration SQL — literal, nunca ilike/nome em runtime');
test('backfill NUNCA usa select/ilike/name/full_name pra resolver — só UPDATE literal por id', () => {
  const executableBody = backfillSql.split('\n').filter((line) => !line.trim().startsWith('--')).join('\n');
  assert.doesNotMatch(executableBody, /ilike/i);
  assert.doesNotMatch(executableBody, /\bfull_name\b/i);
  assert.doesNotMatch(executableBody, /select\s+.*from\s+public\.people/i);
  const updateCount = (executableBody.match(/^\s*update public\.squad_members set person_id/gm) || []).length;
  assert.strictEqual(updateCount, 31);
});
test('todo UUID no backfill é um dos 31 personId RESOLVED — nenhum literal inventado', () => {
  const resolvedIds = new Set(mapping.filter((m) => m.status === 'RESOLVED').map((m) => m.personId));
  const uuidsInSql = new Set([...backfillSql.matchAll(/'([0-9a-f-]{36})'::uuid/g)].map((m) => m[1]));
  assert.strictEqual(uuidsInSql.size, 31);
  for (const id of uuidsInSql) assert.ok(resolvedIds.has(id), `UUID ${id} não está entre os RESOLVED do mapping`);
  for (const id of resolvedIds) assert.ok(uuidsInSql.has(id), `personId RESOLVED ${id} não aparece no backfill SQL`);
});
test('backfill: 3 PRÉ-condições (total, ids existem, person_id vazio) + PÓS-condição presentes desde o início (endurecimento de F1+F3 aplicado)', () => {
  assert.match(backfillSql, /^do \$\$/m);
  assert.match(backfillSql, /raise exception 'squad_members tem % linhas, esperado %/);
  assert.match(backfillSql, /raise exception 'squad_members\.id esperado\(s\) ausente\(s\) ANTES do backfill/);
  assert.match(backfillSql, /select count\(\*\) into v_prefilled_before from public\.squad_members where person_id is not null/);
  assert.match(backfillSql, /raise exception 'squad_members\.person_id já tem % linha\(s\) preenchida\(s\) ANTES do backfill/);
  assert.match(backfillSql, /raise exception 'backfill não bateu EXATAMENTE com o mapping esperado/);
  assert.match(backfillSql, /raise exception 'person_id NOT NULL = %, esperado %/);
  assert.match(backfillSql, /raise exception 'person_id NULL = %, esperado %/);
  assert.match(backfillSql, /raise exception 'person_id distintos \(não-nulos\) = %, esperado %/);
  assert.match(backfillSql, /where sm\.person_id is distinct from e\.person_id/);
  // PRÉ 3 precisa vir ANTES do primeiro UPDATE
  const preIdx = backfillSql.indexOf('v_prefilled_before from public.squad_members');
  const firstUpdateIdx = backfillSql.indexOf('update public.squad_members set person_id =');
  assert.ok(preIdx > 0 && firstUpdateIdx > 0 && preIdx < firstUpdateIdx);
});
test('schema migration: person_id NULLABLE mesmo com 31/31 RESOLVED (nunca NOT NULL automático), FK, UNIQUE, SEM índice redundante', () => {
  assert.match(schemaSql, /add column if not exists person_id uuid references public\.people\(id\)/);
  assert.doesNotMatch(schemaSql, /person_id uuid not null/i);
  assert.match(schemaSql, /add constraint squad_members_person_id_key unique \(person_id\)/);
  const executableBody = schemaSql.split('\n').filter((line) => !line.trim().startsWith('--')).join('\n');
  assert.doesNotMatch(executableBody, /create index/i);
  assert.doesNotMatch(schemaSql, /drop table|drop column|alter table public\.people|alter table public\.person_aliases|alter table public\.player_club_spells|alter table public\.player_positions|alter table public\.player_club_stats|alter table public\.matches|alter table public\.player_match_appearances|alter table public\.career_players|alter table public\.guess_players/i);
});
test('nenhuma outra tabela canônica (nem career_players/guess_players das etapas anteriores) é tocada — só squad_members', () => {
  for (const sql of [schemaSql, backfillSql]) {
    assert.doesNotMatch(sql, /create table/i);
    assert.doesNotMatch(sql, /insert into public\.people/i);
    assert.doesNotMatch(sql, /update public\.people\b/i);
  }
});

// ============================================================================
// 5) canonicalName sempre real, nunca inventado
// ============================================================================
console.log('\n5) canonicalName sempre bate com canonical_people_candidates.json');
test('todo canonicalName do mapping existe em canonical_people_candidates.json', () => {
  for (const m of mapping) {
    if (!m.canonicalName) continue;
    assert.ok(canonicalPeople.some((p) => p.canonicalName === m.canonicalName), `canonicalName "${m.canonicalName}" (${m.squadMemberId}) não existe em canonical_people_candidates.json`);
  }
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

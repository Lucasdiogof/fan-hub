// Testes do seed de person_aliases — rodam contra
// data_export/goias/player_reconciliation/person_aliases_seed.json (o
// dado real gerado, não um mock) simulando o lookup que a aplicação faria:
// agrupar por normalized_alias e contar quantos person_id distintos
// aparecem. 0 = não encontrado, 1 = resolução possível, 2+ = AMBIGUOUS.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { normalizeAlias } from './normalize_alias.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const aliasSeed = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'person_aliases_seed.json'), 'utf8'));
const aliasSourceSeed = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'person_alias_sources_seed.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
const registry = JSON.parse(fs.readFileSync(path.join(path.resolve(__dirname), 'people_registry.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

/** Simula o lookup que a aplicação faria contra person_aliases — 0/1/2+. */
function lookup(rawName) {
  const norm = normalizeAlias(rawName);
  const rows = aliasSeed.filter((a) => a.normalizedAlias === norm);
  const distinctPersonIds = [...new Set(rows.map((r) => r.personId))];
  if (distinctPersonIds.length === 0) return { status: 'NOT_FOUND', personIds: [] };
  if (distinctPersonIds.length === 1) return { status: 'RESOLVED', personIds: distinctPersonIds };
  return { status: 'AMBIGUOUS', personIds: distinctPersonIds };
}

function personByCanonicalName(name) {
  return canonicalPeople.find((p) => p.canonicalName === name);
}

console.log('1) Nicolas — AMBIGUOUS, 2 person_id');
test('lookup("Nicolas") -> AMBIGUOUS com exatamente [A, B]', () => {
  const r = lookup('Nicolas');
  assert.strictEqual(r.status, 'AMBIGUOUS');
  assert.strictEqual(r.personIds.length, 2);
  const a = personByCanonicalName('Nicolas Vichiatto da Silva');
  const b = personByCanonicalName('Nicolas Godinho Johann');
  assert.ok(r.personIds.includes(a.canonicalId));
  assert.ok(r.personIds.includes(b.canonicalId));
});

console.log('\n2) Danilo — AMBIGUOUS, 2 person_id');
test('lookup("Danilo") -> AMBIGUOUS com exatamente [A, B]', () => {
  const r = lookup('Danilo');
  assert.strictEqual(r.status, 'AMBIGUOUS');
  assert.strictEqual(r.personIds.length, 2);
  const a = personByCanonicalName('Danilo Cunha da Silva');
  const b = personByCanonicalName('Danilo Gabriel de Andrade');
  assert.ok(r.personIds.includes(a.canonicalId));
  assert.ok(r.personIds.includes(b.canonicalId));
});

console.log('\n3) Michael — NÃO ambíguo hoje (só 1 dos 2 Michaels está em people)');
test('lookup("Michael") -> RESOLVED, 1 person_id (o PROBABLE ainda não está nos 94 aprovados)', () => {
  const r = lookup('Michael');
  assert.strictEqual(r.status, 'RESOLVED');
  assert.strictEqual(r.personIds.length, 1);
  const exact = personByCanonicalName('Michael Richard Delgado de Oliveira');
  assert.strictEqual(r.personIds[0], exact.canonicalId);
});
test('o Michael PROBABLE (1999) NÃO tem nenhuma linha em person_aliases (não está em people)', () => {
  const probable = personByCanonicalName('Michael (1999, elenco do acesso à Série A)');
  const rows = aliasSeed.filter((a) => a.personId === probable.canonicalId);
  assert.strictEqual(rows.length, 0);
});
test('EVOLUÇÃO: quando o 2º Michael entrar em people, a MESMA função de lookup vira AMBIGUOUS sozinha — sem mudar código', () => {
  // Simula o dia em que o Michael PROBABLE for promovido e ganhar sua
  // própria linha em person_aliases (exatamente como as outras 94 têm
  // hoje) — nenhuma alteração na lógica de lookup, só dado novo.
  const probable = personByCanonicalName('Michael (1999, elenco do acesso à Série A)');
  const futureAliasSeed = [
    ...aliasSeed,
    { personId: probable.canonicalId, alias: 'Michael', normalizedAlias: 'michael', aliasType: 'DISPLAY_NAME', isPreferred: true },
  ];
  function lookupAgainst(seed, rawName) {
    const norm = normalizeAlias(rawName);
    const rows = seed.filter((a) => a.normalizedAlias === norm);
    const ids = [...new Set(rows.map((r) => r.personId))];
    return ids.length === 0 ? { status: 'NOT_FOUND', personIds: [] } : ids.length === 1 ? { status: 'RESOLVED', personIds: ids } : { status: 'AMBIGUOUS', personIds: ids };
  }
  const before = lookupAgainst(aliasSeed, 'Michael');
  const after = lookupAgainst(futureAliasSeed, 'Michael');
  assert.strictEqual(before.status, 'RESOLVED');
  assert.strictEqual(after.status, 'AMBIGUOUS');
  assert.strictEqual(after.personIds.length, 2);
});

console.log('\n4) Tadeu — mesma pessoa via os dois nomes');
test('lookup("Tadeu") e lookup("Tadeu Antônio Ferreira") resolvem pro MESMO person_id', () => {
  const r1 = lookup('Tadeu');
  const r2 = lookup('Tadeu Antônio Ferreira');
  assert.strictEqual(r1.status, 'RESOLVED');
  assert.strictEqual(r2.status, 'RESOLVED');
  assert.strictEqual(r1.personIds[0], r2.personIds[0]);
});

console.log('\n5) Walter — mesma pessoa via os dois nomes');
test('lookup("Walter") e lookup("Walter Henrique da Silva") resolvem pro MESMO person_id', () => {
  const r1 = lookup('Walter');
  const r2 = lookup('Walter Henrique da Silva');
  assert.strictEqual(r1.status, 'RESOLVED');
  assert.strictEqual(r2.status, 'RESOLVED');
  assert.strictEqual(r1.personIds[0], r2.personIds[0]);
});

console.log('\n6) Paulo Baier — mesma pessoa via os dois nomes');
test('lookup("Paulo Baier") e lookup("Paulo César Baier") resolvem pro MESMO person_id', () => {
  const r1 = lookup('Paulo Baier');
  const r2 = lookup('Paulo César Baier');
  assert.strictEqual(r1.status, 'RESOLVED');
  assert.strictEqual(r2.status, 'RESOLVED');
  assert.strictEqual(r1.personIds[0], r2.personIds[0]);
});

console.log('\n7) Fabiano — mesma pessoa via os dois nomes (está nos 94 aprovados)');
test('lookup("Fabiano") e lookup("Fabiano Cézar Viegas") resolvem pro MESMO person_id', () => {
  const r1 = lookup('Fabiano');
  const r2 = lookup('Fabiano Cézar Viegas');
  assert.strictEqual(r1.status, 'RESOLVED');
  assert.strictEqual(r2.status, 'RESOLVED');
  assert.strictEqual(r1.personIds[0], r2.personIds[0]);
});

console.log('\n8) unique(person_id, normalized_alias) nunca duplica a mesma pessoa');
test('nenhum par (personId, normalizedAlias) aparece 2x no seed', () => {
  const seen = new Set();
  for (const a of aliasSeed) {
    const key = `${a.personId}|${a.normalizedAlias}`;
    assert.ok(!seen.has(key), `duplicata: ${key}`);
    seen.add(key);
  }
});

console.log('\n9) NUNCA existe unique(normalized_alias) global — ambiguidade é esperada e preservada');
test('pelo menos 1 normalized_alias aponta pra 2+ person_id (prova que não há constraint global impedindo)', () => {
  const byNorm = new Map();
  for (const a of aliasSeed) {
    if (!byNorm.has(a.normalizedAlias)) byNorm.set(a.normalizedAlias, new Set());
    byNorm.get(a.normalizedAlias).add(a.personId);
  }
  const ambiguous = [...byNorm.values()].filter((s) => s.size > 1);
  assert.ok(ambiguous.length >= 2, `esperava pelo menos 2 aliases ambíguos (Danilo, Nicolas), achou ${ambiguous.length}`);
});

console.log('\n10) Todo person_id do seed é um dos 94 APPROVED (nenhum alias órfão)');
test('todo alias aponta pra um person_id existente no registry', () => {
  const registeredIds = new Set(registry.entries.map((e) => e.personId));
  for (const a of aliasSeed) assert.ok(registeredIds.has(a.personId), `person_id "${a.personId}" (alias "${a.alias}") não existe no registry`);
});

console.log('\n11) Toda linha de person_alias_sources referencia um alias real do seed');
test('nenhum aliasIndex fora do array', () => {
  for (const s of aliasSourceSeed) assert.ok(s.aliasIndex >= 0 && s.aliasIndex < aliasSeed.length, `aliasIndex inválido: ${s.aliasIndex}`);
});

console.log('\n12) Normalização — acentuação/caixa não quebra equivalência, mas não funde nomes diferentes');
test('"Rafael Tolói" / "rafael toloi" / "RAFAEL TOLÓI" normalizam igual', () => {
  const n1 = normalizeAlias('Rafael Tolói');
  const n2 = normalizeAlias('rafael toloi');
  const n3 = normalizeAlias('RAFAEL TOLÓI');
  assert.strictEqual(n1, n2);
  assert.strictEqual(n2, n3);
});
test('nomes genuinamente diferentes NÃO normalizam igual', () => {
  assert.notStrictEqual(normalizeAlias('João Paulo'), normalizeAlias('Paulo João'));
  assert.notStrictEqual(normalizeAlias('Tadeu'), normalizeAlias('Walter'));
});
test("apóstrofo/hífen viram separador, não somem colando palavras", () => {
  assert.strictEqual(normalizeAlias("D'Angelo"), 'd angelo');
  assert.strictEqual(normalizeAlias('Jean-Pierre'), 'jean pierre');
});

console.log('\n13) is_preferred: no máximo 1 linha marcada por pessoa');
test('nenhuma pessoa tem 2+ linhas is_preferred=true', () => {
  const byPerson = new Map();
  for (const a of aliasSeed) {
    if (!a.isPreferred) continue;
    byPerson.set(a.personId, (byPerson.get(a.personId) || 0) + 1);
  }
  for (const [personId, count] of byPerson) assert.ok(count <= 1, `pessoa ${personId} tem ${count} linhas preferred`);
});

console.log('\n14) Normalização Unicode global — v2 (NFKD + \\p{M} + \\p{L}/\\p{N}), 9 casos obrigatórios');
test('"Rafael Tolói" -> "rafael toloi"', () => {
  assert.strictEqual(normalizeAlias('Rafael Tolói'), 'rafael toloi');
});
test('"RAFAEL TOLÓI" -> "rafael toloi"', () => {
  assert.strictEqual(normalizeAlias('RAFAEL TOLÓI'), 'rafael toloi');
});
test('"João-Paulo" -> "joao paulo" (hífen vira espaço)', () => {
  assert.strictEqual(normalizeAlias('João-Paulo'), 'joao paulo');
});
test('"João Paulo" -> "joao paulo" (mesma forma, com espaço já presente)', () => {
  assert.strictEqual(normalizeAlias('João Paulo'), 'joao paulo');
});
test("\"D'Angelo\" -> \"d angelo\" (apóstrofo vira espaço)", () => {
  assert.strictEqual(normalizeAlias("D'Angelo"), 'd angelo');
});
test('"Søren" -> "søren" — ø é LETRA, fica intacto (NUNCA "s ren"/"soren")', () => {
  assert.strictEqual(normalizeAlias('Søren'), 'søren');
});
test('"Łukasz Piszczek" -> "łukasz piszczek" — ł é LETRA, fica intacto', () => {
  assert.strictEqual(normalizeAlias('Łukasz Piszczek'), 'łukasz piszczek');
});
test('"Müller" -> "muller" — ü TEM combining mark sob NFKD, esse sim remove', () => {
  assert.strictEqual(normalizeAlias('Müller'), 'muller');
});
test('NUNCA transliteração: normalizeAlias("søren") !== normalizeAlias("soren")', () => {
  assert.notStrictEqual(normalizeAlias('søren'), normalizeAlias('soren'));
});

console.log('\n15) Idempotência de UUID no seed gerado — prova estrutural da Opção B');
test('a migration de person_aliases NUNCA lista a coluna "id" — sempre DEFAULT gen_random_uuid() da tabela', () => {
  const sql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260901030000_seed_goias_person_aliases.sql'), 'utf8');
  const insertLine = sql.match(/insert into public\.person_aliases \(([^)]+)\)/);
  assert.ok(insertLine, 'não achou o INSERT de person_aliases na migration');
  const columns = insertLine[1].split(',').map((c) => c.trim());
  assert.ok(!columns.includes('id'), `coluna "id" não deveria aparecer no INSERT, achou: ${columns.join(', ')}`);
});
test('a migration de person_alias_sources resolve person_alias_id por JOIN (person_id + normalized_alias), nunca por UUID literal pré-calculado', () => {
  const sql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260901030000_seed_goias_person_aliases.sql'), 'utf8');
  assert.ok(sql.includes('select pa.id, v.source, v.source_record_key'), 'esperava resolver person_alias_id via select de pa.id');
  assert.ok(sql.includes('join public.person_aliases pa'), 'esperava um JOIN em public.person_aliases');
  assert.ok(sql.includes('on pa.person_id = v.person_id and pa.normalized_alias = v.normalized_alias'), 'esperava o JOIN casando por (person_id, normalized_alias), não por id');
});
test('cada linha de VALUES em person_alias_sources tem exatamente 1 literal ::uuid (person_id, vindo do registry) — nenhum 2º UUID pré-calculado (seria o alias id)', () => {
  const sql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260901030000_seed_goias_person_aliases.sql'), 'utf8');
  const valuesBlock = sql.split(') as v(person_id, normalized_alias, source, source_record_key)')[0].split('values\n  (')[1];
  const rows = sql.match(/^\s{4}\('[0-9a-f-]+'::uuid,/gm) || [];
  assert.ok(rows.length > 0, 'não achou linhas de VALUES com ::uuid em person_alias_sources');
  const uuidCastsPerRow = sql.match(/^\s{4}\(.+\)[,;]?$/gm)?.filter((l) => l.includes('::uuid')) ?? [];
  for (const row of uuidCastsPerRow) {
    const uuidCasts = (row.match(/::uuid/g) || []).length;
    assert.strictEqual(uuidCasts, 1, `linha com número inesperado de ::uuid (${uuidCasts}): ${row}`);
  }
});
test('generate_person_aliases_seed.mjs está TRAVADO (migration já aplicada) — rodar de novo tem que se recusar, nunca sobrescrever o arquivo', () => {
  const before = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260901030000_seed_goias_person_aliases.sql'), 'utf8');
  assert.throws(() => execFileSync(process.execPath, [path.join(__dirname, 'generate_person_aliases_seed.mjs')], { stdio: 'pipe' }));
  const after = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260901030000_seed_goias_person_aliases.sql'), 'utf8');
  assert.strictEqual(before, after, 'o arquivo já aplicado mudou — o guard de "migration travada" falhou');
});
test('reexecutar generate_additive_person_aliases_seed.mjs (a migration de Evair/Welliton, essa sim ainda não aplicada) produz o MESMO SQL byte-a-byte', () => {
  const additivePath = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902010000_add_evair_welliton_aliases.sql');
  const before = fs.readFileSync(additivePath, 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'generate_additive_person_aliases_seed.mjs')], { stdio: 'pipe' });
  const after = fs.readFileSync(additivePath, 'utf8');
  assert.strictEqual(before, after, 'a migration aditiva mudou ao regenerar — a geração não é determinística');
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length > 0) {
  console.log('\nFALHAS:');
  for (const f of failures) console.log(` - ${f.name}: ${f.err.message}`);
  process.exit(1);
}

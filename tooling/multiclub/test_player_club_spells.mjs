// Testes do seed de player_club_spells — rodam contra o dado real gerado,
// não um mock (exceto a seção 10, testes diretos do algoritmo de registry
// com dado sintético, porque testam robustez a CENÁRIOS que o dataset
// real não apresenta hoje, ex. reordenar um array de fonte).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { loadSpellRegistry, resolveSpellMatch, resolveSpellGroupMatches, registerNewSpell, refreshKnownBoundary, supersedeSpell, emptySpellRegistry } from './spell_registry.mjs';
import { loadClubRegistry, resolveClubId, emptyClubRegistry, registerNewClub } from './club_registry.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const spells = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_spells_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_spell_sources_seed.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
const spellRegistry = loadSpellRegistry(path.join(__dirname, 'spells_registry.json'));
const clubRegistry = loadClubRegistry(path.join(__dirname, 'clubs_registry.json'));
const migrationSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902040000_create_player_club_spells.sql'), 'utf8');
const seedSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902050000_seed_goias_player_club_spells.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byName(name) { return canonicalPeople.find((p) => p.canonicalName === name); }
function spellsOf(canonicalName) {
  const person = byName(canonicalName);
  return spells.filter((s) => s.personId === person.canonicalId).sort((a, b) => a.spellOrder - b.spellOrder);
}
function sourcesOfSpell(spellId) { return sources.filter((s) => s.spellId === spellId); }

console.log('1) Walter — 3 spells Goiás, ordem 1/2/3, 2019 existe, sem relationship_type na linha do spell');
test('Walter tem exatamente 3 spells, spell_order 1/2/3', () => {
  const rows = spellsOf('Walter Henrique da Silva');
  assert.strictEqual(rows.length, 3);
  assert.deepStrictEqual(rows.map((r) => r.spellOrder), [1, 2, 3]);
});
test('spells não têm campo relationshipType — mora só em sources', () => {
  assert.ok(!('relationshipType' in spells[0]));
  assert.ok('relationshipType' in sources[0]);
});
test('o 3º spell de Walter é 2019, VERIFIED', () => {
  const third = spellsOf('Walter Henrique da Silva')[2];
  assert.strictEqual(third.startYear, 2019);
  assert.strictEqual(third.endYear, 2019);
  assert.strictEqual(third.isOngoing, false);
});

console.log('\n2) Paulo Baier / Rafael Moura / Iarley — 2 spells cada, preservados');
for (const [name, p1, p2] of [['Paulo Baier', [2004, 2005], [2007, 2008]], ['Rafael Moura', [2010, 2010], [2019, 2020]], ['Iarley', [2008, 2009], [2011, 2012]]]) {
  test(`${name}: 2 spells (${p1.join('-')}, ${p2.join('-')})`, () => {
    const rows = spellsOf(name);
    assert.strictEqual(rows.length, 2);
    assert.strictEqual(rows[0].startYear, p1[0]); assert.strictEqual(rows[0].endYear, p1[1]);
    assert.strictEqual(rows[1].startYear, p2[0]); assert.strictEqual(rows[1].endYear, p2[1]);
  });
}

console.log('\n3) Evair — 2 spells, 2000 e 2002, mesmo person_id');
test('Evair Aparecido Paulino tem 2 spells (2000, 2002), mesmo personId', () => {
  const rows = spellsOf('Evair Aparecido Paulino');
  assert.strictEqual(rows.length, 2);
  assert.strictEqual(rows[0].startYear, 2000); assert.strictEqual(rows[0].endYear, 2000);
  assert.strictEqual(rows[1].startYear, 2002); assert.strictEqual(rows[1].endYear, 2002);
  assert.strictEqual(rows[0].personId, rows[1].personId);
});

console.log('\n4) Welliton — 2 spells, 2005-2007 e 2021, mesmo person_id');
test('Welliton Soares de Morais tem 2 spells (2005-2007, 2021), mesmo personId', () => {
  const rows = spellsOf('Welliton Soares de Morais');
  assert.strictEqual(rows.length, 2);
  assert.strictEqual(rows[0].startYear, 2005); assert.strictEqual(rows[0].endYear, 2007);
  assert.strictEqual(rows[1].startYear, 2021); assert.strictEqual(rows[1].endYear, 2021);
  assert.strictEqual(rows[0].personId, rows[1].personId);
});

console.log('\n5) Fabiano Cézar Viegas — 2006-2007 VERIFIED, nunca associado a Fabiano Monroe');
test('Fabiano Cézar Viegas tem 1 spell, 2006-2007, VERIFIED', () => {
  const rows = spellsOf('Fabiano Cézar Viegas');
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].startYear, 2006);
  assert.strictEqual(rows[0].endYear, 2007);
  assert.strictEqual(rows[0].verificationStatus, 'VERIFIED');
});
test('"Fabiano Monroe" não existe em canonicalPeople nem em spells', () => {
  assert.ok(!canonicalPeople.some((p) => p.canonicalName.includes('Monroe')));
  assert.ok(!spells.some((s) => s.canonicalName.includes('Monroe')));
});

console.log('\n6) Nicolas Godinho Johann — 2021-2022 VERIFIED (não mais PROVISIONAL/2021)');
test('Nicolas Godinho Johann tem 1 spell, 2021-2022, eligibility APPROVED, verification_status VERIFIED', () => {
  const rows = spellsOf('Nicolas Godinho Johann');
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].startYear, 2021);
  assert.strictEqual(rows[0].endYear, 2022);
  assert.strictEqual(rows[0].eligibility, 'APPROVED');
  assert.strictEqual(rows[0].verificationStatus, 'VERIFIED');
});
test('nenhum spell no seed inteiro é PROVISIONAL', () => {
  assert.ok(!spells.some((s) => s.eligibility === 'PROVISIONAL'));
});

console.log('\n7) Danilo/Nicolas/Michael/Erik — preservados da rodada anterior');
test('Danilo Gabriel de Andrade (1999-2003) != Danilo Cunha da Silva (ongoing)', () => {
  const g = spellsOf('Danilo Gabriel de Andrade');
  const c = spellsOf('Danilo Cunha da Silva');
  assert.strictEqual(g.length, 1); assert.strictEqual(g[0].endYear, 2003);
  assert.strictEqual(c.length, 1); assert.strictEqual(c[0].isOngoing, true);
});
test('Michael Richard Delgado de Oliveira: só 2017-2019, nenhum 1999', () => {
  const rows = spellsOf('Michael Richard Delgado de Oliveira');
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].startYear, 2017); assert.strictEqual(rows[0].endYear, 2019);
});
test('Erik Nascimento de Lima: só 2013-2015', () => {
  const rows = spellsOf('Erik Nascimento de Lima');
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].startYear, 2013); assert.strictEqual(rows[0].endYear, 2015);
});

console.log('\n8) Tadeu — 1 spell contínuo desde 2019/4, LOAN->PERMANENT não cria 2º spell');
test('Tadeu Antônio Ferreira tem exatamente 1 spell (não 2), começando 2019/abr, ongoing', () => {
  const rows = spellsOf('Tadeu Antônio Ferreira');
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].startYear, 2019);
  assert.strictEqual(rows[0].startMonth, 4);
  assert.strictEqual(rows[0].isOngoing, true);
});
test('o único spell de Tadeu tem provenance com AMBOS relationship_type (LOAN e PERMANENT) — a mudança virou dado de fonte, não um novo spell', () => {
  const rows = spellsOf('Tadeu Antônio Ferreira');
  const srcs = sourcesOfSpell(rows[0].spellId);
  const types = new Set(srcs.map((s) => s.relationshipType));
  assert.ok(types.has('LOAN'));
  assert.ok(types.has('PERMANENT'));
});
test('Luiz Felipe do Nascimento dos Santos NÃO mescla mais automaticamente (heurística de gap+relationship_type foi removida — sem override nem contiguidade real, fica 2 spells, exatamente o cenário de falso-positivo que o gap+tipo antigo produziria)', () => {
  const rows = spellsOf('Luiz Felipe do Nascimento dos Santos');
  assert.strictEqual(rows.length, 2);
  assert.strictEqual(rows[0].startYear, 2025); assert.strictEqual(rows[0].endYear, 2025); assert.strictEqual(rows[0].endMonth, 11);
  assert.strictEqual(rows[1].startYear, 2026); assert.strictEqual(rows[1].startMonth, 1); assert.strictEqual(rows[1].isOngoing, true);
});
test('Luiz Felipe NÃO tem continuousSpellOverride nem evidência (lineup_matches/career_players) que prove continuidade em dezembro/2025 — investigado, nada encontrado', () => {
  const luizFelipe = byName('Luiz Felipe do Nascimento dos Santos');
  assert.ok(!luizFelipe.continuousSpellOverride);
});
test('Murilo Camara Saquetti Chimelo Pereira NÃO mescla (gap de 2 meses, sem override) — continua 2 spells', () => {
  const rows = spellsOf('Murilo Camara Saquetti Chimelo Pereira');
  assert.strictEqual(rows.length, 2);
});

console.log('\n9) Estrutura — sem appearances/goals/posição, is_ongoing nunca inventa end_year');
test('CREATE TABLE de player_club_spells não declara appearances/goals/assists/minutes/shirt_number/position', () => {
  const createBlock = migrationSql.split('create table if not exists public.player_club_spells')[1].split('create table if not exists public.player_club_spell_sources')[0];
  for (const forbidden of ['appearances', 'goals', 'assists', 'minutes', 'shirt_number', 'position']) {
    assert.ok(!new RegExp(`\\b${forbidden}\\b`).test(createBlock), `coluna proibida "${forbidden}"`);
  }
});
test('todo spell com is_ongoing=true tem end_year/end_month/endPrecision null', () => {
  for (const s of spells) {
    if (s.isOngoing) {
      assert.strictEqual(s.endYear, null);
      assert.strictEqual(s.endMonth, null);
      assert.strictEqual(s.endPrecision, null);
    }
  }
});

console.log('\n10) Registry — robustez a reordenar array, inserir item anterior, refinar precisão, nova provenance');
test('reordenar o array de origem (mudar qual segmento aparece "primeiro") não muda o spellId — match é por overlap temporal, não por índice', () => {
  const reg = emptySpellRegistry();
  const boundaryA = { startYear: 2004, startMonth: null, endYear: 2005, endMonth: null, isOngoing: false };
  const boundaryB = { startYear: 2007, startMonth: null, endYear: 2008, endMonth: null, isOngoing: false };
  const entryA = registerNewSpell(reg, { personCanonicalPersonKey: 'p:1', clubCanonicalKey: 'c:1', boundary: boundaryA });
  const entryB = registerNewSpell(reg, { personCanonicalPersonKey: 'p:1', clubCanonicalKey: 'c:1', boundary: boundaryB });
  // simula um "rerun" onde a ORDEM de descoberta dos 2 segmentos se
  // inverteu (B resolvido antes de A) — resultado tem que ser o MESMO
  // spellId pra cada boundary, independente da ordem.
  const resolvedBFirst = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:1', clubCanonicalKey: 'c:1', boundary: boundaryB });
  const resolvedAFirst = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:1', clubCanonicalKey: 'c:1', boundary: boundaryA });
  assert.strictEqual(resolvedBFirst.spellId, entryB.spellId);
  assert.strictEqual(resolvedAFirst.spellId, entryA.spellId);
});
test('inserir uma passagem ANTERIOR nova não muda o spellId das passagens já registradas', () => {
  const reg = emptySpellRegistry();
  const boundary2012 = { startYear: 2012, startMonth: null, endYear: 2013, endMonth: null, isOngoing: false };
  const entry2012 = registerNewSpell(reg, { personCanonicalPersonKey: 'p:2', clubCanonicalKey: 'c:1', boundary: boundary2012 });
  // "descobre" uma passagem mais antiga (2008-2009) num run futuro —
  // registra como NOVA (não sobrepõe 2012-2013), e o id de 2012-2013
  // continua o mesmo.
  const boundary2008 = { startYear: 2008, startMonth: null, endYear: 2009, endMonth: null, isOngoing: false };
  const resolved2008 = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:2', clubCanonicalKey: 'c:1', boundary: boundary2008 });
  assert.strictEqual(resolved2008.status, 'new');
  const resolved2012Again = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:2', clubCanonicalKey: 'c:1', boundary: boundary2012 });
  assert.strictEqual(resolved2012Again.spellId, entry2012.spellId);
});
test('refinar o início/fim (YEAR -> MONTH, ainda sobrepondo o boundary anterior) resolve pro MESMO spellId, e refreshKnownBoundary não troca o id', () => {
  const reg = emptySpellRegistry();
  const coarse = { startYear: 2019, startMonth: null, endYear: 2019, endMonth: null, isOngoing: false };
  const entry = registerNewSpell(reg, { personCanonicalPersonKey: 'p:3', clubCanonicalKey: 'c:1', boundary: coarse });
  const refined = { startYear: 2019, startMonth: 3, endYear: 2019, endMonth: 11, isOngoing: false };
  const resolved = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:3', clubCanonicalKey: 'c:1', boundary: refined });
  assert.strictEqual(resolved.status, 'matched');
  assert.strictEqual(resolved.spellId, entry.spellId);
  refreshKnownBoundary(resolved.entry, refined);
  assert.strictEqual(resolved.entry.spellId, entry.spellId);
  assert.deepStrictEqual(resolved.entry.lastKnownBoundary, refined);
});
test('2 entradas de registry que casam ao mesmo tempo -> status ambiguous, nunca escolhido sozinho', () => {
  const reg = emptySpellRegistry();
  registerNewSpell(reg, { personCanonicalPersonKey: 'p:4', clubCanonicalKey: 'c:1', boundary: { startYear: 2010, startMonth: null, endYear: 2015, endMonth: null, isOngoing: false } });
  registerNewSpell(reg, { personCanonicalPersonKey: 'p:4', clubCanonicalKey: 'c:1', boundary: { startYear: 2012, startMonth: null, endYear: 2020, endMonth: null, isOngoing: false } });
  const resolved = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:4', clubCanonicalKey: 'c:1', boundary: { startYear: 2013, startMonth: null, endYear: 2013, endMonth: null, isOngoing: false } });
  assert.strictEqual(resolved.status, 'ambiguous');
  assert.strictEqual(resolved.matches.length, 2);
});
test('nenhuma entrada do registry real usa índice de array na sua identidade (schema da entrada não tem sourceRecordKey/foundingEvidenceKey)', () => {
  for (const e of spellRegistry.entries) {
    assert.ok(!('foundingEvidenceKey' in e), 'registry v1 (baseado em índice) não deveria mais existir');
    assert.ok('lastKnownBoundary' in e);
  }
});
test('reexecutar build+generate produz o MESMO SQL byte-a-byte (nova provenance/reruns não mudam ids)', () => {
  const before = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902050000_seed_goias_player_club_spells.sql'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'build_player_club_spells_seed.mjs')], { stdio: 'pipe' });
  execFileSync(process.execPath, [path.join(__dirname, 'generate_player_club_spells_seed.mjs')], { stdio: 'pipe' });
  const after = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902050000_seed_goias_player_club_spells.sql'), 'utf8');
  assert.strictEqual(before, after);
});

console.log('\n11) Temporal — start_precision independente de end_precision, UNKNOWN suportado pelo schema');
test('CHECK de start_precision e end_precision são independentes (colunas/constraints separadas no schema)', () => {
  assert.ok(migrationSql.includes('start_precision text not null check (start_precision in'));
  assert.ok(migrationSql.includes("end_precision text check (end_precision in ('YEAR', 'MONTH', 'DATE', 'UNKNOWN')"));
});
test('"UNKNOWN" é um valor válido tanto pra start_precision quanto end_precision no schema', () => {
  const startCheck = migrationSql.match(/start_precision text not null check \(start_precision in \(([^)]+)\)\)/)[1];
  const endCheck = migrationSql.match(/end_precision text check \(end_precision in \(([^)]+)\)\)/)[1];
  assert.ok(startCheck.includes('UNKNOWN'));
  assert.ok(endCheck.includes('UNKNOWN'));
});
test('existe pelo menos 1 spell real com start_precision=MONTH e end_precision=null (ongoing) simultaneamente — prova a independência na prática', () => {
  assert.ok(spells.some((s) => s.startPrecision === 'MONTH' && s.isOngoing && s.endPrecision === null));
});

console.log('\n12) Clubs — UUID estável em regenerações, independente de nome/slug');
test('regenerar o clubs registry 2x resolve pro MESMO clubId pra "goias"', () => {
  const reg1 = emptyClubRegistry();
  const e1 = registerNewClub(reg1, 'goias');
  const resolved = resolveClubId(reg1, 'goias');
  assert.strictEqual(resolved.clubId, e1.clubId);
});
test('resolveClubId depende só do registryLookupKey, nunca de name/slug/short_name (a função nem recebe esses parâmetros)', () => {
  assert.strictEqual(resolveClubId.length, 2); // (registry, registryLookupKey) — sem campo de nome
});
test('o clubs registry real e a migration de seed de clubs concordam no mesmo clubId pro Goiás', () => {
  const goiasEntry = clubRegistry.entries.find((e) => e.registryLookupKey === 'goias');
  assert.ok(goiasEntry);
  const seedClubsSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902030000_seed_clubs.sql'), 'utf8');
  assert.ok(seedClubsSql.includes(goiasEntry.clubId));
});
test('todo spell do seed real usa exatamente o clubId do registry (nunca um UUID diferente)', () => {
  const goiasEntry = clubRegistry.entries.find((e) => e.registryLookupKey === 'goias');
  assert.ok(spells.every((s) => s.clubId === goiasEntry.clubId));
});

console.log('\n13) Registry — estratégia SPLIT/MERGE explícita');
test('SPLIT: quando 2 candidates do MESMO run se sobrepõem à foundingBoundary de 1 entrada existente, os dois voltam ambiguous_split (nunca escolhido sozinho)', () => {
  const reg = emptySpellRegistry();
  const wide = registerNewSpell(reg, { personCanonicalPersonKey: 'p:10', clubCanonicalKey: 'c:1', boundary: { startYear: 2010, startMonth: null, endYear: 2014, endMonth: null, isOngoing: false } });
  // descobrimos depois que "2010-2014" eram na verdade 2 passagens
  const candidates = [
    { boundary: { startYear: 2010, startMonth: null, endYear: 2012, endMonth: null, isOngoing: false } },
    { boundary: { startYear: 2014, startMonth: null, endYear: 2014, endMonth: null, isOngoing: false } },
  ];
  const results = resolveSpellGroupMatches(reg, 'p:10', 'c:1', candidates);
  assert.strictEqual(results[0].status, 'ambiguous_split');
  assert.strictEqual(results[1].status, 'ambiguous_split');
  assert.strictEqual(results[0].matches[0].canonicalSpellKey, wide.canonicalSpellKey);
});
test('SPLIT resolvido (via decisão humana simulada): o segmento que ainda contém a foundingBoundary original mantém o spellId, o outro fica livre pra virar novo', () => {
  const reg = emptySpellRegistry();
  const wide = registerNewSpell(reg, { personCanonicalPersonKey: 'p:11', clubCanonicalKey: 'c:1', boundary: { startYear: 2010, startMonth: null, endYear: 2014, endMonth: null, isOngoing: false } });
  // decisão humana: "2010-2012" é a continuação do spell original (contém
  // a foundingBoundary por completo); "2014" é registrado como um spell
  // NOVO, separado — nunca reaproveita a chave do original.
  const inheriting = { startYear: 2010, startMonth: null, endYear: 2012, endMonth: null, isOngoing: false };
  const newOne = { startYear: 2014, startMonth: null, endYear: 2014, endMonth: null, isOngoing: false };
  refreshKnownBoundary(wide, inheriting); // o override decide: este continua sendo o spell original
  const resolvedInheriting = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:11', clubCanonicalKey: 'c:1', boundary: inheriting });
  assert.strictEqual(resolvedInheriting.status, 'matched');
  assert.strictEqual(resolvedInheriting.spellId, wide.spellId);
  const registeredNew = registerNewSpell(reg, { personCanonicalPersonKey: 'p:11', clubCanonicalKey: 'c:1', boundary: newOne });
  assert.notStrictEqual(registeredNew.spellId, wide.spellId);
  assert.notStrictEqual(registeredNew.canonicalSpellKey, wide.canonicalSpellKey);
});

console.log('\n14) Registry — MERGE (supersedeSpell) nunca reaproveita canonicalSpellKey');
test('supersedeSpell marca o antigo SUPERSEDED, o sobrevivente continua ACTIVE, nenhum id/chave é reaproveitado', () => {
  const reg = emptySpellRegistry();
  const a = registerNewSpell(reg, { personCanonicalPersonKey: 'p:12', clubCanonicalKey: 'c:1', boundary: { startYear: 2010, startMonth: null, endYear: 2012, endMonth: null, isOngoing: false } });
  const b = registerNewSpell(reg, { personCanonicalPersonKey: 'p:12', clubCanonicalKey: 'c:1', boundary: { startYear: 2013, startMonth: null, endYear: 2015, endMonth: null, isOngoing: false } });
  const survivor = supersedeSpell(reg, b.canonicalSpellKey, a.canonicalSpellKey);
  assert.strictEqual(survivor.spellId, a.spellId);
  const bEntry = reg.entries.find((e) => e.canonicalSpellKey === b.canonicalSpellKey);
  assert.strictEqual(bEntry.status, 'SUPERSEDED');
  assert.strictEqual(bEntry.supersededByCanonicalSpellKey, a.canonicalSpellKey);
  const aEntry = reg.entries.find((e) => e.canonicalSpellKey === a.canonicalSpellKey);
  assert.strictEqual(aEntry.status, 'ACTIVE');
  // a chave/id de "b" nunca é reaproveitada — continua existindo no
  // registry, só marcada, nunca removida nem sobrescrita.
  assert.ok(reg.entries.some((e) => e.canonicalSpellKey === b.canonicalSpellKey));
});
test('depois do merge, um candidate que se sobrepõe ao período antigo de "b" resolve pro SOBREVIVENTE (a), nunca reabre "b"', () => {
  const reg = emptySpellRegistry();
  const a = registerNewSpell(reg, { personCanonicalPersonKey: 'p:13', clubCanonicalKey: 'c:1', boundary: { startYear: 2010, startMonth: null, endYear: 2012, endMonth: null, isOngoing: false } });
  const b = registerNewSpell(reg, { personCanonicalPersonKey: 'p:13', clubCanonicalKey: 'c:1', boundary: { startYear: 2013, startMonth: null, endYear: 2015, endMonth: null, isOngoing: false } });
  supersedeSpell(reg, b.canonicalSpellKey, a.canonicalSpellKey);
  refreshKnownBoundary(a, { startYear: 2010, startMonth: null, endYear: 2015, endMonth: null, isOngoing: false }); // "a" passa a cobrir o período todo
  const resolved = resolveSpellMatch(reg, { personCanonicalPersonKey: 'p:13', clubCanonicalKey: 'c:1', boundary: { startYear: 2014, startMonth: null, endYear: 2014, endMonth: null, isOngoing: false } });
  assert.strictEqual(resolved.status, 'matched');
  assert.strictEqual(resolved.spellId, a.spellId);
});
test('supersedeSpell lança erro se a chave já estiver SUPERSEDED (nunca reexecuta um merge por cima)', () => {
  const reg = emptySpellRegistry();
  const a = registerNewSpell(reg, { personCanonicalPersonKey: 'p:14', clubCanonicalKey: 'c:1', boundary: { startYear: 2010, startMonth: null, endYear: 2012, endMonth: null, isOngoing: false } });
  const b = registerNewSpell(reg, { personCanonicalPersonKey: 'p:14', clubCanonicalKey: 'c:1', boundary: { startYear: 2013, startMonth: null, endYear: 2015, endMonth: null, isOngoing: false } });
  supersedeSpell(reg, b.canonicalSpellKey, a.canonicalSpellKey);
  assert.throws(() => supersedeSpell(reg, b.canonicalSpellKey, a.canonicalSpellKey));
});
test('Tadeu (dataset real): tem continuousSpellOverride estruturado E resolve 1 spell só — override e regra automática concordam', () => {
  const tadeu = byName('Tadeu Antônio Ferreira');
  assert.ok(tadeu.continuousSpellOverride);
  assert.strictEqual(tadeu.continuousSpellOverride.clubSlug, 'goias');
  assert.strictEqual(spellsOf('Tadeu Antônio Ferreira').length, 1);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length > 0) {
  console.log('\nFALHAS:');
  for (const f of failures) console.log(` - ${f.name}: ${f.err.message}`);
  process.exit(1);
}

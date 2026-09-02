import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { extractSquadPlayerFields, computeSquadDrift, classifyNameDrift, classifyShirtDrift, normalizeNameForComparison } from './crowd_lineup_squad_drift.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const DART_FILE = path.join(ROOT, 'lib', 'features', 'crowd_lineup', 'domain', 'goias_squad.dart');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'crowd_lineup_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'crowd_lineup_person_mapping_stats.json'), 'utf8'));
const squadMapping = JSON.parse(fs.readFileSync(path.join(RECON, 'squad_members_person_mapping.json'), 'utf8'));
const squadMembers = JSON.parse(fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'squad_members.json'), 'utf8'));
const dartSrc = fs.readFileSync(DART_FILE, 'utf8');
const driftReport = JSON.parse(fs.readFileSync(path.join(RECON, 'crowd_lineup_squad_drift_report.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

// extrai pares (id, personId) reais do .dart, na ordem em que aparecem
function extractDartEntries(src) {
  const idRe = /id: '([a-z0-9_]+)',\s*\n\s*personId: '([0-9a-f-]{36})',/g;
  return [...src.matchAll(idRe)].map((m) => ({ id: m[1], personId: m[2] }));
}

// ============================================================================
// 1) Cardinalidade goiasSquad x squad_members
// ============================================================================
console.log('1) cardinalidade goiasSquad x squad_members');
test('goiasSquad tem 31 jogadores, squad_members tem 31 — mesmo id-space exato', () => {
  assert.strictEqual(mapping.length, 31);
  assert.strictEqual(squadMembers.length, 31);
  const smIds = new Set(squadMembers.map((s) => s.id));
  for (const m of mapping) assert.ok(smIds.has(m.squadPlayerId), `${m.squadPlayerId} não existe em squad_members`);
  const goiasSquadIds = new Set(mapping.map((m) => m.squadPlayerId));
  for (const s of squadMembers) assert.ok(goiasSquadIds.has(s.id), `squad_members:${s.id} não existe no goiasSquad`);
});

// ============================================================================
// 2) Mapping 100% RESOLVED via F4 (nunca por nome)
// ============================================================================
console.log('\n2) mapping 100% RESOLVED, reusando F4');
test('31/31 RESOLVED, 0 UNRESOLVED/AMBIGUOUS/OUT_OF_SCOPE', () => {
  assert.strictEqual(stats.RESOLVED, 31);
  assert.strictEqual(stats.UNRESOLVED, 0);
  assert.strictEqual(stats.AMBIGUOUS, 0);
  assert.strictEqual(stats.OUT_OF_SCOPE, 0);
  assert.strictEqual(stats.allResolved100pct, true);
});
test('todo personId do mapping F5 é idêntico ao personId aprovado na F4 pro mesmo id (nunca resolvido de novo por nome)', () => {
  const f4ById = new Map(squadMapping.map((m) => [m.squadMemberId, m]));
  for (const m of mapping) {
    const f4 = f4ById.get(m.squadPlayerId);
    assert.ok(f4, `${m.squadPlayerId} não encontrado no mapping F4`);
    assert.strictEqual(f4.status, 'RESOLVED');
    assert.strictEqual(m.personId, f4.personId, `${m.squadPlayerId}: F5 diverge da F4`);
    assert.strictEqual(m.canonicalName, f4.canonicalName);
  }
});
test('0 personId duplicado entre os 31 RESOLVED (1:1)', () => {
  const counts = new Map();
  for (const m of mapping) counts.set(m.personId, (counts.get(m.personId) || 0) + 1);
  const dup = [...counts.entries()].filter(([, c]) => c > 1);
  assert.strictEqual(dup.length, 0, `personIds duplicados: ${JSON.stringify(dup)}`);
});

// ============================================================================
// 3) Casos sensíveis
// ============================================================================
console.log('\n3) casos sensíveis');
test('nicolas -> Nicolas Vichiatto da Silva (nunca Godinho)', () => {
  const m = mapping.find((x) => x.squadPlayerId === 'nicolas');
  assert.match(m.canonicalName, /Vichiatto/i);
  assert.doesNotMatch(m.canonicalName, /Godinho/i);
});
test('danilo -> Danilo Cunha da Silva (nunca Gabriel)', () => {
  const m = mapping.find((x) => x.squadPlayerId === 'danilo');
  assert.match(m.canonicalName, /Cunha/i);
  assert.doesNotMatch(m.canonicalName, /Gabriel/i);
});
test('murilo_camara e murillo_victorio resolvem pra pessoas DISTINTAS', () => {
  const camara = mapping.find((x) => x.squadPlayerId === 'murilo_camara');
  const victorio = mapping.find((x) => x.squadPlayerId === 'murillo_victorio');
  assert.notStrictEqual(camara.personId, victorio.personId);
  assert.match(camara.canonicalName, /Camara/i);
  assert.match(victorio.canonicalName, /Victorio/i);
});
test('tadeu, luiz_felipe, rodrigo_soares, djalma, lourenco, lucas_rodrigues batem com F4', () => {
  const f4ById = new Map(squadMapping.map((m) => [m.squadMemberId, m]));
  for (const id of ['tadeu', 'luiz_felipe', 'rodrigo_soares', 'djalma', 'lourenco', 'lucas_rodrigues']) {
    const m5 = mapping.find((x) => x.squadPlayerId === id);
    const m4 = f4ById.get(id);
    assert.strictEqual(m5.personId, m4.personId, id);
  }
});
test('Dieguinho ausente do goiasSquad — mesma ausência já confirmada na F4 pra squad_members', () => {
  assert.ok(!mapping.some((m) => m.squadPlayerId === 'dieguinho'));
  assert.ok(!squadMapping.some((m) => m.squadMemberId === 'dieguinho'));
});

// ============================================================================
// 4) O .dart real bate exatamente com o mapping (não confia só no JSON)
// ============================================================================
console.log('\n4) goias_squad.dart real bate com o mapping');
test('extraídos 31 pares (id, personId) do .dart, todos batendo 1:1 com o mapping', () => {
  const dartEntries = extractDartEntries(dartSrc);
  assert.strictEqual(dartEntries.length, 31, `esperava 31 pares id/personId no .dart, achei ${dartEntries.length}`);
  const mappingById = new Map(mapping.map((m) => [m.squadPlayerId, m.personId]));
  for (const entry of dartEntries) {
    assert.ok(mappingById.has(entry.id), `${entry.id} do .dart não está no mapping`);
    assert.strictEqual(entry.personId, mappingById.get(entry.id), `${entry.id}: personId do .dart diverge do mapping`);
  }
});
test('nenhum SquadPlayer no .dart ficou sem personId (non-null field, 31/31 injetados)', () => {
  const idCount = [...dartSrc.matchAll(/^\s*id: '[a-z0-9_]+',$/gm)].length;
  const personIdCount = [...dartSrc.matchAll(/^\s*personId: '[0-9a-f-]{36}',$/gm)].length;
  assert.strictEqual(idCount, 31);
  assert.strictEqual(personIdCount, 31);
});
test('SquadPlayer.id (slug) nunca foi substituído/alterado — mesmos 31 slugs de antes da F5', () => {
  const knownSlugs = new Set([
    'tadeu', 'ezequiel', 'murillo_victorio', 'thiago_rodrigues',
    'luisao', 'lucas_ribeiro', 'luiz_felipe', 'ramon_menezes', 'murilo_camara',
    'rodrigo_soares', 'marcos_vinicius', 'nicolas', 'danilo', 'djalma',
    'lourenco', 'filipe_machado', 'baldoria', 'juninho', 'lucas_rodrigues',
    'gege', 'lucas_lima', 'brayann', 'wellington_rato', 'pedrinho',
    'anselmo_ramon', 'cadu', 'felipe_clemente', 'jean_carlos', 'halerrandrio',
    'esli_garcia', 'kadu_sousa',
  ]);
  const dartIds = extractDartEntries(dartSrc).map((e) => e.id);
  assert.strictEqual(dartIds.length, 31);
  for (const id of dartIds) assert.ok(knownSlugs.has(id), `slug inesperado: ${id}`);
  for (const id of knownSlugs) assert.ok(dartIds.includes(id), `slug ausente: ${id}`);
});

// ============================================================================
// 5) Nenhuma migration Supabase necessária — match_lineup_votes.slots é
//    jsonb livre, pid nunca tipado/FK, nada a migrar no banco
// ============================================================================
console.log('\n5) nenhuma migration Supabase (contrato de persistência intocado)');
test('supabase/crowd_lineup.sql não referencia person_id em nenhuma tabela/coluna', () => {
  const sql = fs.readFileSync(path.join(ROOT, 'supabase', 'crowd_lineup.sql'), 'utf8');
  assert.doesNotMatch(sql, /person_id/i);
});
test('nenhum arquivo em supabase/migrations/ desta etapa foi criado (F5 é 0 migration)', () => {
  const before = fs.readdirSync(path.join(ROOT, 'supabase', 'migrations')).filter((f) => f.endsWith('.sql'));
  assert.strictEqual(before.length, 35, `esperava 35 migrations já aplicadas (até a F4.5), achei ${before.length} — F5 não deveria ter adicionado nenhuma`);
});

// ============================================================================
// 6) Reprodutibilidade
// ============================================================================
console.log('\n6) reprodutibilidade');
test('rodar build_crowd_lineup_person_mapping.mjs de novo produz o mesmo JSON', () => {
  const before = fs.readFileSync(path.join(RECON, 'crowd_lineup_person_mapping.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'build_crowd_lineup_person_mapping.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'crowd_lineup_person_mapping.json'), 'utf8');
  assert.strictEqual(before, after);
});
test('rodar apply_crowd_lineup_person_mapping.mjs de novo (idempotência): detecta que já foi aplicado e aborta sem duplicar', () => {
  let threw = false;
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'apply_crowd_lineup_person_mapping.mjs')], { cwd: ROOT, stdio: 'pipe' });
  } catch {
    threw = true;
  }
  assert.ok(threw, 'rodar apply de novo sobre um arquivo já injetado deveria abortar (evita personId duplicado), mas não abortou');
  // confirma que o arquivo não foi corrompido/duplicado pela tentativa
  const personIdCount = [...fs.readFileSync(DART_FILE, 'utf8').matchAll(/personId: '[0-9a-f-]{36}',/g)].length;
  assert.strictEqual(personIdCount, 31, 'a tentativa de reaplicar deveria ter abortado ANTES de escrever qualquer coisa');
});

// ============================================================================
// 7) Endurecimento — drift real (name/shirtNumber) goiasSquad x
//    squad_members, formalizado (era só inspeção visual antes)
// ============================================================================
console.log('\n7) drift real name/shirtNumber — goiasSquad x squad_members');

test('classifyNameDrift: string idêntica -> NAME_MATCH', () => {
  assert.strictEqual(classifyNameDrift('Tadeu', 'Tadeu'), 'NAME_MATCH');
});
test('classifyNameDrift: só acentuação/caixa difere -> NAME_FORMAT_ONLY', () => {
  assert.strictEqual(classifyNameDrift('Luisao', 'Luisão'), 'NAME_FORMAT_ONLY');
  assert.strictEqual(classifyNameDrift('TADEU', 'tadeu'), 'NAME_FORMAT_ONLY');
  assert.strictEqual(classifyNameDrift('Murilo  Câmara', 'Murilo Câmara'), 'NAME_FORMAT_ONLY');
});
test('classifyNameDrift: nome realmente diferente -> NAME_DIVERGENCE, nunca escondido como FORMAT_ONLY', () => {
  assert.strictEqual(classifyNameDrift('Tadeu', 'Thiago'), 'NAME_DIVERGENCE');
});
test('classifyNameDrift: abreviação editorial NÃO é auto-classificada como FORMAT_ONLY (heurística de forma normalizada não cobre isso, vira DIVERGENCE pra revisão humana)', () => {
  assert.strictEqual(classifyNameDrift('Wellington Rato', 'W. Rato'), 'NAME_DIVERGENCE');
});
test('classifyShirtDrift: mesmo número -> SHIRT_MATCH, número diferente -> SHIRT_DIVERGENCE', () => {
  assert.strictEqual(classifyShirtDrift(23, 23), 'SHIRT_MATCH');
  assert.strictEqual(classifyShirtDrift(23, 24), 'SHIRT_DIVERGENCE');
});
test('normalizeNameForComparison remove acento/caixa/espaço duplo', () => {
  assert.strictEqual(normalizeNameForComparison('  Luisão  '), 'luisao');
});

test('extractSquadPlayerFields no .dart REAL extrai 31 entradas com name+shirtNumber (não só id+personId)', () => {
  const entries = extractSquadPlayerFields(dartSrc);
  assert.strictEqual(entries.length, 31);
  for (const e of entries) {
    assert.ok(typeof e.name === 'string' && e.name.length > 0, `${e.id}: name ausente`);
    assert.ok(Number.isInteger(e.shirtNumber) && e.shirtNumber > 0, `${e.id}: shirtNumber inválido`);
  }
});

test('computeSquadDrift no dado REAL (goiasSquad x squad_members.json, o export já validado pela F4) — pareamento slug->slug, nunca por nome', () => {
  const entries = extractSquadPlayerFields(dartSrc);
  const { rows, stats: driftStats } = computeSquadDrift(entries, squadMembers);
  assert.strictEqual(rows.length, 31);
  assert.ok(rows.every((r) => !r.missingInSquadMembers), 'algum slug do goiasSquad não existe em squad_members — cardinalidade já provada 31/31 na F5 original');
  // resultado real — reportado como é, não forçado a bater com o ideal do pedido
  assert.deepStrictEqual(
    { NAME_MATCH: driftStats.NAME_MATCH, NAME_FORMAT_ONLY: driftStats.NAME_FORMAT_ONLY, NAME_DIVERGENCE: driftStats.NAME_DIVERGENCE, SHIRT_MATCH: driftStats.SHIRT_MATCH, SHIRT_DIVERGENCE: driftStats.SHIRT_DIVERGENCE },
    { NAME_MATCH: 31, NAME_FORMAT_ONLY: 0, NAME_DIVERGENCE: 0, SHIRT_MATCH: 31, SHIRT_DIVERGENCE: 0 },
  );
});

test('persisted crowd_lineup_squad_drift_report.json bate com o recomputado agora (nenhum drift no arquivo escondendo um resultado diferente do atual)', () => {
  const entries = extractSquadPlayerFields(dartSrc);
  const recomputed = computeSquadDrift(entries, squadMembers);
  assert.deepStrictEqual(driftReport.stats.NAME_MATCH, recomputed.stats.NAME_MATCH);
  assert.deepStrictEqual(driftReport.stats.NAME_DIVERGENCE, recomputed.stats.NAME_DIVERGENCE);
  assert.deepStrictEqual(driftReport.stats.SHIRT_DIVERGENCE, recomputed.stats.SHIRT_DIVERGENCE);
  assert.strictEqual(driftReport.rows.length, 31);
});

test('0 NAME_DIVERGENCE e 0 SHIRT_DIVERGENCE no dado real — se isso mudar no futuro, o teste falha (nunca silencia drift novo)', () => {
  assert.strictEqual(driftReport.stats.NAME_DIVERGENCE, 0);
  assert.strictEqual(driftReport.stats.SHIRT_DIVERGENCE, 0);
});

test('goiasSquad e squad_members.json não foram alterados por esta auditoria (só leitura, nunca corrige automaticamente)', () => {
  const beforeDart = fs.readFileSync(DART_FILE, 'utf8');
  const beforeSquadMembers = fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'squad_members.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_crowd_lineup_squad_drift.mjs')], { cwd: ROOT });
  const afterDart = fs.readFileSync(DART_FILE, 'utf8');
  const afterSquadMembers = fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'squad_members.json'), 'utf8');
  assert.strictEqual(beforeDart, afterDart, 'goias_squad.dart foi alterado pela auditoria — nunca deveria');
  assert.strictEqual(beforeSquadMembers, afterSquadMembers, 'squad_members.json foi alterado pela auditoria — nunca deveria');
});

test('reprodutibilidade: rodar audit_crowd_lineup_squad_drift.mjs de novo produz o mesmo JSON byte a byte', () => {
  const before = fs.readFileSync(path.join(RECON, 'crowd_lineup_squad_drift_report.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_crowd_lineup_squad_drift.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'crowd_lineup_squad_drift_report.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

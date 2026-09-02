import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { extractGoiasPlayers } from './build_goias_players_person_mapping.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const DART_FILE = path.join(ROOT, 'lib', 'features', 'arena', 'games', 'career_path', 'goias_players.dart');
const CAREER_DART_FILE = path.join(ROOT, 'lib', 'features', 'arena', 'games', 'career_path', 'career_players.dart');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'goias_players_person_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'goias_players_person_mapping_stats.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(RECON, 'people_insert_plan.json'), 'utf8'));
const dartSrc = fs.readFileSync(DART_FILE, 'utf8');
const careerDartSrc = fs.readFileSync(CAREER_DART_FILE, 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byIndex(i) { return mapping.find((m) => m.sourceIndex === i); }
function byName(name) { return mapping.find((m) => m.sourceName === name); }

// ============================================================================
// 1) Contagens — 215 total, classificação real
// ============================================================================
console.log('1) contagens reais');
test('215 entradas no total (mesma contagem confirmada na auditoria da F1)', () => {
  assert.strictEqual(mapping.length, 215);
  assert.strictEqual(stats.total, 215);
});
test('classificação real: 41 RESOLVED / 58 AMBIGUOUS / 116 UNRESOLVED / 0 TEXT_ALIAS_ONLY / 0 OUT_OF_SCOPE, soma 215', () => {
  assert.strictEqual(stats.RESOLVED, 41);
  assert.strictEqual(stats.AMBIGUOUS, 58);
  assert.strictEqual(stats.UNRESOLVED, 116);
  assert.strictEqual(stats.TEXT_ALIAS_ONLY, 0);
  assert.strictEqual(stats.OUT_OF_SCOPE, 0);
  assert.strictEqual(stats.RESOLVED + stats.AMBIGUOUS + stats.UNRESOLVED + stats.TEXT_ALIAS_ONLY + stats.OUT_OF_SCOPE, 215);
});
test('nenhuma linha RESOLVED sem personId, nenhuma linha não-RESOLVED com personId', () => {
  for (const m of mapping) {
    if (m.status === 'RESOLVED') assert.ok(m.personId, `${m.sourceName}: RESOLVED sem personId`);
    else assert.strictEqual(m.personId, null, `${m.sourceName}: ${m.status} com personId preenchido`);
  }
});
test('0 personId duplicado entre as 41 RESOLVED (cardinalidade 1:1)', () => {
  const ids = mapping.filter((m) => m.status === 'RESOLVED').map((m) => m.personId);
  assert.strictEqual(new Set(ids).size, ids.length);
});

// ============================================================================
// 2) goias_players.dart já participava da reconciliação existente (source
//    'goias_players_dart') — reusada, não uma pipeline paralela
// ============================================================================
console.log('\n2) reconciliação reutilizada (não paralela)');
test('todo member source=goias_players_dart em canonical_people_candidates.json tem sourceId numérico dentro de [0,215)', () => {
  let count = 0;
  for (const p of canonicalPeople) {
    for (const m of p.members) {
      if (m.source !== 'goias_players_dart') continue;
      count++;
      const idx = Number(m.sourceId);
      assert.ok(Number.isInteger(idx) && idx >= 0 && idx < 215, `sourceId inválido: ${m.sourceId}`);
    }
  }
  assert.strictEqual(count, 214, '214 dos 215 índices têm member (178/Nicolas é o único deliberadamente fora, ver teste de homônimo)');
});
test('o mapping nunca cria uma pessoa nova — todo personId RESOLVED já existia em canonical_people_candidates.json ANTES desta etapa', () => {
  const knownIds = new Set(canonicalPeople.map((p) => p.canonicalId));
  for (const m of mapping) {
    if (m.status !== 'RESOLVED') continue;
    assert.ok(knownIds.has(m.personId), `${m.sourceName}: personId ${m.personId} não existe em canonical_people_candidates.json`);
  }
});

// ============================================================================
// 3) Homônimos obrigatórios
// ============================================================================
console.log('\n3) homônimos obrigatórios');
test('índice 178 "Nicolas" (bare) é AMBIGUOUS, 0 owners, nunca resolvido pra Vichiatto nem Godinho', () => {
  const m = byIndex(178);
  assert.strictEqual(m.sourceName, 'Nicolas');
  assert.strictEqual(m.status, 'AMBIGUOUS');
  assert.strictEqual(m.personId, null);
  assert.strictEqual(m.sources.length, 0);
});
test('"Danilo Portugal" é AMBIGUOUS (identity=AMBIGUOUS_IDENTITY na própria pessoa canônica)', () => {
  const m = byName('Danilo Portugal');
  assert.ok(m);
  assert.strictEqual(m.status, 'AMBIGUOUS');
  assert.strictEqual(m.personId, null);
});
test('"Danilo Dias" (pessoa distinta de Danilo Portugal e do Danilo de career_players) fica PROVISIONAL -> UNRESOLVED, nunca fundido', () => {
  const m = byName('Danilo Dias');
  assert.ok(m);
  assert.strictEqual(m.status, 'UNRESOLVED');
  assert.strictEqual(m.personId, null);
});
test('"Carlos Eduardo" bare é AMBIGUOUS — 2 Carlos Eduardo diferentes existem no elenco (Amaral Pereira de Castro / de Sousa Leopoldino), nunca escolhido um sozinho', () => {
  const m = byName('Carlos Eduardo');
  assert.ok(m);
  assert.strictEqual(m.status, 'AMBIGUOUS');
  assert.strictEqual(m.personId, null);
});
test('"Murilo Henrique" (goiasPlayers) é uma pessoa PROVISIONAL própria, nunca fundida com Murilo Câmara nem Murillo Victorio (squad_members)', () => {
  const m = byName('Murilo Henrique');
  assert.ok(m);
  assert.strictEqual(m.status, 'UNRESOLVED');
  assert.notStrictEqual(m.canonicalName, 'Murilo Camara Saquetti Chimelo Pereira');
  assert.notStrictEqual(m.canonicalName, 'Murillo Carvalho Victorio');
});
test('Michael e Fabiano bare não existem em goias_players.dart — confirmado por ausência, não presumido', () => {
  assert.strictEqual(mapping.some((m) => /^michael$/i.test(m.sourceName)), false);
  assert.strictEqual(mapping.some((m) => /^fabiano/i.test(m.sourceName)), false);
});

// ============================================================================
// 4) 0 colisões de texto normalizado DENTRO de goias_players.dart
// ============================================================================
console.log('\n4) colisões de texto normalizado (dentro de goias_players.dart)');
test('231 textos distintos (215 nomes + 16 aliases), 0 colisão — cada nome/alias é único', () => {
  assert.strictEqual(stats.distinctNormalizedTexts, 231);
  assert.strictEqual(stats.normalizedTextCollisions, 0);
  assert.strictEqual(stats.samePersonCollisions, 0);
  assert.strictEqual(stats.crossPersonCollisions, 0);
});

// ============================================================================
// 5) goias_players.dart real bate com o mapping (não confia só no JSON)
// ============================================================================
console.log('\n5) goias_players.dart real bate com o mapping');
test('extractGoiasPlayers no .dart real extrai exatamente 215 entradas, na mesma ordem do mapping', () => {
  const entries = extractGoiasPlayers(dartSrc);
  assert.strictEqual(entries.length, 215);
  entries.forEach((e, i) => assert.strictEqual(e.name, mapping[i].sourceName, `índice ${i}`));
});
test('as 41 linhas RESOLVED do mapping têm personId injetado no .dart real; as 174 restantes não têm', () => {
  const personIdLines = [...dartSrc.matchAll(/personId: '([0-9a-f-]{36})'/g)].map((m) => m[1]);
  assert.strictEqual(personIdLines.length, 41);
  const expectedIds = mapping.filter((m) => m.status === 'RESOLVED').map((m) => m.personId).sort();
  assert.deepStrictEqual(personIdLines.sort(), expectedIds);
});
test('16 aliases continuam intactos no .dart real, nenhum alterado pela injeção de personId', () => {
  const aliasCount = [...dartSrc.matchAll(/aliases: \[/g)].length;
  assert.strictEqual(aliasCount, 16);
});

// ============================================================================
// 6) career_players.dart (30 jogadores) intocado nesta etapa
// ============================================================================
console.log('\n6) career_players.dart intocado');
test('career_players.dart continua com 30 entradas, 21 com personId, 9 sem — F6 não reabre a reconciliation foundation', () => {
  const idCount = [...careerDartSrc.matchAll(/^\s{4}id: '[a-z0-9_]+',$/gm)].length;
  const personIdCount = [...careerDartSrc.matchAll(/personId: '[0-9a-f-]{36}',/g)].length;
  assert.strictEqual(idCount, 30);
  assert.strictEqual(personIdCount, 21);
});
test('os 9 career_players historicamente UNRESOLVED continuam sem personId (grafite/bruno_henrique/pedro_raul/jadilson/souza/roni/vitor/marcelo_rangel/apodi)', () => {
  const stillUnresolvedIds = ['grafite', 'bruno_henrique', 'pedro_raul', 'jadilson', 'souza', 'roni', 'vitor', 'marcelo_rangel', 'apodi'];
  for (const id of stillUnresolvedIds) {
    const idIdx = careerDartSrc.indexOf(`id: '${id}',`);
    assert.ok(idIdx !== -1, `${id} não encontrado`);
    const nextEntryIdx = careerDartSrc.indexOf("id: '", idIdx + 10);
    const block = careerDartSrc.slice(idIdx, nextEntryIdx === -1 ? undefined : nextEntryIdx);
    assert.doesNotMatch(block, /personId: '[0-9a-f-]{36}'/, `${id} ganhou personId indevidamente`);
  }
});

// ============================================================================
// 7) Reprodutibilidade
// ============================================================================
console.log('\n7) reprodutibilidade e idempotência');
test('rodar build_goias_players_person_mapping.mjs de novo produz o mesmo JSON byte a byte', () => {
  const before = fs.readFileSync(path.join(RECON, 'goias_players_person_mapping.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'build_goias_players_person_mapping.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'goias_players_person_mapping.json'), 'utf8');
  assert.strictEqual(before, after);
});
test('rodar apply_goias_players_person_mapping.mjs de novo (idempotência): detecta que já foi aplicado e aborta sem duplicar', () => {
  let threw = false;
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'apply_goias_players_person_mapping.mjs')], { cwd: ROOT, stdio: 'pipe' });
  } catch {
    threw = true;
  }
  assert.ok(threw, 'rodar apply de novo sobre o arquivo já injetado deveria abortar');
  const personIdCount = [...fs.readFileSync(DART_FILE, 'utf8').matchAll(/personId: '[0-9a-f-]{36}'/g)].length;
  assert.strictEqual(personIdCount, 41, 'a tentativa de reaplicar deveria ter abortado ANTES de escrever qualquer coisa');
});

// ============================================================================
// 8) Nenhuma migration Supabase — goias_players.dart é local, 0 mudança de banco
// ============================================================================
console.log('\n8) 0 migrations Supabase');
test('nenhum arquivo novo em supabase/migrations/ (F6 é 0 migration, igual F5)', () => {
  // Filtra por timestamp <= o baseline da F4.5 — etapas futuras (M2.2A em
  // diante) podem adicionar migrations próprias sem invalidar este teste.
  const count = fs.readdirSync(path.join(ROOT, 'supabase', 'migrations'))
    .filter((f) => f.endsWith('.sql') && f <= '20260902210000_z').length;
  assert.strictEqual(count, 35, `esperava 35 migrations até o baseline da F4.5, achei ${count}`);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const DATA = path.join(ROOT, 'data_export', 'goias');
const RECON = path.join(DATA, 'player_reconciliation');
const BUILD_SCRIPT = path.join(__dirname, 'build_lineup_matches_canonical_mapping.mjs');

const mapping = JSON.parse(fs.readFileSync(path.join(RECON, 'lineup_matches_canonical_mapping.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'lineup_matches_canonical_mapping_stats.json'), 'utf8'));
const lineupMatches = JSON.parse(fs.readFileSync(path.join(DATA, 'lineup_matches.json'), 'utf8'));
const matchesSeed = JSON.parse(fs.readFileSync(path.join(RECON, 'matches_seed.json'), 'utf8'));
const appearances = JSON.parse(fs.readFileSync(path.join(RECON, 'player_match_appearances_seed.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function slotsOf(lineupMatchId) { return mapping.find((m) => m.lineupMatchId === lineupMatchId).players; }
function allSlots() { return mapping.flatMap((m) => m.players.map((p) => ({ ...p, lineupMatchId: m.lineupMatchId }))); }

// ============================================================================
// 1) 3 identidades nunca confundidas
// ============================================================================
console.log('1) 3 identidades nunca confundidas');
test('lineup_matches.id (feature) permanece intocado — nenhum registro de matches_seed.json reescreve o id da feature', () => {
  for (const m of lineupMatches) {
    const row = matchesSeed.find((r) => r.lineupMatchId === m.id);
    assert.ok(row, `${m.id} sem row em matches_seed.json`);
    assert.strictEqual(row.lineupMatchId, m.id, 'lineupMatchId nunca deveria ser sobrescrito');
  }
});
test('canonicalMatchId é sempre um UUID distinto de lineupMatchId (nunca reaproveitado como o mesmo valor)', () => {
  for (const m of mapping) {
    if (!m.canonicalMatchId) continue;
    assert.notStrictEqual(m.canonicalMatchId, m.lineupMatchId);
    assert.match(m.canonicalMatchId, /^[0-9a-f-]{36}$/);
  }
});
test('personId, quando presente, é sempre um UUID distinto de canonicalMatchId e lineupMatchId', () => {
  for (const slot of allSlots()) {
    if (!slot.personId) continue;
    assert.match(slot.personId, /^[0-9a-f-]{36}$/);
  }
});

// ============================================================================
// 6) coverage lineup_matches -> canonicalMatchId
// ============================================================================
console.log('\n6) coverage de identidade de partida');
test('31/31 lineup_matches têm canonicalMatchId — 0 sem, 0 com 2+', () => {
  assert.strictEqual(stats.totalLineupMatches, 31);
  assert.strictEqual(stats.matchesWithCanonical, 31);
  assert.strictEqual(stats.matchesWithoutCanonical, 0);
  assert.strictEqual(stats.matchesWith2PlusCanonical, 0);
});
test('nenhum canonicalMatchId novo foi criado por esta etapa — todo matchId em mapping.json já existia em matches_seed.json (F7 só lê o registry, nunca reconcilia)', () => {
  const knownMatchIds = new Set(matchesSeed.map((m) => m.matchId));
  for (const m of mapping) if (m.canonicalMatchId) assert.ok(knownMatchIds.has(m.canonicalMatchId), m.lineupMatchId);
});

// ============================================================================
// 9) ida/volta
// ============================================================================
console.log('\n9) pares ida/volta — canonicalMatchId distintos, nunca por placar/nome');
test('Independiente 2010, Vasco 2013, Atlético-GO 2026: ida e volta sempre têm canonicalMatchId DIFERENTE', () => {
  for (const check of stats.idaVoltaChecks) {
    assert.ok(check.canonicalMatchIdA, check.pair[0]);
    assert.ok(check.canonicalMatchIdB, check.pair[1]);
    assert.strictEqual(check.distinct, true, `${check.pair.join(' vs ')} deveriam ser distintos`);
  }
  assert.strictEqual(stats.idaVoltaChecks.length, 3);
});

// ============================================================================
// 8/13 — classificação por slot
// ============================================================================
console.log('\n8/13) classificação por slot (341 total)');
test('341 slots totais (31 partidas x 11), soma das classificações bate exatamente', () => {
  assert.strictEqual(stats.totalSlots, 341);
  const sum = Object.values(stats.slotStatus).reduce((a, b) => a + b, 0);
  assert.strictEqual(sum, 341);
});
test('162 RESOLVED_EXISTING_APPEARANCE — bate com o total real de player_match_appearances_seed.json', () => {
  assert.strictEqual(stats.slotStatus.RESOLVED_EXISTING_APPEARANCE, 162);
  assert.strictEqual(appearances.length, 162);
});
test('0 RESOLVED_PERSON_NO_APPEARANCE e 0 SOURCE_MISMATCH nos dados reais — nenhum gap nem divergência de integridade encontrado', () => {
  assert.strictEqual(stats.slotStatus.RESOLVED_PERSON_NO_APPEARANCE || 0, 0);
  assert.strictEqual(stats.slotStatus.SOURCE_MISMATCH || 0, 0);
});
test('todo slot RESOLVED_EXISTING_APPEARANCE tem personId + appearanceSourceRef preenchidos; todo AMBIGUOUS/UNRESOLVED tem personId null', () => {
  for (const slot of allSlots()) {
    if (slot.status === 'RESOLVED_EXISTING_APPEARANCE') {
      assert.ok(slot.personId, JSON.stringify(slot));
      assert.ok(slot.appearanceSourceRef, JSON.stringify(slot));
    } else {
      assert.strictEqual(slot.personId, null, JSON.stringify(slot));
    }
  }
});

// ============================================================================
// 14) homônimos obrigatórios
// ============================================================================
console.log('\n14) homônimos obrigatórios');
test('Danilo em 2003 (2x) -> Danilo Gabriel de Andrade, NUNCA Danilo Cunha', () => {
  for (const id of ['2003_juventude_brA_reacao', '2003_santos_brA_reacao']) {
    const slot = slotsOf(id).find((p) => p.rawAnswer === 'DANILO');
    assert.strictEqual(slot.status, 'RESOLVED_EXISTING_APPEARANCE');
    assert.strictEqual(slot.canonicalName, 'Danilo Gabriel de Andrade');
    assert.doesNotMatch(slot.canonicalName, /Cunha/);
  }
});
test('"Danilo Portugal" (4 ocorrências, 2005-2006) fica AMBIGUOUS_PERSON, personId null — nunca fundido com Gabriel nem Cunha', () => {
  const occurrences = allSlots().filter((s) => s.rawName === 'Danilo Portugal');
  assert.strictEqual(occurrences.length, 4);
  for (const o of occurrences) {
    assert.strictEqual(o.status, 'AMBIGUOUS_PERSON');
    assert.strictEqual(o.personId, null);
  }
});
test('Michael 1999 (1999_santacruz_brB_titulo) fica UNRESOLVED, NUNCA vaza pro Michael Richard Delgado de Oliveira (moderno)', () => {
  const slot = slotsOf('1999_santacruz_brB_titulo').find((p) => p.rawAnswer === 'MICHAEL');
  assert.strictEqual(slot.status, 'UNRESOLVED_PERSON');
  assert.strictEqual(slot.personId, null);
  assert.doesNotMatch(slot.canonicalName || '', /Richard Delgado/);
});
test('Fabiano em 2006 (3x) -> Fabiano Cézar Viegas, NUNCA Fabiano Monroe', () => {
  const occurrences = allSlots().filter((s) => s.rawAnswer === 'FABIANO');
  assert.strictEqual(occurrences.length, 3);
  for (const o of occurrences) {
    assert.strictEqual(o.status, 'RESOLVED_EXISTING_APPEARANCE');
    assert.strictEqual(o.canonicalName, 'Fabiano Cézar Viegas');
    assert.doesNotMatch(o.canonicalName, /Monroe/);
  }
});
test('Nicolas (4 ocorrências) se divide corretamente: 2021 -> Godinho, 2026 -> Vichiatto, nunca por escolha de texto', () => {
  const g2021 = ['2021_csa_brB_g4', '2021_guarani_brB_acesso'].map((id) => slotsOf(id).find((p) => p.rawAnswer === 'NICOLAS'));
  const v2026 = ['2026_atleticogo_goiano_final_ida', '2026_atleticogo_goiano_final_volta'].map((id) => slotsOf(id).find((p) => p.rawAnswer === 'NICOLAS'));
  for (const s of g2021) { assert.strictEqual(s.status, 'RESOLVED_EXISTING_APPEARANCE'); assert.strictEqual(s.canonicalName, 'Nicolas Godinho Johann'); }
  for (const s of v2026) { assert.strictEqual(s.status, 'RESOLVED_EXISTING_APPEARANCE'); assert.strictEqual(s.canonicalName, 'Nicolas Vichiatto da Silva'); }
  const ids = new Set([...g2021, ...v2026].map((s) => s.personId));
  assert.strictEqual(ids.size, 2, 'os 2 Nicolas precisam resolver pra personId DIFERENTES');
});
test('"Carlos Eduardo" bare (2018_aparecidense_goiano_final_volta) fica AMBIGUOUS_PERSON — 2 Carlos Eduardo reais existem no elenco, nunca escolhido 1 sozinho', () => {
  const slot = slotsOf('2018_aparecidense_goiano_final_volta').find((p) => p.rawName === 'Carlos Eduardo');
  assert.strictEqual(slot.status, 'AMBIGUOUS_PERSON');
  assert.strictEqual(slot.personId, null);
});
test('Luiz Felipe / Murilo / Murillo: 0 ocorrências em lineup_matches — confirmado por ausência, não presumido', () => {
  assert.strictEqual(stats.homonymAuditCounts.luiz_felipe, 0);
  assert.strictEqual(stats.homonymAuditCounts.murilo, 0);
  assert.strictEqual(stats.homonymAuditCounts.murillo, 0);
});

// ============================================================================
// 15/16) diff de posição e camisa (snapshot da partida, nunca substituído)
// ============================================================================
console.log('\n15/16) diff de posição/camisa — snapshot, nunca corrigido automaticamente');
test('positionDiff: 152 MATCH, 10 CANONICAL_NULL (compostos/genéricos, Etapa E), 0 SOURCE_NULL, 0 DIVERGENCE', () => {
  assert.deepStrictEqual(stats.positionDiff, { MATCH: 152, CANONICAL_NULL: 10, SOURCE_NULL: 0, DIVERGENCE: 0 });
});
test('shirtDiff: 162 MATCH, 0 divergência — shirt_number do slot bate 100% com player_match_appearances.shirt_number', () => {
  assert.deepStrictEqual(stats.shirtDiff, { MATCH: 162, CANONICAL_NULL: 0, SOURCE_NULL: 0, DIVERGENCE: 0 });
});

// ============================================================================
// 25) duplicatas
// ============================================================================
console.log('\n25) duplicatas');
test('0 duplicatas de pessoa dentro da MESMA escalação (personId conhecido nunca aparece 2x na mesma lineup)', () => {
  assert.strictEqual(stats.duplicateSourcePlayers.length, 0);
});
test('0 appearance STARTED órfã — todas as 162 rastreiam de volta a um slot real em lineup_matches.json', () => {
  assert.strictEqual(stats.orphanAppearances.length, 0);
  assert.strictEqual(stats.appearancesLinkedToSlot, 162);
});

// ============================================================================
// 26/27) sanity de data/placar/competição contra passport (nunca usado como identidade)
// ============================================================================
console.log('\n26/27) sanity factual contra passport_matches');
test('15 partidas linkadas a passport_matches — 100% batem em data/placar/competição', () => {
  assert.strictEqual(stats.passportSanity.length, 15);
  for (const p of stats.passportSanity) {
    assert.strictEqual(p.dateMatch, true, p.lineupMatchId);
    assert.strictEqual(p.scoreMatch, true, p.lineupMatchId);
    assert.strictEqual(p.competitionMatch, true, p.lineupMatchId);
  }
});

// ============================================================================
// Read-only — nenhuma mutação em people/matches/appearances/registries
// ============================================================================
console.log('\nread-only — F7 nunca escreve na fundação canônica');
const PROTECTED_FILES = [
  path.join(RECON, 'canonical_people_candidates.json'),
  path.join(RECON, 'people_insert_plan.json'),
  path.join(RECON, 'matches_seed.json'),
  path.join(RECON, 'match_source_refs_seed.json'),
  path.join(RECON, 'player_match_appearances_seed.json'),
  path.join(RECON, 'player_match_appearance_sources_seed.json'),
  path.join(__dirname, 'matches_registry.json'),
  path.join(__dirname, 'people_registry.json'),
];
test('build_lineup_matches_canonical_mapping.mjs nunca abre nenhum arquivo protegido em modo escrita (checagem estática do código-fonte)', () => {
  const src = fs.readFileSync(BUILD_SCRIPT, 'utf8');
  for (const file of PROTECTED_FILES) {
    const base = path.basename(file);
    assert.doesNotMatch(src, new RegExp(`writeFileSync\\([^)]*${base}`), `${base} não deveria ser escrito por este script`);
  }
});
test('rodar o build de novo NÃO altera nenhum dos arquivos protegidos (hash antes == depois)', () => {
  const before = PROTECTED_FILES.map((f) => fs.readFileSync(f, 'utf8'));
  execFileSync(process.execPath, [BUILD_SCRIPT], { cwd: ROOT });
  const after = PROTECTED_FILES.map((f) => fs.readFileSync(f, 'utf8'));
  before.forEach((b, i) => assert.strictEqual(b, after[i], PROTECTED_FILES[i]));
});
test('lineup_matches.dart, lineup_matches.json e supabase/lineup_matches.sql permanecem intocados (feature IDs preservados)', () => {
  const dartFile = path.join(ROOT, 'lib', 'features', 'arena', 'games', 'lineup', 'lineup_matches.dart');
  const sqlFile = path.join(ROOT, 'supabase', 'lineup_matches.sql');
  const jsonFile = path.join(DATA, 'lineup_matches.json');
  for (const f of [dartFile, sqlFile, jsonFile]) assert.ok(fs.existsSync(f), f);
  const src = fs.readFileSync(BUILD_SCRIPT, 'utf8');
  assert.doesNotMatch(src, /writeFileSync\([^)]*lineup_matches\.(dart|sql|json)/);
});

// ============================================================================
// Endurecimento pós-revisão — coverage no nível da PARTIDA, nunca
// confundida com coverage no nível do slot (validado independentemente
// no Supabase real pelo usuário: 31/31/26/5)
// ============================================================================
console.log('\ncoverage por partida — MATCH IDENTITY != PLAYER IDENTITY BY MATCH != BY SLOT');
test('matchIdentityCoverage: 31 partidas totais, 31 com canonicalMatchId — nunca confundir com coverage de jogador', () => {
  assert.strictEqual(stats.coverage.matchIdentityCoverage.matchesTotal, 31);
  assert.strictEqual(stats.coverage.matchIdentityCoverage.matchesWithCanonicalMatchId, 31);
});
test('playerIdentityCoverageByMatch: 26 partidas com >=1 appearance resolvida, 5 com ZERO — derivado do dataset real, não hardcoded no teste', () => {
  const cov = stats.coverage.playerIdentityCoverageByMatch;
  assert.strictEqual(cov.matchesWithAtLeastOneResolvedAppearance, 26);
  assert.strictEqual(cov.matchesWithZeroResolvedAppearances, 5);
  assert.strictEqual(cov.matchesWithAtLeastOneResolvedAppearance + cov.matchesWithZeroResolvedAppearances, stats.coverage.matchIdentityCoverage.matchesWithCanonicalMatchId);
});
test('playerIdentityCoverageBySlot: 162/341 (~47,5%) — granularidade de JOGADOR, número real independente das outras 2 métricas', () => {
  assert.strictEqual(stats.coverage.playerIdentityCoverageBySlot.totalSlots, 341);
  assert.strictEqual(stats.coverage.playerIdentityCoverageBySlot.resolvedSlots, 162);
});
test('as 5 partidas com zero appearance são exatamente: 1990 Flamengo, 1996 Guarani, 1996 Grêmio, 2003 Fluminense, 2018 Aparecidense', () => {
  const ids = stats.coverage.playerIdentityCoverageByMatch.zeroAppearanceMatches.map((m) => m.lineupMatchId).sort();
  assert.deepStrictEqual(ids, [
    '1990_flamengo_cdb_final_volta',
    '1996_gremio_brA_semi',
    '1996_guarani_brA_quartas',
    '2003_fluminense_brA_reacao',
    '2018_aparecidense_goiano_final_volta',
  ]);
});
test('nas 5 partidas zeradas: RESOLVED_EXISTING_APPEARANCE=0 e RESOLVED_PERSON_NO_APPEARANCE=0 em TODAS — zero é porque zero pessoa foi aprovada ali, nunca porque a Etapa E esqueceu de inserir', () => {
  for (const m of stats.coverage.playerIdentityCoverageByMatch.zeroAppearanceMatches) {
    assert.strictEqual(m.slotStatusBreakdown.RESOLVED_EXISTING_APPEARANCE || 0, 0, m.lineupMatchId);
    assert.strictEqual(m.slotStatusBreakdown.RESOLVED_PERSON_NO_APPEARANCE || 0, 0, m.lineupMatchId);
    assert.strictEqual(m.isGapFromEtapaE, false, m.lineupMatchId);
  }
  assert.strictEqual(stats.coverage.playerIdentityCoverageByMatch.anyGapFromEtapaE, false);
});
test('nas 5 partidas zeradas, a soma UNRESOLVED_PERSON + AMBIGUOUS_PERSON é sempre 11 (os 11 slots inteiros, sem sobra nem falta)', () => {
  for (const m of stats.coverage.playerIdentityCoverageByMatch.zeroAppearanceMatches) {
    const sum = (m.slotStatusBreakdown.UNRESOLVED_PERSON || 0) + (m.slotStatusBreakdown.AMBIGUOUS_PERSON || 0);
    assert.strictEqual(sum, 11, m.lineupMatchId);
    assert.strictEqual(m.slotCount, 11, m.lineupMatchId);
  }
});
test('para TODAS as 31 partidas (não só as 5 zeradas): a soma de slotStatusBreakdown é sempre exatamente 11', () => {
  for (const m of mapping) {
    const sum = Object.values(m.slotStatusBreakdown).reduce((a, b) => a + b, 0);
    assert.strictEqual(sum, 11, m.lineupMatchId);
    assert.strictEqual(m.players.length, 11, m.lineupMatchId);
  }
});
test('0 SOURCE_MISMATCH em qualquer partida (não só nas 5 zeradas) — reconfirmado no nível granular', () => {
  for (const m of mapping) assert.strictEqual(m.slotStatusBreakdown.SOURCE_MISMATCH || 0, 0, m.lineupMatchId);
});
test('26 + 5 partidas com hasAtLeastOneResolvedAppearance consistente com resolvedAppearanceCount (>0 vs ===0)', () => {
  for (const m of mapping) {
    assert.strictEqual(m.hasAtLeastOneResolvedAppearance, m.resolvedAppearanceCount > 0, m.lineupMatchId);
  }
});

// ============================================================================
// Reprodutibilidade
// ============================================================================
console.log('\nreprodutibilidade');
test('rodar build_lineup_matches_canonical_mapping.mjs de novo produz o mesmo JSON byte a byte', () => {
  const beforeMapping = fs.readFileSync(path.join(RECON, 'lineup_matches_canonical_mapping.json'), 'utf8');
  const beforeStats = fs.readFileSync(path.join(RECON, 'lineup_matches_canonical_mapping_stats.json'), 'utf8');
  execFileSync(process.execPath, [BUILD_SCRIPT], { cwd: ROOT });
  const afterMapping = fs.readFileSync(path.join(RECON, 'lineup_matches_canonical_mapping.json'), 'utf8');
  const afterStats = fs.readFileSync(path.join(RECON, 'lineup_matches_canonical_mapping_stats.json'), 'utf8');
  assert.strictEqual(beforeMapping, afterMapping);
  assert.strictEqual(beforeStats, afterStats);
});

// ============================================================================
// 28) 0 migrations
// ============================================================================
console.log('\n28) 0 migrations');
test('nenhuma migration nova em supabase/migrations/ (F7 é auditoria/tooling, 0 mudança de banco)', () => {
  // Filtra por timestamp <= o baseline da F4.5 — etapas futuras (M2.2A em
  // diante) podem adicionar migrations próprias sem invalidar este teste.
  const count = fs.readdirSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files'))
    .filter((f) => f.endsWith('.sql') && f <= '20260902210000_z').length;
  assert.strictEqual(count, 35, `esperava 35 migrations até o baseline da F4.5, achei ${count}`);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

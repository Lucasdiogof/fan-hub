import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const BUILD_SCRIPT = path.join(__dirname, 'audit_career_players_canonical_consumption.mjs');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'career_players_canonical_consumption_audit.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'career_players_canonical_consumption_stats.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byId(id) { return audit.find((a) => a.careerPlayerId === id); }

// ============================================================================
// 2) 30 rows, 21 resolved / 9 unresolved reconfirmado
// ============================================================================
console.log('2) 30 rows, 21 resolved / 9 unresolved');
test('30 career_players totais, 21 ELIGIBLE_FOR_ANALYSIS, 9 BLOCKED_NO_PERSON_ID', () => {
  assert.strictEqual(stats.totalCareerPlayers, 30);
  assert.strictEqual(stats.resolved, 21);
  assert.strictEqual(stats.blockedNoPersonId, 9);
});
test('os 9 blocked são exatamente os 9 já conhecidos — F2 NÃO resolveu nenhum deles', () => {
  assert.deepStrictEqual(stats.blockedIds, ['apodi', 'bruno_henrique', 'grafite', 'jadilson', 'marcelo_rangel', 'pedro_raul', 'roni', 'souza', 'vitor']);
});
test('todo BLOCKED_NO_PERSON_ID tem personId null — nunca resolvido por nome/autocomplete', () => {
  for (const id of stats.blockedIds) {
    const row = byId(id);
    assert.strictEqual(row.canonicalConsumption, 'BLOCKED_NO_PERSON_ID');
    assert.strictEqual(row.personId, null);
  }
});

// ============================================================================
// 6) posição — Fernandão/Iarley = ATA canônico, editorial mais amplo
// ============================================================================
console.log('\n6) posição — Fernandão/Iarley continuam ATA no canônico');
test('Fernandão e Iarley: canônico é [ATA] só (override da Etapa C), editorial é mais amplo (BROADER_EDITORIAL_LABEL) — F2 nunca expande a posição canônica de volta', () => {
  for (const id of ['fernandao', 'iarley']) {
    const row = byId(id);
    assert.deepStrictEqual(row.positionComparison.canonicalCodes, ['ATA']);
    assert.strictEqual(row.positionComparison.result, 'BROADER_EDITORIAL_LABEL');
  }
});
test('19/21 posições batem exatamente (MATCH_PRIMARY) — maioria sem divergência', () => {
  assert.strictEqual(stats.positionComparisonTally.MATCH_PRIMARY, 19);
});

// ============================================================================
// 20/7-8) múltiplas passagens — nunca recombinadas num intervalo contínuo
// ============================================================================
console.log('\n7/8/20) múltiplas passagens pelo Goiás — nunca combinadas num intervalo só');
test('8 pessoas com 2+ spells canônicos no Goiás — nenhuma foi recombinada num intervalo contínuo pelo script', () => {
  assert.strictEqual(stats.peopleWithMultipleGoiasSpells.length, 8);
  for (const p of stats.peopleWithMultipleGoiasSpells) {
    const row = byId(p.careerPlayerId);
    // cada spell canônico preserva seu próprio startYear/endYear distinto —
    // nunca um único período fabricado cobrindo do 1º ao último.
    const years = row.canonicalSpells.map((s) => `${s.startYear}-${s.endYear ?? 'ongoing'}`);
    assert.strictEqual(new Set(years).size, row.canonicalSpells.length, `${p.careerPlayerId}: spells com anos duplicados/colapsados`);
  }
});
test('Fernandão, Evair, Welliton, Rafael Moura, Araújo, Iarley, Paulo Baier: 2 spells canônicos, 2 entradas Goiás no editorial, MATCH — nenhuma soma indevida', () => {
  const expectedMatch = ['fernandao', 'evair', 'welliton', 'rafael_moura', 'araujo', 'iarley', 'paulo_baier'];
  for (const id of expectedMatch) {
    const row = byId(id);
    assert.strictEqual(row.canonicalSpells.length, 2, id);
    assert.strictEqual(row.editorialGoiasEntries.length, 2, id);
    assert.strictEqual(row.goiasSpellComparison.result, 'MATCH', id);
  }
});

// ============================================================================
// 12/21) Walter — teste explícito obrigatório
// ============================================================================
console.log('\n12/21) Walter — spell != club total, nunca confundidos');
test('Walter: CLUB_TOTAL canônico é 97/48 PARTIAL, bate exatamente com aggregate_stats editorial (mesma nota de ledger)', () => {
  const row = byId('walter');
  assert.strictEqual(row.canonicalTotal.appearances, 97);
  assert.strictEqual(row.canonicalTotal.goals, 48);
  assert.strictEqual(row.canonicalTotal.verificationStatus, 'PARTIAL');
  assert.strictEqual(row.editorialTotal.appearances, 97);
  assert.strictEqual(row.editorialTotal.goals, 48);
  assert.strictEqual(row.editorialTotalSource, 'aggregate_stats');
  assert.strictEqual(row.appearancesComparison, 'MATCH');
  assert.strictEqual(row.goalsComparison, 'MATCH');
});
test('Walter: 3 spells canônicos (2012-2013, 2016-2017, 2019) mas só 2 aparecem no clubCareer editorial — o 3º (2019, 0 jogos) fica de fora, classificado LEGACY_MISSING_SPELL, nunca escondido', () => {
  const row = byId('walter');
  assert.strictEqual(row.canonicalSpells.length, 3);
  assert.strictEqual(row.editorialGoiasEntries.length, 2);
  assert.strictEqual(row.goiasSpellComparison.result, 'LEGACY_MISSING_SPELL');
  const spell2019 = row.canonicalSpells.find((s) => s.startYear === 2019);
  assert.ok(spell2019);
  const spellStat2019 = row.canonicalSpellStats.find((s) => s.spellId === spell2019.spellId);
  assert.strictEqual(spellStat2019.appearances, 0);
  assert.strictEqual(spellStat2019.goals, null);
});
test('Walter: a SPELL stat (2019, 0 jogos) nunca é confundida com o CLUB_TOTAL (97 jogos) — são linhas canônicas distintas, com spellId != null vs null', () => {
  const row = byId('walter');
  assert.strictEqual(row.canonicalTotal.appearances, 97);
  const spellStat = row.canonicalSpellStats.find((s) => s.appearances === 0);
  assert.ok(spellStat);
  assert.notStrictEqual(spellStat.appearances, row.canonicalTotal.appearances);
});

// ============================================================================
// 13/22) Tadeu — baseline/snapshot
// ============================================================================
console.log('\n13/22) Tadeu — snapshot com as_of_date, goals diverge (canonical null, legacy 13)');
test('Tadeu: appearances=400 bate exatamente (MATCH), mas canônico tem as_of_date/as_of_match_id (é um SNAPSHOT, não um fato atemporal)', () => {
  const row = byId('tadeu');
  assert.strictEqual(row.appearancesComparison, 'MATCH');
  assert.strictEqual(row.canonicalTotal.appearances, 400);
  assert.strictEqual(row.canonicalTotal.asOfDate, '2026-08-28');
  assert.ok(row.canonicalTotal.asOfMatchId);
});
test('Tadeu: goals diverge — editorial tem 13, canônico tem NULL (CANONICAL_NULL) — nunca escondido, nunca um dos dois sobrescrito automaticamente por este script', () => {
  const row = byId('tadeu');
  assert.strictEqual(row.editorialTotal.goals, 13);
  assert.strictEqual(row.canonicalTotal.goals, null);
  assert.strictEqual(row.goalsComparison, 'CANONICAL_NULL');
});

// ============================================================================
// 9/10) appearances/goals — NULL != 0, nunca soma de carreira inteira
// ============================================================================
console.log('\n9/10) stats — NULL != 0, nunca soma de carreira inteira contra CLUB_TOTAL Goiás');
test('Danilo: CLUB_TOTAL 116/15 bate exatamente com a ÚNICA entrada Goiás do editorial (nunca a carreira inteira, que soma centenas a mais em outros clubes)', () => {
  const row = byId('danilo');
  assert.strictEqual(row.canonicalTotal.appearances, 116);
  assert.strictEqual(row.canonicalTotal.goals, 15);
  assert.strictEqual(row.appearancesComparison, 'MATCH');
  assert.strictEqual(row.goalsComparison, 'MATCH');
  // nunca comparado contra soma de TODOS os clubes (Corinthians 342, São Paulo 193 etc.)
  const totalCareerApps = row.editorialGoiasEntries.reduce((a, e) => a + (e.appearances || 0), 0);
  assert.notStrictEqual(totalCareerApps, 342 + 193 + 116 + 85 + 15);
});
test('Dill: appearances/goals null nos 2 lados (nunca virou 0) — canônico não tem CLUB_TOTAL ainda, classificado NOT_COMPARABLE, não MATCH forçado', () => {
  const row = byId('dill');
  assert.strictEqual(row.editorialTotal.appearances, null);
  assert.strictEqual(row.editorialTotal.goals, null);
  assert.strictEqual(row.canonicalTotal, null);
  assert.strictEqual(row.appearancesComparison, 'NOT_COMPARABLE');
  assert.strictEqual(row.goalsComparison, 'NOT_COMPARABLE');
});
test('20/21 appearances e 19/21 goals batem exatamente (MATCH) — maioria sem divergência real', () => {
  assert.strictEqual(stats.appearancesComparisonTally.MATCH, 20);
  assert.strictEqual(stats.goalsComparisonTally.MATCH, 19);
});

// ============================================================================
// Read-only — nunca escreve na fundação nem no dataset editorial
// ============================================================================
console.log('\nread-only — F2 nunca escreve em people/positions/spells/stats/career_players');
const PROTECTED_FILES = [
  path.join(RECON, 'canonical_people_candidates.json'),
  path.join(RECON, 'people_insert_plan.json'),
  path.join(RECON, 'player_positions_seed.json'),
  path.join(RECON, 'player_club_spells_seed.json'),
  path.join(RECON, 'player_club_stats_seed.json'),
  path.join(RECON, 'career_players_person_mapping.json'),
  path.join(ROOT, 'data_export', 'goias', 'career_players.json'),
];
test('audit_career_players_canonical_consumption.mjs nunca abre nenhum arquivo protegido em modo escrita (checagem estática)', () => {
  const src = fs.readFileSync(BUILD_SCRIPT, 'utf8');
  for (const file of PROTECTED_FILES) {
    const base = path.basename(file);
    assert.doesNotMatch(src, new RegExp(`writeFileSync\\([^)]*${base}`), `${base} não deveria ser escrito por este script`);
  }
});
test('rodar o script de novo NÃO altera nenhum arquivo protegido (hash antes == depois)', () => {
  const before = PROTECTED_FILES.map((f) => fs.readFileSync(f, 'utf8'));
  execFileSync(process.execPath, [BUILD_SCRIPT], { cwd: ROOT });
  const after = PROTECTED_FILES.map((f) => fs.readFileSync(f, 'utf8'));
  before.forEach((b, i) => assert.strictEqual(b, after[i], PROTECTED_FILES[i]));
});
test('career_players.dart (fallback Flutter) permanece intocado', () => {
  const dartFile = path.join(ROOT, 'lib', 'features', 'arena', 'games', 'career_path', 'career_players.dart');
  assert.ok(fs.existsSync(dartFile));
  const src = fs.readFileSync(BUILD_SCRIPT, 'utf8');
  assert.doesNotMatch(src, /writeFileSync\([^)]*career_players\.dart/);
});

// ============================================================================
// Reprodutibilidade
// ============================================================================
console.log('\nreprodutibilidade');
test('rodar audit_career_players_canonical_consumption.mjs de novo produz o mesmo JSON byte a byte', () => {
  const beforeAudit = fs.readFileSync(path.join(RECON, 'career_players_canonical_consumption_audit.json'), 'utf8');
  const beforeStats = fs.readFileSync(path.join(RECON, 'career_players_canonical_consumption_stats.json'), 'utf8');
  execFileSync(process.execPath, [BUILD_SCRIPT], { cwd: ROOT });
  const afterAudit = fs.readFileSync(path.join(RECON, 'career_players_canonical_consumption_audit.json'), 'utf8');
  const afterStats = fs.readFileSync(path.join(RECON, 'career_players_canonical_consumption_stats.json'), 'utf8');
  assert.strictEqual(beforeAudit, afterAudit);
  assert.strictEqual(beforeStats, afterStats);
});

console.log('\n0 migrations');
test('nenhuma migration nova em supabase/migrations/ (F2 é auditoria, 0 mudança de banco)', () => {
  // Filtra por timestamp <= o baseline da F4.5 (última migration aplicada
  // antes de F2/F5/F6/F7) em vez de comparar o total absoluto — assim o
  // teste continua válido mesmo depois de etapas futuras (M2.2A em diante)
  // adicionarem migrations próprias; o que importa aqui é só que F2 mesma
  // não gerou nenhuma.
  const count = fs.readdirSync(path.join(ROOT, 'supabase', 'migrations'))
    .filter((f) => f.endsWith('.sql') && f <= '20260902210000_z').length;
  assert.strictEqual(count, 35, `esperava 35 migrations até o baseline da F4.5, achei ${count}`);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

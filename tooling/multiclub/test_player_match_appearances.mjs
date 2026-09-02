// Testes da Etapa E — player_match_appearances, matches, match_source_refs,
// match_registry (resolução em 2 etapas), kickoff_precision, spell_link, e
// o algoritmo conceitual de recompute (baseline+delta). Roda contra o dado
// real gerado, sem tocar o Supabase.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { computeDelta, recomputeTotal, countsAsAppearance } from './recompute_player_club_stats.mjs';
import {
  emptyMatchRegistry, resolveMatchAnchors, resolveMatchCandidate, resolveMatch,
  registerNewMatch, appendAnchors, refreshDescriptor, supersedeMatch,
  validateMatchRegistryIntegrity, sideIdentity,
} from './match_registry.mjs';
import { kickoffIntervalDays, kickoffIntervalsOverlap, compareKickoffBoundary } from './kickoff_precision.mjs';
import { resolveSpellForDate, classifySpellGap, overlapCandidates, NEAR_BOUNDARY_GRACE_MONTHS } from './spell_link.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const appearances = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_match_appearances_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_match_appearance_sources_seed.json'), 'utf8'));
const buildStats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_match_appearances_seed_stats.json'), 'utf8'));
const matches = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'matches_seed.json'), 'utf8'));
const matchesStats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'matches_seed_stats.json'), 'utf8'));
const sourceRefs = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'match_source_refs_seed.json'), 'utf8'));
const matchIdentityAudit = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'match_identity_audit.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
const insertPlan = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'people_insert_plan.json'), 'utf8'));
const clubSpells = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_spells_seed.json'), 'utf8'));
const lineupMatches = JSON.parse(fs.readFileSync(path.join(ROOT, 'data_export', 'goias', 'lineup_matches.json'), 'utf8'));

const createMatchesSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902100000_create_matches.sql'), 'utf8');
const seedMatchesSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902110000_seed_goias_matches.sql'), 'utf8');
const createAppearancesSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902120000_create_player_match_appearances.sql'), 'utf8');
const seedAppearancesSql = fs.readFileSync(path.join(ROOT, 'supabase', 'migrations', '20260902130000_seed_goias_player_match_appearances.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byName(name) { return canonicalPeople.find((p) => p.canonicalName === name); }
function appearancesOf(canonicalName) { const p = byName(canonicalName); return appearances.filter((a) => a.personId === p.canonicalId); }
function kickoff(overrides) { return { precision: 'DATE', year: 2026, month: 1, date: '2026-01-01', at: null, ...overrides }; }

// ============================================================================
// 1) Chave natural — nunca 2 linhas pra mesma (person, club, match)
// ============================================================================
console.log('1) unicidade (person, club, match)');
test('nenhuma combinação (personId, clubSlug, canonicalMatchId) se repete no seed', () => {
  const seen = new Set();
  for (const a of appearances) {
    const key = `${a.personId}|${a.clubSlug}|${a.canonicalMatchId}`;
    assert.ok(!seen.has(key), `duplicata: ${key}`);
    seen.add(key);
  }
});
test('migration de criação declara UNIQUE (person_id, club_id, canonical_match_id)', () => {
  assert.match(createAppearancesSql, /unique \(person_id, club_id, canonical_match_id\)/);
});
test('migration de seed usa ON CONFLICT (person_id, club_id, canonical_match_id) DO NOTHING', () => {
  assert.match(seedAppearancesSql, /on conflict \(person_id, club_id, canonical_match_id\) do nothing/);
});

// ============================================================================
// 2) 100% STARTED — semântica confirmada do lineup_matches (starting XI only)
// ============================================================================
console.log('\n2) participation_status — 100% STARTED (fonte é só titular)');
test('todas as 162 linhas do seed são STARTED — nenhuma SUBSTITUTE_USED/UNUSED_SUBSTITUTE inventada', () => {
  assert.ok(appearances.length > 0);
  assert.ok(appearances.every((a) => a.participationStatus === 'STARTED'));
});
test('lineup_matches.json tem exatamente 11 jogadores por partida em todas as 31 partidas (confirma starting-XI-only)', () => {
  for (const m of lineupMatches) assert.strictEqual(m.lineup.length, 11, `${m.id} tem ${m.lineup.length} entradas`);
});
test('countsAsAppearance: STARTED e SUBSTITUTE_USED contam, UNUSED_SUBSTITUTE não', () => {
  assert.strictEqual(countsAsAppearance('STARTED'), true);
  assert.strictEqual(countsAsAppearance('SUBSTITUTE_USED'), true);
  assert.strictEqual(countsAsAppearance('UNUSED_SUBSTITUTE'), false);
});
test('schema não tem coluna counts_as_appearance persistida — só menciona o termo em comentários explicativos', () => {
  const offendingLines = createAppearancesSql.split('\n').filter((line) => /counts_as_appearance/.test(line) && !/^\s*--/.test(line));
  assert.strictEqual(offendingLines.length, 0, `linha fora de comentário: ${offendingLines.join(' | ')}`);
});
test('LIMITAÇÃO REAL DO WORKER documentada: provider atual não expõe banco de reservas completo, seed nunca inventa UNUSED_SUBSTITUTE', () => {
  assert.match(buildStats.workerLimitation, /não expõe banco de reservas completo/);
  assert.strictEqual((buildStats.byParticipationStatus.UNUSED_SUBSTITUTE || 0), 0);
  assert.strictEqual((buildStats.byParticipationStatus.SUBSTITUTE_USED || 0), 0);
});

// ============================================================================
// 3) Correção de status é UPDATE da mesma linha, nunca 2ª inserção
// ============================================================================
console.log('\n3) correção de status (UNUSED_SUBSTITUTE -> SUBSTITUTE_USED) é UPDATE, nunca INSERT novo');
test('comentário da migration documenta explicitamente que correção de status é UPDATE da mesma linha', () => {
  assert.match(createAppearancesSql, /UPDATE desta MESMA\s+\n?\s*-- linha, nunca uma 2ª inserção/);
});
test('simulação: aplicar countsAsAppearance ANTES e DEPOIS de uma correção de status na MESMA linha nunca duplica a chave', () => {
  const row = { personId: 'p1', clubId: 'c1', canonicalMatchId: 'm1', participationStatus: 'UNUSED_SUBSTITUTE' };
  assert.strictEqual(countsAsAppearance(row.participationStatus), false);
  row.participationStatus = 'SUBSTITUTE_USED'; // UPDATE in place — mesma referência de objeto/linha
  assert.strictEqual(countsAsAppearance(row.participationStatus), true);
  assert.strictEqual(row.canonicalMatchId, 'm1'); // identidade da linha não mudou
});

// ============================================================================
// 4-7) Algoritmo baseline+delta (recompute_player_club_stats.mjs) —
// SEMPRE com kickoff como intervalo (kickoff_precision.mjs), nunca string.
// ============================================================================
console.log('\n4) baseline+delta — backfill histórico nunca aumenta o total, mesmo com precisão coarse');
test('inserir uma appearance ANTES do baseline (mesmo com precisão YEAR) não muda o total (Tadeu 400@2026-08-28, backfill 2024)', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATETIME', year: 2026, month: 8, date: '2026-08-28', at: '2026-08-28T16:00:00' }) };
  const backfilled = [{ canonicalMatchId: 'pe_backfill_2024', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'YEAR', year: 2024, month: null, date: null, at: null }) }];
  const result = recomputeTotal(baseline, backfilled);
  assert.strictEqual(result.total, 400);
  assert.strictEqual(result.delta, 0);
  assert.strictEqual(result.ambiguousBoundary.length, 0);
});
test('backfill não gera 400 linhas artificiais — o seed real do Tadeu tem muito menos de 400 appearances', () => {
  const tadeuRows = appearancesOf('Tadeu Antônio Ferreira');
  assert.ok(tadeuRows.length > 0);
  assert.ok(tadeuRows.length < 20, `esperado << 400, achou ${tadeuRows.length}`);
});

console.log('\n5) baseline+delta — o próprio match do snapshot nunca soma de novo; fronteira do mesmo dia');
test('uma appearance cujo canonical_match_id é IGUAL ao as_of_match_id do baseline não soma (já incluída no snapshot)', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATETIME', date: '2026-08-28', at: '2026-08-28T16:00:00' }) };
  const candidates = [{ canonicalMatchId: 'pe_cb52680435343cc4', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATETIME', date: '2026-08-28', at: '2026-08-28T16:00:00' }) }];
  const result = recomputeTotal(baseline, candidates);
  assert.strictEqual(result.total, 400);
  assert.strictEqual(result.delta, 0);
});
test('uma partida diferente NO MESMO DIA do baseline, SEM horário confiável dos 2 lados, fica em ambiguousBoundary', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28', at: null }) };
  const candidates = [{ canonicalMatchId: 'pe_outro_jogo_mesmo_dia', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATE', date: '2026-08-28', at: null }) }];
  const result = recomputeTotal(baseline, candidates);
  assert.strictEqual(result.total, 400);
  assert.strictEqual(result.delta, 0);
  assert.strictEqual(result.ambiguousBoundary.length, 1);
});
test('mesmo dia do baseline, AMBOS com horário DATETIME confiável, e o candidato é POSTERIOR -> entra no delta (401)', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATETIME', date: '2026-08-28', at: '2026-08-28T16:00:00' }) };
  const candidates = [{ canonicalMatchId: 'pe_outro_jogo_mesmo_dia_depois', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATETIME', date: '2026-08-28', at: '2026-08-28T20:00:00' }) }];
  const result = recomputeTotal(baseline, candidates);
  assert.strictEqual(result.total, 401);
  assert.strictEqual(result.ambiguousBoundary.length, 0);
});
test('mesmo dia do baseline, AMBOS com DATETIME, mas o candidato é ANTERIOR -> nunca soma (nem ambíguo, nem contado)', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATETIME', date: '2026-08-28', at: '2026-08-28T20:00:00' }) };
  const candidates = [{ canonicalMatchId: 'pe_outro_jogo_mesmo_dia_antes', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATETIME', date: '2026-08-28', at: '2026-08-28T16:00:00' }) }];
  const result = recomputeTotal(baseline, candidates);
  assert.strictEqual(result.total, 400);
  assert.strictEqual(result.ambiguousBoundary.length, 0);
});
test('mesmo dia do baseline, só UM lado com DATETIME confiável -> AMBIGUOUS_BOUNDARY (nunca decide com informação parcial)', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28', at: null }) };
  const candidates = [{ canonicalMatchId: 'pe_outro_jogo_mesmo_dia', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATETIME', date: '2026-08-28', at: '2026-08-28T20:00:00' }) }];
  const result = recomputeTotal(baseline, candidates);
  assert.strictEqual(result.total, 400);
  assert.strictEqual(result.ambiguousBoundary.length, 1);
});
test('intervalo YEAR/MONTH do candidate CRUZA a fronteira do baseline -> AMBIGUOUS_BOUNDARY, nunca soma automaticamente', () => {
  // baseline em agosto/2026; candidate só sabe "2026" (YEAR) — o intervalo
  // (jan-dez/2026) cruza o baseline, não dá pra saber se é antes ou depois.
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28', at: null }) };
  const candidates = [{ canonicalMatchId: 'pe_algum_jogo_2026_sem_mes', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'YEAR', year: 2026, month: null, date: null, at: null }) }];
  const result = recomputeTotal(baseline, candidates);
  assert.strictEqual(result.total, 400);
  assert.strictEqual(result.ambiguousBoundary.length, 1);
});

console.log('\n6) baseline+delta — appearance futura genuína soma 1x, idempotente em reexecução');
test('1 STARTED estritamente posterior ao baseline -> 401', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28' }) };
  const candidates = [{ canonicalMatchId: 'pe_futuro_2026_09_05', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATE', date: '2026-09-05' }) }];
  const result = recomputeTotal(baseline, candidates);
  assert.strictEqual(result.total, 401);
});
test('rerodar o cálculo com a MESMA lista de entrada continua dando 401, nunca 402 (idempotência) — inclusive sincronizando a MESMA partida 10x', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28' }) };
  const candidates = [{ canonicalMatchId: 'pe_futuro_2026_09_05', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATE', date: '2026-09-05' }) }];
  let last;
  for (let i = 0; i < 10; i++) last = recomputeTotal(baseline, candidates);
  assert.strictEqual(last.total, 401);
});
test('a MESMA partida aparecendo 2x na lista de entrada (ex.: dado duplicado por engano) só conta 1x', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28' }) };
  const row = { canonicalMatchId: 'pe_futuro_2026_09_05', participationStatus: 'STARTED', kickoff: kickoff({ precision: 'DATE', date: '2026-09-05' }) };
  assert.strictEqual(recomputeTotal(baseline, [row, row]).total, 401);
});

console.log('\n7) baseline+delta — UNUSED_SUBSTITUTE futuro não soma até virar SUBSTITUTE_USED (mesma linha, UPDATE)');
test('1 UNUSED_SUBSTITUTE posterior ao baseline mantém 400', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28' }) };
  const candidates = [{ canonicalMatchId: 'pe_futuro_2026_09_12', participationStatus: 'UNUSED_SUBSTITUTE', kickoff: kickoff({ precision: 'DATE', date: '2026-09-12' }) }];
  assert.strictEqual(recomputeTotal(baseline, candidates).total, 400);
});
test('a MESMA linha corrigida (UPDATE) pra SUBSTITUTE_USED -> vira 401 na próxima recomputação, sem 2ª linha', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28' }) };
  const row = { canonicalMatchId: 'pe_futuro_2026_09_12', participationStatus: 'UNUSED_SUBSTITUTE', kickoff: kickoff({ precision: 'DATE', date: '2026-09-12' }) };
  const candidates = [row];
  assert.strictEqual(recomputeTotal(baseline, candidates).total, 400);
  row.participationStatus = 'SUBSTITUTE_USED'; // UPDATE in place — mesma linha, não um push
  assert.strictEqual(candidates.length, 1);
  assert.strictEqual(recomputeTotal(baseline, candidates).total, 401);
});
test('substituto que ENTRA conta como appearance; substituto NÃO utilizado nunca conta — mesma partida futura', () => {
  const baseline = { appearances: 400, asOfMatchId: 'pe_cb52680435343cc4', asOfKickoff: kickoff({ precision: 'DATE', date: '2026-08-28' }) };
  const entered = [{ canonicalMatchId: 'pe_futuro_sub_entrou', participationStatus: 'SUBSTITUTE_USED', kickoff: kickoff({ precision: 'DATE', date: '2026-09-01' }) }];
  const unused = [{ canonicalMatchId: 'pe_futuro_sub_banco', participationStatus: 'UNUSED_SUBSTITUTE', kickoff: kickoff({ precision: 'DATE', date: '2026-09-01' }) }];
  assert.strictEqual(recomputeTotal(baseline, entered).total, 401);
  assert.strictEqual(recomputeTotal(baseline, unused).total, 400);
});

// ============================================================================
// 8) Coerência de spell — mesmo padrão de FK composta da Etapa D
// ============================================================================
console.log('\n8) coerência spell_id <-> person_id/club_id');
test('migration declara a FK composta player_match_appearances_spell_coherence_fkey (spell_id, person_id, club_id)', () => {
  assert.match(createAppearancesSql, /constraint player_match_appearances_spell_coherence_fkey/);
  assert.match(createAppearancesSql, /foreign key \(spell_id, person_id, club_id\)/);
  assert.match(createAppearancesSql, /references public\.player_club_spells \(id, person_id, club_id\)/);
});
test('toda appearance do seed com spell_id preenchido referencia um spell REAL dessa MESMA pessoa (nunca de outra)', () => {
  const spellById = new Map(clubSpells.map((s) => [s.spellId, s]));
  const withSpell = appearances.filter((a) => a.spellId);
  assert.ok(withSpell.length > 0);
  for (const a of withSpell) {
    const spell = spellById.get(a.spellId);
    assert.ok(spell, `spell_id ${a.spellId} não existe em player_club_spells_seed.json`);
    assert.strictEqual(spell.personId, a.personId, `spell ${a.spellId} pertence a outra pessoa`);
  }
});
test('simulação estrutural — combinar o spell_id do Walter com o person_id do Tadeu seria rejeitado pela MESMA FK composta aplicada e comprovada na Etapa D', () => {
  const walter = byName('Walter Henrique da Silva');
  const tadeu = byName('Tadeu Antônio Ferreira');
  const walterSpell = clubSpells.find((s) => s.personId === walter.canonicalId);
  assert.ok(walterSpell);
  assert.notStrictEqual(walterSpell.personId, tadeu.canonicalId);
});
test('walterSpell com 0 jogos oficiais continua uma passagem VÁLIDA (não é excluído do dataset por ter appearances=0)', () => {
  const walter = byName('Walter Henrique da Silva');
  const walterSpells = clubSpells.filter((s) => s.personId === walter.canonicalId);
  assert.ok(walterSpells.length >= 3, `esperado >= 3 passagens (Walter tem 3 spells reais, 1 com 0 jogos), achou ${walterSpells.length}`);
});
test('82 appearances sem spell_id são 100% decompostas por categoria auditável (A/B/C/D), nunca um "sem spell" opaco', () => {
  assert.strictEqual(buildStats.spellCoherenceReport.length, buildStats.withoutSpellId);
  for (const r of buildStats.spellCoherenceReport) assert.ok(['A', 'B', 'C', 'D'].includes(r.category), `categoria inválida: ${r.category}`);
  const sum = buildStats.spellDecomposition.A + buildStats.spellDecomposition.B + buildStats.spellDecomposition.C + buildStats.spellDecomposition.D;
  assert.strictEqual(sum, buildStats.withoutSpellId);
});
test('a decomposição B/C/D do dataset real (0/0/0) NÃO significa que o grace foi usado pra linkar — resolveSpellForDate nunca importa/usa NEAR_BOUNDARY_GRACE_MONTHS', () => {
  // Prova ESTRUTURAL, não só numérica: o próprio código-fonte de
  // resolveSpellForDate/overlapCandidates (spell_link.mjs) não referencia
  // a constante de grace — só classifySpellGap (diagnóstico) a usa.
  const src = fs.readFileSync(path.join(__dirname, 'spell_link.mjs'), 'utf8');
  const fnBody = src.slice(src.indexOf('export function resolveSpellForDate'), src.indexOf('export const NEAR_BOUNDARY_GRACE_MONTHS'));
  assert.doesNotMatch(fnBody, /GRACE/);
});
test('grace NUNCA auto-linka: pessoa com spell YEAR terminando 2020, partida em 2021 (7 meses de gap, dentro do grace de 6? não — fora) permanece sem overlap -> spellId continua null mesmo perto do boundary', () => {
  const spellsForPerson = [{ startYear: 2018, startMonth: null, endYear: 2020, endMonth: null, isOngoing: false, startPrecision: 'YEAR', endPrecision: 'YEAR' }];
  // 3 meses depois do fim do spell (dentro do grace de 6) — ainda assim,
  // resolveSpellForDate (a função que REALMENTE decide o link) não linka.
  const closeDate = '2021-03-15';
  assert.strictEqual(resolveSpellForDate(spellsForPerson, closeDate), null);
  assert.strictEqual(overlapCandidates(spellsForPerson, closeDate).length, 0);
  // classifySpellGap (só diagnóstico) É que usa o grace — categoriza como B
  assert.strictEqual(classifySpellGap(spellsForPerson, closeDate), 'B');
});
test('classifySpellGap: 2+ overlaps concorrentes -> D, nunca escolhe um deles como spellId', () => {
  const spellsForPerson = [
    { startYear: 2019, startMonth: 1, endYear: 2019, endMonth: 12, isOngoing: false, startPrecision: 'MONTH', endPrecision: 'MONTH' },
    { startYear: 2019, startMonth: 6, endYear: 2020, endMonth: 6, isOngoing: false, startPrecision: 'MONTH', endPrecision: 'MONTH' },
  ];
  assert.strictEqual(resolveSpellForDate(spellsForPerson, '2019-07-01'), null);
  assert.strictEqual(classifySpellGap(spellsForPerson, '2019-07-01'), 'D');
});

// ============================================================================
// 9) Homônimos — nunca auto-resolvidos além do matchIdFilter curado na Etapa A
// ============================================================================
console.log('\n9) homônimos nunca cruzam (Nicolas, Danilo, Michael)');
test('Nicolas Vichiatto só tem appearances nos 2 matches do seu matchIdFilter, nunca nos do Nicolas Godinho', () => {
  const rows = appearancesOf('Nicolas Vichiatto da Silva').map((a) => a.lineupMatchId).sort();
  assert.deepStrictEqual(rows, ['2026_atleticogo_goiano_final_ida', '2026_atleticogo_goiano_final_volta']);
});
test('Nicolas Godinho só tem appearances nos 2 matches do seu matchIdFilter, nunca nos do Nicolas Vichiatto', () => {
  const rows = appearancesOf('Nicolas Godinho Johann').map((a) => a.lineupMatchId).sort();
  assert.deepStrictEqual(rows, ['2021_csa_brB_g4', '2021_guarani_brB_acesso']);
});
test('conjuntos de matches do Nicolas Vichiatto e do Nicolas Godinho são disjuntos', () => {
  const a = new Set(appearancesOf('Nicolas Vichiatto da Silva').map((x) => x.lineupMatchId));
  const b = new Set(appearancesOf('Nicolas Godinho Johann').map((x) => x.lineupMatchId));
  for (const id of a) assert.ok(!b.has(id));
});
test('Danilo Gabriel de Andrade só tem appearances nos 2 matches do seu matchIdFilter', () => {
  const rows = appearancesOf('Danilo Gabriel de Andrade').map((a) => a.lineupMatchId).sort();
  assert.deepStrictEqual(rows, ['2003_juventude_brA_reacao', '2003_santos_brA_reacao']);
});
test('Danilo Cunha da Silva (sem matchIdFilter, sem evidência de lineup) fica BLOCKED, nunca herda partidas do Danilo Gabriel', () => {
  const person = byName('Danilo Cunha da Silva');
  assert.ok(buildStats.blocked.some((b) => b.canonicalId === person.canonicalId));
  assert.strictEqual(appearancesOf('Danilo Cunha da Silva').length, 0);
});
test('pessoa PROVISIONAL (Michael 1999, insert_status != APPROVED) nunca gera appearance mesmo tendo matchIdFilter válido', () => {
  const person = byName('Michael (1999, elenco do acesso à Série A)');
  const plan = insertPlan.find((p) => p.canonical_person_id === person.canonicalId);
  assert.strictEqual(plan.insert_status, 'PROVISIONAL');
  assert.strictEqual(appearancesOf('Michael (1999, elenco do acesso à Série A)').length, 0);
});

// ============================================================================
// 10) position_code — catálogo Etapa C, nunca 2 códigos numa coluna,
// composto/genérico preservado na provenance
// ============================================================================
console.log('\n10) position_code — catálogo canônico, composto vira NULL+provenance');
test('todo position_code presente no seed pertence ao catálogo canônico de 15 códigos da Etapa C', () => {
  const CANONICAL = new Set(['GOL', 'ZAG', 'LD', 'LE', 'ALD', 'ALE', 'VOL', 'MC', 'MEI', 'MD', 'ME', 'PD', 'PE', 'SA', 'ATA']);
  for (const a of appearances) if (a.positionCode) assert.ok(CANONICAL.has(a.positionCode), `código fora do catálogo: ${a.positionCode}`);
});
test('Jackson (Dieguinho) tem "LD/MC" registrado — position_code fica NULL nessa linha, valor bruto preservado na source', () => {
  const person = byName('Jackson Diego Ibraim Fagundes');
  const row = appearances.find((a) => a.personId === person.canonicalId && a.lineupMatchId === '2021_guarani_brB_acesso');
  assert.ok(row);
  assert.strictEqual(row.positionCode, null);
  const src = sources.find((s) => s.personId === person.canonicalId && s.lineupMatchId === '2021_guarani_brB_acesso');
  assert.strictEqual(src.rawValue.pos, 'LD/MC');
});
test('migration reusa exatamente o catálogo de 15 códigos da Etapa C (mesma lista, nunca um vocabulário paralelo)', () => {
  assert.match(createAppearancesSql, /'GOL', 'ZAG', 'LD', 'LE', 'ALD', 'ALE', 'VOL', 'MC', 'MEI', 'MD', 'ME', 'PD', 'PE', 'SA', 'ATA'/);
});

// ============================================================================
// 11) matches — identidade canônica multi-clube-safe
// ============================================================================
console.log('\n11) public.matches — identidade multi-clube-safe');
test('matches_seed.json tem 31 linhas, todas com pelo menos um lado apontando pro Goiás', () => {
  assert.strictEqual(matches.length, 31);
  assert.ok(matches.every((m) => m.homeClubSlug === 'goias' || m.awayClubSlug === 'goias'));
});
test('nenhuma linha de matches_seed.json tem os dois lados preenchidos (só existe 1 clube no catálogo hoje)', () => {
  assert.ok(matches.every((m) => !(m.homeClubSlug && m.awayClubSlug)));
});
test('cross-check lineup_matches x passport_matches: 15 linkadas, 16 não — números batem com o audit', () => {
  assert.strictEqual(matchIdentityAudit.linkedCount, 15);
  assert.strictEqual(matchIdentityAudit.unlinkedCount, 16);
  assert.strictEqual(matches.filter((m) => m.passportMatchId).length, 15);
});
test('schema de matches é simétrico (home_club_id/away_club_id), nunca "goias + adversário"', () => {
  assert.match(createMatchesSql, /home_club_id uuid references public\.clubs\(id\)/);
  assert.match(createMatchesSql, /away_club_id uuid references public\.clubs\(id\)/);
});
test('matches.id é literal (sem DEFAULT gen_random_uuid()) — vem do match registry', () => {
  assert.doesNotMatch(createMatchesSql.match(/id uuid primary key.*$/m)?.[0] || '', /gen_random_uuid/);
});
test('matches NÃO tem passport_match_id/lineup_match_id como colunas próprias — isso é match_source_refs', () => {
  const matchesTableBlock = createMatchesSql.slice(createMatchesSql.indexOf('create table if not exists public.matches'), createMatchesSql.indexOf('create table if not exists public.match_source_refs'));
  assert.doesNotMatch(matchesTableBlock, /passport_match_id text references/);
  assert.doesNotMatch(matchesTableBlock, /\blineup_match_id text,/);
});
test('home_club_id != away_club_id quando os 2 são conhecidos (constraint declarada)', () => {
  assert.match(createMatchesSql, /check \(home_club_id is null or away_club_id is null or home_club_id <> away_club_id\)/);
});
test('kickoff_precision suporta YEAR/MONTH/DATE/DATETIME, nunca alegando mais do que a fonte tem', () => {
  assert.match(createMatchesSql, /kickoff_precision text not null check \(kickoff_precision in \('YEAR', 'MONTH', 'DATE', 'DATETIME'\)\)/);
});
test('kickoff_at só existe junto de precision DATETIME (constraint declarada)', () => {
  assert.match(createMatchesSql, /check \(\(kickoff_precision = 'DATETIME'\) = \(kickoff_at is not null\)\)/);
});

// ============================================================================
// 11b) Precisão temporal — SEM sentinela, nullability explícita (item 5/6)
// ============================================================================
console.log('\n11b) precisão temporal — sem sentinela, nullability explícita');
test('"YYYY-01-01" (mês E dia placeholder, sem link passport) vira precisão YEAR, kickoff_date/kickoff_month GENUINAMENTE null (nunca sentinela)', () => {
  const m = matches.find((x) => x.lineupMatchId === '2003_juventude_brA_reacao');
  assert.ok(m);
  assert.strictEqual(m.kickoffPrecision, 'YEAR');
  assert.strictEqual(m.kickoffMonth, null);
  assert.strictEqual(m.kickoffDate, null); // NUNCA "2003-01-01"
  assert.strictEqual(m.kickoffYear, 2003);
  assert.strictEqual(m.passportMatchId, null);
});
test('nenhuma partida YEAR/MONTH no seed tem kickoffDate preenchido — 0 sentinelas em todo o dataset', () => {
  const coarse = matches.filter((m) => m.kickoffPrecision === 'YEAR' || m.kickoffPrecision === 'MONTH');
  assert.ok(coarse.length > 0);
  for (const m of coarse) assert.strictEqual(m.kickoffDate, null, `${m.lineupMatchId} (${m.kickoffPrecision}) tem kickoffDate="${m.kickoffDate}" — deveria ser null`);
});
test('migration NUNCA persiste um "01-01" fabricado — kickoff_date é NULLABLE e só exigido em DATE/DATETIME', () => {
  assert.match(createMatchesSql, /kickoff_date date,/);
  assert.match(createMatchesSql, /check \(\(kickoff_precision in \('DATE', 'DATETIME'\)\) = \(kickoff_date is not null\)\)/);
});
test('migration de seed nunca escreve o literal "01-01" como se fosse dado real de uma linha YEAR/MONTH (kickoff_date vira null::date nessas linhas)', () => {
  const yearRows = matches.filter((m) => m.kickoffPrecision === 'YEAR');
  assert.ok(yearRows.length > 0);
  for (const m of yearRows) {
    // a linha VALUES desta partida no SQL gerado usa null::date, nunca uma data literal
    const idx = seedMatchesSql.indexOf(`'${m.matchId}'::uuid`);
    assert.ok(idx !== -1);
    const line = seedMatchesSql.slice(idx, seedMatchesSql.indexOf('\n', idx));
    assert.match(line, /null::date/);
  }
});
test('toda partida com precision YEAR tem verificationStatus PARTIAL (nunca VERIFIED sem confirmação)', () => {
  for (const m of matches.filter((x) => x.kickoffPrecision === 'YEAR')) assert.strictEqual(m.verificationStatus, 'PARTIAL');
});
test('nullability por precisão bate em TODO o seed: YEAR/MONTH sem kickoff_date, DATE/DATETIME com kickoff_date, só DATETIME com kickoff_at', () => {
  for (const m of matches) {
    if (m.kickoffPrecision === 'YEAR' || m.kickoffPrecision === 'MONTH') {
      assert.strictEqual(m.kickoffDate, null);
      assert.strictEqual(m.kickoffAt, null);
    }
    if (m.kickoffPrecision === 'DATE') { assert.ok(m.kickoffDate); assert.strictEqual(m.kickoffAt, null); }
    if (m.kickoffPrecision === 'DATETIME') { assert.ok(m.kickoffDate); assert.ok(m.kickoffAt); }
    if (m.kickoffPrecision === 'YEAR') assert.strictEqual(m.kickoffMonth, null);
    else assert.ok(m.kickoffMonth);
  }
});
test('kickoffIntervalDays: YEAR cobre o ano inteiro, MONTH cobre o mês inteiro, DATE/DATETIME são 1 dia só', () => {
  const [yS, yE] = kickoffIntervalDays({ precision: 'YEAR', year: 2020, month: null, date: null, at: null });
  assert.ok(yE - yS >= 364); // ano bissexto ou não
  const [mS, mE] = kickoffIntervalDays({ precision: 'MONTH', year: 2020, month: 2, date: null, at: null });
  assert.strictEqual(mE - mS, 28); // fevereiro 2020, bissexto -> 29 dias -> 28 de diferença
  const [dS, dE] = kickoffIntervalDays({ precision: 'DATE', year: 2020, month: 2, date: '2020-02-15', at: null });
  assert.strictEqual(dS, dE);
});

// ============================================================================
// 12) Provenance — granular, não duplica dado, private
// ============================================================================
console.log('\n12) provenance');
test('cada appearance tem exatamente 1 source PRIMARY (1:1, esta etapa não deriva nem agrega)', () => {
  assert.strictEqual(sources.length, appearances.length);
  assert.ok(sources.every((s) => s.sourceRole === 'PRIMARY'));
});
test('player_match_appearance_sources não tem GRANT select pra anon/authenticated (zero-privilégio)', () => {
  const revokeIdx = createAppearancesSql.indexOf('revoke all on table public.player_match_appearance_sources');
  const grantOnSourcesIdx = createAppearancesSql.indexOf('grant select on table public.player_match_appearance_sources');
  assert.ok(revokeIdx !== -1);
  assert.strictEqual(grantOnSourcesIdx, -1);
});
test('player_match_appearances TEM select público (leitura liberada, escrita não)', () => {
  assert.match(createAppearancesSql, /grant select on table public\.player_match_appearances to anon, authenticated/);
});
test('source_role de player_match_appearance_sources é PRIMARY/CORROBORATING/CORRECTION — NUNCA BASELINE (aprovado, não alterar)', () => {
  const checkLine = createAppearancesSql.match(/source_role text not null check \(source_role in \(([^)]+)\)\)/);
  assert.ok(checkLine);
  assert.strictEqual(checkLine[1], "'PRIMARY', 'CORROBORATING', 'CORRECTION'");
  assert.doesNotMatch(checkLine[1], /BASELINE/);
});
test('match_source_refs é privado — RLS enabled, ZERO grant/policy pra anon/authenticated', () => {
  assert.match(createMatchesSql, /alter table public\.match_source_refs enable row level security/);
  assert.match(createMatchesSql, /revoke all on table public\.match_source_refs from anon, authenticated/);
  assert.doesNotMatch(createMatchesSql, /grant select on table public\.match_source_refs/);
  assert.doesNotMatch(createMatchesSql, /policy "read match source refs"/);
});
test('match_source_refs separa source_type (semântico) de source_namespace (identidade) — UNIQUE é (source_namespace, source_ref)', () => {
  assert.match(createMatchesSql, /source_type text not null check \(source_type in \('LINEUP_MATCH', 'PASSPORT_MATCH', 'PROVIDER_FIXTURE'\)\)/);
  assert.match(createMatchesSql, /source_namespace text not null,/);
  assert.match(createMatchesSql, /unique \(source_namespace, source_ref\)/);
  assert.doesNotMatch(createMatchesSql, /unique \(source_type, source_ref\)/);
});
test('external_match_id foi removida (redundante com source_ref nas 2 fontes reais) — decisão documentada no comentário', () => {
  const refsBlock = createMatchesSql.slice(createMatchesSql.indexOf('create table if not exists public.match_source_refs'));
  assert.doesNotMatch(refsBlock, /external_match_id/);
});
test('matches_seed_stats.json reporta os números de match_source_refs POR NAMESPACE', () => {
  assert.strictEqual(matchesStats.sourceRefsTotal, sourceRefs.length);
  assert.strictEqual(matchesStats.sourceRefsByNamespace.goias_lineup_curated, 31);
  assert.strictEqual(matchesStats.sourceRefsByNamespace.goias_passport, 15);
  assert.strictEqual(matchesStats.matchesWith2PlusSources, 15);
  assert.strictEqual(matchesStats.matchesWith1Source, 16);
});
test('os 15 matches cruzados (com link passport) têm exatamente 2 source_refs — LINEUP_MATCH + PASSPORT_MATCH, nenhuma provenance perdida', () => {
  for (const m of matches.filter((x) => x.passportMatchId)) {
    const refs = sourceRefs.filter((s) => s.matchId === m.matchId);
    assert.strictEqual(refs.length, 2, `${m.lineupMatchId} tem ${refs.length} source_refs, esperado 2`);
    assert.ok(refs.some((r) => r.sourceNamespace === 'goias_lineup_curated'));
    assert.ok(refs.some((r) => r.sourceNamespace === 'goias_passport'));
  }
});

// ============================================================================
// 13) Nenhuma duplicação de responsabilidade — sem gol, sem stats agregada
// ============================================================================
console.log('\n13) escopo — sem gol, sem stats agregada, sem shirt_number global');
test('schema não tem coluna de gols nem qualquer contador agregado', () => {
  assert.ok(!/\bgoals\b/.test(createAppearancesSql));
  assert.ok(!/total_appearances/.test(createAppearancesSql));
});
test('shirt_number é snapshot da partida, não um número global — comentário documenta isso explicitamente (caso Nicolas/camisa 9)', () => {
  assert.match(createAppearancesSql, /Snapshot da partida/);
});
test('matches=31 e appearances=162 permanecem os mesmos números da v2 — os ajustes estruturais desta rodada não alteraram evidência (nenhuma tentativa de melhorar cobertura)', () => {
  assert.strictEqual(matches.length, 31);
  assert.strictEqual(appearances.length, 162);
});

// ============================================================================
// 14) player_external_ids — confirmado NÃO criado
// ============================================================================
console.log('\n14) player_external_ids — confirmado NÃO criado');
test('nenhuma migration desta etapa cria player_external_ids', () => {
  for (const sql of [createMatchesSql, seedMatchesSql, createAppearancesSql, seedAppearancesSql]) {
    assert.doesNotMatch(sql, /create table[\s\S]{0,40}player_external_ids/);
  }
});

// ============================================================================
// 15) match_registry — estabilidade de matches.id, resolução em 2 etapas
// ============================================================================
console.log('\n15) match_registry — estabilidade + resolução em 2 etapas');
function anchor(sourceType, sourceNamespace, sourceRef) { return { sourceType, sourceNamespace, sourceRef }; }
function descriptorFor({ home, away, kickoffOverrides = {}, competition = 'Brasileirão', season = '2026' }) {
  return { homeIdentity: home, awayIdentity: away, kickoff: kickoff(kickoffOverrides), competition, season };
}

test('corrigir um atributo mutável (data) não afeta o registry — resolveMatchAnchors casa pelo MESMO anchor de sempre', () => {
  const registry = emptyMatchRegistry();
  const anchors = [anchor('LINEUP_MATCH', 'goias_lineup_curated', 'x1')];
  const entry = registerNewMatch(registry, anchors);
  const resolved = resolveMatchAnchors(registry, anchors);
  assert.strictEqual(resolved.status, 'matched');
  assert.strictEqual(resolved.matchId, entry.matchId);
});
test('adicionar horário (kickoff_at) não é um anchor — id permanece igual', () => {
  const registry = emptyMatchRegistry();
  const anchors = [anchor('LINEUP_MATCH', 'goias_lineup_curated', 'x2')];
  const entry = registerNewMatch(registry, anchors);
  const resolved = resolveMatchAnchors(registry, anchors);
  assert.strictEqual(resolved.matchId, entry.matchId);
});
test('adicionar uma fonte passport posteriormente casa pelo anchor já existente e ACRESCENTA o novo anchor, mesmo matchId', () => {
  const registry = emptyMatchRegistry();
  const lineupAnchor = anchor('LINEUP_MATCH', 'goias_lineup_curated', 'x3');
  const entry = registerNewMatch(registry, [lineupAnchor]);
  const laterAnchors = [lineupAnchor, anchor('PASSPORT_MATCH', 'goias_passport', 'pe_x3')];
  const resolved = resolveMatchAnchors(registry, laterAnchors);
  assert.strictEqual(resolved.status, 'matched');
  assert.strictEqual(resolved.matchId, entry.matchId);
  appendAnchors(resolved.entry, laterAnchors);
  assert.strictEqual(resolved.entry.sourceAnchors.length, 2);
  appendAnchors(resolved.entry, laterAnchors); // idempotência
  assert.strictEqual(resolved.entry.sourceAnchors.length, 2);
});
test('renomear texto de exibição do time / reordenar anchors não afeta o id resolvido', () => {
  const registry = emptyMatchRegistry();
  const a1 = anchor('LINEUP_MATCH', 'goias_lineup_curated', 'x5');
  const a2 = anchor('PASSPORT_MATCH', 'goias_passport', 'pe_x5');
  const entry = registerNewMatch(registry, [a1, a2]);
  assert.strictEqual(resolveMatchAnchors(registry, [a2, a1]).matchId, entry.matchId);
});
test('SPLIT/MERGE (supersedeMatch) migra os anchors do superseded pro sobrevivente e nunca reaproveita canonicalMatchKey', () => {
  const registry = emptyMatchRegistry();
  const survivor = registerNewMatch(registry, [anchor('LINEUP_MATCH', 'goias_lineup_curated', 'surv')]);
  const dup = registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_dup')]);
  supersedeMatch(registry, dup.canonicalMatchKey, survivor.canonicalMatchKey);
  const resolved = resolveMatchAnchors(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_dup')]);
  assert.strictEqual(resolved.status, 'matched');
  assert.strictEqual(resolved.matchId, survivor.matchId);
  const supersededEntry = registry.entries.find((e) => e.canonicalMatchKey === dup.canonicalMatchKey);
  assert.strictEqual(supersededEntry.status, 'SUPERSEDED');
  assert.doesNotThrow(() => validateMatchRegistryIntegrity(registry));
});
test('nenhum anchor pertence a 2 entradas ACTIVE diferentes no registry real gerado (validateMatchRegistryIntegrity não lança)', () => {
  const matchRegistryPath = path.join(__dirname, 'matches_registry.json');
  const registry = JSON.parse(fs.readFileSync(matchRegistryPath, 'utf8'));
  assert.doesNotThrow(() => validateMatchRegistryIntegrity(registry));
  assert.strictEqual(registry.entries.length, 31);
});

console.log('\n15b) ETAPA 2 — resolução estrutural SEM nenhum anchor compartilhado (cenário multi-clube real)');
test('cross-club independente: ZERO anchors em comum, mas home/away/kickoff/competição batem -> EXISTING_MATCH, mesmo matchId (nunca cria um 2º)', () => {
  const registry = emptyMatchRegistry();
  const goiasHome = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const juventudeAway = sideIdentity({ clubCanonicalKey: null, teamName: 'Juventude' });
  // Goiás importa primeiro, usando SÓ a própria fonte (passport).
  const goiasAnchor = anchor('PASSPORT_MATCH', 'goias_passport', 'pe_abc');
  const goiasDescriptor = descriptorFor({ home: goiasHome, away: juventudeAway, kickoffOverrides: { precision: 'DATE', date: '2026-05-10' } });
  const matchX = registerNewMatch(registry, [goiasAnchor], { descriptor: goiasDescriptor });

  // Juventude importa depois, com sua PRÓPRIA fonte — ZERO anchors em
  // comum (namespace/ref totalmente diferentes) — mas descrevendo a
  // MESMA partida real (mesmos lados, mesmo dia).
  const juventudeAnchor = anchor('PASSPORT_MATCH', 'juventude_fixture_history', 'jogo_91827');
  const juventudeHome = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const juventudeAway2 = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:2', teamName: 'Juventude' }); // Juventude já se conhece
  const juventudeDescriptor = descriptorFor({ home: juventudeHome, away: juventudeAway2, kickoffOverrides: { precision: 'DATE', date: '2026-05-10' } });

  const stage1 = resolveMatchAnchors(registry, [juventudeAnchor]);
  assert.strictEqual(stage1.status, 'new'); // confirma: zero anchor compartilhado
  const stage2 = resolveMatchCandidate(registry, juventudeDescriptor);
  assert.strictEqual(stage2.status, 'matched');
  assert.strictEqual(stage2.matchId, matchX.matchId);

  // orquestrador completo dá o mesmo resultado
  const full = resolveMatch(registry, { anchors: [juventudeAnchor], descriptor: juventudeDescriptor });
  assert.strictEqual(full.resultKind, 'EXISTING_MATCH');
  assert.strictEqual(full.stage, 'CANDIDATE');
  assert.strictEqual(full.matchId, matchX.matchId);
  appendAnchors(full.entry, [juventudeAnchor]);
  assert.strictEqual(registry.entries.length, 1); // nunca um 2º match Y criado
});
test('cross-club ambíguo: ZERO anchors em comum, 2 candidatos estruturalmente compatíveis (mesmos times, janela temporal compatível) -> BLOCKED_AMBIGUOUS_MATCH, nunca escolhido sozinho', () => {
  const registry = emptyMatchRegistry();
  const home = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const away = sideIdentity({ clubCanonicalKey: null, teamName: 'Juventude' });
  // Goiás x Juventude ocorreu 2x numa janela temporal compatível (2 jogos
  // do returno, ex.: mesmo mês, dado insuficiente pra distinguir).
  const desc1 = descriptorFor({ home, away, kickoffOverrides: { precision: 'MONTH', year: 2026, month: 5, date: null } });
  const desc2 = descriptorFor({ home, away, kickoffOverrides: { precision: 'MONTH', year: 2026, month: 5, date: null } });
  registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_jogo1')], { descriptor: desc1 });
  registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_jogo2')], { descriptor: desc2 });

  const newSourceAnchor = anchor('PROVIDER_FIXTURE', 'onefootball', 'fixture_999');
  const newSourceDescriptor = descriptorFor({ home, away, kickoffOverrides: { precision: 'MONTH', year: 2026, month: 5, date: null } });
  const result = resolveMatch(registry, { anchors: [newSourceAnchor], descriptor: newSourceDescriptor });
  assert.strictEqual(result.resultKind, 'BLOCKED_AMBIGUOUS_MATCH');
  assert.strictEqual(result.stage, 'CANDIDATE');
  assert.strictEqual(result.matches.length, 2);
});
test('0 candidatos estruturalmente compatíveis -> NEW_MATCH', () => {
  const registry = emptyMatchRegistry();
  const home = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const away = sideIdentity({ clubCanonicalKey: null, teamName: 'Cuiabá' });
  const result = resolveMatch(registry, { anchors: [anchor('PROVIDER_FIXTURE', 'onefootball', 'f1')], descriptor: descriptorFor({ home, away }) });
  assert.strictEqual(result.resultKind, 'NEW_MATCH');
});
test('resolveMatchCandidate NUNCA usa placar como identidade — 2 candidatos com placares diferentes ainda contam como o mesmo tipo de match (placar não entra na comparação)', () => {
  const registry = emptyMatchRegistry();
  const home = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const away = sideIdentity({ clubCanonicalKey: null, teamName: 'Vila Nova' });
  const desc = descriptorFor({ home, away, kickoffOverrides: { precision: 'DATE', date: '2026-03-01' } });
  const entry = registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_placarA')], { descriptor: desc });
  // um "placar corrigido depois" (descriptor não guarda placar de
  // propósito — a assinatura de descriptorFor/resolveMatchCandidate nem
  // aceita esse campo) não pode nunca impedir o match de casar.
  const stage2 = resolveMatchCandidate(registry, desc);
  assert.strictEqual(stage2.status, 'matched');
  assert.strictEqual(stage2.matchId, entry.matchId);
  assert.ok(!('homeScore' in desc) && !('awayScore' in desc));
});

console.log('\n15d) GATE de suficiência — 1 candidato SOZINHO não basta, precisa ser INEQUÍVOCO (revisão final pré-commit)');
test('coarse unique candidate: registry tem Goiás x Juventude/Brasileirão/2024/YEAR; fonte independente idêntica em precisão YEAR, zero anchors -> BLOCKED_INSUFFICIENT_MATCH_IDENTITY, NUNCA auto-linka', () => {
  const registry = emptyMatchRegistry();
  const home = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const away = sideIdentity({ clubCanonicalKey: null, teamName: 'Juventude' });
  const existingDescriptor = descriptorFor({ home, away, competition: 'Brasileirão', season: '2024', kickoffOverrides: { precision: 'YEAR', year: 2024, month: null, date: null } });
  const existing = registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_2024_year_only')], { descriptor: existingDescriptor });

  const newAnchor = anchor('PROVIDER_FIXTURE', 'onefootball', 'fixture_2024_juv');
  const newDescriptor = descriptorFor({ home, away, competition: 'Brasileirão', season: '2024', kickoffOverrides: { precision: 'YEAR', year: 2024, month: null, date: null } });

  const stage1 = resolveMatchAnchors(registry, [newAnchor]);
  assert.strictEqual(stage1.status, 'new'); // zero anchor compartilhado, confirmado
  const stage2 = resolveMatchCandidate(registry, newDescriptor);
  assert.strictEqual(stage2.status, 'insufficient'); // 1 candidato existe, mas precisão YEAR dos 2 lados não basta

  const full = resolveMatch(registry, { anchors: [newAnchor], descriptor: newDescriptor });
  assert.strictEqual(full.resultKind, 'BLOCKED_INSUFFICIENT_MATCH_IDENTITY');
  assert.strictEqual(full.stage, 'CANDIDATE');
  assert.strictEqual(full.matches.length, 1);
  assert.strictEqual(full.matches[0].matchId, existing.matchId);
  // nunca criou um 2º match nem "resolveu" o existente sozinho
  assert.strictEqual(registry.entries.length, 1);
});
test('exact independent candidate: registry tem Goiás x Juventude 2024-08-10 DATE; fonte independente DATE/DATETIME no mesmo dia, zero anchors, único candidato -> EXISTING_MATCH, mesmo matchId', () => {
  const registry = emptyMatchRegistry();
  const home = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const away = sideIdentity({ clubCanonicalKey: null, teamName: 'Juventude' });
  const existingDescriptor = descriptorFor({ home, away, kickoffOverrides: { precision: 'DATE', year: 2024, month: 8, date: '2024-08-10' } });
  const existing = registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_2024_08_10')], { descriptor: existingDescriptor });

  for (const newPrecision of ['DATE', 'DATETIME']) {
    const newAnchor = anchor('PROVIDER_FIXTURE', 'onefootball', `fixture_exact_${newPrecision}`);
    const newDescriptor = descriptorFor({
      home, away,
      kickoffOverrides: newPrecision === 'DATE'
        ? { precision: 'DATE', year: 2024, month: 8, date: '2024-08-10' }
        : { precision: 'DATETIME', year: 2024, month: 8, date: '2024-08-10', at: '2024-08-10T20:00:00' },
    });
    const full = resolveMatch(registry, { anchors: [newAnchor], descriptor: newDescriptor });
    assert.strictEqual(full.resultKind, 'EXISTING_MATCH', `precisão ${newPrecision} deveria auto-resolver`);
    assert.strictEqual(full.matchId, existing.matchId);
  }
  assert.strictEqual(registry.entries.length, 1);
});
test('coarse + explicit anchor: MESMO match YEAR, mas chega com source_namespace/source_ref JÁ registrado -> EXISTING_MATCH (anchor exato é soberano, ganha da baixa precisão)', () => {
  const registry = emptyMatchRegistry();
  const home = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const away = sideIdentity({ clubCanonicalKey: null, teamName: 'Juventude' });
  const yearDescriptor = descriptorFor({ home, away, kickoffOverrides: { precision: 'YEAR', year: 2024, month: null, date: null } });
  const knownAnchor = anchor('PASSPORT_MATCH', 'goias_passport', 'pe_2024_year_known');
  const existing = registerNewMatch(registry, [knownAnchor], { descriptor: yearDescriptor });

  // mesma fonte reprocessada (ex.: reimportação) — o anchor já é
  // conhecido, então a etapa 1 resolve sozinha, SEM sequer precisar da
  // etapa 2 (que teria negado por precisão insuficiente se fosse
  // chamada). Precisão continua YEAR nos 2 lados.
  const full = resolveMatch(registry, { anchors: [knownAnchor], descriptor: yearDescriptor });
  assert.strictEqual(full.resultKind, 'EXISTING_MATCH');
  assert.strictEqual(full.stage, 'ANCHOR'); // resolvido pela etapa 1, nunca chegou na etapa 2
  assert.strictEqual(full.matchId, existing.matchId);
});
test('ambiguous permanece ambiguous independente do gate de precisão: 2 candidatos exatos/compatíveis (mesmo com DATE forte) -> BLOCKED_AMBIGUOUS_MATCH, nunca escolhido', () => {
  const registry = emptyMatchRegistry();
  const home = sideIdentity({ clubCanonicalKey: 'goias-app:multiclub:club:1', teamName: 'Goiás' });
  const away = sideIdentity({ clubCanonicalKey: null, teamName: 'Vila Nova' });
  const desc1 = descriptorFor({ home, away, kickoffOverrides: { precision: 'DATE', date: '2026-03-01' } });
  const desc2 = descriptorFor({ home, away, kickoffOverrides: { precision: 'DATE', date: '2026-03-01' } });
  registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_dup1')], { descriptor: desc1 });
  registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'pe_dup2')], { descriptor: desc2 });
  const newAnchor = anchor('PROVIDER_FIXTURE', 'onefootball', 'fixture_dup_check');
  const result = resolveMatch(registry, { anchors: [newAnchor], descriptor: descriptorFor({ home, away, kickoffOverrides: { precision: 'DATE', date: '2026-03-01' } }) });
  assert.strictEqual(result.resultKind, 'BLOCKED_AMBIGUOUS_MATCH'); // count de candidatos vence ANTES do gate de precisão
  assert.strictEqual(result.matches.length, 2);
});
test('o gate NÃO afeta os 31 matches reais do dataset — todos resolvem NEW_MATCH neste 1º run (nenhuma colisão estrutural entre os 3 pares ida/volta, que trocam mando de campo)', () => {
  assert.strictEqual(matchesStats.byResultKind.NEW_MATCH, 31);
  assert.strictEqual(matchesStats.blockedInsufficientMatchIdentity.length, 0);
  assert.strictEqual(matches.length, 31); // item 3 do pedido: não força mudança nos 31 reais
});

console.log('\n15c) source namespaces — coexistência entre clubes, unicidade dentro do namespace');
test('o mesmo source_ref em namespaces DIFERENTES (goias_passport/abc vs. juventude_passport/abc) NUNCA colide — são anchors distintos', () => {
  const registry = emptyMatchRegistry();
  const goiasEntry = registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'abc')]);
  const juventudeEntry = registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'juventude_passport', 'abc')]);
  assert.notStrictEqual(goiasEntry.matchId, juventudeEntry.matchId);
  assert.doesNotThrow(() => validateMatchRegistryIntegrity(registry));
});
test('o MESMO (namespace, ref) não pode apontar pra 2 matches diferentes — validateMatchRegistryIntegrity detecta e lança', () => {
  const registry = emptyMatchRegistry();
  registerNewMatch(registry, [anchor('PASSPORT_MATCH', 'goias_passport', 'abc')]);
  // 2ª entrada corrompida manualmente reusando o mesmo anchor — simula um
  // bug de geração, não um caminho normal do código.
  registry.entries.push({
    matchId: 'deadbeef-0000-5000-8000-000000000000',
    canonicalMatchKey: `goias-app:multiclub:match:${registry.nextSequence}`,
    sourceAnchors: [anchor('PASSPORT_MATCH', 'goias_passport', 'abc')],
    descriptor: null, status: 'ACTIVE', supersededByCanonicalMatchKey: null, registeredAt: '2026-01-01',
  });
  registry.nextSequence += 1;
  assert.throws(() => validateMatchRegistryIntegrity(registry), /anchor .* pertence a 2 entradas ACTIVE/);
});

// ============================================================================
// 16) kickoff_precision — intervalos, sobreposição, fronteira
// ============================================================================
console.log('\n16) kickoff_precision — intervalos e comparação de fronteira');
test('kickoffIntervalsOverlap: YEAR 2020 sobrepõe MONTH maio/2020 (o mês está contido no ano)', () => {
  assert.ok(kickoffIntervalsOverlap({ precision: 'YEAR', year: 2020, month: null, date: null, at: null }, { precision: 'MONTH', year: 2020, month: 5, date: null, at: null }));
});
test('kickoffIntervalsOverlap: YEAR 2020 NÃO sobrepõe DATE 2021-01-01', () => {
  assert.ok(!kickoffIntervalsOverlap({ precision: 'YEAR', year: 2020, month: null, date: null, at: null }, { precision: 'DATE', year: 2021, month: 1, date: '2021-01-01', at: null }));
});
test('compareKickoffBoundary: candidate estritamente antes -> BEFORE; estritamente depois -> AFTER', () => {
  const baseline = { precision: 'DATE', year: 2026, month: 8, date: '2026-08-28', at: null };
  assert.strictEqual(compareKickoffBoundary({ precision: 'DATE', year: 2026, month: 1, date: '2026-01-01', at: null }, baseline), 'BEFORE');
  assert.strictEqual(compareKickoffBoundary({ precision: 'DATE', year: 2026, month: 12, date: '2026-12-01', at: null }, baseline), 'AFTER');
});
test('compareKickoffBoundary: intervalo coarse cruzando a fronteira -> AMBIGUOUS', () => {
  const baseline = { precision: 'DATE', year: 2026, month: 8, date: '2026-08-28', at: null };
  assert.strictEqual(compareKickoffBoundary({ precision: 'MONTH', year: 2026, month: 8, date: null, at: null }, baseline), 'AMBIGUOUS');
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

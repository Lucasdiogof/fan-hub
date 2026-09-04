// Testes do seed de player_club_stats — rodam contra o dado real gerado.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { checkSpellCoverage, worstVerificationStatus } from './stats_coverage.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const IN_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const stats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_stats_seed.json'), 'utf8'));
const sources = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_stat_sources_seed.json'), 'utf8'));
const canonicalPeople = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'canonical_people_candidates.json'), 'utf8'));
const clubSpells = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_spells_seed.json'), 'utf8'));
const buildStats = JSON.parse(fs.readFileSync(path.join(IN_DIR, 'player_club_stats_seed_stats.json'), 'utf8'));
const migrationSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902080000_create_player_club_stats.sql'), 'utf8');
const seedSql = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902090000_seed_goias_player_club_stats.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function byName(name) { return canonicalPeople.find((p) => p.canonicalName === name); }
function statsOf(canonicalName) { const person = byName(canonicalName); return stats.filter((s) => s.personId === person.canonicalId); }
function spellsOf(canonicalName) { const person = byName(canonicalName); return clubSpells.filter((s) => s.personId === person.canonicalId).sort((a, b) => a.spellOrder - b.spellOrder); }

console.log('1) Tadeu — 400 CLUB_TOTAL, snapshot temporal preservado');
test('Tadeu Antônio Ferreira tem exatamente 1 linha CLUB_TOTAL, appearances=400, as_of_date/as_of_match_id preenchidos', () => {
  const rows = statsOf('Tadeu Antônio Ferreira');
  assert.strictEqual(rows.length, 1);
  assert.strictEqual(rows[0].statsScope, 'CLUB_TOTAL');
  assert.strictEqual(rows[0].appearances, 400);
  assert.strictEqual(rows[0].asOfDate, '2026-08-28');
  assert.strictEqual(rows[0].asOfMatchId, 'pe_cb52680435343cc4');
  assert.strictEqual(rows[0].verificationStatus, 'VERIFIED');
});

console.log('\n2) Walter — 3 spells permanecem, CLUB_TOTAL não é dividido, 2019=0 só porque comprovado');
test('Walter Henrique da Silva continua com 3 spells em player_club_spells (não alterado por esta etapa)', () => {
  assert.strictEqual(spellsOf('Walter Henrique da Silva').length, 3);
});
test('Walter tem 1 CLUB_TOTAL (97/48, PARTIAL — nota do ledger) e 1 SPELL (2019, appearances=0, goals=null, VERIFIED)', () => {
  const rows = statsOf('Walter Henrique da Silva');
  const total = rows.find((r) => r.statsScope === 'CLUB_TOTAL');
  const spell = rows.find((r) => r.statsScope === 'SPELL');
  assert.strictEqual(total.appearances, 97);
  assert.strictEqual(total.goals, 48);
  assert.strictEqual(total.verificationStatus, 'PARTIAL');
  assert.strictEqual(spell.appearances, 0);
  assert.strictEqual(spell.goals, null);
  assert.strictEqual(spell.spellOrder, 3);
  assert.strictEqual(spell.verificationStatus, 'VERIFIED');
});
test('o CLUB_TOTAL do Walter NÃO foi recalculado subtraindo o spell 2019 (continua 97, não 97-0 tratado como derivação)', () => {
  const rows = statsOf('Walter Henrique da Silva');
  const total = rows.find((r) => r.statsScope === 'CLUB_TOTAL');
  const totalSource = sources.find((s) => s.personId === total.personId && s.statsScope === 'CLUB_TOTAL');
  assert.strictEqual(totalSource.sourceType, 'career_players_aggregate_stats');
});

console.log('\n3) Múltiplas passagens — CLUB_TOTAL não gera SPELL rows automaticamente sem evidência própria');
for (const name of ['Rafael Moura', 'Iarley', 'Paulo Baier', 'Fernandão']) {
  test(`${name}: tem 2+ spells em player_club_spells, mas SÓ 1 linha CLUB_TOTAL em player_club_stats (sem SPELL rows — sem evidência própria por passagem)`, () => {
    assert.ok(spellsOf(name).length >= 2, `${name} deveria ter 2+ spells`);
    const rows = statsOf(name);
    assert.strictEqual(rows.length, 1);
    assert.strictEqual(rows[0].statsScope, 'CLUB_TOTAL');
  });
}
test('Evair Aparecido Paulino: 1 CLUB_TOTAL + 2 SPELL, e a soma dos SPELL bate exatamente com o CLUB_TOTAL', () => {
  const rows = statsOf('Evair Aparecido Paulino');
  const total = rows.find((r) => r.statsScope === 'CLUB_TOTAL');
  const spellRows = rows.filter((r) => r.statsScope === 'SPELL');
  assert.strictEqual(spellRows.length, 2);
  assert.strictEqual(spellRows.reduce((a, r) => a + r.appearances, 0), total.appearances);
  assert.strictEqual(spellRows.reduce((a, r) => a + r.goals, 0), total.goals);
});
test('Welliton Soares de Morais: 1 CLUB_TOTAL + 2 SPELL, soma bate', () => {
  const rows = statsOf('Welliton Soares de Morais');
  const total = rows.find((r) => r.statsScope === 'CLUB_TOTAL');
  const spellRows = rows.filter((r) => r.statsScope === 'SPELL');
  assert.strictEqual(spellRows.reduce((a, r) => a + r.appearances, 0), total.appearances);
  assert.strictEqual(spellRows.reduce((a, r) => a + r.goals, 0), total.goals);
});
test('Luiz Felipe do Nascimento dos Santos: CLUB_TOTAL derivado por soma bate com as 2 linhas SPELL (squad_members)', () => {
  const rows = statsOf('Luiz Felipe do Nascimento dos Santos');
  const total = rows.find((r) => r.statsScope === 'CLUB_TOTAL');
  const spellRows = rows.filter((r) => r.statsScope === 'SPELL');
  assert.strictEqual(spellRows.length, 2);
  assert.strictEqual(spellRows.reduce((a, r) => a + r.appearances, 0), total.appearances);
});
test('Murilo Camara Saquetti Chimelo Pereira: CLUB_TOTAL derivado por soma bate com as 2 linhas SPELL', () => {
  const rows = statsOf('Murilo Camara Saquetti Chimelo Pereira');
  const total = rows.find((r) => r.statsScope === 'CLUB_TOTAL');
  const spellRows = rows.filter((r) => r.statsScope === 'SPELL');
  assert.strictEqual(spellRows.reduce((a, r) => a + r.appearances, 0), total.appearances);
});

console.log('\n4) NULL != 0 — ausência de dado nunca vira zero, zero explícito é preservado como fato real');
test('nenhuma linha do seed tem appearances/goals inventado — toda linha vem de uma source real (nenhuma linha sem provenance)', () => {
  for (const s of stats) {
    const hasSource = sources.some((src) => src.personId === s.personId && src.statsScope === s.statsScope && (s.statsScope === 'CLUB_TOTAL' ? true : src.spellId === s.spellId));
    assert.ok(hasSource, `sem provenance: ${s.canonicalName} ${s.statsScope}`);
  }
});
test('appearances=0 explícito existe no dataset real (Walter 2019, e outros) e é distinto de ausência (pessoas bloqueadas não têm LINHA nenhuma, nunca uma linha com 0 inventado)', () => {
  assert.ok(stats.some((s) => s.appearances === 0));
  const blockedNames = new Set(buildStats.blocked.map((b) => b.canonicalName));
  assert.ok(blockedNames.size > 0);
  for (const name of blockedNames) assert.strictEqual(statsOf(name).length, 0, `${name} está bloqueado mas tem linha de stats`);
});
test('goals=0 explícito existe (Harlei, Danilo Cunha da Silva) e nunca é confundido com goals=null (Ernando, sem gol conhecido)', () => {
  const harlei = statsOf('Harlei').find((s) => s.statsScope === 'CLUB_TOTAL');
  assert.strictEqual(harlei.goals, 0);
  const ernando = statsOf('Ernando').find((s) => s.statsScope === 'CLUB_TOTAL');
  assert.strictEqual(ernando.goals, null);
  assert.strictEqual(ernando.appearances, 405);
});

console.log('\n5) Identity — Nicolas Godinho != Vichiatto, Danilos separados');
test('Nicolas Godinho Johann NÃO tem nenhuma linha de stats (sem evidência em nenhuma fonte); Nicolas Vichiatto da Silva tem CLUB_TOTAL 38/2', () => {
  assert.strictEqual(statsOf('Nicolas Godinho Johann').length, 0);
  const vichiatto = statsOf('Nicolas Vichiatto da Silva').find((s) => s.statsScope === 'CLUB_TOTAL');
  assert.strictEqual(vichiatto.appearances, 38);
  assert.strictEqual(vichiatto.goals, 2);
});
test('Danilo Cunha da Silva (8/0) e Danilo Gabriel de Andrade (116/15) são pessoas diferentes com stats diferentes', () => {
  const cunha = byName('Danilo Cunha da Silva');
  const gabriel = byName('Danilo Gabriel de Andrade');
  assert.notStrictEqual(cunha.canonicalId, gabriel.canonicalId);
  const cunhaStats = statsOf('Danilo Cunha da Silva').find((s) => s.statsScope === 'CLUB_TOTAL');
  const gabrielStats = statsOf('Danilo Gabriel de Andrade').find((s) => s.statsScope === 'CLUB_TOTAL');
  assert.strictEqual(cunhaStats.appearances, 8);
  assert.strictEqual(gabrielStats.appearances, 116);
});

console.log('\n6) Estável/idempotente — seed 2x não duplica, nova provenance não duplica stat');
test('o INSERT de player_club_stats usa ON CONFLICT DO NOTHING', () => {
  assert.ok(seedSql.includes('on conflict do nothing;'));
});
test('o INSERT de player_club_stat_sources usa ON CONFLICT (player_club_stat_id, source_type, source_ref) DO NOTHING', () => {
  assert.ok(seedSql.includes('on conflict (player_club_stat_id, source_type, source_ref) do nothing;'));
});
test('reexecutar build+generate produz o MESMO SQL byte-a-byte', () => {
  const before = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902090000_seed_goias_player_club_stats.sql'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'build_player_club_stats_seed.mjs')], { stdio: 'pipe' });
  execFileSync(process.execPath, [path.join(__dirname, 'generate_player_club_stats_seed.mjs')], { stdio: 'pipe' });
  const after = fs.readFileSync(path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files', '20260902090000_seed_goias_player_club_stats.sql'), 'utf8');
  assert.strictEqual(before, after);
});
test('nenhum CLUB_TOTAL duplicado (person_id, club_id); nenhum spell_id duplicado entre linhas SPELL', () => {
  const totals = new Set(); const spellIds = new Set();
  for (const s of stats) {
    if (s.statsScope === 'CLUB_TOTAL') { const k = `${s.personId}|${s.clubId}`; assert.ok(!totals.has(k)); totals.add(k); }
    else { assert.ok(!spellIds.has(s.spellId)); spellIds.add(s.spellId); }
  }
});

console.log('\n7) Schema — sem posição, sem shirt_number, sem linha por partida, sem assists (não existe em nenhuma fonte)');
test('CREATE TABLE de player_club_stats não declara position/shirt_number/match_id de partida individual/minutes/assists', () => {
  const createBlock = migrationSql.split('create table if not exists public.player_club_stats')[1].split('create table if not exists public.player_club_stat_sources')[0];
  for (const forbidden of ['position', 'shirt_number', 'minutes', 'assists', 'starts', 'yellow_cards', 'red_cards', 'clean_sheets']) {
    assert.ok(!new RegExp(`\\b${forbidden}\\b`).test(createBlock), `coluna proibida "${forbidden}"`);
  }
});
test('stats_scope=CLUB_TOTAL <=> spell_id null; SPELL <=> spell_id not null (CHECK no schema)', () => {
  assert.ok(migrationSql.includes("check (stats_scope <> 'CLUB_TOTAL' or spell_id is null)"));
  assert.ok(migrationSql.includes("check (stats_scope <> 'SPELL' or spell_id is not null)"));
});
test('appearances/goals têm CHECK >= 0 no schema (nenhuma constraint goals<=appearances inventada)', () => {
  assert.ok(migrationSql.includes('appearances integer check (appearances >= 0)'));
  assert.ok(migrationSql.includes('goals integer check (goals >= 0)'));
  assert.ok(!migrationSql.includes('goals <= appearances'));
});
test('data_mode aceita SNAPSHOT e LIVE, mas nenhuma linha do seed usa LIVE', () => {
  assert.ok(migrationSql.includes("check (data_mode in ('SNAPSHOT', 'LIVE'))"));
  assert.ok(!stats.some((s) => s.dataMode === 'LIVE'));
});

console.log('\n8) Cobertura completa — regra pura testada com dado sintético');
test('3 spells canônicos, stats só pra 2 -> NÃO deriva CLUB_TOTAL (nem appearances nem goals)', () => {
  const canonical = ['spell-1', 'spell-2', 'spell-3'];
  const matched = [{ spellId: 'spell-1', appearances: 10, goals: 1 }, { spellId: 'spell-2', appearances: 20, goals: 2 }];
  const { appearancesFullyCovered, goalsFullyCovered } = checkSpellCoverage(canonical, matched);
  assert.strictEqual(appearancesFullyCovered, false);
  assert.strictEqual(goalsFullyCovered, false);
});
test('2 spells canônicos, stats pros 2 -> PODE derivar CLUB_TOTAL', () => {
  const canonical = ['spell-1', 'spell-2'];
  const matched = [{ spellId: 'spell-1', appearances: 10, goals: 1 }, { spellId: 'spell-2', appearances: 20, goals: 2 }];
  const { appearancesFullyCovered, goalsFullyCovered } = checkSpellCoverage(canonical, matched);
  assert.strictEqual(appearancesFullyCovered, true);
  assert.strictEqual(goalsFullyCovered, true);
});
test('NULL parcial: appearances conhecidos nos 2, goals faltando em 1 -> appearances coberto, goals NÃO coberto (nunca vira 0)', () => {
  const canonical = ['spell-1', 'spell-2'];
  const matched = [{ spellId: 'spell-1', appearances: 10, goals: 1 }, { spellId: 'spell-2', appearances: 20, goals: null }];
  const { appearancesFullyCovered, goalsFullyCovered } = checkSpellCoverage(canonical, matched);
  assert.strictEqual(appearancesFullyCovered, true);
  assert.strictEqual(goalsFullyCovered, false);
});
test('cobertura "a mais" (matched tem spell que não é canônico) também não cobre — nunca soma o que não pertence à pessoa/clube', () => {
  const canonical = ['spell-1', 'spell-2'];
  const matched = [{ spellId: 'spell-1', appearances: 10, goals: 1 }, { spellId: 'spell-2', appearances: 20, goals: 2 }, { spellId: 'spell-999-de-outra-pessoa', appearances: 5, goals: 0 }];
  const { appearancesFullyCovered } = checkSpellCoverage(canonical, matched);
  assert.strictEqual(appearancesFullyCovered, false);
});

console.log('\n9) Luiz Felipe / Murilo Câmara — cobertura real 100%, CLUB_TOTAL derivado corretamente');
for (const name of ['Luiz Felipe do Nascimento dos Santos', 'Murilo Camara Saquetti Chimelo Pereira']) {
  test(`${name}: spells canônicos == spell stats cobertos (100%), CLUB_TOTAL derivado só por isso`, () => {
    const realSpells = spellsOf(name);
    const spellStatRows = statsOf(name).filter((s) => s.statsScope === 'SPELL');
    assert.strictEqual(spellStatRows.length, realSpells.length);
    const total = statsOf(name).find((s) => s.statsScope === 'CLUB_TOTAL');
    assert.ok(total, `${name} deveria ter CLUB_TOTAL derivado`);
  });
}

console.log('\n10) Provenance de total DERIVADO — linhas independentes por componente, nunca um blob opaco');
test('CLUB_TOTAL do Luiz Felipe tem 2 linhas DERIVED_COMPONENT distintas (1 por segmento), reconstruindo A+B=total', () => {
  const total = statsOf('Luiz Felipe do Nascimento dos Santos').find((s) => s.statsScope === 'CLUB_TOTAL');
  const totalSources = sources.filter((s) => s.personId === total.personId && s.statsScope === 'CLUB_TOTAL' && s.spellId === null);
  const components = totalSources.filter((s) => s.sourceRole === 'DERIVED_COMPONENT');
  assert.strictEqual(components.length, 2);
  const sumApp = components.reduce((a, c) => a + c.rawValue.appearances, 0);
  assert.strictEqual(sumApp, total.appearances);
  const refs = new Set(components.map((c) => c.sourceRef));
  assert.strictEqual(refs.size, 2, 'source_ref devem ser distintos entre os 2 componentes (nunca colapsados)');
});
test('CLUB_TOTAL do Evair/Welliton tem provenance PRIMARY (aggregate_stats) + CORROBORATING (2 club_career distintos cada)', () => {
  for (const name of ['Evair Aparecido Paulino', 'Welliton Soares de Morais']) {
    const total = statsOf(name).find((s) => s.statsScope === 'CLUB_TOTAL');
    const totalSources = sources.filter((s) => s.personId === total.personId && s.statsScope === 'CLUB_TOTAL' && s.spellId === null);
    assert.strictEqual(totalSources.filter((s) => s.sourceRole === 'PRIMARY').length, 1, `${name} deveria ter 1 PRIMARY`);
    const corroborating = totalSources.filter((s) => s.sourceRole === 'CORROBORATING');
    assert.strictEqual(corroborating.length, 2, `${name} deveria ter 2 CORROBORATING`);
    assert.strictEqual(new Set(corroborating.map((c) => c.sourceRef)).size, 2, 'source_ref distintos entre os 2 CORROBORATING');
  }
});

console.log('\n11) source_role — Tadeu tem BASELINE, achável objetivamente pelo campo (nunca por nome/notes)');
test('a única source do Tadeu tem source_role=BASELINE, as_of_date=2026-08-28', () => {
  const total = statsOf('Tadeu Antônio Ferreira').find((s) => s.statsScope === 'CLUB_TOTAL');
  const totalSources = sources.filter((s) => s.personId === total.personId && s.statsScope === 'CLUB_TOTAL' && s.spellId === null);
  assert.strictEqual(totalSources.length, 1);
  assert.strictEqual(totalSources[0].sourceRole, 'BASELINE');
  assert.strictEqual(totalSources[0].asOfDate, '2026-08-28');
});
test('todo source_role no seed real é um dos 4 valores válidos', () => {
  const valid = new Set(['PRIMARY', 'CORROBORATING', 'DERIVED_COMPONENT', 'BASELINE']);
  for (const s of sources) assert.ok(valid.has(s.sourceRole), `source_role inválido: ${s.sourceRole}`);
});

console.log('\n12) Integridade SPELL garantida pelo banco — FK composta (spell_id, person_id, club_id)');
test('a migration altera player_club_spells ADITIVAMENTE (UNIQUE id/person_id/club_id) sem reescrever dado', () => {
  assert.ok(migrationSql.includes('alter table public.player_club_spells'));
  assert.ok(migrationSql.includes('add constraint player_club_spells_id_person_club_key unique (id, person_id, club_id)'));
});
test('player_club_stats declara FK composta (spell_id, person_id, club_id) -> player_club_spells(id, person_id, club_id)', () => {
  assert.ok(migrationSql.includes('foreign key (spell_id, person_id, club_id)'));
  assert.ok(migrationSql.includes('references public.player_club_spells (id, person_id, club_id)'));
});

console.log('\n13) Unicidade — índices parciais explícitos (nunca UNIQUE cru, que deixaria NULL colidir mal)');
test('índice parcial garante no máximo 1 CLUB_TOTAL por (person_id, club_id)', () => {
  assert.ok(migrationSql.includes("player_club_stats_club_total_idx"));
  assert.ok(migrationSql.includes("where stats_scope = 'CLUB_TOTAL'"));
});
test('índice parcial garante no máximo 1 stat por spell_id (stats_scope=SPELL)', () => {
  assert.ok(migrationSql.includes('player_club_stats_spell_idx'));
  assert.ok(migrationSql.includes("where stats_scope = 'SPELL'"));
});

console.log('\n14) PARTIALs — divergência auditável (valor persistido, concorrente quando conhecido, motivo, fonte)');
test('as 3 linhas PARTIAL (Walter, Rafael Moura, Paulo Baier) têm entrada em partialDivergences com motivo e fonte', () => {
  const names = new Set(buildStats.partialDivergences.map((d) => d.canonicalName));
  assert.ok(names.has('Walter Henrique da Silva'));
  assert.ok(names.has('Rafael Moura'));
  assert.ok(names.has('Paulo Baier'));
  for (const d of buildStats.partialDivergences) {
    assert.ok(d.persistedValue);
    assert.ok(d.reason);
    assert.ok(d.source);
  }
});
test('Walter: valor concorrente extraído da nota (98/48); Rafael Moura/Paulo Baier: sem número concreto citado, competingValue null (nunca inventado)', () => {
  const walter = buildStats.partialDivergences.find((d) => d.canonicalName === 'Walter Henrique da Silva');
  assert.deepStrictEqual(walter.competingValue, { appearances: 98, goals: 48 });
  const rafaelMoura = buildStats.partialDivergences.find((d) => d.canonicalName === 'Rafael Moura');
  assert.strictEqual(rafaelMoura.competingValue, null);
});

console.log('\n15) Propagação de qualidade — verification_status do CLUB_TOTAL derivado = PIOR entre os componentes');
test('exemplo obrigatório: spell1=20apps/VERIFIED + spell2=30apps/PARTIAL -> CLUB_TOTAL derivado=50apps/PARTIAL (cobertura 100% não implica VERIFIED)', () => {
  assert.strictEqual(worstVerificationStatus(['VERIFIED', 'PARTIAL']), 'PARTIAL');
  assert.strictEqual(worstVerificationStatus(['PARTIAL', 'VERIFIED']), 'PARTIAL');
});
test('todos VERIFIED -> total VERIFIED; qualquer PARTIAL -> total PARTIAL (inclusive com 3+ componentes)', () => {
  assert.strictEqual(worstVerificationStatus(['VERIFIED', 'VERIFIED']), 'VERIFIED');
  assert.strictEqual(worstVerificationStatus(['VERIFIED', 'VERIFIED', 'PARTIAL']), 'PARTIAL');
});
test('Luiz Felipe: os 2 componentes squad_members têm data_quality=verified -> os 2 SPELL stats são VERIFIED -> CLUB_TOTAL derivado herda VERIFIED (propagação correta, não "VERIFIED só por cobertura 100%")', () => {
  const spellRows = statsOf('Luiz Felipe do Nascimento dos Santos').filter((s) => s.statsScope === 'SPELL');
  const total = statsOf('Luiz Felipe do Nascimento dos Santos').find((s) => s.statsScope === 'CLUB_TOTAL');
  assert.ok(spellRows.every((r) => r.verificationStatus === 'VERIFIED'));
  assert.strictEqual(total.verificationStatus, worstVerificationStatus(spellRows.map((r) => r.verificationStatus)));
  assert.strictEqual(total.verificationStatus, 'VERIFIED');
});
test('Murilo Câmara: mesma verificação — os 2 SPELL stats são VERIFIED, CLUB_TOTAL derivado herda VERIFIED por propagação real, não por suposição', () => {
  const spellRows = statsOf('Murilo Camara Saquetti Chimelo Pereira').filter((s) => s.statsScope === 'SPELL');
  const total = statsOf('Murilo Camara Saquetti Chimelo Pereira').find((s) => s.statsScope === 'CLUB_TOTAL');
  assert.ok(spellRows.every((r) => r.verificationStatus === 'VERIFIED'));
  assert.strictEqual(total.verificationStatus, worstVerificationStatus(spellRows.map((r) => r.verificationStatus)));
  assert.strictEqual(total.verificationStatus, 'VERIFIED');
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length > 0) {
  console.log('\nFALHAS:');
  for (const f of failures) console.log(` - ${f.name}: ${f.err.message}`);
  process.exit(1);
}

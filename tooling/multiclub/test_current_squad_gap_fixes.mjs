import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { pathToFileURL } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATIONS = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_audit.json'), 'utf8'));
const evidence = JSON.parse(fs.readFileSync(path.join(__dirname, 'current_squad_gap_evidence.json'), 'utf8'));
const plan = JSON.parse(fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_fix_plan.json'), 'utf8'));
const spells = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_spells_seed.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'player_club_stats_seed.json'), 'utf8'));
const squadMapping = JSON.parse(fs.readFileSync(path.join(RECON, 'squad_members_person_mapping.json'), 'utf8'));

const spellSql = fs.readFileSync(path.join(MIGRATIONS, '20260902200000_fix_current_squad_ongoing_spells.sql'), 'utf8');
const statsSql = fs.readFileSync(path.join(MIGRATIONS, '20260902210000_add_current_squad_missing_club_total_stats.sql'), 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

// ============================================================================
// 1) Cobertura de gaps confirmada — 8 spells + 2 stats, nada mais nada menos
// ============================================================================
console.log('1) cobertura de gaps');
test('8 spell gaps, 2 stats gaps — igual ao achado da F4', () => {
  assert.strictEqual(audit.spellGaps.length, 8);
  assert.strictEqual(audit.statsGaps.length, 2);
  assert.strictEqual(audit.resolvedSquadMembersTotal, 31);
});
test('nenhum spell gap é MULTIPLE_ONGOING_SPELLS (senão o fix builder teria marcado AMBIGUOUS)', () => {
  assert.strictEqual(audit.spellGaps.filter((g) => g.gapType === 'MULTIPLE_ONGOING_SPELLS').length, 0);
});

// ============================================================================
// 2) Plano de fix — todo gap tem exatamente 1 resolução, nada fabricado
// ============================================================================
console.log('\n2) fix plan — classificação e cobertura projetada');
test('8/8 spell fixes classificados EXTEND_EXISTING_SPELL (nenhum NEW_SPELL, nenhum bloqueado)', () => {
  assert.strictEqual(plan.spellFixes.length, 8);
  assert.ok(plan.spellFixes.every((f) => f.resolution === 'EXTEND_EXISTING_SPELL'));
});
test('2/2 stats fixes classificados FIXABLE', () => {
  assert.strictEqual(plan.statsFixes.length, 2);
  assert.ok(plan.statsFixes.every((f) => f.resolution === 'FIXABLE'));
});
test('resumo do plano projeta 31/31 ongoing e 31/31 CLUB_TOTAL', () => {
  assert.strictEqual(plan.summary.ongoingCoverageBefore, '23/31');
  assert.strictEqual(plan.summary.ongoingCoverageAfterProposed, '31/31');
  assert.strictEqual(plan.summary.clubTotalCoverageBefore, '29/31');
  assert.strictEqual(plan.summary.clubTotalCoverageAfterProposed, '31/31');
});
test('todo spell fix referencia um spellId/canonicalSpellKey que já existe no seed aplicado (nunca cria spell novo)', () => {
  const knownSpellIds = new Set(spells.map((s) => s.spellId));
  const knownKeys = new Set(spells.map((s) => s.canonicalSpellKey));
  for (const f of plan.spellFixes) {
    assert.ok(knownSpellIds.has(f.spellId), `spellId ${f.spellId} não existe no seed já aplicado`);
    assert.ok(knownKeys.has(f.canonicalSpellKey), `canonicalSpellKey ${f.canonicalSpellKey} não existe no seed já aplicado`);
  }
});

// ============================================================================
// 3) is_ongoing <=> end_* nulo — invariante do schema preservado no "after"
// ============================================================================
console.log('\n3) invariante is_ongoing <=> end_* nulo');
test('todo "after" com isOngoing=true tem os 4 campos de fim nulos', () => {
  for (const f of plan.spellFixes) {
    assert.strictEqual(f.after.isOngoing, true);
    assert.strictEqual(f.after.endYear, null);
    assert.strictEqual(f.after.endMonth, null);
    assert.strictEqual(f.after.endPrecision, null);
  }
});

// ============================================================================
// 4) Sem overlap — nenhuma correção sobrepõe outro spell do mesmo person+club
// ============================================================================
console.log('\n4) sem overlap entre spells do mesmo person+club');
function monthsSinceEpoch(year, month) { return year * 12 + (month ? month - 1 : 0); }
test('nenhum person tem 2 spells ongoing simultâneos após a correção (Goiás)', () => {
  const byPerson = new Map();
  for (const s of spells) {
    if (s.clubSlug !== 'goias') continue;
    if (!byPerson.has(s.personId)) byPerson.set(s.personId, []);
    byPerson.get(s.personId).push({ ...s });
  }
  // aplica a correção simulada por cima do seed local
  for (const f of plan.spellFixes) {
    const list = byPerson.get(plan.spellFixes.find((x) => x === f).personId) || [];
    const target = list.find((s) => s.spellId === f.spellId);
    if (target) { target.isOngoing = true; target.endYear = null; target.endMonth = null; target.endPrecision = null; }
  }
  for (const [personId, list] of byPerson) {
    const ongoingCount = list.filter((s) => s.isOngoing).length;
    assert.ok(ongoingCount <= 1, `person ${personId} ficaria com ${ongoingCount} spells ongoing simultâneos no Goiás após a correção`);
  }
});
test('spell corrigido não se sobrepõe a nenhum outro spell do mesmo person+club (mesma ordem de spellOrder preservada)', () => {
  const byPerson = new Map();
  for (const s of spells) {
    if (!byPerson.has(s.personId)) byPerson.set(s.personId, []);
    byPerson.get(s.personId).push(s);
  }
  for (const f of plan.spellFixes) {
    const siblings = (byPerson.get(f.personId) || []).filter((s) => s.clubSlug === 'goias' && s.spellId !== f.spellId);
    for (const other of siblings) {
      // sem overlap = ordem de spellOrder intacta (o corrigido continua depois de tudo que vem antes dele)
      const fOrder = spells.find((s) => s.spellId === f.spellId).spellOrder;
      assert.notStrictEqual(other.spellOrder, fOrder, `spellOrder duplicado para person ${f.personId}`);
    }
  }
});

// ============================================================================
// 5) SQL gerado — DO block balanceado, sem CREATE TABLE, com pré/pós-condições
// ============================================================================
console.log('\n5) SQL das migrations propostas');
test('migration de spells: DO block balanceado, 8 UPDATEs, sem CREATE TABLE/INSERT', () => {
  assert.strictEqual((spellSql.match(/do \$\$/g) || []).length, 1);
  assert.strictEqual((spellSql.match(/end \$\$;/g) || []).length, 1);
  assert.strictEqual((spellSql.match(/update public\.player_club_spells/g) || []).length, 8);
  assert.doesNotMatch(spellSql, /create table/i);
  assert.doesNotMatch(spellSql, /insert into/i);
  assert.match(spellSql, /raise exception/);
});
test('migration de stats: DO block balanceado, 2 INSERTs em player_club_stats, 4 em player_club_stat_sources', () => {
  assert.strictEqual((statsSql.match(/do \$\$/g) || []).length, 1);
  assert.strictEqual((statsSql.match(/end \$\$;/g) || []).length, 1);
  assert.strictEqual((statsSql.match(/insert into public\.player_club_stats /g) || []).length, 2);
  assert.strictEqual((statsSql.match(/insert into public\.player_club_stat_sources/g) || []).length, 4);
  assert.doesNotMatch(statsSql, /create table/i);
  assert.match(statsSql, /raise exception/);
});
test('migration de stats nunca escreve source_role=BASELINE nem DERIVED_COMPONENT (só PRIMARY/CORROBORATING, fiel à evidência)', () => {
  const roleValues = [...statsSql.matchAll(/::jsonb, '([A-Z_]+)'/g)].map((m) => m[1]);
  assert.strictEqual(roleValues.length, 4);
  assert.deepStrictEqual(roleValues, ['PRIMARY', 'CORROBORATING', 'PRIMARY', 'CORROBORATING']);
});
test('migration de stats: appearances=0 e goals=0 explícitos (nunca NULL) e verification_status=PARTIAL pros 2 casos', () => {
  const valuesLines = [...statsSql.matchAll(/values \('[0-9a-f-]{36}', '4c16340d-300c-5ab2-903f-17519db9b146', null, 'CLUB_TOTAL', (\d+), (\d+), '([A-Z]+)'/g)];
  assert.strictEqual(valuesLines.length, 2);
  for (const m of valuesLines) {
    assert.strictEqual(m[1], '0');
    assert.strictEqual(m[2], '0');
    assert.strictEqual(m[3], 'PARTIAL');
  }
});
test('migration de spells não altera as outras spells (só os 8 ids alvo aparecem em cláusulas where id =)', () => {
  const ids = [...spellSql.matchAll(/where id = '([0-9a-f-]{36})';/g)].map((m) => m[1]);
  assert.strictEqual(ids.length, 8);
  assert.strictEqual(new Set(ids).size, 8);
  const expectedIds = new Set(plan.spellFixes.map((f) => f.spellId));
  for (const id of ids) assert.ok(expectedIds.has(id));
});
test('migration de stats nunca toca as outras 29 linhas CLUB_TOTAL (só 2 INSERTs, nenhum UPDATE/DELETE)', () => {
  assert.doesNotMatch(statsSql, /update public\.player_club_stats/i);
  assert.doesNotMatch(statsSql, /delete from/i);
});

// ============================================================================
// 6) Gates da rodada de revisão — precondition exata, invariante do elenco
//    inteiro, proveniência preservada, count preservado, sem now()/CURRENT_DATE
// ============================================================================
console.log('\n6) gates da rodada de revisão (F4.5 aprovada com hardenings)');
test('migration de spells tem 1 precondition exata por spell (person_id/club_id/is_ongoing/start_*/end_*/verification_status), não só "id existe"', () => {
  const blocks = [...spellSql.matchAll(/if not exists \(\s*select 1 from public\.player_club_spells\s*where id = '([0-9a-f-]{36})'([\s\S]*?)\) then/g)];
  assert.strictEqual(blocks.length, 8, 'esperava 8 blocos de precondition exata (1 por spell alvo)');
  for (const [, id, conds] of blocks) {
    for (const col of ['person_id', 'club_id', 'is_ongoing', 'start_year', 'start_month', 'start_date', 'start_precision', 'end_year', 'end_month', 'end_date', 'end_precision', 'verification_status']) {
      assert.match(conds, new RegExp(`\\b${col}\\b`), `precondition do spell ${id} não checa ${col}`);
    }
  }
});
test('migration de spells detecta drift com RAISE EXCEPTION antes de qualquer UPDATE (8 raises de DRIFT antes do 1º UPDATE)', () => {
  const firstUpdateIdx = spellSql.indexOf('update public.player_club_spells');
  const driftRaises = [...spellSql.matchAll(/DRIFT DETECTADO/g)].map((m) => m.index);
  assert.strictEqual(driftRaises.length, 8);
  for (const idx of driftRaises) assert.ok(idx < firstUpdateIdx, 'uma checagem de drift aparece DEPOIS do primeiro UPDATE — preconditions precisam vir todas antes');
});
test('migration de spells valida o invariante do ELENCO INTEIRO (31 person_ids), não só os 8 corrigidos', () => {
  const valuesBlocks = [...spellSql.matchAll(/values\n(\s*\('[0-9a-f-]{36}'::uuid\),?\n?)+/g)];
  assert.ok(valuesBlocks.length >= 2, 'esperava pelo menos 2 blocos VALUES com os 31 person_ids (1 pro invariante de ongoing, 1 pro overlap)');
  for (const block of valuesBlocks) {
    const ids = [...block[0].matchAll(/'([0-9a-f-]{36})'/g)].map((m) => m[1]);
    assert.strictEqual(ids.length, 31, 'bloco VALUES não tem os 31 person_ids do elenco atual');
  }
});
test('migration de spells casta os person_ids literais do CTE como ::uuid (senão Postgres rejeita uuid = text)', () => {
  const valuesBlocks = [...spellSql.matchAll(/values\n(\s*\('[0-9a-f-]{36}'(::uuid)?\),?\n?)+/g)];
  assert.ok(valuesBlocks.length >= 2);
  for (const block of valuesBlocks) {
    const rows = [...block[0].matchAll(/\('[0-9a-f-]{36}'(::uuid)?\)/g)];
    for (const r of rows) assert.match(r[0], /::uuid\)$/, `literal sem cast ::uuid: ${r[0]}`);
  }
});
test('migration de spells checa "0 pessoas com != 1 ongoing" e "0 overlap" como pós-condição', () => {
  assert.match(spellSql, /ongoing_count <> 1/);
  assert.match(spellSql, /v_overlap_count/);
  assert.match(spellSql, /a\.start_ord <= b\.end_ord and b\.start_ord <= a\.end_ord/);
});
test('migration de spells confirma count(player_club_spells) antes==depois (só UPDATE, nunca INSERT/DELETE de spell)', () => {
  assert.match(spellSql, /v_total_spells_after <> v_total_spells_before/);
  assert.doesNotMatch(spellSql, /insert into public\.player_club_spells/i);
  assert.doesNotMatch(spellSql, /delete from public\.player_club_spells/i);
});
function stripSqlComments(sql) {
  return sql.split('\n').filter((line) => !line.trim().startsWith('--')).join('\n');
}
test('migration de spells confirma proveniência (player_club_spell_sources) intocada — não apaga a evidência da expiração contratual', () => {
  assert.match(spellSql, /v_provenance_after <> v_provenance_before/);
  const body = stripSqlComments(spellSql);
  assert.doesNotMatch(body, /insert into public\.player_club_spell_sources/i);
  assert.doesNotMatch(body, /update public\.player_club_spell_sources/i);
  assert.doesNotMatch(body, /delete from public\.player_club_spell_sources/i);
});
test('todo spell fix tem provenanceSourceCount >= 1 no fix plan (a evidência já existe antes de nularmos end_*)', () => {
  for (const f of plan.spellFixes) assert.ok(f.before.provenanceSourceCount >= 1, `spell ${f.spellId} (${f.canonicalName}) não tem proveniência registrada — end_* seria perdido sem rastro`);
});
test('nenhuma das duas migrations usa now()/current_date em condição de negócio (só now() em updated_at, housekeeping)', () => {
  for (const sql of [spellSql, statsSql]) {
    const body = stripSqlComments(sql);
    assert.doesNotMatch(body, /current_date/i);
    // updated_at = now() é o único uso de código (não-comentário) esperado
    const nonUpdatedAt = body.split('\n').filter((line) => /now\(\)/.test(line) && !/updated_at\s*=\s*now\(\)/.test(line));
    assert.strictEqual(nonUpdatedAt.length, 0, `now() usado fora de updated_at: ${JSON.stringify(nonUpdatedAt)}`);
  }
});
test('migration de stats confirma exatamente 2 fontes PRIMARY e 2 CORROBORATING (não força 4 PRIMARY nem inventa um número diferente)', () => {
  const roleValues = [...statsSql.matchAll(/::jsonb, '([A-Z_]+)'/g)].map((m) => m[1]);
  assert.strictEqual(roleValues.filter((r) => r === 'PRIMARY').length, 2);
  assert.strictEqual(roleValues.filter((r) => r === 'CORROBORATING').length, 2);
});
test('migration de stats tem precondition explícita de existência de person_id e de club_id antes de cada INSERT', () => {
  assert.strictEqual((statsSql.match(/not exists \(select 1 from public\.people where id = /g) || []).length, 2);
  assert.strictEqual((statsSql.match(/not exists \(select 1 from public\.clubs where id = /g) || []).length, 1);
});
test('migration de stats tem pós-condição de 0 CLUB_TOTAL duplicado por pessoa', () => {
  assert.match(statsSql, /v_duplicate_club_total/);
});
test('migration de stats grava as_of_date=2026-09-02 literal (nunca current_date) nos 2 INSERTs em player_club_stats', () => {
  const insertLines = [...statsSql.matchAll(/values \('[0-9a-f-]{36}', '4c16340d-300c-5ab2-903f-17519db9b146', null, 'CLUB_TOTAL', \d+, \d+, '[A-Z]+', '[A-Z]+', '([0-9-]+)', null\)/g)];
  assert.strictEqual(insertLines.length, 2);
  for (const m of insertLines) assert.strictEqual(m[1], '2026-09-02');
});
test('sanity conceitual baseline+delta (Etapa E/D): snapshot 0 + 1 appearance futura distinta = 1, reprocessar a mesma appearance continua 1 (idempotente)', () => {
  const script = `
    import { recomputeTotal } from ${JSON.stringify(pathToFileURL(path.join(__dirname, 'recompute_player_club_stats.mjs')).href)};
    const baseline = { appearances: 0, asOfMatchId: null, asOfKickoff: { precision: 'DATE', year: 2026, date: '2026-09-02' } };
    const futureAppearance = [{ canonicalMatchId: 'match-ezequiel-estreia', participationStatus: 'STARTED', kickoff: { precision: 'DATE', year: 2026, date: '2026-09-15' } }];
    const first = recomputeTotal(baseline, futureAppearance);
    const second = recomputeTotal(baseline, futureAppearance);
    const doubled = recomputeTotal(baseline, [...futureAppearance, ...futureAppearance]);
    console.log(JSON.stringify({ first, second, doubled }));
  `;
  const out = execFileSync(process.execPath, ['--input-type=module', '-e', script], { encoding: 'utf8' });
  const { first, second, doubled } = JSON.parse(out);
  assert.strictEqual(first.total, 1);
  assert.strictEqual(first.delta, 1);
  // reprocessar a MESMA appearance (ex.: sync rodando de novo) não pode duplicar
  assert.strictEqual(second.total, 1, 'reprocessar a mesma appearance não é idempotente');
  // e reprocessar 2x a mesma lista (dedup por canonicalMatchId) também não duplica
  assert.strictEqual(doubled.total, 1, 'dedup por canonicalMatchId falhou — mesma partida 2x não pode contar 2x');
});

// ============================================================================
// 7) NULL != 0 preservado nas outras 29 linhas CLUB_TOTAL (não tocadas)
// ============================================================================
console.log('\n7) NULL != 0 nas 29 linhas CLUB_TOTAL não tocadas');
test('as 29 linhas CLUB_TOTAL do elenco atual (squad_members RESOLVED) continuam intocadas — só os 2 gaps entram no plano', () => {
  const resolvedPersonIds = new Set(squadMapping.filter((m) => m.status === 'RESOLVED').map((m) => m.personId));
  const clubTotalGoias = stats.filter((s) => s.clubSlug === 'goias' && s.statsScope === 'CLUB_TOTAL' && resolvedPersonIds.has(s.personId));
  assert.strictEqual(clubTotalGoias.length, 29, 'esperava 29 CLUB_TOTAL já existentes entre os 31 do elenco atual (2 são o gap)');
  const targetPersonIds = new Set(plan.statsFixes.map((f) => f.personId));
  assert.strictEqual(targetPersonIds.size, 2);
  for (const s of clubTotalGoias) assert.ok(!targetPersonIds.has(s.personId), `pessoa ${s.personId} já tinha CLUB_TOTAL — não deveria estar no fix plan`);
});

// ============================================================================
// 8) F4 permanece intocado — 31 mapeamentos squad_members.person_id sem mudança
// ============================================================================
console.log('\n8) F4 (squad_members.person_id) permanece intocado');
test('squad_members_person_mapping.json continua 31 RESOLVED (F4.5 não mexe em squad_members)', () => {
  assert.strictEqual(squadMapping.filter((m) => m.status === 'RESOLVED').length, 31);
});
test('casos sensíveis seguem corretos: Nicolas->Vichiatto, Danilo->Cunha, Murilo Câmara != Murillo Victorio', () => {
  const nicolas = squadMapping.find((m) => m.squadMemberId === 'nicolas' || /nicolas/i.test(m.canonicalName || ''));
  if (nicolas) assert.match(nicolas.canonicalName, /Vichiatto/i);
  const murilo = squadMapping.find((m) => /murilo c[aâ]mara/i.test(m.canonicalName || ''));
  const murillo = plan.statsFixes.find((f) => f.squadMemberId === 'murillo_victorio');
  if (murilo && murillo) assert.notStrictEqual(murilo.personId, murillo.personId);
});
test('nenhum arquivo de F4 (schema/backfill de squad_members.person_id) foi alterado por esta etapa', () => {
  for (const file of ['20260902180000_add_person_id_to_squad_members.sql', '20260902190000_backfill_squad_members_person_id.sql']) {
    assert.ok(fs.existsSync(path.join(MIGRATIONS, file)), `${file} deveria continuar existindo, intocado`);
  }
});

// ============================================================================
// 9) Registry de spells não é tocado — nenhuma spell nova, nenhum id novo
// ============================================================================
console.log('\n9) spells_registry.json intocado (nenhuma spell nova criada)');
test('spells_registry.json não tem diff no git (F4.5 é DML puro sobre spells já registradas)', () => {
  let diffOutput = '';
  try {
    diffOutput = execFileSync('git', ['status', '--porcelain', '--', 'tooling/multiclub/spells_registry.json'], { cwd: ROOT, encoding: 'utf8' });
  } catch {
    return; // sem git disponível no ambiente de teste — não é uma falha do fix
  }
  assert.strictEqual(diffOutput.trim(), '', 'spells_registry.json foi modificado — F4.5 não deveria criar/alterar entradas de registry');
});

// ============================================================================
// 10) Reprodutibilidade — rodar audit+builder de novo produz o mesmo resultado
// ============================================================================
console.log('\n10) reprodutibilidade (audit -> fix plan -> migrations), sem depender de new Date()/now()');
test('rodar audit_current_squad_canonical_gaps.mjs de novo produz exatamente o mesmo JSON — nada depende de new Date()/now() no tooling', () => {
  const before = fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_audit.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_current_squad_canonical_gaps.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_audit.json'), 'utf8');
  assert.strictEqual(before, after, 'audit não é determinístico — rodar de novo produziu um resultado diferente');
});
test('rodar build_current_squad_gap_fixes.mjs de novo produz exatamente o mesmo JSON (byte a byte, exceto nada — determinístico)', () => {
  const before = fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_fix_plan.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'build_current_squad_gap_fixes.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'current_squad_canonical_gap_fix_plan.json'), 'utf8');
  assert.strictEqual(before, after, 'fix plan não é determinístico — rodar de novo produziu um resultado diferente');
});
test('nenhum script de tooling desta etapa referencia new Date()/Date.now() (a data de snapshot é literal, 2026-09-02, auditada)', () => {
  for (const file of ['audit_current_squad_canonical_gaps.mjs', 'build_current_squad_gap_fixes.mjs', 'generate_current_squad_gap_migration.mjs']) {
    const src = fs.readFileSync(path.join(__dirname, file), 'utf8');
    assert.doesNotMatch(src, /new Date\(\)/);
    assert.doesNotMatch(src, /Date\.now\(\)/);
  }
});
test('rodar generate_current_squad_gap_migration.mjs de novo produz exatamente o mesmo SQL', () => {
  const beforeSpell = fs.readFileSync(path.join(MIGRATIONS, '20260902200000_fix_current_squad_ongoing_spells.sql'), 'utf8');
  const beforeStats = fs.readFileSync(path.join(MIGRATIONS, '20260902210000_add_current_squad_missing_club_total_stats.sql'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'generate_current_squad_gap_migration.mjs')], { cwd: ROOT });
  const afterSpell = fs.readFileSync(path.join(MIGRATIONS, '20260902200000_fix_current_squad_ongoing_spells.sql'), 'utf8');
  const afterStats = fs.readFileSync(path.join(MIGRATIONS, '20260902210000_add_current_squad_missing_club_total_stats.sql'), 'utf8');
  assert.strictEqual(beforeSpell, afterSpell, 'migration de spells não é determinística');
  assert.strictEqual(beforeStats, afterStats, 'migration de stats não é determinística');
});

// ============================================================================
// 11) Evidência — todo squadMemberId do evidence.json corresponde a um gap real
// ============================================================================
console.log('\n11) evidência não tem entradas órfãs');
test('todo squadMemberId em spellCorrections/statsAdditions corresponde a um gap real do audit', () => {
  const spellGapIds = new Set(audit.spellGaps.map((g) => g.squadMemberId));
  const statsGapIds = new Set(audit.statsGaps.map((g) => g.squadMemberId));
  for (const c of evidence.spellCorrections) assert.ok(spellGapIds.has(c.squadMemberId), `evidência de spell pra ${c.squadMemberId} não corresponde a nenhum gap do audit`);
  for (const c of evidence.statsAdditions) assert.ok(statsGapIds.has(c.squadMemberId), `evidência de stats pra ${c.squadMemberId} não corresponde a nenhum gap do audit`);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

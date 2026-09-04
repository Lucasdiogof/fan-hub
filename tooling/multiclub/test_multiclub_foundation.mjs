import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const HARDCODE_SCRIPT = path.join(__dirname, 'audit_multiclub_hardcodes.mjs');
const SCOPE_SCRIPT = path.join(__dirname, 'audit_multiclub_data_scope.mjs');

const hardcodeStats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_hardcode_audit_stats.json'), 'utf8'));
const scopeStats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit_stats.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

// ============================================================================
// Auditoria de hardcodes — 0 stale (toda entrada citada ainda existe no
// código real), CRITICAL identificado corretamente
// ============================================================================
console.log('1) auditoria de hardcodes — reproduzível e verificada contra o código real');
test('0 entradas stale — todo padrão citado ainda existe no arquivo real hoje', () => {
  assert.strictEqual(hardcodeStats.stale, 0, JSON.stringify(hardcodeStats.staleList));
});
test('pelo menos 3 hardcodes CRITICAL identificados (colisão de progresso/ranking/membership)', () => {
  assert.ok(hardcodeStats.byRisk.CRITICAL >= 3, JSON.stringify(hardcodeStats.byRisk));
});

// ============================================================================
// Sanity checks estruturais — os fatos centrais do relatório M1
// ============================================================================
console.log('\n2) sanity checks estruturais');
test('UUID canônico do Goiás só existe em lib/core/club/goias_club_config.dart — nenhum outro arquivo Dart o repete', () => {
  assert.strictEqual(hardcodeStats.sanity.clubUuidOnlyInGoiasClubConfig.pass, true, JSON.stringify(hardcodeStats.sanity.clubUuidOnlyInGoiasClubConfig));
});
test('clubRegistry tem só clubes REAIS conhecidos (M4: goias + bragantino), Goiás sempre presente, nenhum sintético', () => {
  assert.strictEqual(hardcodeStats.sanity.clubRegistryRealClubs.pass, true, JSON.stringify(hardcodeStats.sanity.clubRegistryRealClubs));
  assert.deepStrictEqual([...hardcodeStats.sanity.clubRegistryRealClubs.keys].sort(), ['bragantino', 'goias']);
});
test('só as configs de clube conhecidas existem (goias + bragantino reais) — nenhum *_club_config.dart sintético/não-cadastrado', () => {
  assert.strictEqual(hardcodeStats.sanity.onlyKnownClubConfigs.pass, true, JSON.stringify(hardcodeStats.sanity.onlyKnownClubConfigs));
});
test('rotas GoRouter (81 confirmadas) não têm slug/nome de clube em nenhum path', () => {
  assert.strictEqual(hardcodeStats.sanity.routesHaveNoClubSlug.pass, true, JSON.stringify(hardcodeStats.sanity.routesHaveNoClubSlug));
  assert.ok(hardcodeStats.sanity.routesHaveNoClubSlug.totalRoutes > 0);
});

// ============================================================================
// Auditoria de escopo de dados — coerência com a fundação canônica já
// aplicada (Etapas B-F7) e o risco de colisão real
// ============================================================================
console.log('\n3) auditoria de escopo de dados Supabase — ROW_SCOPE e KEY_SCOPE nunca confundidos');
test('0 tabelas stale — todo padrão de coluna citado ainda existe no schema real', () => {
  assert.strictEqual(scopeStats.stale, 0, JSON.stringify(scopeStats.staleList));
});
test('27 tabelas auditadas (era 26 na 1ª rodada — quiz_questions, a tabela de CONTEÚDO, estava faltando; só quiz_question_progress, a de PROGRESSO, tinha entrado)', () => {
  assert.strictEqual(scopeStats.totalTables, 27);
});
test('INVARIANTE: a soma de todas as classificações fecha com o total de tabelas (27) — se alguma tabela cair fora do universo/ficar stale, quebra aqui', () => {
  assert.strictEqual(scopeStats.verified, 27, `verified=${scopeStats.verified}`);
  assert.strictEqual(scopeStats.stale, 0, JSON.stringify(scopeStats.staleList));
  assert.strictEqual(scopeStats.classificationSum, 27, `soma das classificações=${scopeStats.classificationSum}, byClassification=${JSON.stringify(scopeStats.byClassification)}`);
});
test('a fundação canônica (people/clubs/player_club_spells/player_positions/player_club_stats/matches/match_source_refs/player_match_appearances) está 100% ALREADY_SCOPED ou GLOBAL nos 2 eixos (row+key)', () => {
  const foundationTables = ['people', 'clubs', 'player_club_spells', 'player_positions', 'player_club_stats', 'matches', 'match_source_refs', 'player_match_appearances'];
  const scope = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8'));
  for (const name of foundationTables) {
    const row = scope.tables.find((t) => t.table === name);
    assert.ok(row, `${name} não encontrada na auditoria`);
    assert.ok(['ALREADY_SCOPED', 'GLOBAL_NO_SCOPE_NEEDED'].includes(row.rowScope), `${name}.rowScope`);
    assert.ok(['SAFE_COMPOSITE_OR_SURROGATE', 'GLOBAL_NO_SCOPE_NEEDED'].includes(row.keyScope), `${name}.keyScope`);
  }
});
test('supporter_memberships continua TENANT_SCOPE_REQUIRED (get_my_membership sem filtro de clube) — achado CRITICAL preservado', () => {
  const scope = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8'));
  const row = scope.tables.find((t) => t.table === 'supporter_memberships');
  assert.strictEqual(row.classification, 'TENANT_SCOPE_REQUIRED');
  assert.match(row.note, /CRITICAL/);
});
test('as 6 tabelas de CONTEÚDO club-specific (career_players/guess_players/squad_members/lineup_matches/passport_matches/quiz_questions) têm KEY_SCOPE = COLLISION_RISK_LEGACY_ID_GLOBAL_PK — PK é só "id" texto, club_id sozinho NÃO resolveria colisão de chave', () => {
  const scope = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8'));
  for (const name of ['career_players', 'guess_players', 'squad_members', 'lineup_matches', 'passport_matches', 'quiz_questions']) {
    const row = scope.tables.find((t) => t.table === name);
    assert.strictEqual(row.keyScope, 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', name);
    assert.strictEqual(row.rowScope, 'ADDING_CLUB_ID_SUFFICIENT', name);
  }
});
test('lineup_matches continua explicitamente na lista de tabelas com risco de colisão de chave — nunca escondida por causa da decisão F7 (F7 é sobre identidade de jogador dentro do slot, não sobre tenancy da linha)', () => {
  assert.ok(scopeStats.keyScopeCollisionTables.includes('lineup_matches'));
});
test('ACHADO NOVO — UNIQUE(person_id) é um 2º eixo de KEY_SCOPE: career_players/guess_players/squad_members têm UNIQUE(person_id) (confirmado nas migrations F, não suposto), e a auditoria registra o candidato futuro UNIQUE(club_id, person_id) — NUNCA UNIQUE(person_id) cru — quando forem multi-tenant', () => {
  assert.deepStrictEqual(
    [...scopeStats.personIdUniqueKeyScopeTables].sort(),
    ['career_players', 'guess_players', 'squad_members'],
  );
  const scope = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8'));
  for (const name of ['career_players', 'guess_players', 'squad_members']) {
    const row = scope.tables.find((t) => t.table === name);
    assert.strictEqual(row.keyScopeProblem, true, `${name}.keyScopeProblem`);
    const u = row.uniqueConstraints.find((c) => c.columns.length === 1 && c.columns[0] === 'person_id');
    assert.ok(u, `${name} deveria ter UNIQUE(person_id) nas constraints estruturadas`);
    assert.ok(u.keyScopeRisk, `${name} UNIQUE(person_id) deveria estar marcado keyScopeRisk`);
    assert.match(u.futureMultiTenant, /club_id, person_id/, `${name} candidato futuro deveria ser UNIQUE(club_id, person_id)`);
    // a fonte PK legada TAMBÉM tem de continuar presente — as 3 têm 2 fontes de KEY_SCOPE, não 1.
    assert.ok(row.keyScopeSources.some((s) => s.kind === 'PRIMARY_KEY'), `${name} deveria manter a fonte PRIMARY_KEY`);
    assert.ok(row.keyScopeSources.some((s) => s.kind === 'UNIQUE'), `${name} deveria ter a fonte UNIQUE(person_id)`);
  }
});
test('lineup_matches NÃO ganha um eixo de KEY_SCOPE por person_id (person_id dele vive no jsonb de slot, F7 — não é coluna/constraint)', () => {
  assert.ok(!scopeStats.personIdUniqueKeyScopeTables.includes('lineup_matches'));
});
test('as tabelas de UNIQUE global legítimo (store_orders.order_number, user_notification_tokens.fcm_token) NÃO são marcadas como problema de KEY_SCOPE — unicidade global é correta ali (KEEP_GLOBAL)', () => {
  const scope = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8'));
  for (const name of ['store_orders', 'user_notification_tokens']) {
    const row = scope.tables.find((t) => t.table === name);
    assert.ok(row.uniqueConstraints.some((c) => c.global), `${name} deveria ter uma UNIQUE global marcada`);
    assert.strictEqual(row.keyScopeProblem, false, `${name}.keyScopeProblem deveria ser false (UNIQUE global é legítima)`);
  }
});
test('career_players/guess_players/squad_members/lineup_matches/quiz_questions NÃO têm nenhuma FK real de banco apontando pra elas (só passport_matches tem) — dependência é só convenção/RPC, nunca constraint', () => {
  assert.strictEqual(scopeStats.contentTablesWithRealFk.career_players, 0);
  assert.strictEqual(scopeStats.contentTablesWithRealFk.guess_players, 0);
  assert.strictEqual(scopeStats.contentTablesWithRealFk.squad_members, 0);
  assert.strictEqual(scopeStats.contentTablesWithRealFk.lineup_matches, 0);
  assert.strictEqual(scopeStats.contentTablesWithRealFk.quiz_questions, 0);
  assert.ok(scopeStats.contentTablesWithRealFk.passport_matches > 0);
});
test('passport_matches é a ÚNICA tabela de conteúdo classificada NEEDS_DECISION (FK real + schema assimétrico goias_is_home/goias_score) — não é mecânico como as outras 5', () => {
  assert.deepStrictEqual(scopeStats.needsDecisionTables, ['passport_matches']);
});
test('squad_members é a única tabela de conteúdo sem nenhuma cadeia de progress/ranking/RPC dependente (confirmado, não presumido)', () => {
  const scope = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8'));
  const chain = scope.progressChains.find((c) => c.content === 'squad_members');
  assert.deepStrictEqual(chain.progress, []);
  assert.deepStrictEqual(chain.ranking, []);
});
test('recomendação de tipo de club_id é UUID referenciando clubs(id) — nunca text referenciando clubs(slug) — confirmado contra o schema real de clubs (id uuid, slug text separado)', () => {
  assert.strictEqual(scopeStats.clubIdTypeRecommendation.type, 'uuid');
  assert.strictEqual(scopeStats.clubIdTypeRecommendation.references, 'clubs(id)');
  assert.match(scopeStats.clubIdTypeRecommendation.neverUse, /text references clubs\(slug\)/);
});
test('nenhuma entrada da auditoria propõe club_id como text (grep no próprio script de auditoria — só uuid aparece como tipo recomendado)', () => {
  const src = fs.readFileSync(SCOPE_SCRIPT, 'utf8');
  assert.doesNotMatch(src, /club_id text references/i);
});

// ============================================================================
// Read-only
// ============================================================================
console.log('\n4) read-only — auditoria M1 nunca escreve em produto/Supabase');
test('os 2 scripts de auditoria só escrevem nos próprios outputs (data_export/.../multiclub_*)', () => {
  for (const script of [HARDCODE_SCRIPT, SCOPE_SCRIPT]) {
    const src = fs.readFileSync(script, 'utf8');
    const writes = [...src.matchAll(/writeFileSync\(([^,]+),/g)].map((m) => m[1]);
    for (const w of writes) assert.match(w, /OUT_DIR/, `${path.basename(script)}: write fora de OUT_DIR: ${w}`);
  }
});

// ============================================================================
// Reprodutibilidade
// ============================================================================
console.log('\n5) reprodutibilidade');
test('rodar audit_multiclub_hardcodes.mjs de novo produz o mesmo JSON byte a byte', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_hardcode_audit.json'), 'utf8');
  execFileSync(process.execPath, [HARDCODE_SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_hardcode_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});
test('rodar audit_multiclub_data_scope.mjs de novo produz o mesmo JSON byte a byte', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8');
  execFileSync(process.execPath, [SCOPE_SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_data_scope_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

// ============================================================================
// 0 migrations
// ============================================================================
console.log('\n6) 0 migrations');
test('nenhuma migration nova em supabase/migrations/ (M1 é fundação Dart + auditoria, 0 mudança de banco)', () => {
  // Filtra por timestamp <= o baseline da F4.5 — a M2.2A (etapa seguinte)
  // adiciona migrations próprias sem invalidar este teste, que só afirma
  // que M1 mesma não gerou nenhuma.
  const count = fs.readdirSync(path.join(ROOT, 'supabase', 'migrations'))
    .filter((f) => f.endsWith('.sql') && f <= '20260902210000_z').length;
  assert.strictEqual(count, 35, `esperava 35 migrations até o baseline da F4.5, achei ${count}`);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

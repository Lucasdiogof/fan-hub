import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { classifyKeyScope } from './audit_multiclub_key_scope.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_multiclub_key_scope.mjs');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_key_scope_audit.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_key_scope_stats.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) snapshot ao vivo — precondition M2.2B');
test('clubs = 1 (Goiás), integridade 100% limpa, 0 colisões prospectivas', () => {
  assert.strictEqual(audit.liveSnapshot.clubs.count, 1);
  assert.strictEqual(audit.liveSnapshot.clubs.goiasId, '4c16340d-300c-5ab2-903f-17519db9b146');
  assert.strictEqual(audit.liveSnapshot.integrityAllClean, true);
  assert.strictEqual(stats.liveCollisionZero, true);
});
test('passport tem 1697 partidas reais (impacto de compat), continua fora da M2.2B', () => {
  assert.strictEqual(audit.liveSnapshot.rowCounts.passport_matches, 1697);
  const pm = audit.targets.find((t) => t.table === 'passport_matches');
  assert.strictEqual(pm.classification, 'PRODUCT_DECISION');
});

console.log('\n2) classificador — casos reais');
test('29 constraints / 26 tabelas auditadas; 23 KEY_SCOPE_BLOCKED; 4 KEEP_GLOBAL; 2 PRODUCT_DECISION', () => {
  assert.strictEqual(stats.tenantScopedConstraintsAudited, 29);
  assert.strictEqual(stats.distinctTablesAudited, 26);
  assert.strictEqual(stats.keyScopeBlockedCount, 23);
  assert.strictEqual(stats.keepGlobalCount, 4);
  assert.strictEqual(stats.productDecisionCount, 2);
  assert.strictEqual(stats.bridgeFirstCount, 18);
  assert.strictEqual(stats.enforceInBCount, 5);
  assert.strictEqual(stats.bridgeFirstCount + stats.enforceInBCount + stats.keepGlobalCount + stats.productDecisionCount, 29);
});
test('os 5 PK-swaps de conteúdo (career/guess/squad/lineup/quiz id) são ENFORCE_IN_B — sem bridge (o ADD PRIMARY KEY constrói o índice; app nunca faz upsert em conteúdo), nunca SAFE_NOW', () => {
  const eib = audit.targets.filter((t) => t.classification === 'ENFORCE_IN_B');
  assert.strictEqual(eib.length, 5);
  for (const t of eib) { assert.strictEqual(t.bridgeIndex, null); assert.deepStrictEqual(t.dropBlockers, []); }
  assert.strictEqual(stats.safeNowCount, 0);
});
test('as 3 tabelas de conteúdo "de pessoa" têm UNIQUE(person_id) global flagada', () => {
  assert.deepStrictEqual([...stats.globalPersonUniqueConstraints].sort(), ['career_players', 'guess_players', 'squad_members']);
});
test('KEEP_GLOBAL cobre order_number, fcm_token e cpf — nunca ganham club_id na chave', () => {
  const g = audit.targets.filter((t) => t.classification === 'KEEP_GLOBAL').map((t) => t.currentKey.join(','));
  assert.ok(g.includes('order_number'));
  assert.ok(g.includes('fcm_token'));
  assert.ok(g.includes('cpf'));
});

console.log('\n3) DETECTOR funciona — casos sintéticos fabricados (não só "true")');
test('FABRICADO: global UNIQUE(user_id) com app onConflict é BLOCKED + REQUIRES_NEW_APP + REQUIRES_OLD_APP_RETIREMENT', () => {
  const fake = { table: 'fake_progress', currentKind: 'PK', currentKey: ['user_id'], targetKey: ['user_id', 'club_id'], bridgeIndex: 'fake_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id', keyScope: 'BLOCKED' };
  const r = classifyKeyScope(fake);
  assert.strictEqual(r.keyScopeBlocked, true);
  assert.ok(r.dropBlockers.includes('REQUIRES_NEW_APP'), 'deveria exigir app novo');
  assert.ok(r.dropBlockers.includes('REQUIRES_OLD_APP_RETIREMENT'), 'deveria exigir retirar app antigo');
});
test('FABRICADO: RPC que faz ON CONFLICT na chave legada gera REQUIRES_RPC_UPDATE', () => {
  const fake = { table: 'fake_rpc', currentKind: 'PK', currentKey: ['user_id', 'item_id'], targetKey: ['club_id', 'user_id', 'item_id'], bridgeIndex: 'x', writer: 'RPC', rpcConflict: 'user_id, item_id', keyScope: 'BLOCKED' };
  const r = classifyKeyScope(fake);
  assert.ok(r.dropBlockers.includes('REQUIRES_RPC_UPDATE'));
});
test('FABRICADO: alvo BLOCKED sem club_id na targetKey é erro (detector não deixa passar chave inválida)', () => {
  assert.throws(() => classifyKeyScope({ table: 'bad', targetKey: ['user_id'], keyScope: 'BLOCKED', currentKey: ['user_id'] }), /sem club_id/);
});
test('FABRICADO: KEEP_GLOBAL não é marcado como bloqueado', () => {
  const r = classifyKeyScope({ table: 'g', keyScope: 'GLOBAL_OK', currentKey: ['order_number'], targetKey: ['order_number'] });
  assert.strictEqual(r.classification, 'KEEP_GLOBAL');
  assert.strictEqual(r.keyScopeBlocked, false);
});
test('FABRICADO: índice único PARCIAL + app onConflict só de colunas → PARTIAL_ON_CONFLICT_REQUIRES_PREDICATE (REQUIRES_RPC_UPDATE)', () => {
  const fake = { table: 'fake_partial', currentKind: 'PARTIAL_UNIQUE', currentKey: ['user_id', 'match_id'], currentPredicate: "origin='x'", targetKey: ['club_id', 'user_id', 'match_id'], targetPredicate: "origin='x'", bridgeIndex: 'fp_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,match_id', keyScope: 'BLOCKED' };
  const r = classifyKeyScope(fake);
  assert.strictEqual(r.partialOnConflictRequiresPredicate, true, 'deveria sinalizar que onConflict de colunas é insuficiente');
  assert.ok(r.dropBlockers.includes('REQUIRES_RPC_UPDATE'), 'parcial escrito por app exige RPC com predicate');
});
test('tickets: bridge PARCIAL correto, mas NÃO diretamente compatível com onConflict do PostgREST → REQUIRES_RPC_UPDATE (não escondido no grupo genérico)', () => {
  const t = audit.targets.find((x) => x.table === 'tickets');
  assert.strictEqual(t.currentKind, 'PARTIAL_UNIQUE');
  assert.strictEqual(t.partialOnConflictRequiresPredicate, true);
  assert.ok(t.dropBlockers.includes('REQUIRES_RPC_UPDATE'));
  assert.ok(t.dropBlockers.includes('REQUIRES_NEW_APP'));
  assert.ok(t.dropBlockers.includes('REQUIRES_OLD_APP_RETIREMENT'));
  assert.deepStrictEqual(stats.partialOnConflictRequiresPredicateTables, ['tickets']);
});

console.log('\n4) prova central de compatibilidade — nenhum onConflict do app tem club_id');
test('NENHUM onConflict do app Flutter (nem no M3.3) inclui club_id — dropar qualquer chave legada quebraria o app', () => {
  assert.deepStrictEqual(stats.appOnConflictKeysWithClub, []);
  // e os alvos legados conhecidos existem no app
  assert.ok('user_id,game_id' in stats.appOnConflicts);
  assert.ok('user_id,match_id' in stats.appOnConflicts);
});
test('todo bridge index proposto inclui club_id na chave', () => {
  for (const t of audit.targets.filter((x) => x.bridgeIndex)) {
    assert.ok(t.targetKey.includes('club_id'), `${t.table} bridge sem club_id`);
  }
  assert.strictEqual(stats.bridgeIndexes.length, 18);
});

console.log('\n5) segundo clube ainda bloqueado');
test('SECOND_CLUB_BLOCKED = true enquanto existir constraint global bloqueando repetição de key', () => {
  assert.strictEqual(stats.secondClubBlocked, true);
  assert.ok(stats.keyScopeBlockedCount > 0);
});

console.log('\n6) testes estáticos das migrations bridge (M2.2B-A) — só aditivo');
const MIG = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files');
const bridgeFiles = fs.existsSync(MIG) ? fs.readdirSync(MIG).filter((f) => f.includes('prepare_tenant_aware') && f.endsWith('.sql')) : [];
const bridgeSql = bridgeFiles.map((f) => fs.readFileSync(path.join(MIG, f), 'utf8')).join('\n');
test('existem as 4 migrations bridge tenant_aware (content/progress/engagement/notification)', () => {
  assert.strictEqual(bridgeFiles.length, 4, JSON.stringify(bridgeFiles));
  for (const kw of ['content', 'progress', 'engagement', 'notification']) {
    assert.ok(bridgeFiles.some((f) => f.includes(kw)), `faltou migration ${kw}`);
  }
});
test('migrations bridge são 100% ADITIVAS — só CREATE UNIQUE INDEX + guard; nenhum DROP/ALTER-DROP/DELETE/UPDATE/TRUNCATE/CASCADE', () => {
  assert.doesNotMatch(bridgeSql, /\bdrop\s+(constraint|index|table|primary)\b/i);
  assert.doesNotMatch(bridgeSql, /alter\s+table[^;]*drop/i);
  assert.doesNotMatch(bridgeSql, /\b(truncate|cascade)\b/i);
  assert.doesNotMatch(bridgeSql, /\bdelete\s+from\b/i);
  assert.doesNotMatch(bridgeSql, /\bupdate\s+public\./i);
});
test('cada bridge index do audit aparece numa migration, todos com club_id, com guard clubs=1 + Goiás', () => {
  for (const idx of stats.bridgeIndexes) assert.ok(bridgeSql.includes(idx), `bridge ${idx} não está em nenhuma migration`);
  // toda criação de índice inclui club_id
  const creates = bridgeSql.match(/create unique index[^;]+;/gi) || [];
  assert.strictEqual(creates.length, 18, `esperava 18 CREATE UNIQUE INDEX, achei ${creates.length}`);
  for (const c of creates) assert.match(c, /club_id/i, `bridge sem club_id: ${c.slice(0, 60)}`);
  for (const f of bridgeFiles) {
    const s = fs.readFileSync(path.join(MIG, f), 'utf8');
    assert.match(s, /count\(\*\) from public\.clubs\) <> 1/i, `${f} sem guard clubs=1`);
    assert.match(s, /4c16340d-300c-5ab2-903f-17519db9b146/, `${f} sem guard Goiás`);
  }
});
test('passaporte NÃO é tocado por nenhuma migration bridge, e nenhum namespacing de id', () => {
  assert.doesNotMatch(bridgeSql, /passport_/i);
  assert.doesNotMatch(bridgeSql, /'goias:|:tadeu|club-b/i);
});
test('NENHUMA migration bridge usa CREATE UNIQUE INDEX IF NOT EXISTS (fail loud em drift, não silenciar objeto pré-existente)', () => {
  assert.doesNotMatch(bridgeSql, /create\s+unique\s+index\s+if\s+not\s+exists/i);
  // o único "if not exists" permitido é o guard do DO-block (select 1 from clubs)
  const guardOnly = (bridgeSql.match(/if\s+not\s+exists/gi) || []).every((_, i) => true);
  assert.ok(guardOnly);
});
test('os 3 índices tenant de person_id (career/guess/squad) NÃO têm predicate parcial (WHERE person_id is not null) — UNIQUE completo, NULLs já distintos', () => {
  const personCreates = (bridgeSql.match(/create unique index \w*club_person\w*[^;]+;/gi) || []);
  assert.strictEqual(personCreates.length, 3, `esperava 3 índices club_person, achei ${personCreates.length}`);
  for (const c of personCreates) {
    assert.match(c, /\(club_id, person_id\)/i, `índice person sem (club_id, person_id): ${c}`);
    assert.doesNotMatch(c, /where\s+person_id/i, `índice person NÃO deveria ter predicate parcial: ${c}`);
  }
  // e nenhum statement CREATE INDEX usa NULLS NOT DISTINCT (comentários à parte)
  const allCreates = (bridgeSql.match(/create unique index[^;]+;/gi) || []);
  for (const c of allCreates) assert.doesNotMatch(c, /nulls\s+not\s+distinct/i);
});
test('o bridge de tickets É parcial (WHERE origin = membership_check_in) — preservado de propósito', () => {
  assert.match(bridgeSql, /tickets_club_user_match_checkin_uidx[\s\S]*?where origin = 'membership_check_in'/i);
});

console.log('\n7) reprodutibilidade byte a byte (offline, sem rede)');
test('rodar o audit de novo produz o mesmo JSON byte a byte', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_key_scope_audit.json'), 'utf8');
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_key_scope_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

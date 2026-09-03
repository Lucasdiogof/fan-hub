import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { checkFunctionSignatureAclMatch } from './audit_multiclub_conflict_targets.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_multiclub_conflict_targets.mjs');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_conflict_targets_audit.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_conflict_targets_stats.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) Flutter — todo onConflict tenant inclui club_id, globais preservados');
test('11/11 upserts tenant diretos prontos; 0 legacy remanescente no novo runtime', () => {
  assert.strictEqual(stats.directTenantUpsertsAudited, 11);
  assert.strictEqual(stats.directTenantUpsertsReady, 11);
  assert.deepStrictEqual(stats.legacyConflictTargetsRemainingInNewRuntime, []);
});
test('GLOBAL vs TENANT distinguidos — fcm_token e profiles.user_id NÃO ganham club_id (não zerar strings cegamente)', () => {
  const g = stats.globalConflictTargets.map((x) => x.onConflict);
  assert.ok(g.includes('fcm_token'));
  assert.ok(g.includes('user_id'));
});
test('cada onConflict tenant do lib bate com uma bridge conhecida e contém club_id', () => {
  for (const t of audit.flutterTargets.filter((x) => x.scope === 'TENANT')) {
    assert.ok(audit.libOnConflicts[t.onConflict], `onConflict ${t.onConflict} não achado no lib`);
    assert.match(t.onConflict, /club_id/);
    assert.ok(t.bridge, `${t.table} sem bridge`);
  }
});

console.log('\n2) tickets — RPC dedicada, não onConflict direto');
test('tickets usa a RPC dedicada e não tem mais upsert direto no lib', () => {
  assert.strictEqual(stats.ticketsUsesDedicatedRpc, true);
  assert.strictEqual(stats.ticketsPartialPredicatePresent, true);
});

console.log('\n3) arena_record_score_for_club — ON CONFLICT tenant, guard mantido, ACL');
test('ON CONFLICT (club_id, user_id, game_id, item_id) no SQL real (sem contar comentários), 0 legacy', () => {
  assert.strictEqual(audit.arena.tenantConflict, true);
  assert.strictEqual(audit.arena.noLegacyConflict, true);
});
test('key_scope_collision guard MANTIDO (não removido nesta rodada)', () => {
  assert.strictEqual(audit.arena.keyScopeGuardKept, true);
  assert.strictEqual(stats.keyScopeCollisionGuardKept, true);
});
test('arena RPC: security definer + search_path seguro + ACL (revoke anon, grant authenticated)', () => {
  assert.strictEqual(audit.arena.securityDefiner, true);
  assert.strictEqual(audit.arena.safeSearchPath, true);
  assert.strictEqual(audit.arena.aclRevokeAnon, true);
  assert.strictEqual(audit.arena.aclGrantAuthenticated, true);
});
test('arena RPC: FUNCTION_SIGNATURE_ACL_MATCH — tipos do REVOKE/GRANT batem com o CREATE FUNCTION, na mesma ordem', () => {
  assert.strictEqual(audit.arena.functionSignatureAclMatch, true);
});

console.log('\n4) ticket RPC — predicate parcial, auth.uid(), ACL, só membership');
test('ON CONFLICT parcial (WHERE origin=membership_check_in), deriva auth.uid() (sem p_user_id), valida club, só membership', () => {
  assert.strictEqual(audit.ticketRpc.partialPredicate, true);
  assert.strictEqual(audit.ticketRpc.derivesAuthUid, true);
  assert.strictEqual(audit.ticketRpc.validatesClub, true);
  assert.strictEqual(audit.ticketRpc.onlyMembershipOrigin, true);
});
test('ticket RPC ACL: revoke anon+service_role, grant authenticated, search_path seguro', () => {
  assert.strictEqual(audit.ticketRpc.aclRevokeAnon, true);
  assert.strictEqual(audit.ticketRpc.aclRevokeServiceRole, true);
  assert.strictEqual(audit.ticketRpc.aclGrantAuthenticated, true);
  assert.strictEqual(audit.ticketRpc.safeSearchPath, true);
});
test('ticket RPC: FUNCTION_SIGNATURE_ACL_MATCH — tipos do REVOKE/GRANT batem com o CREATE FUNCTION, na mesma ordem (regressão do bug real: posição 8 era `int` no ACL vs `text` no CREATE)', () => {
  assert.strictEqual(audit.ticketRpc.functionSignatureAclMatch, true);
});

console.log('\n5) Edge — notification_events tenant, deliveries global');
test('notification_events onConflict tenant-aware nas 3 ocorrências (poll goal+full_time, sync access); 0 legacy', () => {
  assert.strictEqual(audit.edge.notificationEventsTenant, 3);
  assert.strictEqual(audit.edge.notificationEventsLegacyRemaining, 0);
});
test('notification_deliveries continua onConflict global (event_id,token_id) — KEEP', () => {
  assert.strictEqual(audit.edge.deliveriesUnchanged, true);
});

console.log('\n6) migrations M3.4 são adoption — nenhum DROP/enforcement');
test('nenhuma migration M3.4 dropa legacy / default / usa cascade / DML', () => {
  assert.strictEqual(audit.migrationsTouchLegacyDrop, false);
});

console.log('\n7) DETECTOR funciona — casos sintéticos fabricados (não só "true")');
// checkers puros equivalentes aos do audit, pra provar que reprovam SQL ruim
const stripComments = (sql) => sql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n');
const arenaTenantOk = (sql) => /on conflict \(club_id, user_id, game_id, item_id\)/i.test(stripComments(sql));
const ticketPartialOk = (sql) => /on conflict \(club_id, user_id, match_id\) where origin = 'membership_check_in'/i.test(sql);
const aclOk = (sql, fn) => new RegExp(`revoke execute[\\s\\S]*${fn}[\\s\\S]*from anon`, 'i').test(sql) && !/grant execute[\s\S]*to anon/i.test(sql);
test('FABRICADO: arena ON CONFLICT sem club_id → detector reprova', () => {
  assert.strictEqual(arenaTenantOk('on conflict (user_id, game_id, item_id) do update'), false);
  assert.strictEqual(arenaTenantOk('on conflict (club_id, user_id, game_id, item_id) do update'), true);
});
test('FABRICADO: ticket RPC sem o predicate parcial → detector reprova', () => {
  assert.strictEqual(ticketPartialOk('on conflict (club_id, user_id, match_id) do update'), false);
  assert.strictEqual(ticketPartialOk("on conflict (club_id, user_id, match_id) where origin = 'membership_check_in' do update"), true);
});
test('FABRICADO: adicionar grant a anon → detector de ACL reprova', () => {
  const bad = "revoke execute on function public.f() from anon;\ngrant execute on function public.f() to anon;";
  const good = "revoke execute on function public.f() from anon;\ngrant execute on function public.f() to authenticated;";
  assert.strictEqual(aclOk(bad, 'f'), false);
  assert.strictEqual(aclOk(good, 'f'), true);
});
test('FABRICADO: FUNCTION_SIGNATURE_ACL_MATCH reprova quando REVOKE/GRANT diverge do CREATE — reproduz o bug real da M3.4 rodada 1 (posição 8: CREATE=text, ACL=int)', () => {
  const droppedSql = `
create or replace function public.f(
  p_a uuid,
  p_b text,
  p_c int,
  p_d text
)
returns void
language plpgsql
as $$ begin end; $$;

revoke execute on function public.f(uuid, text, int, int) from public;
grant execute on function public.f(uuid, text, int, int) to authenticated;
`;
  const fixedSql = `
create or replace function public.f(
  p_a uuid,
  p_b text,
  p_c int,
  p_d text
)
returns void
language plpgsql
as $$ begin end; $$;

revoke execute on function public.f(uuid, text, int, text) from public;
grant execute on function public.f(uuid, text, int, text) to authenticated;
`;
  const bad = checkFunctionSignatureAclMatch(droppedSql, 'f');
  const good = checkFunctionSignatureAclMatch(fixedSql, 'f');
  assert.strictEqual(bad.ok, false);
  assert.deepStrictEqual(bad.mismatches, [
    { occurrence: 0, position: 3, expected: 'text', actual: 'int' },
    { occurrence: 1, position: 3, expected: 'text', actual: 'int' },
  ]);
  assert.strictEqual(good.ok, true);
  assert.deepStrictEqual(good.mismatches, []);
});
test('FABRICADO: FUNCTION_SIGNATURE_ACL_MATCH reprova quando o número de parâmetros diverge (não só o tipo)', () => {
  const sql = `
create or replace function public.g(p_a uuid, p_b text)
returns void
language sql
as $$ select 1; $$;

revoke execute on function public.g(uuid) from public;
`;
  const result = checkFunctionSignatureAclMatch(sql, 'g');
  assert.strictEqual(result.ok, false);
  assert.strictEqual(result.mismatches[0].reason, 'length');
});
test('FABRICADO: FUNCTION_SIGNATURE_ACL_MATCH normaliza aliases de tipo equivalentes (integer==int, timestamp with time zone==timestamptz) sem falso positivo', () => {
  const sql = `
create or replace function public.h(p_a integer, p_b timestamptz)
returns void
language sql
as $$ select 1; $$;

revoke execute on function public.h(int, timestamp with time zone) from public;
`;
  const result = checkFunctionSignatureAclMatch(sql, 'h');
  assert.strictEqual(result.ok, true);
});

console.log('\n8) segundo clube ainda bloqueado + bridges precondition');
test('SECOND_CLUB_BLOCKED=true e dbBridgePreconditionSatisfied=true', () => {
  assert.strictEqual(stats.secondClubBlocked, true);
  assert.strictEqual(stats.dbBridgePreconditionSatisfied, true);
  assert.strictEqual(stats.bridgeDependencyCount, 12);
});
test('FUNCTION_SIGNATURE_ACL_MATCH — gate agregado das 2 migrations M3.4 (nenhum drift CREATE vs REVOKE/GRANT)', () => {
  assert.strictEqual(stats.functionSignatureAclMatchAll, true);
});

console.log('\n9) reprodutibilidade byte a byte');
test('rodar o audit de novo produz o mesmo JSON byte a byte', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_conflict_targets_audit.json'), 'utf8');
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_conflict_targets_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

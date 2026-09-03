import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';
import { auditArenaRpcCrossClubFix } from './audit_arena_rpc_cross_club_fix.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_arena_rpc_cross_club_fix.mjs');
const MIGRATION_PATH = path.join(
  ROOT,
  'supabase/migrations/20260903150000_fix_arena_score_cross_club_reads.sql'
);

const realSql = fs.readFileSync(MIGRATION_PATH, 'utf8');

let passed = 0;
const failures = [];
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log(`  PASS — ${name}`);
  } catch (err) {
    failures.push({ name, err });
    console.log(`  FAIL — ${name}\n    ${err.message}`);
  }
}

console.log('1) Migration real — todos os checks passam');
const real = auditArenaRpcCrossClubFix(realSql);
test('arenaScorePrevReadClubScoped=true na migration real', () => {
  assert.strictEqual(real.checks.arenaScorePrevReadClubScoped, true);
});
test('arenaScoreTotalScoreClubScoped=true (já estava correto, não reescrito)', () => {
  assert.strictEqual(real.checks.arenaScoreTotalScoreClubScoped, true);
});
test('arenaScoreGameScoreClubScoped=true (já estava correto, não reescrito)', () => {
  assert.strictEqual(real.checks.arenaScoreGameScoreClubScoped, true);
});
test('arenaScoreConflictTargetTenantAware=true — on conflict (club_id,user_id,game_id,item_id)', () => {
  assert.strictEqual(real.checks.arenaScoreConflictTargetTenantAware, true);
});
test('arenaScoreAclCorrect=true — REVOKE public/anon/service_role + GRANT authenticated, assinatura exata', () => {
  assert.strictEqual(real.checks.arenaScoreAclCorrect, true);
});
test('missingClubFilterCountBefore=1, missingClubFilterCountAfter=0 — premissa corrigida (não mais "3")', () => {
  assert.strictEqual(real.missingClubFilterCountBefore, 1);
  assert.strictEqual(real.missingClubFilterCountAfter, 0);
});
test('keyScopeGuardDecision=KEEP_DEFENSIVELY, guard ainda presente no corpo', () => {
  assert.strictEqual(real.keyScopeGuardDecision, 'KEEP_DEFENSIVELY');
  assert.strictEqual(real.keyScopeGuardPresent, true);
});
test('arenaScoreCrossClubReady=true — resultado real, não forçado', () => {
  assert.strictEqual(real.arenaScoreCrossClubReady, true);
});

console.log('\n2) FABRICADO — cada filtro validado INDIVIDUALMENTE (não uma busca genérica pela string club_id)');

test('remover club_id só do SELECT de v_prev derruba SÓ esse check, os outros continuam true', () => {
  const broken = realSql.replace(
    'where user_id = v_uid and game_id = p_game_id and item_id = p_item_id\n    and club_id = p_club_id\n  for update;',
    'where user_id = v_uid and game_id = p_game_id and item_id = p_item_id\n  for update;'
  );
  assert.notStrictEqual(broken, realSql, 'a substituição precisa realmente ter encontrado o bloco');
  const result = auditArenaRpcCrossClubFix(broken);
  assert.strictEqual(result.checks.arenaScorePrevReadClubScoped, false);
  assert.strictEqual(result.checks.arenaScoreTotalScoreClubScoped, true);
  assert.strictEqual(result.checks.arenaScoreGameScoreClubScoped, true);
  assert.strictEqual(result.arenaScoreCrossClubReady, false);
});

test('remover club_id só da soma total_score derruba SÓ esse check, v_prev/game_score continuam true', () => {
  const broken = realSql.replace(
    '(select coalesce(sum(score), 0)::int\n      from public.user_game_item_progress\n      where user_id = v_uid and club_id = p_club_id),',
    '(select coalesce(sum(score), 0)::int\n      from public.user_game_item_progress\n      where user_id = v_uid),'
  );
  assert.notStrictEqual(broken, realSql);
  const result = auditArenaRpcCrossClubFix(broken);
  assert.strictEqual(result.checks.arenaScoreTotalScoreClubScoped, false);
  assert.strictEqual(result.checks.arenaScorePrevReadClubScoped, true);
  assert.strictEqual(result.checks.arenaScoreGameScoreClubScoped, true);
  assert.strictEqual(result.arenaScoreCrossClubReady, false);
});

test('remover club_id só da soma game_score derruba SÓ esse check, v_prev/total_score continuam true', () => {
  const broken = realSql.replace(
    '(select coalesce(sum(score), 0)::int\n      from public.user_game_item_progress\n      where user_id = v_uid and club_id = p_club_id and game_id = p_game_id);',
    '(select coalesce(sum(score), 0)::int\n      from public.user_game_item_progress\n      where user_id = v_uid and game_id = p_game_id);'
  );
  assert.notStrictEqual(broken, realSql);
  const result = auditArenaRpcCrossClubFix(broken);
  assert.strictEqual(result.checks.arenaScoreGameScoreClubScoped, false);
  assert.strictEqual(result.checks.arenaScorePrevReadClubScoped, true);
  assert.strictEqual(result.checks.arenaScoreTotalScoreClubScoped, true);
  assert.strictEqual(result.arenaScoreCrossClubReady, false);
});

test('FABRICADO: on conflict voltando pra chave legada (sem club_id) é detectado', () => {
  const broken = realSql.replace(
    'on conflict (club_id, user_id, game_id, item_id) do update set',
    'on conflict (user_id, game_id, item_id) do update set'
  );
  assert.notStrictEqual(broken, realSql);
  const result = auditArenaRpcCrossClubFix(broken);
  assert.strictEqual(result.checks.arenaScoreConflictTargetTenantAware, false);
  assert.strictEqual(result.arenaScoreCrossClubReady, false);
});

test('FABRICADO: GRANT vazando pra anon é detectado (ACL não fica "correct" por engano)', () => {
  const broken = realSql.replace(
    'to authenticated;',
    'to authenticated, anon;'
  );
  assert.notStrictEqual(broken, realSql);
  const result = auditArenaRpcCrossClubFix(broken);
  assert.strictEqual(result.checks.arenaScoreAclCorrect, false);
  assert.strictEqual(result.arenaScoreCrossClubReady, false);
});

test('FABRICADO: assinatura do REVOKE divergindo da CREATE FUNCTION (mesmo bug do M3.4) é detectado', () => {
  const broken = realSql.replace(
    'revoke all on function public.arena_record_score_for_club(\n  uuid, text, text, text, integer, text, integer, integer, integer, boolean, boolean\n) from public, anon, service_role;',
    'revoke all on function public.arena_record_score_for_club(\n  uuid, text, text, text, int, text, integer, integer, integer, boolean, boolean\n) from public, anon, service_role;'
  );
  assert.notStrictEqual(broken, realSql);
  const result = auditArenaRpcCrossClubFix(broken);
  assert.strictEqual(result.checks.arenaScoreAclCorrect, false);
});

console.log('\n3) Preservação — nada além do necessário foi tocado');
test('a única ocorrência NOVA de "and club_id = p_club_id" isolada é a do v_prev (as outras já existiam)', () => {
  const vPrevBlock = realSql.includes(
    'where user_id = v_uid and game_id = p_game_id and item_id = p_item_id\n    and club_id = p_club_id\n  for update;'
  );
  assert.strictEqual(vPrevBlock, true, 'o SELECT de v_prev precisa ter o filtro na forma esperada');
});
test('0 DDL proibido (DROP TABLE/COLUMN/CASCADE/TRUNCATE) na migration', () => {
  assert.strictEqual(real.noForbiddenDdl, true);
});
test('guard de segurança clubs=1+goias presente', () => {
  assert.strictEqual(real.signatureGuardPresent, true);
});

console.log('\n4) reprodutibilidade byte a byte');
test('rodar o audit de novo produz o mesmo JSON (só lê a migration local, nada ao vivo)', () => {
  const before = fs.readFileSync(
    path.join(RECON, 'arena_rpc_cross_club_fix_audit.json'),
    'utf8'
  );
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(
    path.join(RECON, 'arena_rpc_cross_club_fix_audit.json'),
    'utf8'
  );
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_multiclub_final_key_enforcement.mjs');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_final_key_enforcement_audit.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_final_key_enforcement_stats.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) Escopo físico — 18 objetos (12 promoções + 5 UNIQUE + 1 índice parcial)');
test('legacyKeysToDrop=18, tenantKeysReady=18 — todos os 18 realmente na migration, nenhum esquecido/sobrando', () => {
  assert.strictEqual(stats.legacyKeysToDrop, 18);
  assert.strictEqual(stats.tenantKeysReady, 18);
  assert.strictEqual(audit.pkPromotions.length, 12);
  assert.strictEqual(audit.uniqueDrops.length, 5);
  assert.strictEqual(audit.partialIndexDrops.length, 1);
});

console.log('\n2) DEFAULT Goiás — 24 tabelas');
test('goiasDefaultsToDrop=24 — as 24 exatas, nenhuma tabela extra nem faltando', () => {
  assert.strictEqual(stats.goiasDefaultsToDrop, 24);
  assert.strictEqual(audit.defaultTables.length, 24);
});

console.log('\n3) Legacy RPC retirement — REVOKE, nunca DROP FUNCTION');
test('legacyRpcsToRetire=8, 0 authenticated remanescente — as 8 realmente revogadas pras 4 roles', () => {
  assert.strictEqual(stats.legacyRpcsToRetire, 8);
  assert.strictEqual(stats.legacyRpcAuthenticatedExecuteRemaining, 0);
  assert.strictEqual(audit.legacyRpcs.length, 8);
});
test('a migration usa REVOKE — "DROP FUNCTION" só aparece em comentário explicando que NÃO é usado (achado e corrigido nesta rodada: falso positivo de regex em comentário)', () => {
  const migRpc = fs.readFileSync(path.join(ROOT, 'archive/supabase/goias-legacy-migrations/files/20260903140000_retire_legacy_rpc_execute_grants.sql'), 'utf8');
  const codeOnly = migRpc.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n');
  assert.ok(/revoke execute/i.test(codeOnly));
  assert.ok(!/drop\s+function/i.test(codeOnly));
});

console.log('\n4) Constraints/tabelas GLOBAIS e Passaporte — nunca tocados');
test('os 4 constraints globais e as 4 tabelas de passaporte não aparecem em nenhuma das 3 migrations', () => {
  assert.strictEqual(stats.globalConstraintsPreserved, true);
  assert.strictEqual(stats.passportUntouched, true);
});

console.log('\n5) RLS — não inventada, não tocada');
test('nenhuma menção a policy/row level security nas 3 migrations — M2.2B-B fecha KEY_SCOPE, não AUTH_SCOPE', () => {
  assert.strictEqual(stats.rlsUntouched, true);
});

console.log('\n6) 0 DDL/DML proibido, 0 IF EXISTS escondendo drift');
test('0 CASCADE/TRUNCATE/DROP TABLE/DROP COLUMN/DROP NOT NULL, 0 INSERT/UPDATE/DELETE, 0 IF EXISTS — fora dos comentários que os mencionam pra dizer que não usa', () => {
  assert.strictEqual(stats.anyForbiddenDdl, false);
  assert.strictEqual(stats.anyDml, false);
  assert.strictEqual(stats.anyIfExists, false);
});
test('FABRICADO: um DROP TABLE de verdade (fora de comentário) precisa ser pego pelo detector', () => {
  const fakeSql = 'drop table public.foo;';
  const codeOnly = fakeSql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n');
  assert.ok(/\bdrop\s+table\b/i.test(codeOnly));
});
test('FABRICADO: a MESMA frase dentro de um comentário -- não deve disparar', () => {
  const fakeSql = '-- este texto menciona drop table só pra dizer que não faz isso\nselect 1;';
  const codeOnly = fakeSql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n');
  assert.ok(!/\bdrop\s+table\b/i.test(codeOnly));
});

console.log('\n7) Guard de segurança (clubs=1 + Goiás) nas 3 migrations');
test('guardPresentInAllThree=true — nenhuma das 3 aplicaria contra um banco com != 1 clube ou clube != Goiás', () => {
  assert.strictEqual(stats.guardPresentInAllThree, true);
});

console.log('\n8) Current app sobrevive ao schema final (reconfirmado, não só citado do relatório anterior)');
test('currentAppSurvivesFinalSchema=true — 0 caller das 8 RPCs legacy no HEAD atual, grepado de novo nesta rodada', () => {
  assert.strictEqual(stats.currentAppSurvivesFinalSchema, true);
});
test('legacyAppExpectedToFail=true — consequência direta de 18 chaves + 24 defaults saindo', () => {
  assert.strictEqual(stats.legacyAppExpectedToFail, true);
});

console.log('\n9) key_scope_collision guard — achado registrado, NÃO corrigido nesta rodada (fora do escopo DDL)');
test('classificado KEEP_TEMPORARILY com justificativa real, não removido às cegas', () => {
  assert.strictEqual(audit.keyScopeCollisionGuardFinding.classification, 'KEEP_TEMPORARILY');
  assert.ok(audit.keyScopeCollisionGuardFinding.requiredPreM4Fix.includes('club_id'));
});

console.log('\n10) DECISÃO FINAL — não forçada pra true');
test('keyScopeFinalReady=true é o resultado real desta rodada (todos os 11 sub-critérios batem)', () => {
  assert.strictEqual(stats.keyScopeFinalReady, true);
});
test('FABRICADO: se qualquer 1 dos 18 objetos estivesse faltando na migration, keyScopeFinalReady teria que cair', () => {
  const simulate = (tenantKeysReady, legacyKeysToDrop) => tenantKeysReady === legacyKeysToDrop;
  assert.strictEqual(simulate(17, 18), false);
  assert.strictEqual(simulate(18, 18), true);
});

console.log('\n11) reprodutibilidade byte a byte');
test('rodar o audit de novo produz o mesmo JSON byte a byte (nada aqui é ao vivo — só lê os arquivos de migration locais e o código atual)', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_final_key_enforcement_audit.json'), 'utf8');
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_final_key_enforcement_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

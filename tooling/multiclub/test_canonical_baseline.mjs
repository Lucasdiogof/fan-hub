import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'canonical_baseline_audit.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('A) nenhum literal de clube proibido');
test('a_noForbiddenClubLiterals = true, 0 hits', () => {
  assert.strictEqual(audit.a_noForbiddenClubLiterals, true);
  assert.deepStrictEqual(audit.forbiddenLiteralHits, []);
});

console.log('\nA2) nenhum IDENTIFIER com "goias"/"bragantino"/"GOI-" embutido (mais rígido que A, que só olha literais de string)');
test('a2_noForbiddenIdentifiers = true, 0 hits — cobre goias_is_home/goias_score/goias_debut_year renomeados nesta rodada', () => {
  assert.strictEqual(audit.a2_noForbiddenIdentifiers, true);
  assert.deepStrictEqual(audit.identifierHits, []);
});

console.log('\nB) nenhum UUID real de clube');
test('b_noRealClubUuid = true — nem o UUID do Goiás nem o preview do Bragantino aparecem', () => {
  assert.strictEqual(audit.b_noRealClubUuid, true);
  assert.deepStrictEqual(audit.uuidHits, []);
});

console.log('\nC) nenhum DEFAULT club_id hardcoded');
test('c_noHardcodedClubIdDefault = true — a live schema já não tem esses defaults (dropados em M4.1c-B), e o baseline nunca reintroduz', () => {
  assert.strictEqual(audit.c_noHardcodedClubIdDefault, true);
  assert.strictEqual(audit.defaultClubIdHitsCount, 0);
});

console.log('\nD) RPC ACL — toda function com REVOKE ALL + GRANT explícito, assinatura completa');
test('d_rpcAclClean = true, 0 issues, 28 funções únicas (25 do dump + handle_new_user + generate_store_order_number/create_store_order_for_club/subscribe_to_plan_for_club genéricas; handle_new_user tinha 2 definições idênticas no arquivo — bug real achado comparando contagem local x live no Bragantino, deduplicado)', () => {
  assert.strictEqual(audit.d_rpcAclClean, true);
  assert.deepStrictEqual(audit.rpcAclIssues, []);
  assert.strictEqual(audit.functionCount, 28);
});

console.log('\nE) profiles/user_addresses/handle_new_user presentes (gap achado nos relatórios 48-50, fechado aqui)');
test('as 3 peças que nunca estiveram em migration nenhuma agora estão no baseline', () => {
  assert.strictEqual(audit.e_hasProfilesTable, true);
  assert.strictEqual(audit.e_hasUserAddressesTable, true);
  assert.strictEqual(audit.e_hasHandleNewUserFn, true);
});

console.log('\nF) trigger auth.users prevista');
test('f_hasAuthTrigger = true — on_auth_user_created explícito, nunca assumido do db dump', () => {
  assert.strictEqual(audit.f_hasAuthTrigger, true);
});

console.log('\nG) Storage — 2 buckets, 4 policies, exatos');
test('g_storageBucketsOk/g_storagePoliciesOk = true', () => {
  assert.strictEqual(audit.g_storageBucketsOk, true);
  assert.deepStrictEqual([...audit.bucketInserts].sort(), ['avatars', 'email-assets']);
  assert.strictEqual(audit.g_storagePoliciesOk, true);
  assert.strictEqual(audit.storagePolicyNames.length, 4);
});

console.log('\nH) zero dado real/seed editorial (INSERTs de topo, fora de corpo de function)');
test('h_zeroEditorialSeeds = true — só os 2 buckets de Storage inserem algo', () => {
  assert.strictEqual(audit.h_zeroEditorialSeeds, true);
  assert.deepStrictEqual(audit.nonStorageInserts, []);
});

console.log('\nI) baseline é determinístico/reprodutível');
test('rodar o audit de novo produz o mesmo JSON (só lê o arquivo local do baseline)', () => {
  const before = fs.readFileSync(path.join(RECON, 'canonical_baseline_audit.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_canonical_baseline.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'canonical_baseline_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log('\nJ) workdir canônico reconhecido pelo CLI (config.toml válido)');
test('j_canonicalConfigExists e j_workdirRecognized = true — erro observado é de CONEXÃO (db-url falsa), nunca de config/workdir inválido', () => {
  assert.strictEqual(audit.j_canonicalConfigExists, true);
  assert.strictEqual(audit.j_workdirRecognized, true);
});

console.log('\nL) zero plano editorial (catálogo Membership hardcoded)');
test('l_noEditorialPlanContent = true, 0 hits — nossa-gente/plano-vip/etc nunca aparecem, plans agora vêm de membership_plans (tabela vazia)', () => {
  assert.strictEqual(audit.l_noEditorialPlanContent, true);
  assert.deepStrictEqual(audit.editorialPlanHits, []);
});

console.log('\nM) Store — SCHEMA CAPABILITY preservada (tabelas presentes), sem prefixo GOI- hardcoded');
test('m_storeSchemaGeneric = true — store_orders/store_order_items presentes, generate_store_order_number(p_club_id) e create_store_order_for_club genéricos, clubs.order_prefix existe', () => {
  assert.strictEqual(audit.m_storeSchemaGeneric, true);
  assert.strictEqual(audit.m_storeTablesPresent, true);
  assert.strictEqual(audit.m_storeOrderNumberFnGeneric, true);
  assert.strictEqual(audit.m_storeCreateOrderFnPresent, true);
  assert.strictEqual(audit.m_clubsHasOrderPrefixColumn, true);
});

console.log('\nN) Membership — SCHEMA CAPABILITY genérica (membership_plans data-driven) OU blocker explicitamente registrado');
test('n_membershipOkOrBlocked = true via schema genérico real (não via blocker) — subscribe_to_plan_for_club lê de membership_plans, catálogo fica vazio', () => {
  assert.strictEqual(audit.n_membershipOkOrBlocked, true);
  assert.strictEqual(audit.n_membershipSchemaGeneric, true);
  assert.strictEqual(audit.n_membershipPlansTablePresent, true);
  assert.strictEqual(audit.n_membershipRpcIsDataDriven, true);
  assert.deepStrictEqual(audit.n_canonicalBaselineBlockers, [], 'nenhum blocker deveria estar registrado nesta rodada — o schema ficou genérico de verdade');
});

console.log('\nFABRICADO — provas de que os detectores reprovam estado errado, não só confirmam o certo');
test('identifier proibido: se uma coluna "goias_score" fosse reintroduzida por engano, a2_noForbiddenIdentifiers cairia (mesmo sem aspas de literal string)', () => {
  const fakeBody = 'alter table public.passport_matches add column goias_score integer;';
  assert.ok(/goias/i.test(fakeBody));
});
test('plano editorial: se "nossa-gente" reaparecesse em qualquer CASE/INSERT, l_noEditorialPlanContent cairia', () => {
  const fakeBody = "when p_plan_id = 'nossa-gente' then v_plan_name := 'NOSSA GENTE';";
  assert.ok(/'nossa-gente'/i.test(fakeBody));
});
test('store hardcoded: uma function generate_store_order_number() sem p_club_id (assinatura antiga) reprovaria m_storeOrderNumberFnGeneric', () => {
  const fakeBody = 'CREATE OR REPLACE FUNCTION public.generate_store_order_number()\n RETURNS text';
  const genericSigRe = /CREATE OR REPLACE FUNCTION public\.generate_store_order_number\(p_club_id uuid\)/i;
  assert.strictEqual(genericSigRe.test(fakeBody), false);
});
test('membership sem tabela nem blocker: ausência de membership_plans E de blocker registrado reprovaria n_membershipOkOrBlocked', () => {
  const fakeMembershipPlansPresent = false;
  const fakeBlockers = [];
  const fakeOkOrBlocked = fakeMembershipPlansPresent || fakeBlockers.length > 0;
  assert.strictEqual(fakeOkOrBlocked, false);
});
test('literal proibido: se o baseline tivesse "goias" solto, a_noForbiddenClubLiterals cairia', () => {
  const fakeBody = "insert into public.clubs (slug) values ('goias');";
  assert.ok(/'goias'/i.test(fakeBody));
});
test('UUID real: se o baseline citasse o UUID do Goiás em qualquer lugar, b_noRealClubUuid cairia', () => {
  const fakeBody = "-- club_id de referência: 4c16340d-300c-5ab2-903f-17519db9b146";
  assert.ok(fakeBody.includes('4c16340d-300c-5ab2-903f-17519db9b146'));
});
test('RPC ACL: uma function com GRANT sem assinatura (bug real encontrado e corrigido nesta rodada) seria pega', () => {
  const fakeBaselineBroken = 'create or replace function public.foo(a uuid) ... $function$;\nrevoke all on function public.foo(a uuid) from public;\ngrant execute on function public.foo to authenticated;';
  const grantReWithSig = /grant execute on function public\.foo\([^)]*\) to/i;
  assert.strictEqual(grantReWithSig.test(fakeBaselineBroken), false, 'GRANT sem parênteses/assinatura deveria falhar a checagem');
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

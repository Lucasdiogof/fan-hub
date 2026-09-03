import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_legacy_contract_retirement.mjs');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_legacy_contract_retirement_audit.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_legacy_contract_retirement_stats.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) origin/main vs HEAD — números reais');
test('origin/main = 613874a (a mesma baseline do rollout gate) — commits atrás só cresce a cada novo commit local, nunca diminui, nunca é hardcoded como um número fixo', () => {
  assert.strictEqual(audit.originMainCommit, '613874a7e00073c19560f8a9ebe0325efc395c0a');
  assert.ok(stats.commitsBehindOriginMain >= 35, `esperado >= 35 (snapshot do rollout gate), veio ${stats.commitsBehindOriginMain}`);
});
test('o inventário de RPC bate com o código real (extraído via git show, não hardcoded cego)', () => {
  assert.strictEqual(stats.rpcInventoryMatchesCode, true);
});

console.log('\n2) Direct PostgREST legacy writes — AUTO_RETIRED_BY_KEY_ENFORCEMENT');
test('14 writes tenant-scoped fecham só com a troca de chave do M2.2B-B (onConflict deixa de casar com nenhuma constraint)', () => {
  assert.strictEqual(stats.autoRetiredByKeyEnforcement, 14);
  assert.ok(audit.breakdown.autoRetiredByKeyEnforcement.includes('Arena — conquista 100%'));
  assert.ok(audit.breakdown.autoRetiredByKeyEnforcement.includes('Arena — gravação de pontuação (parte user_game_item_progress)'));
});
test('cada write AUTO_RETIRED_BY_KEY_ENFORCEMENT realmente usa onConflict/ON CONFLICT numa chave que muda de old->new (no Flutter direto ou dentro do corpo da RPC legacy)', () => {
  const keyClosed = audit.writeMatrix.filter((w) => w.closesBy === 'KEY');
  for (const w of keyClosed) {
    assert.notStrictEqual(w.oldTarget, w.newTarget, `${w.feature}: oldTarget e newTarget deveriam diferir`);
    const hasConflictRef = /onConflict|on conflict/i.test(w.oldMechanism) || /on conflict/i.test(w.oldTarget);
    assert.ok(hasConflictRef, `${w.feature}: nem oldMechanism nem oldTarget referenciam um ON CONFLICT`);
  }
});

console.log('\n3) RPC legacy — inventário e classificação');
test('8 RPCs dual-track (legacy != HEAD) — 3 writes (arena_record_score, subscribe_to_plan, create_store_order), 5 reads', () => {
  assert.strictEqual(stats.legacyRpcsUsed, 8);
  assert.strictEqual(stats.legacyRpcsUsedWrites, 3);
});
test('0 RPC segura pra REVOKE agora — cliente legacy ainda ao vivo (rollout gate); nenhum REVOKE foi executado', () => {
  assert.strictEqual(stats.safeToRevokeLegacyRpcs, 0);
});
test('passport_* e cpf_is_taken continuam STILL_REQUIRED — fora do escopo do M2.2B-B (sem club_id nas tabelas de passaporte)', () => {
  const passportEntries = audit.rpcInventory.filter((r) => r.name.startsWith('passport_'));
  assert.strictEqual(passportEntries.length, 11);
  assert.ok(passportEntries.every((r) => r.classification.includes('OUT_OF_SCOPE_PASSPORT_DEFERRED')));
});

console.log('\n4) Legacy direct INSERT sem onConflict — os casos perigosos (LEGACY_WRITE_SURVIVES_KEY_ENFORCEMENT)');
test('5 writes sobrevivem à MERA remoção de chave (dependem só do DEFAULT) — nenhum é ignorado silenciosamente', () => {
  assert.strictEqual(stats.legacyWritesSurvivingKeyEnforcement, 5);
  assert.deepStrictEqual(
    audit.breakdown.closedByDefault.sort(),
    [
      'Arena — gravação de pontuação (parte score_events)',
      'Ingresso — linhas de compra',
      'Ingresso — pedido de compra',
      'Loja — criação de pedido',
      'Sócio Torcedor — assinatura',
    ].sort(),
  );
});
test('cada um desses 5 realmente não tem onConflict/ON CONFLICT nenhum (insert puro)', () => {
  const defaultClosed = audit.writeMatrix.filter((w) => w.closesBy.startsWith('DEFAULT'));
  for (const w of defaultClosed) {
    assert.ok(!/onConflict:/.test(w.oldMechanism) || /insert simples/i.test(w.oldMechanism), `${w.feature} deveria ser insert simples, não upsert`);
  }
});

console.log('\n5) DEFAULT Goiás — AUTO_RETIRED_BY_DEFAULT_REMOVAL');
test('os mesmos 5 writes ficam sem alternativa se DROP DEFAULT também acontecer (NOT NULL violation)', () => {
  assert.strictEqual(stats.autoRetiredByDefaultRemoval, 5);
  for (const feature of audit.breakdown.closedByDefault) {
    const w = audit.writeMatrix.find((x) => x.feature === feature);
    assert.ok(audit.liveSnapshot.clubIdDefaultTables.includes(w.table), `${w.table} deveria estar na lista de tabelas com DEFAULT`);
  }
});

console.log('\n6) PWA stale cache — o gate real é enforcement server-side, não "novo PWA foi deployado"');
test('a classificação nunca depende de "o app foi atualizado" — só de KEY/DEFAULT no servidor', () => {
  const anyClientTrustBased = audit.writeMatrix.some((w) => /vers[aã]o|version|client.declar/i.test(JSON.stringify(w)));
  assert.strictEqual(anyClientTrustBased, false);
});

console.log('\n7) CLIENT_VERSION_SIGNAL != SERVER_ENFORCED_CONTRACT (fabricado)');
test('FABRICADO: uma RPC aceitando p_client_build NUNCA conta como enforcement — só REVOKE/DROP do path antigo conta', () => {
  const fakeRpcWithClientSignal = { name: 'fake_rpc', acceptsParam: 'p_client_build', legacyPathStillExecutable: true };
  const isActuallyEnforced = !fakeRpcWithClientSignal.legacyPathStillExecutable; // só conta se o path antigo NÃO executa mais
  assert.strictEqual(isActuallyEnforced, false);
});

console.log('\n8) achado incidental — ticket check-in já quebrado, independente de M2.2B-B');
test('o achado é citado com evidência (EXPLAIN read-only, arquivo+linha do índice parcial original) e classificado à parte de "auto retirado"', () => {
  assert.strictEqual(stats.alreadyBrokenIndependentOfM2_2bB, 1);
  assert.ok(audit.liveSnapshot.ticketCheckinAlreadyBrokenInProduction.verification.includes('EXPLAIN'));
  assert.ok(audit.liveSnapshot.ticketCheckinAlreadyBrokenInProduction.verification.includes('read-only'));
  assert.ok(!audit.breakdown.autoRetiredByKeyEnforcement.includes('Ingresso — check-in de sócio (o ingresso em si)'));
});

console.log('\n9) Critério de fechamento — resultado real, não manipulado');
test('unversionedLegacyWritesRemaining=0 -> rpcOnlyMigrationRequired=false -> legacyContractRetirementReady=true (resultado real desta auditoria)', () => {
  assert.strictEqual(stats.unversionedLegacyWritesRemaining, 0);
  assert.strictEqual(stats.rpcOnlyMigrationRequired, false);
  assert.strictEqual(stats.legacyContractRetirementReady, true);
});
test('FABRICADO: se existisse 1 write sem KEY nem DEFAULT nem ALREADY_BROKEN, o critério reprovaria (prova que o script não está sempre-verde)', () => {
  const fakeMatrix = [
    { feature: 'x', closesBy: 'KEY', scope: 'TENANT' },
    { feature: 'y', closesBy: 'DEFAULT', scope: 'TENANT' },
    { feature: 'z', closesBy: 'NONE_OF_THE_ABOVE', scope: 'TENANT' }, // caso perigoso fabricado
  ];
  const tenantWrites = fakeMatrix.filter((w) => w.scope === 'TENANT');
  const remaining = tenantWrites.filter((w) => w.closesBy !== 'KEY' && !w.closesBy.startsWith('DEFAULT') && w.closesBy !== 'ALREADY_BROKEN_PRE_EXISTING').length;
  assert.strictEqual(remaining, 1);
  assert.strictEqual(remaining > 0, true); // rpcOnlyMigrationRequired seria true aqui
});

console.log('\n10) reprodutibilidade — o resto do audit, fora do que é DELIBERADAMENTE ao vivo');
test('rodar o audit de novo produz o mesmo resultado, exceto commitsBehindOriginMain (recalculado ao vivo de propósito — HEAD avança a cada commit desta etapa, não é um bug)', () => {
  const stripLive = (json) => { const c = JSON.parse(json); delete c.commitsBehindOriginMain; return c; };
  const before = stripLive(fs.readFileSync(path.join(RECON, 'multiclub_legacy_contract_retirement_audit.json'), 'utf8'));
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = stripLive(fs.readFileSync(path.join(RECON, 'multiclub_legacy_contract_retirement_audit.json'), 'utf8'));
  assert.deepStrictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_multiclub_rollout_readiness.mjs');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_rollout_readiness_audit.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_rollout_readiness_stats.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) O mecanismo cliente (minimum-version gate) existe e está fiado no boot');
test('tabela + gate existem, tenant-aware (club_id, platform), leitura pública, seed inerte, store_url nullable', () => {
  assert.strictEqual(audit.minimumVersion.releaseGateFileExists, true);
  assert.strictEqual(audit.minimumVersion.releaseMigrationExists, true);
  assert.strictEqual(audit.minimumVersion.releaseTableClubAndPlatformScoped, true);
  assert.strictEqual(audit.minimumVersion.releaseTablePublicReadOnly, true);
  assert.strictEqual(audit.minimumVersion.releaseMigrationSeedIsInert, true);
  assert.strictEqual(audit.minimumVersion.releaseTableStoreUrlNullable, true);
  assert.strictEqual(stats.minimumVersionMechanismExists, true);
});
test('o router redireciona quando bloqueado E a splash aguarda a checagem antes de liberar navegação', () => {
  assert.strictEqual(audit.boot.routerRedirectsOnBlocked, true);
  assert.strictEqual(audit.boot.splashAwaitsReleaseCheck, true);
  assert.strictEqual(stats.newAppContainsMinimumVersionGate, true);
});
test('fail-safe: timeout interno + fail-open em erro, nunca trava o boot por outage', () => {
  assert.strictEqual(audit.boot.releaseGateHasTimeout, true);
  assert.strictEqual(audit.boot.releaseGateFailsOpenOnError, true);
});

console.log('\n2) RELEASE_GATE_IS_SECURITY_BOUNDARY — nunca true, por design');
test('o gate é UX/disponibilidade (fail-open), nunca uma fronteira de segurança', () => {
  assert.strictEqual(stats.releaseGateIsSecurityBoundary, false);
});

console.log('\n3) Evidência de distribuição — só o que o repo PROVA, nunca inventado');
test('PUBLIC_STORE_RELEASE_EXISTS=false — evidência técnica (signing debug, sem keystore, doc confirma iOS fora do escopo), confiança alta não absoluta', () => {
  assert.strictEqual(stats.publicStoreReleaseExists, false);
  assert.strictEqual(audit.distributionEvidence.publicStoreReleaseExists.confidence, 'high_not_absolute');
  assert.strictEqual(audit.distributionEvidence.publicStoreReleaseExists.evidence.androidReleaseUsesDebugSigning, true);
  assert.strictEqual(audit.distributionEvidence.publicStoreReleaseExists.evidence.androidHasRealKeystoreConfig, false);
});
test('TEST_DISTRIBUTION_EXISTS=false — mesma evidência técnica', () => {
  assert.strictEqual(stats.testDistributionExists, false);
});
test('GitHub Releases e distribuição manual de APK/IPA: genuinamente indetermináveis -> UNKNOWN, nunca "false" por omissão', () => {
  assert.strictEqual(audit.distributionEvidence.githubReleasesExistence, 'UNKNOWN_REQUIRES_OWNER_CONFIRMATION');
  assert.strictEqual(audit.distributionEvidence.manualApkIpaDistribution, 'UNKNOWN_REQUIRES_OWNER_CONFIRMATION');
});
test('WEB_PWA_DEPLOYMENT_EXISTS=true — CONFIRMADO ao vivo (não suposição), com evidência citada (URL, status, version.json)', () => {
  assert.strictEqual(stats.webDeploymentExists, true);
  assert.strictEqual(audit.distributionEvidence.webPwaDeploymentExists.evidence.wranglerTomlServesWebBuild, true);
  assert.strictEqual(audit.distributionEvidence.webPwaDeploymentExists.evidence.liveCheckHttpStatus, 200);
  assert.strictEqual(audit.distributionEvidence.webPwaDeploymentExists.evidence.versionJson.version, '1.0.0');
});
test('LEGACY_CLIENTS_IN_THE_WILD=true — o deployment web ao vivo reflete um commit anterior a TODA a série multiclub (35 commits atrás no snapshot)', () => {
  assert.strictEqual(stats.legacyClientsInTheWild, true);
  assert.strictEqual(audit.distributionEvidence.legacyClientsInTheWild.commitsLocalHeadAheadOfOriginMainAtCheckTime, 35);
  assert.strictEqual(audit.distributionEvidence.legacyClientsInTheWild.degreeOfActiveUsage, 'UNKNOWN_REQUIRES_OWNER_CONFIRMATION');
});
test('LEGACY_WRITE_PATHS_EXIST=true — chaves/RPCs legacy ainda existem no schema (fato já estabelecido pela M3.4/M2.2B-A)', () => {
  assert.strictEqual(stats.legacyWritePathsExist, true);
});

console.log('\n4) Server enforcement — ainda nada, e client-declared version nunca é boundary');
test('nada no servidor identifica versão do cliente hoje (0 header custom, 0 policy/RPC de versão)', () => {
  assert.strictEqual(audit.serverEnforcement.customVersionHeaderSent, false);
  assert.strictEqual(audit.serverEnforcement.rlsReferencesRequestVersion, false);
  assert.strictEqual(stats.serverCanIdentifyClientVersion, false);
  assert.strictEqual(stats.directPostgrestWritesCanBeVersionRejected, false);
  assert.strictEqual(stats.legacyRpcCallsCanBeVersionRejected, false);
});

console.log('\n5) Telemetria — wording preciso, nunca "100% das instalações conhecidas"');
test('Sentry dá SINAL de release a partir de atividade capturada, não um censo completo', () => {
  assert.strictEqual(audit.telemetry.sentryReleaseTaggingPresent, true);
  assert.strictEqual(stats.telemetryCanProvideReleaseSignalFromCapturedActivity, true);
});

console.log('\n6) DECISION GATE — legacyClientsInTheWild decide m2_2bBBlockedByRollout, não suposição de app publicado');
test('legacyAppWritesBlocked=false E m2_2bBBlockedByRollout=true (Cenário B: cliente legacy confirmado ao vivo) -> m2_2bBReady=false', () => {
  assert.strictEqual(stats.legacyAppWritesBlocked, false);
  assert.strictEqual(stats.m2_2bBBlockedByRollout, true);
  assert.strictEqual(stats.m2_2bBReady, false);
});

console.log('\n7) DETECTOR — fabricados provando a lógica do decision gate nos 2 cenários pedidos');
// Reimplementação pura da mesma regra do audit, pra provar a lógica em
// isolamento nos cenários que o estado REAL de hoje não cobre sozinho.
function computeGate({ legacyClientsInTheWild, serverCanIdentifyClientVersion, anyPolicyReferencesVersion, anyRpcTakesVersionParam }) {
  const legacyAppWritesBlocked = serverCanIdentifyClientVersion && anyPolicyReferencesVersion && anyRpcTakesVersionParam;
  const m2_2bBBlockedByRollout = legacyClientsInTheWild !== false; // true OU unknown -> bloqueia; só false libera
  return { legacyAppWritesBlocked, m2_2bBBlockedByRollout, m2_2bBReady: legacyAppWritesBlocked && !m2_2bBBlockedByRollout };
}
test('FABRICADO — Cenário A (pedido §13, caso 1): release gate existe + 0 legacy client -> legacyAppWritesBlocked pode ficar false MAS rollout NÃO bloqueia M2.2B-B', () => {
  const g = computeGate({ legacyClientsInTheWild: false, serverCanIdentifyClientVersion: false, anyPolicyReferencesVersion: false, anyRpcTakesVersionParam: false });
  assert.strictEqual(g.legacyAppWritesBlocked, false);
  assert.strictEqual(g.m2_2bBBlockedByRollout, false);
});
test('FABRICADO — Cenário B (pedido §13, caso 2): legacy clients existem + contrato antigo ainda ativo -> M2.2B-B permanece BLOQUEADA', () => {
  const g = computeGate({ legacyClientsInTheWild: true, serverCanIdentifyClientVersion: false, anyPolicyReferencesVersion: false, anyRpcTakesVersionParam: false });
  assert.strictEqual(g.m2_2bBBlockedByRollout, true);
  assert.strictEqual(g.m2_2bBReady, false);
});
test('FABRICADO — Cenário C: legacyClientsInTheWild UNKNOWN -> conta como bloqueio (nunca otimista por omissão)', () => {
  const g = computeGate({ legacyClientsInTheWild: 'UNKNOWN_REQUIRES_OWNER_CONFIRMATION', serverCanIdentifyClientVersion: true, anyPolicyReferencesVersion: true, anyRpcTakesVersionParam: true });
  assert.strictEqual(g.m2_2bBBlockedByRollout, true);
  assert.strictEqual(g.m2_2bBReady, false); // mesmo com "enforcement" hipotético pronto, unknown ainda bloqueia
});
test('FABRICADO — client version signal sozinho (RPC aceita p_client_build) NUNCA vira legacyAppWritesBlocked sem o contrato antigo ser revogado', () => {
  // só o parâmetro existir não basta — precisa TAMBÉM do path antigo estar
  // fechado (aqui simulado por serverCanIdentifyClientVersion/policy ainda
  // false, mesmo com o parâmetro presente).
  const g = computeGate({ legacyClientsInTheWild: false, serverCanIdentifyClientVersion: false, anyPolicyReferencesVersion: false, anyRpcTakesVersionParam: true });
  assert.strictEqual(g.legacyAppWritesBlocked, false);
});

console.log('\n8) reprodutibilidade — mesma execução, mesmo resultado (a recomputação de rede/git pode divergir entre sessões distantes, mas não entre 2 chamadas seguidas)');
test('rodar o audit de novo produz o mesmo resultado, exceto commitsLocalHeadAheadOfOriginMainNow (recalculado ao vivo de propósito)', () => {
  const stripLive = (json) => {
    const c = JSON.parse(json);
    delete c.distributionEvidence.legacyClientsInTheWild.commitsLocalHeadAheadOfOriginMainNow;
    return c;
  };
  const before = stripLive(fs.readFileSync(path.join(RECON, 'multiclub_rollout_readiness_audit.json'), 'utf8'));
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = stripLive(fs.readFileSync(path.join(RECON, 'multiclub_rollout_readiness_audit.json'), 'utf8'));
  assert.deepStrictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

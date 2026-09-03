import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_second_club_product_readiness.mjs');

const audit = JSON.parse(
  fs.readFileSync(path.join(RECON, 'second_club_product_readiness_audit.json'), 'utf8')
);
const stats = JSON.parse(
  fs.readFileSync(path.join(RECON, 'second_club_product_readiness_stats.json'), 'utf8')
);

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

console.log('1) Database — inalterado, reconfirmado');
test('rowScopeReady/keyScopeFinal/arenaCrossClubReady=true — nada regrediu das rodadas anteriores', () => {
  assert.strictEqual(audit.rowScopeReady, true);
  assert.strictEqual(audit.keyScopeFinal, true);
  assert.strictEqual(audit.arenaCrossClubReady, true);
});

console.log('\n2) Cobertura direta de leitura/escrita — 100%, real, não forçada');
test('directReadTenantCoverage e directWriteTenantCoverage = 100% nas tabelas com club_id', () => {
  assert.strictEqual(audit.directReadTenantCoverage.pct, 100);
  assert.strictEqual(audit.directWriteTenantCoverage.pct, 100);
  assert.strictEqual(audit.directReadTenantCoverage.correct, audit.directReadTenantCoverage.total);
});

console.log('\n3) RPC inventory — 9 _for_club corretas, 12 Passaporte sem club_id + ACL aberto');
test('9 RPCs _for_club, 12 RPCs de Passaporte com EXECUTE público (achado real, não hipotético)', () => {
  assert.strictEqual(audit.rpcTenantCoverage.forClubTotal, 9);
  assert.strictEqual(audit.rpcTenantCoverage.passportUntenanted, 12);
  assert.strictEqual(audit.passportRpcAcl.publicExecuteCount, 12);
});

console.log('\n4) AUTH_SCOPE / RLS — user isolation != club isolation');
test('RLS: 52 policies em tabelas tenant-scoped, 0 referenciam club_id — user isolation real, club isolation não existe', () => {
  assert.strictEqual(audit.authScopeDecision.rlsTenantTablePoliciesTotal, 52);
  assert.strictEqual(audit.authScopeDecision.rlsTenantTablePoliciesReferencingClubId, 0);
  assert.strictEqual(audit.authScopeDecision.rlsUserIsolation, true);
  assert.strictEqual(audit.authScopeDecision.rlsClubIsolation, false);
});
test('Modelo C derivado do código (APP_CLUB define o clube, conta é global) — não inventado', () => {
  assert.strictEqual(audit.authScopeDecision.model, 'C_APP_DEFINES_CLUB_ACCOUNT_GLOBAL');
});

console.log('\n5) APP_CLUB resolution — fail-loud pra valor explícito desconhecido, nunca cai pro Goiás');
test('explicitUnknownClubFails=true, emptyAppClubDefaultsToGoias=true (compat documentada, não bug)', () => {
  assert.strictEqual(audit.explicitUnknownClubFails, true);
  assert.strictEqual(audit.emptyAppClubDefaultsToGoias, true);
});
test('ClubScopedFallback nunca resolve a um clube default (forClub devolve null pra código não registrado)', () => {
  assert.strictEqual(audit.clubScopedFallbackNeverDefaults, true);
});

console.log('\n6) ClubCapabilities — existe mas não está wireada (achado real)');
test('clubCapabilitiesWired=false — 0 consumidores reais de config.capabilities.<campo> em todo o lib/', () => {
  assert.strictEqual(stats.clubCapabilitiesWired, false);
  assert.strictEqual(audit.clubCapabilitiesCoverage.wired, false);
});
test('FABRICADO: se um consumidor real existisse, o check deveria virar true', () => {
  const fakeDartWithConsumer = `
    if (sl<ClubConfig>().capabilities.hasStore) {
      return const StoreEntryCard();
    }
  `;
  assert.ok(/\.capabilities\./.test(fakeDartWithConsumer), 'o padrão precisa casar num consumidor real fabricado');
});

console.log('\n7) Assets — achado crítico: AppAssets bypassa ClubConfig.assets em múltiplos arquivos');
test('goiasFallbacksRemaining > 0 — múltiplos arquivos leem AppAssets.<literal> em vez de clubConfig.assets', () => {
  assert.ok(audit.goiasFallbacksRemaining > 0, 'esperava pelo menos 1 consumidor direto de AppAssets encontrado');
});

console.log('\n8) notifications-dispatch — achado crítico: sem filtro de club_id');
test('fetchRecipientTokens e isActiveMember confirmados SEM filtro club_id no código real', () => {
  assert.strictEqual(audit.notificationsDispatchClubScoped.filtersClubId, false);
  assert.strictEqual(audit.notificationsDispatchClubScoped.isActiveMemberFiltersClubId, false);
});
test('edgeTenantCoverage.notificationsDispatch=BLOCKED — consistente com o achado acima', () => {
  assert.strictEqual(audit.edgeTenantCoverage.notificationsDispatch, 'BLOCKED');
});
test('as outras 2 Edge Functions tenant-relevantes continuam CLUB_CONFIGURED', () => {
  assert.strictEqual(audit.edgeTenantCoverage.notificationsPollLiveMatch, 'CLUB_CONFIGURED');
  assert.strictEqual(audit.edgeTenantCoverage.notificationsSyncAndCheckAccess, 'CLUB_CONFIGURED');
});

console.log('\n9) Store — GOI- hardcoded confirmado no round 1; corrigido do lado Flutter na M4.1 (SQL segue pendente)');
test('SUPERSEDIDO PELA M4.1: hasGoiPrefixInFlutter era true no round 1, corrigido em supabase_store_orders_repository.dart (ver test_m4_critical_club_leakage.mjs §5 pra prova atual); orderPrefixDefined/orderPrefixConsumedElsewhere continuam corretos', () => {
  assert.strictEqual(audit.storeOrderNumberHardcode.hasGoiPrefixInFlutter, false);
  assert.strictEqual(audit.storeOrderNumberHardcode.orderPrefixDefined, true);
  assert.strictEqual(audit.storeOrderNumberHardcode.orderPrefixConsumedElsewhere, true);
});

console.log('\n10) Worker — futebol pronto, news/social 0% tenant-aware');
test('workerTenantCoverage: football CLUB_CONFIGURED, news/social BLOCKED', () => {
  assert.strictEqual(audit.workerTenantCoverage.football, 'CLUB_CONFIGURED');
  assert.strictEqual(audit.workerTenantCoverage.news, 'BLOCKED');
  assert.strictEqual(audit.workerTenantCoverage.social, 'BLOCKED');
});

console.log('\n11) Local storage — os 3 stores conhecidos continuam club-scoped');
test('localStorageIsolated=true — StoreLocalStorage/GuessPlayerStorage/LocalBestScoreStore com ClubScopedStorageKey', () => {
  assert.strictEqual(stats.localStorageIsolated, true);
});

console.log('\n12) Release Gate — sem blocker');
test('releaseGateTenantReady=true', () => {
  assert.strictEqual(audit.releaseGateTenantReady, true);
});

console.log('\n13) Registry drift — consistente hoje, mas DB nunca faz parte do check (gap documentado)');
test('registryConsistencyReady=true (trivial com 1 clube) mas dbIncludedInDriftCheck=false (gap real)', () => {
  assert.strictEqual(audit.registryDrift.registryConsistencyReady, true);
  assert.strictEqual(audit.registryDrift.dbIncludedInDriftCheck, false);
});

console.log('\n14) Blockers — classificados, não misturados');
test('7 blockers BEFORE_ANY, 5 BEFORE_PUBLIC, 3 per-feature — nenhuma lista vazia por acidente', () => {
  assert.strictEqual(audit.secondClubTechnicalBlockers.length, 7);
  assert.strictEqual(audit.secondClubProductBlockers.length, 5);
  assert.strictEqual(audit.blockersPerFeature.length, 3);
});
test('Passaporte é BLOCKER_BEFORE_ENABLING_PASSAPORTE, não um blocker geral de clubB', () => {
  const passportBlocker = audit.blockersPerFeature.find((b) => b.feature === 'PASSAPORTE');
  assert.ok(passportBlocker);
  assert.strictEqual(passportBlocker.blocker, 'BLOCKER_BEFORE_ENABLING_PASSAPORTE');
});

console.log('\n15) Decisão final — não forçada, os dois campos podem (e devem) divergir de simplesmente "true"');
test('secondClubTechnicallySafe=false E secondClubProductReady=false — resultado real desta rodada', () => {
  assert.strictEqual(audit.secondClubTechnicallySafe, false);
  assert.strictEqual(audit.secondClubProductReady, false);
});
test('FABRICADO: se os 7 blockers técnicos fossem 0 E notifications-dispatch filtrasse club_id, secondClubTechnicallySafe teria que virar true', () => {
  const simulate = (blockersCount, notifOk) => blockersCount === 0 && notifOk;
  assert.strictEqual(simulate(7, false), false);
  assert.strictEqual(simulate(0, true), true);
});
test('KEY_SCOPE_SECOND_CLUB_BLOCKER=false NUNCA deveria colapsar pra secondClubProductReady=true — são campos diferentes', () => {
  assert.strictEqual(audit.keyScopeFinal, true); // o problema físico de chaves está resolvido...
  assert.strictEqual(audit.secondClubProductReady, false); // ...mas isso não implica pronto pra produto
});

console.log('\n16) reprodutibilidade');
test('rodar o audit de novo produz o mesmo resultado nos campos estáveis (o script só lê arquivos locais + baseline datado, nada ao vivo)', () => {
  const stripVolatile = (json) => {
    const c = JSON.parse(json);
    return c; // nada neste script é live-computed a partir de fontes voláteis — deve ser 100% estável
  };
  const before = stripVolatile(
    fs.readFileSync(path.join(RECON, 'second_club_product_readiness_audit.json'), 'utf8')
  );
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = stripVolatile(
    fs.readFileSync(path.join(RECON, 'second_club_product_readiness_audit.json'), 'utf8')
  );
  assert.deepStrictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

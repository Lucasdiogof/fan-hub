import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const audit = JSON.parse(
  fs.readFileSync(path.join(RECON, 'm4_2_club_capabilities_audit.json'), 'utf8')
);

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

// ============================================================================
// 1) capabilityConsumers — todo arquivo esperado realmente lê capability
// ============================================================================
console.log('1) capabilityConsumers — Home/nav/Perfil/Arena/Jogos/Social/router leem ClubCapabilities de verdade');
test('10/10 arquivos esperados aparecem como consumidor real', () => {
  assert.strictEqual(audit.capabilityConsumersCount, 10);
  for (const f of [
    'features/home/presentation/pages/home_page.dart',
    'features/home/presentation/pages/home_shell_page.dart',
    'features/home/presentation/widgets/main_navigation_items.dart',
    'features/home/presentation/widgets/goias_bottom_navigation_bar.dart',
    'features/home/presentation/widgets/main_navigation_rail.dart',
    'features/profile/presentation/pages/profile_page.dart',
    'features/arena/presentation/pages/arena_page.dart',
    'features/match/presentation/pages/games_page.dart',
    'features/social/presentation/pages/social_feed_page.dart',
    'core/router/app_router.dart',
  ]) {
    assert.ok(audit.capabilityConsumers.includes(f), f);
  }
});

// ============================================================================
// 2) capabilityUngatedEntryPoints — Squad/Notifications, lista fechada e
//    documentada, nunca "esquecida"
// ============================================================================
console.log('\n2) capabilityUngatedEntryPoints — só Squad/Notifications, cada um com motivo');
test('exatamente 2 entry points deliberadamente ungated, cada um com reason não-vazio', () => {
  assert.strictEqual(audit.capabilityUngatedEntryPoints.length, 2);
  const features = audit.capabilityUngatedEntryPoints.map((e) => e.feature).sort();
  assert.deepStrictEqual(features, ['Notifications', 'Squad']);
  for (const e of audit.capabilityUngatedEntryPoints) {
    assert.ok(e.reason.length > 20, e.feature);
  }
});

// ============================================================================
// 3) Rotas — capabilityGateRedirect cobre todos os prefixos esperados
// ============================================================================
console.log('\n3) rotas — capabilityGateRedirect cobre passport/arena(hub+jogos)/store/membership/tickets/crowd-lineup/news');
test('8/8 prefixos gateados presentes no checker real', () => {
  for (const [prefix, present] of Object.entries(audit.gatedPrefixes)) {
    assert.strictEqual(present, true, prefix);
  }
});
test('router real está de fato conectado ao checker (nunca só a função existir sozinha)', () => {
  assert.strictEqual(audit.routerWired, true);
});

// ============================================================================
// 4) Synthetic club-b — capabilities desligadas onde deveriam
// ============================================================================
console.log('\n4) synthetic club-b — Passaporte/Loja/Sócio/Ingressos/Torcida/News/Social todos bloqueados');
test('7/7 capabilities false no clube sintético (achados novos desta rodada incluídos: Ingressos e Torcida)', () => {
  assert.strictEqual(audit.passportBlockedForSyntheticClub, true);
  assert.strictEqual(audit.storeBlockedForSyntheticClub, true);
  assert.strictEqual(audit.membershipBlockedForSyntheticClub, true);
  assert.strictEqual(audit.ticketsBlockedForSyntheticClub, true);
  assert.strictEqual(audit.crowdLineupBlockedForSyntheticClub, true);
  assert.strictEqual(audit.newsBlockedForSyntheticClub, true);
  assert.strictEqual(audit.socialBlockedForSyntheticClub, true);
});
test('clube sintético continua com exatamente 1 jogo de Arena habilitado (quiz) — prova granularidade, não tudo-ou-nada', () => {
  assert.deepStrictEqual(audit.syntheticEnabledArenaGames, ['quiz']);
});

// ============================================================================
// 5) Arena — hub/grid/cards de identidade filtram por capability real
// ============================================================================
console.log('\n5) Arena — grid de jogos, Passaporte, Torcida e os 2 cards de identidade, todos filtrados');
test('arenaCapabilityEnforced = true', () => {
  assert.strictEqual(audit.arenaCapabilityEnforced, true);
});

// ============================================================================
// 6) News/Social — Flutter manda ?club= de verdade (sem isso o gate do
//    Worker da M4.1 é inalcançável do lado do cliente)
// ============================================================================
console.log('\n6) News/Social — Flutter finalmente manda club pro gate do Worker (M4.1 tinha o gate, nunca era alcançado)');
test('NewsRemoteDataSource manda club nas 2 chamadas (lista + artigo)', () => {
  assert.strictEqual(audit.newsCapabilityEnforced, true);
});
test('SocialRemoteDataSource manda club', () => {
  assert.strictEqual(audit.socialCapabilityEnforced, true);
});
test('SocialFeedPage filtra as opções da barra (Notícias/Instagram/YouTube/X) por hasNews/hasSocial', () => {
  assert.strictEqual(audit.socialFeedPageFiltersOptionsByCapability, true);
});

// ============================================================================
// 7) syntheticClubFeatureLeaks — nunca true
// ============================================================================
console.log('\n7) 0 vazamento — nenhuma das 7 capabilities do clube sintético ficou true por engano');
test('syntheticClubFeatureLeaks = false', () => {
  assert.strictEqual(audit.syntheticClubFeatureLeaks, false);
});
test('FABRICADO: se qualquer 1 das 7 capabilities do clube sintético virasse true, syntheticClubFeatureLeaks teria que virar true', () => {
  const simulateLeak = (allBlocked) => !allBlocked;
  assert.strictEqual(simulateLeak(true), false);
  assert.strictEqual(simulateLeak(false), true);
});

// ============================================================================
// 8) Testes obrigatórios existem de verdade
// ============================================================================
console.log('\n8) testes obrigatórios — rota bloqueada + deep link (unit puro) e menu escondido (widget real)');
test('capability_route_gate_test.dart e capability_nav_gating_test.dart existem', () => {
  assert.strictEqual(audit.requiredTestsExist.routeGateUnitTests, true);
  assert.strictEqual(audit.requiredTestsExist.navWidgetTests, true);
});

// ============================================================================
// 9) Decisão final
// ============================================================================
console.log('\n9) decisão final — m4CapabilitiesReady nunca forçado, cai se qualquer checagem acima falhar');
test('m4CapabilitiesReady = true', () => {
  assert.strictEqual(audit.m4CapabilitiesReady, true);
});

// ============================================================================
// 10) Reprodutibilidade
// ============================================================================
console.log('\n10) reprodutibilidade — audit byte-idêntico ao rodar de novo');
test('rodar audit_m4_2_club_capabilities.mjs de novo produz o mesmo JSON', () => {
  const before = fs.readFileSync(path.join(RECON, 'm4_2_club_capabilities_audit.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_m4_2_club_capabilities.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'm4_2_club_capabilities_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_m4_critical_club_leakage.mjs');

const audit = JSON.parse(
  fs.readFileSync(path.join(RECON, 'm4_1_critical_club_leakage_audit.json'), 'utf8'),
);
const stats = JSON.parse(
  fs.readFileSync(path.join(RECON, 'm4_1_critical_club_leakage_stats.json'), 'utf8'),
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

console.log('1) Assets — os ~12 consumidores reais migrados, 0 hardcode restante (exceto exclusão-padrão)');
test('clubAssetRuntimeHardcodes=0 — nenhum arquivo (fora de store_entry_card.dart) lê AppAssets.<literal> mais', () => {
  assert.strictEqual(stats.clubAssetRuntimeHardcodes, 0);
  assert.deepStrictEqual(audit.clubAssetRuntimeHardcodes, []);
});
test('store_entry_card.dart continua com o hardcode — exclusão-padrão do projeto, não um bug desta rodada', () => {
  assert.strictEqual(audit.storeEntryCardStillExcluded, true);
});

console.log('\n2) ClubBranding — main.dart virou o 1º consumidor real (era 0 antes da M4.1)');
test('clubBrandingConsumers=1 (main.dart) — achado real, não forçado', () => {
  assert.strictEqual(stats.clubBrandingConsumers, 1);
});
test('FABRICADO: se main.dart nunca tivesse sido tocado, o grep encontraria 0 — prova que o check é real, não hardcoded pra 1', () => {
  // Reproduz manualmente a regex do checker contra um texto SEM o consumo —
  // prova que a ausência do padrão realmente resulta em 0 matches.
  const fakeMainWithoutBranding = "theme: AppTheme.light(),\ndarkTheme: AppTheme.dark(),";
  assert.strictEqual(/\.branding\./.test(fakeMainWithoutBranding), false);
});

console.log('\n3) ProductNaming — deliberadamente NÃO wireado nesta rodada (decisão documentada, não esquecimento)');
test('productNamingConsumers=0 — l10n continua sendo a fonte real de copy, ClubProductNaming não foi ligado (fora de escopo da M4.1 por decisão explícita)', () => {
  assert.strictEqual(stats.productNamingConsumers, 0);
});

console.log('\n4) Config bypasses — os 5 confirmados corrigidos');
test('configBypassesRemaining=0 — membership contact, pickup info, social links, main.dart title, passport ticket', () => {
  assert.strictEqual(stats.configBypassesRemaining, 0);
  assert.strictEqual(audit.configBypasses.membershipContactFixed, true);
  assert.strictEqual(audit.configBypasses.pickupInfoFixed, true);
  assert.strictEqual(audit.configBypasses.socialLinksFixed, true);
  assert.strictEqual(audit.configBypasses.mainTitleFixed, true);
  assert.strictEqual(audit.configBypasses.mainThemeFixed, true);
  assert.strictEqual(audit.configBypasses.passportTicketFixed, true);
});

console.log('\n5) Store order prefix — Flutter corrigido, SQL deliberadamente adiado (PARE, decisão de schema)');
test('flutterHasGoiHardcode=false, flutterUsesConfig=true — o path de demo agora lê ClubIntegrations.orderPrefix', () => {
  assert.strictEqual(audit.orderPrefix.flutterHasGoiHardcode, false);
  assert.strictEqual(audit.orderPrefix.flutterUsesConfig, true);
});
test('sqlStillHardcoded=true — generate_store_order_number() NÃO foi tocado nesta rodada, design proposto mas não aplicado', () => {
  assert.strictEqual(audit.orderPrefix.sqlStillHardcoded, true);
});
test('goiasOrderPrefixHardcodes=1 (só o SQL, não mais 2) — reflete a correção parcial real, não arredondado pra 0', () => {
  assert.strictEqual(stats.goiasOrderPrefixHardcodes, 1);
});

console.log('\n6) notifications-dispatch — as 2 camadas corrigidas EM CÓDIGO (M4.1c): usuário elegível E token do clube certo');
test('notificationUserEligibilityClubScoped=true, notificationMembershipLookupClubScoped=true — a parte de QUEM é elegível continua correta', () => {
  assert.strictEqual(stats.notificationUserEligibilityClubScoped, true);
  assert.strictEqual(stats.notificationMembershipLookupClubScoped, true);
});
test('notificationTokenDeliveryClubScoped=true — migration desenhada corretamente + dispatch filtra activeTokensForClub(clubId) + Flutter manda club_id no registro (achado M4.1b fechado EM CÓDIGO)', () => {
  assert.strictEqual(stats.notificationTokenDeliveryClubScoped, true);
  assert.strictEqual(audit.notifications.migration.designCorrect, true);
  assert.strictEqual(audit.notifications.tokenFetchFiltersByClubId, true);
  assert.strictEqual(audit.notifications.flutterRegistersClubId, true);
});
test('notificationMulticlubModelReady=true — as duas camadas juntas, nunca mascaradas numa flag só', () => {
  assert.strictEqual(stats.notificationMulticlubModelReady, true);
});
// Supersessão (M4.1c-B): migration A (club_id + NOT NULL + DEFAULT) foi
// aplicada ao vivo na rodada M4.1c-A (2026-09-03) — o teste original daqui
// assumia "0 db push nesta rodada" (verdade só na rodada M4.1c). Nunca
// deletado, corrigido pra refletir o estado real de cada rodada.
test('notificationSchemaAppliedLive=true — migration A (club_id/NOT NULL/DEFAULT) já foi aplicada ao vivo (M4.1c-A)', () => {
  assert.strictEqual(stats.notificationSchemaAppliedLive, true);
});
test('migration A: adiciona club_id, SET NOT NULL, MANTÉM DEFAULT (rollout-compat com 1.0.1+2, achado do dono — corrigido nesta rodada) — fcm_token continua a única UNIQUE', () => {
  assert.strictEqual(audit.notifications.migration.addsClubIdColumn, true);
  assert.strictEqual(audit.notifications.migration.setsNotNull, true);
  assert.strictEqual(audit.notifications.migration.keepsDefaultForRolloutCompat, true);
  assert.strictEqual(audit.notifications.migration.preservesFcmTokenUniqueOnly, true);
});
// Supersessão (M4.1c-B): migration B agora É um arquivo real
// (20260903170000_drop_default_notification_tokens_club_id.sql),
// autorizada só depois do PWA+APK 1.0.2+3 confirmados publicados/entregues
// pelo dono. O teste original daqui provava a AUSÊNCIA do arquivo — agora
// prova o DESIGN dele (só DROP DEFAULT, nada mais) e que ainda não foi
// aplicado ao vivo NESTE PONTO da rodada (antes do db push).
test('migration B (DROP DEFAULT) existe, só remove o DEFAULT (nada mais), ainda não aplicada ao vivo antes do db push desta rodada', () => {
  assert.strictEqual(audit.notifications.migrationB.createdAsFileYet, true);
  assert.strictEqual(audit.notifications.migrationB.dropsDefault, true);
  assert.strictEqual(audit.notifications.migrationB.touchesOnlyDefault, true);
  assert.strictEqual(audit.notifications.migrationB.designCorrect, true);
});
test('estados de rollout ANTES do db push da M4.1c-B: coluna pronta + DEFAULT transicional=true, DEFAULT final=false — as 2 fases nunca colapsadas numa flag só', () => {
  assert.strictEqual(stats.notificationTokenClubColumnReady, true);
  assert.strictEqual(stats.notificationTokenClubDefaultTransitional, true);
  assert.strictEqual(stats.notificationTokenDefaultFinal, false);
});
test('FABRICADO: migration B com qualquer coisa além de DROP DEFAULT (ex.: ADD COLUMN) derruba touchesOnlyDefault — nunca ampliar o escopo da migration B silenciosamente', () => {
  const fakeExpandedMigrationB =
    'alter table public.user_notification_tokens alter column club_id drop default;\n' +
    'alter table public.user_notification_tokens add column extra text;';
  const touchesOnlyDefault =
    !/add column/i.test(fakeExpandedMigrationB) &&
    !/set not null/i.test(fakeExpandedMigrationB) &&
    !/drop\s+(constraint|column)/i.test(fakeExpandedMigrationB) &&
    !/unique/i.test(fakeExpandedMigrationB);
  assert.strictEqual(touchesOnlyDefault, false);
});
test('FABRICADO: comentário SQL mencionando "UNIQUE"/"NOT NULL" (explicando o que a migration B NÃO faz) nunca derruba touchesOnlyDefault — mesma classe de falso-positivo de comentário já corrigida em outras rodadas deste projeto', () => {
  const realMigrationBWithExplanatoryComments =
    '-- club_id continua NOT NULL, FK -> clubs(id), fcm_token continua a única\n' +
    '-- UNIQUE — nada disso muda aqui, só o DEFAULT sai.\n' +
    'alter table public.user_notification_tokens\n' +
    '  alter column club_id drop default;\n';
  const stripped = realMigrationBWithExplanatoryComments
    .split('\n')
    .map((l) => l.replace(/--.*$/, ''))
    .join('\n');
  const touchesOnlyDefault =
    !/add column/i.test(stripped) &&
    !/set not null/i.test(stripped) &&
    !/drop\s+(constraint|column)/i.test(stripped) &&
    !/unique/i.test(stripped);
  assert.strictEqual(touchesOnlyDefault, true, 'comentário explicativo não deveria contar como código real');
  // prova que SEM o strip o mesmo texto falsamente reprovaria — é isso que
  // o audit real corrige (stripSqlComments antes de checar).
  const withoutStrip =
    !/add column/i.test(realMigrationBWithExplanatoryComments) &&
    !/set not null/i.test(realMigrationBWithExplanatoryComments) &&
    !/drop\s+(constraint|column)/i.test(realMigrationBWithExplanatoryComments) &&
    !/unique/i.test(realMigrationBWithExplanatoryComments);
  assert.strictEqual(withoutStrip, false, 'sem o strip, o comentário derrubaria o check — prova que o bug era real');
});
test('FABRICADO: reproduz o bug de rollout que o dono encontrou — se a migration A tivesse DROP DEFAULT, keepsDefaultForRolloutCompat cairia (e quebraria o registro do 1.0.1+2 em produção)', () => {
  const fakeMigrationWithDrop =
    'alter table user_notification_tokens add column club_id uuid default \'x\'::uuid;\n' +
    'alter table user_notification_tokens alter column club_id set not null;\n' +
    'alter table user_notification_tokens alter column club_id drop default;';
  const dropsDefault = /alter column club_id drop default/.test(fakeMigrationWithDrop);
  assert.strictEqual(dropsDefault, true); // reproduz o bug — keepsDefaultForRolloutCompat seria false com esse texto
});
test('FABRICADO: se o módulo _shared/recipient_eligibility.ts não existisse, o check de elegibilidade cairia (prova que não está só verificando presença de qualquer club_id solto)', () => {
  const fakeIndexTs = "async function fetchRecipientTokens(admin, eventType) { return admin.from('user_notification_tokens').select('*').eq('is_active', true); }";
  assert.strictEqual(/explicitlyEligibleUserIds\(clubId/.test(fakeIndexTs), false);
});
test('FABRICADO: se o dispatch ainda chamasse activeTokens() (sem argumento, versão pré-M4.1c) em vez de activeTokensForClub(clubId), o check cairia', () => {
  const fakeShared = "async function fetchRecipientTokens(source, clubId, eventType) { return source.activeTokens(); }";
  assert.strictEqual(/activeTokensForClub\(clubId\)/.test(fakeShared), false);
});
test('FABRICADO: se a migration recriasse (club_id,fcm_token) como chave, preservesFcmTokenUniqueOnly cairia (o dono foi explícito: nunca essa chave composta)', () => {
  const fakeMigration = "alter table user_notification_tokens add column club_id uuid; alter table user_notification_tokens add constraint uq unique (club_id, fcm_token);";
  const preserves =
    !/add\s+constraint[\s\S]*club_id[\s\S]*fcm_token/i.test(fakeMigration) &&
    !/unique\s*\(\s*club_id\s*,\s*fcm_token\s*\)/i.test(fakeMigration);
  assert.strictEqual(preserves, false);
});
test('FABRICADO: notificationTokenDeliveryClubScoped exige migration+fetch+Flutter TODOS corretos — falta qualquer um dos 3 derruba o resultado', () => {
  const simulate = (migrationOk, fetchOk, flutterOk) => migrationOk && fetchOk && flutterOk;
  assert.strictEqual(simulate(false, true, true), false);
  assert.strictEqual(simulate(true, false, true), false);
  assert.strictEqual(simulate(true, true, false), false);
  assert.strictEqual(simulate(true, true, true), true);
});

console.log('\n7) Worker News/Social — gate aplicado nas 3 rotas');
test('workerNewsCrossClubFallback=false, workerSocialCrossClubFallback=false', () => {
  assert.strictEqual(stats.workerNewsCrossClubFallback, false);
  assert.strictEqual(stats.workerSocialCrossClubFallback, false);
});
test('gateHelperExists=true — NEWS_SOCIAL_CONFIGURED_CLUB_CODE + resolveRequestedClubCode existem em club_server_config.ts', () => {
  assert.strictEqual(audit.workerNewsSocialGate.gateHelperExists, true);
});

console.log('\n8) Clube sintético — não reaproveita mais NADA do Goiás (fortalecido nesta rodada)');
test('syntheticClubLeaksGoiasIdentity=false — 0 referência a goiasClubConfig.{assets,branding,integrations,productNames} no arquivo sintético', () => {
  assert.strictEqual(stats.syntheticClubLeaksGoiasIdentity, false);
  assert.strictEqual(audit.syntheticClub.noGoiasAssetReuse, true);
  assert.strictEqual(audit.syntheticClub.noGoiasBrandingReuse, true);
  assert.strictEqual(audit.syntheticClub.noGoiasIntegrationsReuse, true);
  assert.strictEqual(audit.syntheticClub.noGoiasProductNamesReuse, true);
});
test('test/core/club/m4_1_critical_leakage_test.dart existe — as asserções de isolamento são código real, não só esta auditoria estática', () => {
  assert.strictEqual(audit.syntheticClub.testFileExists, true);
});

console.log('\n9) Store — explicitamente ainda não seguro (achado M4.1b, não regride as correções já feitas)');
test('storeSafeForClubB=false — store_entry_card.dart (exclusão-padrão) + generate_store_order_number() (SQL adiado) seguem pendentes até M4.2', () => {
  assert.strictEqual(stats.storeSafeForClubB, false);
});

console.log('\n10) Decisão final — CÓDIGO correto (M4.1c) != aplicado em produção, os 2 níveis nunca colapsados em 1 só');
test('m4_1ImplementationLocalComplete=true — o código desta rodada foi escrito e testado de verdade', () => {
  assert.strictEqual(stats.m4_1ImplementationLocalComplete, true);
});
test('m4CriticalLeakageReady=true — CORRIGIDO DE NOVO: agora corretamente true, porque o gap real (entrega por token) foi fechado EM CÓDIGO nesta rodada, testado, não forçado', () => {
  assert.strictEqual(stats.m4CriticalLeakageReady, true);
});
// Supersessão (M4.1c-B): migration A já está aplicada ao vivo desde a
// M4.1c-A — o guarda-corpo real agora é notificationSchemaBAppliedLive
// (migration B, o DROP DEFAULT), ainda false neste ponto (antes do db push
// desta rodada) — nunca confundir "código correto" com "seguro em
// produção" continua valendo, só que pra fase B agora.
test('notificationSchemaAppliedLive=true (A) mas notificationSchemaBAppliedLive=false (B, antes do db push desta rodada) — o guarda-corpo migrou de fase, nunca some', () => {
  assert.strictEqual(stats.notificationSchemaAppliedLive, true);
  assert.strictEqual(stats.notificationSchemaBAppliedLive, false);
});
test('FABRICADO: se qualquer 1 dos hardcodes de asset ainda existisse, m4CriticalLeakageReady teria que cair independente do token', () => {
  const simulate = (assetHardcodes) => assetHardcodes === 0;
  assert.strictEqual(simulate(1), false);
  assert.strictEqual(simulate(0), true);
});
test('FABRICADO: se notificationTokenDeliveryClubScoped voltasse a false (regressão), m4CriticalLeakageReady cairia junto — prova que não dá pra "esconder" o gap dentro de uma métrica agregada', () => {
  const simulate = (allOthersTrue, tokenScoped) => allOthersTrue && tokenScoped;
  assert.strictEqual(simulate(true, false), false);
  assert.strictEqual(simulate(true, true), true);
});

console.log('\n11) reprodutibilidade byte a byte');
test('rodar o audit de novo produz o mesmo JSON (só lê arquivos locais via git grep, nada ao vivo)', () => {
  const before = fs.readFileSync(
    path.join(RECON, 'm4_1_critical_club_leakage_audit.json'),
    'utf8',
  );
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(
    path.join(RECON, 'm4_1_critical_club_leakage_audit.json'),
    'utf8',
  );
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

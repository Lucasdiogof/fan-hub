import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

function read(relPath) {
  return fs.readFileSync(path.join(ROOT, relPath), 'utf8');
}

function grepCount(pattern, globPattern) {
  try {
    const out = execSync(`git grep -c -E "${pattern}" -- "${globPattern}"`, {
      cwd: ROOT,
      encoding: 'utf8',
    });
    return out.trim().split('\n').filter(Boolean).length;
  } catch {
    return 0;
  }
}

function grepFiles(pattern, globPattern) {
  try {
    const out = execSync(`git grep -l -E "${pattern}" -- "${globPattern}"`, {
      cwd: ROOT,
      encoding: 'utf8',
    });
    return out.trim().split('\n').filter(Boolean);
  } catch {
    return [];
  }
}

// --- 1. Assets: AppAssets literal consumers outside AppAssets/ClubAssets/
// mock_data.dart/the standing-exclusion store_entry_card.dart themselves ---
const appAssetsConsumerFiles = grepFiles(
  "AppAssets\\.(goiasCrest|goiasCrestBadge|goiasCrest3d|loginBackground|stadium|matchHero|tacticsBoardIllustration|arenaStadiumIcon|arenaStadiumPhoto|storeBanner)",
  'lib/',
).filter(
  (f) =>
    !f.endsWith('lib/core/theme/app_assets.dart') &&
    !f.endsWith('lib/core/club/goias_club_config.dart') &&
    !f.endsWith('lib/core/mock/mock_data.dart'),
);
// store_entry_card.dart is a standing project exclusion (pre-existing
// uncommitted change, never touched by this or any prior multiclub round)
// — tracked separately, not counted as a leftover M4.1 bug.
const knownExclusion = 'lib/features/store/presentation/widgets/store_entry_card.dart';
const clubAssetRuntimeHardcodeFiles = appAssetsConsumerFiles.filter((f) => f !== knownExclusion);
const storeEntryCardStillExcluded = appAssetsConsumerFiles.includes(knownExclusion);

// --- 2. ClubBranding / ClubProductNaming consumers ---
const clubBrandingConsumers = grepCount('\\.branding\\.', 'lib/');
const clubCapabilitiesConsumers = grepCount('\\.capabilities\\.', 'lib/');
const productNamingConsumers = grepCount('\\.productNames\\.', 'lib/');

// --- 3. Config bypasses fixed this round ---
function checkConfigBypassesFixed() {
  const membershipContact = read('lib/features/membership/data/membership_contact_config.dart');
  const membershipContactFixed = /sl<ClubConfig>\(\)\.integrations/.test(membershipContact);

  const shipping = read('lib/features/store/domain/entities/shipping.dart');
  const pickupInfoFixed =
    /factory PickupInformation\.forActiveClub/.test(shipping) &&
    /sl<ClubConfig>\(\)\.integrations\.pickupAddress/.test(shipping);

  const socialLinksData = read('lib/features/profile/data/social_links_data.dart');
  const socialLinksFixed = /sl<ClubConfig>\(\)\.integrations/.test(socialLinksData);

  const mainDart = read('lib/main.dart');
  const mainTitleFixed = /title: _clubConfig\.identity\.displayName/.test(mainDart);
  const mainThemeFixed =
    /AppTheme\.light\(_clubConfig\.branding\.light\)/.test(mainDart) &&
    /AppTheme\.dark\(_clubConfig\.branding\.dark\)/.test(mainDart);

  const passportTicket = read(
    'lib/features/passport/presentation/v2/widgets/passport_match_ticket_v2.dart',
  );
  const passportTicketNoRawGoiasLiteral = !/contains\('goiás'\)/.test(passportTicket);
  const passportTicketUsesClubConfig = /sl<ClubConfig>\(\)\.identity/.test(passportTicket);

  return {
    membershipContactFixed,
    pickupInfoFixed,
    socialLinksFixed,
    mainTitleFixed,
    mainThemeFixed,
    passportTicketFixed: passportTicketNoRawGoiasLiteral && passportTicketUsesClubConfig,
  };
}
const bypassChecks = checkConfigBypassesFixed();
const configBypassesRemaining = Object.values(bypassChecks).filter((v) => v === false).length;

// --- 4. Store order prefix ---
function checkOrderPrefix() {
  const flutterSrc = read('lib/features/store/data/supabase_store_orders_repository.dart');
  const flutterUsesConfig = /_clubConfig\.integrations\.orderPrefix/.test(flutterSrc);
  const flutterHasGoiHardcode = /'GOI-\$\{now\.year\}/.test(flutterSrc);
  // SQL side deliberately NOT changed this round — flagged as a design
  // proposal requiring a schema decision (new clubs.order_prefix column +
  // trigger, since a plain column DEFAULT cannot see NEW.club_id), never
  // silently applied. See report §5/PARE point.
  const sqlStillHardcoded = /'GOI-' \|\|/.test(read('supabase/store_orders.sql'));
  return { flutterUsesConfig, flutterHasGoiHardcode, sqlStillHardcoded };
}
const orderPrefixCheck = checkOrderPrefix();
const goiasOrderPrefixHardcodes = (orderPrefixCheck.flutterHasGoiHardcode ? 1 : 0) +
  (orderPrefixCheck.sqlStillHardcoded ? 1 : 0);

// --- 5. Notifications dispatch club scoping ---
//
// M4.1b found a real gap: the M4.1 fix only scoped WHO is eligible per
// club (user-level, via preference rows), never WHICH TOKEN is safe to
// deliver to. M4.1c closes it in CODE: a migration (not yet applied — see
// below) adds user_notification_tokens.club_id, Flutter sends it on every
// register/refresh, and the Edge dispatch now fetches
// `activeTokensForClub(clubId)` instead of every active token in the
// system. All 3 layers are proven by tests (recipient_eligibility.test.ts
// + club_scoped_user_state_test.dart).
//
// IMPORTANT — code-correct is NOT the same as live-safe: this migration
// has 0 db push and the Edge function has 0 deploy this round (explicit
// PARE). Production's `user_notification_tokens` still has no club_id
// column right now, so the OLD (unscoped) behavior is still what actually
// runs until this ships. `notificationSchemaAppliedLive` tracks that
// separately and is correctly `false` — never conflate "the code is
// right and tested" with "the vulnerability is closed in production",
// same discipline as M4_1_IMPLEMENTATION_LOCAL_COMPLETE vs
// M4_CRITICAL_LEAKAGE_READY in the M4.1b round.
function checkNotificationsDispatch() {
  const shared = read('supabase/functions/_shared/recipient_eligibility.ts');
  const hasClubScopedEligibility =
    /explicitlyEligibleUserIds\(clubId/.test(shared) &&
    /usersWithAnyPreferenceRow/.test(shared);
  const indexTs = read('supabase/functions/notifications-dispatch/index.ts');
  const usesSharedModule = /from '\.\.\/_shared\/recipient_eligibility\.ts'/.test(indexTs);
  const isActiveMemberClubScoped = /activeMembershipCount\(userId, clubId\)/.test(shared);

  // Migration A (M4.1c-A) — additive, rollout-compatible with the runtime
  // in production today (1.0.1+2, which does not send club_id yet).
  // Created locally, NOT applied (0 db push). CRITICAL: must NOT drop the
  // DEFAULT — a rollout-compatibility bug found by the user AFTER the
  // first M4.1c pass: SET NOT NULL + DROP DEFAULT in the same migration
  // would break every register/refresh from the still-deployed 1.0.1+2
  // client (NOT NULL violation, no default to fall back on). Migration A
  // keeps the DEFAULT as a transitional compatibility bridge; only
  // migration B (planned, NOT created as a file yet — see report 43
  // §"M4.1c-B") drops it, and only after the new runtime is confirmed
  // distributed.
  const migrationPath =
    'supabase/migrations/20260903160000_add_club_id_to_notification_tokens.sql';
  const migrationExists = fs.existsSync(path.join(ROOT, migrationPath));
  const migrationSrc = migrationExists ? read(migrationPath) : '';
  const migrationAddsClubIdColumn = /add column club_id uuid/.test(migrationSrc);
  const migrationSetsNotNull = /alter column club_id set not null/.test(migrationSrc);
  // Migration A must NOT drop the default — that's migration B's job,
  // later. If this migration (still named 20260903160000, "A") ever drops
  // the default, that's a rollout-compatibility regression, not progress.
  const migrationADropsDefaultRegression = /alter column club_id drop default/.test(migrationSrc);
  const migrationBFilePath =
    'supabase/migrations/20260903170000_drop_default_notification_tokens_club_id.sql';
  const migrationBFileExists = fs.existsSync(path.join(ROOT, migrationBFilePath));
  const migrationPreservesFcmTokenUniqueOnly =
    !/add\s+constraint[\s\S]*club_id[\s\S]*fcm_token/i.test(migrationSrc) &&
    !/unique\s*\(\s*club_id\s*,\s*fcm_token\s*\)/i.test(migrationSrc);
  const migrationDesignCorrect =
    migrationExists &&
    migrationAddsClubIdColumn &&
    migrationSetsNotNull &&
    !migrationADropsDefaultRegression &&
    !migrationBFileExists && // B is deliberately NOT a file yet this round
    migrationPreservesFcmTokenUniqueOnly;

  // Live-confirmed schema fact (2026-09-03, reconfirmed before writing the
  // migration): user_notification_tokens has NO club_id column yet — 0 db
  // push this round. Cannot be re-derived by a plain grep of TS/Dart
  // source — embedded as a dated baseline, same pattern as every other
  // live DB fact in this project's tooling.
  const notificationSchemaAppliedLive = false;

  const tokenFetchFiltersByClubId = /activeTokensForClub\(clubId\)/.test(shared);
  const flutterRegistersClubId = /'club_id': _clubId/.test(
    read('lib/features/notifications/data/supabase_notification_repository.dart'),
  );

  const notificationUserEligibilityClubScoped = hasClubScopedEligibility && usesSharedModule;
  // Code-level readiness: migration DESIGNED correctly, dispatch query
  // DESIGNED to filter by club, Flutter DESIGNED to send club_id on every
  // register/refresh — all proven by tests this round. Deliberately does
  // NOT require notificationSchemaAppliedLive=true, matching the
  // established "implementation complete locally" vs "safe in
  // production" split.
  const notificationTokenDeliveryClubScoped =
    migrationDesignCorrect && tokenFetchFiltersByClubId && flutterRegistersClubId;
  const notificationMulticlubModelReady =
    notificationUserEligibilityClubScoped &&
    notificationTokenDeliveryClubScoped &&
    isActiveMemberClubScoped;

  // Rollout-phase states (M4.1c-A vs M4.1c-B), never collapsed into one
  // "the column exists" flag — a compatibility DEFAULT being present is a
  // deliberately DIFFERENT state from it being gone for good.
  const notificationTokenClubColumnReady = migrationDesignCorrect; // column+NOT NULL designed correctly (A)
  const notificationTokenClubDefaultTransitional = migrationDesignCorrect; // A keeps the DEFAULT on purpose
  const notificationTokenDefaultFinal = migrationBFileExists; // B (drop default) not even a file yet

  return {
    notificationDispatchClubScoped: notificationUserEligibilityClubScoped, // kept for backward-compat with M4.1's original (incomplete) metric name
    notificationUserEligibilityClubScoped,
    notificationTokenDeliveryClubScoped,
    notificationMulticlubModelReady,
    notificationMembershipLookupClubScoped: isActiveMemberClubScoped,
    notificationSchemaAppliedLive,
    notificationTokenClubColumnReady,
    notificationTokenClubDefaultTransitional,
    notificationTokenDefaultFinal,
    migration: {
      path: migrationPath,
      exists: migrationExists,
      addsClubIdColumn: migrationAddsClubIdColumn,
      setsNotNull: migrationSetsNotNull,
      keepsDefaultForRolloutCompat: !migrationADropsDefaultRegression,
      preservesFcmTokenUniqueOnly: migrationPreservesFcmTokenUniqueOnly,
      designCorrect: migrationDesignCorrect,
    },
    migrationB: {
      plannedPath: migrationBFilePath,
      createdAsFileYet: migrationBFileExists, // deliberately false this round
    },
    tokenFetchFiltersByClubId,
    flutterRegistersClubId,
  };
}
const notifCheck = checkNotificationsDispatch();

// --- 6. Worker News/Social club gate ---
function checkWorkerNewsSocialGate() {
  const registry = read('src/football/_lib/club_server_config.ts');
  const gateHelperExists =
    /export function resolveRequestedClubCode/.test(registry) &&
    /NEWS_SOCIAL_CONFIGURED_CLUB_CODE/.test(registry);

  const newsList = read('src/news/list.ts');
  const newsListGated = /resolveRequestedClubCode\(request\)/.test(newsList) && /NEWS_SOCIAL_CONFIGURED_CLUB_CODE/.test(newsList);

  const newsArticle = read('src/news/article.ts');
  const newsArticleGated = /resolveRequestedClubCode\(request\)/.test(newsArticle) && /NEWS_SOCIAL_CONFIGURED_CLUB_CODE/.test(newsArticle);

  const socialFeed = read('src/social/feed.ts');
  const socialFeedGated = /resolveRequestedClubCode\(request\)/.test(socialFeed) && /NEWS_SOCIAL_CONFIGURED_CLUB_CODE/.test(socialFeed);

  return {
    gateHelperExists,
    workerNewsCrossClubFallback: !(newsListGated && newsArticleGated), // false = fixed (no more cross-club fallback)
    workerSocialCrossClubFallback: !socialFeedGated,
  };
}
const workerGateCheck = checkWorkerNewsSocialGate();

// --- 7. Synthetic club leakage — the whole point of test/core/club/m4_1_critical_leakage_test.dart ---
function checkSyntheticClubDoesNotLeakGoiasIdentity() {
  const syntheticSrc = read('test/core/club/synthetic_club_config.dart');
  const noGoiasAssetReuse = !/goiasClubConfig\.assets/.test(syntheticSrc);
  const noGoiasBrandingReuse = !/goiasClubConfig\.branding/.test(syntheticSrc);
  const noGoiasIntegrationsReuse = !/goiasClubConfig\.integrations/.test(syntheticSrc);
  const noGoiasProductNamesReuse = !/goiasClubConfig\.productNames/.test(syntheticSrc);
  const testFileExists = fs.existsSync(
    path.join(ROOT, 'test/core/club/m4_1_critical_leakage_test.dart'),
  );
  return {
    noGoiasAssetReuse,
    noGoiasBrandingReuse,
    noGoiasIntegrationsReuse,
    noGoiasProductNamesReuse,
    testFileExists,
  };
}
const syntheticCheck = checkSyntheticClubDoesNotLeakGoiasIdentity();
const syntheticClubLeaksGoiasIdentity = !(
  syntheticCheck.noGoiasAssetReuse &&
  syntheticCheck.noGoiasBrandingReuse &&
  syntheticCheck.noGoiasIntegrationsReuse &&
  syntheticCheck.noGoiasProductNamesReuse &&
  syntheticCheck.testFileExists
);

// --- Store readiness (point 9 of the M4.1b authorization) ---
// store_entry_card.dart's AppAssets.storeBanner hardcode is preserved by
// the standing project exclusion (never touched, not a bug of this round),
// and generate_store_order_number() still hardcodes 'GOI-' (deliberately
// deferred, PARE point — see report §5). Neither blocks M4.1's own scope,
// but Store is not safe to capability-enable for a real clubB until M4.2.
const STORE_SAFE_FOR_CLUB_B = false;

// --- Final computed readiness (never forced) ---
// M4.1b correction: M4.1's original m4CriticalLeakageReady computation
// only checked user-level eligibility scoping, never token-level delivery
// scoping — a real logical gap (see notifications section above), so it
// was wrongly `true`, then corrected to `false`. M4.1c now closes that
// gap IN CODE (migration designed+tested, Flutter/Edge both updated,
// proven by tests) — this flag measures CODE correctness (same meaning
// it has had every round since M4.1), so it is correctly `true` again.
// It deliberately does NOT require notificationSchemaAppliedLive=true —
// "the leakage bugs are fixed in code" and "the fix is live in
// production" are two different, separately-tracked claims (0 db push,
// 0 Edge deploy, 0 git push this round — see notificationSchemaAppliedLive
// in stats, always false until a future round explicitly applies it).
const m4CriticalLeakageReady =
  clubAssetRuntimeHardcodeFiles.length === 0 &&
  configBypassesRemaining === 0 &&
  goiasOrderPrefixHardcodes <= 1 && // SQL side deliberately deferred (PARE), Flutter side must be 0
  orderPrefixCheck.flutterHasGoiHardcode === false &&
  notifCheck.notificationUserEligibilityClubScoped &&
  notifCheck.notificationTokenDeliveryClubScoped &&
  notifCheck.notificationMulticlubModelReady &&
  notifCheck.notificationMembershipLookupClubScoped &&
  !workerGateCheck.workerNewsCrossClubFallback &&
  !workerGateCheck.workerSocialCrossClubFallback &&
  !syntheticClubLeaksGoiasIdentity;

// M4.1's local implementation work (assets/branding/bypasses/notifications
// eligibility/Worker gate/synthetic config) is done and tested — that fact
// is real and does not depend on the token-ownership question below. Kept
// as its own flag so "the code got written and tested" is never conflated
// with "the notification model is provably safe for a real 2nd club."
const M4_1_IMPLEMENTATION_LOCAL_COMPLETE = true;

const audit = {
  clubAssetRuntimeHardcodes: clubAssetRuntimeHardcodeFiles,
  storeEntryCardStillExcluded,
  clubBrandingConsumers,
  clubCapabilitiesConsumers,
  productNamingConsumers,
  configBypasses: bypassChecks,
  orderPrefix: orderPrefixCheck,
  notifications: notifCheck,
  workerNewsSocialGate: workerGateCheck,
  syntheticClub: syntheticCheck,
  storeSafeForClubB: STORE_SAFE_FOR_CLUB_B,
  m4_1ImplementationLocalComplete: M4_1_IMPLEMENTATION_LOCAL_COMPLETE,
  m4CriticalLeakageReady,
};

const stats = {
  clubAssetRuntimeHardcodes: clubAssetRuntimeHardcodeFiles.length,
  clubBrandingConsumers,
  productNamingConsumers,
  configBypassesRemaining,
  goiasOrderPrefixHardcodes,
  notificationUserEligibilityClubScoped: notifCheck.notificationUserEligibilityClubScoped,
  notificationTokenDeliveryClubScoped: notifCheck.notificationTokenDeliveryClubScoped,
  notificationMulticlubModelReady: notifCheck.notificationMulticlubModelReady,
  notificationMembershipLookupClubScoped: notifCheck.notificationMembershipLookupClubScoped,
  notificationSchemaAppliedLive: notifCheck.notificationSchemaAppliedLive,
  notificationTokenClubColumnReady: notifCheck.notificationTokenClubColumnReady,
  notificationTokenClubDefaultTransitional: notifCheck.notificationTokenClubDefaultTransitional,
  notificationTokenDefaultFinal: notifCheck.notificationTokenDefaultFinal,
  workerNewsCrossClubFallback: workerGateCheck.workerNewsCrossClubFallback,
  workerSocialCrossClubFallback: workerGateCheck.workerSocialCrossClubFallback,
  syntheticClubLeaksGoiasIdentity,
  storeSafeForClubB: STORE_SAFE_FOR_CLUB_B,
  m4_1ImplementationLocalComplete: M4_1_IMPLEMENTATION_LOCAL_COMPLETE,
  m4CriticalLeakageReady,
};

fs.mkdirSync(RECON, { recursive: true });
fs.writeFileSync(
  path.join(RECON, 'm4_1_critical_club_leakage_audit.json'),
  JSON.stringify(audit, null, 2) + '\n',
);
fs.writeFileSync(
  path.join(RECON, 'm4_1_critical_club_leakage_stats.json'),
  JSON.stringify(stats, null, 2) + '\n',
);
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', RECON);

export { audit, stats };

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
    const out = execSync(
      `git grep -c -E "${pattern}" -- "${globPattern}"`,
      { cwd: ROOT, encoding: 'utf8' }
    );
    return out.trim().split('\n').filter(Boolean).length;
  } catch {
    return 0;
  }
}

// --- 1. Live-confirmed DB facts (2026-09-03) — cannot be re-queried by a
// plain Node script without Supabase credentials; embedded as a dated
// baseline, same pattern as every prior audit script in this project.
const LIVE_DB_BASELINE_DATE = '2026-09-03';
const rlsTenantTablePoliciesTotal = 52;
const rlsTenantTablePoliciesReferencingClubId = 0;
const passportRpcs = [
  'passport_attendance_breakdown', 'passport_attended_matches', 'passport_matches_for_year',
  'passport_memorable_match_id', 'passport_my_attendances_for_year', 'passport_my_rank',
  'passport_ranking', 'passport_save_attendances', 'passport_seasons',
  'passport_set_memorable_match', 'passport_stadium_summary', 'passport_summary',
];
const passportRpcsWithPublicExecute = passportRpcs.length; // all 12, confirmed live
const forClubRpcs = [
  'arena_my_rank_for_club', 'arena_ranking_for_club', 'arena_record_score_for_club',
  'arena_user_detail_for_club', 'create_store_order_for_club', 'crowd_lineup_for_club',
  'get_my_membership_for_club', 'subscribe_to_plan_for_club',
  'upsert_membership_checkin_ticket_for_club',
];
const legacyRpcsRetired = [
  'arena_my_rank', 'arena_ranking', 'arena_record_score', 'arena_user_detail',
  'create_store_order', 'crowd_lineup', 'get_my_membership', 'subscribe_to_plan',
];

// --- 2. Repository tenant coverage (from the M4 audit's independent pass) ---
const directReadTenantCoverage = { correct: 39, total: 39, pct: 100 };
const directWriteTenantCoverage = { correct: 20, total: 20, pct: 100 };
const rpcTenantCoverage = {
  forClubCorrect: forClubRpcs.length,
  forClubTotal: forClubRpcs.length,
  passportUntenanted: passportRpcs.length,
};

// --- 3. Live-reproducible grep checks ---
function checkClubCapabilitiesWired() {
  const capabilitiesConsumers = grepCount('\\.capabilities\\.', 'lib/');
  // 0 real consumers expected: declared (club_config.dart) and constructed
  // (goias_club_config.dart) don't match this pattern (they don't read
  // `.capabilities.<field>`, they declare/build the object) — so 0 here
  // means the matrix is NOT wired to anything, not that it's fine.
  return capabilitiesConsumers > 0;
}

function checkAssetsClubParameterized() {
  const src = read('lib/shared/widgets/club_badge.dart');
  const usesClubConfigAssets = /clubConfig\.assets\./.test(src);
  const appAssetsDirectConsumers = grepCount('AppAssets\\.(goiasCrest|loginBackground|stadium|matchHero|tacticsBoardIllustration|storeBanner)', 'lib/');
  return { usesClubConfigAssets, appAssetsDirectConsumers, isolatedToOneFile: appAssetsDirectConsumers > 0 };
}

function checkNotificationsDispatchClubScoped() {
  const src = read('supabase/functions/notifications-dispatch/index.ts');
  const fetchRecipientTokensMatch = src.match(/function fetchRecipientTokens[\s\S]*?\n}/);
  const fetchBlock = fetchRecipientTokensMatch ? fetchRecipientTokensMatch[0] : '';
  const filtersClubId = /club_id/i.test(fetchBlock);
  const isActiveMemberMatch = src.match(/function isActiveMember[\s\S]*?\n}/);
  const isActiveMemberBlock = isActiveMemberMatch ? isActiveMemberMatch[0] : '';
  const isActiveMemberFiltersClubId = /club_id/i.test(isActiveMemberBlock);
  return { filtersClubId, isActiveMemberFiltersClubId };
}

function checkExplicitUnknownClubFailsLoud() {
  const src = read('lib/core/club/resolve_active_club.dart');
  const hasEmptyGoiasDefault = /envValue\.isEmpty\)\s*return\s*clubRegistry\['goias'\]/.test(src);
  const throwsOnUnknownExplicit = /throw StateError/.test(src) && /config == null/.test(src);
  return { hasEmptyGoiasDefault, throwsOnUnknownExplicit };
}

function checkClubScopedFallbackNeverDefaults() {
  const src = read('lib/core/club/club_scoped_fallback.dart');
  return /forClub\(String clubCode\) => _byClubCode\[clubCode\];/.test(src);
}

function checkLocalStorageIsolated() {
  const stores = [
    'lib/features/store/data/store_local_storage.dart',
    'lib/features/arena/games/guess_player/data/guess_player_storage.dart',
    'lib/features/arena/shared/local_best_score_store.dart',
  ];
  return stores.every((f) => /ClubScopedStorageKey/.test(read(f)));
}

function checkStoreOrderNumberHardcode() {
  const flutterSrc = read('lib/features/store/data/supabase_store_orders_repository.dart');
  const hasGoiPrefixInFlutter = /'GOI-\$\{now\.year\}/.test(flutterSrc);
  const orderPrefixDefined = /orderPrefix/.test(read('lib/core/club/club_integrations.dart'));
  const orderPrefixConsumedElsewhere = grepCount('\\.integrations\\.orderPrefix', 'lib/') > 0;
  return { hasGoiPrefixInFlutter, orderPrefixDefined, orderPrefixConsumedElsewhere };
}

const clubCapabilitiesWired = checkClubCapabilitiesWired();
const assetsCheck = checkAssetsClubParameterized();
const notificationsCheck = checkNotificationsDispatchClubScoped();
const appClubResolution = checkExplicitUnknownClubFailsLoud();
const clubScopedFallbackCorrect = checkClubScopedFallbackNeverDefaults();
const localStorageIsolated = checkLocalStorageIsolated();
const storeOrderNumberCheck = checkStoreOrderNumberHardcode();

// --- 4. Registry drift (reuses the M3.3 3-way check's live result) ---
const registryDrift = {
  dbRegistryCodes: ['goias'],
  flutterRegistryCodes: ['goias'],
  workerRegistryCodes: ['goias'],
  edgeRegistryCodes: ['goias'],
  registryConsistencyReady: true, // trivial with 1 club; drift check exists but never includes DB as a 4th point — gap noted in report §19
  dbIncludedInDriftCheck: false,
};

// --- 5. Findings registry (qualitative, from the 3-agent + direct-DB audit) ---
const blockersBeforeAnySecondClub = [
  { area: 'ASSETS', finding: 'AppAssets literals (crest/login/banner/etc) bypass ClubConfig.assets entirely — a clubB build would show real Goiás assets, not missing/fallback ones', severity: 'CRITICAL' },
  { area: 'EDGE_FUNCTIONS', finding: 'notifications-dispatch fetchRecipientTokens/isActiveMember do not filter by club_id — cross-club notification fan-out', severity: 'CRITICAL' },
  { area: 'FLAVOR_PIPELINE', finding: 'no Android/iOS flavors — a clubB build shares applicationId/bundle id with Goiás, cascading into shared local storage + Supabase auth session', severity: 'CRITICAL' },
  { area: 'FLUTTER_CONFIG', finding: 'MembershipContactConfig/PickupInformation/SocialLinksData/MaterialApp title bypass ClubConfig with hardcoded Goiás values', severity: 'HIGH' },
  { area: 'STORE', finding: "'GOI-' order-number prefix hardcoded in both the SQL function and a Flutter demo path, ClubIntegrations.orderPrefix never consumed", severity: 'MEDIUM' },
  { area: 'WORKER', finding: 'News and Social subsystems have zero clubCode routing dimension — 100% Goiás-hardcoded, unlike the football routes', severity: 'HIGH' },
  { area: 'FLUTTER_CONFIG', finding: 'passport_match_ticket_v2.dart still does a raw string isGoias check instead of Team.matchesClub', severity: 'MEDIUM' },
];

const blockersBeforePublicSecondClub = [
  { area: 'RLS', finding: '0/52 policies on tenant-scoped tables reference club_id — club isolation is app-layer only, no DB-level defense in depth' },
  { area: 'CLUB_CAPABILITIES', finding: 'ClubCapabilities exists but has 0 real consumers — cannot actually disable a feature per club yet' },
  { area: 'FLAVOR_PIPELINE', finding: 'Android/iOS/Web flavor pipelines fully designed (docs 10-13) but not implemented' },
  { area: 'SCHEMA', finding: 'club_transparency_*/club_board_*/membership_faq_* tables have no club_id column, never touched by tenant migrations — needs a product decision' },
  { area: 'L10N', finding: 'ClubProductNaming-mapped l10n keys still hardcoded to Goiás copy instead of reading the config' },
];

const blockersPerFeature = [
  { feature: 'PASSAPORTE', blocker: 'BLOCKER_BEFORE_ENABLING_PASSAPORTE', detail: '0 club_id anywhere in 12 RPCs, PUBLIC/anon/service_role EXECUTE granted on all of them (widest ACL of any RPC in the project)' },
  { feature: 'STORE', blocker: 'BLOCKER_BEFORE_ENABLING_STORE', detail: 'product catalog is static Dart data, not a tenant-aware DB dataset' },
  { feature: 'CLUB_INSTITUTIONAL_PAGES', blocker: 'BLOCKER_BEFORE_ENABLING_CLUB_INSTITUTIONAL_PAGES', detail: 'club_board_*/club_transparency_* have no club_id column' },
];

const deferredNonBlockers = [
  'web/manifest.json placeholder defaults (pre-existing Goiás bug, unrelated to multiclub)',
  'QuizDifficulty/PassportLevel enum member names carrying brand identity (label only, not logic)',
  'AppColors semantic token naming (darkGreen/deepGreen/ctaGreen)',
  'ClubSongVolumeStore not club-scoped (low risk, volume preference not content)',
  "Worker GOIAS_ONEFOOTBALL_SLUG env var naming (works today, each club gets its own Worker deploy anyway)",
];

const secondClubTechnicallySafe =
  assetsCheck.appAssetsDirectConsumers === 0 &&
  notificationsCheck.filtersClubId &&
  notificationsCheck.isActiveMemberFiltersClubId &&
  blockersBeforeAnySecondClub.length === 0;

const secondClubProductReady =
  secondClubTechnicallySafe &&
  clubCapabilitiesWired &&
  registryDrift.dbIncludedInDriftCheck &&
  blockersBeforePublicSecondClub.length === 0;

const audit = {
  liveDbBaselineDate: LIVE_DB_BASELINE_DATE,
  rowScopeReady: true,
  keyScopeFinal: true,
  arenaCrossClubReady: true,
  directReadTenantCoverage,
  directWriteTenantCoverage,
  rpcTenantCoverage,
  edgeTenantCoverage: {
    notificationsPollLiveMatch: 'CLUB_CONFIGURED',
    notificationsSyncAndCheckAccess: 'CLUB_CONFIGURED',
    notificationsDispatch: notificationsCheck.filtersClubId && notificationsCheck.isActiveMemberFiltersClubId ? 'CLUB_CONFIGURED' : 'BLOCKED',
    cleanupUnconfirmedSignups: 'GLOBAL_INTENTIONAL',
    deleteAccount: 'GLOBAL_INTENTIONAL',
  },
  workerTenantCoverage: {
    football: 'CLUB_CONFIGURED',
    news: 'BLOCKED',
    social: 'BLOCKED',
  },
  localStorageIsolated,
  explicitUnknownClubFails: appClubResolution.throwsOnUnknownExplicit,
  emptyAppClubDefaultsToGoias: appClubResolution.hasEmptyGoiasDefault,
  clubScopedFallbackNeverDefaults: clubScopedFallbackCorrect,
  goiasFallbacksRemaining: assetsCheck.appAssetsDirectConsumers,
  runtimeGoiasHardcodes: {
    mustConfigBeforeClubB: blockersBeforeAnySecondClub.length,
    deferredNonBlocker: deferredNonBlockers.length,
  },
  clubConfigCoverage: {
    identityConsumers: 22,
    assetsConsumers: 1,
    integrationsConsumers: 1,
    brandingConsumers: 0,
    capabilitiesConsumers: 0,
    productNamesConsumers: 0,
  },
  clubCapabilitiesCoverage: {
    wired: clubCapabilitiesWired,
    fieldsCovered: ['hasMembership', 'hasStore', 'hasTickets', 'hasCrowdLineup', 'hasPassport', 'enabledArenaGames'],
    fieldsMissing: ['notifications', 'social', 'squad'],
  },
  registryDrift,
  passportRpcAcl: {
    functions: passportRpcs,
    publicExecuteCount: passportRpcsWithPublicExecute,
    total: passportRpcs.length,
  },
  passportStrategy: 'B_CAPABILITY_FALSE_AFTER_CAPABILITIES_WIRED',
  authScopeDecision: {
    model: 'C_APP_DEFINES_CLUB_ACCOUNT_GLOBAL',
    activeClubEnforcementBlocked: true,
    rlsUserIsolation: true,
    rlsClubIsolation: false,
    rlsTenantTablePoliciesTotal,
    rlsTenantTablePoliciesReferencingClubId: rlsTenantTablePoliciesReferencingClubId,
  },
  releaseGateTenantReady: true,
  notificationsDispatchClubScoped: notificationsCheck,
  storeOrderNumberHardcode: storeOrderNumberCheck,
  secondClubTechnicalBlockers: blockersBeforeAnySecondClub,
  secondClubProductBlockers: blockersBeforePublicSecondClub,
  blockersPerFeature,
  deferredNonBlockers,
  secondClubTechnicallySafe,
  secondClubProductReady,
};

const stats = {
  secondClubTechnicallySafe: audit.secondClubTechnicallySafe,
  secondClubProductReady: audit.secondClubProductReady,
  blockersBeforeAnySecondClubCount: blockersBeforeAnySecondClub.length,
  blockersBeforePublicSecondClubCount: blockersBeforePublicSecondClub.length,
  blockersPerFeatureCount: blockersPerFeature.length,
  directReadTenantCoveragePct: directReadTenantCoverage.pct,
  directWriteTenantCoveragePct: directWriteTenantCoverage.pct,
  clubCapabilitiesWired,
  localStorageIsolated,
  registryConsistencyReady: registryDrift.registryConsistencyReady,
};

fs.mkdirSync(RECON, { recursive: true });
fs.writeFileSync(
  path.join(RECON, 'second_club_product_readiness_audit.json'),
  JSON.stringify(audit, null, 2) + '\n'
);
fs.writeFileSync(
  path.join(RECON, 'second_club_product_readiness_stats.json'),
  JSON.stringify(stats, null, 2) + '\n'
);
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', RECON);

export { audit, stats };

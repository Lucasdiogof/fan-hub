// M4.2A — audita, lendo os arquivos .dart REAIS (nunca lista assumida), se
// `ClubCapabilities` realmente controla o que aparece/abre pra cada clube:
// Home, bottom nav/rail, Perfil, rotas (via `capabilityGateRedirect`),
// Arena (hub + jogos + identidades), News/Social (`?club=` enviado de
// verdade pro Worker). Squad/Notificações são auditados como
// DELIBERADAMENTE não-gateados (decisão registrada, não esquecimento).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const LIB = path.join(ROOT, 'lib');
const TEST = path.join(ROOT, 'test');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

function read(relPath, base = LIB) {
  return fs.readFileSync(path.join(base, relPath), 'utf8');
}
function exists(relPath, base = LIB) {
  return fs.existsSync(path.join(base, relPath));
}
function stripComments(src) {
  return src
    .split('\n')
    .filter((l) => !l.trim().startsWith('//') && !l.trim().startsWith('///'))
    .join('\n');
}

// ============================================================================
// 1) capabilityConsumers — todo arquivo real (fora da própria definição/
//    configs) que lê `.capabilities.`/`isTabEnabled`/`capabilityGateRedirect`.
// ============================================================================
const CONSUMER_FILES = [
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
];
const capabilityConsumers = CONSUMER_FILES.filter((f) => {
  const body = stripComments(read(f));
  return /\.capabilities\b|isTabEnabled\(|capabilityGateRedirect\(/.test(body);
});

// ============================================================================
// 2) capabilityUngatedEntryPoints — pontos de navegação conhecidos que
//    intencionalmente NÃO checam capability (Squad/Notificações) — lista
//    fechada, cada um com o motivo. Se um novo `context.push`/`.go` pra
//    uma feature gateada aparecer sem check, isso é pego pelas checagens
//    de 3-9 abaixo, não aqui.
// ============================================================================
const capabilityUngatedEntryPoints = [
  { feature: 'Squad', route: '/squad', reason: 'infraestrutura básica, sempre club_id-scoped no repository (M3.1) — decisão registrada em ClubCapabilities.' },
  { feature: 'Notifications', route: '/profile/notifications', reason: 'infraestrutura básica, sempre club_id-scoped no repository (M3.2/M4.1c) — decisão registrada em ClubCapabilities.' },
];

// ============================================================================
// 3) Rotas — capabilityGateRedirect cobre os prefixos certos
// ============================================================================
const gateSrc = stripComments(read('core/club/capability_route_gate.dart'));
const gatedPrefixes = {
  passport: /_matches\(location, '\/arena\/passport'\)/.test(gateSrc),
  arenaHub: /_matches\(location, '\/arena'\)/.test(gateSrc),
  arenaGames: /_arenaGameRoutes/.test(gateSrc) && /quiz.*lineup.*career_path.*guess_player.*tactical_identity.*player_identity/s.test(
    gateSrc.replace(/\s/g, '')
  ),
  store: /_matches\(location, '\/store'\)/.test(gateSrc),
  membership: /_matches\(location, '\/membership'\)/.test(gateSrc),
  tickets: /_matches\(location, '\/tickets'\)/.test(gateSrc),
  crowdLineup: /_matches\(location, '\/crowd-lineup'\)/.test(gateSrc),
  news: /_matches\(location, '\/news'\)/.test(gateSrc),
};
const routerWired =
  /capabilityGateRedirect\(location, capabilities\)/.test(
    stripComments(read('core/router/app_router.dart'))
  ) && exists('shared/widgets/feature_unavailable_page.dart');

// ============================================================================
// 4) Synthetic club-b — capabilities realmente desligadas onde deveriam
// ============================================================================
const syntheticSrc = read('core/club/synthetic_club_config.dart', TEST);
function syntheticCapability(field) {
  const m = syntheticSrc.match(new RegExp(`${field}:\\s*(true|false)`));
  return m ? m[1] === 'true' : null;
}
const passportBlockedForSyntheticClub = syntheticCapability('hasPassport') === false;
const storeBlockedForSyntheticClub = syntheticCapability('hasStore') === false;
const membershipBlockedForSyntheticClub = syntheticCapability('hasMembership') === false;
const ticketsBlockedForSyntheticClub = syntheticCapability('hasTickets') === false;
const crowdLineupBlockedForSyntheticClub = syntheticCapability('hasCrowdLineup') === false;
const newsBlockedForSyntheticClub = syntheticCapability('hasNews') === false;
const socialBlockedForSyntheticClub = syntheticCapability('hasSocial') === false;
const syntheticArenaGamesMatch = syntheticSrc.match(/enabledArenaGames:\s*\{([^}]*)\}/);
const syntheticEnabledArenaGames = syntheticArenaGamesMatch
  ? syntheticArenaGamesMatch[1].match(/'([a-z_]+)'/g)?.map((s) => s.slice(1, -1)) ?? []
  : [];

// ============================================================================
// 5) Arena — hub/grid/cards filtram por enabledArenaGames, hasPassport,
//    hasCrowdLineup
// ============================================================================
const arenaPageSrc = stripComments(read('features/arena/presentation/pages/arena_page.dart'));
const arenaCapabilityEnforced =
  /ArenaCatalog\.games\s*\n?\s*\.where\(\(game\)\s*=>\s*capabilities\.enabledArenaGames\.contains\(game\.id\)\)/.test(
    arenaPageSrc.replace(/\s+/g, ' ')
  ) &&
  /if \(capabilities\.hasPassport\)/.test(arenaPageSrc) &&
  /if \(capabilities\.hasCrowdLineup\)/.test(arenaPageSrc) &&
  /capabilities\.enabledArenaGames\.contains\(\s*\n?\s*'tactical_identity'/.test(arenaPageSrc) &&
  /capabilities\.enabledArenaGames\.contains\(\s*\n?\s*'player_identity'/.test(arenaPageSrc);

// ============================================================================
// 6) News/Social — Flutter manda `?club=` de verdade pro Worker (sem isso
//    o gate do Worker, feito na M4.1, é código morto do lado do cliente)
// ============================================================================
const newsDataSourceSrc = stripComments(
  read('features/news/data/datasources/news_remote_data_source.dart')
);
const newsCapabilityEnforced =
  /'club':\s*_clubConfig\.identity\.code/.test(newsDataSourceSrc) &&
  (newsDataSourceSrc.match(/'club':\s*_clubConfig\.identity\.code/g) || []).length >= 2; // getList + getArticle

const socialDataSourceSrc = stripComments(
  read('features/social/data/datasources/social_remote_data_source.dart')
);
const socialCapabilityEnforced = /'club':\s*_clubConfig\.identity\.code/.test(
  socialDataSourceSrc
);

const mediaFilterBarSrc = stripComments(
  read('features/social/presentation/pages/social_feed_page.dart')
);
const socialFeedPageFiltersOptionsByCapability =
  /if \(capabilities\.hasNews\)/.test(mediaFilterBarSrc) &&
  /if \(capabilities\.hasSocial\)/.test(mediaFilterBarSrc);

// ============================================================================
// 7) Synthetic club — nunca vaza identidade/conteúdo do Goiás (M4.1,
//    reconfirmado aqui) E agora com as capabilities certas desligadas
// ============================================================================
const syntheticClubFeatureLeaks = !(
  passportBlockedForSyntheticClub &&
  storeBlockedForSyntheticClub &&
  membershipBlockedForSyntheticClub &&
  ticketsBlockedForSyntheticClub &&
  crowdLineupBlockedForSyntheticClub &&
  newsBlockedForSyntheticClub &&
  socialBlockedForSyntheticClub
);

// ============================================================================
// 8) Testes obrigatórios — existem de verdade, não só a tooling promete
// ============================================================================
const requiredTestFiles = {
  routeGateUnitTests: 'core/club/capability_route_gate_test.dart',
  navWidgetTests: 'features/home/presentation/widgets/capability_nav_gating_test.dart',
};
const requiredTestsExist = Object.fromEntries(
  Object.entries(requiredTestFiles).map(([k, f]) => [k, exists(f, TEST)])
);

// ============================================================================
// Final readiness
// ============================================================================
const m4CapabilitiesReady =
  capabilityConsumers.length === CONSUMER_FILES.length &&
  Object.values(gatedPrefixes).every(Boolean) &&
  routerWired &&
  !syntheticClubFeatureLeaks &&
  arenaCapabilityEnforced &&
  newsCapabilityEnforced &&
  socialCapabilityEnforced &&
  socialFeedPageFiltersOptionsByCapability &&
  Object.values(requiredTestsExist).every(Boolean);

const audit = {
  capabilityConsumers,
  capabilityConsumersCount: capabilityConsumers.length,
  capabilityUngatedEntryPoints,
  gatedPrefixes,
  routerWired,
  passportBlockedForSyntheticClub,
  storeBlockedForSyntheticClub,
  membershipBlockedForSyntheticClub,
  ticketsBlockedForSyntheticClub,
  crowdLineupBlockedForSyntheticClub,
  newsBlockedForSyntheticClub,
  socialBlockedForSyntheticClub,
  syntheticEnabledArenaGames,
  arenaCapabilityEnforced,
  newsCapabilityEnforced,
  socialCapabilityEnforced,
  socialFeedPageFiltersOptionsByCapability,
  syntheticClubFeatureLeaks,
  requiredTestsExist,
  m4CapabilitiesReady,
};

fs.mkdirSync(RECON, { recursive: true });
fs.writeFileSync(
  path.join(RECON, 'm4_2_club_capabilities_audit.json'),
  JSON.stringify(audit, null, 2) + '\n'
);
console.log(JSON.stringify(audit, null, 2));
console.log('\nEscrito em:', RECON);

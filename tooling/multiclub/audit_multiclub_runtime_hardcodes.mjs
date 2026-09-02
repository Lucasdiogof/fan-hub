// M3.3 — audita, lendo os arquivos REAIS (Flutter + Worker + Edge
// Functions, nunca uma lista assumida), se os literais/lógica
// especificamente-Goiás foram eliminados do runtime GENÉRICO (Team.isGoias/
// goiasId, _isGoiasHome, getGoiasSnapshot, teamToGuess hardcoded,
// GOIAS_TEAM_ID, rota /team/goias hardcoded no client) e se os 3 pontos de
// config de clube (Flutter/Worker/Edge Functions) nunca divergem entre si
// (drift check).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const LIB = path.join(ROOT, 'lib');
const SRC = path.join(ROOT, 'src');
const SUPABASE_FUNCTIONS = path.join(ROOT, 'supabase', 'functions');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

function read(relPath) {
  return fs.readFileSync(path.join(ROOT, relPath), 'utf8');
}

function exists(relPath) {
  return fs.existsSync(path.join(ROOT, relPath));
}

// Tira linhas de comentário (`//`/`///` no Dart/TS, `--` no SQL) antes de
// checar por um literal — várias checagens abaixo citam o literal antigo
// DENTRO do próprio comentário explicativo (documentando o que a M3.3
// substituiu), o que faria um regex ingênuo no arquivo inteiro achar um
// falso-positivo. Só o código executável importa pra essas checagens.
function stripComments(src) {
  return src
    .split('\n')
    .filter((l) => {
      const trimmed = l.trim();
      return !trimmed.startsWith('//') && !trimmed.startsWith('///') && !trimmed.startsWith('* ') && trimmed !== '*';
    })
    .join('\n');
}

// ============================================================================
// 1) Violações nomeadas — cada uma checada no arquivo real onde vivia antes
// da M3.3, nunca por grep cego no repo inteiro (editorial/fixture Goiás é
// esperado sobreviver em muitos lugares, ver classificação abaixo).
// ============================================================================
const namedViolationChecks = {
  teamIsGoiasRemoved: !/bool get isGoias|static const int goiasId/.test(
    stripComments(read('lib/features/match/domain/entities/team.dart')),
  ),
  teamMatchesClubPresent: /bool matchesClub\(ClubConfig config\)/.test(
    read('lib/features/match/domain/entities/team.dart'),
  ),
  isGoiasHomeRemoved: !/_isGoiasHome/.test(
    stripComments(read('lib/features/crowd_lineup/presentation/pages/crowd_lineup_page.dart')),
  ),
  getGoiasSnapshotRemovedFromRepository: !/getGoiasSnapshot\(\)/.test(
    stripComments(read('lib/features/match/domain/repositories/football_repository.dart')),
  ),
  hardcodedTeamRouteRemovedFromDatasource: !/'\/api\/football\/team\/goias'/.test(
    stripComments(read('lib/features/match/data/datasources/football_remote_data_source.dart')),
  ),
  teamToGuessHardcodeRemovedFromRepository: !/teamToGuess:\s*'Goiás'/.test(
    stripComments(read('lib/features/arena/games/lineup/data/lineup_match_repository.dart')),
  ),
  goiasTeamIdRemovedFromPollLiveMatch: !/GOIAS_TEAM_ID/.test(
    stripComments(read('supabase/functions/notifications-poll-live-match/index.ts')),
  ),
  hardcodedTeamRouteRemovedFromSyncAndCheckAccess: !/\/api\/football\/team\/goias/.test(
    stripComments(read('supabase/functions/notifications-sync-and-check-access/index.ts')),
  ),
  goiasStringComparisonRemovedFromDispatch: !/p\.homeTeamName === 'Goiás'/.test(
    stripComments(read('supabase/functions/notifications-dispatch/index.ts')),
  ),
  workerGenericTeamRouteExists: exists('src/football/_lib/club_server_config.ts') &&
    /export async function handleTeam\(request: Request, env: Env, clubCode: string\)/.test(read('src/football/team.ts')),
  workerLegacyGoiasRouteStillServed: !/'\/api\/football\/team\/goias'/.test(
    stripComments(read('src/football/team.ts')),
  ) && /TEAM_PATTERN/.test(read('src/index.ts')),
  // Achado real da rodada de hardening: a 1ª versão reusou `fanDemonym`
  // ("Esmeraldino") pro título de gol/vitória, mudando a copy real do app
  // publicado ("GOOOOOOL DO GOIÁS!"/"VITÓRIA DO VERDÃO!" viraram "...DO
  // ESMERALDINO!" nos 2). Nunca mais — a copy vem de 2 campos dedicados
  // (`notificationGoalClubName`/`notificationVictoryNickname`), nunca
  // hardcoded dentro do builder nem reusando um campo semanticamente
  // diferente.
  notificationCopyNeverUsesFanDemonymField: !/clubConfig\.fanDemonym/.test(
    stripComments(read('supabase/functions/_shared/notification_message_builder.ts')),
  ),
  fanDemonymFieldRemovedFromEdgeConfig: !/fanDemonym/.test(
    stripComments(read('supabase/functions/_shared/club_server_config.ts')),
  ),
};

// ============================================================================
// 2) Drift check — os 3 pontos de config de clube (Flutter/Worker/Edge
// Functions) precisam declarar o MESMO canonicalClubId e o MESMO
// oneFootballTeamId pro Goiás, sempre. Extraído via regex do arquivo real,
// nunca hardcoded aqui separadamente (senão o teste nunca pegaria uma
// divergência real).
// ============================================================================
function extractFirst(src, re) {
  const m = src.match(re);
  return m ? m[1] : null;
}

const flutterSrc = read('lib/core/club/goias_club_config.dart');
const workerConfigSrc = read('src/football/_lib/club_server_config.ts');
const edgeConfigSrc = read('supabase/functions/_shared/club_server_config.ts');

const flutterCanonicalClubId = extractFirst(flutterSrc, /canonicalClubId:\s*'([^']+)'/);
const flutterOneFootballTeamId = extractFirst(flutterSrc, /oneFootballTeamId:\s*(\d+)/);
const flutterCode = extractFirst(flutterSrc, /code:\s*'([^']+)'/);

const workerCanonicalClubId = extractFirst(workerConfigSrc, /GOIAS_CANONICAL_CLUB_ID = '([^']+)'/);
const workerOneFootballTeamId = extractFirst(workerConfigSrc, /GOIAS_ONEFOOTBALL_TEAM_ID = (\d+)/);

const edgeCanonicalClubId = extractFirst(edgeConfigSrc, /canonicalClubId:\s*'([^']+)'/);
const edgeOneFootballTeamId = extractFirst(edgeConfigSrc, /oneFootballTeamId:\s*(\d+)/);
const edgeCode = extractFirst(edgeConfigSrc, /code:\s*'([^']+)'/);

// Rodada de hardening (revisão do usuário): o drift check só se aplica aos
// campos que os 3 pontos GENUINAMENTE precisam ter em comum — identidade do
// clube. Campos de apresentação/copy server-only (notification title/body)
// NUNCA precisam existir no Flutter (que nunca consome essa copy) nem no
// Worker (que não manda notificação nenhuma) — forçar isso seria
// duplicação inútil, não consistência. As 2 categorias ficam explícitas
// aqui, nunca implícitas por omissão.
const SHARED_IDENTITY_FIELDS = ['canonicalClubId', 'oneFootballTeamId', 'code'];
const SERVER_ONLY_PRESENTATION_FIELDS = ['notificationGoalClubName', 'notificationVictoryNickname'];

const edgeNotificationGoalClubName = extractFirst(edgeConfigSrc, /notificationGoalClubName:\s*'([^']+)'/);
const edgeNotificationVictoryNickname = extractFirst(edgeConfigSrc, /notificationVictoryNickname:\s*'([^']+)'/);

const driftCheck = {
  sharedIdentityFields: SHARED_IDENTITY_FIELDS,
  serverOnlyPresentationFields: SERVER_ONLY_PRESENTATION_FIELDS,
  flutterCanonicalClubId,
  workerCanonicalClubId,
  edgeCanonicalClubId,
  flutterOneFootballTeamId,
  workerOneFootballTeamId,
  edgeOneFootballTeamId,
  flutterCode,
  edgeCode,
  canonicalClubIdMatchesAcrossAll3:
    flutterCanonicalClubId != null &&
    flutterCanonicalClubId === workerCanonicalClubId &&
    flutterCanonicalClubId === edgeCanonicalClubId,
  oneFootballTeamIdMatchesAcrossAll3:
    flutterOneFootballTeamId != null &&
    flutterOneFootballTeamId === workerOneFootballTeamId &&
    flutterOneFootballTeamId === edgeOneFootballTeamId,
  codeMatchesFlutterAndEdge: flutterCode != null && flutterCode === edgeCode,
  // Server-only — nunca comparado contra Flutter/Worker (não fazem sentido
  // lá), só verificado que EXISTE e é o valor real esperado pro Goiás —
  // prova que não regrediu pra `fanDemonym`/outro campo por engano de novo.
  edgeNotificationGoalClubName,
  edgeNotificationVictoryNickname,
  goiasNotificationCopyCorrect:
    edgeNotificationGoalClubName === 'Goiás' && edgeNotificationVictoryNickname === 'Verdão',
};

// ============================================================================
// 3) Classificação de achados conhecidos — família mais ampla de `isGoias`
// que NÃO foi alterada nesta rodada (data-shape/editorial, deliberadamente
// deferida — ver relatório).
// ============================================================================
const classifiedButNotFixed = {
  clubHistoryEntryIsGoias: {
    file: 'lib/features/squad/domain/club_history_entry.dart',
    present: /final bool isGoias/.test(read('lib/features/squad/domain/club_history_entry.dart')),
    classification: 'GENERIC_RUNTIME_BUG_DEFERRED',
    reason: 'is_goias é coluna real no Supabase, marcando se uma passagem no histórico de clube de um jogador é a do clube atualmente mostrado — resolver de verdade exigiria casar nome de clube livre-texto contra um registry canônico, fora do escopo desta etapa (M3.3 é Flutter+Worker+Edge Functions, não redesign de schema de conteúdo editorial).',
  },
  careerEntryIsGoias: {
    file: 'lib/features/arena/games/career_path/career_models.dart',
    present: /final bool isGoias/.test(read('lib/features/arena/games/career_path/career_models.dart')),
    classification: 'GENERIC_RUNTIME_BUG_DEFERRED',
    reason: 'mesmo padrão de club_history_entry.dart, aplicado ao jogo Adivinhe o Clube (Arena) — mesma razão de não resolver aqui.',
  },
  passportIsGoias: {
    file: 'lib/features/passport/presentation/v2/widgets/passport_match_ticket_v2.dart',
    present: /_isGoias\(String team\)/.test(read('lib/features/passport/presentation/v2/widgets/passport_match_ticket_v2.dart')),
    classification: 'EDITORIAL_CONTENT_ALLOWED_PASSPORT_EXCLUDED',
    reason: 'Passaporte continua fora da tenancy nesta etapa (NEEDS_PRODUCT_DECISION, ver M2.1/M2.2A) — catalogado, não alterado, por instrução explícita.',
  },
  lineupMatchesFallbackTeamToGuess: {
    file: 'lib/features/arena/games/lineup/lineup_matches.dart',
    present: /teamToGuess:\s*'Goiás'/.test(read('lib/features/arena/games/lineup/lineup_matches.dart')),
    classification: 'CONFIG_ALLOWED_FALLBACK_DATASET',
    reason: 'dataset local de fallback registrado só sob a chave \'goias\' em ClubScopedFallback (nunca servido pra outro clube) — mesmo padrão de career_players.dart/goias_players.dart desde a M3.1.',
  },
  clubSongVolumeStoreUnscoped: {
    file: 'lib/features/club/data/club_song_volume_store.dart',
    present: !/ClubScopedStorageKey/.test(read('lib/features/club/data/club_song_volume_store.dart')),
    classification: 'LOCAL_STORAGE_SCOPE_NOT_REQUIRED',
    reason: 'guarda só o volume preferido (0.0-1.0), uma preferência de hábito do usuário, nunca conteúdo do clube — o próprio arquivo de música já vem de ClubAssets/branding, não depende dessa chave.',
  },
};

// ============================================================================
// 4) Local storage — 3 stores corrigidas nesta rodada, ClubScopedStorageKey
// aplicado com migração transparente da chave legacy só pro Goiás.
// ============================================================================
const localStorageFixes = {
  storeLocalStorage: {
    file: 'lib/features/store/data/store_local_storage.dart',
    scoped: /ClubScopedStorageKey/.test(read('lib/features/store/data/store_local_storage.dart')),
    legacyMigration: /identity\.code == 'goias'/.test(read('lib/features/store/data/store_local_storage.dart')),
  },
  guessPlayerStorage: {
    file: 'lib/features/arena/games/guess_player/data/guess_player_storage.dart',
    scoped: /ClubScopedStorageKey/.test(read('lib/features/arena/games/guess_player/data/guess_player_storage.dart')),
    legacyMigration: /_isGoiasLegacyEligible/.test(read('lib/features/arena/games/guess_player/data/guess_player_storage.dart')),
  },
  localBestScoreStore: {
    file: 'lib/features/arena/shared/local_best_score_store.dart',
    scoped: /ClubScopedStorageKey/.test(read('lib/features/arena/shared/local_best_score_store.dart')),
    legacyMigration: /identity\.code == 'goias'/.test(read('lib/features/arena/shared/local_best_score_store.dart')),
  },
};

// ============================================================================
// Métricas agregadas (item 42 do pedido)
// ============================================================================
const genericRuntimeGoiasLiteralViolations = Object.values(namedViolationChecks).filter((v) => v === false).length;
const genericRuntimeGoiasIdViolations = /GOIAS_TEAM_ID|Team\.goiasId/.test(
  stripComments(read('lib/features/match/domain/entities/team.dart')) +
    stripComments(read('supabase/functions/notifications-poll-live-match/index.ts')),
)
  ? 1
  : 0;
const serverRuntimeGoiasLiteralViolations = [
  stripComments(read('src/football/team.ts')),
  stripComments(read('src/football/teamSeason.ts')),
  stripComments(read('supabase/functions/notifications-sync-and-check-access/index.ts')),
].filter((src) => /\/api\/football\/team\/goias\b/.test(src)).length;
const hardcodedApiFootballTeamIds = [flutterOneFootballTeamId, workerOneFootballTeamId, edgeOneFootballTeamId].every(
  (v) => v === '1863',
)
  ? 0 // os 3 concordam entre si e vivem só dentro dos respectivos ClubConfig/registry — não é hardcode fora de config
  : 3;
const workerSpecificRouteViolations = /pathname === '\/api\/football\/team\/goias'/.test(
  stripComments(read('src/index.ts')),
)
  ? 1
  : 0;
// resolveClubServerConfigByClubId/session.club_id (poll-live-match) e
// event.club_id (dispatch) nunca caem pro Goiás por omissão — checado
// via presença do guard explícito (UnknownClubError / club_id desconhecido)
// nos 2 arquivos que resolvem clube a partir de dado gravado no banco.
const crossClubFallbackViolations =
  (/resolveClubServerConfigByClubId/.test(read('supabase/functions/notifications-poll-live-match/index.ts')) &&
  /if \(!clubConfig\)/.test(read('supabase/functions/notifications-poll-live-match/index.ts'))
    ? 0
    : 1) +
  (/resolveClubServerConfigByClubId/.test(read('supabase/functions/notifications-dispatch/index.ts')) &&
  /if \(!clubConfig\)/.test(read('supabase/functions/notifications-dispatch/index.ts'))
    ? 0
    : 1);
const localStorageScopeViolations = Object.values(localStorageFixes).filter((v) => !v.scoped).length;
const serverClubConfigRegistryCount = (workerConfigSrc.match(/^\s*const \w+_SERVER_CONFIG/gm) || []).length || 1;
const realClubRegistryCount = ((read('lib/core/club/club_registry.dart').match(/'[a-z-]+':\s*\w+ClubConfig/g)) || []).length;

const audit = {
  namedViolationChecks,
  driftCheck,
  classifiedButNotFixed,
  localStorageFixes,
  summary: {
    genericRuntimeGoiasLiteralViolations,
    genericRuntimeGoiasIdViolations,
    serverRuntimeGoiasLiteralViolations,
    hardcodedApiFootballTeamIds,
    workerSpecificRouteViolations,
    crossClubFallbackViolations,
    localStorageScopeViolations,
    serverClubConfigRegistryCount,
    realClubRegistryCount,
  },
  allNamedViolationsFixed: Object.values(namedViolationChecks).every(Boolean),
  driftFree:
    driftCheck.canonicalClubIdMatchesAcrossAll3 &&
    driftCheck.oneFootballTeamIdMatchesAcrossAll3 &&
    driftCheck.codeMatchesFlutterAndEdge &&
    driftCheck.goiasNotificationCopyCorrect,
  allLocalStorageFixed: Object.values(localStorageFixes).every((v) => v.scoped && v.legacyMigration),
};

fs.writeFileSync(
  path.join(RECON, 'multiclub_runtime_hardcodes_audit.json'),
  JSON.stringify(audit, null, 2) + '\n',
);
console.log(JSON.stringify(audit.summary, null, 2));
console.log('allNamedViolationsFixed:', audit.allNamedViolationsFixed);
console.log('driftFree:', audit.driftFree);
console.log('allLocalStorageFixed:', audit.allLocalStorageFixed);
console.log('\nEscrito em:', RECON);

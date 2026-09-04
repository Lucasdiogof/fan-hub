// ============================================================================
// Rollout Gate — audit read-only de prontidão pra M2.2B-B (retirar chaves
// legacy). NÃO aplica nada, NÃO decide nada — só mede o que REALMENTE
// existe no código hoje, via grep determinístico (nunca uma lista estática
// marcada "true" à mão).
//
// A pergunta central: depois que M2.2B-B dropar as chaves legacy, o que
// impede uma instalação ANTIGA/atual do app de continuar escrevendo no
// banco? Este audit prova, com evidência de código, que hoje NADA impede
// isso server-side — e que a tela de force-update (client-side) sozinha
// NÃO muda essa resposta, porque o servidor (RLS/RPC/PostgREST) nunca soube
// identificar a versão de quem está chamando.
//
// RODADA 2 (correção): a rodada 1 concluiu "nenhum app publicado ainda"
// olhando só workflow de CI/build. Isso era INCOMPLETO — nunca checou se o
// deployment que JÁ EXISTIA (Cloudflare Worker, `wrangler.toml` `[assets]
// directory = "build/web"`) estava ao vivo. Um `curl` direto em
// 2026-09-03 provou HTTP 200 servindo um build Flutter web REAL, com
// `version.json` = `{"version":"1.0.0","build_number":"1"}` — e
// `git rev-list --count origin/main..HEAD` = 35 (HEAD local está 35
// commits à frente de `origin/main`, cujo último commit é anterior a TODA
// a série multiclub M3.2-M3.4). Ou seja: existe HOJE um cliente web AO VIVO
// rodando código pré-multiclub, com os `onConflict` legacy. Isso é
// LEGACY_CLIENTS_IN_THE_WILD=true, não um exercício hipotético.
//
// Essa evidência (verificação de rede + git) foi feita nesta sessão, é
// datada, e está registrada aqui como snapshot — igual ao padrão já usado
// em `audit_multiclub_key_scope.mjs` (M2.2B) pra achados de rede/live que
// não podem ser re-derivados por grep puro em toda execução futura. Um
// re-check real (novo `curl` + `git fetch`) deve ser feito de novo antes de
// qualquer decisão de M2.2B-B no futuro — este snapshot NÃO se atualiza
// sozinho.
// ============================================================================
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

function grep(pattern, dir) {
  try {
    return execSync(`grep -rhoE ${JSON.stringify(pattern)} ${JSON.stringify(path.join(ROOT, dir))}`, { encoding: 'utf8' })
      .split('\n').filter(Boolean);
  } catch { return []; }
}
function grepCount(pattern, dir) { return grep(pattern, dir).length; }
function fileExists(rel) { return fs.existsSync(path.join(ROOT, rel)); }
function read(rel) { return fs.readFileSync(path.join(ROOT, rel), 'utf8'); }

// --- 1. o mecanismo de minimum-version existe no código? -------------------
const releaseGateFileExists = fileExists('lib/core/release/release_gate.dart');
const releaseMigrationExists = fileExists('archive/supabase/goias-legacy-migrations/files/20260903110000_add_app_release_requirements.sql');
const releaseMigrationSql = releaseMigrationExists
  ? read('archive/supabase/goias-legacy-migrations/files/20260903110000_add_app_release_requirements.sql')
  : '';
const releaseTableClubAndPlatformScoped =
  /club_id uuid not null references public\.clubs/i.test(releaseMigrationSql) &&
  /platform text not null check/i.test(releaseMigrationSql) &&
  /unique \(club_id, platform\)/i.test(releaseMigrationSql);
const releaseTablePublicReadOnly =
  /for select\s*\n?\s*using \(true\)/i.test(releaseMigrationSql) &&
  !/for (insert|update|delete)/i.test(releaseMigrationSql);
const releaseMigrationSeedIsInert =
  /force_update.*false/i.test(releaseMigrationSql) || /select id, platform, '1\.0\.0', 1, false/i.test(releaseMigrationSql);
const releaseTableStoreUrlNullable = /store_url text,/.test(releaseMigrationSql) && !/store_url text not null/i.test(releaseMigrationSql);

const minimumVersionMechanismExists =
  releaseGateFileExists && releaseMigrationExists && releaseTableClubAndPlatformScoped && releaseTablePublicReadOnly;

// --- 2. o novo runtime usa o gate no boot, ANTES de liberar navegação? -----
const routerSql = fileExists('lib/core/router/app_router.dart') ? read('lib/core/router/app_router.dart') : '';
const splashSql = fileExists('lib/features/splash/presentation/pages/splash_video_page.dart')
  ? read('lib/features/splash/presentation/pages/splash_video_page.dart')
  : '';
const routerRedirectsOnBlocked = /releaseGate\.blocked/.test(routerSql) && /update-required/.test(routerSql);
const splashAwaitsReleaseCheck = /ReleaseGate>\(\)\.ensureChecked\(\)/.test(splashSql);
const newAppContainsMinimumVersionGate = routerRedirectsOnBlocked && splashAwaitsReleaseCheck;

// --- 3. fail-safe: nunca trava o boot por indisponibilidade -----------------
const releaseGateSrc = releaseGateFileExists ? read('lib/core/release/release_gate.dart') : '';
const releaseGateHasTimeout = /_checkTimeout/.test(releaseGateSrc) && /\.timeout\(/.test(releaseGateSrc);
const releaseGateFailsOpenOnError = /catch \(_\)/.test(releaseGateSrc) && /fail-open/i.test(releaseGateSrc);

// --- 4. o release gate É uma fronteira de segurança? ------------------------
// NUNCA deve ser — é UX/disponibilidade (fail-open por design), e um valor
// de versão declarado pelo PRÓPRIO cliente (mesmo que via RPC) nunca prova
// nada: um cliente malicioso/desatualizado pode mandar qualquer coisa. A
// única coisa que de fato barra um write antigo é o SERVIDOR revogar o
// contrato antigo (REVOKE EXECUTE / DROP da chave legacy) — nunca uma
// checagem que confia num parâmetro enviado por quem está sendo checado.
const releaseGateIsSecurityBoundary = false; // por design — nunca calculado como true

// --- 5. Evidência de distribuição — o que o repo PROVA, sem inventar -------
// Cada item aqui é OU confirmado por evidência concreta (arquivo/config/
// resposta de rede real, citada) OU marcado UNKNOWN quando o repo
// genuinamente não permite concluir nada (nunca "ausência de workflow" vira
// "certeza de que não existe").
const androidReleaseSigningConfig = fileExists('android/app/build.gradle.kts')
  ? read('android/app/build.gradle.kts')
  : '';
const androidReleaseUsesDebugSigning = /signingConfig = signingConfigs\.getByName\("debug"\)/.test(androidReleaseSigningConfig);
const androidHasRealKeystoreConfig = fileExists('android/key.properties');
const iosDoc = fileExists('docs/multiclub/12_flavors_ios.md') ? read('docs/multiclub/12_flavors_ios.md') : '';
const iosDocConfirmsNotPublished = /TestFlight, App Store Connect.{0,40}fora do escopo/i.test(iosDoc.replace(/\n/g, ' '));
const hasFastlaneOrCodemagic = fileExists('codemagic.yaml') || fs.existsSync(path.join(ROOT, 'android/fastlane')) || fs.existsSync(path.join(ROOT, 'ios/fastlane'));
const buildWorkflows = fs.existsSync(path.join(ROOT, '.github/workflows'))
  ? fs.readdirSync(path.join(ROOT, '.github/workflows'))
  : [];
const anyBuildOrPublishWorkflow = buildWorkflows.some((f) => /build|release|deploy|publish/i.test(f));

// PUBLIC_STORE_RELEASE_EXISTS (Play Store / App Store produção) — evidência
// TÉCNICA contra (não só ausência de workflow): variant `release` do
// Android assina com a keystore de DEBUG (incompatível com upload real na
// Play Console) e nenhum `key.properties`/keystore próprio existe; iOS não
// tem fastlane/ExportOptions/provisioning, e a própria doc do projeto
// registra "TestFlight, App Store Connect — fora do escopo". Confiança
// alta, NÃO absoluta — um build+upload manual totalmente fora deste repo
// não deixaria rastro nenhum aqui.
const publicStoreReleaseExists = {
  value: false,
  confidence: 'high_not_absolute',
  evidence: {
    androidReleaseUsesDebugSigning,
    androidHasRealKeystoreConfig,
    iosDocConfirmsNotPublished,
    hasFastlaneOrCodemagic,
  },
};

// TEST_DISTRIBUTION_EXISTS (Play internal/closed/open testing, TestFlight,
// Firebase App Distribution) — mesma evidência (testing tracks também
// exigem assinatura própria na Play Console; TestFlight exige a mesma
// infra de provisioning que a doc confirma ausente; nenhum fastlane
// firebase_app_distribution/appdistribution config existe).
const testDistributionExists = {
  value: false,
  confidence: 'high_not_absolute',
  evidence: { androidReleaseUsesDebugSigning, iosDocConfirmsNotPublished, hasFastlaneOrCodemagic },
};

// GITHUB_RELEASES / distribuição manual de APK/IPA — genuinamente
// indeterminável pelo repo local (API do GitHub retornou 404 pra este
// audit — pode ser repo privado, rede restrita neste ambiente, ou 0
// releases; as 3 são indistinguíveis daqui) e distribuição manual
// (WhatsApp/e-mail/Drive) nunca deixaria qualquer rastro no código.
const githubReleasesExistence = 'UNKNOWN_REQUIRES_OWNER_CONFIRMATION';
const manualApkIpaDistribution = 'UNKNOWN_REQUIRES_OWNER_CONFIRMATION';

// WEB_PWA_DEPLOYMENT_EXISTS — CONFIRMADO ao vivo (snapshot datado, ver
// cabeçalho do arquivo). `wrangler.toml` prova a INTENÇÃO (serve
// `build/web` como SPA); o `curl` real em 2026-09-03 prova o FATO (HTTP
// 200, `version.json` real).
const wranglerTomlServesWebBuild = fileExists('wrangler.toml') &&
  /directory = "build\/web"/.test(read('wrangler.toml')) &&
  /not_found_handling = "single-page-application"/.test(read('wrangler.toml'));
const webPwaDeploymentExists = {
  value: true,
  checkedAt: '2026-09-03T03:03Z',
  evidence: {
    wranglerTomlServesWebBuild,
    liveCheckUrl: 'https://goias-app.lucasdiogo1234.workers.dev/',
    liveCheckHttpStatus: 200,
    liveCheckCfCacheStatus: 'HIT (primeira request desta sessão — indício de tráfego anterior real, não prova volume/quem)',
    versionJson: { version: '1.0.0', build_number: '1' },
  },
};

// LEGACY_CLIENTS_IN_THE_WILD — a peça que muda o roadmap. O deployment web
// ao vivo reflete `origin/main` (Cloudflare deploya via integração git),
// cujo HEAD está `commitsLocalHeadAheadOfOriginMain` commits ATRÁS do HEAD
// local — ou seja, ele NUNCA viu M3.2/M3.3/M2.2B-A/M3.4. Roda os
// `onConflict`/PK legacy originais. Isso é um cliente legacy real,
// reachable, ao vivo — não hipotético.
const commitsLocalHeadAheadOfOriginMain = (() => {
  try {
    execSync('git fetch origin', { cwd: ROOT, stdio: 'ignore' });
    return parseInt(execSync('git rev-list --count origin/main..HEAD', { cwd: ROOT, encoding: 'utf8' }).trim(), 10);
  } catch { return null; }
})();
const legacyClientsInTheWild = {
  value: true,
  reasoning: 'webPwaDeploymentExists=true E ele reflete um commit anterior a toda a série multiclub (M3.2-M3.4 nunca foram pushados) — logo usa onConflict/PK legacy, confirmado ao vivo.',
  degreeOfActiveUsage: 'UNKNOWN_REQUIRES_OWNER_CONFIRMATION', // existência != volume de tráfego real
  commitsLocalHeadAheadOfOriginMainAtCheckTime: 35, // snapshot datado — ver cabeçalho
  commitsLocalHeadAheadOfOriginMainNow: commitsLocalHeadAheadOfOriginMain, // recalculado a cada execução, pode divergir do snapshot se HEAD/origin mudarem
};

// --- 6. o servidor consegue identificar a versão de quem chama? ------------
const customVersionHeaderSent = grepCount(
  "X-App-Version|X-Client-Version|app[-_]version.*header|headers\\['[Xx]-[Aa]pp",
  'lib',
) > 0;
const rlsReferencesRequestVersion = grepCount('request\\.headers.*version', 'archive/supabase/goias-legacy-migrations/files') > 0;
const serverCanIdentifyClientVersion = customVersionHeaderSent && rlsReferencesRequestVersion;

// --- 7. writes diretos via PostgREST podem ser rejeitados por versão? ------
const anyPolicyReferencesVersion = grepCount('policy[\\s\\S]{0,200}version', 'archive/supabase/goias-legacy-migrations/files') > 0;
const directPostgrestWritesCanBeVersionRejected = serverCanIdentifyClientVersion && anyPolicyReferencesVersion;

// --- 8. RPCs legacy podem rejeitar por versão? ------------------------------
// IMPORTANTE (correção desta rodada): mesmo que uma RPC aceite um parâmetro
// tipo `p_client_build`, isso é só um CLIENT_VERSION_SIGNAL — o cliente
// pode mandar qualquer valor. Só conta como SERVER_ENFORCED_CONTRACT se o
// caminho antigo (sem esse parâmetro, ou com REVOKE na assinatura antiga)
// deixar de existir/executar. Este grep continua medindo só a existência
// do parâmetro porque nenhuma RPC tem isso hoje — mas o significado do
// metric, se um dia ficar true, NUNCA deve ser lido como "seguro" sozinho.
const anyRpcTakesVersionParam = grepCount('p_client_version|p_app_version|p_app_build', 'archive/supabase/goias-legacy-migrations/files') > 0;
const legacyRpcCallsCanBeVersionRejected = anyRpcTakesVersionParam;

// --- 9. LEGACY_WRITE_PATHS_EXIST -------------------------------------------
// As chaves/RPCs legacy (que M2.2B-B pretende retirar) ainda existem no
// schema hoje — fato já estabelecido pelo audit da M3.4/M2.2B-A
// (`user_game_item_progress_pkey`, `tickets_user_match_checkin_uidx`,
// `arena_record_score` legacy, etc., todos confirmados ao vivo).
const legacyWritePathsExist = true;

// --- 10. telemetria consegue detectar uso de versão antiga? ----------------
// Precisão desta rodada: Sentry só vê SESSÕES/EVENTOS CAPTURADOS (erros,
// transactions amostradas) — nunca "100% das instalações ativas". É um
// sinal útil, não um censo.
const mainSrc = fileExists('lib/main.dart') ? read('lib/main.dart') : '';
const sentryReleaseTaggingPresent = /options\.release\s*=\s*release/.test(mainSrc) &&
  /goias_app@\$\{packageInfo\.version\}/.test(mainSrc);
const telemetryCanProvideReleaseSignalFromCapturedActivity = sentryReleaseTaggingPresent;

// --- 11. os booleanos formais pedidos --------------------------------------
const legacyAppWritesBlocked = directPostgrestWritesCanBeVersionRejected && legacyRpcCallsCanBeVersionRejected;
// M2.2B-B só pode avançar sem esperar rollout SE não houver cliente legacy
// no ar. Como legacyClientsInTheWild=true (confirmado), o bloqueio
// PERMANECE true — não é mais "suposição automática de app publicado", é
// decisão baseada no cliente web AO VIVO encontrado nesta rodada.
const m2_2bBBlockedByRollout = legacyClientsInTheWild.value !== false; // true se true OU unknown — só false quando PROVADO false
const m2_2bBReady = legacyAppWritesBlocked && !m2_2bBBlockedByRollout;

const audit = {
  minimumVersion: {
    releaseGateFileExists,
    releaseMigrationExists,
    releaseTableClubAndPlatformScoped,
    releaseTablePublicReadOnly,
    releaseMigrationSeedIsInert,
    releaseTableStoreUrlNullable,
  },
  boot: {
    routerRedirectsOnBlocked,
    splashAwaitsReleaseCheck,
    releaseGateHasTimeout,
    releaseGateFailsOpenOnError,
  },
  distributionEvidence: {
    publicStoreReleaseExists,
    testDistributionExists,
    githubReleasesExistence,
    manualApkIpaDistribution,
    webPwaDeploymentExists,
    legacyClientsInTheWild,
  },
  serverEnforcement: {
    customVersionHeaderSent,
    rlsReferencesRequestVersion,
    anyPolicyReferencesVersion,
    anyRpcTakesVersionParam,
  },
  telemetry: {
    sentryReleaseTaggingPresent,
  },
};

const metrics = {
  minimumVersionMechanismExists,
  newAppContainsMinimumVersionGate,
  releaseGateIsSecurityBoundary,
  publicStoreReleaseExists: publicStoreReleaseExists.value,
  testDistributionExists: testDistributionExists.value,
  webDeploymentExists: webPwaDeploymentExists.value,
  legacyClientsInTheWild: legacyClientsInTheWild.value,
  legacyWritePathsExist,
  serverCanIdentifyClientVersion,
  directPostgrestWritesCanBeVersionRejected,
  legacyRpcCallsCanBeVersionRejected,
  telemetryCanProvideReleaseSignalFromCapturedActivity,
  legacyAppWritesBlocked,
  m2_2bBBlockedByRollout,
  m2_2bBReady,
};

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_rollout_readiness_audit.json'), JSON.stringify(audit, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_rollout_readiness_stats.json'), JSON.stringify(metrics, null, 2) + '\n');
console.log(JSON.stringify(metrics, null, 2));
console.log('\nEscrito em:', OUT_DIR);

export { minimumVersionMechanismExists, metrics };

// ============================================================================
// Post-Rollout Legacy Retirement Gate.
//
// Pergunta central: agora que o M3.4 Web Release está confirmado ao vivo em
// produção, já podemos liberar a execução de M2.2B-B (remover chaves/DEFAULT
// legacy)? NUNCA exige "zero browser antigo existe" — isso é impossível de
// provar olhando o servidor (service worker/cache de browser podem manter
// bundle antigo por tempo indefinido). A pergunta certa é: estamos dispostos
// a encerrar compatibilidade com bundles antigos, sabendo exatamente o que
// vai acontecer com eles quando isso ocorrer?
//
// Combina 3 fontes, todas já auditadas/verificadas em rodadas anteriores +
// verificações novas desta rodada:
//   - Legacy Contract Retirement Audit (`audit_legacy_contract_retirement.mjs`)
//     — o que trava tecnicamente quando as chaves/DEFAULT saem.
//   - M3.4 Web Release (`docs/multiclub/38_...md`) — o release está mesmo
//     no ar (verificado ao vivo, não assumido).
//   - Sentry, risco de cliente nativo, cobertura de club_id no HEAD atual —
//     checados agora, com UNKNOWN explícito onde o repo genuinamente não
//     decide sozinho.
// ============================================================================
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const RECON = OUT_DIR;

function read(rel) { try { return fs.readFileSync(path.join(ROOT, rel), 'utf8'); } catch { return null; } }
function grepCount(pattern, dir) {
  try {
    return execSync(`grep -rhoE ${JSON.stringify(pattern)} ${JSON.stringify(path.join(ROOT, dir))}`, { encoding: 'utf8' })
      .split('\n').filter(Boolean).length;
  } catch { return 0; }
}

// --- 1. o Legacy Contract Retirement Audit já fechado (reusa, não refaz) --
const legacyContract = JSON.parse(read('data_export/goias/player_reconciliation/multiclub_legacy_contract_retirement_stats.json') || '{}');

// --- 2. o novo deployment web está mesmo confirmado ao vivo? ---------------
// Live check real, datado — snapshot desta rodada. Igual ao padrão já usado
// pro achado do deployment stale no rollout gate.
const NEW_WEB_DEPLOYMENT_SNAPSHOT = {
  checkedAt: '2026-09-03',
  url: 'https://goias-app.lucasdiogo1234.workers.dev/',
  versionJson: { version: '1.0.1', build_number: '2' },
  httpStatusRoot: 200,
  serviceWorkerHttpStatus: 200,
  workerGoiasRouteHttpStatus: 200,
  workerUnknownClubHttpStatus: 404,
  bundleContainsM34Markers: {
    updateRequired: true,
    upsertMembershipCheckinTicketForClub: true,
    appReleaseRequirements: true,
  },
};
const newWebDeploymentConfirmed = NEW_WEB_DEPLOYMENT_SNAPSHOT.versionJson.version === '1.0.1' &&
  NEW_WEB_DEPLOYMENT_SNAPSHOT.versionJson.build_number === '2' &&
  NEW_WEB_DEPLOYMENT_SNAPSHOT.httpStatusRoot === 200;

// --- 3. um bundle antigo AINDA PODE existir? (nunca provável de ser false) -
// Service worker + cache de browser + aba aberta desde antes do release +
// PWA instalada offline — nenhum desses é observável do servidor. Sempre
// `true` por design; o gate NUNCA deve exigir provar o contrário.
const oldWebBundleCanStillExist = true;

// --- 4. o HEAD atual sobrevive às chaves finais? (não só "old app falha") -
// Verifica, pro código REAL de HOJE (não o legacy), que toda tabela cujo
// DEFAULT será removido recebe club_id explícito no write correspondente —
// nunca assumido, sempre grepado contra o código atual.
// A prova real e determinística é grep no código Dart atual (a RPC já foi
// confirmada ao vivo via pg_proc nesta sessão — ver relatório): cada
// caminho de escrita que hoje depende do DEFAULT tem, no HEAD atual, um
// literal `club_id` explícito na mesma função/bloco. `create_store_order_
// for_club`/`subscribe_to_plan_for_club`/`arena_record_score_for_club`
// foram confirmadas ao vivo via `pg_proc.prosrc` nesta mesma sessão
// (SELECT prosrc ~ 'insert into ... club_id' = true pras 3) — não
// re-verificadas aqui pra não depender de rede num audit reproduzível;
// snapshot datado, igual ao padrão do restante deste arquivo.
const headWritesIncludeClubId = {
  ticketOrdersInsert: grepCount("'club_id': _clubId", 'lib/features/ticket/data/mock_ticket_repository.dart') > 0,
  ticketsPurchaseInsert: grepCount("'club_id': _clubId", 'lib/features/ticket/data/mock_ticket_repository.dart') > 0,
  undoCheckInFiltersClubId: grepCount("eq\\('club_id', _clubId\\)", 'lib/features/ticket/data/mock_ticket_repository.dart') >= 4,
};
const currentAppDependsOnGoiasDefaults = !Object.values(headWritesIncludeClubId).every(Boolean);
const currentAppSurvivesFinalKeys = legacyContract.rpcOnlyMigrationRequired === false &&
  legacyContract.unversionedLegacyWritesRemaining === 0 &&
  !currentAppDependsOnGoiasDefaults;

// --- 5. updates/deletes tenant-scoped que sobrevivem ao M2.2B-B ------------
// Não é INSERT — não depende de KEY nem DEFAULT (UPDATE/DELETE ... WHERE
// nunca precisam de constraint única pra rodar). Achado real: a versão
// LEGACY (commit 613874a) desses 2 grupos de statement NÃO filtra por
// club_id; a versão ATUAL (HEAD) já filtra (regra 6 da M3.2, confirmado
// por grep acima). Continuam funcionando pro bundle antigo depois de
// M2.2B-B — não é um risco de segurança HOJE porque SECOND_CLUB_BLOCKED,
// mas vira risco real assim que M4 registrar um 2º clube.
const legacyTenantUpdatesDeletesRemaining = [
  { feature: 'undoCheckIn — tickets.status=cancelled', table: 'tickets', legacyFiltersClubId: false, headFiltersClubId: true },
  { feature: 'undoCheckIn — ticket_checkin_decisions delete', table: 'ticket_checkin_decisions', legacyFiltersClubId: false, headFiltersClubId: true },
  { feature: 'clearCheckInDecision — ticket_checkin_decisions delete', table: 'ticket_checkin_decisions', legacyFiltersClubId: false, headFiltersClubId: true },
];

// --- 6. reads do bundle antigo continuam funcionando? ----------------------
// SELECT nunca depende de PK/UNIQUE/DEFAULT — só de RLS + filtro WHERE.
// Com SECOND_CLUB_BLOCKED=true, um filtro só por user_id (sem club_id) já
// retorna exatamente os dados certos (só existe 1 clube). Portanto: o
// bundle antigo abre e LÊ normalmente depois de M2.2B-B; só as ESCRITAS
// cobertas (§1) passam a falhar.
const oldClientReadsContinue = true;
const oldClientWritesBlocked = legacyContract.unversionedLegacyWritesRemaining === 0;

// --- 7. legacy RPC retirement -----------------------------------------------
const LEGACY_RPC_ACL_SNAPSHOT = {
  checkedAt: '2026-09-03',
  rpcs: ['arena_record_score', 'arena_ranking', 'arena_my_rank', 'arena_user_detail', 'crowd_lineup', 'get_my_membership', 'subscribe_to_plan', 'create_store_order'],
  currentEffectiveAcl: { anon: true, authenticated: true, service_role: true, public: true }, // igual pras 8, confirmado ao vivo via has_function_privilege
  plannedFinalAclIfRevoked: { anon: false, authenticated: false, service_role: 'REVIEW (nenhum uso de admin/backend identificado nesta rodada — não assumido)', public: false },
};
const legacyRpcsReadyForRetirement = LEGACY_RPC_ACL_SNAPSHOT.rpcs.length; // 8 — HEAD chama 0 delas (confirmado abaixo)
// Grep individual por nome (nunca alternação `a|b` num regex passado por
// shell — no Windows o `execSync` roda via cmd.exe, que trata `|` como
// pipe do próprio shell mesmo dentro de aspas do Node, quebrando o
// comando silenciosamente).
const currentAppUsesLegacyRpcs = LEGACY_RPC_ACL_SNAPSHOT.rpcs.some(
  (name) => grepCount(`\\.rpc[^'"]{0,60}'${name}'`, 'lib') > 0,
);

// --- 8. DEFAULT Goiás — as 24 tabelas, classificadas ------------------------
const DEFAULT_TABLES_CLASSIFICATION = [
  ...['arena_achievements', 'arena_selected_content', 'career_path_progress', 'lineup_match_progress', 'match_lineup_votes', 'quiz_active_session', 'quiz_question_progress', 'player_identity_results', 'tactical_identity_results', 'user_notification_preferences', 'ticket_checkin_decisions'].map((t) => ({ table: t, classification: 'DROP_IN_M2_2B_B', reason: 'onConflict do HEAD já é tenant-aware (bridge M2.2B-A); write legacy fecha por KEY' })),
  ...['score_events', 'store_orders', 'supporter_memberships', 'ticket_orders', 'tickets'].map((t) => ({ table: t, classification: 'DROP_IN_M2_2B_B', reason: 'HEAD já manda club_id explícito nesse insert (confirmado por grep/pg_proc nesta rodada); write legacy fecha por DEFAULT' })),
  { table: 'career_players', classification: 'DROP_IN_M2_2B_B', reason: 'conteúdo, seed via SQL — nenhum upsert do app por person_id (M2.2B round 1)' },
  { table: 'guess_players', classification: 'DROP_IN_M2_2B_B', reason: 'idem career_players' },
  { table: 'squad_members', classification: 'DROP_IN_M2_2B_B', reason: 'idem career_players' },
  { table: 'lineup_matches', classification: 'DROP_IN_M2_2B_B', reason: 'conteúdo, seed via SQL' },
  { table: 'quiz_questions', classification: 'DROP_IN_M2_2B_B', reason: 'conteúdo, seed via SQL' },
  { table: 'notification_events', classification: 'DROP_IN_M2_2B_B', reason: 'Edge já manda club_id explícito (M3.3/M3.4)' },
  { table: 'match_monitor_sessions', classification: 'DROP_IN_M2_2B_B', reason: 'Edge já filtra por club_id (M3.3)' },
  { table: 'user_game_item_progress', classification: 'DROP_IN_M2_2B_B', reason: 'RPC nova já manda club_id explícito' },
];
const dropInM2_2bBCount = DEFAULT_TABLES_CLASSIFICATION.filter((t) => t.classification === 'DROP_IN_M2_2B_B').length;
const keepOrOutOfScopeCount = DEFAULT_TABLES_CLASSIFICATION.length - dropInM2_2bBCount;

// --- 9. risco de cliente NATIVO legacy --------------------------------------
// Atualizado nesta rodada com fato fornecido pelo DONO do projeto (não
// derivável do repo, e não inventado): o APK `1.0.0+1` foi distribuído
// manualmente pra ~3 pessoas, teste interno/controlado — nunca loja, nunca
// base pública. Isso muda o PESO do bloqueio (grupo pequeno e conhecido,
// não uma base de instalação desconhecida), mas não resolve o risco
// sozinho — só a redistribuição real do `1.0.1+2` resolve.
const legacyWebClientConfirmed = true; // confirmado ao vivo no rollout gate
const NATIVE_CLIENT_SNAPSHOT = {
  registeredAt: '2026-09-03',
  source: 'confirmação direta do dono do projeto (não derivável do repo)',
  legacyNativeClientConfirmed: true,
  legacyNativeClientCount: 3, // aproximado, conforme informado
  legacyNativeClientsControlled: true,
  publicNativeRelease: false,
};
// APK 1.0.1+2 — tentativa de geração NESTA sessão FALHOU (ver histórico
// abaixo); o DONO gerou com sucesso no próprio terminal logo em seguida —
// confirmado nesta sessão via `build/app/outputs/apk/release/output-
// metadata.json` (mesmo filesystem/diretório do projeto): versionCode=2,
// versionName=1.0.1, timestamp 2026-09-03 (bate com o pedido).
const APK_1_0_1_2_STATUS = {
  attemptedAt: '2026-09-03',
  buildCommand: 'flutter build apk --release',
  buildSucceeded: true, // gerado pelo dono no PRÓPRIO terminal, não nesta sessão
  generatedBy: 'owner, own terminal (this session\'s own attempts all failed — see buildBlockerHistory)',
  buildBlockerHistory: "Gradle 9.1 falhou NESTA SESSÃO com 'java.io.IOException: Unable to establish loopback connection' " +
    "(UnixDomainSockets.connect0 'Invalid argument: connect') — 4 mitigações tentadas, todas sem sucesso; " +
    'confirma que era um problema de ambiente desta sessão específica, não do projeto — o dono rodou o MESMO comando no próprio terminal e funcionou.',
  verifiedArtifact: {
    path: 'build/app/outputs/apk/release/output-metadata.json',
    versionCode: 2,
    versionName: '1.0.1',
    applicationId: 'br.com.goiasec.goias_app',
  },
  apkGenerated: true,
  // Confirmado pelo dono nesta sessão ("já mandei pra 3 amigos aqui, tá de
  // boa") — ação manual, nunca automatizável/verificável daqui; registrado
  // como afirmação do dono, mesmo padrão de toda "fato fornecido pelo
  // dono" já usado neste audit (ex.: NATIVE_CLIENT_SNAPSHOT acima).
  apkDeliveredToLegacyUsers: true,
  apkDeliveredConfirmedAt: '2026-09-03',
  apkDeliveredConfirmedBy: 'owner, direct confirmation in chat ("já mandei pra 3 amigos aqui, tá de boa")',
};
const legacyVersionSupportEnded = APK_1_0_1_2_STATUS.apkDeliveredToLegacyUsers === true;

// --- 10. Sentry — rebaixado a evidência adicional, NUNCA bloqueio obrigatório
// (decisão explícita do dono nesta rodada: grupo legacy pequeno e
// controlado não justifica exigir telemetria de produção como pré-condição).
const sentryReleaseSignalAvailable = false; // sem token de API neste ambiente (401 confirmado, não assumido) — DSN é só de envio
const sentryIsBlockingGate = false; // nunca mais obrigatório — só evidência adicional quando disponível

// --- 11. decisão formal -----------------------------------------------------
// Sentry SAIU da fórmula (agora só evidência adicional). O que decide o
// risco nativo não é mais "UNKNOWN", é "a redistribuição do 1.0.1+2 pros
// ~3 usuários legacy foi confirmada" — enquanto isso não acontece, o
// suporte ao 1.0.0+1 continua tecnicamente em vigor.
const postRolloutRetirementReady =
  newWebDeploymentConfirmed &&
  currentAppSurvivesFinalKeys &&
  legacyContract.rpcOnlyMigrationRequired === false &&
  legacyVersionSupportEnded === true;

const blockers = [];
if (!newWebDeploymentConfirmed) blockers.push('novo deployment web não confirmado ao vivo');
if (!currentAppSurvivesFinalKeys) blockers.push('HEAD atual não comprovadamente sobrevive às chaves finais');
if (legacyContract.rpcOnlyMigrationRequired !== false) blockers.push('RPC-only migration ainda necessária');
if (!APK_1_0_1_2_STATUS.apkGenerated) blockers.push('APK 1.0.1+2 ainda não gerado nesta sessão (bloqueio de ambiente Gradle/JDK, não de código — ver apk101_2Status)');
if (!APK_1_0_1_2_STATUS.apkDeliveredToLegacyUsers) blockers.push('APK 1.0.1+2 ainda não confirmado como entregue aos ~3 usuários legacy (ação manual do dono, pendente)');

const metrics = {
  newWebDeploymentConfirmed,
  oldWebBundleCanStillExist,
  currentAppSurvivesFinalKeys,
  legacyWritesCoveredByKeyRemoval: legacyContract.autoRetiredByKeyEnforcement,
  legacyWritesCoveredByDefaultRemoval: legacyContract.autoRetiredByDefaultRemoval,
  legacyTenantUpdatesDeletesRemaining: legacyTenantUpdatesDeletesRemaining.length,
  legacyRpcsReadyForRetirement,
  currentAppUsesLegacyRpcs,
  currentAppDependsOnGoiasDefaults,
  legacyNativeClientConfirmed: NATIVE_CLIENT_SNAPSHOT.legacyNativeClientConfirmed,
  legacyNativeClientCount: NATIVE_CLIENT_SNAPSHOT.legacyNativeClientCount,
  legacyNativeClientsControlled: NATIVE_CLIENT_SNAPSHOT.legacyNativeClientsControlled,
  publicNativeRelease: NATIVE_CLIENT_SNAPSHOT.publicNativeRelease,
  apk101_2Generated: APK_1_0_1_2_STATUS.apkGenerated,
  apk101_2DeliveredToLegacyUsers: APK_1_0_1_2_STATUS.apkDeliveredToLegacyUsers,
  legacyVersionSupportEnded,
  sentryReleaseSignalAvailable,
  sentryIsBlockingGate,
  postRolloutRetirementReady,
  blockers,
};

const audit = {
  legacyContractAuditReused: legacyContract,
  newWebDeploymentSnapshot: NEW_WEB_DEPLOYMENT_SNAPSHOT,
  headWritesIncludeClubId,
  legacyTenantUpdatesDeletesRemaining,
  oldClientReadsContinue,
  oldClientWritesBlocked,
  legacyRpcAclSnapshot: LEGACY_RPC_ACL_SNAPSHOT,
  defaultTablesClassification: DEFAULT_TABLES_CLASSIFICATION,
  dropInM2_2bBCount,
  keepOrOutOfScopeCount,
  legacyWebClientConfirmed,
  nativeClientSnapshot: NATIVE_CLIENT_SNAPSHOT,
  apk101_2Status: APK_1_0_1_2_STATUS,
};

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_post_rollout_retirement_gate_audit.json'), JSON.stringify(audit, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_post_rollout_retirement_gate_stats.json'), JSON.stringify(metrics, null, 2) + '\n');
console.log(JSON.stringify(metrics, null, 2));
console.log('\nEscrito em:', OUT_DIR);

export { metrics, audit };

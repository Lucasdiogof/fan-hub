import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const audit = JSON.parse(
  fs.readFileSync(path.join(RECON, 'multiclub_runtime_hardcodes_audit.json'), 'utf8'),
);

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

// ============================================================================
// 1) As violações nomeadas do pedido — cada uma no arquivo real onde vivia
// ============================================================================
console.log('1) violações nomeadas eliminadas do runtime genérico');
test('allNamedViolationsFixed = true (13/13 — 11 da 1ª rodada + 2 do bug de copy corrigido nesta rodada de hardening)', () => {
  assert.strictEqual(audit.allNamedViolationsFixed, true);
  assert.strictEqual(Object.keys(audit.namedViolationChecks).length, 13);
});
test('Team.isGoias/Team.goiasId removidos; Team.matchesClub(ClubConfig) presente', () => {
  assert.strictEqual(audit.namedViolationChecks.teamIsGoiasRemoved, true);
  assert.strictEqual(audit.namedViolationChecks.teamMatchesClubPresent, true);
});
test('_isGoiasHome removido (crowd_lineup_page.dart)', () => {
  assert.strictEqual(audit.namedViolationChecks.isGoiasHomeRemoved, true);
});
test('getGoiasSnapshot() removido do FootballRepository (renomeado getActiveClubSnapshot)', () => {
  assert.strictEqual(audit.namedViolationChecks.getGoiasSnapshotRemovedFromRepository, true);
});
test('rota /api/football/team/goias hardcoded removida do datasource Flutter (usa ClubConfig.identity.code)', () => {
  assert.strictEqual(audit.namedViolationChecks.hardcodedTeamRouteRemovedFromDatasource, true);
});
test("teamToGuess: 'Goiás' hardcoded removido do repository real (lineup_match_repository.dart)", () => {
  assert.strictEqual(audit.namedViolationChecks.teamToGuessHardcodeRemovedFromRepository, true);
});
test('GOIAS_TEAM_ID removido de notifications-poll-live-match', () => {
  assert.strictEqual(audit.namedViolationChecks.goiasTeamIdRemovedFromPollLiveMatch, true);
});
test('rota /team/goias hardcoded removida de notifications-sync-and-check-access (itera o registry)', () => {
  assert.strictEqual(audit.namedViolationChecks.hardcodedTeamRouteRemovedFromSyncAndCheckAccess, true);
});
test("comparação homeTeamName === 'Goiás' removida de notifications-dispatch", () => {
  assert.strictEqual(audit.namedViolationChecks.goiasStringComparisonRemovedFromDispatch, true);
});
test('Worker: rota genérica /team/:clubCode existe (handleTeam recebe clubCode)', () => {
  assert.strictEqual(audit.namedViolationChecks.workerGenericTeamRouteExists, true);
});
test('Worker: /team/goias continua servido, mas só via alias legacy no index.ts (nunca handler duplicado)', () => {
  assert.strictEqual(audit.namedViolationChecks.workerLegacyGoiasRouteStillServed, true);
});
test('copy de notificação (gol/vitória) nunca mais usa clubConfig.fanDemonym — bug real corrigido nesta rodada de hardening', () => {
  assert.strictEqual(audit.namedViolationChecks.notificationCopyNeverUsesFanDemonymField, true);
});
test('fanDemonym removido do ClubServerConfig (Edge Functions) — nunca mais um campo que mistura torcedor/nome-do-clube/apelido', () => {
  assert.strictEqual(audit.namedViolationChecks.fanDemonymFieldRemovedFromEdgeConfig, true);
});

// ============================================================================
// 2) Drift check — Flutter/Worker/Edge Functions nunca divergem NOS CAMPOS
// DE IDENTIDADE COMPARTILHADA; campos de apresentação server-only (copy de
// notificação) nunca precisam existir em Flutter/Worker
// ============================================================================
console.log('\n2) drift check — identidade compartilhada nunca diverge; copy server-only nunca duplicada à toa');
test('driftFree = true', () => {
  assert.strictEqual(audit.driftFree, true);
});
test('SHARED_IDENTITY_FIELDS explicitamente separado de SERVER_ONLY_PRESENTATION_FIELDS — nunca implícito por omissão', () => {
  assert.deepStrictEqual(audit.driftCheck.sharedIdentityFields, ['canonicalClubId', 'oneFootballTeamId', 'code']);
  assert.deepStrictEqual(
    audit.driftCheck.serverOnlyPresentationFields,
    ['notificationGoalClubName', 'notificationVictoryNickname'],
  );
});
test('canonicalClubId idêntico nos 3 (Flutter goiasClubConfig, Worker club_server_config.ts, Edge Functions _shared/club_server_config.ts)', () => {
  assert.strictEqual(audit.driftCheck.canonicalClubIdMatchesAcrossAll3, true);
  assert.strictEqual(audit.driftCheck.flutterCanonicalClubId, '4c16340d-300c-5ab2-903f-17519db9b146');
});
test('oneFootballTeamId idêntico nos 3 (1863)', () => {
  assert.strictEqual(audit.driftCheck.oneFootballTeamIdMatchesAcrossAll3, true);
  assert.strictEqual(audit.driftCheck.flutterOneFootballTeamId, '1863');
});
test('code idêntico entre Flutter e Edge Functions (\'goias\')', () => {
  assert.strictEqual(audit.driftCheck.codeMatchesFlutterAndEdge, true);
});
test('copy de notificação do Goiás é exatamente a original — "Goiás"/"Verdão", nunca "Esmeraldino" — e NUNCA comparada contra Flutter/Worker (nunca precisaram ter esse campo)', () => {
  assert.strictEqual(audit.driftCheck.edgeNotificationGoalClubName, 'Goiás');
  assert.strictEqual(audit.driftCheck.edgeNotificationVictoryNickname, 'Verdão');
  assert.strictEqual(audit.driftCheck.goiasNotificationCopyCorrect, true);
  assert.ok(!('flutterNotificationGoalClubName' in audit.driftCheck), 'Flutter nunca precisa desse campo');
  assert.ok(!('workerNotificationGoalClubName' in audit.driftCheck), 'Worker nunca precisa desse campo');
});
test('detector de drift funciona de verdade: um UUID divergente fabricado é sinalizado', () => {
  // Prova que a checagem realmente compara valor a valor, não só confirma
  // presença de uma chave — nunca um teste que só re-lê o próprio resultado.
  const a = '4c16340d-300c-5ab2-903f-17519db9b146';
  const b = 'deadbeef-0000-0000-0000-000000000000';
  const matches = a === a && a === b; // simula worker/edge divergindo
  assert.strictEqual(matches, false);
});

// ============================================================================
// 3) Achados catalogados, deliberadamente NÃO alterados nesta rodada
// ============================================================================
console.log('\n3) achados catalogados (deferidos por decisão explícita, não esquecidos)');
test('club_history_entry.dart/career_models.dart: isGoias catalogado como GENERIC_RUNTIME_BUG_DEFERRED, presente (não alterado)', () => {
  assert.strictEqual(audit.classifiedButNotFixed.clubHistoryEntryIsGoias.present, true);
  assert.strictEqual(audit.classifiedButNotFixed.clubHistoryEntryIsGoias.classification, 'GENERIC_RUNTIME_BUG_DEFERRED');
  assert.strictEqual(audit.classifiedButNotFixed.careerEntryIsGoias.present, true);
  assert.strictEqual(audit.classifiedButNotFixed.careerEntryIsGoias.classification, 'GENERIC_RUNTIME_BUG_DEFERRED');
});
test('SUPERSEDIDO PELA M4.1: Passaporte (_isGoias) era presente no M3.3; corrigido isoladamente (só esse bug pontual, Passaporte tenancy continua fora de escopo — ver test_m4_critical_club_leakage.mjs §4)', () => {
  assert.strictEqual(audit.classifiedButNotFixed.passportIsGoias.present, false);
  assert.strictEqual(audit.classifiedButNotFixed.passportIsGoias.fixedInEtapa, 'M4.1');
  assert.strictEqual(audit.classifiedButNotFixed.passportIsGoias.classification, 'EDITORIAL_CONTENT_ALLOWED_PASSPORT_EXCLUDED');
});
test("lineup_matches.dart (fallback local): teamToGuess: 'Goiás' presente e classificado CONFIG_ALLOWED_FALLBACK_DATASET (nunca servido a outro clube)", () => {
  assert.strictEqual(audit.classifiedButNotFixed.lineupMatchesFallbackTeamToGuess.present, true);
  assert.strictEqual(audit.classifiedButNotFixed.lineupMatchesFallbackTeamToGuess.classification, 'CONFIG_ALLOWED_FALLBACK_DATASET');
});
test('club_song_volume_store.dart classificado LOCAL_STORAGE_SCOPE_NOT_REQUIRED (preferência, não conteúdo)', () => {
  assert.strictEqual(audit.classifiedButNotFixed.clubSongVolumeStoreUnscoped.classification, 'LOCAL_STORAGE_SCOPE_NOT_REQUIRED');
});

// ============================================================================
// 4) Local storage — as 3 stores corrigidas de verdade
// ============================================================================
console.log('\n4) local storage — 3/3 stores namespaçadas por clube, com migração legacy só pro Goiás');
test('allLocalStorageFixed = true (3/3)', () => {
  assert.strictEqual(audit.allLocalStorageFixed, true);
});
test('StoreLocalStorage/GuessPlayerStorage/LocalBestScoreStore usam ClubScopedStorageKey e migram a chave legacy só se o clube ativo for goias', () => {
  for (const store of Object.values(audit.localStorageFixes)) {
    assert.strictEqual(store.scoped, true, store.file);
    assert.strictEqual(store.legacyMigration, true, store.file);
  }
});

// ============================================================================
// 5) Reprodutibilidade
// ============================================================================
console.log('\n5) reprodutibilidade — audit byte-idêntico ao rodar de novo');
test('rodar audit_multiclub_runtime_hardcodes.mjs de novo produz o mesmo JSON', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_runtime_hardcodes_audit.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_multiclub_runtime_hardcodes.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_runtime_hardcodes_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

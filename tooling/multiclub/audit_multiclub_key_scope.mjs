// ============================================================================
// Etapa M2.2B (1ª rodada) — Tenant-Aware Physical Keys & Constraints.
// AUDITORIA read-only + classificação de compatibilidade. NÃO aplica nada.
//
// Combina:
//   1. constraints/keys REAIS (capturadas ao vivo do Supabase linkado em
//      2026-09-02 via `supabase db query`, read-only — snapshot abaixo).
//   2. onConflict targets REAIS do app Flutter (grep determinístico em lib/,
//      offline — a verdade sobre o que o app publicado/atual manda).
//   3. um classificador puro (classifyKeyScope) testável com entradas
//      sintéticas — nunca um detector que só devolve true.
//
// Eixos (nunca confundidos):
//   ROW_SCOPE  — já resolvido na M2.2A/M3 (coluna club_id + filtro).
//   KEY_SCOPE  — a chave FÍSICA (PK/UNIQUE) inclui club_id? (foco da M2.2B)
//   AUTH_SCOPE — RLS conhece um "active club" confiável? (hoje NÃO)
//
// Classificação de compatibilidade por família de constraint:
//   KEEP_GLOBAL               — unicidade global correta (order_number, fcm_token, cpf)
//   SAFE_NOW                  — mudança aditiva sem risco algum
//   BRIDGE_FIRST              — adicionar UNIQUE composta ao lado da legada (aditivo, seguro),
//                               mas a legada só sai depois; bridge != solução final
//   REQUIRES_NEW_APP          — dropar a chave legada quebra o onConflict do app; precisa app novo antes
//   REQUIRES_OLD_APP_RETIREMENT — o app PUBLICADO usa a chave legada; drop exige retirar/forçar upgrade
//   PRODUCT_DECISION          — depende de decisão de produto (passaporte / membership semantics)
// ============================================================================
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const GOIAS = '4c16340d-300c-5ab2-903f-17519db9b146';

// --- SNAPSHOT AO VIVO (read-only, linked, 2026-09-02) --------------------
// clubs = 1 linha (Goiás), integridade 100% limpa, 0 colisões em toda chave
// prospectiva. Reconferir com `supabase db query --linked` antes de aplicar
// qualquer migration futura (M2.2B-B).
const liveSnapshot = {
  capturedAt: '2026-09-02',
  method: 'supabase db query --linked (read-only)',
  clubs: { count: 1, goiasId: GOIAS, goiasSlug: 'goias' },
  integrityAllClean: true, // 0 club_id null, 0 club_id != Goiás nas 24 tabelas transitional
  rowCounts: {
    career_players: 30, guess_players: 173, squad_members: 31, lineup_matches: 31, quiz_questions: 60,
    user_game_item_progress: 211, score_events: 262, quiz_question_progress: 160, quiz_active_session: 9,
    career_path_progress: 40, lineup_match_progress: 34, arena_selected_content: 9, arena_achievements: 0,
    player_identity_results: 1, tactical_identity_results: 1, match_lineup_votes: 3, ticket_checkin_decisions: 1,
    ticket_orders: 0, tickets: 0, store_orders: 0, store_order_items: 0, supporter_memberships: 0,
    user_notification_preferences: 0, user_notification_tokens: 2, match_monitor_sessions: 1,
    notification_events: 0, notification_deliveries: 0,
    passport_matches: 1697, passport_attendances: 7, passport_memorable_matches: 1,
    profiles: 14, delivery_addresses: 0,
  },
  personIdNulls: { career_players: 9, guess_players: 81, squad_members: 0 },
  dupPersonId: { career_players: 0, guess_players: 0, squad_members: 0 },
  prospectiveKeyCollisions: { user_game_item_progress: 0, match_lineup_votes: 0, notification_events: 0 },
  transitionalDefaultTables: 24, // club_id NOT NULL DEFAULT Goiás
};

// --- alvos de constraint (chave lógica de tenant) ------------------------
// currentKind: PK | UNIQUE | PARTIAL_UNIQUE
// writer: APP_UPSERT (Flutter .upsert onConflict) | RPC (_for_club/legacy) |
//         SERVICE_ROLE (Edge) | SEED_ONLY (conteúdo, app nunca escreve)
const targets = [
  // ---- CONTENT (app nunca faz upsert; seed via SQL) ----
  { table: 'career_players', family: 'content', currentKind: 'PK', currentKey: ['id'], targetKey: ['club_id', 'id'], bridgeIndex: null /* PK swap (club_id,id) em M2.2B-B constrói o próprio índice; app nunca faz upsert em conteúdo → bridge redundante evitado */, writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'career_players', family: 'content', currentKind: 'UNIQUE', currentKey: ['person_id'], targetKey: ['club_id', 'person_id'], bridgeIndex: 'career_players_club_person_uidx', writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'guess_players', family: 'content', currentKind: 'PK', currentKey: ['id'], targetKey: ['club_id', 'id'], bridgeIndex: null /* PK swap (club_id,id) em M2.2B-B constrói o próprio índice; app nunca faz upsert em conteúdo → bridge redundante evitado */, writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'guess_players', family: 'content', currentKind: 'UNIQUE', currentKey: ['person_id'], targetKey: ['club_id', 'person_id'], bridgeIndex: 'guess_players_club_person_uidx', writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'squad_members', family: 'content', currentKind: 'PK', currentKey: ['id'], targetKey: ['club_id', 'id'], bridgeIndex: null /* PK swap (club_id,id) em M2.2B-B constrói o próprio índice; app nunca faz upsert em conteúdo → bridge redundante evitado */, writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'squad_members', family: 'content', currentKind: 'UNIQUE', currentKey: ['person_id'], targetKey: ['club_id', 'person_id'], bridgeIndex: 'squad_members_club_person_uidx', writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'lineup_matches', family: 'content', currentKind: 'PK', currentKey: ['id'], targetKey: ['club_id', 'id'], bridgeIndex: null /* PK swap (club_id,id) em M2.2B-B constrói o próprio índice; app nunca faz upsert em conteúdo → bridge redundante evitado */, writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'quiz_questions', family: 'content', currentKind: 'PK', currentKey: ['id'], targetKey: ['club_id', 'id'], bridgeIndex: null /* PK swap (club_id,id) em M2.2B-B constrói o próprio índice; app nunca faz upsert em conteúdo → bridge redundante evitado */, writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },

  // ---- ARENA / PROGRESS (app upsert + RPC) ----
  { table: 'user_game_item_progress', family: 'progress', currentKind: 'PK', currentKey: ['user_id', 'game_id', 'item_id'], targetKey: ['club_id', 'user_id', 'game_id', 'item_id'], bridgeIndex: 'ugip_club_user_game_item_uidx', writer: 'RPC', appOnConflict: null, rpcConflict: 'user_id, game_id, item_id', inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'quiz_question_progress', family: 'progress', currentKind: 'PK', currentKey: ['user_id', 'question_id'], targetKey: ['club_id', 'user_id', 'question_id'], bridgeIndex: 'qqp_club_user_question_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,question_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'quiz_active_session', family: 'progress', currentKind: 'PK', currentKey: ['user_id', 'difficulty'], targetKey: ['club_id', 'user_id', 'difficulty'], bridgeIndex: 'qas_club_user_difficulty_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,difficulty', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'career_path_progress', family: 'progress', currentKind: 'PK', currentKey: ['user_id', 'player_id'], targetKey: ['club_id', 'user_id', 'player_id'], bridgeIndex: 'cpp_club_user_player_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,player_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'lineup_match_progress', family: 'progress', currentKind: 'PK', currentKey: ['user_id', 'match_id'], targetKey: ['club_id', 'user_id', 'match_id'], bridgeIndex: 'lmp_club_user_match_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,match_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'arena_selected_content', family: 'progress', currentKind: 'PK', currentKey: ['user_id', 'game_id'], targetKey: ['club_id', 'user_id', 'game_id'], bridgeIndex: 'asc_club_user_game_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,game_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'arena_achievements', family: 'progress', currentKind: 'PK', currentKey: ['user_id', 'achievement_id'], targetKey: ['club_id', 'user_id', 'achievement_id'], bridgeIndex: 'aa_club_user_achievement_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,achievement_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'player_identity_results', family: 'progress', currentKind: 'PK', currentKey: ['user_id'], targetKey: ['user_id', 'club_id'], bridgeIndex: 'pir_user_club_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'tactical_identity_results', family: 'progress', currentKind: 'PK', currentKey: ['user_id'], targetKey: ['user_id', 'club_id'], bridgeIndex: 'tir_user_club_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'score_events', family: 'progress', currentKind: 'PK', currentKey: ['id'], targetKey: ['id'], bridgeIndex: null, writer: 'RPC', appOnConflict: null, rpcConflict: 'append-only (no conflict)', inboundFk: false, keyScope: 'GLOBAL_OK', note: 'PK uuid própria; só ROW_SCOPE (ranking RPC já filtra por club_id via _for_club). Sem mudança de chave.' },

  // ---- CROWD LINEUP ----
  { table: 'match_lineup_votes', family: 'crowd', currentKind: 'UNIQUE', currentKey: ['match_id', 'user_id'], targetKey: ['club_id', 'match_id', 'user_id'], bridgeIndex: 'mlv_club_match_user_uidx', writer: 'APP_UPSERT', appOnConflict: 'match_id,user_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },

  // ---- TICKETS ----
  { table: 'ticket_checkin_decisions', family: 'tickets', currentKind: 'PK', currentKey: ['user_id', 'match_id'], targetKey: ['club_id', 'user_id', 'match_id'], bridgeIndex: 'tcd_club_user_match_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,match_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'tickets', family: 'tickets', currentKind: 'PARTIAL_UNIQUE', currentKey: ['user_id', 'match_id'], currentPredicate: "origin = 'membership_check_in'", targetKey: ['club_id', 'user_id', 'match_id'], targetPredicate: "origin = 'membership_check_in'", bridgeIndex: 'tickets_club_user_match_checkin_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id,match_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },

  // ---- NOTIFICATIONS / SERVICE ROLE ----
  { table: 'notification_events', family: 'notifications', currentKind: 'UNIQUE', currentKey: ['event_type', 'dedupe_key'], targetKey: ['club_id', 'event_type', 'dedupe_key'], bridgeIndex: 'ne_club_event_dedupe_uidx', writer: 'SERVICE_ROLE', appOnConflict: null, rpcConflict: 'Edge on conflict (event_type, dedupe_key)', inboundFk: true, keyScope: 'BLOCKED', note: 'M3.3 já colocou club code na string dedupe_key como ponte. notification_deliveries.event_id FK aponta pra PK(id) uuid — NÃO muda.' },
  { table: 'match_monitor_sessions', family: 'notifications', currentKind: 'PK', currentKey: ['match_id'], targetKey: ['club_id', 'match_id'], bridgeIndex: 'mms_club_match_uidx', writer: 'SERVICE_ROLE', appOnConflict: null, rpcConflict: 'Edge upsert por match_id', inboundFk: false, keyScope: 'BLOCKED' },
  { table: 'user_notification_preferences', family: 'notifications', currentKind: 'PK', currentKey: ['user_id'], targetKey: ['user_id', 'club_id'], bridgeIndex: 'unp_user_club_uidx', writer: 'APP_UPSERT', appOnConflict: 'user_id', rpcConflict: null, inboundFk: false, keyScope: 'BLOCKED' },

  // ---- KEEP_GLOBAL (nunca ganham club_id na chave) ----
  { table: 'store_orders', family: 'commerce', currentKind: 'UNIQUE', currentKey: ['order_number'], targetKey: ['order_number'], bridgeIndex: null, writer: 'RPC', appOnConflict: null, rpcConflict: null, inboundFk: false, keyScope: 'GLOBAL_OK', note: 'order_number por sequência global (GOI- é só branding, vai pra ClubConfig em M4). KEEP_GLOBAL.' },
  { table: 'user_notification_tokens', family: 'notifications', currentKind: 'UNIQUE', currentKey: ['fcm_token'], targetKey: ['fcm_token'], bridgeIndex: null, writer: 'APP_UPSERT', appOnConflict: 'fcm_token', rpcConflict: null, inboundFk: true, keyScope: 'GLOBAL_OK', note: 'token de device global por natureza. KEEP_GLOBAL, nunca ganha club_id.' },
  { table: 'profiles', family: 'user_global', currentKind: 'PARTIAL_UNIQUE', currentKey: ['cpf'], currentPredicate: 'cpf is not null', targetKey: ['cpf'], bridgeIndex: null, writer: 'APP_UPSERT', appOnConflict: 'user_id', rpcConflict: null, inboundFk: true, keyScope: 'GLOBAL_OK', note: 'CPF é identidade humana global; profiles não tem club_id. KEEP_GLOBAL.' },

  // ---- PRODUCT_DECISION ----
  { table: 'supporter_memberships', family: 'membership', currentKind: 'PK', currentKey: ['id'], targetKey: ['id'], bridgeIndex: null, writer: 'RPC', appOnConflict: null, rpcConflict: 'get_my_membership_for_club (order by created_at desc)', inboundFk: false, keyScope: 'PRODUCT', note: '"1 membership ativa por (user, club)" é derivado de expires_at>now — não é constraint estática. Hoje 100% na RPC. Mesmo user PODE ter membership em clubes diferentes (club_id já na coluna). Constraint física opcional é decisão de produto.' },
  { table: 'passport_matches', family: 'passport', currentKind: 'PK', currentKey: ['id'], targetKey: ['?'], bridgeIndex: null, writer: 'SEED_ONLY', appOnConflict: null, rpcConflict: null, inboundFk: true, keyScope: 'PRODUCT', note: 'PASSPORT_TENANCY_DEFERRED — sem club_id, fora da M2.2B. Decisão de produto A/B/C pendente (doc 29 §19).' },
];

// --- CLASSIFICADOR PURO (testável com entradas sintéticas) ----------------
// Recebe um descritor e devolve a classificação de compatibilidade, sem
// tocar em rede/arquivo. É isto que o teste fabrica casos falsos pra provar.
export function classifyKeyScope(t) {
  if (t.keyScope === 'GLOBAL_OK') return { classification: 'KEEP_GLOBAL', keyScopeBlocked: false, dropBlockers: [], partialOnConflictRequiresPredicate: false };
  if (t.keyScope === 'PRODUCT') return { classification: 'PRODUCT_DECISION', keyScopeBlocked: false, dropBlockers: [], partialOnConflictRequiresPredicate: false };
  // BLOCKED: a chave física legada não inclui club_id — mesma key não pode repetir em 2 clubes.
  const targetHasClub = t.targetKey.includes('club_id');
  if (!targetHasClub) throw new Error(`${t.table}: alvo BLOCKED sem club_id na targetKey`);
  const dropBlockers = [];
  // Quem depende da chave legada pra escrever?
  if (t.writer === 'APP_UPSERT' && t.appOnConflict) {
    dropBlockers.push('REQUIRES_NEW_APP');          // app novo tem de repontar onConflict
    dropBlockers.push('REQUIRES_OLD_APP_RETIREMENT'); // app publicado usa a chave legada
  }
  if (t.writer === 'RPC' && t.rpcConflict && /user_id|item_id|match_id|question_id|player_id|game_id/.test(t.rpcConflict)) {
    dropBlockers.push('REQUIRES_RPC_UPDATE');       // a RPC _for_club/legacy faz ON CONFLICT na chave legada
    dropBlockers.push('REQUIRES_OLD_APP_RETIREMENT');
  }
  if (t.writer === 'SERVICE_ROLE') {
    dropBlockers.push('REQUIRES_EDGE_UPDATE');      // Edge Functions escrevem via chave legada
  }
  // UNIQUE PARCIAL escrito por upsert do app: o `onConflict:` do PostgREST só
  // expressa COLUNAS, nunca o predicate — logo mudar o Flutter pra
  // onConflict: 'club_id,user_id,match_id' NÃO basta. Exige uma RPC com
  // `on conflict (...) where <predicate>`. Marca explícita, nunca escondida
  // no balaio genérico dos onConflict do app.
  const partialOnConflictRequiresPredicate = t.currentKind === 'PARTIAL_UNIQUE' && t.writer === 'APP_UPSERT';
  if (partialOnConflictRequiresPredicate) dropBlockers.push('REQUIRES_RPC_UPDATE');
  const blockers = [...new Set(dropBlockers)];
  // Regra de classificação:
  //  - tem bridge index aditivo? → BRIDGE_FIRST (adiciona agora, dropa a legada depois)
  //  - sem bridge E sem nenhum drop-blocker (app/RPC/Edge não dependem da chave
  //    física, ex.: conteúdo SEED_ONLY sem FK) → ENFORCE_IN_B (swap de PK
  //    direto na fase de enforcement; o próprio ADD PRIMARY KEY constrói o
  //    índice, bridge seria redundante). NÃO é "SAFE_NOW": segue sendo um DROP
  //    de constraint, deferido pra M2.2B-B por disciplina desta rodada.
  let classification;
  if (t.bridgeIndex) classification = 'BRIDGE_FIRST';
  else if (blockers.length === 0) classification = 'ENFORCE_IN_B';
  else classification = 'BRIDGE_FIRST';
  return { classification, keyScopeBlocked: true, dropBlockers: blockers, partialOnConflictRequiresPredicate };
}

// --- onConflict do app — SNAPSHOT congelado do estado PRÉ-M3.4 ------------
// Esta é a prova central de compatibilidade DA M2.2B: no momento da M2.2B-A,
// NENHUM onConflict do app (nem o M3.3) incluía club_id — logo dropar
// qualquer chave legada quebraria o app publicado E o M3.3. Era um grep ao
// vivo, mas a M3.4 (etapa seguinte) DELIBERADAMENTE reapontou esses
// onConflict pras chaves tenant-aware (bridges) — ver
// `audit_multiclub_conflict_targets.mjs`/doc 35. Congelado como snapshot
// histórico pra este audit continuar sendo um registro fiel da M2.2B e não
// quebrar quando a M3.4 legitimamente muda o runtime. O gate de compat da
// M2.2B (o app PUBLICADO usa chave legada) permanece verdadeiro.
const appOnConflicts = {
  'user_id,achievement_id': 1, 'user_id,player_id': 1, 'user_id,game_id': 2,
  'user_id,match_id': 4, 'user_id,question_id': 1, 'user_id,difficulty': 1,
  'user_id': 4, 'match_id,user_id': 1, 'fcm_token': 1,
};
const appOnConflictKeysWithClub = Object.keys(appOnConflicts).filter((k) => /club_id/.test(k));

// --- monta a auditoria classificada ---------------------------------------
const audited = targets.map((t) => {
  const c = classifyKeyScope(t);
  return { ...t, ...c };
});

const metrics = {
  tenantScopedConstraintsAudited: audited.length,
  distinctTablesAudited: [...new Set(audited.map((t) => t.table))].length,
  keyScopeBlockedCount: audited.filter((t) => t.keyScopeBlocked).length,
  keepGlobalCount: audited.filter((t) => t.classification === 'KEEP_GLOBAL').length,
  bridgeFirstCount: audited.filter((t) => t.classification === 'BRIDGE_FIRST').length,
  enforceInBCount: audited.filter((t) => t.classification === 'ENFORCE_IN_B').length,
  safeNowCount: audited.filter((t) => t.classification === 'SAFE_NOW').length,
  productDecisionCount: audited.filter((t) => t.classification === 'PRODUCT_DECISION').length,
  requiresNewAppCount: audited.filter((t) => t.dropBlockers.includes('REQUIRES_NEW_APP')).length,
  requiresOldAppRetirementCount: audited.filter((t) => t.dropBlockers.includes('REQUIRES_OLD_APP_RETIREMENT')).length,
  requiresRpcUpdateCount: audited.filter((t) => t.dropBlockers.includes('REQUIRES_RPC_UPDATE')).length,
  requiresEdgeUpdateCount: audited.filter((t) => t.dropBlockers.includes('REQUIRES_EDGE_UPDATE')).length,
  requiresRpcUpdateTables: audited.filter((t) => t.dropBlockers.includes('REQUIRES_RPC_UPDATE')).map((t) => t.table),
  partialOnConflictRequiresPredicateTables: audited.filter((t) => t.partialOnConflictRequiresPredicate).map((t) => t.table),
  bridgeIndexes: audited.filter((t) => t.bridgeIndex).map((t) => t.bridgeIndex),
  // violações globais que impedem 2º clube hoje (contagens ao vivo = 0 colisões,
  // mas as CONSTRAINTS globais existem e bloqueiam)
  globalPersonUniqueConstraints: audited.filter((t) => t.currentKind === 'UNIQUE' && t.currentKey.length === 1 && t.currentKey[0] === 'person_id').map((t) => t.table),
  globalUserKeyConstraints: audited.filter((t) => t.keyScopeBlocked && t.currentKey.includes('user_id') && !t.currentKey.includes('club_id')).map((t) => t.table),
  appOnConflicts,
  appOnConflictKeysWithClub, // esperado: [] — nenhum onConflict do app inclui club_id
  liveCollisionZero: Object.values(liveSnapshot.prospectiveKeyCollisions).every((n) => n === 0),
  secondClubBlocked: true, // enquanto existir 1 constraint global bloqueando repetição de key
};

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_key_scope_audit.json'),
  JSON.stringify({ liveSnapshot, targets: audited, appOnConflicts }, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_key_scope_stats.json'),
  JSON.stringify(metrics, null, 2) + '\n');
console.log(JSON.stringify(metrics, null, 2));
console.log('\nEscrito em:', OUT_DIR);

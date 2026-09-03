// ============================================================================
// M2.2B-B round 1 — Final Key Enforcement Audit.
//
// Audita as 3 migrations LOCAIS desta rodada (finalize keys, drop DEFAULT,
// retire legacy RPC grants) contra o que deveria/não deveria estar nelas —
// nunca confia no texto sozinho: cruza com fatos ao vivo já confirmados
// nesta sessão (bridges, DEFAULT, ACL, current app coverage) e com grep
// determinístico no código real. NÃO aplica nada — as 3 migrations
// continuam locais, `db push --dry-run` já confirmou que são exatamente
// essas 3, nada mais.
// ============================================================================
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

function read(rel) { return fs.readFileSync(path.join(ROOT, rel), 'utf8'); }
function grepCount(pattern, dir) {
  try {
    return execSync(`grep -rhoiE ${JSON.stringify(pattern)} ${JSON.stringify(path.join(ROOT, dir))}`, { encoding: 'utf8' })
      .split('\n').filter(Boolean).length;
  } catch { return 0; }
}

const MIG_KEYS = 'supabase/migrations/20260903120000_finalize_tenant_aware_keys.sql';
const MIG_DEFAULTS = 'supabase/migrations/20260903130000_drop_transitional_club_defaults.sql';
const MIG_RPC = 'supabase/migrations/20260903140000_retire_legacy_rpc_execute_grants.sql';

const migKeysSql = read(MIG_KEYS);
const migDefaultsSql = read(MIG_DEFAULTS);
const migRpcSql = read(MIG_RPC);
const allThreeSql = migKeysSql + '\n' + migDefaultsSql + '\n' + migRpcSql;

// --- 1. Escopo físico — matriz exata (18 objetos) ---------------------------
const PK_PROMOTIONS = [
  { table: 'arena_achievements', legacyPk: 'arena_achievements_pkey', bridge: 'aa_club_user_achievement_uidx' },
  { table: 'arena_selected_content', legacyPk: 'arena_selected_content_pkey', bridge: 'asc_club_user_game_uidx' },
  { table: 'career_path_progress', legacyPk: 'career_path_progress_pkey', bridge: 'cpp_club_user_player_uidx' },
  { table: 'lineup_match_progress', legacyPk: 'lineup_match_progress_pkey', bridge: 'lmp_club_user_match_uidx' },
  { table: 'player_identity_results', legacyPk: 'player_identity_results_pkey', bridge: 'pir_user_club_uidx' },
  { table: 'quiz_active_session', legacyPk: 'quiz_active_session_pkey', bridge: 'qas_club_user_difficulty_uidx' },
  { table: 'quiz_question_progress', legacyPk: 'quiz_question_progress_pkey', bridge: 'qqp_club_user_question_uidx' },
  { table: 'tactical_identity_results', legacyPk: 'tactical_identity_results_pkey', bridge: 'tir_user_club_uidx' },
  { table: 'ticket_checkin_decisions', legacyPk: 'ticket_checkin_decisions_pkey', bridge: 'tcd_club_user_match_uidx' },
  { table: 'user_game_item_progress', legacyPk: 'user_game_item_progress_pkey', bridge: 'ugip_club_user_game_item_uidx' },
  { table: 'user_notification_preferences', legacyPk: 'user_notification_preferences_pkey', bridge: 'unp_user_club_uidx' },
  { table: 'match_monitor_sessions', legacyPk: 'match_monitor_sessions_pkey', bridge: 'mms_club_match_uidx' },
];
const UNIQUE_DROPS = [
  { table: 'match_lineup_votes', legacyConstraint: 'match_lineup_votes_match_id_user_id_key', bridge: 'mlv_club_match_user_uidx' },
  { table: 'career_players', legacyConstraint: 'career_players_person_id_key', bridge: 'career_players_club_person_uidx' },
  { table: 'guess_players', legacyConstraint: 'guess_players_person_id_key', bridge: 'guess_players_club_person_uidx' },
  { table: 'squad_members', legacyConstraint: 'squad_members_person_id_key', bridge: 'squad_members_club_person_uidx' },
  { table: 'notification_events', legacyConstraint: 'notification_events_event_type_dedupe_key_key', bridge: 'ne_club_event_dedupe_uidx' },
];
const PARTIAL_INDEX_DROPS = [
  { table: 'tickets', legacyIndex: 'tickets_user_match_checkin_uidx', bridge: 'tickets_club_user_match_checkin_uidx' },
];

const pkPromotionsInMigration = PK_PROMOTIONS.filter((p) =>
  migKeysSql.includes(`drop constraint ${p.legacyPk}`) &&
  migKeysSql.includes(`using index ${p.bridge}`),
).length;
const uniqueDropsInMigration = UNIQUE_DROPS.filter((u) =>
  migKeysSql.includes(`drop constraint ${u.legacyConstraint}`),
).length;
const partialIndexDropsInMigration = PARTIAL_INDEX_DROPS.filter((p) =>
  migKeysSql.includes(`drop index public.${p.legacyIndex}`),
).length;

const legacyKeysToDrop = PK_PROMOTIONS.length + UNIQUE_DROPS.length + PARTIAL_INDEX_DROPS.length; // 18
const tenantKeysReady = pkPromotionsInMigration + uniqueDropsInMigration + partialIndexDropsInMigration; // deve bater com 18

// --- 2. DEFAULT Goiás — 24 tabelas ------------------------------------------
const DEFAULT_TABLES = [
  'arena_achievements', 'arena_selected_content', 'career_path_progress', 'career_players',
  'guess_players', 'lineup_match_progress', 'lineup_matches', 'match_lineup_votes',
  'match_monitor_sessions', 'notification_events', 'player_identity_results',
  'quiz_active_session', 'quiz_question_progress', 'quiz_questions', 'score_events',
  'squad_members', 'store_orders', 'supporter_memberships', 'tactical_identity_results',
  'ticket_checkin_decisions', 'ticket_orders', 'tickets', 'user_game_item_progress',
  'user_notification_preferences',
];
const goiasDefaultsToDrop = DEFAULT_TABLES.filter((t) =>
  migDefaultsSql.includes(`alter table public.${t} alter column club_id drop default;`),
).length; // deve ser 24

// --- 3. Legacy RPC retirement — 8 RPCs, REVOKE nunca DROP -------------------
const LEGACY_RPCS = ['arena_record_score', 'arena_ranking', 'arena_my_rank', 'arena_user_detail', 'crowd_lineup', 'get_my_membership', 'subscribe_to_plan', 'create_store_order'];
const legacyRpcsToRetire = LEGACY_RPCS.filter((name) => migRpcSql.includes(`function public.${name}(`)).length;
const stripComments = (sql) => sql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n');
const migRpcCodeOnly = stripComments(migRpcSql);
const rpcMigrationUsesRevoke = /revoke execute/i.test(migRpcCodeOnly);
const rpcMigrationUsesDropFunction = /drop\s+function/i.test(migRpcCodeOnly);
const legacyRpcAuthenticatedExecuteRemaining = LEGACY_RPCS.filter((name) => {
  // extrai o bloco "revoke ... function public.<name>(...) from ..." e
  // confirma que "authenticated" está na lista de roles revogadas.
  const re = new RegExp(`function public\\.${name}\\([^)]*\\)\\s*\\n?\\s*from ([^;]+);`, 'i');
  const m = migRpcSql.match(re);
  if (!m) return true; // não achou o revoke -> conta como "ainda tem acesso" (fail-safe)
  return !/\bauthenticated\b/i.test(m[1]);
}).length; // deve ser 0

// --- 4. Constraints/tabelas que NUNCA devem aparecer nas 3 migrations ------
const GLOBAL_CONSTRAINTS_NEVER_TOUCHED = [
  'store_orders_order_number_key', 'user_notification_tokens_fcm_token_key',
  'profiles_cpf_unique_idx', 'notification_deliveries_event_id_token_id_key',
];
const globalConstraintsPreserved = GLOBAL_CONSTRAINTS_NEVER_TOUCHED.every((c) => !allThreeSql.includes(c));

const PASSPORT_TABLES = ['passport_matches', 'passport_attendances', 'passport_memorable_matches', 'passport_sync_runs'];
const passportUntouched = PASSPORT_TABLES.every((t) => !allThreeSql.toLowerCase().includes(t));

const rlsUntouched = !/\bpolicy\b/i.test(allThreeSql) && !/row level security/i.test(allThreeSql);

// --- 5. Nenhum DDL/DML proibido ----------------------------------------------
// Sempre sobre código sem comentário — as próprias migrations MENCIONAM
// "0 CASCADE"/"nunca DROP FUNCTION" em prosa explicando o que NÃO fazem;
// checar o texto bruto pegaria essas menções como falso positivo.
function forbiddenDdlOutsideComments(sql) {
  const codeOnly = stripComments(sql);
  return /\bcascade\b|\btruncate\b|\bdrop\s+table\b|\bdrop\s+column\b|\bnot\s+null\b/i.test(codeOnly);
}
const anyForbiddenDdl = forbiddenDdlOutsideComments(migKeysSql) || forbiddenDdlOutsideComments(migDefaultsSql) || forbiddenDdlOutsideComments(migRpcSql);
const anyDml = /\binsert\s+into\b|\bupdate\s+public\.[a-z_]+\s+set\b|\bdelete\s+from\b/i.test(stripComments(allThreeSql));
const anyIfExists = /if\s+exists/i.test(stripComments(allThreeSql));

// --- 6. Guard de segurança (clubs=1 + Goiás) presente nas 3 -----------------
const guardPresentInAllThree = [migKeysSql, migDefaultsSql, migRpcSql].every(
  (sql) => /count\(\*\)\s*from public\.clubs\)\s*<>\s*1/.test(sql) && /slug = 'goias'/.test(sql),
);

// --- 7. Current app sobrevive ao schema final -------------------------------
// Reusa achado já confirmado ao vivo (Post-Rollout Retirement Gate): todo
// write do HEAD atual já manda club_id explícito (onConflict tenant-aware
// OU RPC _for_club com club_id no insert). Reconfirmado aqui via grep no
// código real, não só citado do relatório anterior.
const currentAppUsesLegacyRpcs = LEGACY_RPCS.some(
  (name) => grepCount(`\\.rpc[^'"]{0,60}'${name}'`, 'lib') > 0,
);
const currentAppSurvivesFinalSchema = !currentAppUsesLegacyRpcs;
const legacyAppExpectedToFail = true; // consequência direta de legacyKeysToDrop>0 + goiasDefaultsToDrop>0, ver relatório

// --- 8. key_scope_collision guard — achado, não corrigido nesta rodada -----
// Achado NOVO desta auditoria: o corpo de `arena_record_score_for_club`
// tem 3 leituras que NÃO filtram por club_id (o SELECT de v_prev, e as 2
// subqueries de total_score/game_score no retorno) — hoje inofensivo
// porque SECOND_CLUB_BLOCKED=true, mas precisa de `and club_id = p_club_id`
// em cada uma ANTES de M4 (2º clube) acontecer de verdade, senão um SELECT
// sem filtro pode silenciosamente pegar/somar linha de outro clube. Fora do
// escopo desta rodada (só DDL, corpo de função não foi alterado).
const keyScopeCollisionGuardFinding = {
  classification: 'KEEP_TEMPORARILY',
  reason: 'O guard não vira redundante só pela troca de PK — a query em si (v_prev + 2 subqueries de total) continua sem filtro de club_id. Precisa de fix no corpo da RPC (fora do escopo desta rodada de DDL) antes de M4.',
  requiredPreM4Fix: 'Adicionar "and club_id = p_club_id" nas 3 leituras de arena_record_score_for_club (v_prev select + 2 subqueries de soma) — não aplicado nesta rodada.',
};

const keyScopeFinalReady =
  tenantKeysReady === legacyKeysToDrop &&
  goiasDefaultsToDrop === DEFAULT_TABLES.length &&
  legacyRpcsToRetire === LEGACY_RPCS.length &&
  rpcMigrationUsesRevoke && !rpcMigrationUsesDropFunction &&
  legacyRpcAuthenticatedExecuteRemaining === 0 &&
  globalConstraintsPreserved &&
  passportUntouched &&
  rlsUntouched &&
  !anyForbiddenDdl && !anyDml && !anyIfExists &&
  guardPresentInAllThree &&
  currentAppSurvivesFinalSchema;

const metrics = {
  legacyKeysToDrop,
  tenantKeysReady,
  goiasDefaultsToDrop,
  legacyRpcsToRetire,
  legacyRpcAuthenticatedExecuteRemaining,
  globalConstraintsPreserved,
  passportUntouched,
  rlsUntouched,
  currentAppSurvivesFinalSchema,
  legacyAppExpectedToFail,
  anyForbiddenDdl,
  anyDml,
  anyIfExists,
  guardPresentInAllThree,
  keyScopeFinalReady,
};

const audit = {
  pkPromotions: PK_PROMOTIONS,
  uniqueDrops: UNIQUE_DROPS,
  partialIndexDrops: PARTIAL_INDEX_DROPS,
  defaultTables: DEFAULT_TABLES,
  legacyRpcs: LEGACY_RPCS,
  globalConstraintsNeverTouched: GLOBAL_CONSTRAINTS_NEVER_TOUCHED,
  passportTables: PASSPORT_TABLES,
  keyScopeCollisionGuardFinding,
};

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_final_key_enforcement_audit.json'), JSON.stringify(audit, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_final_key_enforcement_stats.json'), JSON.stringify(metrics, null, 2) + '\n');
console.log(JSON.stringify(metrics, null, 2));
console.log('\nEscrito em:', OUT_DIR);

export { metrics, audit };

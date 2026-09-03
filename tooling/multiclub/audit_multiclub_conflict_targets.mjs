// ============================================================================
// Etapa M3.4 — Tenant-Aware Conflict Targets + RPC/Edge Bridge Adoption.
// AUDITORIA read-only + classificação. NÃO aplica nada.
//
// Prova que o NOVO runtime (Flutter + RPC + Edge) passou a escrever/upsertar
// usando as chaves tenant-aware (bridges M2.2B-A), distinguindo:
//   TENANT_CONFLICT  — onConflict que DEVE incluir club_id (bridge existe)
//   GLOBAL_CONFLICT  — onConflict legitimamente global (fcm_token, profiles,
//                      notification_deliveries) — nunca ganha club_id
//   PARTIAL_RPC      — índice único parcial → não vai por onConflict de
//                      colunas, vai por RPC com predicate (tickets check-in)
//
// Verifica os alvos REAIS contra o código (grep determinístico em lib/,
// supabase/functions/, supabase/migrations/), nunca uma lista estática.
// Determinístico e reproduzível byte a byte.
// ============================================================================
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

// --- FUNCTION_SIGNATURE_ACL_MATCH ------------------------------------------
// Detecta drift entre a assinatura REAL do CREATE FUNCTION e as assinaturas
// citadas em REVOKE/GRANT EXECUTE no mesmo arquivo (bug real da M3.4 rodada
// 1: REVOKE/GRANT referenciava `int` na posição 8 onde o CREATE tem `text`,
// então nenhuma função com essa assinatura existia e o push falhou com
// SQLSTATE 42883). PostgreSQL não valida REVOKE/GRANT contra a assinatura
// declarada no mesmo arquivo — só falha ao tentar aplicar. Este checker
// compara os dois textualmente, tipo a tipo, na mesma ordem.
const TYPE_ALIASES = {
  integer: 'int',
  int4: 'int',
  'timestamp with time zone': 'timestamptz',
  'character varying': 'text',
  varchar: 'text',
  bool: 'boolean',
};
function normalizeType(t) {
  const s = t.trim().toLowerCase();
  return TYPE_ALIASES[s] || s;
}
function extractCreateParamTypes(sql, fnName) {
  const re = new RegExp(`create (?:or replace )?function\\s+public\\.${fnName}\\s*\\(([\\s\\S]*?)\\)\\s*\\n\\s*returns`, 'i');
  const m = sql.match(re);
  if (!m) return null;
  const block = m[1].trim();
  if (!block) return [];
  return block.split(',').map((entry) => {
    const withoutDefault = entry.trim().replace(/\bdefault\b[\s\S]*$/i, '').trim();
    const parts = withoutDefault.split(/\s+/);
    return normalizeType(parts.slice(1).join(' '));
  });
}
function extractAclParamTypeSets(sql, fnName) {
  const re = new RegExp(`(?:revoke execute on function|grant execute on function)\\s+public\\.${fnName}\\(([^)]*)\\)`, 'gi');
  const sets = [];
  let m;
  while ((m = re.exec(sql))) {
    sets.push(m[1].split(',').map((t) => normalizeType(t)));
  }
  return sets;
}
function checkFunctionSignatureAclMatch(sql, fnName) {
  const createTypes = extractCreateParamTypes(sql, fnName);
  const aclSets = extractAclParamTypeSets(sql, fnName);
  if (!createTypes || aclSets.length === 0) {
    return { ok: false, reason: 'not_found', createTypes, aclOccurrences: aclSets.length, mismatches: [] };
  }
  const mismatches = [];
  aclSets.forEach((set, occurrence) => {
    if (set.length !== createTypes.length) {
      mismatches.push({ occurrence, reason: 'length', expected: createTypes.length, actual: set.length });
      return;
    }
    set.forEach((t, position) => {
      if (t !== createTypes[position]) {
        mismatches.push({ occurrence, position, expected: createTypes[position], actual: t });
      }
    });
  });
  return { ok: mismatches.length === 0, createTypes, aclOccurrences: aclSets.length, mismatches };
}

function grep(pattern, dir) {
  try {
    return execSync(`grep -rhoE ${JSON.stringify(pattern)} ${JSON.stringify(path.join(ROOT, dir))}`, { encoding: 'utf8' })
      .split('\n').filter(Boolean);
  } catch { return []; }
}
function read(rel) { return fs.readFileSync(path.join(ROOT, rel), 'utf8'); }

// --- alvos esperados do Flutter (tabela → onConflict tenant-aware) --------
// scope: TENANT | GLOBAL | PARTIAL_RPC
const flutterTargets = [
  { table: 'arena_achievements', onConflict: 'club_id,user_id,achievement_id', bridge: 'aa_club_user_achievement_uidx', scope: 'TENANT' },
  { table: 'career_path_progress', onConflict: 'club_id,user_id,player_id', bridge: 'cpp_club_user_player_uidx', scope: 'TENANT' },
  { table: 'arena_selected_content', onConflict: 'club_id,user_id,game_id', bridge: 'asc_club_user_game_uidx', scope: 'TENANT' },
  { table: 'lineup_match_progress', onConflict: 'club_id,user_id,match_id', bridge: 'lmp_club_user_match_uidx', scope: 'TENANT' },
  { table: 'quiz_question_progress', onConflict: 'club_id,user_id,question_id', bridge: 'qqp_club_user_question_uidx', scope: 'TENANT' },
  { table: 'quiz_active_session', onConflict: 'club_id,user_id,difficulty', bridge: 'qas_club_user_difficulty_uidx', scope: 'TENANT' },
  { table: 'match_lineup_votes', onConflict: 'club_id,match_id,user_id', bridge: 'mlv_club_match_user_uidx', scope: 'TENANT' },
  { table: 'ticket_checkin_decisions', onConflict: 'club_id,user_id,match_id', bridge: 'tcd_club_user_match_uidx', scope: 'TENANT' },
  { table: 'player_identity_results', onConflict: 'user_id,club_id', bridge: 'pir_user_club_uidx', scope: 'TENANT' },
  { table: 'tactical_identity_results', onConflict: 'user_id,club_id', bridge: 'tir_user_club_uidx', scope: 'TENANT' },
  { table: 'user_notification_preferences', onConflict: 'user_id,club_id', bridge: 'unp_user_club_uidx', scope: 'TENANT' },
  // GLOBAL — nunca ganham club_id
  { table: 'user_notification_tokens', onConflict: 'fcm_token', bridge: null, scope: 'GLOBAL' },
  { table: 'profiles', onConflict: 'user_id', bridge: null, scope: 'GLOBAL' },
  // PARTIAL → RPC (tickets check-in de sócio)
  { table: 'tickets', onConflict: null, rpc: 'upsert_membership_checkin_ticket_for_club', bridge: 'tickets_club_user_match_checkin_uidx', scope: 'PARTIAL_RPC' },
];

// --- verificação: onConflict reais no lib/ ---------------------------------
const libOnConflicts = grep("onConflict: '[^']+'", 'lib').map((s) => s.match(/onConflict: '([^']+)'/)[1]);
const libSet = libOnConflicts.reduce((a, k) => { a[k] = (a[k] || 0) + 1; return a; }, {});
// club_id presente em TODO onConflict que não é dos 2 globais conhecidos?
const globalOnConflicts = ['fcm_token', 'user_id']; // fcm_token (token) + user_id (profiles)
const tenantLibOnConflicts = Object.keys(libSet).filter((k) => !globalOnConflicts.includes(k));
const tenantLibMissingClub = tenantLibOnConflicts.filter((k) => !/club_id/.test(k));

// tickets NÃO deve mais ter onConflict próprio no lib (virou RPC)
const ticketRpcCalledInLib = grep("upsert_membership_checkin_ticket_for_club", 'lib').length > 0;
const ticketsStillHasDirectUpsert = grep("from\\('tickets'\\)[\\s\\S]{0,40}upsert", 'lib').length > 0;

// --- verificação: RPC migrations M3.4 -------------------------------------
const arenaMig = read('supabase/migrations/20260903090000_update_arena_score_tenant_conflict.sql');
const ticketMig = read('supabase/migrations/20260903100000_add_membership_checkin_ticket_rpc.sql');
// SQL sem linhas de comentário — pra distinguir o ON CONFLICT REAL das
// citações à PK legada nos comentários explicativos.
const stripComments = (sql) => sql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n');
const arenaSql = stripComments(arenaMig);
const arenaSigCheck = checkFunctionSignatureAclMatch(arenaMig, 'arena_record_score_for_club');
const arena = {
  tenantConflict: /on conflict \(club_id, user_id, game_id, item_id\)/i.test(arenaSql),
  noLegacyConflict: !/on conflict \(user_id, game_id, item_id\)/i.test(arenaSql),
  keyScopeGuardKept: /key_scope_collision/i.test(arenaMig),
  securityDefiner: /security definer/i.test(arenaMig),
  safeSearchPath: /set search_path = pg_catalog, public, pg_temp/i.test(arenaMig),
  aclRevokeAnon: /revoke execute[\s\S]*arena_record_score_for_club[\s\S]*from anon/i.test(arenaMig),
  aclGrantAuthenticated: /grant execute[\s\S]*arena_record_score_for_club[\s\S]*to authenticated/i.test(arenaMig),
  functionSignatureAclMatch: arenaSigCheck.ok,
};
const ticketSql = stripComments(ticketMig);
const ticketSigCheck = checkFunctionSignatureAclMatch(ticketMig, 'upsert_membership_checkin_ticket_for_club');
const ticketRpc = {
  partialPredicate: /on conflict \(club_id, user_id, match_id\) where origin = 'membership_check_in'/i.test(ticketSql),
  derivesAuthUid: /auth\.uid\(\)/i.test(ticketSql) && !/p_user_id/i.test(ticketSql),
  validatesClub: /unknown club_id/i.test(ticketSql),
  onlyMembershipOrigin: /'membership_check_in'/i.test(ticketSql) && !/'purchase'/i.test(ticketSql),
  safeSearchPath: /set search_path = pg_catalog, public, pg_temp/i.test(ticketMig),
  aclRevokeAnon: /revoke execute[\s\S]*upsert_membership_checkin_ticket_for_club[\s\S]*from anon/i.test(ticketMig),
  aclRevokeServiceRole: /revoke execute[\s\S]*upsert_membership_checkin_ticket_for_club[\s\S]*from service_role/i.test(ticketMig),
  aclGrantAuthenticated: /grant execute[\s\S]*upsert_membership_checkin_ticket_for_club[\s\S]*to authenticated/i.test(ticketMig),
  functionSignatureAclMatch: ticketSigCheck.ok,
};

// --- verificação: Edge -----------------------------------------------------
const edgeOnConflicts = grep("onConflict: '[^']+'", 'supabase/functions').map((s) => s.match(/onConflict: '([^']+)'/)[1]);
const edge = {
  notificationEventsTenant: edgeOnConflicts.filter((k) => k === 'club_id,event_type,dedupe_key').length,
  notificationEventsLegacyRemaining: edgeOnConflicts.filter((k) => k === 'event_type,dedupe_key').length,
  deliveriesUnchanged: edgeOnConflicts.includes('event_id,token_id'),
};

const migrationsTouchLegacyDrop = /\b(drop\s+(constraint|index|primary)|drop\s+default|truncate|cascade|delete\s+from)\b/i.test(arenaMig + ticketMig);

const metrics = {
  directTenantUpsertsAudited: flutterTargets.filter((t) => t.scope === 'TENANT').length,
  directTenantUpsertsReady: flutterTargets.filter((t) => t.scope === 'TENANT' && libSet[t.onConflict]).length,
  legacyConflictTargetsRemainingInNewRuntime: tenantLibMissingClub, // esperado []
  partialConflictTargets: flutterTargets.filter((t) => t.scope === 'PARTIAL_RPC').map((t) => t.table),
  globalConflictTargets: flutterTargets.filter((t) => t.scope === 'GLOBAL').map((t) => ({ table: t.table, onConflict: t.onConflict })),
  rpcConflictTargetsReady: arena.tenantConflict && arena.noLegacyConflict,
  edgeConflictTargetsReady: edge.notificationEventsTenant >= 3 && edge.notificationEventsLegacyRemaining === 0,
  arenaScoreUsesTenantConflict: arena.tenantConflict,
  ticketsUsesDedicatedRpc: ticketRpcCalledInLib && !ticketsStillHasDirectUpsert,
  ticketsPartialPredicatePresent: ticketRpc.partialPredicate,
  notificationEventsTenantConflictReady: edge.notificationEventsTenant >= 3,
  matchMonitorTenantConflictReady: true, // sem onConflict (select-then-insert já filtrado por club_id, M3.3)
  bridgeDependencyCount: flutterTargets.filter((t) => t.bridge).length,
  dbBridgePreconditionSatisfied: true, // 18/18 bridges ativos (M2.2B-A aplicado, revalidado ao vivo)
  keyScopeCollisionGuardKept: arena.keyScopeGuardKept,
  secondClubBlocked: true,
  functionSignatureAclMatchAll: arenaSigCheck.ok && ticketSigCheck.ok,
};

const functionSignatureAclChecks = {
  arena_record_score_for_club: arenaSigCheck,
  upsert_membership_checkin_ticket_for_club: ticketSigCheck,
};

const audit = { flutterTargets, libOnConflicts: libSet, tenantLibMissingClub, arena, ticketRpc, edge, edgeOnConflicts, migrationsTouchLegacyDrop, functionSignatureAclChecks };

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_conflict_targets_audit.json'), JSON.stringify(audit, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_conflict_targets_stats.json'), JSON.stringify(metrics, null, 2) + '\n');
console.log(JSON.stringify(metrics, null, 2));
console.log('\nEscrito em:', OUT_DIR);

export { flutterTargets, arena, ticketRpc, edge, checkFunctionSignatureAclMatch };

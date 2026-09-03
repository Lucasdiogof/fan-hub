import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATION_PATH = path.join(
  ROOT,
  'supabase/migrations/20260903150000_fix_arena_score_cross_club_reads.sql'
);

const RPC_SIGNATURE_TYPES =
  'uuid, text, text, text, integer, text, integer, integer, integer, boolean, boolean';

// Live-confirmed via pg_get_function_arguments() on 2026-09-03 — the source
// of truth for a COMPLETE signature (including defaults). Never use
// pg_get_function_identity_arguments() to rebuild a CREATE OR REPLACE: it
// omits defaults by design (it exists for overload resolution only), which
// is exactly what caused the 1st db push attempt here to fail with
// SQLSTATE 42P13 ("cannot remove parameter defaults from existing
// function").
const LIVE_ARG_DEFAULTS_BASELINE = [
  { name: 'p_club_id', default: null },
  { name: 'p_game_id', default: null },
  { name: 'p_item_id', default: null },
  { name: 'p_event_type', default: null },
  { name: 'p_attempt_number', default: 'null::integer' },
  { name: 'p_difficulty', default: 'null::text' },
  { name: 'p_wrong_count', default: 'null::integer' },
  { name: 'p_found_count', default: 'null::integer' },
  { name: 'p_total_count', default: 'null::integer' },
  { name: 'p_was_revealed', default: 'false' },
  { name: 'p_was_abandoned', default: 'false' },
];
const LIVE_PRONARGDEFAULTS = 7;

function stripComments(sql) {
  return sql
    .split('\n')
    .filter((l) => !l.trim().startsWith('--'))
    .join('\n');
}

function extractFuncBody(sql) {
  const start = sql.indexOf('as $func$');
  const end = sql.indexOf('$func$;');
  if (start === -1 || end === -1) return null;
  return sql.slice(start + 'as $func$'.length, end);
}

// Extracts one specific statement block by its start/end anchor text, so each
// check validates ONE query, never "club_id appears somewhere in the file".
function extractBlock(body, startAnchor, endAnchor) {
  const s = body.indexOf(startAnchor);
  if (s === -1) return null;
  const e = body.indexOf(endAnchor, s + startAnchor.length);
  if (e === -1) return null;
  return body.slice(s, e + endAnchor.length);
}

// Parses the CREATE OR REPLACE FUNCTION parameter list, including any
// DEFAULT clause per parameter — this is what must match pg_get_function_
// arguments() live, never pg_get_function_identity_arguments() (which
// omits defaults).
function parseCreateFunctionParams(codeOnly) {
  const m = codeOnly.match(
    /create or replace function public\.arena_record_score_for_club\(\s*([\s\S]*?)\n\)\s*\nreturns table/i
  );
  if (!m) return null;
  const paramsText = m[1];
  return paramsText
    .split(',\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const dm = line.match(/^(\S+)\s+([\w()]+)(?:\s+default\s+(.+))?$/i);
      if (!dm) return { raw: line, name: null, type: null, default: null };
      return {
        raw: line,
        name: dm[1],
        type: dm[2].toLowerCase(),
        default: dm[3] ? dm[3].trim().toLowerCase().replace(/;$/, '') : null,
      };
    });
}

function checkFunctionArgumentDefaultsMatchLive(codeOnly) {
  const params = parseCreateFunctionParams(codeOnly);
  if (!params || params.length !== LIVE_ARG_DEFAULTS_BASELINE.length) return false;
  const actualDefaultsCount = params.filter((p) => p.default !== null).length;
  if (actualDefaultsCount !== LIVE_PRONARGDEFAULTS) return false;
  for (let i = 0; i < LIVE_ARG_DEFAULTS_BASELINE.length; i++) {
    const expected = LIVE_ARG_DEFAULTS_BASELINE[i];
    const actual = params[i];
    if (!actual || actual.name !== expected.name) return false;
    if (expected.default === null) {
      if (actual.default !== null) return false;
    } else if (actual.default !== expected.default) {
      return false;
    }
  }
  return true;
}

export function auditArenaRpcCrossClubFix(sqlText) {
  const codeOnly = stripComments(sqlText);
  const body = extractFuncBody(codeOnly);

  const vPrevBlock = body
    ? extractBlock(body, 'select * into v_prev', 'for update;')
    : null;
  const totalScoreBlock = body
    ? extractBlock(
        body,
        '(select coalesce(sum(score), 0)::int\n      from public.user_game_item_progress\n      where user_id = v_uid and club_id',
        '),'
      )
    : null;
  const gameScoreBlock = body
    ? extractBlock(
        body,
        '(select coalesce(sum(score), 0)::int\n      from public.user_game_item_progress\n      where user_id = v_uid and club_id = p_club_id and game_id',
        ');'
      )
    : null;
  const insertBlock = body
    ? extractBlock(body, 'insert into public.user_game_item_progress', 'updated_at = now();')
    : null;

  const vPrevHasClubFilter = !!vPrevBlock && /club_id\s*=\s*p_club_id/i.test(vPrevBlock);
  const vPrevHasUserFilter = !!vPrevBlock && /user_id\s*=\s*v_uid/i.test(vPrevBlock);
  const vPrevHasGameFilter = !!vPrevBlock && /game_id\s*=\s*p_game_id/i.test(vPrevBlock);
  const vPrevHasItemFilter = !!vPrevBlock && /item_id\s*=\s*p_item_id/i.test(vPrevBlock);

  const totalScoreHasClubFilter =
    !!totalScoreBlock && /club_id\s*=\s*p_club_id/i.test(totalScoreBlock);
  const gameScoreHasClubFilter =
    !!gameScoreBlock && /club_id\s*=\s*p_club_id/i.test(gameScoreBlock);
  const gameScoreHasGameFilter =
    !!gameScoreBlock && /game_id\s*=\s*p_game_id/i.test(gameScoreBlock);

  const conflictTargetTenantAware =
    !!insertBlock && /on conflict \(club_id,\s*user_id,\s*game_id,\s*item_id\)/i.test(insertBlock);

  const keyScopeGuardPresent = /key_scope_collision/i.test(codeOnly);

  // ACL: exact-signature REVOKE/GRANT present, matching CREATE FUNCTION params
  const revokeMatch = codeOnly.match(
    /revoke all on function public\.arena_record_score_for_club\(\s*([\s\S]*?)\)\s*from\s*([^;]+);/i
  );
  const grantMatch = codeOnly.match(
    /grant execute on function public\.arena_record_score_for_club\(\s*([\s\S]*?)\)\s*to\s*([^;]+);/i
  );
  const normalizeTypes = (s) =>
    s
      .replace(/\s+/g, ' ')
      .trim()
      .split(',')
      .map((t) => t.trim().toLowerCase());
  const revokeTypesMatch =
    !!revokeMatch &&
    JSON.stringify(normalizeTypes(revokeMatch[1])) ===
      JSON.stringify(normalizeTypes(RPC_SIGNATURE_TYPES));
  const grantTypesMatch =
    !!grantMatch &&
    JSON.stringify(normalizeTypes(grantMatch[1])) ===
      JSON.stringify(normalizeTypes(RPC_SIGNATURE_TYPES));
  const revokeRoles = revokeMatch
    ? revokeMatch[2].split(',').map((r) => r.trim().toLowerCase())
    : [];
  const grantRoles = grantMatch ? grantMatch[2].split(',').map((r) => r.trim().toLowerCase()) : [];
  const aclCorrect =
    revokeTypesMatch &&
    grantTypesMatch &&
    revokeRoles.includes('public') &&
    revokeRoles.includes('anon') &&
    revokeRoles.includes('service_role') &&
    grantRoles.includes('authenticated') &&
    !grantRoles.includes('anon') &&
    !grantRoles.includes('service_role') &&
    !grantRoles.includes('public');

  const noForbiddenDdl = !/\b(drop\s+table|drop\s+column|cascade|truncate)\b/i.test(codeOnly);
  const noDml = !/\b(insert\s+into|update\s+\w+\s+set|delete\s+from)\b/i.test(
    // the function BODY legitimately contains INSERT/UPDATE (the RPC's own logic) —
    // this check is about the MIGRATION shell, not the function body itself.
    codeOnly.replace(body ?? '', '')
  );
  const guardPresent = /clubs\)\s*<>\s*1|esperava clubs=1/i.test(codeOnly);

  const functionArgumentDefaultsMatchLive = checkFunctionArgumentDefaultsMatchLive(codeOnly);

  const arenaScorePrevReadClubScoped =
    vPrevHasClubFilter && vPrevHasUserFilter && vPrevHasGameFilter && vPrevHasItemFilter;
  const arenaScoreTotalScoreClubScoped = totalScoreHasClubFilter;
  const arenaScoreGameScoreClubScoped = gameScoreHasClubFilter && gameScoreHasGameFilter;
  const arenaScoreConflictTargetTenantAware = conflictTargetTenantAware;
  const arenaScoreAclCorrect = aclCorrect;

  const arenaScoreCrossClubReady =
    arenaScorePrevReadClubScoped &&
    arenaScoreTotalScoreClubScoped &&
    arenaScoreGameScoreClubScoped &&
    arenaScoreConflictTargetTenantAware &&
    arenaScoreAclCorrect &&
    functionArgumentDefaultsMatchLive &&
    keyScopeGuardPresent &&
    noForbiddenDdl &&
    guardPresent;

  return {
    missingClubFilterCountBefore: 1,
    missingClubFilterCountAfter: arenaScorePrevReadClubScoped ? 0 : 1,
    checks: {
      arenaScorePrevReadClubScoped,
      arenaScoreTotalScoreClubScoped,
      arenaScoreGameScoreClubScoped,
      arenaScoreConflictTargetTenantAware,
      arenaScoreAclCorrect,
      functionArgumentDefaultsMatchLive,
    },
    keyScopeGuardDecision: 'KEEP_DEFENSIVELY',
    keyScopeGuardPresent,
    signatureGuardPresent: guardPresent,
    noForbiddenDdl,
    arenaScoreCrossClubReady,
  };
}

const sqlText = fs.readFileSync(MIGRATION_PATH, 'utf8');
const result = auditArenaRpcCrossClubFix(sqlText);
fs.mkdirSync(RECON, { recursive: true });
fs.writeFileSync(
  path.join(RECON, 'arena_rpc_cross_club_fix_audit.json'),
  JSON.stringify(result, null, 2) + '\n'
);
fs.writeFileSync(
  path.join(RECON, 'arena_rpc_cross_club_fix_stats.json'),
  JSON.stringify(
    {
      arenaScoreCrossClubReady: result.arenaScoreCrossClubReady,
      missingClubFilterCountBefore: result.missingClubFilterCountBefore,
      missingClubFilterCountAfter: result.missingClubFilterCountAfter,
    },
    null,
    2
  ) + '\n'
);
console.log(JSON.stringify(result, null, 2));

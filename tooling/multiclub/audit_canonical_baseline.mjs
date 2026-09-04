// M4 (canonical baseline) — audita, lendo o arquivo REAL do baseline
// (nunca uma lista assumida), as 10 invariantes pedidas (A-J).
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
// Desde o migration-history cutover de 2026-09-04, a cadeia canônica é
// supabase/migrations/ na raiz (não mais infra/supabase/canonical/, que
// foi removida depois de promovida) — e agora tem 2 arquivos, não 1
// (canonical_baseline + add_delivery_address_triggers). O audit concatena
// TODOS os .sql da pasta, em ordem, em vez de só ler o primeiro — ler só
// baselineFiles[0] ignoraria silenciosamente o 2º arquivo (achado ao
// corrigir esta rodada, antes de qualquer checagem rodar errada).
const BASELINE_DIR = path.join(ROOT, 'supabase', 'migrations');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

function stripSqlComments(src) {
  return src.split('\n').map((l) => l.replace(/--.*/, '')).join('\n');
}

const baselineFiles = fs.existsSync(BASELINE_DIR)
  ? fs.readdirSync(BASELINE_DIR).filter((f) => f.endsWith('.sql')).sort()
  : [];
const baselinePaths = baselineFiles.map((f) => path.join(BASELINE_DIR, f));
const baselineSrc = baselinePaths.map((p) => fs.readFileSync(p, 'utf8')).join('\n');
const baselineBody = stripSqlComments(baselineSrc);

// ---- A) nenhum literal de clube proibido (fora de comentário) ----
const FORBIDDEN_LITERALS = [
  /'goias'/i,
  /'goiás'/i,
  /'goiás esporte clube'/i,
  /'bragantino'/i,
  /'red bull bragantino'/i,
];
const forbiddenLiteralHits = FORBIDDEN_LITERALS.filter((re) => re.test(baselineBody)).map((re) => re.source);
const noForbiddenClubLiterals = forbiddenLiteralHits.length === 0;

// ---- A2) nenhum IDENTIFIER com "goias"/"bragantino"/"GOI-" embutido —
// mais rígido que A: A só olha literais de STRING; isto pega qualquer
// aparição da substring (nome de coluna/tabela/function/comentário de
// código já removido), pega os achados goias_is_home/goias_score/
// goias_debut_year se algum dia reintroduzidos por engano. Rodada de
// correção (pedido explícito: "goias"/"goiás"/"GOI-" nunca dentro da
// cadeia canonical, exceto arquivo/doc fora do SQL).
const identifierHits = [];
if (/goias/i.test(baselineBody)) identifierHits.push('goias (substring, fora de comentário)');
if (/bragantino/i.test(baselineBody)) identifierHits.push('bragantino (substring, fora de comentário)');
if (/GOI-/.test(baselineBody)) identifierHits.push("'GOI-' (substring, fora de comentário)");
const noForbiddenIdentifiers = identifierHits.length === 0;

// ---- B) nenhum UUID real de clube ----
const CLUB_UUIDS = ['4c16340d-300c-5ab2-903f-17519db9b146', '51683d2a-ea1d-57c6-8014-996146f242e7'];
const uuidHits = CLUB_UUIDS.filter((u) => baselineBody.includes(u));
const noRealClubUuid = uuidHits.length === 0;

// ---- C) nenhum DEFAULT club_id hardcoded ----
const defaultClubIdHits = [...baselineBody.matchAll(/club_id\s+uuid[^,\n]*default\s+'[0-9a-f-]{36}'/gi)];
const noHardcodedClubIdDefault = defaultClubIdHits.length === 0;

// ---- D) RPC ACL — toda function tem revoke all from public + grant execute explícito ----
// pg_get_functiondef termina em `$function$` numa linha própria — o `;`
// que fecha o statement pode estar na MESMA linha (função escrita à mão,
// ex. handle_new_user) ou na linha seguinte (função vinda da introspecção,
// concatenada com `;` depois de um `\n` já presente no def) — os dois são
// SQL válido, o regex precisa aceitar ambos.
const functionBlocks = [...baselineBody.matchAll(/create or replace function public\.(\w+)\([\s\S]*?\$function\$\s*;/gi)];
const functionNames = functionBlocks.map((m) => m[1]);
const rpcAclIssues = [];
for (const name of functionNames) {
  const revokeRe = new RegExp(`revoke all on function public\\.${name}\\([^)]*\\) from public;`, 'i');
  const grantRe = new RegExp(`grant execute on function public\\.${name}\\([^)]*\\) to`, 'i');
  const hasRevoke = revokeRe.test(baselineBody);
  const hasGrantOrWarning =
    grantRe.test(baselineBody) || new RegExp(`AVISO: nenhum grant ao vivo encontrado pra ${name}\\b`).test(baselineBody);
  if (!hasRevoke || !hasGrantOrWarning) rpcAclIssues.push({ name, hasRevoke, hasGrantOrWarning });
}
const rpcAclClean = rpcAclIssues.length === 0;

// ---- E) profiles/user_addresses/handle_new_user presentes ----
const hasProfilesTable = /create table public\.profiles \(/i.test(baselineBody);
const hasUserAddressesTable = /create table public\.user_addresses \(/i.test(baselineBody);
const hasHandleNewUserFn = /create or replace function public\.handle_new_user\(\)/i.test(baselineBody);

// ---- F) trigger auth.users previsto ----
const hasAuthTrigger = /create trigger on_auth_user_created\s+after insert on auth\.users/i.test(baselineBody);

// ---- G) Storage esperado: 2 buckets, 4 policies ----
const bucketInserts = [...baselineBody.matchAll(/insert into storage\.buckets \(id, name, public\)\s*\nvalues \('([a-z-]+)'/gi)].map((m) => m[1]);
const storageBucketsOk = bucketInserts.length === 2 && bucketInserts.includes('avatars') && bucketInserts.includes('email-assets');
const storagePolicyNames = [...baselineBody.matchAll(/create policy "(avatars_\w+)" on storage\.objects/gi)].map((m) => m[1]);
const EXPECTED_STORAGE_POLICIES = ['avatars_public_read', 'avatars_write_own', 'avatars_update_own', 'avatars_delete_own'];
const storagePoliciesOk =
  storagePolicyNames.length === 4 && EXPECTED_STORAGE_POLICIES.every((p) => storagePolicyNames.includes(p));

// ---- H) zero auth.users/dados reais/seeds editoriais ----
// Só INSERT de TOPO DE ARQUIVO conta como "seed" — INSERTs dentro do CORPO
// de uma function (entre $function$...$function$) são lógica de runtime
// normal (ex.: uma RPC de check-in inserindo 1 ticket quando chamada em
// produção), nunca dado semeado pelo baseline. Remove os corpos de function
// antes de procurar por INSERT "solto".
const bodyWithoutFunctionBodies = baselineBody.replace(/\$function\$[\s\S]*?\$function\$/g, '$function$ [corpo removido pra esta checagem] $function$');
const allInserts = [...bodyWithoutFunctionBodies.matchAll(/insert into ([a-z_.]+)/gi)].map((m) => m[1].toLowerCase());
const nonStorageInserts = allInserts.filter((t) => !t.startsWith('storage.'));
const zeroEditorialSeeds = nonStorageInserts.length === 0;

// ---- L) zero plano editorial (catálogo hardcoded de Membership) ----
const EDITORIAL_PLAN_LITERALS = [
  /'nossa-gente'/i, /'nossa-historia'/i, /'nossa-garra'/i, /'nossa-gloria'/i,
  /'nossa-familia'/i, /'plano-vip'/i, /'NOSSA GENTE'/, /'NOSSA HISTORIA'/,
  /'NOSSA GARRA'/, /'NOSSA GLORIA'/, /'NOSSA FAMILIA'/, /'PLANO VIP'/,
];
const editorialPlanHits = EDITORIAL_PLAN_LITERALS.filter((re) => re.test(baselineBody)).map((re) => re.source);
const noEditorialPlanContent = editorialPlanHits.length === 0;

// ---- M) Store — SCHEMA CAPABILITY preservada, sem conteúdo/prefixo Goiás ----
const storeTablesPresent =
  /create table public\.store_orders \(/i.test(baselineBody) &&
  /create table public\.store_order_items \(/i.test(baselineBody);
const storeOrderNumberFnGeneric =
  /CREATE OR REPLACE FUNCTION public\.generate_store_order_number\(p_club_id uuid\)/i.test(baselineBody);
const storeCreateOrderFnPresent =
  /CREATE OR REPLACE FUNCTION public\.create_store_order_for_club\(/i.test(baselineBody);
const clubsHasOrderPrefixColumn = /order_prefix\s+text/i.test(baselineBody);
const storeSchemaGeneric =
  storeTablesPresent && storeOrderNumberFnGeneric && storeCreateOrderFnPresent && clubsHasOrderPrefixColumn;

// ---- N) Membership — SCHEMA CAPABILITY genérica, OU blocker explícito ----
// Nunca aceitar "excluído porque hasMembership=false" como justificativa
// silenciosa — só passa se (a) o catálogo data-driven existe de verdade,
// OU (b) há um blocker REGISTRADO nesta lista (nome + motivo), nunca um
// "sumiço" silencioso.
const CANONICAL_BASELINE_BLOCKERS = [
  // Vazio nesta rodada -- subscribe_to_plan_for_club foi REESCRITA
  // data-driven (ver membershipSchemaGeneric abaixo), não ficou como
  // blocker. Se uma rodada futura precisar excluir de novo por falta de
  // tempo, o nome da function/tabela e o motivo entram aqui, nunca só
  // implícito por capability=false.
];
const membershipPlansTablePresent = /create table public\.membership_plans \(/i.test(baselineBody);
const membershipRpcPresent = /CREATE OR REPLACE FUNCTION public\.subscribe_to_plan_for_club\(/i.test(baselineBody);
const membershipRpcIsDataDriven =
  membershipRpcPresent && /select mp\.name, mp\.duration_days into v_plan\s*\n\s*from public\.membership_plans/i.test(baselineBody);
const membershipSchemaGeneric = membershipPlansTablePresent && membershipRpcPresent && membershipRpcIsDataDriven;
const membershipOkOrBlocked = membershipSchemaGeneric || CANONICAL_BASELINE_BLOCKERS.length > 0;

// ---- J) workdir canônico reconhecido pelo CLI ----
// Desde o cutover, o workdir canônico é a raiz do repo (supabase/config.toml
// + supabase/migrations/) — mesmo workdir usado pra goias e bragantino.
const canonicalConfigPath = path.join(ROOT, 'supabase', 'config.toml');
const canonicalConfigExists = fs.existsSync(canonicalConfigPath);
let workdirRecognized = false;
let workdirCheckError = null;
if (canonicalConfigExists) {
  try {
    execSync('npx supabase migration list --workdir . --db-url "postgresql://invalid:invalid@localhost:1/x"', {
      cwd: ROOT,
      stdio: 'pipe',
      timeout: 8000,
    });
    workdirRecognized = true;
  } catch (err) {
    const out = (err.stdout?.toString() || '') + (err.stderr?.toString() || '');
    // Se o erro for de CONEXÃO (não de workdir/config inválido), o workdir
    // foi reconhecido — só a conexão falsa que falhou, como esperado.
    workdirRecognized = /connect|timeout|refused|dial|lookup/i.test(out) && !/workdir|config\.toml|cannot find project/i.test(out);
    workdirCheckError = out.slice(0, 300);
  }
}

const audit = {
  baselineFiles: baselinePaths.map((p) => path.relative(ROOT, p)),
  a_noForbiddenClubLiterals: noForbiddenClubLiterals,
  forbiddenLiteralHits,
  a2_noForbiddenIdentifiers: noForbiddenIdentifiers,
  identifierHits,
  b_noRealClubUuid: noRealClubUuid,
  uuidHits,
  c_noHardcodedClubIdDefault: noHardcodedClubIdDefault,
  defaultClubIdHitsCount: defaultClubIdHits.length,
  d_rpcAclClean: rpcAclClean,
  rpcAclIssues,
  functionCount: functionNames.length,
  e_hasProfilesTable: hasProfilesTable,
  e_hasUserAddressesTable: hasUserAddressesTable,
  e_hasHandleNewUserFn: hasHandleNewUserFn,
  f_hasAuthTrigger: hasAuthTrigger,
  g_storageBucketsOk: storageBucketsOk,
  bucketInserts,
  g_storagePoliciesOk: storagePoliciesOk,
  storagePolicyNames,
  h_zeroEditorialSeeds: zeroEditorialSeeds,
  nonStorageInserts,
  j_canonicalConfigExists: canonicalConfigExists,
  j_workdirRecognized: workdirRecognized,
  workdirCheckError,
  l_noEditorialPlanContent: noEditorialPlanContent,
  editorialPlanHits,
  m_storeSchemaGeneric: storeSchemaGeneric,
  m_storeTablesPresent: storeTablesPresent,
  m_storeOrderNumberFnGeneric: storeOrderNumberFnGeneric,
  m_storeCreateOrderFnPresent: storeCreateOrderFnPresent,
  m_clubsHasOrderPrefixColumn: clubsHasOrderPrefixColumn,
  n_membershipOkOrBlocked: membershipOkOrBlocked,
  n_membershipSchemaGeneric: membershipSchemaGeneric,
  n_membershipPlansTablePresent: membershipPlansTablePresent,
  n_membershipRpcIsDataDriven: membershipRpcIsDataDriven,
  n_canonicalBaselineBlockers: CANONICAL_BASELINE_BLOCKERS,
  baselineReady:
    noForbiddenClubLiterals &&
    noForbiddenIdentifiers &&
    noRealClubUuid &&
    noHardcodedClubIdDefault &&
    rpcAclClean &&
    hasProfilesTable &&
    hasUserAddressesTable &&
    hasHandleNewUserFn &&
    hasAuthTrigger &&
    storageBucketsOk &&
    storagePoliciesOk &&
    zeroEditorialSeeds &&
    noEditorialPlanContent &&
    storeSchemaGeneric &&
    membershipOkOrBlocked &&
    canonicalConfigExists,
};

fs.mkdirSync(RECON, { recursive: true });
fs.writeFileSync(path.join(RECON, 'canonical_baseline_audit.json'), JSON.stringify(audit, null, 2) + '\n');
console.log(JSON.stringify(audit, null, 2));
console.log('\nEscrito em:', RECON);

// M4 (convergência) — diff estrutural read-only Goiás x Bragantino.
// Nunca escreve. Exige GOIAS_DB_URL e BRAGANTINO_DB_URL, resolvidos com as
// mesmas garantias fail-loud do resto do tooling (ref validado contra o
// registry, nunca fallback). Normaliza fora do diff só o que é
// explicitamente DATA (clubs.id/slug/name/short_name/order_prefix e
// conteúdo de linhas), nunca estrutura.
import { execFileSync } from 'child_process';
import { resolveTarget } from './db_target_resolver.mjs';

function query(target, sql, label) {
  const oneLine = sql.replace(/\s+/g, ' ').trim();
  const out = execFileSync(
    'npx',
    ['supabase', 'db', 'query', '--workdir', target.workdir, '--db-url', target.dbUrl, '--output-format', 'json', `"${oneLine}"`],
    { encoding: 'utf8', shell: true },
  );
  try {
    return JSON.parse(out).rows;
  } catch {
    console.error(`[${target.club}/${label}] saída não-JSON:`, out.slice(0, 500));
    throw new Error(`falha ao parsear "${label}" em ${target.club}`);
  }
}

function snapshot(target) {
  const tables = query(target, `select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE' order by 1;`, 'tables').map((r) => r.table_name);

  const columns = query(
    target,
    `select table_name, column_name, data_type, udt_name, is_nullable, column_default from information_schema.columns where table_schema='public' and table_name <> 'clubs' order by table_name, ordinal_position;`,
    'columns',
  ).map((r) => `${r.table_name}.${r.column_name}|${r.data_type}|${r.udt_name}|null=${r.is_nullable}|default=${r.column_default ?? ''}`);
  // clubs: compara estrutura de coluna, nunca a linha (id/slug/name/order_prefix são DATA)
  const clubsColumns = query(
    target,
    `select column_name, data_type, udt_name, is_nullable from information_schema.columns where table_schema='public' and table_name='clubs' order by ordinal_position;`,
    'clubsColumns',
  ).map((r) => `clubs.${r.column_name}|${r.data_type}|${r.udt_name}|null=${r.is_nullable}`);

  const constraints = query(
    target,
    `select c.conrelid::regclass::text as tbl, c.contype, pg_get_constraintdef(c.oid) as def from pg_constraint c join pg_namespace n on n.oid=c.connamespace where n.nspname='public' order by 1,2,3;`,
    'constraints',
  ).map((r) => `${r.tbl}|${r.contype}|${r.def}`);

  const indexes = query(
    target,
    `select indexname, indexdef from pg_indexes where schemaname='public' order by 1;`,
    'indexes',
  ).map((r) => `${r.indexname}|${r.indexdef}`);

  const rls = query(
    target,
    `select relname, relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' order by 1;`,
    'rls',
  ).map((r) => `${r.relname}=${r.relrowsecurity}`);

  const policies = query(
    target,
    `select tablename, policyname, cmd, qual, with_check from pg_policies where schemaname='public' order by 1,2;`,
    'policies',
  ).map((r) => `${r.tablename}.${r.policyname}|${r.cmd}|${r.qual ?? ''}|${r.with_check ?? ''}`);

  const functions = query(
    target,
    `select p.proname, pg_get_function_identity_arguments(p.oid) as args, pg_get_functiondef(p.oid) as def from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' order by 1,2;`,
    'functions',
  ).map((r) => `${r.proname}(${r.args})`);
  const functionBodies = {};
  query(
    target,
    `select p.proname, pg_get_function_identity_arguments(p.oid) as args, p.prosrc, p.prolang::regprocedure::text as lang_ignore, l.lanname, p.prosecdef, p.proconfig from pg_proc p join pg_namespace n on n.oid=p.pronamespace join pg_language l on l.oid=p.prolang where n.nspname='public' order by 1,2;`,
    'functionBodies',
  ).forEach((r) => {
    // \r\n vs \n é diferença de arquivo-fonte (CRLF em algumas migrations
    // históricas do Goiás, LF no canonical), nunca lógica. Sequências de
    // whitespace (linha em branco extra entre statements, etc.) também são
    // puramente cosméticas -- achado real ao comparar generate_store_order_
    // number/create_store_order_for_club/subscribe_to_plan_for_club (só
    // diferiam em linhas em branco, corpo logicamente idêntico, confirmado
    // por leitura lado a lado antes de normalizar aqui). Ambos colapsados
    // pra não contar como SCHEMA_DIFF real -- isto NUNCA normaliza texto
    // dentro de uma string SQL literal de forma perigosa porque o alvo é
    // comparação/relatório, nunca reescreve o banco.
    const normalizedSrc = r.prosrc.replace(/\r\n/g, '\n').replace(/[ \t]+\n/g, '\n').replace(/\n{2,}/g, '\n').trim();
    functionBodies[`${r.proname}(${r.args})`] = `${r.lanname}|secdef=${r.prosecdef}|cfg=${JSON.stringify(r.proconfig)}|src=${normalizedSrc}`;
  });

  const grants = query(
    target,
    `select p.proname, pg_get_function_identity_arguments(p.oid) as args,
       has_function_privilege('anon', p.oid, 'EXECUTE') as anon,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as auth,
       has_function_privilege('service_role', p.oid, 'EXECUTE') as svc,
       has_function_privilege('public', p.oid, 'EXECUTE') as pub
     from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' order by 1,2;`,
    'grants',
  ).map((r) => `${r.proname}(${r.args})|anon=${r.anon}|auth=${r.auth}|svc=${r.svc}|pub=${r.pub}`);

  const triggers = query(
    target,
    `select trigger_name, event_object_table, action_timing, event_manipulation from information_schema.triggers where trigger_schema in ('public','auth') order by 1,2;`,
    'triggers',
  ).map((r) => `${r.event_object_table}.${r.trigger_name}|${r.action_timing}|${r.event_manipulation}`);

  const sequences = query(
    target,
    `select sequence_name from information_schema.sequences where sequence_schema='public' order by 1;`,
    'sequences',
  ).map((r) => r.sequence_name);

  const buckets = query(target, `select id from storage.buckets order by id;`, 'buckets').map((r) => r.id);
  const storagePolicies = query(
    target,
    `select policyname, cmd, qual, with_check from pg_policies where schemaname='storage' and tablename='objects' order by 1;`,
    'storagePolicies',
  ).map((r) => `${r.policyname}|${r.cmd}|${r.qual ?? ''}|${r.with_check ?? ''}`);

  return { tables, columns, clubsColumns, constraints, indexes, rls, policies, functions, functionBodies, grants, triggers, sequences, buckets, storagePolicies };
}

function diffSets(labelA, a, labelB, b) {
  const setA = new Set(a);
  const setB = new Set(b);
  const onlyA = [...setA].filter((x) => !setB.has(x));
  const onlyB = [...setB].filter((x) => !setA.has(x));
  return { [`only_${labelA}`]: onlyA, [`only_${labelB}`]: onlyB };
}

const goiasTarget = resolveTarget('goias');
const bragantinoTarget = resolveTarget('bragantino');
console.log('Comparando', goiasTarget.club, 'x', bragantinoTarget.club, '(read-only)');

const g = snapshot(goiasTarget);
const b = snapshot(bragantinoTarget);

const report = {
  tables: diffSets('goias', g.tables, 'bragantino', b.tables),
  columns: diffSets('goias', g.columns, 'bragantino', b.columns),
  clubsColumns: diffSets('goias', g.clubsColumns, 'bragantino', b.clubsColumns),
  constraints: diffSets('goias', g.constraints, 'bragantino', b.constraints),
  indexes: diffSets('goias', g.indexes, 'bragantino', b.indexes),
  rls: diffSets('goias', g.rls, 'bragantino', b.rls),
  policies: diffSets('goias', g.policies, 'bragantino', b.policies),
  functions: diffSets('goias', g.functions, 'bragantino', b.functions),
  grants: diffSets('goias', g.grants, 'bragantino', b.grants),
  triggers: diffSets('goias', g.triggers, 'bragantino', b.triggers),
  sequences: diffSets('goias', g.sequences, 'bragantino', b.sequences),
  buckets: diffSets('goias', g.buckets, 'bragantino', b.buckets),
  storagePolicies: diffSets('goias', g.storagePolicies, 'bragantino', b.storagePolicies),
};

// function bodies: mesmo conjunto de nomes(assinatura) -> compara texto
const bodyDiffs = [];
const allFnKeys = new Set([...Object.keys(g.functionBodies), ...Object.keys(b.functionBodies)]);
for (const key of allFnKeys) {
  const gBody = g.functionBodies[key];
  const bBody = b.functionBodies[key];
  if (gBody === undefined || bBody === undefined) continue; // já reportado em `functions` diff
  if (gBody !== bBody) bodyDiffs.push(key);
}
report.functionBodyTextDiffs = bodyDiffs;

const totalDiffCount = Object.values(report).reduce((acc, v) => {
  if (Array.isArray(v)) return acc + v.length;
  return acc + Object.values(v).reduce((a2, arr) => a2 + arr.length, 0);
}, 0);

console.log(JSON.stringify(report, null, 2));
console.log('\n=== RESULTADO ===');
console.log(`SCHEMA_DIFF=${totalDiffCount}`);
if (totalDiffCount === 0) {
  console.log('SCHEMA_EQUAL=true');
} else {
  console.log('SCHEMA_EQUAL=false — ver categorias acima com only_goias/only_bragantino não-vazios.');
  process.exit(1);
}

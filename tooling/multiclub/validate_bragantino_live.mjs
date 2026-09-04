// M4 (convergência) — validação read-only pós-push contra o Bragantino real.
// Nunca escreve. Nunca aceita Goiás como alvo (checa club === 'bragantino'
// explicitamente antes de tudo). Usa db_target_resolver.mjs pra resolver o
// alvo com as mesmas garantias fail-loud dos outros wrappers.
import { execFileSync } from 'child_process';
import { resolveTarget, printTargetBanner } from './db_target_resolver.mjs';

const club = process.argv[2];
if (club !== 'bragantino') {
  console.error('Este validador só roda contra bragantino (nunca goias). Uso: node validate_bragantino_live.mjs bragantino');
  process.exit(1);
}

const target = resolveTarget(club);
printTargetBanner(target);

function query(sql, label) {
  const oneLine = sql.replace(/\s+/g, ' ').trim();
  const out = execFileSync(
    'npx',
    ['supabase', 'db', 'query', '--workdir', target.workdir, '--db-url', target.dbUrl, '--output-format', 'json', `"${oneLine}"`],
    { encoding: 'utf8', shell: true },
  );
  try {
    return JSON.parse(out).rows;
  } catch {
    console.error(`[${label}] saída não-JSON:`, out.slice(0, 500));
    throw new Error(`falha ao parsear resultado de "${label}"`);
  }
}

const results = {};

results.tableCount = query(
  `select count(*)::int as n from information_schema.tables where table_schema='public' and table_type='BASE TABLE';`,
  'tableCount',
);

results.clubsRows = query(`select id, slug, name, order_prefix from public.clubs;`, 'clubsRows');
results.membershipPlansCount = query(`select count(*)::int as n from public.membership_plans;`, 'membershipPlansCount');
results.storeOrdersCount = query(`select count(*)::int as n from public.store_orders;`, 'storeOrdersCount');
results.storeOrderItemsCount = query(`select count(*)::int as n from public.store_order_items;`, 'storeOrderItemsCount');
results.authUsersCount = query(`select count(*)::int as n from auth.users;`, 'authUsersCount');

results.functionCount = query(
  `select count(*)::int as n from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname='public';`,
  'functionCount',
);

results.storageBuckets = query(`select id from storage.buckets order by id;`, 'storageBuckets');
results.storagePolicies = query(
  `select policyname from pg_policies where schemaname='storage' and tablename='objects' order by policyname;`,
  'storagePolicies',
);

results.rlsDisabledTables = query(
  `select relname from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' and not c.relrowsecurity;`,
  'rlsDisabledTables',
);

results.triggerCount = query(
  `select count(*)::int as n from information_schema.triggers where trigger_schema in ('public','auth');`,
  'triggerCount',
);
results.authUsersTrigger = query(
  `select tgname from pg_trigger where tgrelid = 'auth.users'::regclass and not tgisinternal;`,
  'authUsersTrigger',
);

results.goiasFnHits = query(
  `select count(*)::int as n from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prosrc ilike '%goias%';`,
  'goiasFnHits',
);
results.goiasColumnHits = query(
  `select count(*)::int as n from information_schema.columns where table_schema='public' and column_name ilike '%goias%';`,
  'goiasColumnHits',
);
results.goiasTableHits = query(
  `select count(*)::int as n from information_schema.tables where table_schema='public' and table_name ilike '%goias%';`,
  'goiasTableHits',
);
results.goiasLiteralHits = [{ n: results.goiasFnHits[0].n + results.goiasColumnHits[0].n + results.goiasTableHits[0].n }];

console.log(JSON.stringify(results, null, 2));

const clubs = results.clubsRows;
const problems = [];
if (results.tableCount[0].n < 55) problems.push(`tableCount ${results.tableCount[0].n} < 55`);
if (clubs.length !== 0) problems.push(`public.clubs não está vazia: ${JSON.stringify(clubs)}`);
if (results.membershipPlansCount[0].n !== 0) problems.push('membership_plans não está vazia');
if (results.storeOrdersCount[0].n !== 0) problems.push('store_orders não está vazia');
if (results.storeOrderItemsCount[0].n !== 0) problems.push('store_order_items não está vazia');
if (results.authUsersCount[0].n !== 0) problems.push('auth.users não está vazia');
if (results.functionCount[0].n !== 28) problems.push(`functionCount ${results.functionCount[0].n} !== 28`);
const bucketIds = results.storageBuckets.map((r) => r.id).sort();
if (JSON.stringify(bucketIds) !== JSON.stringify(['avatars', 'email-assets'])) problems.push(`buckets inesperados: ${JSON.stringify(bucketIds)}`);
if (results.storagePolicies.length !== 4) problems.push(`esperava 4 storage policies, achou ${results.storagePolicies.length}`);
if (results.rlsDisabledTables.length !== 0) problems.push(`tabelas sem RLS: ${JSON.stringify(results.rlsDisabledTables)}`);
if (results.authUsersTrigger.length === 0) problems.push('trigger em auth.users não encontrada');
if (results.goiasLiteralHits[0].n !== 0) problems.push(`goiasLiteralHits = ${results.goiasLiteralHits[0].n}, esperado 0`);

console.log('\n=== RESULTADO ===');
if (problems.length === 0) {
  console.log('VALIDATION_OK=true — Bragantino ao vivo bate com todas as expectativas estruturais.');
} else {
  console.log('VALIDATION_OK=false');
  problems.forEach((p) => console.log(' - ' + p));
  process.exit(1);
}

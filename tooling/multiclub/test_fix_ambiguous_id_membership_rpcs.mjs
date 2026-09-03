import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const MIGRATION_PATH = path.join(
  ROOT,
  'supabase/migrations/20260903180000_fix_ambiguous_id_membership_rpcs.sql'
);
const BASELINE_PATH = path.join(
  ROOT,
  'tooling/multiclub/fixtures/db/membership_rpc_ambiguous_id_fix_baseline.json'
);

const migration = fs.readFileSync(MIGRATION_PATH, 'utf8');
const baseline = JSON.parse(fs.readFileSync(BASELINE_PATH, 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log(`  PASS — ${name}`);
  } catch (err) {
    failures.push({ name, err });
    console.log(`  FAIL — ${name}\n    ${err.message}`);
  }
}

function stripLineComments(sql) {
  return sql
    .split('\n')
    .map((line) => {
      const idx = line.indexOf('--');
      return idx === -1 ? line : line.slice(0, idx);
    })
    .join('\n');
}

function normalize(sql) {
  return sql
    .toLowerCase()
    .replace(/set search_path\s+to\s+'pg_catalog',\s*'public',\s*'pg_temp'/g, 'set search_path = pg_catalog, public, pg_temp')
    .replace(/\s+/g, ' ')
    .replace(/\(\s+/g, '(')
    .replace(/\s+\)/g, ')')
    .trim();
}

function extractFunctionBlock(sql, fnName) {
  const startRe = new RegExp(
    `create or replace function public\\.${fnName}\\s*\\(`,
    'i'
  );
  const startMatch = startRe.exec(sql);
  assert.ok(startMatch, `bloco CREATE OR REPLACE FUNCTION de ${fnName} não encontrado`);
  const endMarker = '$function$;';
  const endIdx = sql.indexOf(endMarker, startMatch.index);
  assert.ok(endIdx !== -1, `terminador $function$; de ${fnName} não encontrado`);
  return sql.slice(startMatch.index, endIdx + endMarker.length);
}

console.log('1) Só as duas RPCs-alvo são tocadas nesta migration');
test('exatamente 2 CREATE OR REPLACE FUNCTION no arquivo, nomes exatos', () => {
  const matches = [
    ...migration.matchAll(/create or replace function public\.(\w+)/gi),
  ].map((m) => m[1]);
  assert.strictEqual(matches.length, 2);
  assert.deepStrictEqual(
    matches.sort(),
    ['get_my_membership_for_club', 'subscribe_to_plan_for_club'].sort()
  );
});
test('nenhuma outra RPC _for_club aparece no arquivo (nem em comentário de nome de função)', () => {
  for (const fnName of baseline.otherForClubRpcsScanned) {
    const re = new RegExp(`function public\\.${fnName}\\b`, 'i');
    assert.strictEqual(re.test(migration), false, `${fnName} não deveria aparecer`);
  }
});

const migrationCode = stripLineComments(migration);

console.log('\n2) A referência ambígua foi removida e substituída pela forma qualificada');
test('0 ocorrências de "where id = p_club_id" (sem qualificar) no CÓDIGO (fora de comentários)', () => {
  const re = /where\s+id\s*=\s*p_club_id/gi;
  const matches = [...migrationCode.matchAll(re)];
  assert.strictEqual(matches.length, 0, `encontrado: ${matches.map((m) => m[0]).join(', ')}`);
});
test('exatamente 2 ocorrências de "c.id = p_club_id" no código (uma por função)', () => {
  const re = /c\.id\s*=\s*p_club_id/gi;
  const matches = [...migrationCode.matchAll(re)];
  assert.strictEqual(matches.length, 2);
});
test('o alias "c" vem de "from public.clubs c" no código, nas duas funções', () => {
  const re = /from public\.clubs c\b/gi;
  const matches = [...migrationCode.matchAll(re)];
  assert.strictEqual(matches.length, 2);
});

console.log('\n3) Corpo de cada função — nada além da qualificação mudou');
for (const [fnName, baseFn] of Object.entries(baseline.functions)) {
  test(`${fnName}: corpo normalizado bate com o live "antes" + só a troca id->c.id`, () => {
    const expectedAfter = normalize(stripLineComments(baseFn.liveDefBefore))
      .replace('where id = p_club_id', 'where c.id = p_club_id')
      .replace('from public.clubs where', 'from public.clubs c where')
      .replace(/;$/, '') + ';';
    const actualBlock = normalize(extractFunctionBlock(migrationCode, fnName));
    assert.strictEqual(actualBlock, expectedAfter);
  });
}

console.log('\n4) Assinatura, tipos, defaults, RETURNS TABLE — preservados');
for (const [fnName, baseFn] of Object.entries(baseline.functions)) {
  test(`${fnName}: identity args idênticos ao live baseline`, () => {
    const re = new RegExp(
      `function public\\.${fnName}\\(${baseFn.identityArgs.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\)`,
      'i'
    );
    assert.ok(re.test(migration), `esperava "(${baseFn.identityArgs})" na assinatura`);
  });
  test(`${fnName}: RETURNS TABLE preserva as mesmas colunas/tipos do baseline`, () => {
    const returnsCols = baseFn.returns
      .replace(/^TABLE\(/, '')
      .replace(/\)$/, '');
    const expectedCols = returnsCols
      .split(',')
      .map((c) => normalize(c))
      .sort();
    const block = normalize(extractFunctionBlock(migration, fnName));
    const returnsMatch = /returns table\((.*?)\) language/.exec(block);
    assert.ok(returnsMatch, `RETURNS TABLE não encontrado no bloco de ${fnName}`);
    const actualCols = returnsMatch[1]
      .split(',')
      .map((c) => c.trim())
      .sort();
    assert.deepStrictEqual(actualCols, expectedCols);
  });
}

console.log('\n5) SECURITY DEFINER / volatility / strictness / parallel — preservados (defaults implícitos)');
for (const [fnName, baseFn] of Object.entries(baseline.functions)) {
  const block = extractFunctionBlock(migration, fnName);
  test(`${fnName}: "security definer" presente (prosecdef=${baseFn.prosecdef} no live)`, () => {
    assert.strictEqual(baseFn.prosecdef, true);
    assert.ok(/security definer/i.test(block));
    assert.strictEqual(/security invoker/i.test(block), false);
  });
  test(`${fnName}: nenhuma keyword STRICT/IMMUTABLE/STABLE/PARALLEL (defaults do live: v/${baseFn.proisstrict}/${baseFn.proparallel})`, () => {
    assert.strictEqual(baseFn.provolatile, 'v');
    assert.strictEqual(baseFn.proisstrict, false);
    assert.strictEqual(baseFn.proparallel, 'u');
    assert.strictEqual(/\bstrict\b/i.test(block), false);
    assert.strictEqual(/\bimmutable\b/i.test(block), false);
    assert.strictEqual(/\bstable\b/i.test(block), false);
    assert.strictEqual(/\bparallel\s+(safe|restricted)\b/i.test(block), false);
  });
  test(`${fnName}: search_path list preservada (pg_catalog, public, pg_temp)`, () => {
    assert.ok(/set search_path\s*=\s*pg_catalog,\s*public,\s*pg_temp/i.test(block));
  });
}

console.log('\n6) ACL — revoke total + grant restrito exatamente ao allowlist real (authenticated)');
const signatures = {
  get_my_membership_for_club: 'uuid',
  subscribe_to_plan_for_club: 'uuid, text',
};
for (const [fnName, args] of Object.entries(signatures)) {
  const baseFn = baseline.functions[fnName];
  test(`${fnName}: baseline confirma live ACL = só authenticated (anon/service_role false)`, () => {
    assert.strictEqual(baseFn.acl.anon, false);
    assert.strictEqual(baseFn.acl.authenticated, true);
    assert.strictEqual(baseFn.acl.service_role, false);
  });
  test(`${fnName}: migration revoga de public, anon, service_role`, () => {
    const re = new RegExp(
      `revoke all on function public\\.${fnName}\\(${args}\\)\\s*from public, anon, service_role`,
      'i'
    );
    assert.ok(re.test(migration));
  });
  test(`${fnName}: migration concede execute somente para authenticated`, () => {
    const re = new RegExp(
      `grant execute on function public\\.${fnName}\\(${args}\\)\\s*to authenticated`,
      'i'
    );
    assert.ok(re.test(migration));
  });
}
test('nenhum GRANT para anon/service_role/public em nenhum ponto do arquivo', () => {
  const grantLines = migration
    .split('\n')
    .filter((l) => /^\s*grant\s+execute/i.test(l));
  for (const line of grantLines) {
    assert.strictEqual(/\bto\s+anon\b/i.test(line), false, line);
    assert.strictEqual(/\bto\s+service_role\b/i.test(line), false, line);
    assert.strictEqual(/\bto\s+public\b/i.test(line), false, line);
  }
});

console.log('\n7) git status restrito aos arquivos desta rodada (nenhum arquivo alheio entrou no diff)');
test('supabase/migrations só tem a nova migration como untracked/staged', () => {
  const out = execSync('git status --porcelain supabase/migrations/', {
    cwd: ROOT,
    encoding: 'utf8',
  });
  const lines = out.split('\n').filter(Boolean);
  assert.strictEqual(lines.length, 1, `esperava só 1 linha, achei:\n${out}`);
  assert.ok(lines[0].includes('20260903180000_fix_ambiguous_id_membership_rpcs.sql'));
});
test('a migration não altera nenhum outro arquivo .sql', () => {
  const sqlFiles = fs
    .readdirSync(path.join(ROOT, 'supabase/migrations'))
    .filter((f) => f.endsWith('.sql'));
  const newOnes = sqlFiles.filter((f) =>
    f === '20260903180000_fix_ambiguous_id_membership_rpcs.sql'
  );
  assert.strictEqual(newOnes.length, 1);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

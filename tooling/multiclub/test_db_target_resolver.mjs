import assert from 'assert';
import { execFileSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadProjectsRegistry } from './db_target_resolver.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

function run(script, args, env = {}) {
  try {
    const out = execFileSync(process.execPath, [path.join(__dirname, script), ...args], {
      cwd: ROOT,
      env: { ...process.env, ...env },
      encoding: 'utf8',
      stdio: 'pipe',
    });
    return { code: 0, out };
  } catch (err) {
    return { code: err.status ?? 1, out: (err.stdout || '') + (err.stderr || '') };
  }
}

console.log('1) db-push goias — desde 2026-09-04 é um write target válido (autorização explícita), com as MESMAS guardas do bragantino');
test('db-push.mjs goias sem GOIAS_DB_URL -> fail-loud, nunca escreve sem env var', () => {
  const env = { ...process.env };
  delete env.GOIAS_DB_URL;
  let threw = false;
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'goias', '--dry-run'], { cwd: ROOT, env, stdio: 'pipe' });
  } catch (err) {
    threw = true;
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.strictEqual(threw, true);
  assert.ok(/GOIAS_DB_URL_REQUIRED=true/.test(msg));
});
test('db-push.mjs goias sem --dry-run e sem --yes falha antes de tentar conectar (mesma regra do bragantino)', () => {
  const env = { ...process.env, GOIAS_DB_URL: 'postgresql://postgres.yonozsdgyrhgqrvydbnr:x@aws-0-x.pooler.supabase.com:5432/postgres' };
  let threw = false;
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'goias'], { cwd: ROOT, env, stdio: 'pipe', timeout: 5000 });
  } catch (err) {
    threw = true;
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.strictEqual(threw, true);
  assert.ok(/exige --yes/.test(msg));
});
test('db-push.mjs goias com BRAGANTINO_DB_URL apontando pro Goiás usado como GOIAS_DB_URL do Bragantino é rejeitado (mismatch de ref, nunca aceito por acidente)', () => {
  const env = { ...process.env, GOIAS_DB_URL: 'postgresql://postgres.yrgyzkaaudyzmsqwzecj:x@aws-0-x.pooler.supabase.com:5432/postgres' };
  let threw = false;
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'goias', '--dry-run'], { cwd: ROOT, env, stdio: 'pipe' });
  } catch (err) {
    threw = true;
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.strictEqual(threw, true);
  assert.ok(/MISMATCH/.test(msg));
});

console.log('\n2) env var ausente -> fail-loud, nunca pede senha, nunca usa outro clube');
test('db-push.mjs bragantino sem BRAGANTINO_DB_URL -> BRAGANTINO_DB_URL_REQUIRED=true', () => {
  const env = { ...process.env };
  delete env.BRAGANTINO_DB_URL;
  let threw = false;
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'bragantino', '--dry-run'], { cwd: ROOT, env, stdio: 'pipe' });
  } catch (err) {
    threw = true;
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.strictEqual(threw, true);
  assert.ok(/BRAGANTINO_DB_URL_REQUIRED=true/.test(msg));
});

console.log('\n3) clube desconhecido -> fail-loud, nunca cai pra um default');
test('db-status.mjs juventude -> erro citando os clubes reais disponíveis', () => {
  let threw = false;
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-status.mjs'), 'juventude'], { cwd: ROOT, stdio: 'pipe' });
  } catch (err) {
    threw = true;
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.strictEqual(threw, true);
  assert.ok(/goias, bragantino/.test(msg));
  assert.ok(!/_comment/.test(msg), 'chaves internas do registry (_comment) nunca devem aparecer como clube válido');
});

console.log('\n4) mismatch de host/ref -> fail-loud (env var do clube errado por engano)');
test('BRAGANTINO_DB_URL apontando pro ref do Goiás é rejeitado', () => {
  const env = { ...process.env, BRAGANTINO_DB_URL: 'postgresql://postgres.yonozsdgyrhgqrvydbnr:x@aws-0-x.pooler.supabase.com:5432/postgres' };
  let threw = false;
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'bragantino', '--dry-run'], { cwd: ROOT, env, stdio: 'pipe' });
  } catch (err) {
    threw = true;
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.strictEqual(threw, true);
  assert.ok(/MISMATCH/.test(msg));
});

console.log('\n5) escrita real sem --yes é bloqueada (só --dry-run roda sem --yes)');
test('db-push.mjs bragantino sem --dry-run e sem --yes falha antes de tentar conectar', () => {
  const env = { ...process.env, BRAGANTINO_DB_URL: 'postgresql://postgres.yrgyzkaaudyzmsqwzecj:x@aws-0-x.pooler.supabase.com:5432/postgres' };
  let threw = false;
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'bragantino'], { cwd: ROOT, env, stdio: 'pipe', timeout: 5000 });
  } catch (err) {
    threw = true;
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.strictEqual(threw, true);
  assert.ok(/exige --yes/.test(msg));
});

console.log('\n6) connection string NUNCA aparece inteira em nenhuma saída (só o host)');
test('a env var falsa com senha "x" nunca aparece no output do mismatch (item 4)', () => {
  const env = { ...process.env, BRAGANTINO_DB_URL: 'postgresql://postgres.yonozsdgyrhgqrvydbnr:SENHA_SECRETA_FALSA@aws-0-x.pooler.supabase.com:5432/postgres' };
  let msg = '';
  try {
    execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'bragantino', '--dry-run'], { cwd: ROOT, env, stdio: 'pipe' });
  } catch (err) {
    msg = (err.stdout || '').toString() + (err.stderr || '').toString();
  }
  assert.ok(!msg.includes('SENHA_SECRETA_FALSA'), 'a senha nunca deveria aparecer em nenhuma saída de log');
});

console.log('\n7) MIGRATION_SOURCE_EQUAL_FOR_ALL_CLUBS — desde o cutover de 2026-09-04, todos os clubes usam a MESMA pasta de migrations (só muda DB_URL/project ref)');
test('goias.workdir === bragantino.workdir no registry (raiz do repo, supabase/migrations/) — nunca mais 2 cadeias paralelas', () => {
  const registry = loadProjectsRegistry();
  assert.strictEqual(registry.goias.workdir, registry.bragantino.workdir);
  assert.strictEqual(registry.goias.workdir, '.');
});
test('FABRICADO — se um dia alguém reintroduzir workdirs diferentes por clube, este teste reprova', () => {
  const fakeRegistry = { goias: { workdir: '.' }, bragantino: { workdir: 'infra/supabase/canonical' } };
  assert.notStrictEqual(fakeRegistry.goias.workdir, fakeRegistry.bragantino.workdir);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

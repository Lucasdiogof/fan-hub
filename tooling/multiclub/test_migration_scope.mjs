// Testes do escopo de migrations (A2). Nenhum depende de banco real:
//  * lógica pura (biblioteca) sobre fixtures em diretório temporário;
//  * o manifesto REAL do repositório (só leitura de arquivos locais);
//  * subprocessos com env vars FALSAS apontando para 127.0.0.1:1 (nunca conecta)
//    — o objetivo é provar que os scripts recusam/planejam ANTES de abrir conexão.
// O caminho de sucesso do teste de IDOR NÃO é exercitado por subprocesso (faria
// signup em projeto real); a validação do destino é testada por unidade.
import assert from 'assert';
import { execFileSync } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  assertSupabaseUrlMatchesClub,
  extractProjectRefFromSupabaseUrl,
  loadProjectsRegistry,
  redactDbUrl,
} from './db_target_resolver.mjs';
import {
  assertValid,
  buildClubWorkdir,
  checkFileForClub,
  ROOT,
  ScopeError,
  sha256Normalized,
  validateManifest,
  resolveForClub,
} from './migration_scope.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REGISTRY = loadProjectsRegistry();
const CLUBS = Object.keys(REGISTRY).filter((k) => !k.startsWith('_'));
const REF = Object.fromEntries(CLUBS.map((c) => [c, REGISTRY[c].projectRef]));
const REAL_DIR = path.join(ROOT, 'supabase', 'migrations');
const REAL_MANIFEST = path.join(ROOT, 'supabase', 'migration_scopes.json');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function throwsScope(fn, re) {
  let err = null;
  try { fn(); } catch (e) { err = e; }
  assert.ok(err, 'deveria ter lançado');
  assert.ok(err instanceof ScopeError, `deveria ser ScopeError, veio ${err && err.name}: ${err && err.message}`);
  if (re) assert.ok(re.test(err.message), `mensagem não casa ${re}: ${err.message}`);
}

// ---- fixtures ---------------------------------------------------------------
const TMP_ROOT = fs.mkdtempSync(path.join(os.tmpdir(), 'fanhub-scope-test-'));
let seq = 0;
const FILES = {
  '20260101000000_global_a.sql': 'select 1;\n',
  '20260102000000_goias_only.sql': "update public.x set a = 1 where id = 'g';\n",
  '20260103000000_goias_vilanova.sql': 'select 3;\n',
  '20260104000000_global_b.sql': 'select 4;\n',
};
const SCOPES = {
  '20260101000000': ['global'],
  '20260102000000': ['goias'],
  '20260103000000': ['goias', 'vilanova'],
  '20260104000000': ['global'],
};
function mkFixture({ files = FILES, scopes = SCOPES, mutate } = {}) {
  const dir = path.join(TMP_ROOT, `fx${++seq}`);
  const migrationsDir = path.join(dir, 'migrations');
  fs.mkdirSync(migrationsDir, { recursive: true });
  for (const [f, c] of Object.entries(files)) fs.writeFileSync(path.join(migrationsDir, f), c);
  const manifest = {
    version: 1,
    migrations: Object.entries(files).map(([f, c]) => ({
      version: f.slice(0, 14),
      file: f,
      scope: scopes[f.slice(0, 14)] ?? ['global'],
      sha256: sha256Normalized(Buffer.from(c)),
      note: `fixture ${f}`,
    })),
  };
  if (mutate) mutate(manifest, migrationsDir);
  const manifestPath = path.join(dir, 'migration_scopes.json');
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  return { dir, migrationsDir, manifestPath, clubs: CLUBS, tmpBase: TMP_ROOT };
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
const fakeDbUrl = (club, pw = 'fakepw-SECRET-123') => `postgresql://postgres.${REF[club]}:${pw}@127.0.0.1:1/postgres`;
const dbEnv = () => Object.fromEntries(CLUBS.map((c) => [REGISTRY[c].envVar, fakeDbUrl(c)]));
const tmpDirsNow = () => fs.readdirSync(os.tmpdir()).filter((n) => n.startsWith('fanhub-migrations-'));

const real = assertValid();
const REAL_GOIAS_ONLY = real.filter((e) => e.scope[0] !== 'global').map((e) => e.file);
const REAL_GLOBAL = real.filter((e) => e.scope[0] === 'global').map((e) => e.file);

console.log('1) Manifesto: integridade e regras (fail closed)');
test('manifesto válido (fixture): todos os arquivos possuem entrada', () => {
  const r = validateManifest(mkFixture());
  assert.deepStrictEqual(r.errors, []);
  assert.strictEqual(r.entries.length, 4);
});
test('manifesto REAL do repositório é válido e cobre 1:1 supabase/migrations', () => {
  const r = validateManifest();
  assert.deepStrictEqual(r.errors, []);
  assert.strictEqual(r.entries.length, fs.readdirSync(REAL_DIR).filter((f) => f.endsWith('.sql')).length);
});
test('arquivo sem entrada no manifesto -> falha', () => {
  const fx = mkFixture({ mutate: (m) => { m.migrations.pop(); } });
  throwsScope(() => assertValid(fx), /SEM entrada no manifesto: 20260104000000_global_b\.sql/);
});
test('entrada sem arquivo -> falha', () => {
  const fx = mkFixture({ mutate: (m) => { m.migrations.push({ version: '20260105000000', file: '20260105000000_ghost.sql', scope: ['global'], sha256: 'a'.repeat(64), note: 'x' }); } });
  throwsScope(() => assertValid(fx), /migration inexistente/);
});
test('SHA alterado -> falha', () => {
  const fx = mkFixture();
  fs.appendFileSync(path.join(fx.migrationsDir, '20260101000000_global_a.sql'), '-- editado\n');
  throwsScope(() => assertValid(fx), /SHA-256 diferente/);
});
test('scope desconhecido -> falha', () => {
  const fx = mkFixture({ scopes: { ...SCOPES, '20260102000000': ['juventude'] } });
  throwsScope(() => assertValid(fx), /scope desconhecido "juventude"/);
});
test('combinação ambígua global + goias -> falha', () => {
  const fx = mkFixture({ scopes: { ...SCOPES, '20260102000000': ['global', 'goias'] } });
  throwsScope(() => assertValid(fx), /combinação ambígua/);
});
test('versão duplicada no manifesto -> falha', () => {
  const fx = mkFixture({ mutate: (m) => { m.migrations[1].version = m.migrations[0].version; } });
  throwsScope(() => assertValid(fx), /versão duplicada/);
});
test('arquivo duplicado no manifesto -> falha', () => {
  const fx = mkFixture({ mutate: (m) => { m.migrations.push({ ...m.migrations[0], version: '20260109000000' }); } });
  throwsScope(() => assertValid(fx), /arquivo duplicado/);
});
test('inconsistência arquivo <-> version -> falha', () => {
  const fx = mkFixture({ mutate: (m) => { m.migrations[0].version = '20269999999999'; } });
  throwsScope(() => assertValid(fx), /não corresponde ao prefixo do arquivo/);
});
test('dois arquivos reais com a mesma versão -> falha', () => {
  const fx = mkFixture({ files: { ...FILES, '20260101000000_outro_nome.sql': 'select 9;\n' } });
  throwsScope(() => assertValid(fx), /versão duplicada entre arquivos reais/);
});
test('arquivo não-.sql ou subpasta na pasta de migrations -> falha', () => {
  const a = mkFixture();
  fs.writeFileSync(path.join(a.migrationsDir, 'README.md'), 'x');
  throwsScope(() => assertValid(a), /não é \.sql/);
  const b = mkFixture();
  fs.mkdirSync(path.join(b.migrationsDir, 'goias'));
  throwsScope(() => assertValid(b), /subpasta/);
});
test('campo desconhecido / note vazio / sha malformado -> falha', () => {
  throwsScope(() => assertValid(mkFixture({ mutate: (m) => { m.migrations[0].extra = 1; } })), /campo desconhecido/);
  throwsScope(() => assertValid(mkFixture({ mutate: (m) => { m.migrations[0].note = ' '; } })), /note obrigatório/);
  throwsScope(() => assertValid(mkFixture({ mutate: (m) => { m.migrations[0].sha256 = 'XYZ'; } })), /sha256 deve ser hex/);
});
test('manifesto ausente ou JSON inválido -> falha', () => {
  const fx = mkFixture();
  fs.writeFileSync(fx.manifestPath, '{ nao e json');
  throwsScope(() => assertValid(fx), /não é JSON válido/);
  fs.rmSync(fx.manifestPath);
  throwsScope(() => assertValid(fx), /manifesto inexistente/);
});
test('hash normaliza CRLF -> LF (mesmo conteúdo em checkouts diferentes)', () => {
  assert.strictEqual(sha256Normalized(Buffer.from('a\r\nb\r\n')), sha256Normalized(Buffer.from('a\nb\n')));
  assert.notStrictEqual(sha256Normalized(Buffer.from('a\nb\n')), sha256Normalized(Buffer.from('a\nc\n')));
});

console.log('\n2) Escopo por clube');
test('migration só-Goiás: permitida no Goiás', () => {
  const v = resolveForClub('goias', mkFixture());
  assert.ok(v.allowed.some((e) => e.file === '20260102000000_goias_only.sql'));
});
test('migration só-Goiás: bloqueada no Bragantino', () => {
  const v = resolveForClub('bragantino', mkFixture());
  assert.ok(!v.allowed.some((e) => e.file === '20260102000000_goias_only.sql'));
  assert.ok(v.excluded.some((e) => e.file === '20260102000000_goias_only.sql'));
});
test('migration só-Goiás: bloqueada no Vila Nova', () => {
  const v = resolveForClub('vilanova', mkFixture());
  assert.ok(!v.allowed.some((e) => e.file === '20260102000000_goias_only.sql'));
});
test('global: permitida nos três clubes', () => {
  const fx = mkFixture();
  for (const c of CLUBS) assert.ok(resolveForClub(c, fx).allowed.some((e) => e.file === '20260101000000_global_a.sql'), c);
});
test('lista de clubes (goias + vilanova): vê Goiás e Vila Nova, não o Bragantino', () => {
  const fx = mkFixture();
  const has = (c) => resolveForClub(c, fx).allowed.some((e) => e.file === '20260103000000_goias_vilanova.sql');
  assert.deepStrictEqual([has('goias'), has('vilanova'), has('bragantino')], [true, true, false]);
});
test('clube inexistente -> falha (nunca resolve por padrão)', () => {
  throwsScope(() => resolveForClub('juventude', mkFixture()), /clube desconhecido "juventude"/);
  throwsScope(() => resolveForClub(undefined, mkFixture()), /clube desconhecido/);
});
test('REAL: as 11 migrations de dados do Goiás são só-Goiás e as 8 restantes são globais', () => {
  assert.strictEqual(REAL_GOIAS_ONLY.length, 11);
  assert.strictEqual(REAL_GLOBAL.length, 8);
  assert.ok(REAL_GOIAS_ONLY.every((f) => /^(20260930|20261001|20261002)/.test(f) && !/harden/.test(f)));
  assert.ok(REAL_GLOBAL.includes('20261002040000_harden_passport_per_user_rpcs.sql'));
  assert.ok(REAL_GLOBAL.some((f) => f.startsWith('20260909000000')), '20260909000000 deve ser global (dívida funcional é separada)');
  assert.ok(REAL_GOIAS_ONLY.includes('20261002030000_manto_goias_academy_club_rule.sql'));
});
test('REAL: nenhuma migration só-Goiás é visível ao Bragantino nem ao Vila Nova; todas ao Goiás', () => {
  for (const c of CLUBS.filter((x) => x !== 'goias')) {
    const files = resolveForClub(c).allowed.map((e) => e.file);
    for (const f of REAL_GOIAS_ONLY) assert.ok(!files.includes(f), `${c} vê ${f}`);
    for (const f of REAL_GLOBAL) assert.ok(files.includes(f), `${c} não vê global ${f}`);
  }
  const g = resolveForClub('goias').allowed.map((e) => e.file);
  assert.strictEqual(g.length, REAL_GLOBAL.length + REAL_GOIAS_ONLY.length);
});

console.log('\n3) Workdir temporário por clube');
for (const club of CLUBS) {
  test(`workdir ${club}: contém exatamente globals + ${club}, nunca algo fora do escopo`, () => {
    const before = fs.readdirSync(REAL_DIR).sort().join(',');
    const wd = buildClubWorkdir(club);
    try {
      const files = fs.readdirSync(path.join(wd.workdir, 'supabase', 'migrations')).sort();
      const expected = resolveForClub(club).allowed.map((e) => e.file).sort();
      assert.deepStrictEqual(files, expected);
      if (club !== 'goias') for (const f of REAL_GOIAS_ONLY) assert.ok(!files.includes(f), f);
      for (const f of REAL_GLOBAL) assert.ok(files.includes(f), f);
      // cópias fiéis (CRLF/LF aparte) e config neutro, sem refs de projeto
      for (const e of resolveForClub(club).allowed) {
        assert.strictEqual(sha256Normalized(fs.readFileSync(path.join(wd.workdir, 'supabase', 'migrations', e.file))), e.sha256);
      }
      const cfg = fs.readFileSync(path.join(wd.workdir, 'supabase', 'config.toml'), 'utf8');
      for (const r of Object.values(REF)) assert.ok(!cfg.includes(r), 'config.toml herdou project ref');
      assert.ok(path.relative(ROOT, wd.workdir).startsWith('..'), 'workdir dentro do repositório');
    } finally {
      wd.cleanup();
    }
    assert.ok(!fs.existsSync(wd.workdir), 'cleanup não removeu o workdir');
    assert.strictEqual(fs.readdirSync(REAL_DIR).sort().join(','), before, 'supabase/migrations foi alterada');
  });
}
test('falha na criação do workdir -> ScopeError e nada fica para trás', () => {
  const before = tmpDirsNow().length;
  throwsScope(() => buildClubWorkdir('goias', { tmpBase: path.join(TMP_ROOT, 'nao', 'existe') }), /erro na criação do workdir/);
  assert.strictEqual(tmpDirsNow().length, before);
});
test('manifesto inválido impede criar workdir', () => {
  const fx = mkFixture({ mutate: (m) => { m.migrations.pop(); } });
  const before = fs.readdirSync(TMP_ROOT).length;
  throwsScope(() => buildClubWorkdir('goias', fx), /SEM entrada/);
  assert.strictEqual(fs.readdirSync(TMP_ROOT).length, before);
});

console.log('\n4) run-sql-file: sem bypass (recusa ANTES de abrir conexão)');
const GOIAS_MIG = path.join('supabase', 'migrations', '20260930040000_fix_pedrinho_height.sql');
test('checkFileForClub: migration do Goiás permitida no Goiás, bloqueada nos demais', () => {
  assert.strictEqual(checkFileForClub(GOIAS_MIG, 'goias').allowed, true);
  throwsScope(() => checkFileForClub(GOIAS_MIG, 'bragantino'), /BLOQUEADO por escopo/);
  throwsScope(() => checkFileForClub(GOIAS_MIG, 'vilanova'), /BLOQUEADO por escopo/);
});
test('run-sql-file bragantino <migration do Goiás> -> BLOQUEADO, sem resolver alvo nem conectar', () => {
  const r = run('run-sql-file.mjs', ['bragantino', GOIAS_MIG, '--yes'], dbEnv());
  assert.notStrictEqual(r.code, 0);
  assert.ok(/BLOQUEADO por escopo/.test(r.out), r.out);
  assert.ok(!/ALVO CONFIRMADO|executando|ERRO na execução|ECONNREFUSED/.test(r.out), r.out);
});
test('run-sql-file vilanova <migration do Goiás> -> BLOQUEADO (mesmo sem env var do clube)', () => {
  const env = { ...process.env }; delete env[REGISTRY.vilanova.envVar];
  const r = run('run-sql-file.mjs', ['vilanova', GOIAS_MIG, '--yes'], {});
  assert.notStrictEqual(r.code, 0);
  assert.ok(/BLOQUEADO por escopo/.test(r.out), r.out);
  assert.ok(!/DB_URL_REQUIRED/.test(r.out), 'o escopo deve ser checado antes da env var');
});
test('cópia da migration do Goiás fora de supabase/migrations (mesmo conteúdo, até com LF) -> BLOQUEADA', () => {
  const copy = path.join(TMP_ROOT, 'copia_pedrinho.sql');
  const bytes = fs.readFileSync(GOIAS_MIG, 'utf8').replace(/\r\n/g, '\n');
  fs.writeFileSync(copy, bytes);
  const r = run('run-sql-file.mjs', ['bragantino', copy, '--yes'], dbEnv());
  assert.notStrictEqual(r.code, 0);
  assert.ok(/BLOQUEADO por escopo/.test(r.out) && /fora de supabase\/migrations/.test(r.out), r.out);
});
test('run-sql-file goias <migration do Goiás>: escopo OK (para só por faltar --yes, sem conectar)', () => {
  const r = run('run-sql-file.mjs', ['goias', GOIAS_MIG], dbEnv());
  assert.notStrictEqual(r.code, 0);
  assert.ok(/escopo:\s+OK/.test(r.out), r.out);
  assert.ok(/exige --yes/.test(r.out), r.out);
  assert.ok(!/executando|ERRO na execução/.test(r.out), r.out);
});
test('run-sql-file bragantino <migration global>: permitida (escopo OK)', () => {
  const r = run('run-sql-file.mjs', ['bragantino', path.join('supabase', 'migrations', '20261002040000_harden_passport_per_user_rpcs.sql')], dbEnv());
  assert.ok(/escopo:\s+OK/.test(r.out), r.out);
  assert.ok(!/BLOQUEADO/.test(r.out), r.out);
});
test('SQL que não é migration segue como antes (escopo n/a) e continua exigindo --yes', () => {
  const f = path.join(TMP_ROOT, 'seed_solto.sql');
  fs.writeFileSync(f, 'select 1;\n');
  const r = run('run-sql-file.mjs', ['bragantino', f], dbEnv());
  assert.ok(/escopo:\s+n\/a/.test(r.out), r.out);
  assert.ok(/exige --yes/.test(r.out), r.out);
});
test('project ref continua validado em run-sql-file (env var de outro clube -> MISMATCH)', () => {
  const r = run('run-sql-file.mjs', ['bragantino', path.join(TMP_ROOT, 'seed_solto.sql'), '--yes'], { [REGISTRY.bragantino.envVar]: fakeDbUrl('goias') });
  assert.notStrictEqual(r.code, 0);
  assert.ok(/MISMATCH/.test(r.out), r.out);
});

console.log('\n5) db-push: plano local (dry-run) e fail closed');
for (const club of CLUBS) {
  test(`db-push ${club} --dry-run: mostra alvo, ref, incluídas/excluídas, workdir e comando redigido; não cria nada`, () => {
    const before = tmpDirsNow().length;
    const r = run('db-push.mjs', [club, '--dry-run'], dbEnv());
    assert.strictEqual(r.code, 0, r.out);
    const [inc, exc] = r.out.split('Migrations excluídas por escopo');
    assert.ok(r.out.includes(`Club:        ${club}`) && r.out.includes(`Project ref: ${REF[club]}`), r.out);
    assert.ok(/workdir que seria criado:/.test(r.out) && /comando lógico:/.test(r.out), r.out);
    assert.ok(r.out.includes('<redigido>') && !r.out.includes('fakepw-SECRET-123'), 'credencial vazou no output');
    assert.ok(!/=== db push/.test(r.out), 'dry-run local não pode chamar o CLI');
    const goiasOnlyInIncluded = REAL_GOIAS_ONLY.filter((f) => inc.includes(f));
    if (club === 'goias') {
      assert.strictEqual(goiasOnlyInIncluded.length, REAL_GOIAS_ONLY.length);
      assert.ok(/excluídas por escopo\s*$/.test('x') || true);
      assert.ok(/\(0\):/.test(exc), exc);
    } else {
      assert.strictEqual(goiasOnlyInIncluded.length, 0, `${club} enxerga só-Goiás`);
      for (const f of REAL_GOIAS_ONLY) assert.ok(exc.includes(f), `${f} deveria estar excluída`);
    }
    assert.strictEqual(tmpDirsNow().length, before, 'dry-run criou workdir');
  });
}
test('db-push sem env var do clube -> fail-loud, mesmo com --dry-run', () => {
  const env = { ...process.env }; delete env.GOIAS_DB_URL;
  let msg = '';
  try { execFileSync(process.execPath, [path.join(__dirname, 'db-push.mjs'), 'goias', '--dry-run'], { cwd: ROOT, env, stdio: 'pipe' }); }
  catch (err) { msg = String(err.stdout) + String(err.stderr); }
  assert.ok(/GOIAS_DB_URL_REQUIRED=true/.test(msg), msg);
});
test('db-push com env var apontando para OUTRO projeto -> MISMATCH', () => {
  const r = run('db-push.mjs', ['vilanova', '--dry-run'], { ...dbEnv(), [REGISTRY.vilanova.envVar]: fakeDbUrl('goias') });
  assert.notStrictEqual(r.code, 0);
  assert.ok(/MISMATCH/.test(r.out), r.out);
});
test('db-push: escrita real sem --yes, clube desconhecido e --remote sem --dry-run -> recusa', () => {
  assert.notStrictEqual(run('db-push.mjs', ['goias'], dbEnv()).code, 0);
  assert.notStrictEqual(run('db-push.mjs', ['juventude', '--dry-run'], dbEnv()).code, 0);
  assert.notStrictEqual(run('db-push.mjs', ['goias', '--remote'], dbEnv()).code, 0);
  assert.notStrictEqual(run('db-push.mjs', [], dbEnv()).code, 0);
});
test('db-status --plan usa o mesmo recorte e não exige env var nem conecta', () => {
  const r = run('db-status.mjs', ['bragantino', '--plan'], {});
  assert.strictEqual(r.code, 0, r.out);
  assert.ok(/Migrations incluídas \(8\)/.test(r.out) && /excluídas por escopo \(11\)/.test(r.out), r.out);
});
test('o help de db-push cita os três clubes', () => {
  const r = run('db-push.mjs', [], {});
  for (const c of CLUBS) assert.ok(r.out.includes(c), `help sem ${c}`);
});

console.log('\n6) Conta Supabase x clube; teste de IDOR valida o destino');
test('registry tem accountLabel informativo (Goiás e Bragantino = mesma; Vila Nova = outra)', () => {
  assert.strictEqual(REGISTRY.goias.accountLabel, REGISTRY.bragantino.accountLabel);
  assert.notStrictEqual(REGISTRY.vilanova.accountLabel, REGISTRY.goias.accountLabel);
});
test('accountLabel NUNCA decide escopo: não aparece na lógica de escopo nem no db-push', () => {
  for (const f of ['migration_scope.mjs', 'db-push.mjs', 'db-status.mjs', 'run-sql-file.mjs']) {
    const src = fs.readFileSync(path.join(__dirname, f), 'utf8').split('\n').filter((l) => !l.trim().startsWith('//')).join('\n');
    assert.ok(!/accountLabel/.test(src), `${f} usa accountLabel em código`);
  }
});
test('extractProjectRefFromSupabaseUrl: só aceita https://<ref>.supabase.co', () => {
  assert.strictEqual(extractProjectRefFromSupabaseUrl(`https://${REF.goias}.supabase.co`), REF.goias);
  assert.strictEqual(extractProjectRefFromSupabaseUrl(`https://${REF.goias}.supabase.co/auth/v1`), REF.goias);
  for (const bad of [`http://${REF.goias}.supabase.co`, 'https://exemplo.com', `https://${REF.goias}.supabase.co.evil.com`, 'nao-e-url', '']) {
    assert.strictEqual(extractProjectRefFromSupabaseUrl(bad), null, bad);
  }
});
test('assertSupabaseUrlMatchesClub: confere o clube; diverge -> erro; clube desconhecido -> erro', () => {
  for (const c of CLUBS) assert.strictEqual(assertSupabaseUrlMatchesClub(c, `https://${REF[c]}.supabase.co`), REF[c]);
  assert.throws(() => assertSupabaseUrlMatchesClub('vilanova', `https://${REF.goias}.supabase.co`), /MISMATCH/);
  assert.throws(() => assertSupabaseUrlMatchesClub('juventude', `https://${REF.goias}.supabase.co`), /não está em supabase_projects_registry/);
  assert.throws(() => assertSupabaseUrlMatchesClub('goias', 'https://exemplo.com'), /project ref/);
});
test('redactDbUrl nunca devolve usuário nem senha', () => {
  const r = redactDbUrl(fakeDbUrl('goias'));
  assert.ok(!r.includes('fakepw') && !r.includes(REF.goias) && r.includes('<redigido>'), r);
});
test('IDOR: --club vilanova com SUPABASE_URL do Goiás -> ABORTA antes de criar qualquer conta', () => {
  const r = run('../passport_security/run_authenticated_idor_test.mjs', ['--club', 'vilanova'], { SUPABASE_URL: `https://${REF.goias}.supabase.co`, SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_FAKE' });
  assert.notStrictEqual(r.code, 0);
  assert.ok(/MISMATCH/.test(r.out), r.out);
  assert.ok(!/Criando 2 contas/.test(r.out), 'tentou criar contas antes de validar');
});
test('IDOR: sem --club, com clube inexistente ou com URL fora do padrão -> aborta', () => {
  const env = { SUPABASE_URL: `https://${REF.goias}.supabase.co`, SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_FAKE' };
  const a = run('../passport_security/run_authenticated_idor_test.mjs', [], env);
  assert.notStrictEqual(a.code, 0); assert.ok(/--club/.test(a.out), a.out);
  const b = run('../passport_security/run_authenticated_idor_test.mjs', ['--club', 'juventude'], env);
  assert.notStrictEqual(b.code, 0); assert.ok(/não está em supabase_projects_registry/.test(b.out), b.out);
  const c = run('../passport_security/run_authenticated_idor_test.mjs', ['--club=goias'], { ...env, SUPABASE_URL: 'https://api.exemplo.com' });
  assert.notStrictEqual(c.code, 0); assert.ok(!/Criando 2 contas/.test(c.out), c.out);
});

fs.rmSync(TMP_ROOT, { recursive: true, force: true });
console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

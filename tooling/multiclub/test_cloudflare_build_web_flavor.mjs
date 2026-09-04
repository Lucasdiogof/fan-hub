// M4 — valida o script que resolve "flutter: not found" nos Cloudflare
// Workers Builds (Git integration) sem tocar em nada manual no dashboard.
// Não baixa o SDK de verdade aqui (custaria ~1GB/rede) — os 2 caminhos que
// EXIGEM Flutter de verdade (build local, dry-run wrangler) já foram
// validados manualmente nesta rodada; este teste cobre o que é
// determinístico e barato de rodar sempre: sintaxe, fail-loud, e a
// reconciliação real entre outDir/wrangler*.toml que causaria um deploy
// quebrado silenciosamente se divergisse.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const SCRIPT = path.join(ROOT, 'tool', 'cloudflare_build_web_flavor.sh');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

function runScript(args, env = {}) {
  try {
    const out = execFileSync('bash', [SCRIPT, ...args], {
      cwd: ROOT,
      env: { ...process.env, ...env },
      encoding: 'utf8',
      stdio: 'pipe',
      timeout: 15000,
    });
    return { code: 0, out };
  } catch (err) {
    return { code: err.status ?? 1, out: (err.stdout || '') + (err.stderr || '') };
  }
}

console.log('1) sintaxe bash válida');
test('bash -n tool/cloudflare_build_web_flavor.sh não acusa erro', () => {
  execFileSync('bash', ['-n', SCRIPT], { cwd: ROOT, stdio: 'pipe' });
});

console.log('\n2) fail-loud — nunca cai pra um default/latest silencioso');
test('sem argumento -> exit != 0, mensagem de uso', () => {
  const r = runScript([]);
  assert.notStrictEqual(r.code, 0);
  assert.match(r.out, /uso: bash tool\/cloudflare_build_web_flavor\.sh/);
});
test('clube desconhecido -> exit != 0, nunca resolve por fallback', () => {
  const r = runScript(['juventude']);
  assert.notStrictEqual(r.code, 0);
  assert.match(r.out, /clube desconhecido "juventude"/);
  // Se tivesse caído num fallback silencioso pro Goiás, chegaria a
  // "flutter --version"/"node tool/build_web_flavor.mjs" — nunca deve.
  assert.doesNotMatch(r.out, /flutter --version|build_web_flavor\.mjs/);
});

console.log('\n3) versão do Flutter FIXA, nunca "latest" silencioso');
const scriptSrc = fs.readFileSync(SCRIPT, 'utf8');
test('FLUTTER_VERSION é um número de versão real, não "latest"/"stable" sem versão', () => {
  const m = scriptSrc.match(/FLUTTER_VERSION="([^"]+)"/);
  assert.ok(m, 'FLUTTER_VERSION não encontrado no script');
  assert.match(m[1], /^\d+\.\d+\.\d+$/);
  assert.notStrictEqual(m[1].toLowerCase(), 'latest');
});
test('a versão fixada bate com o ambiente local usado pra desenvolver este projeto (derivada, não inventada)', () => {
  const localVersion = execFileSync('flutter', ['--version'], { encoding: 'utf8', shell: true });
  const localMatch = localVersion.match(/Flutter (\d+\.\d+\.\d+)/);
  const scriptMatch = scriptSrc.match(/FLUTTER_VERSION="([^"]+)"/);
  assert.ok(localMatch && scriptMatch);
  assert.strictEqual(scriptMatch[1], localMatch[1]);
});

console.log('\n4) reutiliza flutter do PATH quando já existe (nunca baixa por cima)');
test('shellScript checa "command -v flutter" ANTES de qualquer download', () => {
  const pathCheckIdx = scriptSrc.indexOf('command -v flutter');
  const downloadIdx = scriptSrc.indexOf('curl -fsSL');
  assert.ok(pathCheckIdx >= 0 && downloadIdx >= 0);
  assert.ok(pathCheckIdx < downloadIdx);
});
test('checa o cache local (SDK já baixado numa build anterior) antes de baixar de novo', () => {
  assert.match(scriptSrc, /if \[ -x "\$\{FLUTTER_INSTALL_DIR\}\/flutter\/bin\/flutter" \]/);
});
test('nunca instala Android SDK/Xcode (só build web)', () => {
  assert.doesNotMatch(scriptSrc, /android-sdk|xcodebuild|sdkmanager/i);
});
test('1 script genérico, nunca um por clube — recebe o clube como argumento posicional', () => {
  assert.doesNotMatch(fs.readdirSync(path.join(ROOT, 'tool')).join(','), /cloudflare_build_(goias|bragantino)\.sh/);
  assert.match(scriptSrc, /CLUB="\$\{1:-\}"/);
});

console.log('\n5) SDK do Flutter nunca versionado no repo (nem cache, nem binário)');
test('.gitignore ou ausência de rastreamento cobre qualquer diretório de cache do Flutter que viesse a ser criado localmente', () => {
  const tracked = execFileSync('git', ['ls-files'], { cwd: ROOT, encoding: 'utf8' });
  assert.doesNotMatch(tracked, /flutter-sdk-cache/);
  assert.doesNotMatch(tracked, /\.tar\.xz$/m);
});

console.log('\n6) outDir por clube reconciliado com o wrangler*.toml REAL (nunca um path adivinhado)');
const goiasFlavor = JSON.parse(fs.readFileSync(path.join(ROOT, 'tool', 'web_flavors', 'goias.json'), 'utf8'));
const bragantinoFlavor = JSON.parse(fs.readFileSync(path.join(ROOT, 'tool', 'web_flavors', 'bragantino.json'), 'utf8'));
const goiasWrangler = fs.readFileSync(path.join(ROOT, 'wrangler.toml'), 'utf8');
const bragantinoWrangler = fs.readFileSync(path.join(ROOT, 'wrangler.bragantino.toml'), 'utf8');
test('goias.json outDir bate com [assets] directory de wrangler.toml (build/web, o Cloudflare builda direto, sem o wrapper de template)', () => {
  assert.strictEqual(goiasFlavor.outDir, 'build/web');
  assert.match(goiasWrangler, /directory = "build\/web"/);
});
test('bragantino.json outDir bate com [assets] directory de wrangler.bragantino.toml', () => {
  assert.strictEqual(bragantinoFlavor.outDir, 'build/flavors/web/bragantino');
  assert.match(bragantinoWrangler, /directory = "build\/flavors\/web\/bragantino"/);
});
test('FABRICADO — um flavor sem "outDir" faz build_web_flavor.mjs falhar loud (nunca adivinha um path)', () => {
  const buildScriptSrc = fs.readFileSync(path.join(ROOT, 'tool', 'build_web_flavor.mjs'), 'utf8');
  assert.match(buildScriptSrc, /if \(!flavor\.outDir\)/);
  assert.match(buildScriptSrc, /process\.exit\(1\)/);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

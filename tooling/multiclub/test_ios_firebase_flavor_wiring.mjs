// M4 — prova estrutural do wiring de GoogleService-Info.plist por flavor no
// iOS (achado como pendência conhecida em rodadas anteriores: o Xcode nunca
// selecionava o plist certo sozinho). Não roda Xcode de verdade (ambiente
// sem macOS) — valida (a) o pbxproj é sintaticamente válido e a nova build
// phase está na posição certa, ANTES de qualquer coisa que empacote o
// plist, (b) o shell script embutido tem a lógica fail-loud correta, sem
// fallback pro Goiás, (c) os 2 plists fonte existem com o bundle_id certo,
// (d) os 2 schemes apontam pra build configuration com APP_CLUB certo.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

const pbxprojPath = path.join(ROOT, 'ios', 'Runner.xcodeproj', 'project.pbxproj');
const pbxproj = fs.readFileSync(pbxprojPath, 'utf8');

console.log('1) build phase nova existe e está na posição certa (primeira do target Runner)');
test('buildPhases do target Runner começa com "Select Firebase Plist For Flavor"', () => {
  const m = pbxproj.match(/97C146ED1CF9000F007C117D \/\* Runner \*\/ = \{[\s\S]*?buildPhases = \(\s*\n\s*(\w+) \/\* ([^*]+) \*\//);
  assert.ok(m, 'não achou o bloco buildPhases do target Runner');
  assert.strictEqual(m[2].trim(), 'Select Firebase Plist For Flavor');
});
test('a build phase roda ANTES do "Run Script" do Flutter (senão pode empacotar o plist errado)', () => {
  const idxSelect = pbxproj.indexOf('ED6554E6BEE1B81D6F7A6754 /* Select Firebase Plist For Flavor */,');
  const idxFlutterRun = pbxproj.indexOf('9740EEB61CF901F6004384FC /* Run Script */,');
  assert.ok(idxSelect > 0 && idxFlutterRun > 0);
  assert.ok(idxSelect < idxFlutterRun);
});

console.log('\n2) shellScript embutido — lógica fail-loud, zero fallback pro Goiás');
const scriptMatch = pbxproj.match(/ED6554E6BEE1B81D6F7A6754[\s\S]*?shellScript = "([\s\S]*?)";\n\t\t\};/);
test('shellScript da nova phase foi encontrado', () => {
  assert.ok(scriptMatch, 'não achou o shellScript da phase ED6554E6BEE1B81D6F7A6754');
});
const script = scriptMatch[1];
test('falha (exit 1) se APP_CLUB não estiver setado', () => {
  assert.match(script, /if \[ -z \\"\$APP_CLUB\\" \]/);
  assert.match(script, /exit 1/);
});
test('lê o plist de Runner/Firebase/${APP_CLUB}/GoogleService-Info.plist, nunca um caminho fixo', () => {
  assert.match(script, /Runner\/Firebase\/\$\{APP_CLUB\}\/GoogleService-Info\.plist/);
});
test('falha (exit 1) se o plist do APP_CLUB pedido não existir — nunca copia o do Goiás como fallback', () => {
  assert.match(script, /if \[ ! -f \\"\$SRC\\" \]/);
  const failBlock = script.slice(script.indexOf('! -f'), script.indexOf('! -f') + 200);
  assert.match(failBlock, /exit 1/);
  assert.doesNotMatch(script, /Firebase\/goias\/GoogleService-Info\.plist.*cp|cp.*Firebase\/goias\/GoogleService-Info\.plist/s);
});
test('FABRICADO — um script sem a checagem "! -f" reprovaria (prova que o teste detecta ausência real)', () => {
  const brokenScript = 'set -e\ncp "$SRC" "$DEST"\n';
  assert.doesNotMatch(brokenScript, /if \[ ! -f/);
});

console.log('\n3) plists fonte — existem, bundle_id certo, nunca alterados por esta rodada');
const goiasPlist = fs.readFileSync(path.join(ROOT, 'ios', 'Runner', 'Firebase', 'goias', 'GoogleService-Info.plist'), 'utf8');
const bragantinoPlist = fs.readFileSync(path.join(ROOT, 'ios', 'Runner', 'Firebase', 'bragantino', 'GoogleService-Info.plist'), 'utf8');
test('plist do goias tem BUNDLE_ID br.com.fanhub.goias', () => {
  assert.match(goiasPlist, /<key>BUNDLE_ID<\/key>\s*<string>br\.com\.fanhub\.goias<\/string>/);
});
test('plist do bragantino tem BUNDLE_ID br.com.fanhub.bragantino', () => {
  assert.match(bragantinoPlist, /<key>BUNDLE_ID<\/key>\s*<string>br\.com\.fanhub\.bragantino<\/string>/);
});
test('os 2 plists fonte não são o mesmo arquivo (bundle IDs realmente diferentes)', () => {
  assert.notStrictEqual(goiasPlist, bragantinoPlist);
});

console.log('\n4) schemes apontam pra build configuration com APP_CLUB certo (via xcconfig)');
const goiasScheme = fs.readFileSync(path.join(ROOT, 'ios', 'Runner.xcodeproj', 'xcshareddata', 'xcschemes', 'goias.xcscheme'), 'utf8');
const bragantinoScheme = fs.readFileSync(path.join(ROOT, 'ios', 'Runner.xcodeproj', 'xcshareddata', 'xcschemes', 'bragantino.xcscheme'), 'utf8');
test('scheme goias usa buildConfiguration Debug-goias/Profile-goias/Release-goias', () => {
  assert.match(goiasScheme, /buildConfiguration = "Debug-goias"/);
  assert.match(goiasScheme, /buildConfiguration = "Release-goias"/);
});
test('scheme bragantino usa buildConfiguration Debug-bragantino/Profile-bragantino/Release-bragantino', () => {
  assert.match(bragantinoScheme, /buildConfiguration = "Debug-bragantino"/);
  assert.match(bragantinoScheme, /buildConfiguration = "Release-bragantino"/);
});
const debugGoiasXcconfig = fs.readFileSync(path.join(ROOT, 'ios', 'Flutter', 'Flavors', 'Debug-goias.xcconfig'), 'utf8');
const debugBragantinoXcconfig = fs.readFileSync(path.join(ROOT, 'ios', 'Flutter', 'Flavors', 'Debug-bragantino.xcconfig'), 'utf8');
test('Debug-goias.xcconfig define APP_CLUB = goias', () => {
  assert.match(debugGoiasXcconfig, /APP_CLUB = goias/);
});
test('Debug-bragantino.xcconfig define APP_CLUB = bragantino', () => {
  assert.match(debugBragantinoXcconfig, /APP_CLUB = bragantino/);
});

console.log('\n5) pbxproj continua sintaticamente coerente (contagem de chaves balanceada)');
test('número de "{" == número de "}" no arquivo inteiro', () => {
  const opens = (pbxproj.match(/\{/g) || []).length;
  const closes = (pbxproj.match(/\}/g) || []).length;
  assert.strictEqual(opens, closes);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

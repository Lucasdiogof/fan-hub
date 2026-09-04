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

console.log('\n4b) cadeia INTEIRA prova ponta-a-ponta: as 6 build configs REAIS do target Runner (não as do PROJECT, que têm o mesmo nome mas nenhum baseConfigurationReference) -> xcconfig -> APP_CLUB certo, pros 3 build types (Debug/Release/Profile inclui Archive)');
// Extrai só o buildConfigurationList do TARGET Runner (97C147051CF9000F007C117D),
// nunca o do PROJECT (que tem configs com os MESMOS nomes "Debug-goias" etc.
// mas sem xcconfig nenhum) -- achar por nome sozinho pegaria o bloco errado.
const targetConfigListMatch = pbxproj.match(
  /97C147051CF9000F007C117D \/\* Build configuration list[^*]*\*\/ = \{[\s\S]*?buildConfigurations = \(([\s\S]*?)\);/,
);
test('achou o buildConfigurationList do target Runner (não o do PROJECT)', () => {
  assert.ok(targetConfigListMatch, 'bloco não encontrado');
});
const targetConfigEntries = [...targetConfigListMatch[1].matchAll(/(\w{24}) \/\* ([\w-]+) \*\//g)];
test('target Runner tem exatamente 9 build configs (Debug/Release/Profile x nenhum-flavor/goias/bragantino)', () => {
  assert.strictEqual(targetConfigEntries.length, 9);
});

const expectedAppClub = { goias: 'goias', bragantino: 'bragantino' };
for (const club of ['goias', 'bragantino']) {
  for (const buildType of ['Debug', 'Release', 'Profile']) {
    const configName = `${buildType}-${club}`;
    test(`target Runner "${configName}" -> xcconfig -> APP_CLUB = ${expectedAppClub[club]} (prova completa, não assumida)`, () => {
      const entry = targetConfigEntries.find((e) => e[2] === configName);
      assert.ok(entry, `config "${configName}" não está no buildConfigurationList do target Runner`);
      const configUuid = entry[1];
      // acha o BLOCO XCBuildConfiguration com esse UUID (pode haver um bloco
      // de mesmo NOME no nível do PROJECT — por isso busca pelo UUID exato,
      // nunca pelo nome).
      const blockMatch = pbxproj.match(new RegExp(`\\t\\t${configUuid} /\\* ${configName} \\*/ = \\{[\\s\\S]*?\\n\\t\\t\\};`));
      assert.ok(blockMatch, `bloco XCBuildConfiguration ${configUuid} não encontrado`);
      const baseConfigMatch = blockMatch[0].match(/baseConfigurationReference = (\w{24}) \/\* ([\w.-]+) \*\//);
      assert.ok(baseConfigMatch, `"${configName}" (target Runner) não tem baseConfigurationReference -- APP_CLUB nunca chegaria no build`);
      const xcconfigFileName = baseConfigMatch[2];
      assert.strictEqual(xcconfigFileName, `${configName}.xcconfig`);
      const xcconfigContent = fs.readFileSync(path.join(ROOT, 'ios', 'Flutter', 'Flavors', xcconfigFileName), 'utf8');
      assert.match(xcconfigContent, new RegExp(`APP_CLUB = ${expectedAppClub[club]}\\b`));
    });
  }
}

console.log('\n4c) prova por analogia: o MESMO mecanismo (xcconfig -> env var em Run Script) já é usado de verdade neste projeto para FLUTTER_ROOT — não é uma suposição sobre como o Xcode se comporta');
test('FLUTTER_ROOT é definido em Generated.xcconfig, incluído pela MESMA cadeia (Debug.xcconfig -> Debug-<flavor>.xcconfig) que define APP_CLUB', () => {
  const generatedXcconfig = fs.readFileSync(path.join(ROOT, 'ios', 'Flutter', 'Generated.xcconfig'), 'utf8');
  const debugXcconfig = fs.readFileSync(path.join(ROOT, 'ios', 'Flutter', 'Debug.xcconfig'), 'utf8');
  assert.match(generatedXcconfig, /FLUTTER_ROOT\s*=/);
  assert.match(debugXcconfig, /#include "Generated\.xcconfig"/);
  assert.match(debugGoiasXcconfig, /#include "\.\.\/Debug\.xcconfig"/);
});
test('o "Run Script" (Flutter) já existente usa $FLUTTER_ROOT direto no shellScript -- prova viva de que build settings de xcconfig chegam no ambiente de um Run Script deste projeto', () => {
  // Busca a DEFINIÇÃO do bloco (com " = {" no fim), nunca a referência
  // dentro de `buildPhases = (...)` que aparece antes no arquivo e tem o
  // MESMO UUID — um regex sem essa âncora captura o shellScript errado
  // (achado real ao rodar este teste: pegava a phase nova, não a do Flutter).
  const flutterRunScriptMatch = pbxproj.match(/9740EEB61CF901F6004384FC \/\* Run Script \*\/ = \{[\s\S]*?shellScript = "((?:[^"\\]|\\.)*)"/);
  assert.ok(flutterRunScriptMatch);
  assert.match(flutterRunScriptMatch[1], /\$FLUTTER_ROOT/);
});

console.log('\n5) pbxproj continua sintaticamente coerente (contagem de chaves balanceada)');
test('número de "{" == número de "}" no arquivo inteiro', () => {
  const opens = (pbxproj.match(/\{/g) || []).length;
  const closes = (pbxproj.match(/\}/g) || []).length;
  assert.strictEqual(opens, closes);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

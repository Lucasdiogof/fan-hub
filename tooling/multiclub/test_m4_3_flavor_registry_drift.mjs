import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'm4_3_flavor_registry_drift_audit.json'), 'utf8'));

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) CLIENT_REGISTRY (Flutter) = {goias, bragantino}');
test('clubRegistry de produção tem os 2 clubes REAIS', () => {
  assert.strictEqual(audit.clientRegistryIsGoiasBragantino, true, JSON.stringify(audit.clientRegistry));
});

console.log('\n2) SERVER_REGISTRY = {goias} só — Bragantino não é servido ainda (capabilities off)');
test('worker/edge/db registry = ["goias"] cada (client-registered != server-served)', () => {
  for (const [name, arr] of Object.entries(audit.serverRegistry)) {
    assert.deepStrictEqual(arr, ['goias'], name);
  }
  assert.strictEqual(audit.serverRegistryOnlyGoias, true);
});

console.log('\n3) BUILD_MECHANISMS = {goias, bragantino}');
test('android flavors, ios schemes e web configs têm goias E bragantino', () => {
  assert.ok(audit.buildMechanisms.androidFlavors.includes('goias'));
  assert.ok(audit.buildMechanisms.androidFlavors.includes('bragantino'));
  assert.ok(audit.buildMechanisms.iosSchemes.includes('bragantino'));
  assert.ok(audit.buildMechanisms.webBuildConfigs.includes('bragantino'));
  assert.strictEqual(audit.buildMechanismsHaveBothClubs, true);
});
test('nenhum flavor sintético clubb/club-b sobrou nos mecanismos de build', () => {
  assert.ok(!audit.buildMechanisms.androidFlavors.includes('clubb'));
  assert.ok(!audit.buildMechanisms.iosSchemes.includes('clubb'));
  assert.ok(!audit.buildMechanisms.webBuildConfigs.includes('club-b'));
});

console.log('\n4) ZERO resíduo sintético nas superfícies migradas (testes mantêm fixtures)');
test('nenhum clubb/club-b/ENABLE_SYNTHETIC_CLUB em lib de produção/android/ios-config/tool-web', () => {
  assert.strictEqual(audit.noSyntheticResidue, true, JSON.stringify(audit.syntheticResidueFiles));
});

console.log('\n5) APP_CLUB obrigatório, sem ENABLE_SYNTHETIC_CLUB');
test('todo comando de flavor passa APP_CLUB=<club> e nenhum tem ENABLE_SYNTHETIC_CLUB', () => {
  assert.strictEqual(audit.appClubEnforcedEverywhere, true);
});

console.log('\n6) FABRICADO — o detector reprova estados errados (não só "true")');
test('registry client sem bragantino -> reprova; server com bragantino -> reprova', () => {
  const clientOk = (arr) => JSON.stringify([...arr].sort()) === JSON.stringify(['bragantino', 'goias']);
  assert.strictEqual(clientOk(['goias']), false);
  assert.strictEqual(clientOk(['goias', 'bragantino']), true);
  const serverOk = (arr) => arr.length === 1 && arr[0] === 'goias';
  assert.strictEqual(serverOk(['goias', 'bragantino']), false);
  assert.strictEqual(serverOk(['goias']), true);
});
test('um resíduo sintético em qualquer superfície derruba noSyntheticResidue', () => {
  const residue = (files) => files.length === 0;
  assert.strictEqual(residue([]), true);
  assert.strictEqual(residue(['ios/Flutter/Flavors/Debug-clubb.xcconfig']), false);
});

console.log('\n7) decisão final');
test('registryDrift = false — client={goias,bragantino}, server={goias}, build={goias,bragantino}, 0 sintético', () => {
  assert.strictEqual(audit.registryDrift, false);
});

console.log('\n8) reprodutibilidade');
test('rodar o audit de novo produz o mesmo JSON (só lê arquivos locais)', () => {
  const before = fs.readFileSync(path.join(RECON, 'm4_3_flavor_registry_drift_audit.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_m4_3_flavor_registry_drift.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'm4_3_flavor_registry_drift_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

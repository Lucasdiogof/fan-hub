// M4 (rebrand Fan Hub) — audita, lendo os arquivos reais (nunca lista
// assumida), a consistência dos registros de clube nas várias camadas depois
// que o `club-b` sintético foi SUBSTITUÍDO pelo Bragantino REAL.
//
// Modelo NOVO (supersede o M4.3B sintético), com 3 grupos NUNCA comparados
// entre si como se fossem um só:
//   CLIENT_REGISTRY  (Flutter clubRegistry) = {goias, bragantino}
//       — o app conhece os 2 clubes reais.
//   SERVER_REGISTRY  (Worker SERVER_CLUB_CODES, Edge, DB) = {goias} SÓ
//       — o Bragantino ainda NÃO é servido no servidor (capabilities off, sem
//         dado de OneFootball/notificações/clubs row). Client-registered !=
//         server-served — comparar os dois como um só daria falso drift.
//   BUILD_MECHANISMS (Android flavors, iOS schemes, Web configs) = {goias,
//       bragantino} — cada um constrói os 2 flavors reais.
//
// E o invariante de limpeza: NENHUM resíduo sintético
// (`clubb`/`club-b`/`ENABLE_SYNTHETIC_CLUB`) nas superfícies migradas.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const LIB = path.join(ROOT, 'lib');
const SRC = path.join(ROOT, 'src');
const SUPABASE_FUNCTIONS = path.join(ROOT, 'supabase', 'functions');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const read = (p) => fs.readFileSync(p, 'utf8');
const sortedEq = (a, b) => JSON.stringify([...a].sort()) === JSON.stringify([...b].sort());

// ---- CLIENT_REGISTRY (Flutter) = {goias, bragantino} ----
const flutterProdSrc = read(path.join(LIB, 'core', 'club', 'club_registry.dart'));
const flutterClientRegistry = [...flutterProdSrc.matchAll(/'([a-z-]+)':\s*\w+ClubConfig/g)].map((m) => m[1]);
const clientRegistryIsGoiasBragantino = sortedEq(flutterClientRegistry, ['bragantino', 'goias']);

// ---- SERVER_REGISTRY = {goias} só (Bragantino não é servido ainda) ----
// SUPERSEDIDO (genericização do Worker de futebol): `SERVER_CLUB_CODES`
// (array hardcoded no código) deixou de existir — o modelo novo é 1 Worker
// deploy POR CLUBE, cada um com seu próprio `CLUB_CODE` vindo do
// `wrangler.toml` (ver club_server_config.ts). "Quais clubes este
// AMBIENTE serve" agora é "quais wrangler.*.toml têm `[vars] CLUB_CODE`
// definido" — só `wrangler.toml` (Goiás) está deployado hoje;
// `wrangler.bragantino.toml` existe mas nunca foi implantado (comentário
// no próprio arquivo confirma) — por isso continua fora do SERVER_REGISTRY
// até um deploy real acontecer.
const wranglerTomlSrc = read(path.join(ROOT, 'wrangler.toml'));
const workerClubCodeMatch = wranglerTomlSrc.match(/^CLUB_CODE\s*=\s*"([a-z-]+)"/m);
const workerRegistry = workerClubCodeMatch ? [workerClubCodeMatch[1]] : [];

const edgeSrc = read(path.join(SUPABASE_FUNCTIONS, '_shared', 'club_server_config.ts'));
const edgeRegistryNamesMatch = edgeSrc.match(/SERVER_CLUB_REGISTRY[^=]*=\s*\[([^\]]*)\]/);
const edgeConstNames = edgeRegistryNamesMatch
  ? [...edgeRegistryNamesMatch[1].matchAll(/([A-Z_]+_SERVER_CONFIG)/g)].map((m) => m[1])
  : [];
const edgeRegistry = edgeConstNames.map((c) => {
  const m = edgeSrc.match(new RegExp(`${c}[\\s\\S]*?code:\\s*'([a-z-]+)'`));
  return m ? m[1] : null;
}).filter(Boolean);

const dbSnapshotPath = path.join(RECON, 'multiclub_tenant_constraints_audit.json');
const dbSnapshotSrc = fs.existsSync(dbSnapshotPath) ? read(dbSnapshotPath) : '';
const dbConfirmedSingleClub = /clubs contém exatamente 1 linha \(Goiás\)/.test(dbSnapshotSrc);
const dbRegistry = dbConfirmedSingleClub ? ['goias'] : [];

const serverRegistrySets = { workerRegistry, edgeRegistry, dbRegistry };
const serverRegistryOnlyGoias = Object.values(serverRegistrySets).every((arr) => arr.length === 1 && arr[0] === 'goias');

// ---- BUILD_MECHANISMS = {goias, bragantino} ----
const gradleSrc = read(path.join(ROOT, 'android', 'app', 'build.gradle.kts'));
const androidFlavors = [...gradleSrc.matchAll(/create\("([a-z]+)"\)/g)].map((m) => m[1]);

const schemesDir = path.join(ROOT, 'ios', 'Runner.xcodeproj', 'xcshareddata', 'xcschemes');
const iosSchemes = fs.existsSync(schemesDir)
  ? fs.readdirSync(schemesDir).filter((f) => f.endsWith('.xcscheme')).map((f) => f.replace('.xcscheme', ''))
  : [];

const webFlavorsDir = path.join(ROOT, 'tool', 'web_flavors');
const webBuildConfigs = fs.existsSync(webFlavorsDir)
  ? fs.readdirSync(webFlavorsDir).filter((f) => f.endsWith('.json')).map((f) => f.replace('.json', ''))
  : [];

const buildMechanismSets = { androidFlavors, iosSchemes, webBuildConfigs };
const hasBoth = (arr) => arr.includes('goias') && arr.includes('bragantino');
const buildMechanismsHaveBothClubs =
  hasBoth(androidFlavors) && hasBoth(iosSchemes) && hasBoth(webBuildConfigs);

// ---- ZERO resíduo sintético nas superfícies migradas ----
// Tira comentários antes de casar — resíduo sintético só conta em CÓDIGO/
// config real, nunca em comentário que explica a REMOÇÃO do sintético.
function stripComments(s) {
  return s
    .replace(/\r/g, '')                   // normaliza CRLF (senão // não casa)
    .replace(/\/\*[\s\S]*?\*\//g, '')   // /* ... */
    .replace(/<!--[\s\S]*?-->/g, '')      // <!-- ... --> (xml/xcscheme)
    .split('\n').map((l) => l.replace(/\/\/.*/, '')).join('\n'); // // linha
}
function grepDir(dir, re, exts) {
  const hits = [];
  if (!fs.existsSync(dir)) return hits;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (/build|Pods|\.symlinks|xcuserdata|node_modules/.test(entry.name)) continue;
      hits.push(...grepDir(full, re, exts));
    } else if (exts.some((e) => entry.name.endsWith(e)) && re.test(stripComments(read(full)))) {
      hits.push(path.relative(ROOT, full));
    }
  }
  return hits;
}
// só as superfícies MIGRADAS (lib de produção, android, ios config, tool web);
// testes (test/, *.test.ts) mantêm fixtures sintéticas de propósito.
const syntheticRe = /clubb|club-b|ENABLE_SYNTHETIC_CLUB|syntheticClub/;
const syntheticResidueFiles = [
  ...grepDir(path.join(LIB, 'core', 'club'), syntheticRe, ['.dart']),
  ...grepDir(path.join(ROOT, 'android', 'app', 'src'), syntheticRe, ['.kts', '.kt', '.xml']),
  ...[path.join(ROOT, 'android', 'app', 'build.gradle.kts')].filter((f) => syntheticRe.test(stripComments(read(f)))).map((f) => path.relative(ROOT, f)),
  ...grepDir(path.join(ROOT, 'ios', 'Flutter', 'Flavors'), syntheticRe, ['.xcconfig']),
  ...grepDir(schemesDir, syntheticRe, ['.xcscheme']),
  ...grepDir(webFlavorsDir, syntheticRe, ['.json']),
  ...[path.join(ROOT, 'tool', 'build_web_flavor.mjs'), path.join(ROOT, 'tool', 'flavor_build_commands.json')]
    .filter((f) => fs.existsSync(f) && syntheticRe.test(stripComments(read(f)))).map((f) => path.relative(ROOT, f)),
];
const noSyntheticResidue = syntheticResidueFiles.length === 0;

// ---- APP_CLUB obrigatório em todo comando de flavor, sem synthetic ----
const commands = JSON.parse(read(path.join(ROOT, 'tool', 'flavor_build_commands.json')));
const cmdOk = (s, club) => new RegExp(`APP_CLUB=${club}`).test(s) && !/ENABLE_SYNTHETIC_CLUB/.test(s);
const appClubEnforcedEverywhere =
  cmdOk(commands.android.goias, 'goias') && cmdOk(commands.android.bragantino, 'bragantino') &&
  cmdOk(commands.ios.goias, 'goias') && cmdOk(commands.ios.bragantino, 'bragantino');

const registryDrift = !(
  clientRegistryIsGoiasBragantino &&
  serverRegistryOnlyGoias &&
  buildMechanismsHaveBothClubs &&
  noSyntheticResidue &&
  appClubEnforcedEverywhere
);

const audit = {
  clientRegistry: flutterClientRegistry,
  clientRegistryIsGoiasBragantino,
  serverRegistry: serverRegistrySets,
  serverRegistryOnlyGoias,
  buildMechanisms: buildMechanismSets,
  buildMechanismsHaveBothClubs,
  syntheticResidueFiles,
  noSyntheticResidue,
  appClubEnforcedEverywhere,
  registryDrift,
};

fs.mkdirSync(RECON, { recursive: true });
fs.writeFileSync(path.join(RECON, 'm4_3_flavor_registry_drift_audit.json'), JSON.stringify(audit, null, 2) + '\n');
console.log(JSON.stringify(audit, null, 2));
console.log('\nEscrito em:', RECON);

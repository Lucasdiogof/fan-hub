// M4.3B — build web por clube, reproduzível: `node tool/build_web_flavor.mjs
// <goias|bragantino|vilanova>`. Sempre injeta --dart-define=APP_CLUB=<code> (nunca conta
// com o fallback vazio->Goiás pra um flavor explícito) e, só pro sintético,
//
// `web/manifest.json`/`web/index.html`/`web/icons/*`/`web/favicon.png` são
// os arquivos REAIS que a Cloudflare (git-integrada) usa pra publicar
// produção — nunca ficam alterados permanentemente por este script. Pra
// qualquer clube (inclusive `goias`, pelo mesmo caminho de código, sem
// caso especial), o script: 1) faz backup em memória do que já está em
// `web/`; 2) escreve os valores do clube pedido (via template +
// substituição); 3) roda o build; 4) SEMPRE restaura o backup no final
// (try/finally), sucesso ou falha — o working tree nunca sai deste script
// diferente de como entrou.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const WEB = path.join(ROOT, 'web');

const club = process.argv[2];
if (!club) {
  console.error('Uso: node tool/build_web_flavor.mjs <goias|bragantino|vilanova>');
  process.exit(1);
}

const flavorConfigPath = path.join(ROOT, 'tool', 'web_flavors', `${club}.json`);
if (!fs.existsSync(flavorConfigPath)) {
  console.error(`Config de flavor não encontrada: ${flavorConfigPath}`);
  process.exit(1);
}
const flavor = JSON.parse(fs.readFileSync(flavorConfigPath, 'utf8'));

function substitute(template, flavor) {
  return template
    .replaceAll('__CLUB_APP_NAME__', flavor.appName)
    .replaceAll('__CLUB_SHORT_NAME__', flavor.shortName)
    .replaceAll('__CLUB_DESCRIPTION__', flavor.description)
    .replaceAll('__CLUB_APPLE_TITLE__', flavor.appleTitle)
    .replaceAll('__CLUB_THEME_COLOR__', flavor.themeColor)
    .replaceAll('__CLUB_THEME_LIGHT__', flavor.themeLight)
    .replaceAll('__CLUB_THEME_DARK__', flavor.themeDark);
}

const manifestTemplate = fs.readFileSync(path.join(WEB, 'manifest.template.json'), 'utf8');
const indexTemplate = fs.readFileSync(path.join(WEB, 'index.template.html'), 'utf8');

const newManifest = substitute(manifestTemplate, flavor);
const newIndex = substitute(indexTemplate, flavor);

const manifestPath = path.join(WEB, 'manifest.json');
const indexPath = path.join(WEB, 'index.html');
const iconFiles = ['Icon-192.png', 'Icon-512.png', 'Icon-maskable-192.png', 'Icon-maskable-512.png'];
const iconsDir = path.join(WEB, 'icons');
const faviconPath = path.join(WEB, 'favicon.png');

// Backup em memória — nunca em disco, pra não deixar sobra nenhuma se o
// processo morrer no meio.
const backup = {
  manifest: fs.readFileSync(manifestPath),
  index: fs.readFileSync(indexPath),
  favicon: fs.readFileSync(faviconPath),
  icons: Object.fromEntries(iconFiles.map((f) => [f, fs.readFileSync(path.join(iconsDir, f))])),
};

function restore() {
  fs.writeFileSync(manifestPath, backup.manifest);
  fs.writeFileSync(indexPath, backup.index);
  fs.writeFileSync(faviconPath, backup.favicon);
  for (const f of iconFiles) fs.writeFileSync(path.join(iconsDir, f), backup.icons[f]);
}

// `outDir` vem do JSON do flavor, NUNCA um padrão hardcoded aqui — cada
// clube tem o path que seu `wrangler*.toml` real já espera em `[assets]
// directory` (Goiás: `build/web`, o Cloudflare builda direto sem passar
// por este script, path do Flutter puro; Bragantino: `build/flavors/web/
// bragantino`, novo, nunca teve um deploy real ainda). Divergir daqui
// quebraria o deploy silenciosamente — por isso falha loud se faltar, em
// vez de inventar um path que pareça razoável.
if (!flavor.outDir) {
  console.error(`Config de flavor "${club}" não tem "outDir" — teria que adivinhar o path que o wrangler*.toml espera, nunca façemos isso. Adicione "outDir" em ${flavorConfigPath}.`);
  process.exit(1);
}
const outDir = path.join(ROOT, ...flavor.outDir.split('/'));

try {
  fs.writeFileSync(manifestPath, newManifest);
  fs.writeFileSync(indexPath, newIndex);

  if (flavor.iconsSourceDir) {
    const src = path.join(ROOT, flavor.iconsSourceDir);
    for (const f of iconFiles) fs.copyFileSync(path.join(src, f), path.join(iconsDir, f));
    fs.copyFileSync(path.join(src, 'favicon.png'), faviconPath);
  }

  const dartDefines = [`APP_CLUB=${flavor.appClub}`];

  // Qualquer argumento extra depois do nome do clube (ex.:
  // `--dart-define=API_BASE_URL=https://...`, útil pra testar o build
  // sintético servido fora do domínio do Worker, onde o fallback de
  // `resolveApiBaseUrl()` pra path relativo não funciona) passa direto pro
  // `flutter build web` — nunca hardcoded aqui, porque pra um build de
  // DEPLOY de verdade (servido pelo próprio Worker) o path relativo é o
  // comportamento CERTO, não um default a sobrescrever.
  const passthroughArgs = process.argv.slice(3);

  const args = [
    'build',
    'web',
    '--release',
    ...dartDefines.flatMap((d) => ['--dart-define', d]),
    '-o',
    outDir,
    ...passthroughArgs,
  ];

  console.log(`\n=== flutter ${args.join(' ')} ===\n`);
  execFileSync('flutter', args, { cwd: ROOT, stdio: 'inherit', shell: true });

  console.log(`\nBuild de "${flavor.code}" pronto em: ${outDir}`);
} finally {
  restore();
  console.log('web/manifest.json, web/index.html e web/icons/* restaurados pro estado do Goiás (produção).');
}

#!/usr/bin/env node
// Uso: node tooling/multiclub/db-push.mjs <goias|bragantino> [--dry-run] [--yes]
//
// Até 2026-09-04, "goias" era um write target estruturalmente impossível
// aqui (bloqueado 2x: registry.writable=false + check hardcoded). O usuário
// autorizou explicitamente nesta rodada a convergência real do schema do
// Goiás pro canonical ("a premissa antiga de bloquear escrita no Goiás não
// vale mais... eu autorizo a convergência do Goiás para o schema canônico"
// — ver docs/multiclub/53+). O hardcode foi removido; a guarda que resta é
// supabase_projects_registry.json (writable=true pros dois agora) + tudo
// abaixo continua idêntico pros dois clubes: clube explícito, env var
// obrigatória (fail-loud, nunca fallback), project ref validado contra o
// registry, --yes obrigatório pra escrita real (nunca implícito).
import { execFileSync } from 'child_process';
import { resolveTarget, printTargetBanner } from './db_target_resolver.mjs';

const clubArg = process.argv[2];
const isDryRun = process.argv.includes('--dry-run');
const hasYes = process.argv.includes('--yes');

if (!clubArg) {
  console.error('Uso: node tooling/multiclub/db-push.mjs <goias|bragantino> [--dry-run] [--yes]');
  process.exit(1);
}

let target;
try {
  target = resolveTarget(clubArg);
} catch (err) {
  console.error(err.message);
  process.exit(1);
}

if (!target.writable) {
  console.error(
    `Clube "${clubArg}" está marcado writable=false em supabase_projects_registry.json ` +
      '— write bloqueado por config, não só por código. Nunca contornar isso editando ' +
      'o registry sem entender por quê está assim.',
  );
  process.exit(1);
}

printTargetBanner(target);

if (!isDryRun && !hasYes) {
  console.error(
    '\nOperação de escrita real exige --yes explícito (nunca implícito). ' +
      'Rode com --dry-run primeiro pra ver o que seria aplicado, ou adicione ' +
      '--yes se já revisou o dry-run e quer aplicar de verdade.',
  );
  process.exit(1);
}

console.log(isDryRun ? '\n=== db push --dry-run ===' : '\n=== db push (ESCRITA REAL) ===');
const args = ['supabase', 'db', 'push', '--workdir', target.workdir, '--db-url', target.dbUrl];
if (isDryRun) args.push('--dry-run');
execFileSync('npx', args, { stdio: 'inherit', shell: true });

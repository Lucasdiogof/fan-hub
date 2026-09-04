#!/usr/bin/env node
// Uso: node tooling/multiclub/db-status.mjs <goias|bragantino>
// Só leitura — sempre `migration list`, nunca `db push`. Funciona pros 2
// clubes (Goiás é sempre permitido em leitura, só não em escrita).
import { execFileSync } from 'child_process';
import { resolveTarget, printTargetBanner } from './db_target_resolver.mjs';

const clubArg = process.argv[2];
if (!clubArg) {
  console.error('Uso: node tooling/multiclub/db-status.mjs <goias|bragantino>');
  process.exit(1);
}

let target;
try {
  target = resolveTarget(clubArg);
} catch (err) {
  console.error(err.message);
  process.exit(1);
}

printTargetBanner(target);

console.log('\n=== migration list (só leitura) ===');
execFileSync(
  'npx',
  ['supabase', 'migration', 'list', '--workdir', target.workdir, '--db-url', target.dbUrl],
  { stdio: 'inherit', shell: true },
);

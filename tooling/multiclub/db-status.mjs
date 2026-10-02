#!/usr/bin/env node
// Uso: node tooling/multiclub/db-status.mjs <goias|bragantino|vilanova> [--plan]
//
// Só leitura — sempre `migration list`, nunca `db push`. Usa a MESMA visão de
// migrations do db-push (manifesto de escopos): o recorte do clube é o
// "esperado"; o `migration list` mostra o histórico REMOTO daquele clube.
//
//   --plan   só imprime o esperado pelo manifesto (sem env var, sem conexão).
//
// Objetivo futuro: comparar automaticamente "esperado pelo manifesto" x
// "histórico remoto" de cada clube. Esta etapa só garante que o "esperado" vem
// da mesma biblioteca (migration_scope.mjs) e que o CLI enxerga o mesmo recorte.
// Interpretação hoje, manual: um clube que NÃO é do Goiás não deve listar
// versões só-Goiás no remoto.
import { spawnSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import { printTargetBanner, resolveTarget } from './db_target_resolver.mjs';
import { buildClubWorkdir, formatView, resolveForClub, ScopeError } from './migration_scope.mjs';

export const USAGE = 'Uso: node tooling/multiclub/db-status.mjs <goias|bragantino|vilanova> [--plan]';

function quoteArg(arg) {
  if (process.platform === 'win32') return `"${String(arg).replace(/"/g, '\\"')}"`;
  return `'${String(arg).replace(/'/g, `'\\''`)}'`;
}

export function main(argv = process.argv.slice(2)) {
  const planOnly = argv.includes('--plan');
  const club = argv.filter((a) => !a.startsWith('--'))[0];
  if (!club) {
    console.error(USAGE);
    return 1;
  }

  let view;
  try {
    view = resolveForClub(club);
  } catch (err) {
    console.error(err instanceof ScopeError ? err.message : err.message);
    return 1;
  }

  if (planOnly) {
    console.log(`Club: ${club}\n${formatView(view)}`);
    return 0;
  }

  let target;
  try {
    target = resolveTarget(club);
  } catch (err) {
    console.error(err.message);
    return 1;
  }
  printTargetBanner(target);
  console.log(`\nClub: ${club}\nProject ref: ${target.projectRef}\n${formatView(view)}`);

  let wd = null;
  try {
    wd = buildClubWorkdir(club);
    console.log('\n=== migration list (só leitura, recorte do clube) ===');
    const args = ['supabase', 'migration', 'list', '--workdir', wd.workdir, '--db-url', target.dbUrl];
    const r = spawnSync('npx', args.map(quoteArg), { stdio: 'inherit', shell: true });
    return r.status ?? 1;
  } catch (err) {
    console.error(err instanceof ScopeError ? err.message : `Falha: ${err.message}`);
    return 1;
  } finally {
    if (wd) wd.cleanup();
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exit(main());
}

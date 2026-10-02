#!/usr/bin/env node
// Uso: node tooling/multiclub/db-push.mjs <goias|bragantino|vilanova> [--dry-run [--remote]] [--yes]
//
//   --dry-run          PLANO LOCAL: valida alvo (env var + project ref) e escopo,
//                      mostra as migrations incluídas/excluídas, o workdir que
//                      seria criado e o comando lógico (credenciais redigidas).
//                      NÃO conecta ao banco, NÃO cria workdir, NÃO chama o CLI.
//   --dry-run --remote além do plano, roda `supabase db push --dry-run` (o CLI
//                      lê o histórico remoto; não aplica nada).
//   --yes              escrita real (nunca implícita).
//
// Fluxo (fail closed — qualquer dúvida aborta ANTES do CLI/Postgres):
//   clube -> registry -> env var + project ref validado -> manifesto de escopos
//   (supabase/migration_scopes.json) -> integridade -> migrations PERMITIDAS ->
//   workdir temporário (fora do repo) só com elas -> `supabase db push
//   --workdir <tmp> --db-url <db do clube>` -> cleanup (também se o CLI falhar).
//
// Destino = SEMPRE clube -> projectRef. Conta/organização Supabase (accountLabel
// no registry) é só informação: nunca decide onde uma migration roda. Esta
// ferramenta usa --db-url (conexão direta ao Postgres do projeto), então NÃO
// depende de `supabase login`/SUPABASE_ACCESS_TOKEN nem do projeto "linkado" em
// supabase/.temp. `supabase/migrations/` nunca é modificada.
//
// Histórico: até 2026-09-04 "goias" era write target bloqueado; a autorização
// explícita da convergência do Goiás (docs/multiclub/53+) removeu o hardcode. As
// guardas que restam são o registry (writable) + clube explícito, env var
// obrigatória (fail-loud, nunca fallback), project ref validado e --yes.
import { spawnSync } from 'child_process';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  loadProjectsRegistry,
  printTargetBanner,
  redactDbUrl,
  resolveTarget,
} from './db_target_resolver.mjs';
import { buildClubWorkdir, formatView, resolveForClub, ScopeError } from './migration_scope.mjs';

export const USAGE =
  'Uso: node tooling/multiclub/db-push.mjs <goias|bragantino|vilanova> [--dry-run [--remote]] [--yes]';

export function parseArgs(argv) {
  const flags = new Set(argv.filter((a) => a.startsWith('--')));
  const positional = argv.filter((a) => !a.startsWith('--'));
  return {
    club: positional[0],
    dryRun: flags.has('--dry-run'),
    remote: flags.has('--remote'),
    yes: flags.has('--yes'),
  };
}

/** Comando lógico (para exibir) — a URL do banco sempre redigida. */
export function logicalCommand({ workdir, dbUrl, dryRun }) {
  const parts = [
    'npx supabase db push',
    `--workdir ${workdir}`,
    `--db-url ${redactDbUrl(dbUrl)}`,
    '--skip-vault',
  ];
  if (dryRun) parts.push('--dry-run');
  return parts.join(' ');
}

function quoteArg(arg) {
  if (process.platform === 'win32') return `"${String(arg).replace(/"/g, '\\"')}"`;
  return `'${String(arg).replace(/'/g, `'\\''`)}'`;
}

function runCli(args) {
  const r = spawnSync('npx', args.map(quoteArg), { stdio: 'inherit', shell: true });
  return r.status ?? 1;
}

export function main(argv = process.argv.slice(2)) {
  const { club, dryRun, remote, yes } = parseArgs(argv);

  if (!club) {
    console.error(USAGE);
    return 1;
  }
  if (remote && !dryRun) {
    console.error('--remote só faz sentido junto com --dry-run.');
    return 1;
  }

  // 1) alvo: clube -> registry -> env var -> project ref (fail-loud)
  let target;
  try {
    target = resolveTarget(club);
  } catch (err) {
    console.error(err.message);
    return 1;
  }
  if (!target.writable) {
    console.error(
      `Clube "${club}" está marcado writable=false em supabase_projects_registry.json ` +
        '— write bloqueado por config, não só por código. Nunca contornar isso editando ' +
        'o registry sem entender por quê está assim.',
    );
    return 1;
  }
  if (!dryRun && !yes) {
    console.error(
      '\nOperação de escrita real exige --yes explícito (nunca implícito). ' +
        'Rode com --dry-run primeiro pra ver o plano, ou adicione --yes se já revisou.',
    );
    return 1;
  }

  // 2) escopo: manifesto íntegro + recorte do clube (antes de qualquer CLI/Postgres)
  let view;
  try {
    view = resolveForClub(club);
  } catch (err) {
    console.error(err instanceof ScopeError ? err.message : `Falha ao resolver escopo: ${err.message}`);
    return 1;
  }

  printTargetBanner(target);
  console.log(`\nClub:        ${club}`);
  console.log(`Project ref: ${target.projectRef}`);
  console.log(formatView(view));

  const plannedWorkdir = path.join(os.tmpdir(), `fanhub-migrations-${club}-<aleatório>`);

  // 3) plano local: nada é criado nem executado
  if (dryRun && !remote) {
    console.log('\n=== PLANO (dry-run local: sem workdir, sem CLI, sem conexão) ===');
    console.log(`workdir que seria criado: ${plannedWorkdir}`);
    console.log(`comando lógico:           ${logicalCommand({ workdir: plannedWorkdir, dbUrl: target.dbUrl, dryRun: false })}`);
    return 0;
  }

  // 4) workdir temporário + CLI (sempre com cleanup)
  let wd = null;
  try {
    wd = buildClubWorkdir(club);
    console.log(`\nworkdir temporário: ${wd.workdir}`);
    console.log(`comando:            ${logicalCommand({ workdir: wd.workdir, dbUrl: target.dbUrl, dryRun })}`);
    console.log(dryRun ? '\n=== db push --dry-run (remoto, só leitura) ===' : '\n=== db push (ESCRITA REAL) ===');
    const args = ['supabase', 'db', 'push', '--workdir', wd.workdir, '--db-url', target.dbUrl, '--skip-vault'];
    if (dryRun) args.push('--dry-run');
    return runCli(args);
  } catch (err) {
    console.error(err instanceof ScopeError ? err.message : `Falha: ${err.message}`);
    return 1;
  } finally {
    if (wd) wd.cleanup();
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  // garante que o registry existe/é legível antes de qualquer outra coisa
  loadProjectsRegistry();
  process.exit(main());
}

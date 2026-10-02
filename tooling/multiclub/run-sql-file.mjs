#!/usr/bin/env node
// Uso: node tooling/multiclub/run-sql-file.mjs <club> <arquivo.sql> [--yes]
//
// Roda um arquivo .sql INTEIRO (múltiplos statements, protocolo "simple
// query") contra o banco do clube, via `pg`. Complementa db-push.mjs (que só
// aplica `supabase/migrations/*`): serve pros arquivos de bootstrap/seed que
// vivem fora da pasta de migrations (`infra/supabase/clubs/<clube>/bootstrap.sql`,
// `supabase/<clube>_*.sql`) — o runbook manda rodar "cada arquivo inteiro, de
// uma vez", e `supabase db query --file` não aceita múltiplos statements
// (ver docs/multiclub/54_m4_convergencia_real_goias_bragantino.md item 3).
//
// Mesmas garantias de db-push.mjs/db_target_resolver.mjs: clube explícito,
// env var obrigatória (fail-loud, nunca fallback), project ref validado
// contra o registry, --yes obrigatório pra escrita real, host nunca logado
// por inteiro.
import fs from 'fs';
import path from 'path';
import { Client } from 'pg';
import { resolveTarget, printTargetBanner } from './db_target_resolver.mjs';
import { checkFileForClub } from './migration_scope.mjs';

// ESCOPO DE MIGRATIONS (A2): este script NÃO pode ser um atalho que contorna o
// manifesto supabase/migration_scopes.json. Se o arquivo for uma migration —
// por estar em supabase/migrations/ OU por ter o mesmo conteúdo (SHA normalizado)
// de uma migration do manifesto — o clube precisa estar no escopo dela, senão o
// script recusa ANTES de resolver o alvo e ANTES de abrir qualquer conexão.
// Nota: rodar uma migration por aqui NÃO registra a versão no histórico do
// Supabase (só `db push` registra). SQL que não é migration segue como antes.

const [clubArg, fileArg] = process.argv.slice(2);
const hasYes = process.argv.includes('--yes');

if (!clubArg || !fileArg) {
  console.error(
    'Uso: node tooling/multiclub/run-sql-file.mjs <club> <arquivo.sql> [--yes]',
  );
  process.exit(1);
}

const filePath = path.resolve(fileArg);
if (!fs.existsSync(filePath)) {
  console.error(`Arquivo não encontrado: ${filePath}`);
  process.exit(1);
}

// Escopo ANTES de tudo (alvo, env var, conexão). Fail closed: manifesto
// inválido, clube desconhecido ou migration fora do escopo -> aborta aqui.
let scope;
try {
  scope = checkFileForClub(filePath, clubArg);
} catch (err) {
  console.error(err.message);
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
    `Clube "${clubArg}" está marcado writable=false em supabase_projects_registry.json.`,
  );
  process.exit(1);
}

const sql = fs.readFileSync(filePath, 'utf8');

printTargetBanner(target);
console.log(`arquivo:          ${path.relative(process.cwd(), filePath)} (${sql.length} bytes)`);
console.log(
  scope.entry
    ? `escopo:           OK — migration ${scope.entry.version} [${scope.entry.scope.join('+')}] permitida em "${clubArg}"`
    : 'escopo:           n/a — SQL que não é migration do manifesto',
);

if (!hasYes) {
  console.error(
    '\nEscrita real exige --yes explícito (nunca implícito). Revise o arquivo antes.',
  );
  process.exit(1);
}

const client = new Client({
  connectionString: target.dbUrl,
  ssl: { rejectUnauthorized: false },
});

try {
  await client.connect();
  console.log('\n=== executando (protocolo simple query, múltiplos statements) ===');
  const result = await client.query(sql);
  const results = Array.isArray(result) ? result : [result];
  for (const r of results) {
    console.log(`  ${r.command ?? '?'}: ${r.rowCount ?? 0} linha(s)`);
  }
  console.log('OK.');
} catch (err) {
  console.error('\nERRO na execução:', err.message);
  process.exitCode = 1;
} finally {
  await client.end();
}

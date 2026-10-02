#!/usr/bin/env node
// Uso: node tooling/multiclub/query-sql-file.mjs <club> <arquivo.sql>
//
// Irmão SÓ DE LEITURA do run-sql-file.mjs: roda cada SELECT do arquivo dentro
// de uma transação READ ONLY (o Postgres recusa qualquer escrita) e imprime o
// resultado em tabela. Serve para diagnóstico (ex.: notificações) sem risco
// de alterar dado. Mesma resolução de alvo/env var do run-sql-file.mjs.
import fs from 'fs';
import path from 'path';
import { Client } from 'pg';
import { resolveTarget, printTargetBanner } from './db_target_resolver.mjs';

const [clubArg, fileArg] = process.argv.slice(2);
if (!clubArg || !fileArg) {
  console.error('Uso: node tooling/multiclub/query-sql-file.mjs <club> <arquivo.sql>');
  process.exit(1);
}

let target;
try {
  target = resolveTarget(clubArg);
} catch (err) {
  console.error(err.message);
  process.exit(1);
}

const filePath = path.resolve(fileArg);
if (!fs.existsSync(filePath)) {
  console.error(`Arquivo não encontrado: ${filePath}`);
  process.exit(1);
}
// Um SELECT por bloco, separados por linha com "-- ##" + título.
const blocks = fs
  .readFileSync(filePath, 'utf8')
  .split(/^-- ## /m)
  .map((b) => b.trim())
  .filter((b) => b && !b.startsWith('--'))
  .map((b) => {
    const nl = b.indexOf('\n');
    return { title: b.slice(0, nl).trim(), sql: b.slice(nl + 1).trim() };
  });

printTargetBanner(target);

const client = new Client({ connectionString: target.dbUrl, ssl: { rejectUnauthorized: false } });
try {
  await client.connect();
  await client.query('begin transaction read only');
  for (const { title, sql } of blocks) {
    console.log(`\n=== ${title} ===`);
    try {
      const r = await client.query(sql);
      if (!r.rows.length) console.log('  (nenhuma linha)');
      else console.table(r.rows);
    } catch (err) {
      console.log(`  ERRO: ${err.message}`);
      await client.query('rollback');
      await client.query('begin transaction read only');
    }
  }
  await client.query('rollback');
} catch (err) {
  console.error('\nERRO:', err.message);
  process.exitCode = 1;
} finally {
  await client.end();
}

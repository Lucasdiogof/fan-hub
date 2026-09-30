#!/usr/bin/env node
// Roda as mesmas checagens do simulador (tooling/vilanova_seeds/checks.mjs)
// contra o banco REMOTO de verdade, via VILANOVA_DB_URL. Só leitura.
import { Client } from 'pg';
import { resolveTarget } from './db_target_resolver.mjs';

const target = resolveTarget('vilanova');
const client = new Client({ connectionString: target.dbUrl, ssl: { rejectUnauthorized: false } });
await client.connect();
const q = async (sql) => (await client.query(sql)).rows;
const dbShim = { exec: (sql) => client.query(sql) };
const checks = (await import('../vilanova_seeds/checks.mjs')).default;
await checks(q, dbShim);
await client.end();

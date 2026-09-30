// Simula um projeto Supabase NOVO do Vila Nova num Postgres de verdade em
// WebAssembly (PGlite, sem instalar nada no sistema): stubs mínimos do
// Supabase (auth/storage/papéis) + canonical baseline + todas as migrations +
// bootstrap do Vila + os seeds passados, na ordem do runbook
// (docs/multiclub/60_vilanova_seeds_runbook.md). Para no primeiro erro.
//
//   npm i --no-save @electric-sql/pglite
//   node tooling/vilanova_seeds/simulate_fresh_project.mjs supabase/vilanova_passport_infra.sql ...
//   CHECKS=tooling/vilanova_seeds/checks.mjs node tooling/vilanova_seeds/simulate_fresh_project.mjs <seeds...>
import { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const db = new PGlite();

const STUBS = `
do $$ begin
  create role anon; exception when duplicate_object then null; end $$;
do $$ begin create role authenticated; exception when duplicate_object then null; end $$;
do $$ begin create role service_role; exception when duplicate_object then null; end $$;
do $$ begin create role supabase_admin; exception when duplicate_object then null; end $$;
do $$ begin create role postgres_fdw; exception when duplicate_object then null; end $$;
create schema if not exists auth;
create schema if not exists extensions;
create schema if not exists storage;
create table if not exists auth.users (id uuid primary key, email text, raw_user_meta_data jsonb, created_at timestamptz default now(), email_confirmed_at timestamptz, last_sign_in_at timestamptz);
create or replace function auth.uid() returns uuid language sql stable as $f$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $f$;
create or replace function auth.role() returns text language sql stable as $f$ select current_setting('request.jwt.claim.role', true) $f$;
create or replace function auth.jwt() returns jsonb language sql stable as $f$ select coalesce(current_setting('request.jwt.claims', true), '{}')::jsonb $f$;
create table if not exists storage.buckets (id text primary key, name text, public boolean);
create table if not exists storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text, owner uuid);
create or replace function storage.foldername(name text) returns text[] language sql immutable as $f$ select string_to_array(name, '/') $f$;
create or replace function storage.filename(name text) returns text language sql immutable as $f$ select (string_to_array(name, '/'))[array_length(string_to_array(name, '/'),1)] $f$;
create or replace function storage.extension(name text) returns text language sql immutable as $f$ select split_part(name, '.', 2) $f$;
`;

async function run(label, sql) {
  try {
    await db.exec(sql);
    console.log(`OK   ${label}`);
    return true;
  } catch (e) {
    console.log(`FAIL ${label}: ${e.message}`);
    const pos = e.position ? Number(e.position) : null;
    if (pos) console.log('     ...' + sql.slice(Math.max(0, pos - 200), pos + 100).replace(/\n/g, '\n     '));
    return false;
  }
}

await run('stubs supabase', STUBS);
const migDir = path.join(REPO, 'supabase/migrations');
for (const f of fs.readdirSync(migDir).filter((f) => f.endsWith('.sql')).sort()) {
  if (!(await run(`migration ${f}`, fs.readFileSync(path.join(migDir, f), 'utf8')))) process.exit(1);
}
await run('bootstrap vilanova', fs.readFileSync(path.join(REPO, 'infra/supabase/clubs/vilanova/bootstrap.sql'), 'utf8'));
for (const f of process.argv.slice(2)) {
  if (!(await run(path.basename(f), fs.readFileSync(path.resolve(REPO, f), 'utf8')))) process.exit(1);
}
const q = async (sql) => (await db.query(sql)).rows;
console.log(JSON.stringify(await q(`select slug, id from public.clubs`)));
globalThis.db = db;
if (process.env.CHECKS) {
  const { pathToFileURL } = await import('node:url');
  const checks = (await import(pathToFileURL(path.resolve(process.env.CHECKS)).href)).default;
  await checks(q, db);
}

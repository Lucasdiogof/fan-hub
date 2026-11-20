// Teste da migration football_snapshots no PGlite. Uso: npm i --no-save @electric-sql/pglite && node tooling/multiclub/test_football_snapshots_sql.mjs
import { PGlite } from '@electric-sql/pglite';
import fs from 'fs';
const db = new PGlite();
await db.exec(`create role anon; create role authenticated; create role service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;
create table public.clubs(id uuid primary key, slug text);
insert into public.clubs values ('00000000-0000-0000-0000-000000000001','a');`);
const sql = fs.readFileSync(''+new URL('../../supabase',import.meta.url).pathname.slice(1)+'/migrations/20261120010000_football_snapshots.sql','utf8');
await db.exec(sql); await db.exec(sql); // idempotente
// Com os default privileges do Supabase simulados acima, anon/authenticated NÃO podem escrever.
for (const role of ['anon', 'authenticated']) {
  await db.exec(`set role ${role}`);
  for (const w of [
    "insert into football_snapshots(club_id,kind,payload) values (gen_random_uuid(),'team','{}'::jsonb)",
    "update football_snapshots set payload='{}'::jsonb",
    'delete from football_snapshots',
  ]) {
    try { await db.query(w); console.log('FALHA: escrita direta permitida'); process.exit(1); }
    catch (e) { console.log(role, 'escrita direta bloqueada:', e.message.slice(0, 45)); }
  }
  await db.exec('reset role');
}
const c='00000000-0000-0000-0000-000000000001';
const q=async s=>JSON.stringify((await db.query(s)).rows[0]);
console.log('absent', await q(`select get_football_snapshot('${c}','team')`));
await db.exec(`insert into football_snapshots(club_id,kind,key,payload,fetched_at,next_refresh_at,expires_at) values ('${c}','team','default','{"a":1}', now()-interval '10 min', now()-interval '5 min', now()+interval '1 hour')`);
console.log('stale', await q(`select get_football_snapshot('${c}','team','')`));
await db.exec(`update football_snapshots set next_refresh_at=now()+interval '5 min'`);
console.log('fresh', await q(`select get_football_snapshot('${c}','team')`));
await db.exec(`update football_snapshots set expires_at=now()-interval '1 s'`);
console.log('expired', await q(`select get_football_snapshot('${c}','team')`));
try{await db.query(`select get_football_snapshot('${c}','hax')`)}catch(e){console.log('badkind', e.message)}
try{await db.query(`insert into football_snapshots(club_id,kind,key,payload) values ('${c}','nope','default','{}')`)}catch(e){console.log('check', e.message)}
await db.exec(`set role anon`);
try{await db.query(`select * from football_snapshots`)}catch(e){console.log('anon table', e.message)}
console.log('anon rpc', await q(`select get_football_snapshot('${c}','team')`));
await db.exec('reset role');
await db.exec(`update football_snapshots set next_refresh_at=null, expires_at=now()+interval '1 day'`);
const nul = (await db.query(`select get_football_snapshot('${c}','team')`)).rows[0].get_football_snapshot;
console.log('null next_refresh_at -> stale:', nul.stale, nul.expired);
if (nul.stale !== false || nul.expired !== false) process.exit(1);

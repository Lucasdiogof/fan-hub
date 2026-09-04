import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const MIGRATIONS = path.join(ROOT, 'archive', 'supabase', 'goias-legacy-migrations', 'files');

const tenantAudit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_tenant_constraints_audit.json'), 'utf8'));
const rowCounts = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_m2_2a_row_counts.json'), 'utf8'));
const plan = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_m2_2a_plan.json'), 'utf8'));

const FILES = {
  A_content: '20260902220000_add_multiclub_content_tenant_scope.sql',
  B1_arena_quiz_identity: '20260902230000_add_multiclub_arena_quiz_progress_tenant_scope.sql',
  B2_career_lineup_votes: '20260902240000_add_multiclub_career_lineup_progress_tenant_scope.sql',
  B3_tickets_store: '20260902250000_add_multiclub_tickets_store_tenant_scope.sql',
  C_membership: '20260902260000_add_multiclub_membership_tenant_scope.sql',
  D_notifications: '20260902270000_add_multiclub_notifications_tenant_scope.sql',
};
const sqlByGroup = Object.fromEntries(
  Object.entries(FILES).map(([g, f]) => [g, fs.readFileSync(path.join(MIGRATIONS, f), 'utf8')])
);
const allSql = Object.values(sqlByGroup).join('\n');
const GOIAS = plan.goiasClubId;

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}
function stripComments(sql) {
  return sql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n');
}

// ============================================================================
// 1) Elegibilidade derivada da M2.1 — nunca lista cega
// ============================================================================
console.log('1) elegibilidade das 24 tabelas, derivada do audit M2.1');
test('24 tabelas elegíveis: rowScopeProblem=true, exclui passport/INHERITS_FROM_*/KEEP_GLOBAL', () => {
  const expected = tenantAudit.tables.filter((t) => {
    if (!t.rowScopeProblem) return false;
    if (t.tenantStrategy?.startsWith('INHERITS_FROM_')) return false;
    if (t.tenantStrategy === 'KEEP_GLOBAL') return false;
    if (['passport_matches', 'passport_attendances', 'passport_memorable_matches'].includes(t.table)) return false;
    return true;
  }).map((t) => t.table).sort();
  const planTables = Object.values(plan.groups).flat().map((e) => e.table).sort();
  assert.deepStrictEqual(planTables, expected);
  assert.strictEqual(planTables.length, 24);
});
test('8 tabelas excluídas, cada uma com razão explícita e correta', () => {
  assert.strictEqual(plan.excludedTables.length, 8);
  const byTable = Object.fromEntries(plan.excludedTables.map((e) => [e.table, e.reason]));
  assert.strictEqual(byTable['passport_matches'], 'PASSPORT_OUT_OF_SCOPE_THIS_ROUND');
  assert.strictEqual(byTable['passport_attendances'], 'PASSPORT_OUT_OF_SCOPE_THIS_ROUND');
  assert.strictEqual(byTable['passport_memorable_matches'], 'PASSPORT_OUT_OF_SCOPE_THIS_ROUND');
  assert.strictEqual(byTable['store_order_items'], 'NO_ROW_SCOPE_PROBLEM');
  assert.strictEqual(byTable['user_notification_tokens'], 'NO_ROW_SCOPE_PROBLEM');
  assert.strictEqual(byTable['notification_deliveries'], 'NO_ROW_SCOPE_PROBLEM');
  assert.strictEqual(byTable['profiles'], 'NO_ROW_SCOPE_PROBLEM');
  assert.strictEqual(byTable['delivery_addresses'], 'NO_ROW_SCOPE_PROBLEM');
});
test('supporter_memberships (CRITICAL da M2.1) está incluída', () => {
  const all = Object.values(plan.groups).flat().map((e) => e.table);
  assert.ok(all.includes('supporter_memberships'));
  const criticalTables = tenantAudit.tables.filter((t) => t.critical === true).map((t) => t.table);
  assert.deepStrictEqual(criticalTables, ['supporter_memberships']);
});
test('grupos batem 5/8/3/4/1/3 = 24', () => {
  assert.strictEqual(plan.groups.A_content.length, 5);
  assert.strictEqual(plan.groups.B1_arena_quiz_identity.length, 8);
  assert.strictEqual(plan.groups.B2_career_lineup_votes.length, 3);
  assert.strictEqual(plan.groups.B3_tickets_store.length, 4);
  assert.strictEqual(plan.groups.C_membership.length, 1);
  assert.strictEqual(plan.groups.D_notifications.length, 3);
});

// ============================================================================
// 2) club_id é uuid, FK clubs(id), default Goiás correto
// ============================================================================
console.log('\n2) tipo/FK/default de club_id em todas as 24 tabelas');
test('24 ALTER TABLE ... ADD COLUMN club_id uuid not null default <Goiás>::uuid references public.clubs (id)', () => {
  const pattern = new RegExp(`alter table public\\.(\\w+)\\s+add column club_id uuid not null default '${GOIAS}'::uuid\\s+references public\\.clubs \\(id\\);`, 'g');
  const matches = [...allSql.matchAll(pattern)];
  assert.strictEqual(matches.length, 24, `esperava 24 ADD COLUMN club_id, achei ${matches.length}`);
  const tables = matches.map((m) => m[1]).sort();
  const expected = Object.values(plan.groups).flat().map((e) => e.table).sort();
  assert.deepStrictEqual(tables, expected);
});
test('nenhuma tabela usa um club_id diferente de Goiás como default', () => {
  const wrongDefault = [...allSql.matchAll(/add column club_id uuid not null default '([0-9a-f-]{36})'::uuid/g)]
    .map((m) => m[1]).filter((id) => id !== GOIAS);
  assert.deepStrictEqual(wrongDefault, []);
});
test('índice club_id criado pra cada uma das 24 tabelas', () => {
  const idxCount = [...allSql.matchAll(/create index if not exists \w+_club_id_idx on public\.\w+ \(club_id\);/g)].length;
  assert.strictEqual(idxCount, 24);
});

// ============================================================================
// 3) Nenhuma PK/UNIQUE antiga alterada ou removida (M2.2B, não agora)
// ============================================================================
console.log('\n3) PKs/UNIQUEs legadas preservadas — só ADD COLUMN');
test('nenhum DROP CONSTRAINT / DROP COLUMN / ALTER COLUMN em nenhum dos 6 arquivos', () => {
  const body = stripComments(allSql);
  assert.doesNotMatch(body, /drop constraint/i);
  assert.doesNotMatch(body, /drop column/i);
  assert.doesNotMatch(body, /alter column/i);
  assert.doesNotMatch(body, /drop table/i);
});
test('nenhum "primary key"/"unique" além do que já existe hoje — 0 ocorrência de PRIMARY KEY/UNIQUE nestas migrations', () => {
  const body = stripComments(allSql);
  assert.doesNotMatch(body, /\bprimary key\b/i);
  assert.doesNotMatch(body, /\bunique\s*\(/i);
});
test('a única ação de DDL em cada bloco é "alter table ... add column" (mais os índices/checagens) — nenhum outro ALTER', () => {
  const body = stripComments(allSql);
  const alterMatches = [...body.matchAll(/alter table[^;]*;/gis)];
  for (const m of alterMatches) assert.match(m[0], /add column club_id/i, `ALTER inesperado: ${m[0].slice(0, 80)}`);
});

// ============================================================================
// 4) Passaporte intocado
// ============================================================================
console.log('\n4) Passaporte fora de escopo — 0 menção nas migrations');
test('nenhuma das 6 migrations referencia passport_matches/passport_attendances/passport_memorable_matches', () => {
  assert.doesNotMatch(allSql, /passport_matches/i);
  assert.doesNotMatch(allSql, /passport_attendances/i);
  assert.doesNotMatch(allSql, /passport_memorable_matches/i);
});

// ============================================================================
// 5) Nenhum dado de negócio tocado — 0 INSERT/UPDATE/DELETE/TRUNCATE
// ============================================================================
console.log('\n5) zero mudança de dado de negócio — só a coluna club_id');
test('0 INSERT em qualquer uma das 6 migrations', () => {
  assert.doesNotMatch(stripComments(allSql), /\binsert into\b/i);
});
test('0 UPDATE em qualquer uma das 6 migrations (a estratégia ADD COLUMN DEFAULT não precisa de nenhum backfill escrito à mão)', () => {
  assert.doesNotMatch(stripComments(allSql), /\bupdate\s+public\./i);
});
test('0 DELETE em qualquer uma das 6 migrations', () => {
  assert.doesNotMatch(stripComments(allSql), /\bdelete from\b/i);
});
test('0 TRUNCATE em qualquer uma das 6 migrations', () => {
  assert.doesNotMatch(stripComments(allSql), /\btruncate\b/i);
});
test('F1-F7: nenhuma menção a person_id/answer/lineup/score/membership_dates como algo sendo alterado (grep negativo de colunas de conteúdo em contexto de SET)', () => {
  assert.doesNotMatch(allSql, /set\s+person_id/i);
  assert.doesNotMatch(allSql, /set\s+answer/i);
  assert.doesNotMatch(allSql, /set\s+lineup/i);
});

// ============================================================================
// 6) 0 namespace de id legado (ex.: 'goias:' + id) — nunca essa estratégia
// ============================================================================
console.log('\n6) 0 namespace de IDs legados');
test('nenhuma migration concatena um prefixo de clube no id legado', () => {
  assert.doesNotMatch(allSql, /'goias:'/i);
  assert.doesNotMatch(allSql, /\|\|\s*id\b/i);
});

// ============================================================================
// 7) Nenhuma RPC tocada nesta rodada — assinaturas antigas preservadas por
//    não existirem (0 CREATE/DROP FUNCTION nos 6 arquivos)
// ============================================================================
console.log('\n7) 0 RPC alterada — compatibilidade proposta apenas no relatório, não implementada');
test('nenhuma das 6 migrations cria/substitui/remove função (get_my_membership, arena_record_score, crowd_lineup etc. continuam byte-idênticas)', () => {
  assert.doesNotMatch(allSql, /create (or replace )?function/i);
  assert.doesNotMatch(allSql, /drop function/i);
});

// ============================================================================
// 8) Idempotência — cada bloco aborta se club_id já existir
// ============================================================================
console.log('\n8) guarda de idempotência em todas as 24 tabelas');
test('24 checagens de information_schema.columns (uma por tabela) antes de qualquer ADD COLUMN', () => {
  const checks = [...allSql.matchAll(/select 1 from information_schema\.columns\s*\n\s*where table_schema = 'public' and table_name = '(\w+)' and column_name = 'club_id'/g)];
  assert.strictEqual(checks.length, 24);
});

// ============================================================================
// 9) Rodada de revisão (2026-09-02): NENHUMA precondition/postcondition
//    executável compara count(*) contra o snapshot congelado — tabelas
//    vivas não podem ter uma migration que falha por atividade normal do
//    usuário entre a geração e o push. Só checagens semânticas (clubs=1+
//    slug, idempotência, NULL/órfão/não-Goiás no estado REAL) sobrevivem.
// ============================================================================
console.log('\n9) guards NUNCA comparam count(*) contra o snapshot congelado (só semânticos)');
test('nenhuma migration faz "select count(*) into v_n from public.<table>" seguido de comparação contra um literal (o padrão antigo removido)', () => {
  const body = stripComments(allSql);
  assert.doesNotMatch(body, /select count\(\*\) into v_n from public\.\w+;\s*\n\s*if v_n <> \d+ then/);
});
test('as únicas comparações "count(*) into v_x ... if v_x <> N" restantes são clubs_count<>1 (precondition global) e as pós-condições semânticas (sempre <> 0, nunca um N arbitrário)', () => {
  const body = stripComments(allSql);
  const comparisons = [...body.matchAll(/if (v_\w+) <> (\d+) then/g)].map((m) => ({ varName: m[1], n: Number(m[2]) }));
  for (const c of comparisons) {
    if (c.varName === 'v_clubs_count') { assert.strictEqual(c.n, 1); continue; }
    assert.strictEqual(c.n, 0, `${c.varName} comparado contra ${c.n}, esperava 0 (pós-condição semântica) ou ser v_clubs_count`);
  }
  // as 3 pós-condições por tabela (null/órfão/não-Goiás) × 24 tabelas + 1 clubs_count global × 6 arquivos
  assert.strictEqual(comparisons.filter((c) => c.varName === 'v_clubs_count').length, 6);
  assert.strictEqual(comparisons.filter((c) => c.varName !== 'v_clubs_count').length, 24 * 3);
});
test('precondition global usa id E slug do clube Goiás (não só o UUID isolado) em cada um dos 6 arquivos', () => {
  for (const sql of Object.values(sqlByGroup)) {
    assert.match(sql, /select count\(\*\) into v_clubs_count from public\.clubs;/);
    assert.match(sql, /if v_clubs_count <> 1 then/);
    assert.match(sql, new RegExp(`where id = '${GOIAS}'::uuid and slug = 'goias'`));
  }
});
test('pós-condição usa club_id <> Goiás (estado real da transação), nunca um count(*) total comparado contra o snapshot', () => {
  const nonGoiasChecks = [...allSql.matchAll(/select count\(\*\) into v_non_goias_count from public\.(\w+) where club_id <> '[0-9a-f-]{36}'::uuid;/g)];
  assert.strictEqual(nonGoiasChecks.length, 24);
});
test('snapshot (multiclub_m2_2a_row_counts.json) continua existindo como auditoria/evidência — só não controla mais se a migration roda', () => {
  assert.ok(fs.existsSync(path.join(RECON, 'multiclub_m2_2a_row_counts.json')));
  assert.strictEqual(Object.keys(rowCounts.counts).length, 32);
});
test('0 é um snapshot válido e aparece explicitamente onde é o caso (ex.: supporter_memberships, tickets, ticket_orders, store_orders, arena_achievements, notification_events, user_notification_preferences)', () => {
  const zeroTables = ['supporter_memberships', 'tickets', 'ticket_orders', 'store_orders', 'arena_achievements', 'notification_events', 'user_notification_preferences'];
  for (const t of zeroTables) assert.strictEqual(rowCounts.counts[t], 0, `${t} deveria ter snapshot 0`);
});

// ============================================================================
// 9b) Indexes — só plain index(club_id), nunca composto/UNIQUE (isso é M2.2B)
// ============================================================================
console.log('\n9b) índices novos são plain B-tree single-column, nunca antecipam KEY_SCOPE');
test('as 24 criações de índice são todas "create index if not exists <table>_club_id_idx on public.<table> (club_id)" — nunca UNIQUE, nunca composto', () => {
  const idx = [...allSql.matchAll(/create index if not exists (\w+)_club_id_idx on public\.(\w+) \(club_id\);/g)];
  assert.strictEqual(idx.length, 24);
  for (const m of idx) assert.strictEqual(m[1], m[2]);
  assert.doesNotMatch(allSql, /create unique index/i);
  assert.doesNotMatch(allSql, /\(club_id,\s*\w+\)/); // nenhum índice composto (club_id, outra_coluna)
});

// ============================================================================
// 10) Reprodutibilidade
// ============================================================================
console.log('\n10) reprodutibilidade — plano e migrations byte-idênticos ao rodar de novo');
test('rodar build_multiclub_m2_2a_plan.mjs de novo produz o mesmo JSON', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_m2_2a_plan.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'build_multiclub_m2_2a_plan.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_m2_2a_plan.json'), 'utf8');
  assert.strictEqual(before, after);
});
test('rodar generate_multiclub_m2_2a_migrations.mjs de novo produz os 6 arquivos byte-idênticos', () => {
  const before = Object.fromEntries(Object.entries(FILES).map(([g, f]) => [g, fs.readFileSync(path.join(MIGRATIONS, f), 'utf8')]));
  execFileSync(process.execPath, [path.join(__dirname, 'generate_multiclub_m2_2a_migrations.mjs')], { cwd: ROOT });
  for (const [g, f] of Object.entries(FILES)) {
    const after = fs.readFileSync(path.join(MIGRATIONS, f), 'utf8');
    assert.strictEqual(before[g], after, `${f} não é determinístico`);
  }
});

// ============================================================================
// 11) Nomenclatura e contagem de migrations
// ============================================================================
console.log('\n11) nomenclatura clara, timestamps sequenciais após as 35 existentes');
test('6 arquivos novos, timestamps 20260902220000..270000, nomes descritivos (nunca "fix_multiclub"/"migration36")', () => {
  const names = Object.values(FILES);
  assert.strictEqual(names.length, 6);
  for (const n of names) {
    assert.doesNotMatch(n, /^migration\d+/);
    assert.doesNotMatch(n, /^fix_multiclub/);
    assert.match(n, /^\d{14}_add_multiclub_\w+_tenant_scope\.sql$/);
  }
  const timestamps = names.map((n) => n.slice(0, 14));
  assert.deepStrictEqual(timestamps, ['20260902220000', '20260902230000', '20260902240000', '20260902250000', '20260902260000', '20260902270000']);
});
test('todos os arquivos de migration existentes até 20260902210000 continuam presentes (35 anteriores, intocados)', () => {
  const all = fs.readdirSync(MIGRATIONS).filter((f) => f.endsWith('.sql'));
  const preExisting = all.filter((f) => f <= '20260902210000_z');
  assert.strictEqual(preExisting.length, 35);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');
const SCRIPT = path.join(__dirname, 'audit_multiclub_tenant_constraints.mjs');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_tenant_constraints_audit.json'), 'utf8'));
const stats = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_tenant_constraints_stats.json'), 'utf8'));
const tbl = (name) => audit.tables.find((t) => t.table === name);

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

console.log('1) universo verificado contra o schema real, 0 stale');
test('0 tabelas stale — todo padrão citado ainda existe no .sql real', () => {
  assert.strictEqual(stats.stale, 0, JSON.stringify(stats.staleList));
});
test('INVARIANTE: sum(groupCounts) === totalTables === 32, e verified === total (nenhuma tabela cai fora do universo)', () => {
  assert.strictEqual(stats.totalTables, 32, `total=${stats.totalTables}`);
  assert.strictEqual(stats.verified, stats.totalTables, `verified=${stats.verified} total=${stats.totalTables}`);
  assert.strictEqual(stats.classificationSum, 32, `somaGrupos=${stats.classificationSum}`);
  assert.strictEqual(stats.byGroup.PROGRESS, 18, `PROGRESS=${stats.byGroup.PROGRESS} (deve ser 18)`);
  assert.deepStrictEqual(stats.byGroup, { CONTENT: 6, PROGRESS: 18, MEMBERSHIP: 1, NOTIFICATIONS: 5, USER_GLOBAL: 2 });
});
test('universo M2.1 é maior que a lista do item 10 — descobriu tabelas não presumidas (identity results, notification_events/deliveries, prefs, memorable_matches, store_order_items)', () => {
  for (const t of ['player_identity_results', 'tactical_identity_results', 'notification_events', 'notification_deliveries', 'user_notification_preferences', 'passport_memorable_matches', 'store_order_items']) {
    assert.ok(tbl(t), `esperava ${t} no universo auditado`);
  }
});

console.log('\n2) membership CRITICAL');
test('supporter_memberships é a ÚNICA tabela CRITICAL, e get_my_membership() é citado sem filtro de clube', () => {
  assert.deepStrictEqual(stats.criticalTables, ['supporter_memberships']);
  const m = tbl('supporter_memberships');
  assert.match(m.rpcReads.join(' '), /get_my_membership/);
  assert.match(m.rpcReads.join(' '), /SEM filtro de clube|order by created_at desc/);
  assert.strictEqual(m.tenantStrategy.startsWith('TENANT_COLUMN_ONLY'), true);
});

console.log('\n3) passaporte — NEEDS_PRODUCT_DECISION (A/B/C), nunca migration mecânica');
test('passport_matches é a ÚNICA NEEDS_PRODUCT_DECISION (schema assimétrico + 2 FKs reais)', () => {
  assert.deepStrictEqual(stats.needsProductDecisionTables, ['passport_matches']);
  const p = tbl('passport_matches');
  assert.strictEqual(p.inboundFks.length, 2);
  assert.ok(p.inboundFks.some((f) => f.from.startsWith('passport_attendances')));
  assert.ok(p.inboundFks.some((f) => f.from.startsWith('passport_memorable_matches')));
});
test('passport_memorable_matches é o nome REAL da 2ª tabela dependente (não "passport_trajectory", que é a feature Flutter) — correção sobre o relatório M1', () => {
  assert.ok(tbl('passport_memorable_matches'), 'passport_memorable_matches deveria estar no universo');
  assert.ok(!tbl('passport_trajectory'), 'não deveria existir uma tabela chamada passport_trajectory');
  assert.strictEqual(tbl('passport_memorable_matches').tenantStrategy, 'INHERITS_FROM_PASSPORT_MATCHES');
});

console.log('\n4) UNIQUE classificado (item 13) — nem toda UNIQUE precisa mudar');
test('as 3 tabelas de conteúdo "de pessoa" têm UNIQUE(person_id) classificado NEEDS_CLUB_SCOPE com candidato unique(club_id, person_id)', () => {
  assert.deepStrictEqual([...stats.personIdContentTables].sort(), ['career_players', 'guess_players', 'squad_members']);
  for (const name of ['career_players', 'guess_players', 'squad_members']) {
    const u = tbl(name).uniques.find((c) => c.cols.length === 1 && c.cols[0] === 'person_id');
    assert.ok(u, `${name} deveria ter UNIQUE(person_id)`);
    assert.strictEqual(u.class, 'NEEDS_CLUB_SCOPE');
    assert.match(u.future, /club_id, person_id/);
  }
});
test('order_number e fcm_token são KEEP_GLOBAL (unicidade global legítima, NÃO viram problema de KEY_SCOPE)', () => {
  const order = tbl('store_orders').uniques.find((u) => u.cols.includes('order_number'));
  const fcm = tbl('user_notification_tokens').uniques.find((u) => u.cols.includes('fcm_token'));
  assert.strictEqual(order.class, 'KEEP_GLOBAL');
  assert.strictEqual(fcm.class, 'KEEP_GLOBAL');
  assert.strictEqual(tbl('store_orders').keyScopeProblem, false);
  assert.strictEqual(tbl('user_notification_tokens').keyScopeProblem, false);
});
test('notification_events.dedupe_key é NEEDS_REDESIGN_OR_NAMESPACE — dedupe GLOBAL colidiria eventos de 2 clubes (achado item 21)', () => {
  const u = tbl('notification_events').uniques.find((c) => c.cols.includes('dedupe_key'));
  assert.strictEqual(u.class, 'NEEDS_REDESIGN_OR_NAMESPACE');
  assert.strictEqual(tbl('notification_events').keyScopeProblem, true);
});

console.log('\n5) cadeias de progresso — club_id tem de viajar a cadeia INTEIRA + a RPC');
test('arena_record_score aparece em toda cadeia de jogo da Arena com p_club_id no destino', () => {
  const arenaGames = audit.progressChains.filter((c) => c.rpc && c.rpc.includes('arena_record_score'));
  assert.ok(arenaGames.length >= 4, 'esperava >=4 jogos da Arena');
  for (const c of arenaGames) {
    assert.ok(c.clubIdMustTravel.some((x) => x.includes('arena_record_score(p_club_id)')), `${c.game}: RPC precisa de p_club_id`);
    assert.ok(c.clubIdMustTravel.includes('user_game_item_progress') || c.clubIdMustTravel.some((x) => x.startsWith('user_game_item_progress')), `${c.game}: user_game_item_progress na cadeia`);
    assert.ok(c.clubIdMustTravel.some((x) => x.startsWith('score_events')), `${c.game}: score_events na cadeia`);
  }
});
test('crowd_lineup e passport também exigem club_id na RPC/agregação', () => {
  const crowd = audit.progressChains.find((c) => c.game === 'crowd_lineup');
  assert.ok(crowd.clubIdMustTravel.some((x) => x.includes('crowd_lineup(p_club_id)')));
  const pass = audit.progressChains.find((c) => c.game === 'passport');
  assert.ok(pass.clubIdMustTravel.some((x) => x.includes('passport_ranking') || x.includes('where club_id')));
});
test('a lista de RPCs que precisam de club_id cobre record_score, ranking, membership, crowd_lineup e passport', () => {
  const joined = stats.rpcsNeedingClubId.join(' | ');
  for (const r of ['arena_record_score', 'arena_ranking', 'get_my_membership', 'crowd_lineup', 'passport_ranking']) {
    assert.match(joined, new RegExp(r));
  }
});

console.log('\n6) RLS matrix — usuário != tenant (item 24)');
test('tabelas OWNER (auth.uid()=user_id) marcam vazamento de tenant possível PARA O MESMO usuário (RLS de usuário não separa clube)', () => {
  const owner = audit.rlsMatrix.filter((r) => r.usesAuthUid && r.tenantLeakPossibleForSameUser);
  assert.ok(owner.length >= 10, `esperava várias tabelas OWNER com leak de tenant, achei ${owner.length}`);
  for (const r of owner) assert.match(r.note, /não separa clubA de clubB|não separa clube/i);
});
test('tabelas de conteúdo são PUBLIC_READ — RLS não separa clube nenhum, ROW_SCOPE tem de vir do filtro da query', () => {
  for (const name of stats.contentTables) {
    const r = audit.rlsMatrix.find((x) => x.table === name);
    assert.strictEqual(r.publicRead, true, `${name} deveria ser PUBLIC_READ`);
  }
});

console.log('\n7) preservação de ids legados + tipo do club_id');
test('política de id legado: nunca renomear/namespacing, só composta ou surrogate', () => {
  assert.match(stats.legacyIdPolicy, /NUNCA renomear/);
  assert.match(stats.legacyIdPolicy, /goias:tadeu/);
  assert.match(stats.legacyIdPolicy, /surrogate/);
});
test('club_id é sempre uuid references clubs(id), nunca text/slug (grep no próprio script)', () => {
  assert.strictEqual(stats.clubIdType.type, 'uuid');
  const src = fs.readFileSync(SCRIPT, 'utf8');
  assert.doesNotMatch(src, /club_id text references/i);
});
test('proveniência de match_id NÃO é presumida globalmente única (item 23)', () => {
  assert.strictEqual(audit.externalKeyProvenance.match_id.globallyUniqueProven, false);
  assert.match(audit.externalKeyProvenance.match_id.risk, /nunca presumir/i);
});

console.log('\n8) roadmap faseado (itens 4/5/6/7) — additive → runtime → enforcement');
test('roadmap tem as 4 fases na ordem: M2.2A (additive) → M3 (runtime) → M2.2B (enforcement) → M4 (flavors)', () => {
  const r = audit.roadmap;
  for (const p of ['M2.2A', 'M3', 'M2.2B', 'M4']) assert.ok(r[p], `fase ${p} ausente`);
  assert.match(r['M2.2A'].compat, /BACKWARD_COMPATIBLE/);
  assert.match(r['M2.2A'].goal, /old app \+ new DB/);
  assert.match(r['M3'].compat, /DUAL/);
  assert.match(r['M3'].goal, /new app \+ transitional DB/);
  assert.match(r['M2.2B'].compat, /REQUIRES_APP_DEPLOY_FIRST/);
  assert.ok(r['M2.2B'].does.some((s) => /trocar PK/i.test(s)), 'M2.2B deve conter a troca de PK');
  // a troca de PK NUNCA pode estar na fase aditiva
  assert.ok(!r['M2.2A'].does.some((s) => /trocar PK|remove PK|NOT NULL definitivo/i.test(s)), 'M2.2A não pode conter troca/remoção de PK');
});
test('contrato de compat de RPC: as RPCs críticas não podem quebrar na M2.2A e nenhuma chamada pode depender do default Goiás com 2 clubes', () => {
  const c = audit.rpcCompatibilityContract;
  for (const r of ['arena_record_score', 'get_my_membership', 'crowd_lineup', 'passport_ranking']) {
    assert.ok(c.mustNotBreakInM2_2A.includes(r), `${r} deveria estar na lista mustNotBreakInM2_2A`);
  }
  assert.match(c.hardRule, /NENHUMA chamada pode depender do default Goiás/i);
});
test('backfill é DESIGN, não executado — contagens deferidas pra M2.2 (M2.1 não roda db query)', () => {
  assert.strictEqual(audit.backfillPlan.countsComputed, false);
  assert.match(audit.backfillPlan.rule, /4c16340d-300c-5ab2-903f-17519db9b146/);
});
test('membership CRITICAL segue o rollout faseado (club_id aditivo em M2.2A, activeClubId no repo em M3, contrato antigo removível só em M2.2B)', () => {
  assert.ok(audit.roadmap['M2.2A'].does.some((s) => /club_id/i.test(s)));
  assert.ok(audit.roadmap['M3'].does.some((s) => /club_id|activeClubId/i.test(s)));
});

console.log('\n9) F7 preservada em lineup_matches (correção obrigatória)');
test('lineup_matches: club_id é só tenancy da LINHA; o jsonb dos 11 permanece editorial e SEM person_id — F7 preservada (person_id NUNCA no slot)', () => {
  const l = tbl('lineup_matches');
  assert.strictEqual(l.f7Preserved, true);
  assert.match(l.note, /SEM person_id/);
  assert.match(l.note, /NUNCA entra em cada slot|nunca no slot/i);
  // nunca deve afirmar que person_id VIVE no jsonb
  assert.doesNotMatch(l.note, /person_id vive no jsonb/i);
  // e lineup NÃO é uma das tabelas de conteúdo com UNIQUE(person_id)
  assert.ok(!stats.personIdContentTables.includes('lineup_matches'));
});

console.log('\n10) RLS vs APP_CLUB — 3 conceitos, o Postgres não lê APP_CLUB');
test('modelo de RLS separa userSecurity / applicationTenantFilter / databaseEnforcedTenantIdentity, e marca o 3º como inexistente hoje', () => {
  const m = audit.rlsTenantModel;
  assert.match(m.userSecurity.rule, /auth\.uid\(\) = user_id/);
  assert.match(m.applicationTenantFilter.rule, /club_id/);
  assert.match(m.databaseEnforcedTenantIdentity.status, /NÃO existe hoje/i);
  assert.match(m.consequence, /NÃO é vazamento ENTRE usuários|isolamento de PRODUTO/i);
  assert.match(m.firstMandatoryGate, /repositories SEMPRE filtram club_id/i);
});
test('passaporte permanece NEEDS_PRODUCT_DECISION e bloqueia migration de passport na M2.2A sem aprovação de produto', () => {
  assert.strictEqual(audit.passportDecision.status, 'NEEDS_PRODUCT_DECISION');
  assert.strictEqual(audit.passportDecision.blocking, true);
  assert.match(audit.passportDecision.note, /1697\+|sem aprovação/i);
});
test('user_notification_preferences deve virar (user_id, club_id) — preferência é por-clube, embora o token siga GLOBAL', () => {
  const p = tbl('user_notification_preferences');
  assert.match(p.tenantStrategy, /user_id, club_id/);
  assert.strictEqual(tbl('user_notification_tokens').tenantStrategy, 'KEEP_GLOBAL');
});

console.log('\n11) read-only + 0 migration');
test('o script só escreve nos próprios outputs (OUT_DIR)', () => {
  const src = fs.readFileSync(SCRIPT, 'utf8');
  const writes = [...src.matchAll(/writeFileSync\(([^,]+),/g)].map((m) => m[1]);
  for (const w of writes) assert.match(w, /OUT_DIR/, `write fora de OUT_DIR: ${w}`);
});
test('nenhuma migration nova (M2.1 é auditoria/design, 0 mudança de banco) — 35 migrations', () => {
  const count = fs.readdirSync(path.join(ROOT, 'supabase', 'migrations')).filter((f) => f.endsWith('.sql')).length;
  assert.strictEqual(count, 35, `esperava 35 migrations, achei ${count}`);
});

console.log('\n12) reprodutibilidade byte a byte');
test('rodar o audit de novo produz o mesmo JSON byte a byte', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_tenant_constraints_audit.json'), 'utf8');
  execFileSync(process.execPath, [SCRIPT], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_tenant_constraints_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

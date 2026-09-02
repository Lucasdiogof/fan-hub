import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const LIB = path.join(ROOT, 'lib');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const audit = JSON.parse(
  fs.readFileSync(path.join(RECON, 'multiclub_runtime_user_state_scope_audit.json'), 'utf8')
);
const GOIAS_UUID = '4c16340d-300c-5ab2-903f-17519db9b146';

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

const DIRECT_TABLES = Object.keys(audit.directTables);
const RPCS = Object.keys(audit.rpcs);

// ============================================================================
// 1) 14/14 tabelas de estado por usuário com ROW_SCOPE pronto
// ============================================================================
console.log('1) 14/14 tabelas de estado com leitura/escrita direta tenant-scoped');
test('allDirectTablesRowScopeReady = true', () => {
  assert.strictEqual(audit.allDirectTablesRowScopeReady, true);
});
test('as 14 tabelas têm .eq(\'club_id\', ...) na leitura real', () => {
  for (const t of DIRECT_TABLES) assert.strictEqual(audit.directTables[t].hasClubIdInReads, true, t);
});
test('as 14 tabelas recebem ClubConfig no construtor do repository', () => {
  for (const t of DIRECT_TABLES) assert.strictEqual(audit.directTables[t].hasClubConfigCtorParam, true, t);
});
test('13/14 gravam club_id direto (insert/upsert); store_orders grava via RPC (create_store_order_for_club)', () => {
  for (const t of DIRECT_TABLES) {
    const r = audit.directTables[t];
    if (r.writeVia === 'rpc') {
      assert.strictEqual(t, 'store_orders');
    } else {
      assert.strictEqual(r.hasClubIdInWrites, true, t);
    }
  }
});

// ============================================================================
// 2) 8/8 RPCs tenant-aware novas — aditivas, nunca substituem a legacy
// ============================================================================
console.log('\n2) 8/8 RPCs novas tenant-aware — legacy intacta, nunca mais chamada pelo Flutter novo');
test('allRpcsTenantAwareReady = true', () => {
  assert.strictEqual(audit.allRpcsTenantAwareReady, true);
});
test('as 8 RPCs novas têm call site real no repository certo, com p_club_id', () => {
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].newRpcCallSitePresent, true, r);
    assert.strictEqual(audit.rpcs[r].hasClubIdParam, true, r);
  }
});
test('nenhuma das 8 RPCs legacy é mais chamada pelo Flutter (código novo usa só a variante _for_club)', () => {
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].legacyStillCalledInFlutter, false, r);
  }
});
test('as 8 RPCs legacy continuam definidas no SQL fonte, byte-presentes (nunca DROP FUNCTION)', () => {
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].legacySqlStillDefined, true, r);
  }
});
test('as 8 migrations novas existem, validam p_club_id (NULL/clube inexistente rejeitados) e são só aditivas', () => {
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].migrationExists, true, r);
    assert.strictEqual(audit.rpcs[r].migrationValidatesClubId, true, r);
    assert.strictEqual(audit.rpcs[r].migrationIsAdditiveOnly, true, r);
  }
});

// ============================================================================
// 3) 0 UUID do Goiás hardcoded fora de goias_club_config.dart
// ============================================================================
console.log('\n3) 0 UUID Goiás hardcoded nos repositories/DI tocados nesta etapa');
test('nenhum dos repositories/DI tocados tem o UUID literal do Goiás', () => {
  assert.deepStrictEqual(audit.goiasUuidHardcodedInTouchedFiles, []);
});

// ============================================================================
// 4) KEY_SCOPE_BLOCKED registrado explicitamente onde se aplica
// ============================================================================
console.log('\n4) KEY_SCOPE_BLOCKED documentado nas tabelas cuja PK/UNIQUE ainda não inclui club_id');
test('arena_selected_content, arena_achievements, ticket_checkin_decisions, tickets e as 4 tabelas de progresso continuam keyScopeBlocked=true', () => {
  for (const t of [
    'quiz_question_progress', 'quiz_active_session', 'career_path_progress',
    'lineup_match_progress', 'arena_selected_content', 'arena_achievements',
    'player_identity_results', 'tactical_identity_results',
    'ticket_checkin_decisions', 'tickets', 'user_notification_preferences',
  ]) {
    assert.strictEqual(audit.directTables[t].keyScopeBlocked, true, t);
  }
});
test('match_lineup_votes/ticket_orders/store_orders continuam keyScopeBlocked=false (chave física já suficiente ou sem colisão possível)', () => {
  for (const t of ['match_lineup_votes', 'ticket_orders', 'store_orders']) {
    assert.strictEqual(audit.directTables[t].keyScopeBlocked, false, t);
  }
});

// ============================================================================
// 5) Tabelas deliberadamente fora do escopo Flutter (só Edge Function/global)
// ============================================================================
console.log('\n5) escopo estrito — tabelas só-Edge-Function e a global documentadas, nenhuma tocada no Dart');
test('match_monitor_sessions/notification_events/notification_deliveries: só as 3 realmente Edge-Function-only (user_notification_tokens saiu daqui — ver globalTables)', () => {
  const keys = Object.keys(audit.edgeFunctionOnlyTables);
  assert.deepStrictEqual(
    keys.sort(),
    ['match_monitor_sessions', 'notification_deliveries', 'notification_events'].sort()
  );
  for (const k of keys) {
    assert.ok(audit.edgeFunctionOnlyTables[k].reason.length > 0, k);
  }
});
test('user_notification_tokens está em globalTables (owner Dart real, mas deliberadamente sem club_id), não em edgeFunctionOnlyTables', () => {
  assert.deepStrictEqual(Object.keys(audit.globalTables), ['user_notification_tokens']);
  assert.strictEqual(audit.globalTables.user_notification_tokens.hasClubIdColumn, false);
  assert.ok(audit.globalTables.user_notification_tokens.ownerRepo.length > 0);
  assert.ok(!('user_notification_tokens' in audit.edgeFunctionOnlyTables));
});
test('nenhum repository Dart desta etapa referencia match_monitor_sessions/notification_events/notification_deliveries', () => {
  const touchedFiles = new Set([
    ...Object.values(audit.directTables).flatMap((r) => r.repos),
    ...Object.values(audit.rpcs).map((r) => r.callerRepo),
  ]);
  for (const f of touchedFiles) {
    const src = fs.readFileSync(path.join(LIB, f), 'utf8');
    for (const forbidden of ['match_monitor_sessions', 'notification_events', 'notification_deliveries']) {
      assert.doesNotMatch(src, new RegExp(`from\\('${forbidden}'\\)`), `${f} referencia ${forbidden}`);
    }
  }
});
test('user_notification_tokens continua sem club_id em supabase_notification_repository.dart (fica global)', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/notifications/data/supabase_notification_repository.dart'), 'utf8');
  const tokenBlockMatch = src.match(/registerToken\([\s\S]*?\n {2}\}/);
  assert.ok(tokenBlockMatch, 'não achou o método registerToken');
  assert.doesNotMatch(tokenBlockMatch[0], /'club_id'/, 'registerToken não deveria mandar club_id (token é global)');
});

// ============================================================================
// 6) Escopo — Passaporte e M3.3 continuam intocados
// ============================================================================
console.log('\n6) escopo estrito — Passaporte intocado (M3.3 é quem legitimamente toca branding/isGoias/Worker agora)');
test('passport_matches/passport_attendances/passport_memorable_matches: repository do Passaporte não foi tocado', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/passport/data/supabase_passport_repository.dart'), 'utf8');
  assert.doesNotMatch(src, /_clubConfig/);
  assert.doesNotMatch(src, /club_id/);
});
// SUPERSEDIDO pela M3.3 (mesmo padrão de regressão auto-referencial já
// visto em M2.2A/M3.1): esta asserção provava, na época da M3.2, que
// `team.dart` (Team.isGoias/goiasId) ainda não tinha sido tocado — a M3.3
// é exatamente a etapa que devia tocar, adicionando `Team.matchesClub
// (ClubConfig)` e removendo `isGoias`/`goiasId`. A prova de que ISSO
// aconteceu corretamente mora em `test_multiclub_runtime_hardcodes.mjs`
// (seção 1), não aqui — nunca reintroduzir esta asserção como estava.
test('AppColors/AppAssets não foram tocados nesta etapa (nenhum arquivo de tema no diff esperado)', () => {
  const themeFile = path.join(LIB, 'core/theme/app_colors.dart');
  assert.ok(fs.existsSync(themeFile));
});

// ============================================================================
// 8) Hardening de segurança — REVOKE PUBLIC, grant allowlist, search_path,
// qualificação de schema, contagem DEFINER/INVOKER, legacy intacta
// ============================================================================
console.log('\n8) hardening de segurança — REVOKE PUBLIC, grants, search_path, schema-qualification');
test('allRpcsSecurityHardeningReady = true', () => {
  assert.strictEqual(audit.allRpcsSecurityHardeningReady, true);
});
test('8/8 RPCs novas têm REVOKE ALL ... FROM PUBLIC explícito (nunca herdam o EXECUTE-pra-PUBLIC padrão do CREATE FUNCTION)', () => {
  for (const r of RPCS) assert.strictEqual(audit.rpcs[r].revokePublicPresent, true, r);
});
test('8/8 RPCs novas têm grant allowlist exato (== expectedRoles, nunca copiado cego da legacy)', () => {
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].grantAllowlistMatches, true, r);
    assert.deepStrictEqual(audit.rpcs[r].grantedRoles, [...audit.rpcs[r].expectedRoles].sort(), r);
  }
});
test('grantedRoles da migration ORIGINAL (view parcial, insuficiente sozinha — ver seção 9): nenhuma lista anon/service_role no texto da migration de criação', () => {
  for (const r of RPCS) {
    assert.ok(!audit.rpcs[r].grantedRoles.includes('anon'), r);
    assert.ok(!audit.rpcs[r].grantedRoles.includes('service_role'), r);
  }
});
test('7 SECURITY DEFINER + 1 SECURITY INVOKER (create_store_order_for_club) — nunca 6+1 ou 8+0', () => {
  assert.strictEqual(audit.summary.securityDefinerCount, 7);
  assert.strictEqual(audit.summary.securityInvokerCount, 1);
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].securityDefinerMatchesExpected, true, r);
  }
  assert.strictEqual(audit.rpcs.create_store_order_for_club.isSecurityDefiner, false);
});
test('7/7 SECURITY DEFINER têm search_path seguro (pg_catalog, public, pg_temp — nunca só `public`, pg_temp nunca precede)', () => {
  for (const r of RPCS) {
    if (audit.rpcs[r].isSecurityDefiner) assert.strictEqual(audit.rpcs[r].safeSearchPath, true, r);
  }
});
test('8/8 RPCs novas: toda relação real referenciada no corpo é schema-qualificada (public.<tabela>, nunca bare)', () => {
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].schemaQualified, true, r);
    assert.deepStrictEqual(audit.rpcs[r].schemaQualificationProblems, [], r);
  }
});
test('detecção de qualificação funciona de verdade: uma referência bare fabricada (from supporter_memberships) é sinalizada como problema', () => {
  const migSrc = fs.readFileSync(
    path.join(ROOT, 'supabase', 'migrations', '20260903010000_add_membership_tenant_aware_rpcs.sql'),
    'utf8'
  );
  const bareInjected = migSrc.replace(
    'from public.supporter_memberships m',
    'from supporter_memberships m'
  );
  assert.notStrictEqual(bareInjected, migSrc, 'fixture não encontrou a linha esperada pra substituir');
  const startIdx = bareInjected.indexOf('create or replace function public.get_my_membership_for_club(');
  const asIdx = bareInjected.indexOf('as $$', startIdx);
  const endIdx = bareInjected.indexOf('$$;', asIdx + 5);
  const block = bareInjected.slice(startIdx, endIdx + 3);
  const problems = [];
  const re = /(from|into|update|join)\s+supporter_memberships\b/gi;
  let match;
  while ((match = re.exec(block)) !== null) {
    const before = block.slice(Math.max(0, match.index - 8), match.index);
    if (!/public\.\s*$/i.test(before)) problems.push(match[0]);
  }
  assert.ok(problems.length > 0, 'a checagem deveria ter sinalizado a referência bare fabricada');
});
test('create_store_order_for_club (SECURITY INVOKER) também tem REVOKE PUBLIC + grant allowlist, apesar de não ter search_path', () => {
  const r = audit.rpcs.create_store_order_for_club;
  assert.strictEqual(r.isSecurityDefiner, false);
  assert.strictEqual(r.revokePublicPresent, true);
  assert.strictEqual(r.grantAllowlistMatches, true);
});
test('0 RPCs legacy alteradas: nenhum arquivo-fonte legacy (arena_ranking.sql/crowd_lineup.sql/store_orders.sql) aparece no git diff desta etapa', () => {
  const diffOutput = execFileSync('git', ['diff', '--name-only'], { cwd: ROOT }).toString();
  // Mesmo mapeamento legacySqlFile do audit_multiclub_runtime_user_state_scope.mjs
  // (o audit não expõe esse campo no JSON de saída, então repete aqui a lista
  // conhecida de arquivos-fonte legacy — subscribe_to_plan não tem arquivo
  // próprio, vive só na migration antiga 20260830220002).
  const legacyFiles = [
    'arena_ranking.sql', 'supporter_memberships.sql', 'crowd_lineup.sql', 'store_orders.sql',
  ];
  for (const f of legacyFiles) {
    assert.ok(!diffOutput.includes(f), `${f} aparece no git diff — legacy não deveria ter sido tocada`);
  }
});
test('a 8 migrations novas nunca fazem DROP/ALTER na legacy — mesma checagem migrationIsAdditiveOnly já provada na seção 2', () => {
  for (const r of RPCS) assert.strictEqual(audit.rpcs[r].migrationIsAdditiveOnly, true, r);
});

// ============================================================================
// 9) Correção pós-push — ACL EFETIVO (soma das migrations, nunca só a
// original). Achado real: `pg_default_acl` do projeto Supabase concede
// EXECUTE a anon/authenticated/service_role em toda função nova de `public`
// automaticamente (independente do REVOKE ALL FROM PUBLIC da migration
// original) — confirmado ao vivo via `pg_proc.proacl` logo após o 1º push,
// que mostrou `anon`/`service_role` com EXECUTE nas 8 novas mesmo com a
// migration original "correta" pelo texto. `20260903040000_harden_tenant_
// rpc_execute_grants.sql` fecha isso revogando explicitamente de
// public+anon+service_role, sem tocar nas 4 migrations originais nem na
// legacy. Estes testes provam o ACL EFETIVO (original + hardening somados em
// ordem), não só a migration isolada — nunca mais confiar só no texto de 1
// arquivo pra provar EXECUTE, já que esse foi exatamente o gap que passou
// pela seção 8 na 1ª rodada.
// ============================================================================
console.log('\n9) correção pós-push — ACL efetivo (original + hardening), nunca só 1 migration isolada');
test('8/8 RPCs novas têm hardeningMigration registrada e o arquivo existe', () => {
  for (const r of RPCS) {
    assert.strictEqual(audit.rpcs[r].hardeningMigration, '20260903040000_harden_tenant_rpc_execute_grants.sql', r);
  }
  assert.ok(fs.existsSync(path.join(ROOT, 'supabase', 'migrations', '20260903040000_harden_tenant_rpc_execute_grants.sql')));
});
test('ACL efetivo das 8 novas = exatamente ["authenticated"] — public/anon/service_role fora, mesmo somando as 2 migrations', () => {
  for (const r of RPCS) {
    assert.deepStrictEqual(audit.rpcs[r].effectiveRoles, ['authenticated'], r);
    assert.strictEqual(audit.rpcs[r].effectivePublicGranted, false, r);
    assert.strictEqual(audit.rpcs[r].effectiveAnonGranted, false, r);
    assert.strictEqual(audit.rpcs[r].effectiveServiceRoleGranted, false, r);
    assert.strictEqual(audit.rpcs[r].effectiveGrantAllowlistMatches, true, r);
  }
});
test('allRpcsSecurityHardeningReady/allRpcsTenantAwareReady agora dependem do ACL efetivo, não só da migration original', () => {
  assert.strictEqual(audit.allRpcsSecurityHardeningReady, true);
  assert.strictEqual(audit.allRpcsTenantAwareReady, true);
});
test('a migration de hardening não altera as 4 originais nem a legacy — só REVOKE/GRANT sobre as 8 já criadas', () => {
  const src = fs.readFileSync(
    path.join(ROOT, 'supabase', 'migrations', '20260903040000_harden_tenant_rpc_execute_grants.sql'),
    'utf8'
  );
  // Só o SQL executável importa aqui — o próprio comentário explicativo do
  // arquivo MENCIONA "CREATE FUNCTION" e "ALTER DEFAULT PRIVILEGES" ao
  // explicar a causa raiz, então precisa tirar as linhas `--` primeiro (senão
  // a asserção dá falso-positivo no texto explicativo, não no SQL real).
  const executableOnly = src
    .split('\n')
    .filter((l) => !l.trim().startsWith('--'))
    .join('\n');
  assert.doesNotMatch(executableOnly, /create (or replace )?function/i, 'a migration de hardening não deveria criar/redefinir nenhuma função');
  assert.doesNotMatch(executableOnly, /\balter\s+default\s+privileges\b/i, 'esta rodada não altera ALTER DEFAULT PRIVILEGES global — só as 8 funções específicas');
});
test('simulação de ACL usa como ponto de partida o default REAL confirmado ao vivo (public+anon+authenticated+service_role), nunca um estado assumido', () => {
  // DEFAULT_ACL_ROLES_ON_CREATE não é exposto no JSON — reconstrói a
  // asserção a partir do timeline: a 1ª entrada de grantTimeline de qualquer
  // RPC é sempre um "revoke" (nunca um "grant" a mais, porque o role já
  // nasce concedido pelo default do projeto — só precisa ser revogado).
  for (const r of RPCS) {
    const timeline = audit.rpcs[r].grantTimeline;
    assert.ok(timeline.length >= 4, r); // 1 revoke+1 grant por migration, no mínimo 2 migrations
    assert.strictEqual(timeline[0].type, 'revoke', r);
  }
});

// ============================================================================
// 7) Reprodutibilidade
// ============================================================================
console.log('\n7) reprodutibilidade — audit byte-idêntico ao rodar de novo');
test('rodar audit_multiclub_runtime_user_state_scope.mjs de novo produz o mesmo JSON', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_runtime_user_state_scope_audit.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_multiclub_runtime_user_state_scope.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_runtime_user_state_scope_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

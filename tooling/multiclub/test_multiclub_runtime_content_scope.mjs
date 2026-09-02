import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import assert from 'assert';
import { execFileSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const LIB = path.join(ROOT, 'lib');
const RECON = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const audit = JSON.parse(fs.readFileSync(path.join(RECON, 'multiclub_runtime_content_scope_audit.json'), 'utf8'));
const GOIAS_UUID = '4c16340d-300c-5ab2-903f-17519db9b146';

let passed = 0;
const failures = [];
function test(name, fn) {
  try { fn(); passed++; console.log(`  PASS — ${name}`); }
  catch (err) { failures.push({ name, err }); console.log(`  FAIL — ${name}\n    ${err.message}`); }
}

const TABLES = ['career_players', 'guess_players', 'squad_members', 'lineup_matches', 'quiz_questions'];

// ============================================================================
// 1) 5/5 tabelas de conteúdo tenant-scoped
// ============================================================================
console.log('1) 5/5 content tables tenant-scoped');
test('ALL_RUNTIME_READ_PATHS_SCOPED = true (o próprio invariante que a M3.1 pediu)', () => {
  assert.strictEqual(audit.allRuntimeReadPathsScoped, true);
});
test('as 5 tabelas têm .eq(\'club_id\', _clubConfig.identity.canonicalClubId) no repository real', () => {
  for (const t of TABLES) assert.strictEqual(audit.tables[t].hasClubIdFilter, true, t);
});
test('as 5 tabelas recebem ClubConfig no construtor (this._clubConfig)', () => {
  for (const t of TABLES) assert.strictEqual(audit.tables[t].hasClubConfigCtorParam, true, t);
});

// ============================================================================
// 2) 0 UUID do Goiás hardcoded em repository
// ============================================================================
console.log('\n2) 0 UUID Goiás hardcoded em repository (só em goias_club_config.dart)');
test('nenhuma das 5 tabelas tem o UUID literal do Goiás no repository', () => {
  assert.deepStrictEqual(audit.goiasUuidHardcodedInRepositories, []);
  for (const t of TABLES) assert.strictEqual(audit.tables[t].hardcodedGoiasUuid, false, t);
});
test('o UUID do Goiás CONTINUA centralizado em goias_club_config.dart (não foi removido de lá)', () => {
  const src = fs.readFileSync(path.join(LIB, 'core', 'club', 'goias_club_config.dart'), 'utf8');
  assert.ok(src.includes(GOIAS_UUID));
});

// ============================================================================
// 3) 0 cross-club fallback — mecanismo ClubScopedFallback usado, nunca
//    "return <const>" incondicional
// ============================================================================
console.log('\n3) 0 cross-club fallback — ClubScopedFallback em vez de constante incondicional');
test('nenhuma das 4 tabelas com fallback usa "return <fallbackConst>;" incondicional (padrão antigo proibido)', () => {
  for (const t of TABLES) assert.strictEqual(audit.tables[t].usesUnconditionalFallbackReturn, false, t);
});
test('career_players/guess_players/lineup_matches/quiz_questions usam ClubScopedFallback; squad_members nunca teve fallback (ok, F4)', () => {
  for (const t of TABLES) assert.strictEqual(audit.tables[t].usesClubScopedFallback, true, t);
});
test('ClubScopedFallback e ClubDataUnavailableException existem em lib/core/club/', () => {
  assert.strictEqual(audit.clubScopedFallbackExists, true);
  assert.strictEqual(audit.clubDataUnavailableExists, true);
});

// ============================================================================
// 3.5) EMPTY_NO_FALLBACK != REMOTE_FAILURE_NO_FALLBACK — hardening pós-review:
//    0 linhas (sucesso) e falha remota real (rede/parse/exception) nunca são
//    conflatadas; sem fallback, a falha remota SEMPRE relança a exceção
//    original (nunca vira ClubDataUnavailableException).
// ============================================================================
console.log('\n3.5) EMPTY_NO_FALLBACK != REMOTE_FAILURE_NO_FALLBACK — falha remota nunca vira ClubDataUnavailableException');
test('invariant global emptyVsRemoteFailureSemanticsInvariant.holds = true', () => {
  assert.strictEqual(audit.emptyVsRemoteFailureSemanticsInvariant.holds, true);
});
test('career_players/guess_players/lineup_matches/quiz_questions relançam a exceção original via Error.throwWithStackTrace no catch (nunca perdem o stack trace)', () => {
  for (const t of ['career_players', 'guess_players', 'lineup_matches', 'quiz_questions']) {
    assert.strictEqual(audit.tables[t].hasErrorPreservingRethrow, true, t);
  }
});
test('career_players/guess_players/lineup_matches/quiz_questions lançam ClubDataUnavailableException só no caminho de sucesso+vazio (fora do catch)', () => {
  for (const t of ['career_players', 'guess_players', 'lineup_matches', 'quiz_questions']) {
    assert.strictEqual(audit.tables[t].hasEmptyResultThrow, true, t);
    assert.strictEqual(audit.tables[t].catchNeverThrowsClubDataUnavailable, true, t);
  }
});
test('as 5 tabelas (incl. squad_members, que nunca lançou nada) têm emptyAndFailureSemanticsDistinct = true', () => {
  for (const t of TABLES) assert.strictEqual(audit.tables[t].emptyAndFailureSemanticsDistinct, true, t);
});

// ============================================================================
// 4) 0 2º clube real cadastrado
// ============================================================================
console.log('\n4) 0 segundo clube real — clubRegistry ainda só Goiás');
test('clubRegistry tem exatamente 1 entrada (goias)', () => {
  assert.strictEqual(audit.clubRegistryEntryCount, 1);
  assert.strictEqual(audit.clubRegistryOnlyGoias, true);
});

// ============================================================================
// 5) 0 drift semântico F1-F7 — colunas protegidas continuam na query
// ============================================================================
console.log('\n5) 0 drift semântico (F1/F3/F4/F7) — colunas protegidas continuam presentes');
test('career_players: id/answer/accepted_answers/club_career/person_id continuam no select (F1/F2/F6)', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/arena/games/career_path/data/career_player_repository.dart'), 'utf8');
  for (const col of ['id', 'answer', 'accepted_answers', 'club_career', 'person_id']) {
    assert.ok(src.includes(col), `coluna ${col} sumiu do select`);
  }
});
test('guess_players: id/name/display_name/person_id continuam no select (F3)', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/arena/games/guess_player/data/guess_player_repository.dart'), 'utf8');
  for (const col of ['id', 'name', 'display_name', 'person_id']) {
    assert.ok(src.includes(col), `coluna ${col} sumiu do select`);
  }
});
test('lineup_matches: lineup (jsonb, 11 slots, sem person_id) continua intocado — F7', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/arena/games/lineup/data/lineup_match_repository.dart'), 'utf8');
  const body = src.split('\n').filter((l) => !l.trim().startsWith('///') && !l.trim().startsWith('//')).join('\n');
  assert.ok(src.includes('lineup'));
  assert.doesNotMatch(body, /person_id/); // F7: identidade NUNCA entra no jsonb/slot (só no comentário explicando a regra, filtrado acima)
});
test('quiz_questions: id/difficulty/question/options/correct_index continuam no select', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/arena/games/quiz/data/quiz_question_repository.dart'), 'utf8');
  for (const col of ['id', 'difficulty', 'question', 'options', 'correct_index']) {
    assert.ok(src.includes(col), `coluna ${col} sumiu do select`);
  }
});
test('squad_members: .select() sem lista explícita de colunas continua igual (F4/F4.5, nenhuma coluna list adicionada)', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/squad/data/supabase_squad_repository.dart'), 'utf8');
  assert.match(src, /\.select\(\)\s*\n/);
});

// ============================================================================
// 6) DI — sl() injeta ClubConfig nas 5 registrations, sem GetIt espalhado
//    dentro dos repositories
// ============================================================================
console.log('\n6) DI — ClubConfig injetado via sl() na registration, nunca GetIt.I dentro do repository');
test('as 5 registrations em injection_container.dart passam sl() como 2º argumento', () => {
  for (const ok of Object.values(audit.diHasSlCallForEachRepo)) assert.strictEqual(ok, true);
});
test('nenhum dos 5 repositories chama sl()/GetIt.I() por conta própria (só recebe ClubConfig pelo construtor)', () => {
  const files = [
    'features/arena/games/career_path/data/career_player_repository.dart',
    'features/arena/games/guess_player/data/guess_player_repository.dart',
    'features/squad/data/supabase_squad_repository.dart',
    'features/arena/games/lineup/data/lineup_match_repository.dart',
    'features/arena/games/quiz/data/quiz_question_repository.dart',
  ];
  for (const f of files) {
    const src = fs.readFileSync(path.join(LIB, f), 'utf8');
    assert.doesNotMatch(src, /\bsl</, `${f} chama sl<...>() diretamente`);
    assert.doesNotMatch(src, /GetIt\.I/, `${f} chama GetIt.I diretamente`);
  }
});

// ============================================================================
// 7) Bypass de página corrigido (career_path/guess_player/lineup)
// ============================================================================
console.log('\n7) bypass de deep-link corrigido — página nunca usa a lista const direto');
test('career_path_page.dart / guess_player_page.dart / lineup_page.dart usam FutureBuilder + repository, nunca a lista local direto', () => {
  const pages = [
    ['career_players', 'features/arena/games/career_path/pages/career_path_page.dart'],
    ['guess_players', 'features/arena/games/guess_player/pages/guess_player_page.dart'],
    ['lineup_matches', 'features/arena/games/lineup/pages/lineup_page.dart'],
  ];
  for (const [table, f] of pages) {
    assert.strictEqual(audit.tables[table].bypassFixed, true, f);
  }
});

// ============================================================================
// 8) Escopo — nenhuma tabela fora das 5 foi tocada nesta rodada
// ============================================================================
console.log('\n8) escopo estrito — só as 5 tabelas de conteúdo, nada de M3.2/Passaporte');
test('passport_matches/passport_attendances/passport_memorable_matches: repository do Passaporte não foi tocado', () => {
  const src = fs.readFileSync(path.join(LIB, 'features/passport/data/supabase_passport_repository.dart'), 'utf8');
  assert.doesNotMatch(src, /_clubConfig/);
  assert.doesNotMatch(src, /club_id/);
});
test('progress/score/membership/notification/ticket/store repositories NÃO foram tocados (M3.2)', () => {
  const untouchedFiles = [
    'features/arena/data/arena_progress_repository.dart',
    'features/membership/data/supabase_membership_repository.dart',
    'features/notifications/data/supabase_notification_repository.dart',
    'features/ticket/data/mock_ticket_repository.dart',
    'features/store/data/supabase_store_orders_repository.dart',
    'features/crowd_lineup/data/supabase_crowd_lineup_repository.dart',
  ];
  for (const f of untouchedFiles) {
    const src = fs.readFileSync(path.join(LIB, f), 'utf8');
    assert.doesNotMatch(src, /_clubConfig/, `${f} foi tocado — fora de escopo da M3.1`);
  }
});
test('nenhuma RPC (arena_record_score/arena_ranking/get_my_membership/crowd_lineup) foi tocada — 0 arquivo .sql novo', () => {
  const migrationsDir = path.join(ROOT, 'supabase', 'migrations');
  const count = fs.readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).length;
  assert.strictEqual(count, 41, `esperava 41 migrations (M2.2A já aplicada, M3.1 é 0 migration), achou ${count}`);
});

// ============================================================================
// 9) Reprodutibilidade
// ============================================================================
console.log('\n9) reprodutibilidade — audit byte-idêntico ao rodar de novo');
test('rodar audit_multiclub_runtime_content_scope.mjs de novo produz o mesmo JSON', () => {
  const before = fs.readFileSync(path.join(RECON, 'multiclub_runtime_content_scope_audit.json'), 'utf8');
  execFileSync(process.execPath, [path.join(__dirname, 'audit_multiclub_runtime_content_scope.mjs')], { cwd: ROOT });
  const after = fs.readFileSync(path.join(RECON, 'multiclub_runtime_content_scope_audit.json'), 'utf8');
  assert.strictEqual(before, after);
});

console.log(`\n${passed} passaram, ${failures.length} falharam.`);
if (failures.length) process.exit(1);

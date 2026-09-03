// ============================================================================
// Legacy Contract Retirement Audit — WEB/PWA-first.
//
// Pergunta central desta rodada: será que o simples fechamento das
// constraints/DEFAULT legacy (M2.2B-B, como já estava escopada antes desta
// rodada) já é TECNICAMENTE suficiente pra aposentar os writes do PWA
// publicado (`origin/main`), sem precisar converter nada pra RPC-only?
//
// Método: o código do CLIENTE LEGACY é fixado no commit `613874a` (era
// `origin/main` no momento desta auditoria original — ver
// [[project-goias-app-rollout-gate]], deployment web ao vivo confirmado
// rodando exatamente esse snapshot). **Correção pós-release**: depois do
// M3.4 Web Release, `origin/main` passou a SER o código novo (mesmo commit
// que HEAD) — usar a ref `origin/main` aqui deixaria de comparar
// "legacy vs novo" e passaria a comparar "novo vs novo", invalidando o
// audit inteiro. Por isso a baseline legacy é um HASH FIXO, nunca mais uma
// ref que se move. Cada write do commit legacy foi inventariado via
// `git show 613874a:<file>` (reproduzível, sem rede) e classificado contra
// 2 mecanismos de fechamento, que NUNCA dependem do que o cliente declara
// (CLIENT_VERSION_SIGNAL != SERVER_ENFORCED_CONTRACT):
//
//   AUTO_RETIRED_BY_KEY_ENFORCEMENT — o write usa `upsert(onConflict: ...)`
//     numa chave que M2.2B-B troca (ex.: `(user_id,x)` -> `(club_id,user_id,x)`).
//     Depois da troca, o Postgres REJEITA o INSERT ... ON CONFLICT porque as
//     colunas do onConflict não batem mais com nenhuma constraint única
//     (erro 42P10) — falha alta, limpa, sem gravar dado errado.
//
//   AUTO_RETIRED_BY_DEFAULT_REMOVAL — o write é um INSERT simples (sem
//     onConflict) que nunca inclui `club_id` no payload (o conceito não
//     existe em `origin/main`) — depende inteiramente do
//     `DEFAULT <GoiasUUID>`. M2.2B-B já tinha `DROP DEFAULT` no escopo
//     (ver [[project-goias-app-multiclub-audit]], bullet M2.2B). Sem o
//     default, esse INSERT vira `NOT NULL violation` — falha alta, limpa.
//
// Alguns fatos (definição exata das constraints legacy, presença do
// DEFAULT, e um bug real encontrado por acidente nesta auditoria) exigiram
// consulta AO VIVO ao Supabase (read-only) — embutidos aqui como snapshot
// datado, mesmo padrão já usado em `audit_multiclub_key_scope.mjs`. Um
// re-check real deve ser feito antes de qualquer decisão futura.
// ============================================================================
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

// Commit real do PWA legacy publicado ANTES do M3.4 Web Release — fixo de
// propósito, nunca `origin/main` (que agora É o código novo pós-push).
const LEGACY_BASELINE_COMMIT = '613874a7e00073c19560f8a9ebe0325efc395c0a';

function showLegacyBaseline(relPath) {
  try {
    return execSync(`git show ${LEGACY_BASELINE_COMMIT}:${JSON.stringify(relPath)}`, { cwd: ROOT, encoding: 'utf8' });
  } catch {
    return null; // arquivo não existe no commit legacy
  }
}
function readHead(relPath) {
  try {
    return fs.readFileSync(path.join(ROOT, relPath), 'utf8');
  } catch {
    return null;
  }
}
function extractOnConflicts(src) {
  if (!src) return [];
  return [...src.matchAll(/onConflict:\s*'([^']+)'/g)].map((m) => m[1]);
}
function extractRpcNames(src) {
  if (!src) return [];
  // `.rpc<Map<String, dynamic>>('name', ...)` tem `<>` aninhado (generics
  // dentro de generics) — não dá pra casar isso com uma classe `[^>]*`
  // (para no primeiro `>`). Em vez de tentar casar o generic, casa
  // qualquer coisa até a primeira aspa simples depois de `.rpc`.
  return [...src.matchAll(/\.rpc[^'";]{0,60}'([a-z_]+)'/g)].map((m) => m[1]);
}

// --- 1. commit legacy fixo vs HEAD — números reais -------------------------
// Pós M3.4 Web Release: `origin/main` já É o código novo (mesmo commit que
// HEAD, a menos de trabalho local não pushado ainda). "Commits à frente"
// deixou de significar "quanto falta publicar" pra virar só "quanto HEAD
// já andou desde o snapshot legacy fixo" — cresce pra sempre, por design.
const commitsAheadOfLegacyBaseline = (() => {
  try {
    return parseInt(execSync(`git rev-list --count ${LEGACY_BASELINE_COMMIT}..HEAD`, { cwd: ROOT, encoding: 'utf8' }).trim(), 10);
  } catch { return null; }
})();
// Drift detector NOVO desta rodada: origin/main ainda é o mesmo commit que
// HEAD (== release realmente publicado, sem trabalho local não-pushado
// acumulando silenciosamente)? Só informativo — nunca usado pra decidir
// nada sozinho.
const originMainMatchesHead = (() => {
  try {
    execSync('git fetch origin', { cwd: ROOT, stdio: 'ignore' });
    const originMain = execSync('git rev-parse origin/main', { cwd: ROOT, encoding: 'utf8' }).trim();
    const head = execSync('git rev-parse HEAD', { cwd: ROOT, encoding: 'utf8' }).trim();
    return { matches: originMain === head, originMain, head };
  } catch { return { matches: null, originMain: null, head: null }; }
})();
// --- 2. Inventário completo dos write files (commit legacy fixo vs HEAD) --
// Cada entrada é um write site real, achado por `git show <hash legacy>:` +
// leitura manual desta rodada (não um grep cego — onConflict/.rpc sozinhos
// não bastam pra saber SE é write nem qual tabela/coluna realmente conta).
const WRITE_MATRIX = [
  // --- upserts diretos (ON CONFLICT) — tenant-scoped, fecham por chave ---
  { feature: 'Arena — conquista 100%', table: 'arena_achievements', file: 'lib/features/arena/data/arena_progress_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,achievement_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,achievement_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — progresso Quem Vestiu (career_path)', table: 'career_path_progress', file: 'lib/features/arena/games/career_path/data/supabase_career_path_storage.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,player_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,player_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — jogo selecionado (career_path owner)', table: 'arena_selected_content', file: 'lib/features/arena/games/career_path/data/supabase_career_path_storage.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,game_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,game_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — progresso Escalação (lineup)', table: 'lineup_match_progress', file: 'lib/features/arena/games/lineup/data/supabase_lineup_storage.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,match_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,match_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — jogo selecionado (lineup owner)', table: 'arena_selected_content', file: 'lib/features/arena/games/lineup/data/supabase_lineup_storage.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,game_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,game_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — Que Craque Você É', table: 'player_identity_results', file: 'lib/features/arena/games/player_identity/data/supabase_player_identity_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id', newMechanism: 'upsert onConflict', newTarget: 'user_id,club_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — Quiz (progresso pergunta)', table: 'quiz_question_progress', file: 'lib/features/arena/games/quiz/data/quiz_progress_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,question_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,question_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — Quiz (sessão ativa)', table: 'quiz_active_session', file: 'lib/features/arena/games/quiz/data/quiz_progress_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,difficulty', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,difficulty', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — Identidade Tática', table: 'tactical_identity_results', file: 'lib/features/arena/games/tactical_identity/data/supabase_tactical_identity_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id', newMechanism: 'upsert onConflict', newTarget: 'user_id,club_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Escalação da Torcida — voto', table: 'match_lineup_votes', file: 'lib/features/crowd_lineup/data/supabase_crowd_lineup_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'match_id,user_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,match_id,user_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Preferências de notificação', table: 'user_notification_preferences', file: 'lib/features/notifications/data/supabase_notification_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id', newMechanism: 'upsert onConflict', newTarget: 'user_id,club_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Ingresso — confirmar check-in (decisão)', table: 'ticket_checkin_decisions', file: 'lib/features/ticket/data/mock_ticket_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,match_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,match_id', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Ingresso — recusar check-in (decisão)', table: 'ticket_checkin_decisions', file: 'lib/features/ticket/data/mock_ticket_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,match_id', newMechanism: 'upsert onConflict', newTarget: 'club_id,user_id,match_id', closesBy: 'KEY', scope: 'TENANT' },

  // --- GLOBAL — nunca ganham club_id, fora do escopo do M2.2B-B ---
  { feature: 'Token de push (FCM)', table: 'user_notification_tokens', file: 'lib/features/notifications/data/supabase_notification_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'fcm_token', newMechanism: 'upsert onConflict', newTarget: 'fcm_token', closesBy: 'OUT_OF_SCOPE_GLOBAL', scope: 'GLOBAL' },
  { feature: 'Perfil do usuário', table: 'profiles', file: 'lib/features/profile/data/supabase_profile_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id', newMechanism: 'upsert onConflict', newTarget: 'user_id', closesBy: 'OUT_OF_SCOPE_GLOBAL', scope: 'GLOBAL' },

  // --- JÁ QUEBRADO EM PRODUÇÃO, independente de M2.2B-B (achado desta rodada) ---
  { feature: 'Ingresso — check-in de sócio (o ingresso em si)', table: 'tickets', file: 'lib/features/ticket/data/mock_ticket_repository.dart', oldMechanism: 'upsert onConflict', oldTarget: 'user_id,match_id', newMechanism: 'RPC dedicada (M3.4)', newTarget: 'upsert_membership_checkin_ticket_for_club', closesBy: 'ALREADY_BROKEN_PRE_EXISTING', scope: 'TENANT' },

  // --- RPC legacy (writes) — sobrevivem à chave, só fecham por DEFAULT ---
  { feature: 'Arena — gravação de pontuação (parte user_game_item_progress)', table: 'user_game_item_progress', file: 'lib/features/arena/ranking/data/supabase_arena_ranking_repository.dart', oldMechanism: 'RPC arena_record_score', oldTarget: 'on conflict (user_id,game_id,item_id)', newMechanism: 'RPC arena_record_score_for_club', newTarget: 'on conflict (club_id,user_id,game_id,item_id)', closesBy: 'KEY', scope: 'TENANT' },
  { feature: 'Arena — gravação de pontuação (parte score_events)', table: 'score_events', file: 'lib/features/arena/ranking/data/supabase_arena_ranking_repository.dart', oldMechanism: 'RPC arena_record_score (insert simples)', oldTarget: 'nenhum (plain insert)', newMechanism: 'RPC arena_record_score_for_club', newTarget: 'club_id explícito no insert', closesBy: 'DEFAULT (redundante — a mesma transação já falha antes, no insert de user_game_item_progress)', scope: 'TENANT' },
  { feature: 'Loja — criação de pedido', table: 'store_orders', file: 'lib/features/store/data/supabase_store_orders_repository.dart', oldMechanism: 'RPC create_store_order (insert simples)', oldTarget: 'nenhum (plain insert)', newMechanism: 'RPC create_store_order_for_club', newTarget: 'club_id explícito no insert', closesBy: 'DEFAULT', scope: 'TENANT' },
  { feature: 'Loja — itens do pedido', table: 'store_order_items', file: 'lib/features/store/data/supabase_store_orders_repository.dart', oldMechanism: 'RPC create_store_order (insert simples)', oldTarget: 'nenhum (tabela sem club_id — escopo via FK order_id)', newMechanism: 'RPC create_store_order_for_club', newTarget: 'sem club_id (inalterado — herda via FK)', closesBy: 'OUT_OF_SCOPE_NO_CLUB_ID_COLUMN', scope: 'N/A' },
  { feature: 'Sócio Torcedor — assinatura', table: 'supporter_memberships', file: 'lib/features/membership/data/supabase_membership_repository.dart', oldMechanism: 'RPC subscribe_to_plan (insert simples)', oldTarget: 'nenhum (plain insert)', newMechanism: 'RPC subscribe_to_plan_for_club', newTarget: 'club_id explícito no insert', closesBy: 'DEFAULT', scope: 'TENANT' },

  // --- inserts diretos (sem RPC, sem onConflict) — sobrevivem à chave ---
  { feature: 'Ingresso — pedido de compra', table: 'ticket_orders', file: 'lib/features/ticket/data/mock_ticket_repository.dart', oldMechanism: 'insert simples', oldTarget: 'nenhum', newMechanism: 'insert simples (club_id adicionado)', newTarget: 'club_id explícito', closesBy: 'DEFAULT', scope: 'TENANT' },
  { feature: 'Ingresso — linhas de compra', table: 'tickets', file: 'lib/features/ticket/data/mock_ticket_repository.dart', oldMechanism: 'insert simples (origin=purchase)', oldTarget: 'nenhum', newMechanism: 'insert simples (club_id adicionado)', newTarget: 'club_id explícito', closesBy: 'DEFAULT', scope: 'TENANT' },
];

// --- 3. Legacy RPCs (inventário completo, incl. leitura) -------------------
// Nome exato extraído de `_client.rpc<T>('nome', ...)` em cada arquivo,
// origin/main vs HEAD — writes vs reads marcados manualmente (ler o corpo
// da função não dá pra automatizar por regex com segurança).
const RPC_INVENTORY = [
  { name: 'arena_record_score', kind: 'WRITE', replacement: 'arena_record_score_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'arena_ranking', kind: 'READ', replacement: 'arena_ranking_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'arena_my_rank', kind: 'READ', replacement: 'arena_my_rank_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'arena_user_detail', kind: 'READ', replacement: 'arena_user_detail_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'crowd_lineup', kind: 'READ', replacement: 'crowd_lineup_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'get_my_membership', kind: 'READ', replacement: 'get_my_membership_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'subscribe_to_plan', kind: 'WRITE', replacement: 'subscribe_to_plan_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'create_store_order', kind: 'WRITE', replacement: 'create_store_order_for_club', stillCalledByHead: false, classification: 'SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT' },
  { name: 'cpf_is_taken', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED' },
  { name: 'passport_seasons', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED — sem club_id na tabela)' },
  { name: 'passport_matches_for_year', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'passport_summary', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'passport_attendance_breakdown', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'passport_stadium_summary', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'passport_attended_matches', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'passport_memorable_match_id', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'passport_set_memorable_match', kind: 'WRITE', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED — tabela sem club_id)' },
  { name: 'passport_save_attendances', kind: 'WRITE', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED — tabela sem club_id)' },
  { name: 'passport_ranking', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'passport_my_rank', kind: 'READ', replacement: null, stillCalledByHead: true, classification: 'STILL_REQUIRED (OUT_OF_SCOPE_PASSPORT_DEFERRED)' },
  { name: 'upsert_membership_checkin_ticket_for_club', kind: 'WRITE', replacement: null, stillCalledByHead: true, classification: 'NEW_IN_M3_4 (não existe em origin/main)' },
];

// --- 4. Verificação reproduzível: os RPC names acima batem com o código? --
const verifiedLegacyRpcNames = new Set();
const verifiedHeadRpcNames = new Set();
for (const relFile of [
  'lib/features/arena/ranking/data/supabase_arena_ranking_repository.dart',
  'lib/features/auth/data/auth_remote_data_source.dart',
  'lib/features/crowd_lineup/data/supabase_crowd_lineup_repository.dart',
  'lib/features/membership/data/supabase_membership_repository.dart',
  'lib/features/passport/data/supabase_passport_repository.dart',
  'lib/features/store/data/supabase_store_orders_repository.dart',
  'lib/features/ticket/data/mock_ticket_repository.dart',
]) {
  for (const n of extractRpcNames(showLegacyBaseline(relFile))) verifiedLegacyRpcNames.add(n);
  for (const n of extractRpcNames(readHead(relFile))) verifiedHeadRpcNames.add(n);
}
const rpcInventoryMatchesCode = RPC_INVENTORY.filter((r) => r.name !== 'upsert_membership_checkin_ticket_for_club')
  .every((r) => verifiedLegacyRpcNames.has(r.name)) &&
  [...verifiedLegacyRpcNames].every((n) => RPC_INVENTORY.some((r) => r.name === n));

// --- 5. Snapshot AO VIVO (datado) — constraints, DEFAULT, e o bug achado --
// Consultas reais rodadas nesta sessão (read-only: information_schema,
// pg_indexes, e um `EXPLAIN` — nunca uma escrita de verdade):
const LIVE_SNAPSHOT = {
  checkedAt: '2026-09-03',
  clubIdDefaultTables: [ // as 24 tabelas com club_id NOT NULL DEFAULT <GoiasUUID>
    'arena_achievements', 'arena_selected_content', 'career_path_progress', 'career_players',
    'guess_players', 'lineup_match_progress', 'lineup_matches', 'match_lineup_votes',
    'match_monitor_sessions', 'notification_events', 'player_identity_results',
    'quiz_active_session', 'quiz_question_progress', 'quiz_questions', 'score_events',
    'squad_members', 'store_orders', 'supporter_memberships', 'tactical_identity_results',
    'ticket_checkin_decisions', 'ticket_orders', 'tickets', 'user_game_item_progress',
    'user_notification_preferences',
  ],
  tablesWithoutClubIdColumn: ['store_order_items', 'profiles', 'user_notification_tokens', 'passport_matches', 'passport_attendances', 'passport_memorable_matches', 'user_addresses', 'delivery_addresses'],
  // BUG achado por acidente nesta auditoria — nada a ver com M2.2B-B.
  ticketCheckinAlreadyBrokenInProduction: {
    finding: 'A UNICA unique constraint cobrindo (user_id, match_id) em tickets é PARCIAL (tickets_user_match_checkin_uidx, WHERE origin=\'membership_check_in\'), desde a criação original (supabase/tickets.sql linha 110-112) — não introduzida por trabalho multiclub.',
    verification: 'EXPLAIN (COSTS false) [read-only, nenhuma escrita real] no exato SQL que o upsert(onConflict: "user_id,match_id") de origin/main gera -> Postgres recusa: 42P10 "there is no unique or exclusion constraint matching the ON CONFLICT specification".',
    consequence: 'O check-in de ingresso de sócio no PWA publicado HOJE já falha, para todo usuário, independente de M2.2B-B. Achado incidental desta auditoria — fora do escopo desta rodada consertar (0 db push/commit).',
  },
};

// --- 6. Classificação e métricas --------------------------------------------
const tenantWrites = WRITE_MATRIX.filter((w) => w.scope === 'TENANT');
const autoRetiredByKeyEnforcement = tenantWrites.filter((w) => w.closesBy === 'KEY');
const alreadyBroken = tenantWrites.filter((w) => w.closesBy === 'ALREADY_BROKEN_PRE_EXISTING');
const closedByDefault = tenantWrites.filter((w) => w.closesBy.startsWith('DEFAULT'));
const outOfScopeNoColumn = WRITE_MATRIX.filter((w) => w.closesBy === 'OUT_OF_SCOPE_NO_CLUB_ID_COLUMN');
const globalWrites = WRITE_MATRIX.filter((w) => w.scope === 'GLOBAL');

// writes que sobrevivem à MERA remoção de chave (sem contar DEFAULT) —
// exatamente os que dependem só de DEFAULT pra fechar.
const legacyWritesSurvivingKeyEnforcement = closedByDefault.length;
const defaultDependentLegacyWrites = closedByDefault.length;
// se M2.2B-B remover a chave E o DEFAULT (como já estava escopado antes
// desta rodada — ver M2.2B round 1), sobra alguém sem nenhum dos dois
// mecanismos? Conta os que não são KEY, nem DEFAULT, nem
// ALREADY_BROKEN/OUT_OF_SCOPE/GLOBAL.
const unversionedLegacyWritesRemaining = tenantWrites.filter(
  (w) => w.closesBy !== 'KEY' && !w.closesBy.startsWith('DEFAULT') && w.closesBy !== 'ALREADY_BROKEN_PRE_EXISTING',
).length; // exclui ALREADY_BROKEN_PRE_EXISTING de propósito — não é "sobra", já está morto

const legacyRpcsUsed = RPC_INVENTORY.filter((r) => r.stillCalledByHead === false).length; // legacy != HEAD, dual-track
const legacyRpcsUsedWrites = RPC_INVENTORY.filter((r) => r.stillCalledByHead === false && r.kind === 'WRITE').length;
const safeToRevokeLegacyRpcs = 0; // NENHUM ainda — cliente legacy continua ao vivo (ver rollout gate). Os 8 dual-track são CANDIDATOS pós-retirement, não seguros agora.

const rpcOnlyMigrationRequired = unversionedLegacyWritesRemaining > 0;
// Fechamento TÉCNICO (key+default juntos, como M2.2B-B já estava escopada)
// é suficiente? Isto NÃO reabre M2_2B_B_BLOCKED_BY_APP_ROLLOUT — ver nota
// no relatório: retirement técnico != decisão de produto de quebrar
// usuários reais de um deployment ao vivo sem aviso/redeploy.
const legacyContractRetirementReady = !rpcOnlyMigrationRequired;

const metrics = {
  oldDirectUpserts: WRITE_MATRIX.filter((w) => w.oldMechanism.includes('upsert onConflict')).length,
  autoRetiredByKeyEnforcement: autoRetiredByKeyEnforcement.length,
  legacyRpcsUsed,
  legacyRpcsUsedWrites,
  safeToRevokeLegacyRpcs,
  legacyWritesSurvivingKeyEnforcement,
  defaultDependentLegacyWrites,
  autoRetiredByDefaultRemoval: defaultDependentLegacyWrites,
  unversionedLegacyWritesRemaining,
  alreadyBrokenIndependentOfM2_2bB: alreadyBroken.length,
  outOfScopeNoClubIdColumn: outOfScopeNoColumn.length,
  globalWritesOutOfScope: globalWrites.length,
  rpcOnlyMigrationRequired,
  legacyContractRetirementReady,
  commitsAheadOfLegacyBaseline,
  originMainMatchesHead: originMainMatchesHead.matches,
  rpcInventoryMatchesCode,
};

const audit = {
  legacyBaselineCommit: LEGACY_BASELINE_COMMIT,
  commitsAheadOfLegacyBaseline,
  originMainMatchesHead,
  writeMatrix: WRITE_MATRIX,
  rpcInventory: RPC_INVENTORY,
  liveSnapshot: LIVE_SNAPSHOT,
  breakdown: {
    tenantWriteCount: tenantWrites.length,
    autoRetiredByKeyEnforcement: autoRetiredByKeyEnforcement.map((w) => w.feature),
    closedByDefault: closedByDefault.map((w) => w.feature),
    alreadyBroken: alreadyBroken.map((w) => w.feature),
    outOfScopeNoColumn: outOfScopeNoColumn.map((w) => w.feature),
    globalOutOfScope: globalWrites.map((w) => w.feature),
    unversionedRemaining: tenantWrites.filter((w) => w.closesBy !== 'KEY' && !w.closesBy.startsWith('DEFAULT') && w.closesBy !== 'ALREADY_BROKEN_PRE_EXISTING').map((w) => w.feature),
  },
};

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_legacy_contract_retirement_audit.json'), JSON.stringify(audit, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_legacy_contract_retirement_stats.json'), JSON.stringify(metrics, null, 2) + '\n');
console.log(JSON.stringify(metrics, null, 2));
console.log('\nEscrito em:', OUT_DIR);

export { WRITE_MATRIX, RPC_INVENTORY, LIVE_SNAPSHOT, metrics };

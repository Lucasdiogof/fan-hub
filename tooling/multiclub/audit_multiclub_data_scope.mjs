// Etapa M1 (rodada de correção) — classificação de escopo de TODA tabela
// Supabase relevante, agora separando 2 problemas INDEPENDENTES (nunca
// confundidos entre si, correção pedida pelo usuário):
//
//   ROW_SCOPE  — dá pra filtrar `where club_id = activeClub`? (resolvido
//                por ADICIONAR uma coluna club_id)
//   KEY_SCOPE  — o mesmo id legado (ex.: 'tadeu') pode existir em 2
//                clubes ao mesmo tempo SEM colidir? (NÃO resolvido só
//                adicionando club_id — depende da PK/UNIQUE mudar pra
//                composta, ou de uma chave surrogate nova)
//
// club_id (tenant scope) é ORTOGONAL à decisão de identidade da série F
// (person_id = pessoa canônica; feature id = chave editorial/gameplay;
// conteúdo editorial != domínio canônico) — adicionar club_id nunca
// significa "Career Path passa a consumir player_club_stats ao vivo".
// São eixos diferentes, nunca confundir.
//
// Pra cada tabela citada, o script confirma no arquivo .sql real se o
// padrão (PK/coluna) ainda existe — nunca confia numa lista estática sem
// checar. READ-ONLY.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

// scope: CANONICAL_GLOBAL_DATA | CLUB_SCOPED_DATA | USER_GLOBAL_DATA | FEATURE_GLOBAL_DATA
// rowScope: ALREADY_SCOPED | ADDING_CLUB_ID_SUFFICIENT | GLOBAL_NO_SCOPE_NEEDED
// keyScope: SAFE_COMPOSITE_OR_SURROGATE | COLLISION_RISK_LEGACY_ID_GLOBAL_PK | GLOBAL_NO_SCOPE_NEEDED
// classification: TENANT_SCOPE_REQUIRED | BUILD_LOCAL_ONLY | GLOBAL | NEEDS_DECISION
const tables = [
  // --- fundação canônica (Etapas B-F7) — já club-safe nos 2 eixos ---
  { table: 'people', file: 'supabase/migrations/20260901000000_create_people.sql', clubIdPattern: null, currentPrimaryKey: 'id uuid (gen_random_uuid)', scope: 'CANONICAL_GLOBAL_DATA', rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED', classification: 'GLOBAL', note: 'representa a PESSOA, nunca a relação com um clube.' },
  { table: 'clubs', file: 'supabase/migrations/20260902020000_create_clubs.sql', clubIdPattern: 'id uuid primary key', currentPrimaryKey: 'id uuid', scope: 'CANONICAL_GLOBAL_DATA', rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED', classification: 'GLOBAL', note: 'é o próprio registro de clubes — id UUID, slug text UNIQUE separado. Confirma o tipo correto pro §10: club_id em qualquer outra tabela deve ser uuid, nunca text apontando pro slug.' },
  { table: 'player_club_spells', file: 'supabase/migrations/20260902040000_create_player_club_spells.sql', clubIdPattern: 'club_id uuid not null references public.clubs(id)', currentPrimaryKey: 'id uuid; unique(person_id, club_id, spell_order)', scope: 'CLUB_SCOPED_DATA', rowScope: 'ALREADY_SCOPED', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE', classification: 'TENANT_SCOPE_REQUIRED', note: 'já resolvido nos 2 eixos — modelo de referência pra M2.' },
  { table: 'player_positions', file: 'supabase/migrations/20260902060000_create_player_positions.sql', clubIdPattern: 'club_id uuid not null references public.clubs(id)', currentPrimaryKey: 'id uuid; unique parcial c/ club_id', scope: 'CLUB_SCOPED_DATA', rowScope: 'ALREADY_SCOPED', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE', classification: 'TENANT_SCOPE_REQUIRED', note: null },
  { table: 'player_club_stats', file: 'supabase/migrations/20260902080000_create_player_club_stats.sql', clubIdPattern: 'club_id uuid not null references public.clubs(id)', currentPrimaryKey: 'id uuid; unique parcial c/ club_id', scope: 'CLUB_SCOPED_DATA', rowScope: 'ALREADY_SCOPED', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE', classification: 'TENANT_SCOPE_REQUIRED', note: null },
  { table: 'matches', file: 'supabase/migrations/20260902100000_create_matches.sql', clubIdPattern: 'home_club_id uuid references public.clubs(id)', currentPrimaryKey: 'id uuid', scope: 'CLUB_SCOPED_DATA', rowScope: 'ALREADY_SCOPED', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE', classification: 'TENANT_SCOPE_REQUIRED', note: 'simétrico (home/away), nunca "goias + adversário".' },
  { table: 'match_source_refs', file: 'supabase/migrations/20260902100000_create_matches.sql', clubIdPattern: 'source_club_id uuid references public.clubs(id)', currentPrimaryKey: 'id uuid; unique(source_namespace, source_ref)', scope: 'CLUB_SCOPED_DATA', rowScope: 'ALREADY_SCOPED', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE', classification: 'TENANT_SCOPE_REQUIRED', note: 'ATENÇÃO: source_club_id é só informativo — a unicidade real vem de unique(source_namespace, source_ref), convenção de namespace, não constraint sobre club_id.' },
  { table: 'player_match_appearances', file: 'supabase/migrations/20260902120000_create_player_match_appearances.sql', clubIdPattern: 'club_id uuid not null references public.clubs(id)', currentPrimaryKey: 'id uuid; unique(person_id, club_id, canonical_match_id)', scope: 'CLUB_SCOPED_DATA', rowScope: 'ALREADY_SCOPED', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE', classification: 'TENANT_SCOPE_REQUIRED', note: null },

  // --- CONTEÚDO club-specific — universo AMPLIADO (quiz_questions estava
  // faltando na 1ª rodada, adicionado agora) ---
  { table: 'career_players', file: 'supabase/career_players.sql', clubIdPattern: 'id text primary key', currentPrimaryKey: 'id text (ex.: "tadeu")', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'PK é só id (texto livre) — adicionar club_id resolve ROW_SCOPE (filtrar por clube) mas NÃO resolve KEY_SCOPE sozinho: "tadeu" ainda não poderia existir em 2 clubes ao mesmo tempo sem migrar a PK pra composta unique(club_id, id) ou pra um id surrogate novo. RPC arena_record_score confia em exists(select 1 from career_players where id = p_item_id) SEM filtro de clube (supabase/arena_ranking.sql) — precisaria ganhar club_id no predicado.' },
  { table: 'guess_players', file: 'supabase/guess_players.sql', clubIdPattern: 'id text primary key', currentPrimaryKey: 'id text', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'mesmo padrão de career_players — mesma entrada na RPC arena_record_score (case guess_player).' },
  { table: 'squad_members', file: 'supabase/squad_members.sql', clubIdPattern: 'id text primary key', currentPrimaryKey: 'id text', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'ÚNICA do grupo sem nenhuma tabela de progress/ranking dependente (confirmado — grep não achou referência fora de supabase/checkup.sql, que é só sanity check) — o mais simples de escopar dos 6, sem cadeia de RPC pra reconciliar.' },
  { table: 'lineup_matches', file: 'supabase/lineup_matches.sql', clubIdPattern: 'id text primary key', currentPrimaryKey: 'id text (ex.: "2021_csa_brB_g4")', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'PERMANECE explicitamente na lista de collision risk — corrige a contradição da rodada anterior do relatório (que listava esta tabela como COLLISION_RISK mas depois dizia que M2 nunca tocaria conteúdo editorial). Continua editorial/gameplay-driven (F7 intocada) — club_id aqui é só tenant scope, NUNCA person_id dentro do jsonb de slot.' },
  { table: 'passport_matches', file: 'supabase/passport_esmeraldino.sql', clubIdPattern: 'id text primary key', currentPrimaryKey: 'id text (ex.: "pe_...")', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'NEEDS_DECISION', note: 'ÚNICA tabela deste grupo com FK REAL de banco apontando pra ela (passport_attendances.match_id, passport_trajectory.match_id — confirmado via grep) — schema também é assimétrico (goias_is_home/goias_score/opponent, não home_club_id/away_club_id como matches). Coexistência de 2 clubes na MESMA tabela hoje exigiria redesenho de schema, não só uma coluna club_id — marcado NEEDS_DECISION, não TENANT_SCOPE_REQUIRED, porque a resposta não é mecânica.' },
  { table: 'quiz_questions', file: 'supabase/quiz_questions.sql', clubIdPattern: 'id text primary key', currentPrimaryKey: 'id text', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'estava AUSENTE da 1ª rodada da auditoria (só quiz_question_progress, a tabela de PROGRESSO, estava presente — a tabela de CONTEÚDO tinha ficado de fora do universo). Mesmo padrão RPC de career_players/guess_players/lineup_matches (case quiz em arena_record_score).' },

  // --- gamificação/progresso — plain-text ids, sem club_id ---
  { table: 'user_game_item_progress', file: 'supabase/arena_ranking.sql', clubIdPattern: 'primary key (user_id, game_id, item_id)', currentPrimaryKey: '(user_id, game_id, item_id)', scope: 'USER_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'item_id texto livre — mesmo problema de KEY_SCOPE que a tabela de conteúdo que referencia (encadeamento, ver §17 do relatório).' },
  { table: 'score_events', file: 'supabase/arena_ranking.sql', clubIdPattern: 'game_id text not null', currentPrimaryKey: 'id uuid (append-only)', scope: 'USER_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED', note: 'PK própria (uuid) nunca colide — o problema aqui é só ROW_SCOPE, nas RPCs de agregação (arena_ranking/arena_my_rank/arena_user_detail somam sem filtro de clube), nunca na tabela em si.', classification: 'TENANT_SCOPE_REQUIRED' },
  { table: 'lineup_match_progress', file: 'supabase/arena_progress.sql', clubIdPattern: 'primary key (user_id, match_id)', currentPrimaryKey: '(user_id, match_id)', scope: 'USER_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: null },
  { table: 'arena_selected_content', file: 'supabase/arena_progress.sql', clubIdPattern: 'primary key (user_id, game_id)', currentPrimaryKey: '(user_id, game_id) — nem inclui item_id', scope: 'USER_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'a mais frágil do grupo — PK nem tem item_id, só game_id.' },
  { table: 'quiz_question_progress', file: 'supabase/arena_progress.sql', clubIdPattern: 'primary key (user_id, question_id)', currentPrimaryKey: '(user_id, question_id)', scope: 'USER_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: null },
  { table: 'career_path_progress', file: 'supabase/arena_progress.sql', clubIdPattern: 'primary key (user_id, player_id)', currentPrimaryKey: '(user_id, player_id)', scope: 'USER_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: null },
  { table: 'match_lineup_votes', file: 'supabase/crowd_lineup.sql', clubIdPattern: 'unique (match_id, user_id)', currentPrimaryKey: 'id uuid; unique(match_id, user_id)', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: 'match_id sem FK real pra lineup_matches.id (confirmado — é só convenção, não constraint).' },
  { table: 'ticket_checkin_decisions', file: 'supabase/tickets.sql', clubIdPattern: 'primary key (user_id, match_id)', currentPrimaryKey: '(user_id, match_id)', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: null },
  { table: 'match_monitor_sessions', file: 'supabase/notifications.sql', clubIdPattern: 'match_id text primary key', currentPrimaryKey: 'match_id text', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK', classification: 'TENANT_SCOPE_REQUIRED', note: null },

  // --- USER/INFRA que precisa de tenant scope por razão de PRODUTO, não de PK legado ---
  { table: 'supporter_memberships', file: 'supabase/supporter_memberships.sql', clubIdPattern: 'create table if not exists public.supporter_memberships', currentPrimaryKey: 'id uuid (sem club_id nenhum)', scope: 'USER_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED', classification: 'TENANT_SCOPE_REQUIRED', note: 'CRITICAL — get_my_membership() é order by created_at desc limit 1 SEM filtro de clube nenhum. Aqui o problema é 100% ROW_SCOPE (não há id legado colidindo, o problema é a ausência total de dimensão de clube).' },
  { table: 'store_orders', file: 'supabase/store_orders.sql', clubIdPattern: 'create table if not exists public.store_orders', currentPrimaryKey: 'id uuid', scope: 'FEATURE_GLOBAL_DATA', rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED', classification: 'TENANT_SCOPE_REQUIRED', note: 'sem catálogo compartilhado hoje (product_id é snapshot jsonb, não FK) então 0 colisão de KEY_SCOPE ativa — mas order_prefix "GOI-" hardcoded e 0 conceito de clube (ROW_SCOPE).' },

  // --- dado de usuário genuinamente global ---
  { table: 'profiles', file: null, clubIdPattern: null, currentPrimaryKey: 'id uuid = auth.users.id', scope: 'USER_GLOBAL_DATA', rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED', classification: 'GLOBAL', note: 'SEM arquivo .sql no repo (criada direto no dashboard) — 1 pessoa pode torcer por clubes diferentes com a mesma conta, correto ficar global. Identidade do usuário != estado do usuário por clube (membership/progress/ranking SÃO club-scoped, profiles não é).' },
  { table: 'user_notification_tokens', file: 'supabase/notifications.sql', clubIdPattern: 'fcm_token', currentPrimaryKey: 'user_id + fcm_token unique', scope: 'USER_GLOBAL_DATA', rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED', classification: 'GLOBAL', note: 'token de device não é inerentemente de clube — mas user_notification_preferences precisaria de dimensão de clube se uma conta seguir 2 clubes (não auditado como tabela própria, é o mesmo arquivo).' },
];

// --- ENDURECIMENTO (rodada de correção da M1): KEY_SCOPE não é só a PK.
// Toda tabela agora carrega suas constraints estruturadas reais (PK,
// UNIQUE, FK), confirmadas contra o schema, pra que a auditoria considere
// PRIMARY KEY / UNIQUE / FK target — não só a PK. ACHADO NOVO desta
// rodada: career_players/guess_players/squad_members ganharam, na série F,
// `UNIQUE(person_id)` (constraints <tabela>_person_id_key, confirmadas em
// supabase/migrations/20260902{140000,160000,180000}_add_person_id_to_*.sql)
// — isso é um SEGUNDO problema de KEY_SCOPE além do id: hoje a mesma
// pessoa canônica não poderia aparecer na linha do clubA E na do clubB ao
// mesmo tempo. Candidato futuro (M2, NÃO alterado aqui): UNIQUE(club_id,
// person_id) quando person_id is not null — nunca UNIQUE(person_id) cru.
const PERSON_ID_FUTURE = 'UNIQUE(club_id, person_id) quando person_id is not null — permite a mesma pessoa em produtos de clubes diferentes sem perder a proteção 1:1 dentro de um mesmo clube';
const constraintDetails = {
  people: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [] },
  clubs: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['slug'] }], foreignKeys: [] },
  player_club_spells: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['person_id', 'club_id', 'spell_order'] }], foreignKeys: [{ columns: ['person_id'], references: 'people(id)' }, { columns: ['club_id'], references: 'clubs(id)' }] },
  player_positions: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['person_id', 'club_id', 'spell_id', 'position_code'] }, { columns: ['person_id', 'club_id', 'spell_id', 'position_order'] }], foreignKeys: [{ columns: ['person_id'], references: 'people(id)' }, { columns: ['club_id'], references: 'clubs(id)' }] },
  player_club_stats: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['person_id', 'club_id', 'scope', 'competition'] }], foreignKeys: [{ columns: ['person_id'], references: 'people(id)' }, { columns: ['club_id'], references: 'clubs(id)' }] },
  matches: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [{ columns: ['home_club_id'], references: 'clubs(id)' }, { columns: ['away_club_id'], references: 'clubs(id)' }] },
  match_source_refs: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['source_namespace', 'source_ref'] }], foreignKeys: [{ columns: ['source_club_id'], references: 'clubs(id)' }] },
  player_match_appearances: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['person_id', 'club_id', 'canonical_match_id'] }], foreignKeys: [{ columns: ['person_id'], references: 'people(id)' }, { columns: ['club_id'], references: 'clubs(id)' }] },
  career_players: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['person_id'], constraint: 'career_players_person_id_key', addedBy: 'supabase/migrations/20260902140000_add_person_id_to_career_players.sql', keyScopeRisk: true, futureMultiTenant: PERSON_ID_FUTURE }], foreignKeys: [{ columns: ['person_id'], references: 'people(id)' }] },
  guess_players: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['person_id'], constraint: 'guess_players_person_id_key', addedBy: 'supabase/migrations/20260902160000_add_person_id_to_guess_players.sql', keyScopeRisk: true, futureMultiTenant: PERSON_ID_FUTURE }], foreignKeys: [{ columns: ['person_id'], references: 'people(id)' }] },
  squad_members: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['person_id'], constraint: 'squad_members_person_id_key', addedBy: 'supabase/migrations/20260902180000_add_person_id_to_squad_members.sql', keyScopeRisk: true, futureMultiTenant: PERSON_ID_FUTURE }], foreignKeys: [{ columns: ['person_id'], references: 'people(id)' }] },
  lineup_matches: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [], note: 'person_id vive DENTRO do jsonb de slot (F7), nunca como coluna/constraint — logo não é um 2º eixo de KEY_SCOPE aqui, diferente de career_players/guess_players/squad_members.' },
  passport_matches: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [], note: 'não tem person_id nem club_id; é ALVO de 2 FKs (passport_attendances.match_id, passport_trajectory.match_id).' },
  quiz_questions: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [] },
  user_game_item_progress: { primaryKey: ['user_id', 'game_id', 'item_id'], uniqueConstraints: [], foreignKeys: [] },
  score_events: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [] },
  lineup_match_progress: { primaryKey: ['user_id', 'match_id'], uniqueConstraints: [], foreignKeys: [] },
  arena_selected_content: { primaryKey: ['user_id', 'game_id'], uniqueConstraints: [], foreignKeys: [] },
  quiz_question_progress: { primaryKey: ['user_id', 'question_id'], uniqueConstraints: [], foreignKeys: [] },
  career_path_progress: { primaryKey: ['user_id', 'player_id'], uniqueConstraints: [], foreignKeys: [] },
  match_lineup_votes: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['match_id', 'user_id'] }], foreignKeys: [] },
  ticket_checkin_decisions: { primaryKey: ['user_id', 'match_id'], uniqueConstraints: [], foreignKeys: [] },
  match_monitor_sessions: { primaryKey: ['match_id'], uniqueConstraints: [], foreignKeys: [] },
  supporter_memberships: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [] },
  store_orders: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['order_number'], global: true, note: 'sequência global public.store_order_number_seq — prefixo+sequência garantem unicidade global, candidato KEEP_GLOBAL (decisão de M2)' }], foreignKeys: [] },
  profiles: { primaryKey: ['id'], uniqueConstraints: [], foreignKeys: [{ columns: ['id'], references: 'auth.users(id)' }] },
  user_notification_tokens: { primaryKey: ['id'], uniqueConstraints: [{ columns: ['fcm_token'], global: true, note: 'token de device é globalmente único por natureza — KEEP_GLOBAL' }], foreignKeys: [] },
};

// Anexa as constraints estruturadas e deriva os 2 eixos como o pedido §5:
// keyScopeProblem passa a ser a UNIÃO de todas as fontes de KEY_SCOPE (a PK
// legada global + qualquer UNIQUE que impeça a mesma chave em 2 clubes,
// ex.: UNIQUE(person_id)), nunca só a PK.
function enrich(t, columnConfirmed) {
  const cd = constraintDetails[t.table] || { primaryKey: [], uniqueConstraints: [], foreignKeys: [] };
  const keyScopeSources = [];
  if (t.keyScope === 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK') {
    keyScopeSources.push({ kind: 'PRIMARY_KEY', columns: cd.primaryKey, reason: 'chave legada global (id/PK texto livre) — o mesmo id poderia existir em 2 clubes e colidir; club_id sozinho não resolve, precisa de PK composta unique(club_id, id) ou surrogate.' });
  }
  for (const u of cd.uniqueConstraints) {
    if (u.keyScopeRisk) {
      keyScopeSources.push({ kind: 'UNIQUE', columns: u.columns, constraint: u.constraint, reason: `UNIQUE(${u.columns.join(', ')}) força unicidade global dessa(s) coluna(s) — hoje impede a mesma pessoa em 2 clubes. Candidato futuro: ${u.futureMultiTenant}` });
    }
  }
  return {
    ...t,
    columnConfirmed,
    primaryKey: cd.primaryKey,
    uniqueConstraints: cd.uniqueConstraints,
    foreignKeys: cd.foreignKeys,
    rowScopeProblem: t.rowScope === 'ADDING_CLUB_ID_SUFFICIENT',
    keyScopeProblem: keyScopeSources.length > 0,
    keyScopeSources,
  };
}

const verified = [];
const staleNotes = [];
for (const t of tables) {
  if (!t.file) { verified.push(enrich(t, null)); continue; }
  const fullPath = path.join(ROOT, t.file);
  if (!fs.existsSync(fullPath)) { staleNotes.push({ table: t.table, reason: `arquivo ${t.file} não existe` }); continue; }
  const content = fs.readFileSync(fullPath, 'utf8');
  const columnConfirmed = t.clubIdPattern ? content.includes(t.clubIdPattern) : null;
  if (t.clubIdPattern && !columnConfirmed) { staleNotes.push({ table: t.table, reason: `padrão "${t.clubIdPattern}" não encontrado em ${t.file} — schema pode ter mudado` }); continue; }
  verified.push(enrich(t, columnConfirmed));
}

// --- FKs reais de banco (não convenção) apontando pras 6 tabelas de
// conteúdo — descoberto por grep, nunca assumido ---
const contentTables = ['career_players', 'guess_players', 'squad_members', 'lineup_matches', 'passport_matches', 'quiz_questions'];
const realForeignKeys = {};
const sqlDir = path.join(ROOT, 'supabase');
function grepSqlFiles(pattern) {
  const hits = [];
  for (const f of fs.readdirSync(sqlDir)) {
    if (!f.endsWith('.sql')) continue;
    const content = fs.readFileSync(path.join(sqlDir, f), 'utf8');
    for (const line of content.split('\n')) {
      if (line.includes(pattern)) hits.push({ file: `supabase/${f}`, line: line.trim() });
    }
  }
  return hits;
}
for (const t of contentTables) realForeignKeys[t] = grepSqlFiles(`references public.${t}`);

// --- cadeia de progresso/ranking (§17) — qual tabela de progresso
// depende de qual tabela de conteúdo, e a RPC central que amarra tudo ---
const progressChains = [
  { content: 'lineup_matches', progress: ['lineup_match_progress', 'arena_selected_content(game_id=lineup)'], ranking: ['user_game_item_progress(game_id=lineup)', 'score_events(game_id=lineup)'], rpc: 'arena_record_score — case lineup: exists(select 1 from lineup_matches where id = p_item_id)' },
  { content: 'career_players', progress: ['career_path_progress', 'arena_selected_content(game_id=career_path)'], ranking: ['user_game_item_progress(game_id=career_path)', 'score_events(game_id=career_path)'], rpc: 'arena_record_score — case career_path: exists(select 1 from career_players where id = p_item_id)' },
  { content: 'guess_players', progress: [], ranking: ['user_game_item_progress(game_id=guess_player)', 'score_events(game_id=guess_player)'], rpc: 'arena_record_score — case guess_player: exists(select 1 from guess_players where id = p_item_id)' },
  { content: 'quiz_questions', progress: ['quiz_question_progress', 'quiz_active_session(por difficulty, não por id)'], ranking: ['user_game_item_progress(game_id=quiz)', 'score_events(game_id=quiz)'], rpc: 'arena_record_score — case quiz: exists(select 1 from quiz_questions where id = p_item_id)' },
  { content: 'squad_members', progress: [], ranking: [], rpc: 'nenhuma — squad_members não alimenta nenhum jogo/progresso, confirmado por grep (só supabase/checkup.sql referencia, e é sanity check).' },
];

const stats = {
  totalTables: tables.length,
  verified: verified.length,
  stale: staleNotes.length,
  staleList: staleNotes,
  byScope: verified.reduce((acc, t) => { acc[t.scope] = (acc[t.scope] || 0) + 1; return acc; }, {}),
  byClassification: verified.reduce((acc, t) => { acc[t.classification] = (acc[t.classification] || 0) + 1; return acc; }, {}),
  byRowScope: verified.reduce((acc, t) => { acc[t.rowScope] = (acc[t.rowScope] || 0) + 1; return acc; }, {}),
  byKeyScope: verified.reduce((acc, t) => { acc[t.keyScope] = (acc[t.keyScope] || 0) + 1; return acc; }, {}),
  needsDecisionTables: verified.filter((t) => t.classification === 'NEEDS_DECISION').map((t) => t.table),
  keyScopeCollisionTables: verified.filter((t) => t.keyScope === 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK').map((t) => t.table),
  keyScopeProblemTables: verified.filter((t) => t.keyScopeProblem).map((t) => t.table),
  rowScopeProblemTables: verified.filter((t) => t.rowScopeProblem).map((t) => t.table),
  // ACHADO desta rodada: KEY_SCOPE por UNIQUE(person_id), um 2º eixo além
  // da PK legada — nas 3 tabelas de conteúdo "de pessoa".
  personIdUniqueKeyScopeTables: verified
    .filter((t) => t.keyScopeSources.some((s) => s.kind === 'UNIQUE' && s.columns.length === 1 && s.columns[0] === 'person_id'))
    .map((t) => t.table),
  contentTablesWithRealFk: Object.fromEntries(Object.entries(realForeignKeys).map(([k, v]) => [k, v.length])),
  clubIdTypeRecommendation: { type: 'uuid', references: 'clubs(id)', neverUse: 'text references clubs(slug)', confirmedClubsIdType: 'uuid (supabase/migrations/20260902020000_create_clubs.sql)' },
};
// Invariante estrutural (§2 do pedido de endurecimento): a soma de todas
// as classificações tem de fechar com o total de tabelas auditadas — se
// alguma tabela ficar stale/fora do universo, isso quebra e o teste pega.
stats.classificationSum = Object.values(stats.byClassification).reduce((a, b) => a + b, 0);

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_data_scope_audit.json'), JSON.stringify({ tables: verified, stale: staleNotes, realForeignKeys, progressChains }, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_data_scope_audit_stats.json'), JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);

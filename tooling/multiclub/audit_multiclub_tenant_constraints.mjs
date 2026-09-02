// ============================================================================
// Etapa M2.1 — Tenant Scope & Legacy Key Compatibility (AUDITORIA/DESIGN,
// read-only). NUNCA gera migration, NUNCA escreve no Supabase, NUNCA toca
// consumidor Flutter — só lê o schema/código real e classifica.
//
// Dois eixos, sempre independentes (nunca confundidos):
//   ROW_SCOPE  — dá pra garantir que o app do clubA não receba linha do
//                clubB? (resolvido por uma coluna club_id + filtro)
//   KEY_SCOPE  — clubA e clubB podem usar a MESMA chave legada (id/UNIQUE)
//                sem colidir? (NÃO resolvido só por club_id — depende de
//                PK/UNIQUE composta ou surrogate)
//
// Classificação de UNIQUE (item 13 do pedido):
//   KEEP_GLOBAL       — unicidade correta globalmente (ex.: fcm_token,
//                       order_number por sequência) — não ganha club_id
//   NEEDS_CLUB_SCOPE  — precisa virar unique(club_id, ...) pra permitir a
//                       mesma chave em 2 clubes
//   NEEDS_REDESIGN    — nem club_id nem composta resolvem sozinhos; exige
//                       decisão de schema/produto (ex.: passport_matches)
//
// Cada tabela cita padrões REAIS do .sql; o script confirma que ainda
// existem (staleness guard), nunca confia numa lista estática. Determinístico
// e reproduzível byte a byte.
// ============================================================================
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT, 'data_export', 'goias', 'player_reconciliation');

const GOIAS_CLUB_UUID = '4c16340d-300c-5ab2-903f-17519db9b146';

// rls.model: OWNER (auth.uid()=user_id) | PUBLIC_READ (using true) |
//            SERVICE_ROLE (using false, só service_role) | USER_PK
// rowScope: ADDING_CLUB_ID_SUFFICIENT | ALREADY_SCOPED | GLOBAL_NO_SCOPE_NEEDED
// keyScope: COLLISION_RISK_LEGACY_ID_GLOBAL_PK | PERSON_ID_UNIQUE_COLLISION |
//           SAFE_COMPOSITE_OR_SURROGATE | GLOBAL_NO_SCOPE_NEEDED
// tenantStrategy: TENANT_COLUMN_ONLY | COMPOSITE_PK | SURROGATE_PK |
//                 KEEP_GLOBAL | NEEDS_PRODUCT_DECISION | ALREADY_SAFE
const tables = [
  // ===== CONTEÚDO editorial club-specific (as 6 da matriz M1) =====
  {
    table: 'career_players', file: 'supabase/career_players.sql', group: 'CONTENT',
    verify: ['id text primary key'],
    pk: ['id'], uniques: [{ cols: ['person_id'], class: 'NEEDS_CLUB_SCOPE', addedBy: 'migrations/20260902140000', future: 'unique(club_id, person_id) where person_id is not null' }],
    fks: [{ cols: ['person_id'], ref: 'people(id)', addedBy: 'migrations/20260902140000' }], inboundFks: [],
    rls: { enabled: true, model: 'PUBLIC_READ', tenantAware: false }, checks: [],
    rpcReads: ['arena_record_score (case career_path: exists(... where id=p_item_id))'], rpcWrites: [],
    repos: ['mock_career_path_repository / supabase career fetch (.from(career_players))'], worker: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK id text legado global', 'UNIQUE(person_id) — mesma pessoa não pode aparecer em 2 clubes'],
    tenantStrategy: 'COMPOSITE_PK_OR_SURROGATE', chainOwner: 'career_path',
    note: 'club_id resolve ROW_SCOPE; KEY_SCOPE exige composta unique(club_id,id) OU surrogate row_id + unique(club_id,id), e o UNIQUE(person_id) vira unique(club_id, person_id). Progresso encadeado: career_path_progress → user_game_item_progress → score_events → arena_record_score.',
  },
  {
    table: 'guess_players', file: 'supabase/guess_players.sql', group: 'CONTENT',
    verify: ['id text primary key'],
    pk: ['id'], uniques: [{ cols: ['person_id'], class: 'NEEDS_CLUB_SCOPE', addedBy: 'migrations/20260902160000', future: 'unique(club_id, person_id) where person_id is not null' }],
    fks: [{ cols: ['person_id'], ref: 'people(id)', addedBy: 'migrations/20260902160000' }], inboundFks: [],
    rls: { enabled: true, model: 'PUBLIC_READ', tenantAware: false }, checks: ["data_status in ('verified','review','incomplete')"],
    rpcReads: ['arena_record_score (case guess_player)'], rpcWrites: [],
    repos: ['.from(guess_players)'], worker: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK id text legado global', 'UNIQUE(person_id)'],
    tenantStrategy: 'COMPOSITE_PK_OR_SURROGATE', chainOwner: 'guess_player',
    note: 'sem cadeia de progress próprio (só user_game_item_progress/score_events via arena_record_score).',
  },
  {
    table: 'squad_members', file: 'supabase/squad_members.sql', group: 'CONTENT',
    verify: ['id text primary key'],
    pk: ['id'], uniques: [{ cols: ['person_id'], class: 'NEEDS_CLUB_SCOPE', addedBy: 'migrations/20260902180000', future: 'unique(club_id, person_id) where person_id is not null' }],
    fks: [{ cols: ['person_id'], ref: 'people(id)', addedBy: 'migrations/20260902180000' }], inboundFks: [],
    rls: { enabled: true, model: 'PUBLIC_READ', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(squad_members)'], worker: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK id text legado global', 'UNIQUE(person_id)'],
    tenantStrategy: 'COMPOSITE_PK_OR_SURROGATE', chainOwner: null,
    note: 'ÚNICA tabela de conteúdo sem cadeia de progress/ranking — a mais simples de escopar. É fonte de foto (squadPhotoAssets) mas não alimenta RPC.',
  },
  {
    table: 'lineup_matches', file: 'supabase/lineup_matches.sql', group: 'CONTENT',
    verify: ['id text primary key'],
    pk: ['id'], uniques: [], fks: [], inboundFks: [],
    rls: { enabled: true, model: 'PUBLIC_READ', tenantAware: false }, checks: [],
    rpcReads: ['arena_record_score (case lineup)'], rpcWrites: [],
    repos: ['.from(lineup_matches)'], worker: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK id text legado global ("2021_csa_brB_g4")'],
    tenantStrategy: 'COMPOSITE_PK_OR_SURROGATE', chainOwner: 'lineup',
    f7Preserved: true,
    note: 'club_id é só tenancy da LINHA (COMPOSITE_PK ou SURROGATE). O JSON dos 11 jogadores permanece editorial e SEM person_id — decisão F7 preservada: person_id NUNCA entra em cada slot do jsonb; a identidade canônica futura mora em player_match_appearances/provenance/people, nunca no slot. Não há eixo UNIQUE(person_id) aqui (é diferente de career/guess/squad, que têm a coluna). Cadeia: lineup_match_progress + arena_selected_content(game_id=lineup) → user_game_item_progress → score_events → arena_record_score.',
  },
  {
    table: 'quiz_questions', file: 'supabase/quiz_questions.sql', group: 'CONTENT',
    verify: ['id text primary key'],
    pk: ['id'], uniques: [], fks: [], inboundFks: [],
    rls: { enabled: true, model: 'PUBLIC_READ', tenantAware: false }, checks: [],
    rpcReads: ['arena_record_score (case quiz)'], rpcWrites: [],
    repos: ['.from(quiz_questions)'], worker: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK id text legado global'],
    tenantStrategy: 'COMPOSITE_PK_OR_SURROGATE', chainOwner: 'quiz',
    note: 'cadeia: quiz_question_progress + quiz_active_session(por difficulty) → user_game_item_progress → score_events.',
  },
  {
    table: 'passport_matches', file: 'supabase/passport_esmeraldino.sql', group: 'CONTENT',
    verify: ['create table if not exists public.passport_matches', 'goias_is_home', 'opponent text not null'],
    pk: ['id'], uniques: [], fks: [{ cols: ['venue_id'], ref: 'venues(id)' }],
    inboundFks: [{ from: 'passport_attendances.match_id' }, { from: 'passport_memorable_matches.match_id' }],
    rls: { enabled: true, model: 'PUBLIC_READ', tenantAware: false }, checks: ['status/outcome/date_precision enums'],
    rpcReads: ['passport_ranking / passport_my_rank (via passport_attendances)'], rpcWrites: [],
    repos: ['.from via passport repo'], worker: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK id text legado global ("pe_...")', 'schema ASSIMÉTRICO (goias_is_home/goias_score/opponent) — não modela 2 clubes na mesma linha'],
    tenantStrategy: 'NEEDS_PRODUCT_DECISION', chainOwner: 'passport',
    note: 'ÚNICA com 2 FKs reais apontando pra ela + schema assimétrico. Já tem home_team/away_team/home_score/away_score em paralelo aos goias_* — meio caminho pra simétrico. Ver §19 (A/B/C).',
  },

  // ===== PROGRESSO / USER-STATE (club-scoped por produto) =====
  {
    table: 'user_game_item_progress', file: 'supabase/arena_ranking.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, game_id, item_id)'],
    pk: ['user_id', 'game_id', 'item_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER_READ_ONLY', tenantAware: false }, checks: [],
    rpcReads: ['arena_ranking (indireto via score_events)', 'arena_user_detail', 'arena_record_score (for update)'],
    rpcWrites: ['arena_record_score (security definer upsert)'], repos: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['item_id text livre (career_players.id/quiz_questions.id/...) — colide junto com a tabela de conteúdo que referencia'],
    tenantStrategy: 'COMPOSITE_PK (add club_id à PK)', chainOwner: null,
    note: 'CORAÇÃO da cadeia de pontos. Escrito SÓ pela RPC arena_record_score (sem policy de insert/update). club_id tem de viajar pra PK e pra RPC, senão o meio da cadeia fica sem filtro.',
  },
  {
    table: 'score_events', file: 'supabase/arena_ranking.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.score_events', 'id uuid primary key'],
    pk: ['id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER_READ_ONLY', tenantAware: false }, checks: [],
    rpcReads: ['arena_ranking / arena_my_rank (agregam sum(points_delta) SEM filtro de clube)'],
    rpcWrites: ['arena_record_score (append-only insert)'], repos: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'TENANT_COLUMN_ONLY', chainOwner: null,
    note: 'PK própria uuid nunca colide (KEY_SCOPE ok). O problema é 100% ROW_SCOPE nas RPCs de agregação de ranking, que somam cross-club hoje. club_id na coluna + no group by/where da RPC.',
  },
  {
    table: 'quiz_question_progress', file: 'supabase/arena_progress.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, question_id)'],
    pk: ['user_id', 'question_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(quiz_question_progress)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['question_id text livre'], tenantStrategy: 'COMPOSITE_PK', chainOwner: null,
    note: 'escrito direto pelo cliente (policies de insert/update próprias) — diferente de user_game_item_progress.',
  },
  {
    table: 'quiz_active_session', file: 'supabase/arena_progress.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, difficulty)'],
    pk: ['user_id', 'difficulty'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(quiz_active_session)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'COMPOSITE_PK (add club_id à PK)', chainOwner: null,
    note: 'PK (user, difficulty) — difficulty é enum global, mas a sessão contém question_ids de um clube; precisa de club_id na PK pra 2 clubes coexistirem por usuário.',
  },
  {
    table: 'lineup_match_progress', file: 'supabase/arena_progress.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, match_id)'],
    pk: ['user_id', 'match_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(lineup_match_progress)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['match_id text livre (= lineup_matches.id, sem FK real)'], tenantStrategy: 'COMPOSITE_PK', chainOwner: null, note: null,
  },
  {
    table: 'career_path_progress', file: 'supabase/arena_progress.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, player_id)'],
    pk: ['user_id', 'player_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(career_path_progress)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['player_id text livre (= career_players.id)'], tenantStrategy: 'COMPOSITE_PK', chainOwner: null, note: null,
  },
  {
    table: 'arena_selected_content', file: 'supabase/arena_progress.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, game_id)'],
    pk: ['user_id', 'game_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(arena_selected_content)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK nem inclui item_id (só user_id, game_id) — a mais frágil; selected_id text guarda o conteúdo de um clube'],
    tenantStrategy: 'COMPOSITE_PK (add club_id à PK)', chainOwner: null, note: 'sem club_id, o "último item visto" de 2 clubes disputaria a mesma linha por (user, game).',
  },
  {
    table: 'arena_achievements', file: 'supabase/arena_progress.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, achievement_id)'],
    pk: ['user_id', 'achievement_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(arena_achievements)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['achievement_id text livre — a mesma conquista existiria nos 2 clubes'], tenantStrategy: 'COMPOSITE_PK', chainOwner: null, note: null,
  },
  {
    table: 'player_identity_results', file: 'supabase/player_identity_results.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.player_identity_results', 'primary key'],
    pk: ['user_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }, { cols: ['closest_player_id'], ref: '(convenção, sem FK) squad/guess id' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(player_identity_results)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'COMPOSITE_PK (add club_id à PK)', chainOwner: null,
    note: 'PK = user_id (1 resultado por usuário). closest_player_id é de um clube; pra 2 clubes, PK vira (user_id, club_id). Sem ranking.',
  },
  {
    table: 'tactical_identity_results', file: 'supabase/tactical_identity_results.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.tactical_identity_results', 'primary key'],
    pk: ['user_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(tactical_identity_results)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'COMPOSITE_PK (add club_id à PK)', chainOwner: null,
    note: 'idêntico a player_identity_results (closest_coach_id de um clube).',
  },
  {
    table: 'passport_attendances', file: 'supabase/passport_esmeraldino.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.passport_attendances', 'unique (user_id, match_id)', 'references public.passport_matches (id)'],
    pk: ['id'], uniques: [{ cols: ['user_id', 'match_id'], class: 'NEEDS_CLUB_SCOPE_VIA_MATCH' }],
    fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }, { cols: ['match_id'], ref: 'passport_matches(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER_READ_RPC_WRITE', tenantAware: false }, checks: [],
    rpcReads: ['passport_ranking', 'passport_my_rank'], rpcWrites: ['passport_save_attendances (security definer)'], repos: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE',
    keyScopeSources: [], tenantStrategy: 'INHERITS_FROM_PASSPORT_MATCHES',
    chainOwner: null, note: 'tem FK REAL pra passport_matches(id). Se passport_matches ganhar club_id/redesign, a tenancy aqui herda via match_id. unique(user_id, match_id) já é seguro se match_id for tenant-safe.',
  },
  {
    table: 'passport_memorable_matches', file: 'supabase/passport_trajectory.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.passport_memorable_matches', 'references public.passport_matches (id)'],
    pk: ['user_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }, { cols: ['match_id'], ref: 'passport_matches(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: ['passport_attended_matches / passport_stadium_summary'], rpcWrites: ['passport_set_memorable_match (security definer)'], repos: [],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'SAFE_COMPOSITE_OR_SURROGATE',
    keyScopeSources: [], tenantStrategy: 'INHERITS_FROM_PASSPORT_MATCHES', chainOwner: null,
    note: '2º dependente FK REAL de passport_matches (a tabela se chama passport_memorable_matches; "passport_trajectory" é o nome da feature Flutter/arquivo, NÃO da tabela — correção sobre o relatório M1). PK user_id = 1 partida memorável por usuário; tenancy herda de passport_matches via match_id (redesign §19 propaga aqui). Se uma conta seguir 2 clubes, a PK user_id precisaria de club_id.',
  },
  {
    table: 'match_lineup_votes', file: 'supabase/crowd_lineup.sql', group: 'PROGRESS',
    verify: ['unique (match_id, user_id)', 'create or replace function public.crowd_lineup'],
    pk: ['id'], uniques: [{ cols: ['match_id', 'user_id'], class: 'NEEDS_CLUB_SCOPE' }],
    fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: ['crowd_lineup(p_match_id) — agrega TODOS os votos do match_id, security definer, SEM filtro de clube'], rpcWrites: [], repos: ['.from(match_lineup_votes)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['match_id text livre sem FK (convenção)', 'UNIQUE(match_id, user_id) — 1 voto por jogo; se 2 clubes tiverem o mesmo match_id, o voto de um clube bloquearia o do outro'],
    tenantStrategy: 'NEEDS_CLUB_SCOPE (unique vira (club_id, match_id, user_id))', chainOwner: null,
    note: 'a RPC crowd_lineup agrega por match_id — colisão de match_id entre clubes misturaria as escalações da torcida.',
  },
  {
    table: 'ticket_checkin_decisions', file: 'supabase/tickets.sql', group: 'PROGRESS',
    verify: ['primary key (user_id, match_id)', "decision in ('confirmed', 'declined')"],
    pk: ['user_id', 'match_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: ["decision in ('confirmed','declined')"],
    rpcReads: [], rpcWrites: [], repos: ['.from(ticket_checkin_decisions)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['match_id text livre na PK'], tenantStrategy: 'COMPOSITE_PK', chainOwner: null, note: null,
  },
  {
    table: 'ticket_orders', file: 'supabase/tickets.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.ticket_orders', 'home_team_id int not null'],
    pk: ['id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [{ from: 'tickets.order_id' }],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(ticket_orders)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'TENANT_COLUMN_ONLY', chainOwner: null,
    note: 'PK uuid (ok). Carrega home_team_id/away_team_id/home_team_name na linha (identidade de time embutida) + match_id/number texto. ROW_SCOPE via club_id; number é humano, não único global.',
  },
  {
    table: 'tickets', file: 'supabase/tickets.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.tickets', 'tickets_user_match_checkin_uidx'],
    pk: ['id'], uniques: [{ cols: ['user_id', 'match_id'], partial: "where origin='membership_check_in'", class: 'NEEDS_CLUB_SCOPE' }],
    fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }, { cols: ['order_id'], ref: 'ticket_orders(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: ['status/origin enums'],
    rpcReads: [], rpcWrites: [], repos: ['.from(tickets)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['índice único parcial (user_id, match_id) where origin=membership_check_in — colide se 2 clubes tiverem o mesmo match_id'],
    tenantStrategy: 'NEEDS_CLUB_SCOPE (índice parcial vira (club_id, user_id, match_id))', chainOwner: null, note: null,
  },
  {
    table: 'store_orders', file: 'supabase/store_orders.sql', group: 'PROGRESS',
    verify: ['order_number text not null unique', 'store_order_number_seq', 'create or replace function public.create_store_order'],
    pk: ['id'], uniques: [{ cols: ['order_number'], class: 'KEEP_GLOBAL', global: true }],
    fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [{ from: 'store_order_items.order_id' }],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: ['create_store_order (SEM security definer, roda como caller)'], repos: ['.from(store_orders)', 'create_store_order rpc'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'TENANT_COLUMN_ONLY (order_number KEEP_GLOBAL)', chainOwner: null,
    note: "order_number = 'GOI-' || ano || sequência global — prefixo 'GOI-' hardcoded na generate_store_order_number(); em M3/M4 o prefixo vem de ClubConfig.integrations.orderPrefix. Unicidade por sequência é global, KEEP_GLOBAL.",
  },
  {
    table: 'store_order_items', file: 'supabase/store_orders.sql', group: 'PROGRESS',
    verify: ['create table if not exists public.store_order_items', 'references public.store_orders(id)'],
    pk: ['id'], uniques: [], fks: [{ cols: ['order_id'], ref: 'store_orders(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER_VIA_PARENT', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: ['create_store_order'], repos: [],
    rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'INHERITS_FROM_STORE_ORDERS', chainOwner: null,
    note: 'tenancy herda de store_orders via order_id (FK real). product_id é snapshot jsonb-like, não FK — 0 colisão.',
  },
  {
    table: 'supporter_memberships', file: 'supabase/supporter_memberships.sql', group: 'MEMBERSHIP',
    verify: ['create table if not exists public.supporter_memberships', 'create or replace function public.get_my_membership', 'order by m.created_at desc'],
    pk: ['id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER_INSERT_SELECT', tenantAware: false }, checks: [],
    rpcReads: ['get_my_membership() — order by created_at desc limit 1, SEM filtro de clube'], rpcWrites: [], repos: ['.from + get_my_membership rpc'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'TENANT_COLUMN_ONLY', chainOwner: null,
    critical: true,
    note: 'CRITICAL — sem club_id, get_my_membership() devolveria a assinatura mais recente de QUALQUER clube. Contrato futuro precisa de p_club_id explícito (o Postgres não conhece APP_CLUB). arena_ranking.is_member já está hardcoded false (dívida separada).',
  },

  // ===== NOTIFICATIONS / INFRA (service-role ou device) =====
  {
    table: 'user_notification_tokens', file: 'supabase/notifications.sql', group: 'NOTIFICATIONS',
    verify: ['fcm_token text not null unique', "platform in ('android', 'ios')"],
    pk: ['id'], uniques: [{ cols: ['fcm_token'], class: 'KEEP_GLOBAL', global: true }],
    fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [{ from: 'notification_deliveries.token_id' }],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: ['platform enum'],
    rpcReads: [], rpcWrites: [], repos: ['.from(user_notification_tokens)'],
    rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'KEEP_GLOBAL', chainOwner: null,
    note: 'token de device é globalmente único por natureza (1 device → 1 conta). NÃO ganha club_id.',
  },
  {
    table: 'user_notification_preferences', file: 'supabase/notifications.sql', group: 'NOTIFICATIONS',
    verify: ['create table if not exists public.user_notification_preferences', 'matches_enabled', 'tickets_enabled'],
    pk: ['user_id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: [], rpcWrites: [], repos: ['.from(user_notification_preferences)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['PK user_id — 1 linha de preferência por usuário, sem dimensão de clube'],
    tenantStrategy: 'COMPOSITE_PK (PK vira (user_id, club_id))', chainOwner: null,
    note: 'PROVAVELMENTE vira (user_id, club_id): matches_enabled/tickets_enabled são por-clube — "mesmo usuário: clubA jogos ON, clubB jogos OFF" é estado válido. Entra no tenant/KEY_SCOPE design (não é só ROW_SCOPE). user_notification_tokens continua GLOBAL (device), mas as PREFERÊNCIAS não.',
  },
  {
    table: 'match_monitor_sessions', file: 'supabase/notifications.sql', group: 'NOTIFICATIONS',
    verify: ['match_id text primary key', 'service role only'],
    pk: ['match_id'], uniques: [], fks: [], inboundFks: [],
    rls: { enabled: true, model: 'SERVICE_ROLE', tenantAware: false }, checks: ['status enum'],
    rpcReads: [], rpcWrites: ['Edge Functions (service_role)'], repos: [], worker: ['poll de gol/full_time (Cron)'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['match_id text PK — provider id; se 2 clubes usarem o mesmo namespace de match_id, colide'],
    tenantStrategy: 'NEEDS_CLUB_SCOPE (match_id + club_id, ou provar namespace global)', chainOwner: null,
    note: 'não é dado de usuário (só service_role). Depende da PROVENIÊNCIA do match_id (§20).',
  },
  {
    table: 'notification_events', file: 'supabase/notifications.sql', group: 'NOTIFICATIONS',
    verify: ['create table if not exists public.notification_events', 'unique (event_type, dedupe_key)', "event_type in ('match_access_open', 'goal', 'full_time')"],
    pk: ['id'], uniques: [{ cols: ['event_type', 'dedupe_key'], class: 'NEEDS_REDESIGN_OR_NAMESPACE', global: true }],
    fks: [], inboundFks: [{ from: 'notification_deliveries.event_id' }],
    rls: { enabled: true, model: 'SERVICE_ROLE', tenantAware: false }, checks: ['event_type/status enums'],
    rpcReads: [], rpcWrites: ['Edge Functions'], repos: [], worker: ['detecção de gol/full_time'],
    rowScope: 'ADDING_CLUB_ID_SUFFICIENT', keyScope: 'COLLISION_RISK_LEGACY_ID_GLOBAL_PK',
    keyScopeSources: ['UNIQUE(event_type, dedupe_key) — dedupe GLOBAL; um "goal" de fixture X de 2 clubes com dedupe_key colidente seria de-duplicado indevidamente (um clube não notificaria)'],
    tenantStrategy: 'NEEDS_CLUB_SCOPE (dedupe_key precisa incluir club_id OU o namespace do provider tem de ser provado globalmente único)', chainOwner: null,
    note: 'achado do item 21: a dedupe_key precisa ser única POR clube, não global, senão eventos de clubes diferentes se anulam.',
  },
  {
    table: 'notification_deliveries', file: 'supabase/notifications.sql', group: 'NOTIFICATIONS',
    verify: ['create table if not exists public.notification_deliveries', 'unique (event_id, token_id)'],
    pk: ['id'], uniques: [{ cols: ['event_id', 'token_id'], class: 'KEEP_GLOBAL', global: true }],
    fks: [{ cols: ['event_id'], ref: 'notification_events(id)' }, { cols: ['token_id'], ref: 'user_notification_tokens(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'SERVICE_ROLE', tenantAware: false }, checks: ['status enum'],
    rpcReads: [], rpcWrites: ['Edge Functions'], repos: [],
    rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'INHERITS_FROM_EVENT (via event_id FK)', chainOwner: null,
    note: 'unique(event_id, token_id) usa uuids reais — herda tenancy do notification_events. KEEP_GLOBAL.',
  },

  // ===== USER-GLOBAL (não é club-scoped) =====
  {
    table: 'profiles', file: null, group: 'USER_GLOBAL',
    verify: [], pk: ['id'], uniques: [], fks: [{ cols: ['id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    rpcReads: ['arena_ranking (join pr.full_name/avatar_url)'], rpcWrites: [], repos: ['.from(profiles)'],
    rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'KEEP_GLOBAL', chainOwner: null,
    note: 'SEM .sql no repo (criada no dashboard — lacuna documentada). Identidade do usuário é global: 1 conta pode torcer por 2 clubes sem duplicar perfil.',
  },
  {
    table: 'delivery_addresses', file: 'supabase/delivery_addresses.sql', group: 'USER_GLOBAL',
    verify: ['create table if not exists public.delivery_addresses', 'delivery_address_enforce_single_default'],
    pk: ['id'], uniques: [], fks: [{ cols: ['user_id'], ref: 'auth.users(id)' }], inboundFks: [],
    rls: { enabled: true, model: 'OWNER', tenantAware: false }, checks: [],
    triggers: ['delivery_addresses_ensure_default (before insert)', 'delivery_addresses_single_default (before insert/update)'],
    rpcReads: [], rpcWrites: [], repos: ['.from(delivery_addresses)'],
    rowScope: 'GLOBAL_NO_SCOPE_NEEDED', keyScope: 'GLOBAL_NO_SCOPE_NEEDED',
    keyScopeSources: [], tenantStrategy: 'KEEP_GLOBAL', chainOwner: null,
    note: 'endereço de entrega da pessoa não é de clube — a MESMA lista serve compras de qualquer loja. KEEP_GLOBAL. store_orders.address é snapshot congelado, não FK.',
  },
];

const verified = [];
const staleNotes = [];
for (const t of tables) {
  const rec = {
    ...t,
    rowScopeProblem: t.rowScope === 'ADDING_CLUB_ID_SUFFICIENT',
    keyScopeProblem: (t.keyScopeSources || []).length > 0,
    fileConfirmed: null,
  };
  if (!t.file) { verified.push(rec); continue; }
  const full = path.join(ROOT, t.file);
  if (!fs.existsSync(full)) { staleNotes.push({ table: t.table, reason: `arquivo ${t.file} não existe` }); continue; }
  const content = fs.readFileSync(full, 'utf8');
  const missing = (t.verify || []).filter((p) => !content.includes(p));
  if (missing.length) { staleNotes.push({ table: t.table, reason: `padrões ausentes em ${t.file}: ${JSON.stringify(missing)}` }); continue; }
  rec.fileConfirmed = true;
  verified.push(rec);
}

// --- classificação de UNIQUE agregada (item 13) ---
const uniqueDecisions = [];
for (const t of verified) {
  for (const u of t.uniques || []) {
    uniqueDecisions.push({ table: t.table, columns: u.cols, class: u.class, global: !!u.global, partial: u.partial || null, future: u.future || null });
  }
}

// --- proveniência de match_id (item 23) — de onde vêm as chaves externas ---
const externalKeyProvenance = {
  match_id: {
    tablesUsing: ['lineup_match_progress', 'ticket_checkin_decisions', 'ticket_orders', 'tickets', 'match_lineup_votes', 'match_monitor_sessions', 'passport_matches(pe_...)'],
    provider: 'OneFootball (slug goias-1863, team id 1863) para partidas ao vivo; passport usa id próprio "pe_...". Worker confirma acoplamento: src/football/_lib/config.ts (GOIAS_ONEFOOTBALL_SLUG), isGoias em standing/match normalizado.',
    globallyUniqueProven: false,
    risk: 'match_id NÃO tem namespace globalmente provado único entre clubes — precisa entrar na key (club_id) OU provar origem antes de confiar. Nunca presumir que ids do provider são distintos/iguais entre clubes.',
  },
};

// --- cadeias de progresso (item 18) ---
const progressChains = [
  { game: 'career_path', content: 'career_players', chain: ['career_path_progress', 'arena_selected_content(game_id=career_path)', 'user_game_item_progress(game_id=career_path)', 'score_events(game_id=career_path)'], rpc: 'arena_record_score (case career_path)', clubIdMustTravel: ['career_players', 'career_path_progress', 'arena_selected_content', 'user_game_item_progress', 'score_events', 'arena_record_score(p_club_id)', 'arena_ranking/arena_my_rank/arena_user_detail (where club_id)'] },
  { game: 'lineup', content: 'lineup_matches', chain: ['lineup_match_progress', 'arena_selected_content(game_id=lineup)', 'user_game_item_progress(game_id=lineup)', 'score_events(game_id=lineup)'], rpc: 'arena_record_score (case lineup)', clubIdMustTravel: ['lineup_matches', 'lineup_match_progress', 'arena_selected_content', 'user_game_item_progress', 'score_events', 'arena_record_score(p_club_id)'] },
  { game: 'quiz', content: 'quiz_questions', chain: ['quiz_question_progress', 'quiz_active_session(por difficulty)', 'user_game_item_progress(game_id=quiz)', 'score_events(game_id=quiz)'], rpc: 'arena_record_score (case quiz)', clubIdMustTravel: ['quiz_questions', 'quiz_question_progress', 'quiz_active_session', 'user_game_item_progress', 'score_events', 'arena_record_score(p_club_id)'] },
  { game: 'guess_player', content: 'guess_players', chain: ['user_game_item_progress(game_id=guess_player)', 'score_events(game_id=guess_player)'], rpc: 'arena_record_score (case guess_player)', clubIdMustTravel: ['guess_players', 'user_game_item_progress', 'score_events', 'arena_record_score(p_club_id)'] },
  { game: 'passport', content: 'passport_matches', chain: ['passport_attendances', 'passport_memorable_matches'], rpc: 'passport_save_attendances / passport_ranking / passport_my_rank', clubIdMustTravel: ['passport_matches(redesign §19)', 'passport_attendances(herda via match_id)', 'passport_memorable_matches(herda via match_id)', 'passport_ranking/my_rank(where club_id)'] },
  { game: 'crowd_lineup', content: null, chain: ['match_lineup_votes'], rpc: 'crowd_lineup(p_match_id) — agrega por match_id sem club', clubIdMustTravel: ['match_lineup_votes(unique (club_id, match_id, user_id))', 'crowd_lineup(p_club_id)'] },
];

// --- RLS matrix (item 24): usuário != tenant ---
const rlsMatrix = verified.map((t) => ({
  table: t.table,
  rlsEnabled: t.rls.enabled,
  model: t.rls.model,
  usesAuthUid: /OWNER|USER/.test(t.rls.model),
  publicRead: t.rls.model === 'PUBLIC_READ',
  serviceRoleOnly: t.rls.model === 'SERVICE_ROLE',
  usesClubId: false,
  tenantLeakPossibleForSameUser: t.rowScopeProblem,
  note: t.rls.model === 'PUBLIC_READ'
    ? 'leitura pública — RLS não separa clube nenhum; ROW_SCOPE tem de vir do filtro da query/app'
    : /OWNER|USER/.test(t.rls.model)
      ? 'auth.uid()=user_id protege usuário A de B, mas NÃO separa clubA de clubB PARA O MESMO usuário'
      : 'service_role — sem dimensão de usuário; tenancy é por club_id na coluna',
}));

// --- RLS vs APP_CLUB (item 3 do pedido de correção) — 3 conceitos SEPARADOS.
// APP_CLUB existe no Flutter/build; NÃO existe automaticamente numa policy RLS
// do Postgres. Nunca criar a falsa impressão de que a RLS "lê APP_CLUB". ---
const rlsTenantModel = {
  userSecurity: { rule: 'auth.uid() = user_id', enforcedBy: 'RLS', guarantees: 'usuário A não vê linha do usuário B' },
  applicationTenantFilter: { rule: ".eq('club_id', activeClubId)", enforcedBy: 'repository Flutter', guarantees: 'o app do clubA não PEDE linhas do clubB' },
  databaseEnforcedTenantIdentity: {
    rule: 'RLS/RPC que exige club_id a partir de uma FONTE CONFIÁVEL no servidor',
    enforcedBy: 'só possível com JWT claim de clube, contexto de RPC confiável, OU proibir acesso direto e passar tudo por RPC',
    status: 'NÃO existe hoje — não inventar agora; exige uma decisão adicional de auth/contexto',
  },
  consequence: 'Para dados do MESMO usuário em múltiplos clubes, auth.uid()=user_id NÃO impede o próprio usuário de ler seus registros do outro clube numa query manual sem filtro. Isso NÃO é vazamento ENTRE usuários — é isolamento de PRODUTO/tenant dentro da mesma identidade.',
  firstMandatoryGate: 'repositories SEMPRE filtram club_id + RPCs recebem p_club_id + constraints incluem club_id. Enforcement estrito no próprio RLS fica como decisão FUTURA de auth/contexto confiável, registrada, não implementada.',
};

// --- backfill (item 25): DESIGN, não executado (M2.1 não roda SQL) ---
const backfillPlan = {
  rule: 'Toda linha existente hoje é do Goiás (único clube em clubs). Backfill futuro: club_id = ' + GOIAS_CLUB_UUID + ' em 100% das linhas de cada tabela TENANT_*.',
  countsComputed: false,
  reason: 'M2.1 é design — NÃO roda db query. As contagens exatas por tabela ficam pra 1ª subetapa de M2.2 (npx supabase db query, read-only), antes de qualquer migration.',
  precondition: 'clubs contém exatamente 1 linha (Goiás). Confirmado pela fundação canônica.',
  postcondition: 'club_id not null em todas as linhas TENANT_*; nenhuma linha órfã (todo club_id referencia clubs(id)).',
};

// --- ROADMAP FASEADO (itens 4/5/6/7/26/27) — a ordem é o que importa.
// NUNCA trocar PK/assinatura de RPC antes do app publicado mandar club_id.
// Sequência: M2.2A (aditivo) → M3 (runtime tenant-aware) → M2.2B (enforcement)
// → M4 (flavors). O DB só passa a EXIGIR tenancy depois que o app novo estiver
// implantado/adotado — senão o app instalado perde progresso/ranking/
// membership/tickets/votos/pedidos.
const roadmap = {
  'M2.2A': {
    name: 'Additive Tenant Schema (DB primeiro, SÓ compatível)',
    does: [
      'add column club_id uuid NULLABLE default <goias> em todas as TENANT_*',
      'backfill club_id = <goias> (100% das linhas — 1 tenant hoje)',
      'FK club_id references clubs(id)',
      'indexes auxiliares por club_id',
    ],
    doesNot: ['NÃO remove PK/UNIQUE antiga que quebre o client atual', 'NÃO endurece assinatura de RPC de forma incompatível'],
    rpcRule: 'se uma RPC mudar aqui, tem de continuar aceitando o contrato ANTIGO (assume Goiás enquanto só há 1 tenant real).',
    goal: 'old app + new DB = funciona',
    compat: 'BACKWARD_COMPATIBLE',
  },
  'M3': {
    name: 'Tenant-Aware Runtime (Flutter passa a mandar club_id)',
    does: [
      'consumidores migram pra ClubConfig.identity.canonicalClubId',
      "repositories filtram .eq('club_id', activeClubId) em toda query",
      'RPCs novas recebem p_club_id explícito; writes gravam club_id',
      'colapsar os 3 isGoias duplicados → isOurClub(config); Team.goiasId → ClubConfig.integrations.oneFootballTeamId',
    ],
    doesNot: ['DB ainda mantém compatibilidade com a versão antiga (PK/UNIQUE ainda as antigas)'],
    goal: 'new app + transitional DB = funciona  E  old app + transitional DB = funciona',
    compat: 'REQUIRES_DUAL_READ_WRITE',
  },
  'M2.2B': {
    name: 'Tenant Enforcement (só depois do app novo implantado/adotado)',
    does: [
      'trocar PKs → compostas/surrogate (club_id na chave)',
      'trocar UNIQUEs (person_id → (club_id, person_id); match_lineup_votes/tickets etc.)',
      'NOT NULL definitivo onde faltou; endurecer assinaturas de RPC (p_club_id obrigatório)',
      'remover compatibilidade legacy; endurecer constraints/RLS',
    ],
    goal: 'DB agora PODE exigir tenancy explicitamente',
    compat: 'REQUIRES_APP_DEPLOY_FIRST (gate: app que manda club_id publicado e adotado)',
  },
  'M4': {
    name: 'Flavors / integrações externas',
    does: ['pipeline de flavor (Android/iOS/web)', 'Worker generalizado por club_id', 'avaliar onboarding de um 2º clube real (decisão de produto separada)'],
    goal: 'multi-club de verdade; release gate: todo pipeline passa APP_CLUB=<clube> explícito, nunca depende do default Goiás',
    compat: 'n/a',
  },
};

// --- contrato de compat de RPC na M2.2A (item 6) — documentar, não decidir
// implementação. Nenhuma dessas RPCs pode quebrar antes do app novo. ---
const rpcCompatibilityContract = {
  mustNotBreakInM2_2A: ['arena_record_score', 'arena_ranking', 'arena_my_rank', 'arena_user_detail', 'get_my_membership', 'crowd_lineup', 'passport_save_attendances', 'passport_ranking', 'passport_my_rank', 'create_store_order'],
  transitionalStrategy: 'RPC legacy assume Goiás ENQUANTO só existe 1 tenant real; RPC nova recebe p_club_id explícito (overload/versionamento OU um default que resolve pro único clube). Implementação decidida na M2.2A, não aqui.',
  hardRule: 'quando existir um 2º clube, NENHUMA chamada pode depender do default Goiás — o gate final de M2.2B/M4 remove o fallback.',
};

// --- passaporte: continua decisão de PRODUTO, alto impacto de compat ---
const passportDecision = {
  status: 'NEEDS_PRODUCT_DECISION',
  techRecommendation: 'B (simétrico home/away, alinhado à canônica matches) a longo prazo; A (renomear goias_* → club_*) como ponte mínima',
  blocking: true,
  note: 'Passaporte tem 1697+ registros reais (partidas 2000–2026) + 2 FKs dependentes — impacto grande de compatibilidade. NENHUMA migration de passport entra na M2.2A sem aprovação de PRODUTO separada. A recomendação técnica NÃO é a decisão.',
};

const stats = {
  totalTables: tables.length,
  verified: verified.length,
  stale: staleNotes.length,
  staleList: staleNotes,
  byGroup: verified.reduce((a, t) => { a[t.group] = (a[t.group] || 0) + 1; return a; }, {}),
  byTenantStrategy: verified.reduce((a, t) => { const k = t.tenantStrategy.split(' ')[0]; a[k] = (a[k] || 0) + 1; return a; }, {}),
  rowScopeProblemTables: verified.filter((t) => t.rowScopeProblem).map((t) => t.table),
  keyScopeProblemTables: verified.filter((t) => t.keyScopeProblem).map((t) => t.table),
  criticalTables: verified.filter((t) => t.critical).map((t) => t.table),
  needsProductDecisionTables: verified.filter((t) => t.tenantStrategy === 'NEEDS_PRODUCT_DECISION').map((t) => t.table),
  uniqueDecisions,
  uniqueByClass: uniqueDecisions.reduce((a, u) => { a[u.class] = (a[u.class] || 0) + 1; return a; }, {}),
  contentTables: verified.filter((t) => t.group === 'CONTENT').map((t) => t.table),
  personIdContentTables: verified.filter((t) => (t.uniques || []).some((u) => u.cols.length === 1 && u.cols[0] === 'person_id')).map((t) => t.table),
  clubIdType: { type: 'uuid', references: 'clubs(id)', neverUse: 'text references clubs(slug)' },
  rpcsNeedingClubId: [
    'arena_record_score (p_club_id + validação exists com club_id + upsert/insert com club_id)',
    'arena_ranking / arena_my_rank / arena_user_detail (where/group by club_id)',
    'get_my_membership (p_club_id, ou order by dentro do clube)',
    'crowd_lineup (p_club_id no filtro por match_id)',
    'passport_ranking / passport_my_rank / passport_save_attendances (club_id)',
  ],
  legacyIdPolicy: 'NUNCA renomear id existente, NUNCA namespacing "goias:tadeu". Só PK composta unique(club_id, id) OU surrogate row_id uuid + unique(club_id, id).',
  classificationSum: 0,
};
stats.classificationSum = Object.values(stats.byGroup).reduce((a, b) => a + b, 0);

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_tenant_constraints_audit.json'),
  JSON.stringify({ tables: verified, stale: staleNotes, uniqueDecisions, progressChains, rlsMatrix, rlsTenantModel, externalKeyProvenance, backfillPlan, roadmap, rpcCompatibilityContract, passportDecision }, null, 2) + '\n');
fs.writeFileSync(path.join(OUT_DIR, 'multiclub_tenant_constraints_stats.json'),
  JSON.stringify(stats, null, 2) + '\n');
console.log(JSON.stringify(stats, null, 2));
console.log('\nEscrito em:', OUT_DIR);

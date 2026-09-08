-- ============================================================================
-- CANONICAL BASELINE — Fan Hub multi-Supabase (clube novo)
--
-- Fontes (revisadas conscientemente, nunca concatenação cega de migrations
-- nem `migration squash`):
--   1. introspecção AO VIVO do schema `public` do Goiás (colunas, PK/FK/
--      UNIQUE/CHECK via pg_get_constraintdef, índices via pg_get_indexdef,
--      RLS via pg_policies, grants via information_schema, funções via
--      pg_get_functiondef, grants de função via has_function_privilege) —
--      `supabase db dump` não está disponível neste ambiente (exige Docker,
--      confirmado indisponível) — introspecção direta foi o caminho real.
--   2. auditoria das 60 migrations históricas (docs/multiclub/48) — usada
--      pra CLASSIFICAR o que é genérico vs Goiás-específico, nunca como
--      fonte de SQL (o SQL vem sempre do estado AO VIVO, item 1).
--   3. achados dos relatórios 48/49/50 (profiles/user_addresses/
--      handle_new_user nunca versionados; Storage buckets/policies nunca
--      versionados).
--
-- ZERO identidade de clube: nenhum literal 'goias'/'Goiás'/'bragantino'/
-- 'RB Bragantino', nenhum UUID de clube, nenhum DEFAULT de club_id, ZERO
-- identifier semanticamente ligado ao Goiás (rodada de correção — ver
-- "RENAMES" abaixo). `public.clubs` é criada VAZIA — confirmado que a live
-- schema já não tem nenhum DEFAULT de club_id (dropado pelas migrations
-- 20260903130000/170000) e este dump é schema-only (nunca inclui a linha
-- do Goiás).
--
-- SCHEMA CAPABILITY vs PRODUCT CAPABILITY (princípio adotado nesta rodada
-- de correção): o schema canônico fica ESTRUTURALMENTE capaz de suportar
-- Store/Membership pra qualquer clube — não escolhemos migrations
-- modulares, então "hasStore=false"/"hasMembership=false" é decisão de
-- PRODUTO/runtime (Flutter, `ClubCapabilities`), nunca motivo pra tirar
-- tabela/RPC genérica do baseline. O que sai do baseline é só CONTEÚDO
-- editorial (planos reais, prefixo de pedido hardcoded) — nunca a
-- capacidade estrutural de a feature existir.
--
-- ============================================================================
-- RENAMES (Goiás continua com os nomes ANTIGOS ao vivo — 0 DDL nele nesta
-- rodada — mapping abaixo é só documentação pro cutover futuro, Fase 2):
--   passport_matches.goias_is_home    -> club_is_home
--   passport_matches.goias_score      -> club_score
--   guess_players.goias_debut_year    -> club_debut_year
-- Motivo: nome de coluna que assume "o clube deste app é o Goiás" — mesmo
-- sem ser um dos 4 itens proibidos originais (UUID/nome/DEFAULT de
-- club_id), ainda é identidade de clube embutida no domínio. Isolamento
-- físico por projeto elimina o risco de VAZAMENTO cross-clube, mas não
-- resolve "coluna chamada club_score conteria... espera, chamada
-- goias_score conteria dado do Bragantino" — corrigido renomeando no
-- CANONICAL baseline, nunca no Goiás.
-- ============================================================================
--
-- STORE — redesenhado nesta rodada (schema capability preservada):
--   - `store_orders`/`store_order_items` MANTIDAS na estrutura.
--   - `generate_store_order_number()` deixou de ter prefixo `'GOI-'`
--     hardcoded — agora recebe `p_club_id` e lê `clubs.order_prefix`
--     (coluna NOVA, genérica, nullable — cai pra `upper(left(slug,3))` se
--     o clube não tiver configurado um prefixo próprio ainda). `GOI` em si
--     nunca aparece aqui — só seria escrito no bootstrap do Goiás (fora do
--     baseline, ver infra/supabase/clubs/goias/bootstrap.sql, nunca
--     aplicado contra o projeto real nesta rodada).
--   - `order_number` deixou de ter `DEFAULT` de coluna (função não-determi-
--     nística por clube não pode ser DEFAULT sem argumento) — agora é
--     calculado explicitamente dentro de `create_store_order_for_club`
--     antes do INSERT.
--   - `create_store_order_for_club` REINCLUÍDA (estava excluída na rodada
--     anterior só por depender da função antiga).
--   - ZERO produto/conteúdo de loja inserido.
--
-- MEMBERSHIP — redesenhado nesta rodada (schema capability preservada):
--   - Tabela NOVA `membership_plans` (club-scoped, vazia) — catálogo
--     data-driven, nunca mais hardcoded no corpo de função.
--   - `subscribe_to_plan_for_club` REESCRITA: mesma lógica operacional do
--     original (advisory lock, bloqueio de assinatura duplicada, insert em
--     `supporter_memberships`), mas o nome/duração do plano vêm de um
--     `SELECT` em `membership_plans` — zero 'nossa-gente'/'NOSSA GENTE'/
--     qualquer plano editorial no corpo.
--   - ZERO plano inserido pelo baseline — cadastro de plano é bootstrap/
--     conteúdo por clube, uma etapa própria.
--   - Código NOVO (não introspecção direta) — precisa de revisão extra
--     antes de qualquer aplicação real (nunca testado contra Postgres de
--     verdade nesta rodada, ambiente sem Docker/Postgres local).
--
-- EXCLUÍDO ainda (revisão manual, conteúdo Goiás-específico que introspecção
-- ingênua não capturaria):
--   - `subscribe_to_plan` (RPC legada, pre-`_for_club`): mesmo hardcode do
--     original, já sem EXECUTE grant ao vivo (M4.1c revogou) — vestigial.
--   - As 7 outras RPCs legadas (`arena_my_rank`, `arena_ranking`,
--     `arena_record_score`, `arena_user_detail`, `create_store_order`,
--     `crowd_lineup`, `get_my_membership`): idem, já sem EXECUTE grant ao
--     vivo, confirmado que um projeto novo nunca precisaria delas mesmo se
--     copiadas.
--
-- ACEITO, flagged, mantido como estava (fora do escopo desta correção):
--   - CHECK `difficulty in ('torcedor','esmeraldino','fanatico')`
--     (quiz_active_session/quiz_question_progress) — decisão já tomada
--     antes (docs/multiclub/10_club_config.md §4): enum interno, nunca
--     mostrado cru ao usuário, sempre via l10n.
--
-- Passaporte (12 RPCs `passport_*`) INCLUÍDO estruturalmente, mesmo não
-- sendo tenant-aware (PASSPORT_TENANCY_DEFERRED continua true) — no modelo
-- de 1-Supabase-por-clube, "não ter club_id" deixa de ser um risco de
-- vazamento cross-clube (cada projeto só tem o dado do seu próprio clube
-- fisicamente). `hasPassport=false` no Bragantino, feature não fica
-- alcançável no app de qualquer forma.
--
-- profiles/user_addresses: capturados pela introspecção normal (são schema
-- `public`, só nunca tinham migration — a introspecção ao vivo já resolve
-- isso, sem precisar de bloco especial).
-- ============================================================================

-- ---- auth.users trigger (fora de `public`, pg_get_functiondef/dump não
-- captura automaticamente objetos ligados a uma tabela de outro schema —
-- adicionado explícito, corpo confirmado ao vivo, 100% genérico) ----
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$function$;
revoke all on function public.handle_new_user() from public;
grant execute on function public.handle_new_user() to anon, authenticated, service_role;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---- Storage — buckets + policies (nunca versionado, nunca capturado por
-- db dump/migration nenhuma; DML explicitamente permitido aqui pelo pedido
-- — infraestrutura genérica, não dado editorial) ----
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('email-assets', 'email-assets', true)
on conflict (id) do nothing;

drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read" on storage.objects
  for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars_write_own" on storage.objects;
create policy "avatars_write_own" on storage.objects
  for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own" on storage.objects
  for update
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own" on storage.objects
  for delete
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (auth.uid())::text);

-- ============================================================================
-- TABLES (introspecção ao vivo, `public` schema)
-- ============================================================================

-- ---- TABLE: app_release_requirements ----
create table public.app_release_requirements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  club_id uuid NOT NULL,
  platform text NOT NULL,
  minimum_version text NOT NULL,
  minimum_build integer NOT NULL,
  latest_version text,
  latest_build integer,
  force_update boolean NOT NULL DEFAULT false,
  message text,
  store_url text,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.app_release_requirements add constraint app_release_requirements_platform_check CHECK ((platform = ANY (ARRAY['android'::text, 'ios'::text, 'web'::text])));
alter table public.app_release_requirements add constraint app_release_requirements_pkey PRIMARY KEY (id);
alter table public.app_release_requirements add constraint app_release_requirements_club_id_platform_key UNIQUE (club_id, platform);
alter table public.app_release_requirements enable row level security;
create policy "read app release requirements" on public.app_release_requirements for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.app_release_requirements to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.app_release_requirements to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.app_release_requirements to service_role;

-- ---- TABLE: arena_achievements ----
create table public.arena_achievements (
  user_id uuid NOT NULL,
  achievement_id text NOT NULL,
  unlocked_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.arena_achievements add constraint arena_achievements_pkey PRIMARY KEY (club_id, user_id, achievement_id);
CREATE INDEX arena_achievements_club_id_idx ON public.arena_achievements USING btree (club_id);
alter table public.arena_achievements enable row level security;
create policy "insert own achievements" on public.arena_achievements for INSERT to public with check ((auth.uid() = user_id));
create policy "read own achievements" on public.arena_achievements for SELECT to public using ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.arena_achievements to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.arena_achievements to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.arena_achievements to service_role;

-- ---- TABLE: arena_selected_content ----
create table public.arena_selected_content (
  user_id uuid NOT NULL,
  game_id text NOT NULL,
  selected_id text NOT NULL,
  club_id uuid NOT NULL
);
alter table public.arena_selected_content add constraint arena_selected_content_pkey PRIMARY KEY (club_id, user_id, game_id);
CREATE INDEX arena_selected_content_club_id_idx ON public.arena_selected_content USING btree (club_id);
alter table public.arena_selected_content enable row level security;
create policy "insert own selected content" on public.arena_selected_content for INSERT to public with check ((auth.uid() = user_id));
create policy "read own selected content" on public.arena_selected_content for SELECT to public using ((auth.uid() = user_id));
create policy "update own selected content" on public.arena_selected_content for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.arena_selected_content to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.arena_selected_content to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.arena_selected_content to service_role;

-- ---- TABLE: career_path_progress ----
create table public.career_path_progress (
  user_id uuid NOT NULL,
  player_id text NOT NULL,
  round_state jsonb NOT NULL,
  status text NOT NULL DEFAULT 'in_progress'::text,
  completed_at timestamp with time zone,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.career_path_progress add constraint career_path_progress_pkey PRIMARY KEY (club_id, user_id, player_id);
CREATE INDEX career_path_progress_club_id_idx ON public.career_path_progress USING btree (club_id);
CREATE INDEX career_path_progress_user_status_idx ON public.career_path_progress USING btree (user_id, status);
alter table public.career_path_progress enable row level security;
create policy "insert own career progress" on public.career_path_progress for INSERT to public with check ((auth.uid() = user_id));
create policy "read own career progress" on public.career_path_progress for SELECT to public using ((auth.uid() = user_id));
create policy "update own career progress" on public.career_path_progress for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.career_path_progress to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.career_path_progress to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.career_path_progress to service_role;

-- ---- TABLE: career_players ----
create table public.career_players (
  id text NOT NULL,
  answer text NOT NULL,
  accepted_answers jsonb NOT NULL DEFAULT '[]'::jsonb,
  position text,
  club_career jsonb NOT NULL,
  national_teams jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  aggregate_stats jsonb NOT NULL DEFAULT '[]'::jsonb,
  person_id uuid,
  club_id uuid NOT NULL
);
alter table public.career_players add constraint career_players_pkey PRIMARY KEY (id);
CREATE INDEX career_players_club_id_idx ON public.career_players USING btree (club_id);
CREATE UNIQUE INDEX career_players_club_person_uidx ON public.career_players USING btree (club_id, person_id);
alter table public.career_players enable row level security;
create policy "read career players" on public.career_players for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.career_players to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.career_players to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.career_players to service_role;

-- ---- TABLE: club_board_members ----
create table public.club_board_members (
  id text NOT NULL,
  section_id text NOT NULL,
  name text NOT NULL,
  role text NOT NULL,
  photo_url text,
  sort_order integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.club_board_members add constraint club_board_members_pkey PRIMARY KEY (id);
alter table public.club_board_members enable row level security;
create policy "club_board_members_read_all" on public.club_board_members for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_board_members to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_board_members to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_board_members to service_role;

-- ---- TABLE: club_board_sections ----
create table public.club_board_sections (
  id text NOT NULL,
  title text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.club_board_sections add constraint club_board_sections_pkey PRIMARY KEY (id);
alter table public.club_board_sections enable row level security;
create policy "club_board_sections_read_all" on public.club_board_sections for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_board_sections to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_board_sections to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_board_sections to service_role;

-- ---- TABLE: club_transparency_documents ----
create table public.club_transparency_documents (
  id text NOT NULL,
  topic_id text NOT NULL,
  title text NOT NULL,
  document_date date NOT NULL,
  pdf_url text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.club_transparency_documents add constraint club_transparency_documents_pkey PRIMARY KEY (id);
alter table public.club_transparency_documents enable row level security;
create policy "club_transparency_documents_read_all" on public.club_transparency_documents for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_transparency_documents to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_transparency_documents to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_transparency_documents to service_role;

-- ---- TABLE: club_transparency_topics ----
create table public.club_transparency_topics (
  id text NOT NULL,
  title text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.club_transparency_topics add constraint club_transparency_topics_pkey PRIMARY KEY (id);
alter table public.club_transparency_topics enable row level security;
create policy "club_transparency_topics_read_all" on public.club_transparency_topics for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_transparency_topics to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_transparency_topics to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.club_transparency_topics to service_role;

-- ---- TABLE: clubs ----
-- `order_prefix` é NOVO nesta rodada de correção (SCHEMA CAPABILITY pra
-- Store, ver cabeçalho) -- config genérica por clube, nunca um valor
-- hardcoded aqui. Goiás ao vivo NÃO tem esta coluna (0 DDL nele nesta
-- rodada) -- só existiria se/quando o cutover da Fase 2 acontecer.
create table public.clubs (
  id uuid NOT NULL,
  slug text NOT NULL,
  name text NOT NULL,
  short_name text NOT NULL,
  order_prefix text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.clubs add constraint clubs_pkey PRIMARY KEY (id);
alter table public.clubs add constraint clubs_slug_key UNIQUE (slug);
alter table public.clubs enable row level security;
create policy "read clubs" on public.clubs for SELECT to public using (true);
grant SELECT on public.clubs to anon;
grant SELECT on public.clubs to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.clubs to service_role;

-- ---- TABLE: delivery_addresses ----
create table public.delivery_addresses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  label text,
  zip_code text NOT NULL,
  street text NOT NULL,
  number text NOT NULL,
  complement text,
  neighborhood text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.delivery_addresses add constraint delivery_addresses_pkey PRIMARY KEY (id);
CREATE INDEX delivery_addresses_user_id_idx ON public.delivery_addresses USING btree (user_id, created_at);
alter table public.delivery_addresses enable row level security;
create policy "delete own delivery addresses" on public.delivery_addresses for DELETE to public using ((auth.uid() = user_id));
create policy "insert own delivery addresses" on public.delivery_addresses for INSERT to public with check ((auth.uid() = user_id));
create policy "select own delivery addresses" on public.delivery_addresses for SELECT to public using ((auth.uid() = user_id));
create policy "update own delivery addresses" on public.delivery_addresses for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.delivery_addresses to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.delivery_addresses to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.delivery_addresses to service_role;

-- ---- TABLE: guess_players ----
create table public.guess_players (
  id text NOT NULL,
  name text NOT NULL,
  display_name text NOT NULL,
  aliases jsonb NOT NULL DEFAULT '[]'::jsonb,
  position text,
  shirt_number integer,
  academy_club text,
  nationality_code text,
  nationality_name text,
  club_debut_year integer,
  photo_key text,
  data_status text NOT NULL DEFAULT 'incomplete'::text,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  person_id uuid,
  club_id uuid NOT NULL
);
alter table public.guess_players add constraint guess_players_data_status_check CHECK ((data_status = ANY (ARRAY['verified'::text, 'review'::text, 'incomplete'::text])));
alter table public.guess_players add constraint guess_players_pkey PRIMARY KEY (id);
CREATE INDEX guess_players_club_id_idx ON public.guess_players USING btree (club_id);
CREATE UNIQUE INDEX guess_players_club_person_uidx ON public.guess_players USING btree (club_id, person_id);
alter table public.guess_players enable row level security;
create policy "read guess players" on public.guess_players for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.guess_players to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.guess_players to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.guess_players to service_role;

-- ---- TABLE: lineup_match_progress ----
create table public.lineup_match_progress (
  user_id uuid NOT NULL,
  match_id text NOT NULL,
  game_state jsonb NOT NULL,
  status text NOT NULL DEFAULT 'in_progress'::text,
  completed_at timestamp with time zone,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.lineup_match_progress add constraint lineup_match_progress_pkey PRIMARY KEY (club_id, user_id, match_id);
CREATE INDEX lineup_match_progress_club_id_idx ON public.lineup_match_progress USING btree (club_id);
CREATE INDEX lineup_match_progress_user_status_idx ON public.lineup_match_progress USING btree (user_id, status);
alter table public.lineup_match_progress enable row level security;
create policy "insert own lineup progress" on public.lineup_match_progress for INSERT to public with check ((auth.uid() = user_id));
create policy "read own lineup progress" on public.lineup_match_progress for SELECT to public using ((auth.uid() = user_id));
create policy "update own lineup progress" on public.lineup_match_progress for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.lineup_match_progress to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.lineup_match_progress to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.lineup_match_progress to service_role;

-- ---- TABLE: lineup_matches ----
create table public.lineup_matches (
  id text NOT NULL,
  competition text NOT NULL,
  season text NOT NULL,
  phase text NOT NULL,
  match_date date NOT NULL,
  venue text,
  home_team text NOT NULL,
  away_team text NOT NULL,
  home_score integer NOT NULL,
  away_score integer NOT NULL,
  formation text NOT NULL,
  formation_confidence text NOT NULL,
  lineup jsonb NOT NULL,
  display_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.lineup_matches add constraint lineup_matches_formation_confidence_check CHECK ((formation_confidence = ANY (ARRAY['confirmed'::text, 'probable'::text, 'estimated'::text])));
alter table public.lineup_matches add constraint lineup_matches_pkey PRIMARY KEY (id);
CREATE INDEX lineup_matches_club_id_idx ON public.lineup_matches USING btree (club_id);
alter table public.lineup_matches enable row level security;
create policy "read lineup matches" on public.lineup_matches for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.lineup_matches to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.lineup_matches to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.lineup_matches to service_role;

-- ---- TABLE: match_lineup_votes ----
create table public.match_lineup_votes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  match_id text NOT NULL,
  user_id uuid NOT NULL,
  formation text NOT NULL,
  slots jsonb NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.match_lineup_votes add constraint match_lineup_votes_pkey PRIMARY KEY (id);
CREATE INDEX match_lineup_votes_club_id_idx ON public.match_lineup_votes USING btree (club_id);
CREATE INDEX match_lineup_votes_match_idx ON public.match_lineup_votes USING btree (match_id);
CREATE UNIQUE INDEX mlv_club_match_user_uidx ON public.match_lineup_votes USING btree (club_id, match_id, user_id);
alter table public.match_lineup_votes enable row level security;
create policy "insert own vote" on public.match_lineup_votes for INSERT to public with check ((auth.uid() = user_id));
create policy "read own vote" on public.match_lineup_votes for SELECT to public using ((auth.uid() = user_id));
create policy "update own vote" on public.match_lineup_votes for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.match_lineup_votes to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.match_lineup_votes to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.match_lineup_votes to service_role;

-- ---- TABLE: match_monitor_sessions ----
create table public.match_monitor_sessions (
  match_id text NOT NULL,
  kickoff timestamp with time zone NOT NULL,
  home_team_name text NOT NULL,
  away_team_name text NOT NULL,
  status text NOT NULL DEFAULT 'scheduled'::text,
  last_known_score jsonb,
  started_at timestamp with time zone,
  last_polled_at timestamp with time zone,
  ends_at timestamp with time zone NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.match_monitor_sessions add constraint match_monitor_sessions_status_check CHECK ((status = ANY (ARRAY['scheduled'::text, 'active'::text, 'finished'::text, 'timed_out'::text])));
alter table public.match_monitor_sessions add constraint match_monitor_sessions_pkey PRIMARY KEY (club_id, match_id);
CREATE INDEX match_monitor_sessions_club_id_idx ON public.match_monitor_sessions USING btree (club_id);
alter table public.match_monitor_sessions enable row level security;
create policy "service role only" on public.match_monitor_sessions for ALL to public using (false) with check (false);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.match_monitor_sessions to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.match_monitor_sessions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.match_monitor_sessions to service_role;

-- ---- TABLE: match_source_refs ----
create table public.match_source_refs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL,
  source_type text NOT NULL,
  source_namespace text NOT NULL,
  source_ref text NOT NULL,
  source_club_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.match_source_refs add constraint match_source_refs_source_type_check CHECK ((source_type = ANY (ARRAY['LINEUP_MATCH'::text, 'PASSPORT_MATCH'::text, 'PROVIDER_FIXTURE'::text])));
alter table public.match_source_refs add constraint match_source_refs_pkey PRIMARY KEY (id);
alter table public.match_source_refs add constraint match_source_refs_source_namespace_source_ref_key UNIQUE (source_namespace, source_ref);
CREATE INDEX match_source_refs_match_id_idx ON public.match_source_refs USING btree (match_id);
alter table public.match_source_refs enable row level security;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.match_source_refs to service_role;

-- ---- TABLE: matches ----
create table public.matches (
  id uuid NOT NULL,
  home_club_id uuid,
  away_club_id uuid,
  home_team_name text NOT NULL,
  away_team_name text NOT NULL,
  kickoff_year integer NOT NULL,
  kickoff_month integer,
  kickoff_date date,
  kickoff_at timestamp with time zone,
  kickoff_precision text NOT NULL,
  competition text,
  season text,
  home_score integer,
  away_score integer,
  verification_status text NOT NULL,
  data_notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.matches add constraint matches_check CHECK (((home_club_id IS NOT NULL) OR (away_club_id IS NOT NULL)));
alter table public.matches add constraint matches_check4 CHECK (((kickoff_precision = 'YEAR'::text) = (kickoff_month IS NULL)));
alter table public.matches add constraint matches_check6 CHECK (((kickoff_date IS NULL) OR (kickoff_month IS NULL) OR ((EXTRACT(month FROM kickoff_date))::integer = kickoff_month)));
alter table public.matches add constraint matches_check5 CHECK (((kickoff_date IS NULL) OR ((EXTRACT(year FROM kickoff_date))::integer = kickoff_year)));
alter table public.matches add constraint matches_kickoff_precision_check CHECK ((kickoff_precision = ANY (ARRAY['YEAR'::text, 'MONTH'::text, 'DATE'::text, 'DATETIME'::text])));
alter table public.matches add constraint matches_verification_status_check CHECK ((verification_status = ANY (ARRAY['VERIFIED'::text, 'PARTIAL'::text])));
alter table public.matches add constraint matches_check3 CHECK (((kickoff_precision = ANY (ARRAY['DATE'::text, 'DATETIME'::text])) = (kickoff_date IS NOT NULL)));
alter table public.matches add constraint matches_check2 CHECK (((kickoff_precision = 'DATETIME'::text) = (kickoff_at IS NOT NULL)));
alter table public.matches add constraint matches_check1 CHECK (((home_club_id IS NULL) OR (away_club_id IS NULL) OR (home_club_id <> away_club_id)));
alter table public.matches add constraint matches_pkey PRIMARY KEY (id);
CREATE INDEX matches_away_club_id_idx ON public.matches USING btree (away_club_id);
CREATE INDEX matches_home_club_id_idx ON public.matches USING btree (home_club_id);
CREATE INDEX matches_kickoff_date_idx ON public.matches USING btree (kickoff_date);
CREATE INDEX matches_kickoff_year_month_idx ON public.matches USING btree (kickoff_year, kickoff_month);
alter table public.matches enable row level security;
create policy "read matches" on public.matches for SELECT to public using (true);
grant SELECT on public.matches to anon;
grant SELECT on public.matches to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.matches to service_role;

-- ---- TABLE: membership_faq_categories ----
create table public.membership_faq_categories (
  id text NOT NULL,
  title text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.membership_faq_categories add constraint membership_faq_categories_pkey PRIMARY KEY (id);
alter table public.membership_faq_categories enable row level security;
create policy "read faq categories" on public.membership_faq_categories for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_faq_categories to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_faq_categories to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_faq_categories to service_role;

-- ---- TABLE: membership_faq_items ----
create table public.membership_faq_items (
  id text NOT NULL,
  category_id text NOT NULL,
  question text NOT NULL,
  answer jsonb NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.membership_faq_items add constraint membership_faq_items_pkey PRIMARY KEY (id);
alter table public.membership_faq_items enable row level security;
create policy "read faq items" on public.membership_faq_items for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_faq_items to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_faq_items to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_faq_items to service_role;

-- ---- TABLE: membership_regulation_versions ----
create table public.membership_regulation_versions (
  id text NOT NULL,
  version text NOT NULL,
  effective_at date NOT NULL,
  content_markdown text NOT NULL,
  is_current boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.membership_regulation_versions add constraint membership_regulation_versions_pkey PRIMARY KEY (id);
alter table public.membership_regulation_versions enable row level security;
create policy "read regulation versions" on public.membership_regulation_versions for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_regulation_versions to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_regulation_versions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_regulation_versions to service_role;

-- ---- TABLE: notification_deliveries ----
create table public.notification_deliveries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  token_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text,
  fcm_message_id text,
  error text,
  attempted_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.notification_deliveries add constraint notification_deliveries_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text, 'invalid_token'::text])));
alter table public.notification_deliveries add constraint notification_deliveries_pkey PRIMARY KEY (id);
alter table public.notification_deliveries add constraint notification_deliveries_event_id_token_id_key UNIQUE (event_id, token_id);
CREATE INDEX notification_deliveries_pending_idx ON public.notification_deliveries USING btree (event_id) WHERE (status = 'pending'::text);
alter table public.notification_deliveries enable row level security;
create policy "service role only" on public.notification_deliveries for ALL to public using (false) with check (false);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notification_deliveries to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notification_deliveries to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notification_deliveries to service_role;

-- ---- TABLE: notification_events ----
create table public.notification_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  match_id text NOT NULL,
  event_type text NOT NULL,
  dedupe_key text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending'::text,
  detected_at timestamp with time zone NOT NULL DEFAULT now(),
  completed_at timestamp with time zone,
  club_id uuid NOT NULL
);
alter table public.notification_events add constraint notification_events_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'processing'::text, 'completed'::text, 'failed'::text])));
alter table public.notification_events add constraint notification_events_event_type_check CHECK ((event_type = ANY (ARRAY['match_access_open'::text, 'goal'::text, 'full_time'::text])));
alter table public.notification_events add constraint notification_events_pkey PRIMARY KEY (id);
CREATE UNIQUE INDEX ne_club_event_dedupe_uidx ON public.notification_events USING btree (club_id, event_type, dedupe_key);
CREATE INDEX notification_events_club_id_idx ON public.notification_events USING btree (club_id);
CREATE INDEX notification_events_status_idx ON public.notification_events USING btree (status);
alter table public.notification_events enable row level security;
create policy "service role only" on public.notification_events for ALL to public using (false) with check (false);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notification_events to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notification_events to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notification_events to service_role;

-- ---- TABLE: passport_attendances ----
create table public.passport_attendances (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  match_id text NOT NULL,
  attended boolean NOT NULL DEFAULT true,
  marked_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  source text NOT NULL DEFAULT 'self_declared'::text
);
alter table public.passport_attendances add constraint passport_attendances_pkey PRIMARY KEY (id);
alter table public.passport_attendances add constraint passport_attendances_user_id_match_id_key UNIQUE (user_id, match_id);
CREATE INDEX passport_attendances_match_idx ON public.passport_attendances USING btree (match_id);
CREATE INDEX passport_attendances_user_attended_idx ON public.passport_attendances USING btree (user_id) WHERE (attended = true);
alter table public.passport_attendances enable row level security;
create policy "passport_attendances_read_own" on public.passport_attendances for SELECT to public using ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_attendances to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_attendances to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_attendances to service_role;

-- ---- TABLE: passport_matches ----
create table public.passport_matches (
  id text NOT NULL,
  season integer NOT NULL,
  match_date date NOT NULL,
  match_time time without time zone,
  kickoff_at timestamp with time zone,
  display_timezone text,
  date_precision text NOT NULL,
  status text NOT NULL,
  competition text NOT NULL,
  competition_code text NOT NULL,
  competition_source_name text,
  round text,
  opponent text NOT NULL,
  club_is_home boolean,
  neutral_site boolean,
  home_team text,
  away_team text,
  home_score integer,
  away_score integer,
  club_score integer,
  opponent_score integer,
  score_display text,
  outcome text,
  venue_id text,
  source_provider text NOT NULL,
  source_match_id text,
  source_url text,
  source_confidence text,
  data_notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  venue_confidence text,
  venue_audit_status text
);
alter table public.passport_matches add constraint passport_matches_outcome_check CHECK ((outcome = ANY (ARRAY['WIN'::text, 'DRAW'::text, 'LOSS'::text])));
alter table public.passport_matches add constraint passport_matches_date_precision_check CHECK ((date_precision = ANY (ARRAY['date_only'::text, 'datetime'::text])));
alter table public.passport_matches add constraint passport_matches_status_check CHECK ((status = ANY (ARRAY['FINISHED'::text, 'SCHEDULED'::text, 'POSTPONED'::text, 'CANCELLED'::text])));
alter table public.passport_matches add constraint passport_matches_pkey PRIMARY KEY (id);
CREATE INDEX passport_matches_competition_idx ON public.passport_matches USING btree (competition_code);
CREATE INDEX passport_matches_finished_by_season_idx ON public.passport_matches USING btree (season, match_date) WHERE (status = 'FINISHED'::text);
CREATE INDEX passport_matches_season_date_idx ON public.passport_matches USING btree (season, match_date);
CREATE INDEX passport_matches_source_idx ON public.passport_matches USING btree (source_provider, source_match_id);
CREATE INDEX passport_matches_status_idx ON public.passport_matches USING btree (status);
CREATE INDEX passport_matches_venue_idx ON public.passport_matches USING btree (venue_id);
alter table public.passport_matches enable row level security;
create policy "passport_matches_read_all" on public.passport_matches for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_matches to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_matches to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_matches to service_role;

-- ---- TABLE: passport_memorable_matches ----
create table public.passport_memorable_matches (
  user_id uuid NOT NULL,
  match_id text NOT NULL,
  selected_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.passport_memorable_matches add constraint passport_memorable_matches_pkey PRIMARY KEY (user_id);
alter table public.passport_memorable_matches enable row level security;
create policy "passport_memorable_matches_read_own" on public.passport_memorable_matches for SELECT to public using ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_memorable_matches to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_memorable_matches to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_memorable_matches to service_role;

-- ---- TABLE: passport_sync_runs ----
create table public.passport_sync_runs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  provider text NOT NULL,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  finished_at timestamp with time zone,
  status text NOT NULL DEFAULT 'running'::text,
  inserted_count integer NOT NULL DEFAULT 0,
  updated_count integer NOT NULL DEFAULT 0,
  unchanged_count integer NOT NULL DEFAULT 0,
  failed_count integer NOT NULL DEFAULT 0,
  error_summary text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);
alter table public.passport_sync_runs add constraint passport_sync_runs_status_check CHECK ((status = ANY (ARRAY['running'::text, 'success'::text, 'partial'::text, 'failed'::text])));
alter table public.passport_sync_runs add constraint passport_sync_runs_pkey PRIMARY KEY (id);
alter table public.passport_sync_runs enable row level security;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_sync_runs to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_sync_runs to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.passport_sync_runs to service_role;

-- ---- TABLE: people ----
create table public.people (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  canonical_name text NOT NULL,
  display_name text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.people add constraint people_pkey PRIMARY KEY (id);
alter table public.people enable row level security;
create policy "read people" on public.people for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.people to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.people to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.people to service_role;

-- ---- TABLE: person_alias_sources ----
create table public.person_alias_sources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_alias_id uuid NOT NULL,
  source text NOT NULL,
  source_record_key text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.person_alias_sources add constraint person_alias_sources_pkey PRIMARY KEY (id);
alter table public.person_alias_sources add constraint person_alias_sources_person_alias_id_source_source_record_k_key UNIQUE (person_alias_id, source, source_record_key);
alter table public.person_alias_sources enable row level security;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.person_alias_sources to service_role;

-- ---- TABLE: person_aliases ----
create table public.person_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  alias text NOT NULL,
  normalized_alias text NOT NULL,
  alias_type text NOT NULL,
  is_preferred boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.person_aliases add constraint person_aliases_alias_type_check CHECK ((alias_type = ANY (ARRAY['LEGAL_NAME'::text, 'FULL_NAME'::text, 'DISPLAY_NAME'::text, 'NICKNAME'::text, 'SHORT_NAME'::text, 'SOURCE_VARIANT'::text, 'MISSPELLING'::text])));
alter table public.person_aliases add constraint person_aliases_pkey PRIMARY KEY (id);
alter table public.person_aliases add constraint person_aliases_person_id_normalized_alias_key UNIQUE (person_id, normalized_alias);
CREATE INDEX person_aliases_normalized_alias_idx ON public.person_aliases USING btree (normalized_alias);
CREATE UNIQUE INDEX person_aliases_one_preferred_per_person ON public.person_aliases USING btree (person_id) WHERE is_preferred;
alter table public.person_aliases enable row level security;
create policy "read person aliases" on public.person_aliases for SELECT to public using (true);
grant SELECT on public.person_aliases to anon;
grant SELECT on public.person_aliases to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.person_aliases to service_role;

-- ---- TABLE: player_club_spell_sources ----
create table public.player_club_spell_sources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  spell_id uuid NOT NULL,
  source text NOT NULL,
  source_record_key text NOT NULL,
  evidence_type text NOT NULL,
  relationship_type text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_club_spell_sources add constraint player_club_spell_sources_evidence_type_check CHECK ((evidence_type = ANY (ARRAY['PRIMARY'::text, 'CORROBORATING'::text])));
alter table public.player_club_spell_sources add constraint player_club_spell_sources_relationship_type_check CHECK ((relationship_type = ANY (ARRAY['PERMANENT'::text, 'LOAN'::text, 'UNKNOWN'::text])));
alter table public.player_club_spell_sources add constraint player_club_spell_sources_pkey PRIMARY KEY (id);
alter table public.player_club_spell_sources add constraint player_club_spell_sources_spell_id_source_source_record_key_key UNIQUE (spell_id, source, source_record_key);
alter table public.player_club_spell_sources enable row level security;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_club_spell_sources to service_role;

-- ---- TABLE: player_club_spells ----
create table public.player_club_spells (
  id uuid NOT NULL,
  person_id uuid NOT NULL,
  club_id uuid NOT NULL,
  start_year integer NOT NULL,
  start_month integer,
  start_date date,
  start_precision text NOT NULL,
  is_ongoing boolean NOT NULL DEFAULT false,
  end_year integer,
  end_month integer,
  end_date date,
  end_precision text,
  spell_order integer NOT NULL,
  verification_status text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_club_spells add constraint player_club_spells_check7 CHECK (((end_precision <> 'MONTH'::text) OR ((end_date IS NULL) AND (end_month IS NOT NULL) AND (end_year IS NOT NULL))));
alter table public.player_club_spells add constraint player_club_spells_start_precision_check CHECK ((start_precision = ANY (ARRAY['YEAR'::text, 'MONTH'::text, 'DATE'::text, 'UNKNOWN'::text])));
alter table public.player_club_spells add constraint player_club_spells_end_precision_check CHECK ((end_precision = ANY (ARRAY['YEAR'::text, 'MONTH'::text, 'DATE'::text, 'UNKNOWN'::text])));
alter table public.player_club_spells add constraint player_club_spells_verification_status_check CHECK ((verification_status = ANY (ARRAY['VERIFIED'::text, 'PARTIAL'::text])));
alter table public.player_club_spells add constraint player_club_spells_start_month_check CHECK (((start_month IS NULL) OR ((start_month >= 1) AND (start_month <= 12))));
alter table public.player_club_spells add constraint player_club_spells_end_month_check CHECK (((end_month IS NULL) OR ((end_month >= 1) AND (end_month <= 12))));
alter table public.player_club_spells add constraint player_club_spells_check CHECK (((NOT is_ongoing) OR ((end_year IS NULL) AND (end_month IS NULL) AND (end_date IS NULL) AND (end_precision IS NULL))));
alter table public.player_club_spells add constraint player_club_spells_check1 CHECK ((is_ongoing OR (end_precision IS NOT NULL)));
alter table public.player_club_spells add constraint player_club_spells_check2 CHECK (((start_precision <> 'YEAR'::text) OR ((start_month IS NULL) AND (start_date IS NULL) AND (start_year IS NOT NULL))));
alter table public.player_club_spells add constraint player_club_spells_check3 CHECK (((start_precision <> 'MONTH'::text) OR ((start_date IS NULL) AND (start_month IS NOT NULL) AND (start_year IS NOT NULL))));
alter table public.player_club_spells add constraint player_club_spells_check4 CHECK (((start_precision <> 'DATE'::text) OR (start_date IS NOT NULL)));
alter table public.player_club_spells add constraint player_club_spells_check5 CHECK (((start_precision <> 'UNKNOWN'::text) OR ((start_year IS NULL) AND (start_month IS NULL) AND (start_date IS NULL))));
alter table public.player_club_spells add constraint player_club_spells_check6 CHECK (((end_precision <> 'YEAR'::text) OR ((end_month IS NULL) AND (end_date IS NULL) AND (end_year IS NOT NULL))));
alter table public.player_club_spells add constraint player_club_spells_check8 CHECK (((end_precision <> 'DATE'::text) OR (end_date IS NOT NULL)));
alter table public.player_club_spells add constraint player_club_spells_check9 CHECK (((end_precision <> 'UNKNOWN'::text) OR ((end_year IS NULL) AND (end_month IS NULL) AND (end_date IS NULL))));
alter table public.player_club_spells add constraint player_club_spells_pkey PRIMARY KEY (id);
alter table public.player_club_spells add constraint player_club_spells_id_person_club_key UNIQUE (id, person_id, club_id);
alter table public.player_club_spells add constraint player_club_spells_person_id_club_id_spell_order_key UNIQUE (person_id, club_id, spell_order);
CREATE INDEX player_club_spells_club_id_idx ON public.player_club_spells USING btree (club_id);
CREATE INDEX player_club_spells_person_id_idx ON public.player_club_spells USING btree (person_id);
alter table public.player_club_spells enable row level security;
create policy "read player club spells" on public.player_club_spells for SELECT to public using (true);
grant SELECT on public.player_club_spells to anon;
grant SELECT on public.player_club_spells to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_club_spells to service_role;

-- ---- TABLE: player_club_stat_sources ----
create table public.player_club_stat_sources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  player_club_stat_id uuid NOT NULL,
  source_type text NOT NULL,
  source_ref text NOT NULL,
  raw_value jsonb NOT NULL,
  source_role text NOT NULL,
  as_of_date date,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_club_stat_sources add constraint player_club_stat_sources_source_role_check CHECK ((source_role = ANY (ARRAY['PRIMARY'::text, 'CORROBORATING'::text, 'DERIVED_COMPONENT'::text, 'BASELINE'::text])));
alter table public.player_club_stat_sources add constraint player_club_stat_sources_pkey PRIMARY KEY (id);
alter table public.player_club_stat_sources add constraint player_club_stat_sources_player_club_stat_id_source_type_so_key UNIQUE (player_club_stat_id, source_type, source_ref);
alter table public.player_club_stat_sources enable row level security;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_club_stat_sources to service_role;

-- ---- TABLE: player_club_stats ----
create table public.player_club_stats (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  club_id uuid NOT NULL,
  spell_id uuid,
  stats_scope text NOT NULL,
  appearances integer,
  goals integer,
  verification_status text NOT NULL,
  data_mode text NOT NULL DEFAULT 'SNAPSHOT'::text,
  as_of_date date,
  as_of_match_id text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_club_stats add constraint player_club_stats_data_mode_check CHECK ((data_mode = ANY (ARRAY['SNAPSHOT'::text, 'LIVE'::text])));
alter table public.player_club_stats add constraint player_club_stats_goals_check CHECK ((goals >= 0));
alter table public.player_club_stats add constraint player_club_stats_appearances_check CHECK ((appearances >= 0));
alter table public.player_club_stats add constraint player_club_stats_stats_scope_check CHECK ((stats_scope = ANY (ARRAY['CLUB_TOTAL'::text, 'SPELL'::text])));
alter table public.player_club_stats add constraint player_club_stats_check2 CHECK (((appearances IS NOT NULL) OR (goals IS NOT NULL)));
alter table public.player_club_stats add constraint player_club_stats_check1 CHECK (((stats_scope <> 'SPELL'::text) OR (spell_id IS NOT NULL)));
alter table public.player_club_stats add constraint player_club_stats_check CHECK (((stats_scope <> 'CLUB_TOTAL'::text) OR (spell_id IS NULL)));
alter table public.player_club_stats add constraint player_club_stats_verification_status_check CHECK ((verification_status = ANY (ARRAY['VERIFIED'::text, 'PARTIAL'::text])));
alter table public.player_club_stats add constraint player_club_stats_pkey PRIMARY KEY (id);
CREATE INDEX player_club_stats_club_id_idx ON public.player_club_stats USING btree (club_id);
CREATE UNIQUE INDEX player_club_stats_club_total_idx ON public.player_club_stats USING btree (person_id, club_id) WHERE (stats_scope = 'CLUB_TOTAL'::text);
CREATE INDEX player_club_stats_person_id_idx ON public.player_club_stats USING btree (person_id);
CREATE UNIQUE INDEX player_club_stats_spell_idx ON public.player_club_stats USING btree (spell_id) WHERE (stats_scope = 'SPELL'::text);
alter table public.player_club_stats enable row level security;
create policy "read player club stats" on public.player_club_stats for SELECT to public using (true);
grant SELECT on public.player_club_stats to anon;
grant SELECT on public.player_club_stats to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_club_stats to service_role;

-- ---- TABLE: player_identity_results ----
create table public.player_identity_results (
  user_id uuid NOT NULL,
  test_type text NOT NULL DEFAULT 'player_identity'::text,
  archetype text NOT NULL,
  creativity smallint NOT NULL,
  definition smallint NOT NULL,
  leadership smallint NOT NULL,
  intensity smallint NOT NULL,
  technique smallint NOT NULL,
  tactics smallint NOT NULL,
  closest_player_id text,
  answers jsonb NOT NULL,
  completed_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.player_identity_results add constraint player_identity_results_pkey PRIMARY KEY (user_id, club_id);
CREATE INDEX player_identity_results_club_id_idx ON public.player_identity_results USING btree (club_id);
alter table public.player_identity_results enable row level security;
create policy "insert own player identity result" on public.player_identity_results for INSERT to public with check ((auth.uid() = user_id));
create policy "read own player identity result" on public.player_identity_results for SELECT to public using ((auth.uid() = user_id));
create policy "update own player identity result" on public.player_identity_results for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_identity_results to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_identity_results to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_identity_results to service_role;

-- ---- TABLE: player_match_appearance_sources ----
create table public.player_match_appearance_sources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  player_match_appearance_id uuid NOT NULL,
  source_type text NOT NULL,
  source_ref text NOT NULL,
  raw_value jsonb NOT NULL,
  source_role text NOT NULL,
  observed_at date,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_match_appearance_sources add constraint player_match_appearance_sources_source_role_check CHECK ((source_role = ANY (ARRAY['PRIMARY'::text, 'CORROBORATING'::text, 'CORRECTION'::text])));
alter table public.player_match_appearance_sources add constraint player_match_appearance_sources_pkey PRIMARY KEY (id);
alter table public.player_match_appearance_sources add constraint player_match_appearance_sourc_player_match_appearance_id_so_key UNIQUE (player_match_appearance_id, source_type, source_ref);
alter table public.player_match_appearance_sources enable row level security;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_match_appearance_sources to service_role;

-- ---- TABLE: player_match_appearances ----
create table public.player_match_appearances (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  club_id uuid NOT NULL,
  canonical_match_id uuid NOT NULL,
  spell_id uuid,
  participation_status text NOT NULL,
  position_code text,
  shirt_number integer,
  verification_status text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_match_appearances add constraint player_match_appearances_participation_status_check CHECK ((participation_status = ANY (ARRAY['STARTED'::text, 'SUBSTITUTE_USED'::text, 'UNUSED_SUBSTITUTE'::text])));
alter table public.player_match_appearances add constraint player_match_appearances_verification_status_check CHECK ((verification_status = ANY (ARRAY['VERIFIED'::text, 'PARTIAL'::text])));
alter table public.player_match_appearances add constraint player_match_appearances_shirt_number_check CHECK ((shirt_number > 0));
alter table public.player_match_appearances add constraint player_match_appearances_position_code_check CHECK ((position_code = ANY (ARRAY['GOL'::text, 'ZAG'::text, 'LD'::text, 'LE'::text, 'ALD'::text, 'ALE'::text, 'VOL'::text, 'MC'::text, 'MEI'::text, 'MD'::text, 'ME'::text, 'PD'::text, 'PE'::text, 'SA'::text, 'ATA'::text])));
alter table public.player_match_appearances add constraint player_match_appearances_pkey PRIMARY KEY (id);
alter table public.player_match_appearances add constraint player_match_appearances_person_id_club_id_canonical_match__key UNIQUE (person_id, club_id, canonical_match_id);
CREATE INDEX player_match_appearances_club_id_idx ON public.player_match_appearances USING btree (club_id);
CREATE INDEX player_match_appearances_match_id_idx ON public.player_match_appearances USING btree (canonical_match_id);
CREATE INDEX player_match_appearances_person_id_idx ON public.player_match_appearances USING btree (person_id);
alter table public.player_match_appearances enable row level security;
create policy "read player match appearances" on public.player_match_appearances for SELECT to public using (true);
grant SELECT on public.player_match_appearances to anon;
grant SELECT on public.player_match_appearances to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_match_appearances to service_role;

-- ---- TABLE: player_position_sources ----
create table public.player_position_sources (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  player_position_id uuid NOT NULL,
  source_type text NOT NULL,
  source_ref text NOT NULL,
  raw_value text NOT NULL,
  match_id text,
  observed_at date,
  evidence_type text NOT NULL,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_position_sources add constraint player_position_sources_evidence_type_check CHECK ((evidence_type = ANY (ARRAY['PRIMARY'::text, 'CORROBORATING'::text])));
alter table public.player_position_sources add constraint player_position_sources_pkey PRIMARY KEY (id);
alter table public.player_position_sources add constraint player_position_sources_player_position_id_source_type_sour_key UNIQUE (player_position_id, source_type, source_ref, match_id);
CREATE UNIQUE INDEX player_position_sources_no_match_idx ON public.player_position_sources USING btree (player_position_id, source_type, source_ref) WHERE (match_id IS NULL);
alter table public.player_position_sources enable row level security;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_position_sources to service_role;

-- ---- TABLE: player_positions ----
create table public.player_positions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  club_id uuid NOT NULL,
  spell_id uuid,
  position_code text NOT NULL,
  position_order integer NOT NULL,
  verification_status text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.player_positions add constraint player_positions_position_order_check CHECK ((position_order > 0));
alter table public.player_positions add constraint player_positions_verification_status_check CHECK ((verification_status = ANY (ARRAY['VERIFIED'::text, 'PARTIAL'::text])));
alter table public.player_positions add constraint player_positions_position_code_check CHECK ((position_code = ANY (ARRAY['GOL'::text, 'ZAG'::text, 'LD'::text, 'LE'::text, 'ALD'::text, 'ALE'::text, 'VOL'::text, 'MC'::text, 'MEI'::text, 'MD'::text, 'ME'::text, 'PD'::text, 'PE'::text, 'SA'::text, 'ATA'::text])));
alter table public.player_positions add constraint player_positions_pkey PRIMARY KEY (id);
alter table public.player_positions add constraint player_positions_person_id_club_id_spell_id_position_order_key UNIQUE (person_id, club_id, spell_id, position_order);
alter table public.player_positions add constraint player_positions_person_id_club_id_spell_id_position_code_key UNIQUE (person_id, club_id, spell_id, position_code);
CREATE INDEX player_positions_club_id_idx ON public.player_positions USING btree (club_id);
CREATE UNIQUE INDEX player_positions_general_code_idx ON public.player_positions USING btree (person_id, club_id, position_code) WHERE (spell_id IS NULL);
CREATE UNIQUE INDEX player_positions_general_order_idx ON public.player_positions USING btree (person_id, club_id, position_order) WHERE (spell_id IS NULL);
CREATE INDEX player_positions_person_id_idx ON public.player_positions USING btree (person_id);
alter table public.player_positions enable row level security;
create policy "read player positions" on public.player_positions for SELECT to public using (true);
grant SELECT on public.player_positions to anon;
grant SELECT on public.player_positions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.player_positions to service_role;

-- ---- TABLE: profiles ----
create table public.profiles (
  id uuid NOT NULL,
  full_name text,
  avatar_url text,
  phone text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  cpf text,
  birth_date date,
  marketing_opt_in boolean NOT NULL DEFAULT false
);
alter table public.profiles add constraint profiles_pkey PRIMARY KEY (id);
CREATE UNIQUE INDEX profiles_cpf_unique_idx ON public.profiles USING btree (cpf) WHERE (cpf IS NOT NULL);
alter table public.profiles enable row level security;
create policy "profiles_insert_own" on public.profiles for INSERT to public with check ((auth.uid() = id));
create policy "profiles_select_own" on public.profiles for SELECT to public using ((auth.uid() = id));
create policy "profiles_update_own" on public.profiles for UPDATE to public using ((auth.uid() = id)) with check ((auth.uid() = id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profiles to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profiles to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profiles to service_role;

-- ---- TABLE: quiz_active_session ----
create table public.quiz_active_session (
  user_id uuid NOT NULL,
  difficulty text NOT NULL,
  question_ids text[] NOT NULL,
  current_index integer NOT NULL DEFAULT 0,
  answers jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_review boolean NOT NULL DEFAULT false,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.quiz_active_session add constraint quiz_active_session_pkey PRIMARY KEY (club_id, user_id, difficulty);
CREATE INDEX quiz_active_session_club_id_idx ON public.quiz_active_session USING btree (club_id);
alter table public.quiz_active_session enable row level security;
create policy "delete own quiz session" on public.quiz_active_session for DELETE to public using ((auth.uid() = user_id));
create policy "insert own quiz session" on public.quiz_active_session for INSERT to public with check ((auth.uid() = user_id));
create policy "read own quiz session" on public.quiz_active_session for SELECT to public using ((auth.uid() = user_id));
create policy "update own quiz session" on public.quiz_active_session for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_active_session to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_active_session to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_active_session to service_role;

-- ---- TABLE: quiz_question_progress ----
create table public.quiz_question_progress (
  user_id uuid NOT NULL,
  question_id text NOT NULL,
  difficulty text NOT NULL,
  was_correct_first_attempt boolean NOT NULL,
  pending_review boolean NOT NULL DEFAULT false,
  answered_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.quiz_question_progress add constraint quiz_question_progress_pkey PRIMARY KEY (club_id, user_id, question_id);
CREATE INDEX quiz_question_progress_club_id_idx ON public.quiz_question_progress USING btree (club_id);
CREATE INDEX quiz_question_progress_user_difficulty_idx ON public.quiz_question_progress USING btree (user_id, difficulty);
alter table public.quiz_question_progress enable row level security;
create policy "insert own quiz progress" on public.quiz_question_progress for INSERT to public with check ((auth.uid() = user_id));
create policy "read own quiz progress" on public.quiz_question_progress for SELECT to public using ((auth.uid() = user_id));
create policy "update own quiz progress" on public.quiz_question_progress for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_question_progress to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_question_progress to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_question_progress to service_role;

-- ---- TABLE: quiz_questions ----
create table public.quiz_questions (
  id text NOT NULL,
  difficulty text NOT NULL,
  question text NOT NULL,
  options jsonb NOT NULL,
  correct_index integer NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.quiz_questions add constraint quiz_questions_difficulty_check CHECK ((difficulty = ANY (ARRAY['torcedor'::text, 'esmeraldino'::text, 'fanatico'::text])));
alter table public.quiz_questions add constraint quiz_questions_pkey PRIMARY KEY (id);
CREATE INDEX quiz_questions_club_id_idx ON public.quiz_questions USING btree (club_id);
alter table public.quiz_questions enable row level security;
create policy "read quiz questions" on public.quiz_questions for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_questions to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_questions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.quiz_questions to service_role;

-- ---- TABLE: score_events ----
create table public.score_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  game_id text NOT NULL,
  item_id text NOT NULL,
  event_type text NOT NULL,
  context text NOT NULL,
  attempt_number integer,
  previous_item_score integer NOT NULL,
  new_item_score integer NOT NULL,
  points_delta integer NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.score_events add constraint score_events_pkey PRIMARY KEY (id);
CREATE INDEX score_events_club_id_idx ON public.score_events USING btree (club_id);
CREATE INDEX score_events_user_created_idx ON public.score_events USING btree (user_id, created_at);
CREATE INDEX score_events_user_game_created_idx ON public.score_events USING btree (user_id, game_id, created_at);
alter table public.score_events enable row level security;
create policy "read own score events" on public.score_events for SELECT to public using ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.score_events to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.score_events to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.score_events to service_role;

-- ---- TABLE: squad_members ----
create table public.squad_members (
  id text NOT NULL,
  name text NOT NULL,
  full_name text,
  shirt_number integer,
  position text NOT NULL,
  birth_date date,
  nationality text,
  height_cm integer,
  foot text,
  photo_url text,
  club_history jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  position_group text NOT NULL,
  instagram_url text,
  person_id uuid,
  club_id uuid NOT NULL,
  active boolean NOT NULL DEFAULT true,
  departed_at date,
  departed_to text
);
alter table public.squad_members add constraint squad_members_pkey PRIMARY KEY (id);
CREATE INDEX squad_members_club_id_idx ON public.squad_members USING btree (club_id);
CREATE UNIQUE INDEX squad_members_club_person_uidx ON public.squad_members USING btree (club_id, person_id);
alter table public.squad_members enable row level security;
create policy "squad_members_read_all" on public.squad_members for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.squad_members to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.squad_members to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.squad_members to service_role;

-- ---- TABLE: store_orders ----
-- `order_number` deixou de ter `DEFAULT generate_store_order_number()`
-- (sem argumento) -- uma função que precisa saber o clube não pode ser
-- DEFAULT de coluna sem argumento. Calculado explicitamente dentro de
-- `create_store_order_for_club` antes do INSERT (ver função abaixo).
create table public.store_orders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  order_number text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  status text NOT NULL,
  fulfillment_method text NOT NULL,
  customer jsonb NOT NULL,
  address jsonb,
  shipping_option jsonb,
  pickup_responsible jsonb,
  payment jsonb NOT NULL,
  subtotal numeric NOT NULL,
  discount_amount numeric NOT NULL DEFAULT 0,
  shipping_cost numeric NOT NULL DEFAULT 0,
  coupon_code text,
  club_id uuid NOT NULL
);
alter table public.store_orders add constraint store_orders_pkey PRIMARY KEY (id);
alter table public.store_orders add constraint store_orders_order_number_key UNIQUE (order_number);
create index store_orders_club_id_idx on public.store_orders using btree (club_id);
create index store_orders_user_id_idx on public.store_orders using btree (user_id, created_at desc);
alter table public.store_orders enable row level security;
create policy "select own orders" on public.store_orders for SELECT to public using (auth.uid() = user_id);
create policy "insert own orders" on public.store_orders for INSERT to public with check (auth.uid() = user_id);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.store_orders to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.store_orders to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.store_orders to service_role;

-- ---- TABLE: store_order_items ----
create table public.store_order_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  product_id text NOT NULL,
  product_name text NOT NULL,
  product_image text NOT NULL,
  size text NOT NULL,
  quantity integer NOT NULL,
  unit_price numeric NOT NULL,
  personalization_surcharge numeric NOT NULL DEFAULT 0,
  personalized_name text,
  personalized_number integer,
  total_price numeric NOT NULL
);
alter table public.store_order_items add constraint store_order_items_pkey PRIMARY KEY (id);
create index store_order_items_order_id_idx on public.store_order_items using btree (order_id);
alter table public.store_order_items enable row level security;
create policy "select own order items" on public.store_order_items for SELECT to public using (exists (select 1 from store_orders o where o.id = store_order_items.order_id and o.user_id = auth.uid()));
create policy "insert own order items" on public.store_order_items for INSERT to public with check (exists (select 1 from store_orders o where o.id = store_order_items.order_id and o.user_id = auth.uid()));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.store_order_items to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.store_order_items to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.store_order_items to service_role;

-- ---- TABLE: membership_plans ----
-- NOVA nesta rodada de correção -- catálogo de planos data-driven,
-- club-scoped, VAZIO (zero plano inserido pelo baseline). Substitui o
-- catálogo hardcoded que existia dentro do corpo de
-- subscribe_to_plan_for_club (planos reais do Sócio Esmeralda) -- cadastro
-- de plano real é bootstrap/conteúdo por clube, uma etapa própria,
-- claramente fora deste baseline. `supporter_memberships.plan_id` continua
-- sem FK formal pra esta tabela (mesmo desenho do original -- não
-- introduzido aqui, minimizando mudança além do pedido).
create table public.membership_plans (
  club_id uuid NOT NULL,
  plan_key text NOT NULL,
  name text NOT NULL,
  duration_days integer NOT NULL DEFAULT 30,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.membership_plans add constraint membership_plans_pkey PRIMARY KEY (club_id, plan_key);
alter table public.membership_plans enable row level security;
create policy "read membership plans" on public.membership_plans for SELECT to public using (true);
grant SELECT on public.membership_plans to anon;
grant SELECT on public.membership_plans to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_plans to service_role;

-- ---- TABLE: supporter_memberships ----
create table public.supporter_memberships (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  plan_id text NOT NULL,
  plan_name text NOT NULL,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  expires_at timestamp with time zone NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.supporter_memberships add constraint supporter_memberships_pkey PRIMARY KEY (id);
CREATE INDEX supporter_memberships_club_id_idx ON public.supporter_memberships USING btree (club_id);
CREATE INDEX supporter_memberships_user_id_idx ON public.supporter_memberships USING btree (user_id);
alter table public.supporter_memberships enable row level security;
create policy "select own memberships" on public.supporter_memberships for SELECT to public using ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.supporter_memberships to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.supporter_memberships to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.supporter_memberships to service_role;

-- ---- TABLE: tactical_identity_results ----
create table public.tactical_identity_results (
  user_id uuid NOT NULL,
  game_type text NOT NULL DEFAULT 'tactical_identity'::text,
  x smallint NOT NULL,
  y smallint NOT NULL,
  archetype text NOT NULL,
  possession_percentage smallint NOT NULL,
  vertical_percentage smallint NOT NULL,
  dogmatic_percentage smallint NOT NULL,
  pragmatic_percentage smallint NOT NULL,
  closest_coach_id text,
  answers jsonb NOT NULL,
  completed_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.tactical_identity_results add constraint tactical_identity_results_pkey PRIMARY KEY (user_id, club_id);
CREATE INDEX tactical_identity_results_club_id_idx ON public.tactical_identity_results USING btree (club_id);
alter table public.tactical_identity_results enable row level security;
create policy "insert own tactical identity result" on public.tactical_identity_results for INSERT to public with check ((auth.uid() = user_id));
create policy "read own tactical identity result" on public.tactical_identity_results for SELECT to public using ((auth.uid() = user_id));
create policy "update own tactical identity result" on public.tactical_identity_results for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.tactical_identity_results to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.tactical_identity_results to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.tactical_identity_results to service_role;

-- ---- TABLE: ticket_checkin_decisions ----
create table public.ticket_checkin_decisions (
  user_id uuid NOT NULL,
  match_id text NOT NULL,
  decision text NOT NULL,
  sector_id text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.ticket_checkin_decisions add constraint ticket_checkin_decisions_decision_check CHECK ((decision = ANY (ARRAY['confirmed'::text, 'declined'::text])));
alter table public.ticket_checkin_decisions add constraint ticket_checkin_decisions_pkey PRIMARY KEY (club_id, user_id, match_id);
CREATE INDEX ticket_checkin_decisions_club_id_idx ON public.ticket_checkin_decisions USING btree (club_id);
alter table public.ticket_checkin_decisions enable row level security;
create policy "delete own checkin decisions" on public.ticket_checkin_decisions for DELETE to public using ((auth.uid() = user_id));
create policy "insert own checkin decisions" on public.ticket_checkin_decisions for INSERT to public with check ((auth.uid() = user_id));
create policy "read own checkin decisions" on public.ticket_checkin_decisions for SELECT to public using ((auth.uid() = user_id));
create policy "update own checkin decisions" on public.ticket_checkin_decisions for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.ticket_checkin_decisions to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.ticket_checkin_decisions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.ticket_checkin_decisions to service_role;

-- ---- TABLE: ticket_orders ----
create table public.ticket_orders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  number text NOT NULL,
  match_id text NOT NULL,
  competition text NOT NULL,
  round text NOT NULL,
  home_team_id integer NOT NULL,
  home_team_name text NOT NULL,
  away_team_id integer NOT NULL,
  away_team_name text NOT NULL,
  kickoff timestamp with time zone,
  stadium text NOT NULL,
  items jsonb NOT NULL,
  holder_name text NOT NULL,
  holder_document text NOT NULL,
  total numeric NOT NULL,
  status text NOT NULL DEFAULT 'confirmed'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.ticket_orders add constraint ticket_orders_pkey PRIMARY KEY (id);
CREATE INDEX ticket_orders_club_id_idx ON public.ticket_orders USING btree (club_id);
alter table public.ticket_orders enable row level security;
create policy "insert own orders" on public.ticket_orders for INSERT to public with check ((auth.uid() = user_id));
create policy "read own orders" on public.ticket_orders for SELECT to public using ((auth.uid() = user_id));
create policy "update own orders" on public.ticket_orders for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.ticket_orders to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.ticket_orders to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.ticket_orders to service_role;

-- ---- TABLE: tickets ----
create table public.tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  match_id text NOT NULL,
  competition text NOT NULL,
  round text NOT NULL,
  home_team_id integer NOT NULL,
  home_team_name text NOT NULL,
  away_team_id integer NOT NULL,
  away_team_name text NOT NULL,
  kickoff timestamp with time zone,
  stadium text NOT NULL,
  sector_id text NOT NULL,
  sector_name text NOT NULL,
  venue_label text NOT NULL,
  gate text NOT NULL,
  category_label text,
  holder_name text NOT NULL,
  holder_document text NOT NULL,
  status text NOT NULL DEFAULT 'active'::text,
  origin text NOT NULL,
  order_id uuid,
  price numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  refunded_at timestamp with time zone,
  club_id uuid NOT NULL
);
alter table public.tickets add constraint tickets_status_check CHECK ((status = ANY (ARRAY['active'::text, 'cancelled'::text, 'used'::text, 'expired'::text, 'refunded'::text])));
alter table public.tickets add constraint tickets_origin_check CHECK ((origin = ANY (ARRAY['purchase'::text, 'membership_check_in'::text])));
alter table public.tickets add constraint tickets_pkey PRIMARY KEY (id);
CREATE INDEX tickets_club_id_idx ON public.tickets USING btree (club_id);
CREATE UNIQUE INDEX tickets_club_user_match_checkin_uidx ON public.tickets USING btree (club_id, user_id, match_id) WHERE (origin = 'membership_check_in'::text);
CREATE INDEX tickets_user_match_idx ON public.tickets USING btree (user_id, match_id);
alter table public.tickets enable row level security;
create policy "insert own tickets" on public.tickets for INSERT to public with check ((auth.uid() = user_id));
create policy "read own tickets" on public.tickets for SELECT to public using ((auth.uid() = user_id));
create policy "update own tickets" on public.tickets for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.tickets to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.tickets to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.tickets to service_role;

-- ---- TABLE: user_addresses ----
create table public.user_addresses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  zip_code text,
  street text,
  number text,
  complement text,
  neighborhood text,
  city text,
  state text,
  country text DEFAULT 'BR'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.user_addresses add constraint user_addresses_pkey PRIMARY KEY (id);
alter table public.user_addresses add constraint user_addresses_user_id_key UNIQUE (user_id);
alter table public.user_addresses enable row level security;
create policy "addresses_delete_own" on public.user_addresses for DELETE to public using ((auth.uid() = user_id));
create policy "addresses_insert_own" on public.user_addresses for INSERT to public with check ((auth.uid() = user_id));
create policy "addresses_select_own" on public.user_addresses for SELECT to public using ((auth.uid() = user_id));
create policy "addresses_update_own" on public.user_addresses for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_addresses to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_addresses to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_addresses to service_role;

-- ---- TABLE: user_game_item_progress ----
create table public.user_game_item_progress (
  user_id uuid NOT NULL,
  game_id text NOT NULL,
  item_id text NOT NULL,
  first_played_at timestamp with time zone NOT NULL DEFAULT now(),
  completed_at timestamp with time zone,
  attempts_used integer,
  wrong_attempts integer,
  was_revealed boolean NOT NULL DEFAULT false,
  was_abandoned boolean NOT NULL DEFAULT false,
  was_reviewed boolean NOT NULL DEFAULT false,
  score integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.user_game_item_progress add constraint user_game_item_progress_pkey PRIMARY KEY (club_id, user_id, game_id, item_id);
CREATE INDEX user_game_item_progress_club_id_idx ON public.user_game_item_progress USING btree (club_id);
CREATE INDEX user_game_item_progress_user_game_idx ON public.user_game_item_progress USING btree (user_id, game_id);
alter table public.user_game_item_progress enable row level security;
create policy "read own item progress" on public.user_game_item_progress for SELECT to public using ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_game_item_progress to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_game_item_progress to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_game_item_progress to service_role;

-- ---- TABLE: user_notification_preferences ----
create table public.user_notification_preferences (
  user_id uuid NOT NULL,
  matches_enabled boolean NOT NULL DEFAULT true,
  tickets_enabled boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.user_notification_preferences add constraint user_notification_preferences_pkey PRIMARY KEY (user_id, club_id);
CREATE INDEX user_notification_preferences_club_id_idx ON public.user_notification_preferences USING btree (club_id);
alter table public.user_notification_preferences enable row level security;
create policy "insert own preferences" on public.user_notification_preferences for INSERT to public with check ((auth.uid() = user_id));
create policy "read own preferences" on public.user_notification_preferences for SELECT to public using ((auth.uid() = user_id));
create policy "update own preferences" on public.user_notification_preferences for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_notification_preferences to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_notification_preferences to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_notification_preferences to service_role;

-- ---- TABLE: user_notification_tokens ----
create table public.user_notification_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  fcm_token text NOT NULL,
  platform text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  last_seen_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  club_id uuid NOT NULL
);
alter table public.user_notification_tokens add constraint user_notification_tokens_platform_check CHECK ((platform = ANY (ARRAY['android'::text, 'ios'::text])));
alter table public.user_notification_tokens add constraint user_notification_tokens_pkey PRIMARY KEY (id);
alter table public.user_notification_tokens add constraint user_notification_tokens_fcm_token_key UNIQUE (fcm_token);
CREATE INDEX user_notification_tokens_user_idx ON public.user_notification_tokens USING btree (user_id) WHERE is_active;
alter table public.user_notification_tokens enable row level security;
create policy "delete own tokens" on public.user_notification_tokens for DELETE to public using ((auth.uid() = user_id));
create policy "insert own tokens" on public.user_notification_tokens for INSERT to public with check ((auth.uid() = user_id));
create policy "read own tokens" on public.user_notification_tokens for SELECT to public using ((auth.uid() = user_id));
create policy "update own tokens" on public.user_notification_tokens for UPDATE to public using ((auth.uid() = user_id)) with check ((auth.uid() = user_id));
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_notification_tokens to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_notification_tokens to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.user_notification_tokens to service_role;

-- ---- TABLE: venues ----
create table public.venues (
  id text NOT NULL,
  canonical_name text NOT NULL,
  display_name text NOT NULL,
  city text,
  state text,
  country text,
  latitude numeric,
  longitude numeric,
  aliases text[] NOT NULL DEFAULT '{}'::text[],
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);
alter table public.venues add constraint venues_pkey PRIMARY KEY (id);
alter table public.venues enable row level security;
create policy "venues_read_all" on public.venues for SELECT to public using (true);
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.venues to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.venues to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.venues to service_role;

-- ============================================================================
-- FOREIGN KEY CONSTRAINTS (bloco único, depois de todas as tabelas)
-- ============================================================================
-- Movidas pra cá deliberadamente: introspecção lista tabelas em ordem
-- alfabetica (career_players antes de people, app_release_requirements
-- antes de clubs, etc.) e um FK inline logo apos o CREATE TABLE falha
-- (42P01 relation does not exist) sempre que a tabela referenciada nasce
-- depois no arquivo. Bug real, achado pelo push REAL contra Bragantino
-- (dry-run nao pega — nao executa de fato). Fix estrutural: TODAS as FKs
-- ficam num bloco so, depois que toda CREATE TABLE ja rodou — nunca mais
-- depende de ordem alfabetica, nem hoje nem em tabela futura.

alter table public.app_release_requirements add constraint app_release_requirements_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.arena_achievements add constraint arena_achievements_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.arena_achievements add constraint arena_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.arena_selected_content add constraint arena_selected_content_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.arena_selected_content add constraint arena_selected_content_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.career_path_progress add constraint career_path_progress_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.career_path_progress add constraint career_path_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.career_players add constraint career_players_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.career_players add constraint career_players_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.club_board_members add constraint club_board_members_section_id_fkey FOREIGN KEY (section_id) REFERENCES club_board_sections(id) ON DELETE CASCADE;
alter table public.club_transparency_documents add constraint club_transparency_documents_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES club_transparency_topics(id) ON DELETE CASCADE;
alter table public.delivery_addresses add constraint delivery_addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.guess_players add constraint guess_players_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.guess_players add constraint guess_players_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.lineup_match_progress add constraint lineup_match_progress_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.lineup_match_progress add constraint lineup_match_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.lineup_matches add constraint lineup_matches_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.match_lineup_votes add constraint match_lineup_votes_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.match_lineup_votes add constraint match_lineup_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.match_monitor_sessions add constraint match_monitor_sessions_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.match_source_refs add constraint match_source_refs_source_club_id_fkey FOREIGN KEY (source_club_id) REFERENCES clubs(id);
alter table public.match_source_refs add constraint match_source_refs_match_id_fkey FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE;
alter table public.matches add constraint matches_home_club_id_fkey FOREIGN KEY (home_club_id) REFERENCES clubs(id);
alter table public.matches add constraint matches_away_club_id_fkey FOREIGN KEY (away_club_id) REFERENCES clubs(id);
alter table public.membership_faq_items add constraint membership_faq_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES membership_faq_categories(id) ON DELETE CASCADE;
alter table public.notification_deliveries add constraint notification_deliveries_event_id_fkey FOREIGN KEY (event_id) REFERENCES notification_events(id) ON DELETE CASCADE;
alter table public.notification_deliveries add constraint notification_deliveries_token_id_fkey FOREIGN KEY (token_id) REFERENCES user_notification_tokens(id) ON DELETE CASCADE;
alter table public.notification_events add constraint notification_events_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.passport_attendances add constraint passport_attendances_match_id_fkey FOREIGN KEY (match_id) REFERENCES passport_matches(id) ON DELETE CASCADE;
alter table public.passport_attendances add constraint passport_attendances_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.passport_matches add constraint passport_matches_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES venues(id);
alter table public.passport_memorable_matches add constraint passport_memorable_matches_match_id_fkey FOREIGN KEY (match_id) REFERENCES passport_matches(id) ON DELETE CASCADE;
alter table public.passport_memorable_matches add constraint passport_memorable_matches_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.person_alias_sources add constraint person_alias_sources_person_alias_id_fkey FOREIGN KEY (person_alias_id) REFERENCES person_aliases(id) ON DELETE CASCADE;
alter table public.person_aliases add constraint person_aliases_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.player_club_spell_sources add constraint player_club_spell_sources_spell_id_fkey FOREIGN KEY (spell_id) REFERENCES player_club_spells(id) ON DELETE CASCADE;
alter table public.player_club_spells add constraint player_club_spells_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.player_club_spells add constraint player_club_spells_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.player_club_stat_sources add constraint player_club_stat_sources_player_club_stat_id_fkey FOREIGN KEY (player_club_stat_id) REFERENCES player_club_stats(id) ON DELETE CASCADE;
alter table public.player_club_stats add constraint player_club_stats_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.player_club_stats add constraint player_club_stats_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.player_club_stats add constraint player_club_stats_spell_coherence_fkey FOREIGN KEY (spell_id, person_id, club_id) REFERENCES player_club_spells(id, person_id, club_id);
alter table public.player_identity_results add constraint player_identity_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.player_identity_results add constraint player_identity_results_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.player_match_appearance_sources add constraint player_match_appearance_sources_player_match_appearance_id_fkey FOREIGN KEY (player_match_appearance_id) REFERENCES player_match_appearances(id) ON DELETE CASCADE;
alter table public.player_match_appearances add constraint player_match_appearances_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.player_match_appearances add constraint player_match_appearances_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.player_match_appearances add constraint player_match_appearances_canonical_match_id_fkey FOREIGN KEY (canonical_match_id) REFERENCES matches(id);
alter table public.player_match_appearances add constraint player_match_appearances_spell_coherence_fkey FOREIGN KEY (spell_id, person_id, club_id) REFERENCES player_club_spells(id, person_id, club_id);
alter table public.player_position_sources add constraint player_position_sources_player_position_id_fkey FOREIGN KEY (player_position_id) REFERENCES player_positions(id) ON DELETE CASCADE;
alter table public.player_positions add constraint player_positions_spell_id_fkey FOREIGN KEY (spell_id) REFERENCES player_club_spells(id);
alter table public.player_positions add constraint player_positions_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.player_positions add constraint player_positions_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.profiles add constraint profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.quiz_active_session add constraint quiz_active_session_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.quiz_active_session add constraint quiz_active_session_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.quiz_question_progress add constraint quiz_question_progress_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.quiz_question_progress add constraint quiz_question_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.quiz_questions add constraint quiz_questions_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.score_events add constraint score_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.score_events add constraint score_events_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.squad_members add constraint squad_members_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.squad_members add constraint squad_members_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);
alter table public.store_order_items add constraint store_order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES store_orders(id) ON DELETE CASCADE;
alter table public.store_orders add constraint store_orders_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.store_orders add constraint store_orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.membership_plans add constraint membership_plans_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.supporter_memberships add constraint supporter_memberships_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.supporter_memberships add constraint supporter_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.tactical_identity_results add constraint tactical_identity_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.tactical_identity_results add constraint tactical_identity_results_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.ticket_checkin_decisions add constraint ticket_checkin_decisions_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.ticket_checkin_decisions add constraint ticket_checkin_decisions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.ticket_orders add constraint ticket_orders_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.ticket_orders add constraint ticket_orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.tickets add constraint tickets_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.tickets add constraint tickets_order_id_fkey FOREIGN KEY (order_id) REFERENCES ticket_orders(id) ON DELETE SET NULL;
alter table public.tickets add constraint tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.user_addresses add constraint user_addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.user_game_item_progress add constraint user_game_item_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.user_game_item_progress add constraint user_game_item_progress_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.user_notification_preferences add constraint user_notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.user_notification_preferences add constraint user_notification_preferences_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.user_notification_tokens add constraint user_notification_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.user_notification_tokens add constraint user_notification_tokens_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);

-- ============================================================================
-- FUNCTIONS (RPCs)
-- ============================================================================

-- ---- FUNCTION: arena_my_rank -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: arena_my_rank_for_club ----
CREATE OR REPLACE FUNCTION public.arena_my_rank_for_club(p_club_id uuid, p_period text DEFAULT 'all_time'::text)
 RETURNS TABLE(rank integer, total_score integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return query
  with all_totals as (
    select
      e.user_id,
      sum(e.points_delta)::int as total_score,
      count(*) filter (
        where e.event_type = 'first_try_correct' and e.points_delta > 0
      )::int as first_try_count,
      count(*) filter (
        where e.event_type in ('revealed', 'abandoned', 'attempts_exhausted')
      )::int as revealed_or_abandoned_count,
      max(e.created_at) as reached_at
    from public.score_events e
    where e.club_id = p_club_id
      and (
        p_period = 'all_time'
        or (p_period = 'weekly' and e.created_at >= date_trunc(
              'week', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
        or (p_period = 'monthly' and e.created_at >= date_trunc(
              'month', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
      )
    group by e.user_id
    having sum(e.points_delta) > 0
  ),
  ranked as (
    select
      user_id,
      total_score,
      row_number() over (
        order by total_score desc, first_try_count desc,
          revealed_or_abandoned_count asc, reached_at asc
      )::int as rank
    from all_totals
  )
  select r.rank, r.total_score
  from ranked r
  where r.user_id = auth.uid();
end;
$function$
;
revoke all on function public.arena_my_rank_for_club(p_club_id uuid, p_period text) from public;
grant execute on function public.arena_my_rank_for_club(p_club_id uuid, p_period text) to authenticated;

-- ---- FUNCTION: arena_ranking -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: arena_ranking_for_club ----
CREATE OR REPLACE FUNCTION public.arena_ranking_for_club(p_club_id uuid, p_period text DEFAULT 'all_time'::text, p_limit integer DEFAULT 50)
 RETURNS TABLE(rank integer, user_id uuid, name text, avatar_url text, is_member boolean, total_score integer, first_try_count integer, revealed_or_abandoned_count integer, reached_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return query
  with window_events as (
    select *
    from public.score_events e
    where e.club_id = p_club_id
      and (
        p_period = 'all_time'
        or (p_period = 'weekly' and e.created_at >= date_trunc(
              'week', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
        or (p_period = 'monthly' and e.created_at >= date_trunc(
              'month', now() at time zone 'America/Sao_Paulo'
            ) at time zone 'America/Sao_Paulo')
      )
  ),
  totals as (
    select
      w.user_id,
      sum(w.points_delta)::int as total_score,
      count(*) filter (
        where w.event_type = 'first_try_correct' and w.points_delta > 0
      )::int as first_try_count,
      count(*) filter (
        where w.event_type in ('revealed', 'abandoned', 'attempts_exhausted')
      )::int as revealed_or_abandoned_count,
      max(w.created_at) as reached_at
    from window_events w
    group by w.user_id
    having sum(w.points_delta) > 0
  )
  select
    row_number() over (
      order by t.total_score desc, t.first_try_count desc,
        t.revealed_or_abandoned_count asc, t.reached_at asc
    )::int as rank,
    t.user_id,
    coalesce(nullif(trim(pr.full_name), ''), 'Torcedor') as name,
    pr.avatar_url,
    -- Mesmo mock explicado na RPC legacy: sócio ainda não é consultável a
    -- partir daqui pro ranking (não é o que get_my_membership_for_club
    -- resolve — aquilo é só "eu, agora"; aqui seria "qualquer um no
    -- ranking").
    false as is_member,
    t.total_score,
    t.first_try_count,
    t.revealed_or_abandoned_count,
    t.reached_at
  from totals t
  left join public.profiles pr on pr.id = t.user_id
  order by t.total_score desc, t.first_try_count desc,
    t.revealed_or_abandoned_count asc, t.reached_at asc
  limit p_limit;
end;
$function$
;
revoke all on function public.arena_ranking_for_club(p_club_id uuid, p_period text, p_limit integer) from public;
grant execute on function public.arena_ranking_for_club(p_club_id uuid, p_period text, p_limit integer) to authenticated;

-- ---- FUNCTION: arena_record_score -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: arena_record_score_for_club ----
CREATE OR REPLACE FUNCTION public.arena_record_score_for_club(p_club_id uuid, p_game_id text, p_item_id text, p_event_type text, p_attempt_number integer DEFAULT NULL::integer, p_difficulty text DEFAULT NULL::text, p_wrong_count integer DEFAULT NULL::integer, p_found_count integer DEFAULT NULL::integer, p_total_count integer DEFAULT NULL::integer, p_was_revealed boolean DEFAULT false, p_was_abandoned boolean DEFAULT false)
 RETURNS TABLE(points_delta integer, item_score integer, total_score integer, game_score integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_prev record;
  v_is_replay boolean;
  v_context text;
  v_candidate int;
  v_cap int;
  v_new_score int;
  v_delta int;
  v_item_exists boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  -- item_id precisa existir de verdade na tabela de conteúdo do jogo
  -- correspondente E pertencer ao clube informado — mesma proteção
  -- anti-id-fabricado da RPC legacy, agora também tenant-scoped.
  v_item_exists := case p_game_id
    when 'quiz' then
      exists (
        select 1 from public.quiz_questions
        where id = p_item_id and club_id = p_club_id
      )
    when 'career_path' then
      exists (
        select 1 from public.career_players
        where id = p_item_id and club_id = p_club_id
      )
    when 'guess_player' then
      exists (
        select 1 from public.guess_players
        where id = p_item_id and club_id = p_club_id
      )
    when 'lineup' then
      exists (
        select 1 from public.lineup_matches
        where id = p_item_id and club_id = p_club_id
      )
    else false
  end;

  if not v_item_exists then
    raise exception 'invalid item_id % for game_id % and club_id %',
      p_item_id, p_game_id, p_club_id;
  end if;

  select * into v_prev
  from public.user_game_item_progress
  where user_id = v_uid and game_id = p_game_id and item_id = p_item_id
    and club_id = p_club_id
  for update;

  -- KEY_SCOPE guard: mantido por defesa (KEEP_DEFENSIVELY), mesmo que agora
  -- estruturalmente inalcançável — v_prev só pode conter uma linha do
  -- próprio p_club_id desde a correção acima, então esta condição nunca
  -- mais deve ser verdadeira. Histórico: protegia contra o INSERT bater na
  -- PK legada (user_id, game_id, item_id), que já não existe desde a
  -- M2.2B-B (KEY_SCOPE_FINAL=true).
  if v_prev.user_id is not null and v_prev.club_id is distinct from p_club_id then
    raise exception
      'key_scope_collision: item % (game %) already has progress under a different club_id (KEY_SCOPE not yet resolved, see M2.2B)',
      p_item_id, p_game_id;
  end if;

  v_is_replay := v_prev.user_id is not null;
  v_context := case when v_is_replay then 'review' else 'first_play' end;

  v_candidate := case p_game_id
    when 'quiz' then
      case
        when p_event_type in ('first_try_correct', 'review_correct') then
          case p_difficulty
            when 'torcedor' then case when v_is_replay then 3 else 8 end
            when 'esmeraldino' then case when v_is_replay then 4 else 10 end
            when 'fanatico' then case when v_is_replay then 5 else 12 end
            else 0
          end
        else 0
      end
    when 'career_path' then
      case
        when p_was_revealed then 2
        when p_attempt_number is not null then
          case p_attempt_number
            when 1 then 25 when 2 then 20 when 3 then 15
            when 4 then 10 when 5 then 5 else 0
          end
        else 0
      end
    when 'guess_player' then
      case
        when p_was_revealed then 2
        when p_attempt_number is not null then
          case p_attempt_number
            when 1 then 25 when 2 then 22 when 3 then 19 when 4 then 16
            when 5 then 13 when 6 then 10 when 7 then 7 else 0
          end
        else 0
      end
    when 'lineup' then
      case
        when p_was_abandoned then
          round(
            (coalesce(p_found_count, 0)::numeric
              / greatest(coalesce(p_total_count, 1), 1)) * 8
          )::int
        else
          greatest(12, 20 - coalesce(p_wrong_count, 0))
      end
    else 0
  end;

  v_cap := case
    when p_game_id in ('career_path', 'guess_player') and v_is_replay then 5
    when p_game_id = 'lineup' and v_is_replay
      and coalesce(v_prev.was_abandoned, false) then 8
    else v_candidate
  end;

  v_candidate := least(v_candidate, v_cap);
  v_new_score := greatest(coalesce(v_prev.score, 0), v_candidate);
  v_delta := v_new_score - coalesce(v_prev.score, 0);

  insert into public.user_game_item_progress as p (
    user_id, game_id, item_id, club_id, completed_at, attempts_used,
    wrong_attempts, was_revealed, was_abandoned, was_reviewed, score,
    updated_at
  )
  values (
    v_uid, p_game_id, p_item_id, p_club_id, now(), p_attempt_number,
    p_wrong_count, p_was_revealed, p_was_abandoned, v_is_replay, v_new_score,
    now()
  )
  on conflict (club_id, user_id, game_id, item_id) do update set
    club_id = p_club_id,
    completed_at = now(),
    attempts_used = coalesce(excluded.attempts_used, p.attempts_used),
    wrong_attempts = coalesce(excluded.wrong_attempts, p.wrong_attempts),
    was_revealed = p.was_revealed or excluded.was_revealed,
    was_abandoned = p.was_abandoned or excluded.was_abandoned,
    was_reviewed = true,
    score = v_new_score,
    updated_at = now();

  insert into public.score_events (
    user_id, game_id, item_id, club_id, event_type, context, attempt_number,
    previous_item_score, new_item_score, points_delta
  )
  values (
    v_uid, p_game_id, p_item_id, p_club_id, p_event_type, v_context,
    p_attempt_number, coalesce(v_prev.score, 0), v_new_score, v_delta
  );

  return query
  select
    v_delta,
    v_new_score,
    (select coalesce(sum(score), 0)::int
      from public.user_game_item_progress
      where user_id = v_uid and club_id = p_club_id),
    (select coalesce(sum(score), 0)::int
      from public.user_game_item_progress
      where user_id = v_uid and club_id = p_club_id and game_id = p_game_id);
end;
$function$
;
revoke all on function public.arena_record_score_for_club(p_club_id uuid, p_game_id text, p_item_id text, p_event_type text, p_attempt_number integer, p_difficulty text, p_wrong_count integer, p_found_count integer, p_total_count integer, p_was_revealed boolean, p_was_abandoned boolean) from public;
grant execute on function public.arena_record_score_for_club(p_club_id uuid, p_game_id text, p_item_id text, p_event_type text, p_attempt_number integer, p_difficulty text, p_wrong_count integer, p_found_count integer, p_total_count integer, p_was_revealed boolean, p_was_abandoned boolean) to authenticated;

-- ---- FUNCTION: arena_user_detail -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: arena_user_detail_for_club ----
CREATE OR REPLACE FUNCTION public.arena_user_detail_for_club(p_club_id uuid, p_user_id uuid)
 RETURNS TABLE(game_id text, game_score integer, first_try_count integer, review_count integer, abandoned_or_revealed_count integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return query
  select
    p.game_id,
    sum(p.score)::int as game_score,
    count(*) filter (
      where not p.was_reviewed and not p.was_revealed and not p.was_abandoned
        and p.score > 0
    )::int as first_try_count,
    count(*) filter (where p.was_reviewed and p.score > 0)::int as review_count,
    count(*) filter (
      where p.was_revealed or p.was_abandoned
    )::int as abandoned_or_revealed_count
  from public.user_game_item_progress p
  where p.user_id = p_user_id and p.club_id = p_club_id
  group by p.game_id;
end;
$function$
;
revoke all on function public.arena_user_detail_for_club(p_club_id uuid, p_user_id uuid) from public;
grant execute on function public.arena_user_detail_for_club(p_club_id uuid, p_user_id uuid) to authenticated;

-- ---- FUNCTION: cpf_is_taken ----
CREATE OR REPLACE FUNCTION public.cpf_is_taken(p_cpf text)
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.profiles where cpf = p_cpf
  );
$function$
;
revoke all on function public.cpf_is_taken(p_cpf text) from public;
grant execute on function public.cpf_is_taken(p_cpf text) to anon, authenticated, service_role;

-- ---- FUNCTION: create_store_order -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: create_store_order_for_club ----
-- REINCLUÍDA nesta rodada de correção (estava excluída só por depender da
-- generate_store_order_number antiga). Idêntica à original, só troca
-- `order_number` DEFAULT implícito por cálculo explícito via a função
-- redesenhada acima. Código NOVO nesse ponto específico -- resto
-- introspectado ao vivo sem mudança.
CREATE OR REPLACE FUNCTION public.create_store_order_for_club(p_club_id uuid, p_status text, p_fulfillment_method text, p_customer jsonb, p_address jsonb, p_shipping_option jsonb, p_pickup_responsible jsonb, p_payment jsonb, p_subtotal numeric, p_discount_amount numeric, p_shipping_cost numeric, p_coupon_code text, p_items jsonb)
 RETURNS store_orders
 LANGUAGE plpgsql
AS $function$
declare
  v_order public.store_orders;
  v_item jsonb;
  v_order_number text;
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  v_order_number := public.generate_store_order_number(p_club_id);

  insert into public.store_orders (
    user_id, club_id, order_number, status, fulfillment_method, customer, address,
    shipping_option, pickup_responsible, payment, subtotal,
    discount_amount, shipping_cost, coupon_code
  ) values (
    auth.uid(), p_club_id, v_order_number, p_status, p_fulfillment_method,
    p_customer, p_address, p_shipping_option, p_pickup_responsible, p_payment,
    p_subtotal, p_discount_amount, p_shipping_cost, p_coupon_code
  )
  returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.store_order_items (
      order_id, product_id, product_name, product_image, size,
      quantity, unit_price, personalization_surcharge,
      personalized_name, personalized_number, total_price
    ) values (
      v_order.id,
      v_item->>'productId',
      v_item->>'productName',
      v_item->>'thumbnail',
      v_item->>'size',
      (v_item->>'quantity')::integer,
      (v_item->>'unitPrice')::numeric,
      coalesce((v_item->>'personalizationSurcharge')::numeric, 0),
      v_item->>'personalizedName',
      (v_item->>'personalizedNumber')::integer,
      (coalesce((v_item->>'unitPrice')::numeric, 0) +
        coalesce((v_item->>'personalizationSurcharge')::numeric, 0)) *
        (v_item->>'quantity')::integer
    );
  end loop;

  return v_order;
end;
$function$;
revoke all on function public.create_store_order_for_club(p_club_id uuid, p_status text, p_fulfillment_method text, p_customer jsonb, p_address jsonb, p_shipping_option jsonb, p_pickup_responsible jsonb, p_payment jsonb, p_subtotal numeric, p_discount_amount numeric, p_shipping_cost numeric, p_coupon_code text, p_items jsonb) from public;
grant execute on function public.create_store_order_for_club(p_club_id uuid, p_status text, p_fulfillment_method text, p_customer jsonb, p_address jsonb, p_shipping_option jsonb, p_pickup_responsible jsonb, p_payment jsonb, p_subtotal numeric, p_discount_amount numeric, p_shipping_cost numeric, p_coupon_code text, p_items jsonb) to authenticated;

-- ---- FUNCTION: crowd_lineup -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: crowd_lineup_for_club ----
CREATE OR REPLACE FUNCTION public.crowd_lineup_for_club(p_club_id uuid, p_match_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
declare
  v_result jsonb;
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  with v as (
    select formation, slots
    from public.match_lineup_votes
    where match_id = p_match_id and club_id = p_club_id
  ),
  fc as (
    select formation, count(*)::int c from v group by formation
  ),
  sc as (
    select formation, (s ->> 'i')::int slot, s ->> 'pid' pid, count(*)::int c
    from v, jsonb_array_elements(v.slots) s
    group by formation, (s ->> 'i')::int, s ->> 'pid'
  ),
  slot_players as (
    select formation, slot, jsonb_object_agg(pid, c) players
    from sc group by formation, slot
  ),
  formation_slots as (
    select formation, jsonb_object_agg(slot::text, players) slotmap
    from slot_players group by formation
  )
  select jsonb_build_object(
    'total_votes', (select count(*)::int from v),
    'formations', coalesce((select jsonb_object_agg(formation, c) from fc), '{}'::jsonb),
    'slots', coalesce((select jsonb_object_agg(formation, slotmap) from formation_slots), '{}'::jsonb)
  )
  into v_result;

  return v_result;
end;
$function$
;
revoke all on function public.crowd_lineup_for_club(p_club_id uuid, p_match_id text) from public;
grant execute on function public.crowd_lineup_for_club(p_club_id uuid, p_match_id text) to authenticated;

-- ---- FUNCTION: delivery_address_enforce_single_default ----
CREATE OR REPLACE FUNCTION public.delivery_address_enforce_single_default()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.is_default then
    update public.delivery_addresses
      set is_default = false
      where user_id = new.user_id and id <> new.id and is_default = true;
  end if;
  return new;
end;
$function$
;
revoke all on function public.delivery_address_enforce_single_default() from public;
grant execute on function public.delivery_address_enforce_single_default() to anon, authenticated, service_role;

-- ---- FUNCTION: delivery_address_ensure_default ----
CREATE OR REPLACE FUNCTION public.delivery_address_ensure_default()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if not exists (
    select 1 from public.delivery_addresses
    where user_id = new.user_id and id <> new.id
  ) then
    new.is_default := true;
  end if;
  return new;
end;
$function$
;
revoke all on function public.delivery_address_ensure_default() from public;
grant execute on function public.delivery_address_ensure_default() to anon, authenticated, service_role;

-- ---- TRIGGERS: delivery_addresses (gap achado comparando Goiás x
-- Bragantino já convergidos -- capture original de trigger só cobriu
-- auth.users; corrigido aqui pra qualquer clube novo nascer completo) ----
CREATE TRIGGER delivery_addresses_ensure_default BEFORE INSERT ON public.delivery_addresses FOR EACH ROW EXECUTE FUNCTION delivery_address_ensure_default();
CREATE TRIGGER delivery_addresses_single_default BEFORE INSERT OR UPDATE ON public.delivery_addresses FOR EACH ROW EXECUTE FUNCTION delivery_address_enforce_single_default();

-- ---- SEQUENCE: store_order_number_seq ----
-- Sequence standalone (não é SERIAL de nenhuma coluna -- order_number é
-- text) -- não aparece na introspecção de colunas/constraints, criada à
-- parte. 1 sequence por PROJETO (não por clube) é suficiente no modelo
-- multi-Supabase -- cada projeto só serve 1 clube fisicamente, nunca
-- precisou ser "por clube" pra evitar colisão.
create sequence public.store_order_number_seq;

-- ---- FUNCTION: generate_store_order_number ----
-- REDESENHADA nesta rodada de correção -- genérica por clube, nunca um
-- prefixo hardcoded. Código NOVO (não introspecção), precisa de revisão
-- extra antes de qualquer aplicação real.
CREATE OR REPLACE FUNCTION public.generate_store_order_number(p_club_id uuid)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare
  v_prefix text;
begin
  select coalesce(order_prefix, upper(left(slug, 3))) into v_prefix
  from public.clubs where id = p_club_id;

  if v_prefix is null then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return v_prefix || '-' || extract(year from now())::text || '-' ||
    lpad(nextval('public.store_order_number_seq')::text, 6, '0');
end;
$function$;
revoke all on function public.generate_store_order_number(p_club_id uuid) from public;
grant execute on function public.generate_store_order_number(p_club_id uuid) to authenticated;

-- ---- FUNCTION: get_my_membership -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: get_my_membership_for_club ----
CREATE OR REPLACE FUNCTION public.get_my_membership_for_club(p_club_id uuid)
 RETURNS TABLE(id uuid, plan_id text, plan_name text, started_at timestamp with time zone, expires_at timestamp with time zone, is_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs c where c.id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  return query
  select
    m.id,
    m.plan_id,
    m.plan_name,
    m.started_at,
    m.expires_at,
    (m.expires_at > now()) as is_active
  from public.supporter_memberships m
  where m.user_id = auth.uid() and m.club_id = p_club_id
  order by m.created_at desc
  limit 1;
end;
$function$
;
revoke all on function public.get_my_membership_for_club(p_club_id uuid) from public;
grant execute on function public.get_my_membership_for_club(p_club_id uuid) to authenticated;

-- ---- FUNCTION: handle_new_user -- definição real fica lá em cima, junto
-- do trigger on_auth_user_created (é a mesma function, precisa existir
-- antes do trigger ser criado). A introspecção também a captura aqui por
-- ser schema `public` — CREATE OR REPLACE duplicado é idempotente (por
-- isso nunca quebrou nenhum push), mas 2 definições da mesma function no
-- arquivo é ruído; removido, mantendo só a de cima. ----

-- ---- FUNCTION: list_unconfirmed_signups_for_cleanup ----
CREATE OR REPLACE FUNCTION public.list_unconfirmed_signups_for_cleanup()
 RETURNS TABLE(id uuid, email text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
  select id, email
  from auth.users
  where email_confirmed_at is null
    and created_at < now() - interval '48 hours';
$function$
;
revoke all on function public.list_unconfirmed_signups_for_cleanup() from public;
grant execute on function public.list_unconfirmed_signups_for_cleanup() to service_role;

-- ---- FUNCTION: passport_attendance_breakdown ----
CREATE OR REPLACE FUNCTION public.passport_attendance_breakdown(p_user_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(total_attended integer, wins integer, draws integer, losses integer, home_games integer, away_games integer, goals_for integer, goals_against integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    count(*)::int,
    count(*) filter (where m.outcome = 'WIN')::int,
    count(*) filter (where m.outcome = 'DRAW')::int,
    count(*) filter (where m.outcome = 'LOSS')::int,
    count(*) filter (where m.club_is_home)::int,
    count(*) filter (where not m.club_is_home)::int,
    coalesce(sum(m.club_score), 0)::int,
    coalesce(sum(m.opponent_score), 0)::int
  from public.passport_attendances a
  join public.passport_matches m on m.id = a.match_id
  where a.user_id = coalesce(p_user_id, auth.uid())
    and a.attended = true
    and m.status = 'FINISHED';
$function$
;
revoke all on function public.passport_attendance_breakdown(p_user_id uuid) from public;
grant execute on function public.passport_attendance_breakdown(p_user_id uuid) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_attended_matches ----
CREATE OR REPLACE FUNCTION public.passport_attended_matches(p_user_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id text, season integer, match_date date, match_time time without time zone, kickoff_at timestamp with time zone, display_timezone text, date_precision text, status text, competition text, competition_code text, round text, opponent text, club_is_home boolean, neutral_site boolean, home_team text, away_team text, home_score integer, away_score integer, club_score integer, opponent_score integer, score_display text, outcome text, venue_name text, venue_city text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    m.id, m.season, m.match_date, m.match_time, m.kickoff_at,
    m.display_timezone, m.date_precision, m.status, m.competition,
    m.competition_code, m.round, m.opponent, m.club_is_home,
    m.neutral_site, m.home_team, m.away_team, m.home_score,
    m.away_score, m.club_score, m.opponent_score, m.score_display,
    m.outcome, v.display_name, v.city
  from public.passport_matches m
  join public.passport_attendances a on a.match_id = m.id
  left join public.venues v on v.id = m.venue_id
  where a.user_id = coalesce(p_user_id, auth.uid()) and a.attended = true
  order by m.match_date desc, m.kickoff_at desc nulls last;
$function$
;
revoke all on function public.passport_attended_matches(p_user_id uuid) from public;
grant execute on function public.passport_attended_matches(p_user_id uuid) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_matches_for_year ----
CREATE OR REPLACE FUNCTION public.passport_matches_for_year(p_season integer)
 RETURNS TABLE(id text, season integer, match_date date, match_time time without time zone, kickoff_at timestamp with time zone, display_timezone text, date_precision text, status text, competition text, competition_code text, round text, opponent text, club_is_home boolean, neutral_site boolean, home_team text, away_team text, home_score integer, away_score integer, club_score integer, opponent_score integer, score_display text, outcome text, venue_name text, venue_city text, attended boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    m.id, m.season, m.match_date, m.match_time, m.kickoff_at,
    m.display_timezone, m.date_precision, m.status, m.competition,
    m.competition_code, m.round, m.opponent, m.club_is_home,
    m.neutral_site, m.home_team, m.away_team, m.home_score,
    m.away_score, m.club_score, m.opponent_score, m.score_display,
    m.outcome, v.display_name, v.city,
    coalesce(a.attended, false) as attended
  from public.passport_matches m
  left join public.venues v on v.id = m.venue_id
  left join public.passport_attendances a
    on a.match_id = m.id and a.user_id = auth.uid()
  where m.season = p_season
  order by m.match_date asc, m.kickoff_at asc nulls last;
$function$
;
revoke all on function public.passport_matches_for_year(p_season integer) from public;
grant execute on function public.passport_matches_for_year(p_season integer) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_memorable_match_id ----
CREATE OR REPLACE FUNCTION public.passport_memorable_match_id(p_user_id uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select match_id
  from public.passport_memorable_matches
  where user_id = coalesce(p_user_id, auth.uid());
$function$
;
revoke all on function public.passport_memorable_match_id(p_user_id uuid) from public;
grant execute on function public.passport_memorable_match_id(p_user_id uuid) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_my_attendances_for_year ----
CREATE OR REPLACE FUNCTION public.passport_my_attendances_for_year(p_season integer)
 RETURNS TABLE(match_id text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select a.match_id
  from public.passport_attendances a
  join public.passport_matches m on m.id = a.match_id
  where a.user_id = auth.uid() and a.attended = true and m.season = p_season;
$function$
;
revoke all on function public.passport_my_attendances_for_year(p_season integer) from public;
grant execute on function public.passport_my_attendances_for_year(p_season integer) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_my_rank ----
CREATE OR REPLACE FUNCTION public.passport_my_rank(p_year integer DEFAULT NULL::integer)
 RETURNS TABLE(rank integer, match_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with mine as (
    select a.user_id, a.marked_at, m.season
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.attended = true
      and (p_year is null or m.season = p_year)
  ),
  totals as (
    select
      user_id,
      count(*)::int as match_count,
      max(marked_at) as last_marked_at
    from mine
    group by user_id
  ),
  ranked as (
    select
      user_id,
      match_count,
      row_number() over (
        order by match_count desc, last_marked_at asc
      )::int as rank
    from totals
  )
  select r.rank, r.match_count
  from ranked r
  where r.user_id = auth.uid();
$function$
;
revoke all on function public.passport_my_rank(p_year integer) from public;
grant execute on function public.passport_my_rank(p_year integer) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_ranking ----
CREATE OR REPLACE FUNCTION public.passport_ranking(p_year integer DEFAULT NULL::integer, p_limit integer DEFAULT 50)
 RETURNS TABLE(rank integer, user_id uuid, name text, avatar_url text, is_member boolean, match_count integer, last_marked_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with mine as (
    select a.user_id, a.marked_at, m.season
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.attended = true
      and (p_year is null or m.season = p_year)
  ),
  totals as (
    select
      user_id,
      count(*)::int as match_count,
      max(marked_at) as last_marked_at
    from mine
    group by user_id
  )
  select
    row_number() over (
      order by t.match_count desc, t.last_marked_at asc
    )::int as rank,
    t.user_id,
    coalesce(nullif(trim(pr.full_name), ''), 'Torcedor') as name,
    pr.avatar_url,
    -- Mesma limitação já documentada em arena_ranking: status de sócio
    -- ainda é mock/local, sem tabela real no Supabase pra saber se OUTRO
    -- usuário é sócio.
    false as is_member,
    t.match_count,
    t.last_marked_at
  from totals t
  left join public.profiles pr on pr.id = t.user_id
  order by t.match_count desc, t.last_marked_at asc
  limit p_limit;
$function$
;
revoke all on function public.passport_ranking(p_year integer, p_limit integer) from public;
grant execute on function public.passport_ranking(p_year integer, p_limit integer) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_save_attendances ----
CREATE OR REPLACE FUNCTION public.passport_save_attendances(p_changes jsonb)
 RETURNS TABLE(result_match_id text, result_attended boolean, applied boolean, reason text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_match_id text;
  v_attended boolean;
  v_match record;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  for v_item in select * from jsonb_array_elements(p_changes)
  loop
    v_match_id := v_item ->> 'matchId';
    v_attended := (v_item ->> 'attended')::boolean;

    select * into v_match
    from public.passport_matches
    where id = v_match_id;

    if v_match.id is null then
      result_match_id := v_match_id;
      result_attended := v_attended;
      applied := false;
      reason := 'not_found';
      return next;
      continue;
    end if;

    if v_match.status <> 'FINISHED' then
      result_match_id := v_match_id;
      result_attended := v_attended;
      applied := false;
      reason := 'not_finished';
      return next;
      continue;
    end if;

    if v_match.match_date > current_date then
      result_match_id := v_match_id;
      result_attended := v_attended;
      applied := false;
      reason := 'future_match';
      return next;
      continue;
    end if;

    insert into public.passport_attendances as pa (
      user_id, match_id, attended, marked_at, updated_at, source
    )
    values (v_uid, v_match_id, v_attended, now(), now(), 'self_declared')
    on conflict (user_id, match_id) do update set
      attended = v_attended,
      updated_at = now();

    if not v_attended then
      delete from public.passport_memorable_matches
      where user_id = v_uid and match_id = v_match_id;
    end if;

    result_match_id := v_match_id;
    result_attended := v_attended;
    applied := true;
    reason := null;
    return next;
  end loop;
end;
$function$
;
revoke all on function public.passport_save_attendances(p_changes jsonb) from public;
grant execute on function public.passport_save_attendances(p_changes jsonb) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_seasons ----
CREATE OR REPLACE FUNCTION public.passport_seasons()
 RETURNS TABLE(season integer, match_count integer, finished_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    m.season,
    count(*)::int as match_count,
    count(*) filter (where m.status = 'FINISHED')::int as finished_count
  from public.passport_matches m
  group by m.season
  order by m.season desc;
$function$
;
revoke all on function public.passport_seasons() from public;
grant execute on function public.passport_seasons() to anon, authenticated, service_role;

-- ---- FUNCTION: passport_set_memorable_match ----
CREATE OR REPLACE FUNCTION public.passport_set_memorable_match(p_match_id text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_attended boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select attended into v_attended
  from public.passport_attendances
  where user_id = v_uid and match_id = p_match_id;

  if v_attended is not true then
    raise exception 'match_not_attended';
  end if;

  insert into public.passport_memorable_matches (user_id, match_id, selected_at)
  values (v_uid, p_match_id, now())
  on conflict (user_id) do update set
    match_id = excluded.match_id,
    selected_at = now();
end;
$function$
;
revoke all on function public.passport_set_memorable_match(p_match_id text) from public;
grant execute on function public.passport_set_memorable_match(p_match_id text) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_stadium_summary ----
CREATE OR REPLACE FUNCTION public.passport_stadium_summary(p_user_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(unique_stadiums integer, most_visited_stadium_name text, most_visited_stadium_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with mine as (
    select m.venue_id, m.match_date
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.user_id = coalesce(p_user_id, auth.uid()) and a.attended = true and m.status = 'FINISHED'
  ),
  by_venue as (
    select
      v.id as venue_id,
      v.display_name,
      count(*)::int as visit_count,
      max(mine.match_date) as last_visit
    from mine
    join public.venues v on v.id = mine.venue_id
    group by v.id, v.display_name
  )
  select
    (select count(distinct venue_id) from mine where venue_id is not null)::int,
    (select display_name from by_venue order by visit_count desc, last_visit desc limit 1),
    (select visit_count from by_venue order by visit_count desc, last_visit desc limit 1);
$function$
;
revoke all on function public.passport_stadium_summary(p_user_id uuid) from public;
grant execute on function public.passport_stadium_summary(p_user_id uuid) to anon, authenticated, service_role;

-- ---- FUNCTION: passport_summary ----
CREATE OR REPLACE FUNCTION public.passport_summary(p_user_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(total_matches integer, years_with_attendance integer, first_marked_match_id text, first_marked_match_date date, last_marked_match_id text, last_marked_match_date date)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with mine as (
    select a.match_id, m.match_date, m.season
    from public.passport_attendances a
    join public.passport_matches m on m.id = a.match_id
    where a.user_id = coalesce(p_user_id, auth.uid()) and a.attended = true
  )
  select
    (select count(*) from mine)::int,
    (select count(distinct season) from mine)::int,
    (select match_id from mine order by match_date asc limit 1),
    (select match_date from mine order by match_date asc limit 1),
    (select match_id from mine order by match_date desc limit 1),
    (select match_date from mine order by match_date desc limit 1);
$function$
;
revoke all on function public.passport_summary(p_user_id uuid) from public;
grant execute on function public.passport_summary(p_user_id uuid) to anon, authenticated, service_role;

-- ---- FUNCTION: rls_auto_enable ----
CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;
revoke all on function public.rls_auto_enable() from public;
grant execute on function public.rls_auto_enable() to anon, authenticated, service_role;

-- ---- FUNCTION: subscribe_to_plan -- EXCLUÍDA (ver cabeçalho/relatório) ----

-- ---- FUNCTION: subscribe_to_plan_for_club ----
-- REESCRITA nesta rodada de correção -- mesma lógica operacional do
-- original (advisory lock, bloqueio de assinatura duplicada, insert em
-- supporter_memberships), mas nome/duração do plano vêm de um SELECT em
-- membership_plans -- zero plano editorial no corpo. Código NOVO (não
-- introspecção), precisa de revisão extra antes de qualquer aplicação
-- real (nunca testado contra Postgres de verdade nesta rodada).
CREATE OR REPLACE FUNCTION public.subscribe_to_plan_for_club(p_club_id uuid, p_plan_id text)
 RETURNS TABLE(id uuid, plan_id text, plan_name text, started_at timestamp with time zone, expires_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_plan record;
  v_active_count int;
  v_started_at timestamptz;
  v_expires_at timestamptz;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs c where c.id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  select mp.name, mp.duration_days into v_plan
  from public.membership_plans mp
  where mp.club_id = p_club_id and mp.plan_key = p_plan_id and mp.is_active;

  if v_plan is null then
    raise exception 'invalid plan_id %', p_plan_id;
  end if;

  perform pg_advisory_xact_lock(
    hashtext('subscribe_to_plan_for_club:' || v_uid::text || ':' || p_club_id::text)
  );

  select count(*) into v_active_count
  from public.supporter_memberships
  where supporter_memberships.user_id = v_uid
    and supporter_memberships.club_id = p_club_id
    and supporter_memberships.expires_at > now();

  if v_active_count > 0 then
    raise exception 'membership already active';
  end if;

  v_started_at := now();
  v_expires_at := v_started_at + (v_plan.duration_days || ' days')::interval;

  insert into public.supporter_memberships (
    user_id, club_id, plan_id, plan_name, started_at, expires_at
  )
  values (
    v_uid, p_club_id, p_plan_id, v_plan.name, v_started_at, v_expires_at
  )
  returning supporter_memberships.id into v_id;

  return query
  select v_id, p_plan_id, v_plan.name, v_started_at, v_expires_at;
end;
$function$;
revoke all on function public.subscribe_to_plan_for_club(p_club_id uuid, p_plan_id text) from public;
grant execute on function public.subscribe_to_plan_for_club(p_club_id uuid, p_plan_id text) to authenticated;

-- ---- FUNCTION: upsert_membership_checkin_ticket_for_club ----
CREATE OR REPLACE FUNCTION public.upsert_membership_checkin_ticket_for_club(p_club_id uuid, p_match_id text, p_competition text, p_round text, p_home_team_id integer, p_home_team_name text, p_away_team_id integer, p_away_team_name text, p_kickoff timestamp with time zone, p_stadium text, p_sector_id text, p_sector_name text, p_venue_label text, p_gate text, p_holder_name text, p_holder_document text)
 RETURNS tickets
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public', 'pg_temp'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_row public.tickets;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  insert into public.tickets (
    user_id, club_id, match_id, competition, round,
    home_team_id, home_team_name, away_team_id, away_team_name,
    kickoff, stadium, sector_id, sector_name, venue_label, gate,
    category_label, holder_name, holder_document, status, origin,
    order_id, price
  )
  values (
    v_uid, p_club_id, p_match_id, p_competition, p_round,
    p_home_team_id, p_home_team_name, p_away_team_id, p_away_team_name,
    p_kickoff, p_stadium, p_sector_id, p_sector_name, p_venue_label, p_gate,
    null, p_holder_name, p_holder_document, 'active', 'membership_check_in',
    null, null
  )
  on conflict (club_id, user_id, match_id) where origin = 'membership_check_in'
  do update set
    competition = excluded.competition,
    round = excluded.round,
    home_team_id = excluded.home_team_id,
    home_team_name = excluded.home_team_name,
    away_team_id = excluded.away_team_id,
    away_team_name = excluded.away_team_name,
    kickoff = excluded.kickoff,
    stadium = excluded.stadium,
    sector_id = excluded.sector_id,
    sector_name = excluded.sector_name,
    venue_label = excluded.venue_label,
    gate = excluded.gate,
    holder_name = excluded.holder_name,
    holder_document = excluded.holder_document,
    status = 'active'
  returning * into v_row;

  return v_row;
end;
$function$
;
revoke all on function public.upsert_membership_checkin_ticket_for_club(p_club_id uuid, p_match_id text, p_competition text, p_round text, p_home_team_id integer, p_home_team_name text, p_away_team_id integer, p_away_team_name text, p_kickoff timestamp with time zone, p_stadium text, p_sector_id text, p_sector_name text, p_venue_label text, p_gate text, p_holder_name text, p_holder_document text) from public;
grant execute on function public.upsert_membership_checkin_ticket_for_club(p_club_id uuid, p_match_id text, p_competition text, p_round text, p_home_team_id integer, p_home_team_name text, p_away_team_id integer, p_away_team_name text, p_kickoff timestamp with time zone, p_stadium text, p_sector_id text, p_sector_name text, p_venue_label text, p_gate text, p_holder_name text, p_holder_document text) to authenticated;

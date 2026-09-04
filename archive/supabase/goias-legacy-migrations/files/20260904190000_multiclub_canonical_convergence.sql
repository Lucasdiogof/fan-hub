-- Convergência do schema do Goiás para o schema canônico Fan Hub
-- (infra/supabase/canonical/supabase/migrations/20260904000000_canonical_baseline.sql).
--
-- Autorização explícita do usuário em 2026-09-04: "ninguém está usando o
-- app... podemos alterar schema, RPCs, colunas e contratos do Goiás para
-- chegar na melhor arquitetura final." Confirmado por dado real: store_orders,
-- store_order_items e supporter_memberships estão todas com 0 linhas no
-- Goiás ao vivo neste momento — nada a preservar nessas 3 tabelas. Existem
-- 17 usuários reais em auth.users, não tocados por esta migration.
--
-- Fontes: introspecção ao vivo do próprio Goiás (yonozsdgyrhgqrvydbnr),
-- feita antes de escrever este arquivo. Nenhuma suposição sobre estado —
-- toda função/coluna/valor abaixo foi confirmada existir/ter esse valor
-- antes de ser referenciada.

-- ============================================================================
-- 1) RENAMES goias_* -> club_* (passport_matches, guess_players)
-- ============================================================================
-- Únicas 3 functions que de fato referenciam essas colunas no Goiás ao vivo
-- (confirmado via prosrc ilike '%goias%' — passport_summary/passport_seasons/
-- passport_my_attendances_for_year NÃO referenciam, apesar do canonical
-- baseline tê-las tocado por precaução; aqui só mexemos no que existe de
-- verdade). Nenhum index/constraint tem "goias" no nome (confirmado).

alter table public.passport_matches rename column goias_is_home to club_is_home;
alter table public.passport_matches rename column goias_score to club_score;
alter table public.guess_players rename column goias_debut_year to club_debut_year;

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
$function$;
revoke all on function public.passport_attendance_breakdown(p_user_id uuid) from public;
grant execute on function public.passport_attendance_breakdown(p_user_id uuid) to anon, authenticated, service_role;

-- passport_attended_matches/passport_matches_for_year mudam NOME de coluna
-- de saída (goias_is_home/goias_score -> club_is_home/club_score) -- Postgres
-- não permite CREATE OR REPLACE mudar nomes de OUT parameters (SQLSTATE
-- 42P13, erro real batido no primeiro push, migration inteira revertida
-- limpo por ser transacional -- confirmado: nada ficou parcialmente
-- aplicado). Precisa DROP + CREATE explícito pras 2. Isso também apaga
-- qualquer GRANT anterior (a function é um objeto novo depois do DROP) --
-- por isso o REVOKE/GRANT explícito logo depois, endurecendo a ACL solta
-- que existia antes (pub=true) pro mesmo padrão do resto do projeto.
drop function public.passport_attended_matches(uuid);

CREATE FUNCTION public.passport_attended_matches(p_user_id uuid DEFAULT NULL::uuid)
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
$function$;
revoke all on function public.passport_attended_matches(p_user_id uuid) from public;
grant execute on function public.passport_attended_matches(p_user_id uuid) to anon, authenticated, service_role;

drop function public.passport_matches_for_year(integer);

CREATE FUNCTION public.passport_matches_for_year(p_season integer)
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
$function$;
revoke all on function public.passport_matches_for_year(p_season integer) from public;
grant execute on function public.passport_matches_for_year(p_season integer) to anon, authenticated, service_role;

-- ============================================================================
-- 2) clubs.order_prefix (SCHEMA CAPABILITY genérica, igual ao canonical)
-- ============================================================================
alter table public.clubs add column order_prefix text;
update public.clubs set order_prefix = 'GOI' where slug = 'goias';

-- ============================================================================
-- 3) STORE — genericizar generate_store_order_number, remover 'GOI-' hardcoded
-- ============================================================================
-- store_orders/store_order_items estão com 0 linhas ao vivo agora — não há
-- pedido existente pra preservar. Ainda assim a troca é feita sem truncar
-- nada (só DDL/DROP DEFAULT + CREATE OR REPLACE), pelo mesmo motivo que se
-- aplicaria se houvesse dado: nunca truncar por conveniência.

alter table public.store_orders alter column order_number drop default;
drop function public.generate_store_order_number();

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

CREATE OR REPLACE FUNCTION public.create_store_order_for_club(p_club_id uuid, p_status text, p_fulfillment_method text, p_customer jsonb, p_address jsonb, p_shipping_option jsonb, p_pickup_responsible jsonb, p_payment jsonb, p_subtotal numeric, p_discount_amount numeric, p_shipping_cost numeric, p_coupon_code text, p_items jsonb)
 RETURNS store_orders
 LANGUAGE plpgsql
AS $function$
declare
  v_order public.store_orders;
  v_order_number text;
  v_item jsonb;
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

-- ============================================================================
-- 4) MEMBERSHIP — membership_plans data-driven, remover catálogo hardcoded
-- ============================================================================
-- 6 planos reais extraídos do CASE hardcoded de subscribe_to_plan_for_club
-- (todos com duration_days=30, é o valor fixo que a function legacy usava
-- pra todos os planos sem distinção -- comportamento preservado, não
-- inventado).

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
alter table public.membership_plans add constraint membership_plans_club_id_fkey FOREIGN KEY (club_id) REFERENCES clubs(id);
alter table public.membership_plans enable row level security;
create policy "read membership plans" on public.membership_plans for SELECT to public using (true);
grant SELECT on public.membership_plans to anon;
grant SELECT on public.membership_plans to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.membership_plans to service_role;

insert into public.membership_plans (club_id, plan_key, name, duration_days, sort_order)
select id, v.plan_key, v.name, 30, v.sort_order
from public.clubs, (values
  ('nossa-gente', 'NOSSA GENTE', 1),
  ('nossa-historia', 'NOSSA HISTORIA', 2),
  ('nossa-garra', 'NOSSA GARRA', 3),
  ('nossa-gloria', 'NOSSA GLORIA', 4),
  ('nossa-familia', 'NOSSA FAMILIA', 5),
  ('plano-vip', 'PLANO VIP', 6)
) as v(plan_key, name, sort_order)
where clubs.slug = 'goias';

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

  perform pg_advisory_xact_lock(
    hashtext('subscribe_to_plan_for_club:' || v_uid::text || ':' || p_club_id::text)
  );

  select mp.name, mp.duration_days into v_plan
  from public.membership_plans mp
  where mp.club_id = p_club_id and mp.plan_key = p_plan_id and mp.is_active;

  if v_plan is null then
    raise exception 'invalid plan_id %', p_plan_id;
  end if;

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

-- ============================================================================
-- 5) Legado a remover — 8 functions vestigiais, já com 0 grant de EXECUTE ao
--    vivo (confirmado antes desta migration), nunca existiram no canonical
--    baseline. Removidas pra SCHEMA_DIFF=0 real contra o Bragantino.
-- ============================================================================
drop function public.arena_my_rank(p_period text);
drop function public.arena_ranking(p_period text, p_limit integer);
drop function public.arena_record_score(p_game_id text, p_item_id text, p_event_type text, p_attempt_number integer, p_difficulty text, p_wrong_count integer, p_found_count integer, p_total_count integer, p_was_revealed boolean, p_was_abandoned boolean);
drop function public.arena_user_detail(p_user_id uuid);
drop function public.create_store_order(p_status text, p_fulfillment_method text, p_customer jsonb, p_address jsonb, p_shipping_option jsonb, p_pickup_responsible jsonb, p_payment jsonb, p_subtotal numeric, p_discount_amount numeric, p_shipping_cost numeric, p_coupon_code text, p_items jsonb);
drop function public.crowd_lineup(p_match_id text);
drop function public.get_my_membership();
drop function public.subscribe_to_plan(p_plan_id text);

-- Corrige "column reference \"id\" is ambiguous" (SQLSTATE 42702) em
-- public.get_my_membership_for_club e public.subscribe_to_plan_for_club.
--
-- Ambas usam RETURNS TABLE(id uuid, ...), o que faz o plpgsql declarar uma
-- variável OUT chamada `id`. O guard de validação do clube
-- (`where id = p_club_id`) referenciava esse `id` sem qualificar, e como
-- plpgsql.variable_conflict é 'error' por padrão, a chamada estoura em
-- runtime toda vez -- get_my_membership_for_club quebra no load da tela de
-- Sócio (mesmo sem tentar contratar) e subscribe_to_plan_for_club quebra na
-- contratação em si. As outras 7 RPCs `_for_club` foram auditadas ao vivo
-- (pg_get_functiondef) e não têm coluna `id` no RETURNS TABLE(...) nem em
-- OUT -- não sofrem desta ambiguidade, não foram tocadas.
--
-- Corpo obtido via pg_get_functiondef ao vivo antes desta migration.
-- Única mudança: qualificar a referência ambígua como `c.id` (alias novo
-- em `from public.clubs c`). Nada mais no corpo, na assinatura, nos tipos,
-- nos defaults, em SECURITY DEFINER/INVOKER, em search_path ou na
-- semântica muda.

create or replace function public.get_my_membership_for_club(p_club_id uuid)
returns table(
  id uuid,
  plan_id text,
  plan_name text,
  started_at timestamp with time zone,
  expires_at timestamp with time zone,
  is_active boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $function$
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
$function$;

revoke all on function public.get_my_membership_for_club(uuid)
  from public, anon, service_role;

grant execute on function public.get_my_membership_for_club(uuid)
  to authenticated;

create or replace function public.subscribe_to_plan_for_club(p_club_id uuid, p_plan_id text)
returns table(
  id uuid,
  plan_id text,
  plan_name text,
  started_at timestamp with time zone,
  expires_at timestamp with time zone
)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $function$
declare
  v_uid uuid := auth.uid();
  v_plan_name text;
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

  -- Mesmo catálogo hardcoded da RPC legacy (ver comentário lá) -- se um
  -- plano for adicionado/renomeado, precisa espelhar aqui também.
  v_plan_name := case p_plan_id
    when 'nossa-gente' then 'NOSSA GENTE'
    when 'nossa-historia' then 'NOSSA HISTORIA'
    when 'nossa-garra' then 'NOSSA GARRA'
    when 'nossa-gloria' then 'NOSSA GLORIA'
    when 'nossa-familia' then 'NOSSA FAMILIA'
    when 'plano-vip' then 'PLANO VIP'
    else null
  end;

  if v_plan_name is null then
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
  v_expires_at := v_started_at + interval '30 days';

  insert into public.supporter_memberships (
    user_id, club_id, plan_id, plan_name, started_at, expires_at
  )
  values (
    v_uid, p_club_id, p_plan_id, v_plan_name, v_started_at, v_expires_at
  )
  returning supporter_memberships.id into v_id;

  return query
  select v_id, p_plan_id, v_plan_name, v_started_at, v_expires_at;
end;
$function$;

revoke all on function public.subscribe_to_plan_for_club(uuid, text)
  from public, anon, service_role;

grant execute on function public.subscribe_to_plan_for_club(uuid, text)
  to authenticated;

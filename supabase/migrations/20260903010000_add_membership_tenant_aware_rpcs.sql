-- ============================================================================
-- M3.2 — RPCs tenant-aware ADITIVAS pra Sócio Torcedor. NUNCA substitui
-- get_my_membership/subscribe_to_plan — essas continuam byte-idênticas,
-- servindo só o app já publicado.
--
-- Achado CRÍTICO carregado desde a M1: get_my_membership() faz
-- `order by created_at desc limit 1` SEM filtro de clube — numa base
-- multi-clube real vazaria a assinatura mais recente de QUALQUER clube.
-- get_my_membership_for_club fecha isso filtrando também por
-- `club_id = p_club_id`, nunca só pelo mais recente.
--
-- subscribe_to_plan_for_club espelha a mesma trava de concorrência
-- (pg_advisory_xact_lock) e a mesma regra de "não permite 2 assinaturas
-- ativas simultâneas" — mas agora escopada por (user_id, club_id): um
-- usuário pode ter uma assinatura ativa no clube A e outra no clube B ao
-- mesmo tempo (mesmo padrão já adotado em user_notification_preferences —
-- "clubA jogos ON, clubB jogos OFF" é válido).
-- ============================================================================

create or replace function public.get_my_membership_for_club(p_club_id uuid)
returns table (
  id uuid,
  plan_id text,
  plan_name text,
  started_at timestamptz,
  expires_at timestamptz,
  is_active boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
begin
  if p_club_id is null then
    raise exception 'p_club_id is required';
  end if;
  if not exists (select 1 from public.clubs where id = p_club_id) then
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
$$;

-- Hardening (rodada de revisão): revoga PUBLIC explícito antes de conceder
-- — nunca herdar o EXECUTE-pra-PUBLIC padrão do CREATE FUNCTION (mesma
-- dívida real confirmada nas 8 legacy, ver LEGACY_RPC_PUBLIC_EXECUTE_DEBT
-- no relatório). Ler o próprio status de sócio não faz sentido sem sessão
-- — nunca `anon`; nenhum caller server-side — nunca `service_role`.
revoke all on function public.get_my_membership_for_club(uuid) from public;
grant execute on function public.get_my_membership_for_club(uuid)
  to authenticated;

create or replace function public.subscribe_to_plan_for_club(
  p_club_id uuid,
  p_plan_id text
)
returns table (
  id uuid,
  plan_id text,
  plan_name text,
  started_at timestamptz,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
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
  if not exists (select 1 from public.clubs where id = p_club_id) then
    raise exception 'unknown club_id %', p_club_id;
  end if;

  perform pg_advisory_xact_lock(
    hashtext('subscribe_to_plan_for_club:' || v_uid::text || ':' || p_club_id::text)
  );

  -- Mesmo catálogo hardcoded da RPC legacy (ver comentário lá) — se um
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
$$;

revoke all on function public.subscribe_to_plan_for_club(uuid, text)
  from public;
grant execute on function public.subscribe_to_plan_for_club(uuid, text)
  to authenticated;

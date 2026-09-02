-- ============================================================================
-- M3.2 — RPC tenant-aware ADITIVA pra Escalação da Torcida. NUNCA substitui
-- crowd_lineup(p_match_id) — essa continua byte-idêntica, servindo só o app
-- já publicado.
--
-- Mesma lógica de agregação da legacy (contagem de formação + jogador por
-- slot), só que a CTE base `v` agora também filtra por club_id — sem isso,
-- dois clubes votando na "mesma" partida (mesmo match_id, ids de partida
-- ainda não namespaced globalmente) misturariam votos.
-- ============================================================================

create or replace function public.crowd_lineup_for_club(
  p_club_id uuid,
  p_match_id text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
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
$$;

-- Achado real (revisão de segurança): a tela "Escalação da Torcida" está
-- 100% atrás do redirect global de login (`app_router.dart`, rota
-- `/crowd-lineup` não está em `_publicRoutes`) — hoje NENHUM caller
-- anônimo alcança esta RPC de verdade, mesmo a legacy `crowd_lineup`
-- concedendo `anon` explicitamente. A variante nova nasce só com o
-- privilégio que o app REALMENTE usa hoje — revisitar se um uso público
-- real (embed/web) for decidido no futuro.
revoke all on function public.crowd_lineup_for_club(uuid, text) from public;
grant execute on function public.crowd_lineup_for_club(uuid, text)
  to authenticated;

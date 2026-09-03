-- ============================================================================
-- M3.4 — RPC tenant-aware pro check-in de sócio (ingresso gratuito).
-- NÃO aplicada ainda (arquivo local, aguardando revisão).
--
-- Existe porque o índice único do check-in é PARCIAL
-- (club_id, user_id, match_id) WHERE origin='membership_check_in' — e o
-- `onConflict:` do PostgREST só expressa colunas, nunca o predicate. Então o
-- upsert tenant-aware do ticket de sócio precisa de SQL explícito com
-- `ON CONFLICT (...) WHERE origin='membership_check_in'`.
--
-- Regras:
--  * usuário SEMPRE de auth.uid() no servidor (nunca aceita p_user_id);
--  * valida p_club_id (não nulo e existente em clubs);
--  * cria/atualiza SOMENTE ticket origin='membership_check_in' — nunca toca
--    tickets origin='purchase' (a compra tem fluxo próprio de pedido);
--  * SECURITY INVOKER (roda como o chamador, igual create_store_order): a RLS
--    OWNER de `tickets` (auth.uid()=user_id) já autoriza o próprio usuário —
--    não precisa de privilégio elevado;
--  * search_path seguro, relações schema-qualified;
--  * preserva o comportamento funcional do upsert antigo (mesmos campos).
-- ============================================================================

create or replace function public.upsert_membership_checkin_ticket_for_club(
  p_club_id uuid,
  p_match_id text,
  p_competition text,
  p_round text,
  p_home_team_id int,
  p_home_team_name text,
  p_away_team_id int,
  p_away_team_name text,
  p_kickoff timestamptz,
  p_stadium text,
  p_sector_id text,
  p_sector_name text,
  p_venue_label text,
  p_gate text,
  p_holder_name text,
  p_holder_document text
)
returns public.tickets
language plpgsql
set search_path = pg_catalog, public, pg_temp
as $$
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
$$;

-- ACL (regra permanente M3.2) — nova função recebe grants default via
-- pg_default_acl (anon/authenticated/service_role); revoga tudo e concede só
-- authenticated, explicitamente, na mesma migration.
revoke execute on function public.upsert_membership_checkin_ticket_for_club(uuid, text, text, text, int, text, int, text, timestamptz, text, text, text, text, text, text, text) from public;
revoke execute on function public.upsert_membership_checkin_ticket_for_club(uuid, text, text, text, int, text, int, text, timestamptz, text, text, text, text, text, text, text) from anon;
revoke execute on function public.upsert_membership_checkin_ticket_for_club(uuid, text, text, text, int, text, int, text, timestamptz, text, text, text, text, text, text, text) from service_role;
grant execute on function public.upsert_membership_checkin_ticket_for_club(uuid, text, text, text, int, text, int, text, timestamptz, text, text, text, text, text, text, text) to authenticated;

-- ============================================================================
-- M2.2B-A — Additive tenant-aware BRIDGE keys (CROWD LINEUP / TICKETS).
-- NÃO aplicada ainda (arquivo local, aguardando revisão). 0 db push.
--
-- Só ADITIVO. match_lineup_votes: UNIQUE(match_id, user_id) legada continua;
-- bridge (club_id, match_id, user_id) ao lado. ticket_checkin_decisions:
-- PK(user_id, match_id) legada continua; bridge (club_id, user_id, match_id).
-- tickets: índice parcial legado (user_id, match_id) WHERE check-in continua;
-- bridge (club_id, user_id, match_id) com o MESMO predicado parcial.
--
-- Todos os três têm onConflict no app apontando pra chave legada
-- ('match_id,user_id' e 'user_id,match_id') — por isso o drop da legada é
-- REQUIRES_NEW_APP + REQUIRES_OLD_APP_RETIREMENT (M2.2B-B, só depois do M3.4).
--
-- Backward-compatible / validado ao vivo (0 colisão). Tabelas minúsculas
-- (match_lineup_votes=3, ticket_checkin_decisions=1, tickets=0).
-- ============================================================================

do $$
begin
  if (select count(*) from public.clubs) <> 1 then
    raise exception 'M2.2B-A abortado: esperava exatamente 1 clube, achou %', (select count(*) from public.clubs);
  end if;
  if not exists (select 1 from public.clubs where id = '4c16340d-300c-5ab2-903f-17519db9b146') then
    raise exception 'M2.2B-A abortado: clube Goiás canônico ausente';
  end if;
end $$;

create unique index mlv_club_match_user_uidx
  on public.match_lineup_votes (club_id, match_id, user_id);

create unique index tcd_club_user_match_uidx
  on public.ticket_checkin_decisions (club_id, user_id, match_id);

-- tickets: bridge PARCIAL, e é parcial de propósito — um usuário pode ter
-- outros tickets origin='purchase' pra a mesma partida; o UNIQUE só vale pro
-- check-in de sócio. IMPORTANTE (M3.4): um índice único PARCIAL NÃO é
-- inferível pelo `onConflict:` do PostgREST/Supabase Flutter, que só expressa
-- COLUNAS, nunca o predicate. Trocar o Flutter pra onConflict:
-- 'club_id,user_id,match_id' seria INSUFICIENTE. Por isso tickets é
-- REQUIRES_RPC_UPDATE: em M3.4 o check-in de sócio precisa de uma RPC
-- tenant-aware própria com `on conflict (club_id, user_id, match_id) where
-- origin = 'membership_check_in'` e identidade via auth.uid() (não gerada
-- agora). Essa RPC futura obedece a regra M3.2: REVOKE de PUBLIC/anon/
-- service_role, GRANT authenticated, search_path seguro, relations
-- schema-qualified, has_function_privilege pós-push.
create unique index tickets_club_user_match_checkin_uidx
  on public.tickets (club_id, user_id, match_id) where origin = 'membership_check_in';

-- NOTA: store_orders.UNIQUE(order_number) e ticket_orders (PK uuid) NÃO
-- entram — order_number é KEEP_GLOBAL (sequência global; GOI- é só branding,
-- vira ClubConfig em M4) e ticket_orders tem PK uuid própria (só ROW_SCOPE).

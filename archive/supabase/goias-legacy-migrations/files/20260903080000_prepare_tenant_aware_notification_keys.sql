-- ============================================================================
-- M2.2B-A — Additive tenant-aware BRIDGE keys (NOTIFICATIONS / MONITOR / PREFS).
-- NÃO aplicada ainda (arquivo local, aguardando revisão). 0 db push.
--
-- Só ADITIVO.
--  notification_events: UNIQUE(event_type, dedupe_key) legada continua;
--    bridge (club_id, event_type, dedupe_key). M3.3 já embutiu o código do
--    clube na STRING dedupe_key como ponte lógica; este bridge dá a chave
--    FÍSICA. Escrito por Edge Functions (service_role) — o drop da legada é
--    REQUIRES_EDGE_UPDATE (as 3 functions M3.3 já estão no ar; um update
--    futuro reponta o ON CONFLICT). notification_deliveries NÃO muda
--    (FK event_id aponta pra PK(id) uuid, herda tenancy).
--  match_monitor_sessions: PK(match_id) legada continua; bridge
--    (club_id, match_id). Escrito por Edge (service_role).
--  user_notification_preferences: PK(user_id) legada continua; bridge
--    (user_id, club_id). onConflict do app = 'user_id' → drop é
--    REQUIRES_NEW_APP. Estado esperado: ROW_SCOPE_READY, KEY_SCOPE_NOT_YET.
--
-- Backward-compatible / validado ao vivo (0 colisão; notification_events=0,
-- match_monitor_sessions=1, user_notification_preferences=0 linhas).
--
-- user_notification_tokens NÃO entra — fcm_token é KEEP_GLOBAL (device),
-- nunca ganha club_id.
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

create unique index ne_club_event_dedupe_uidx
  on public.notification_events (club_id, event_type, dedupe_key);

create unique index mms_club_match_uidx
  on public.match_monitor_sessions (club_id, match_id);

create unique index unp_user_club_uidx
  on public.user_notification_preferences (user_id, club_id);

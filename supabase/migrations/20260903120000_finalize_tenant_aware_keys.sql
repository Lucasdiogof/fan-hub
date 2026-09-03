-- ============================================================================
-- M2.2B-B round 1 — Finalize tenant-aware keys (KEY_SCOPE_FINAL).
-- NÃO aplicada ainda (arquivo local, aguardando revisão).
--
-- Objetivo: as 18 bridges tenant-aware da M2.2B-A (aditivas, coexistindo
-- com as chaves legacy desde então) SUBSTITUEM as chaves legacy — cada uma
-- promovida a chave física real, a legada removida. 0 DROP CASCADE, 0
-- TRUNCATE, 0 DML (nenhum INSERT/UPDATE/DELETE) — só DDL estrutural.
--
-- Efeito colateral documentado: `ADD CONSTRAINT ... PRIMARY KEY USING
-- INDEX <bridge>` RENOMEIA o índice bridge pro nome da constraint (ex.:
-- `aa_club_user_achievement_uidx` vira `arena_achievements_pkey`) —
-- comportamento padrão do Postgres, não um bug. Reflita isso em qualquer
-- tooling que procure pelo nome antigo da bridge depois desta migration
-- aplicar.
--
-- Guard: só executa se `clubs` tiver exatamente 1 linha e for Goiás —
-- nunca aplicar contra um banco que já tenha um 2º clube real (M4 segue
-- bloqueada; se isso disparar, é sinal de que algo mudou sem uma etapa
-- própria — abortar e investigar, nunca ajustar o guard pra passar).
-- ============================================================================

do $$
begin
  if (select count(*) from public.clubs) <> 1
     or not exists (
       select 1 from public.clubs
       where id = '4c16340d-300c-5ab2-903f-17519db9b146'::uuid and slug = 'goias'
     ) then
    raise exception 'M2.2B-B guard: esperava clubs=1 (Goiás) — abortando';
  end if;
end $$;

-- --- 1. Promoção de PK legada -> bridge tenant-aware (12 tabelas) ----------
-- Cada UNIQUE bridge já existe e está válida (M2.2B-A, indisvalid=indisready
-- =indisunique=true, reconfirmado ao vivo nesta rodada) — a promoção não
-- reconstrói índice nenhum, só troca qual constraint "possui" o índice.

alter table public.arena_achievements drop constraint arena_achievements_pkey;
alter table public.arena_achievements add constraint arena_achievements_pkey primary key using index aa_club_user_achievement_uidx;

alter table public.arena_selected_content drop constraint arena_selected_content_pkey;
alter table public.arena_selected_content add constraint arena_selected_content_pkey primary key using index asc_club_user_game_uidx;

alter table public.career_path_progress drop constraint career_path_progress_pkey;
alter table public.career_path_progress add constraint career_path_progress_pkey primary key using index cpp_club_user_player_uidx;

alter table public.lineup_match_progress drop constraint lineup_match_progress_pkey;
alter table public.lineup_match_progress add constraint lineup_match_progress_pkey primary key using index lmp_club_user_match_uidx;

alter table public.player_identity_results drop constraint player_identity_results_pkey;
alter table public.player_identity_results add constraint player_identity_results_pkey primary key using index pir_user_club_uidx;

alter table public.quiz_active_session drop constraint quiz_active_session_pkey;
alter table public.quiz_active_session add constraint quiz_active_session_pkey primary key using index qas_club_user_difficulty_uidx;

alter table public.quiz_question_progress drop constraint quiz_question_progress_pkey;
alter table public.quiz_question_progress add constraint quiz_question_progress_pkey primary key using index qqp_club_user_question_uidx;

alter table public.tactical_identity_results drop constraint tactical_identity_results_pkey;
alter table public.tactical_identity_results add constraint tactical_identity_results_pkey primary key using index tir_user_club_uidx;

alter table public.ticket_checkin_decisions drop constraint ticket_checkin_decisions_pkey;
alter table public.ticket_checkin_decisions add constraint ticket_checkin_decisions_pkey primary key using index tcd_club_user_match_uidx;

alter table public.user_game_item_progress drop constraint user_game_item_progress_pkey;
alter table public.user_game_item_progress add constraint user_game_item_progress_pkey primary key using index ugip_club_user_game_item_uidx;

alter table public.user_notification_preferences drop constraint user_notification_preferences_pkey;
alter table public.user_notification_preferences add constraint user_notification_preferences_pkey primary key using index unp_user_club_uidx;

alter table public.match_monitor_sessions drop constraint match_monitor_sessions_pkey;
alter table public.match_monitor_sessions add constraint match_monitor_sessions_pkey primary key using index mms_club_match_uidx;

-- --- 2. DROP de UNIQUE legada — PK surrogate (id) intacta (5 tabelas) ------

alter table public.match_lineup_votes drop constraint match_lineup_votes_match_id_user_id_key;
alter table public.career_players drop constraint career_players_person_id_key;
alter table public.guess_players drop constraint guess_players_person_id_key;
alter table public.squad_members drop constraint squad_members_person_id_key;
alter table public.notification_events drop constraint notification_events_event_type_dedupe_key_key;

-- --- 3. DROP de índice parcial legado (1 tabela) ---------------------------
-- `tickets_user_match_checkin_uidx` é um índice (não uma constraint) —
-- criado direto via CREATE UNIQUE INDEX, por isso DROP INDEX, não ADD/DROP
-- CONSTRAINT. A semântica parcial (WHERE origin='membership_check_in') fica
-- preservada na bridge `tickets_club_user_match_checkin_uidx`, intocada.

drop index public.tickets_user_match_checkin_uidx;

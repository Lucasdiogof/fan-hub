-- ============================================================================
-- M2.2B-B round 1 — Drop the transitional DEFAULT Goiás (24 tabelas).
-- NÃO aplicada ainda (arquivo local, aguardando revisão).
--
-- `DEFAULT '<GoiasUUID>'::uuid` em `club_id` era um andaime de compatibilidade
-- (M2.2A) pra escritas antigas que nunca mandavam `club_id` — confirmado
-- nesta rodada, por grep + `pg_proc.prosrc` ao vivo, que TODO write do HEAD
-- atual (M3.4+) já manda `club_id` explicitamente. Sem o andaime, essas
-- mesmas escritas antigas (bundle legacy) passam a falhar com NOT NULL
-- violation — decisão deliberada, autorizada pelo dono (Post-Rollout
-- Retirement Gate, `docs/multiclub/39_post_rollout_legacy_retirement_gate.md`).
--
-- `NOT NULL` e a FK pra `clubs(id)` NÃO são tocados — só o DEFAULT sai.
-- 0 DML, 0 CASCADE.
--
-- Guard: mesmo padrão da migration anterior — só executa com clubs=1 (Goiás).
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

alter table public.arena_achievements alter column club_id drop default;
alter table public.arena_selected_content alter column club_id drop default;
alter table public.career_path_progress alter column club_id drop default;
alter table public.career_players alter column club_id drop default;
alter table public.guess_players alter column club_id drop default;
alter table public.lineup_match_progress alter column club_id drop default;
alter table public.lineup_matches alter column club_id drop default;
alter table public.match_lineup_votes alter column club_id drop default;
alter table public.match_monitor_sessions alter column club_id drop default;
alter table public.notification_events alter column club_id drop default;
alter table public.player_identity_results alter column club_id drop default;
alter table public.quiz_active_session alter column club_id drop default;
alter table public.quiz_question_progress alter column club_id drop default;
alter table public.quiz_questions alter column club_id drop default;
alter table public.score_events alter column club_id drop default;
alter table public.squad_members alter column club_id drop default;
alter table public.store_orders alter column club_id drop default;
alter table public.supporter_memberships alter column club_id drop default;
alter table public.tactical_identity_results alter column club_id drop default;
alter table public.ticket_checkin_decisions alter column club_id drop default;
alter table public.ticket_orders alter column club_id drop default;
alter table public.tickets alter column club_id drop default;
alter table public.user_game_item_progress alter column club_id drop default;
alter table public.user_notification_preferences alter column club_id drop default;

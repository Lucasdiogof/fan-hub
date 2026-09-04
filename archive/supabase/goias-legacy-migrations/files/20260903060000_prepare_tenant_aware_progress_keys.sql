-- ============================================================================
-- M2.2B-A — Additive tenant-aware BRIDGE keys (ARENA / PROGRESS).
-- NÃO aplicada ainda (arquivo local, aguardando revisão). 0 db push.
--
-- Só ADITIVO: cria um UNIQUE INDEX composto incluindo club_id AO LADO da PK
-- legada de cada tabela de progresso. A PK legada (sem club_id) continua —
-- é ela que o app publicado E o app M3.3 ainda usam no `onConflict`
-- (verificado: nenhum onConflict do app inclui club_id). Este bridge existe
-- pra que o M3.4 possa repontar o onConflict / o ON CONFLICT das RPCs
-- `_for_club` pra chave composta ANTES de M2.2B-B dropar a PK legada.
-- Enquanto a PK legada existir, um 2º clube ainda não repete (user,item).
--
-- Backward-compatible: a PK legada já garante unicidade do subconjunto, logo
-- o superset com club_id é trivialmente único — nunca falha sobre os dados
-- atuais (validado ao vivo 2026-09-02: 0 colisão prospectiva). Tabelas
-- pequenas (máx. user_game_item_progress=211) — CREATE INDEX instantâneo.
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

create unique index ugip_club_user_game_item_uidx
  on public.user_game_item_progress (club_id, user_id, game_id, item_id);

create unique index qqp_club_user_question_uidx
  on public.quiz_question_progress (club_id, user_id, question_id);

create unique index qas_club_user_difficulty_uidx
  on public.quiz_active_session (club_id, user_id, difficulty);

create unique index cpp_club_user_player_uidx
  on public.career_path_progress (club_id, user_id, player_id);

create unique index lmp_club_user_match_uidx
  on public.lineup_match_progress (club_id, user_id, match_id);

create unique index asc_club_user_game_uidx
  on public.arena_selected_content (club_id, user_id, game_id);

create unique index aa_club_user_achievement_uidx
  on public.arena_achievements (club_id, user_id, achievement_id);

-- identity results: hoje PK(user_id). Target (user_id, club_id).
create unique index pir_user_club_uidx
  on public.player_identity_results (user_id, club_id);

create unique index tir_user_club_uidx
  on public.tactical_identity_results (user_id, club_id);

-- NOTA: score_events NÃO entra — PK própria uuid nunca colide; só ROW_SCOPE,
-- já coberto pelo filtro club_id das RPCs de ranking `_for_club`.

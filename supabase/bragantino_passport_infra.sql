-- ============================================================================
-- Passaporte do Bragantino — colunas de enriquecimento.
--
-- RODE NO PROJETO SUPABASE DO BRAGANTINO (yrgyzkaaudyzmsqwzecj), NUNCA no do
-- Goiás. Idempotente: pode rodar quantas vezes precisar.
--
-- POR QUE ESTE ARQUIVO É TÃO PEQUENO
-- A auditoria anterior (estática, lendo só os .sql do repositório) concluiu
-- que faltava tudo no Bragantino: `venues`, `passport_attendances`,
-- `passport_memorable_matches` e as ~10 RPCs. Testando O BANCO AO VIVO em
-- 2026-09-07, TODAS essas estruturas já existem e já respondem com o contrato
-- que o Flutter espera:
--
--   passport_matches_for_year(2025) -> id, season, match_date, match_time,
--     kickoff_at, display_timezone, date_precision, status, competition,
--     competition_code, round, opponent, club_is_home, neutral_site,
--     home_team, away_team, home_score, away_score, club_score,
--     opponent_score, score_display, outcome, venue_name, venue_city,
--     attended                                   <- nomes GENÉRICOS, corretos
--   passport_seasons / passport_summary / passport_attendance_breakdown /
--   passport_stadium_summary / passport_attended_matches /
--   passport_memorable_match_id / passport_ranking / passport_my_rank  -> OK
--   passport_save_attendances / passport_set_memorable_match sem sessão ->
--     "not authenticated" (o guard de servidor existe e funciona)
--
-- Ou seja: só falta DADO, e as colunas de enriquecimento abaixo, que são
-- exclusivas do Bragantino (o dataset dele tem estádio partida a partida; o
-- schema herdado só tinha `venue_id`). Nada aqui recria nem altera o que já
-- funciona.
--
-- Ordem de execução:
--   1. este arquivo
--   2. bragantino_passport_venues_seed.sql   (catálogo de estádios)
--   3. bragantino_passport_matches_2024/2025/2026_seed.sql
-- ============================================================================

-- Trava de segurança: se estas estruturas não existirem, este é o banco
-- errado (ou o schema esperado mudou). Melhor parar do que alterar tabela de
-- outro projeto.
do $$
begin
  if to_regclass('public.passport_matches') is null
     or to_regclass('public.venues') is null
     or to_regclass('public.passport_attendances') is null
     or to_regclass('public.passport_memorable_matches') is null then
    raise exception
      'schema base do Passaporte ausente -- confira se este e o projeto Supabase do Bragantino';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Enriquecimento vindo do dataset do Bragantino.
--
-- `stadium` guarda o TEXTO ORIGINAL da fonte e serve de provenance: é por ele
-- que dá pra auditar de onde veio cada estádio. Quem o app exibe é
-- `venues.display_name`, via `venue_id` — a RPC já lê de lá. Os dois convivem
-- de propósito: um é o que a fonte disse, o outro é a versão normalizada.
-- ---------------------------------------------------------------------------
alter table public.passport_matches
  add column if not exists stadium text;

-- Evidência do estádio em TRÊS níveis:
--   MATCH_SPECIFIC            — a ficha da própria partida diz o estádio;
--   HISTORICAL_RECONSTRUCTION — deduzido de contexto histórico, com fonte,
--                               mas NÃO confirmado na ficha da partida;
--   UNKNOWN                   — não se sabe; `stadium` fica null.
-- Promoção automática de HISTORICAL_RECONSTRUCTION para MATCH_SPECIFIC nunca
-- acontece: subir de nível exige edição deliberada com fonte nova.
alter table public.passport_matches
  add column if not exists stadium_status text not null default 'UNKNOWN';

-- 'NEEDS_SOURCE' era o nome antigo de UNKNOWN.
update public.passport_matches
   set stadium_status = 'UNKNOWN'
 where stadium_status = 'NEEDS_SOURCE';

alter table public.passport_matches
  drop constraint if exists passport_matches_stadium_status_check;
alter table public.passport_matches
  add constraint passport_matches_stadium_status_check
  check (stadium_status in
    ('MATCH_SPECIFIC', 'HISTORICAL_RECONSTRUCTION', 'UNKNOWN'));

-- Estádio e evidência andam juntos nos dois sentidos. Isso impede que uma
-- importação futura encha o campo sem fonte — ou declare fonte sem estádio.
alter table public.passport_matches
  drop constraint if exists passport_matches_stadium_evidence_check;
alter table public.passport_matches
  add constraint passport_matches_stadium_evidence_check
  check (
    (stadium is null and stadium_status = 'UNKNOWN')
    or (stadium is not null and stadium_status <> 'UNKNOWN')
  );

-- Edição da competição ("Brasileirão 2025") e se a fase/rodada foi de fato
-- exposta pela fonte. Guardados como auditoria: o app não lê nenhum dos dois
-- hoje, e `round` continua sendo null quando a fonte não informou — em vez de
-- receber um número inventado.
alter table public.passport_matches
  add column if not exists competition_edition text;
alter table public.passport_matches
  add column if not exists phase_status text
    not null default 'ROUND_NOT_EXPOSED_BY_SOURCE';

alter table public.passport_matches
  drop constraint if exists passport_matches_phase_status_check;
alter table public.passport_matches
  add constraint passport_matches_phase_status_check
  check (phase_status in ('CONFIRMED', 'ROUND_NOT_EXPOSED_BY_SOURCE'));

-- Dia da semana e período do dia, derivados da data/hora da própria partida.
-- `day_period` é 'UNKNOWN' quando não há horário conhecido — nunca um chute
-- de "deve ter sido à noite".
alter table public.passport_matches
  add column if not exists weekday text;
alter table public.passport_matches
  add column if not exists day_type text;
alter table public.passport_matches
  add column if not exists day_period text not null default 'UNKNOWN';

alter table public.passport_matches
  drop constraint if exists passport_matches_day_type_check;
alter table public.passport_matches
  add constraint passport_matches_day_type_check
  check (day_type is null or day_type in ('WEEKDAY', 'WEEKEND'));

alter table public.passport_matches
  drop constraint if exists passport_matches_day_period_check;
alter table public.passport_matches
  add constraint passport_matches_day_period_check
  check (day_period in ('MORNING', 'AFTERNOON', 'NIGHT', 'UNKNOWN'));

-- ---------------------------------------------------------------------------
-- Índices para os filtros que a tela do Passaporte realmente faz.
-- ---------------------------------------------------------------------------
create index if not exists passport_matches_season_date_idx
  on public.passport_matches (season, match_date);
create index if not exists passport_matches_finished_by_season_idx
  on public.passport_matches (season, match_date)
  where status = 'FINISHED';
create index if not exists passport_matches_source_idx
  on public.passport_matches (source_provider, source_match_id);

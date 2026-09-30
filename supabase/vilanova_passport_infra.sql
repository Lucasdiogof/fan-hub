-- ============================================================================
-- Passaporte do Vila Nova — colunas de enriquecimento.
--
-- RODE NO PROJETO SUPABASE DO VILA NOVA, NUNCA no do Goiás nem no do
-- Bragantino. Idempotente: pode rodar quantas vezes precisar.
--
-- Mesmo contrato do Bragantino (`supabase/bragantino_passport_infra.sql`):
-- o canonical baseline já cria `venues`, `passport_attendances`,
-- `passport_memorable_matches` e as RPCs; faltam só as colunas de
-- enriquecimento abaixo (estádio partida a partida, edição da competição,
-- dia/período). Copiadas de lá sem mudança — o dataset do Vila tem o mesmo
-- formato.
--
-- Ordem de execução (depois do baseline + infra/supabase/clubs/vilanova/bootstrap.sql):
--   1. este arquivo
--   2. vilanova_passport_venues_seed.sql   (catálogo de estádios)
--   3. vilanova_passport_matches_<ano>_seed.sql (um por ano)
-- ============================================================================

-- Trava de segurança: schema do Passaporte presente E este é o banco do Vila
-- (passport_matches não tem club_id, então a linha de `clubs` é a única prova).
do $$
begin
  if to_regclass('public.passport_matches') is null
     or to_regclass('public.venues') is null
     or to_regclass('public.passport_attendances') is null
     or to_regclass('public.passport_memorable_matches') is null then
    raise exception
      'schema base do Passaporte ausente -- aplique o canonical baseline antes';
  end if;
  if not exists (select 1 from public.clubs where slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception
      'este nao e o projeto Supabase do Vila Nova (clubs precisa ter so a linha vilanova) -- PARE';
  end if;
end $$;

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

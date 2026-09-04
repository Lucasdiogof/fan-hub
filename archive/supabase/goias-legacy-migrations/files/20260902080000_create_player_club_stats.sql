-- ============================================================================
-- Cria `public.player_club_stats` + `public.player_club_stat_sources` —
-- estatística AGREGADA (jogos, gols) de uma pessoa num clube, em 2
-- granularidades explícitas:
--   CLUB_TOTAL — total conhecido pelo clube (spell_id NULL). Não implica
--   que sabemos distribuir entre passagens.
--   SPELL — número de UMA passagem específica (spell_id NOT NULL). Só
--   existe quando a fonte realmente fornece o número daquela passagem —
--   NUNCA derivado de CLUB_TOTAL por diferença/proporção/palpite.
--
-- NÃO é estatística de partida (isso é player_match_appearances, Etapa E
-- futura) — nenhuma linha por jogo aqui, só agregados.
--
-- Migration ADITIVA: não altera `people`, `clubs`, `player_positions` nem
-- os DADOS de `player_club_spells` (já aplicada na Etapa B) — só
-- ACRESCENTA uma constraint UNIQUE nela (ver abaixo), nunca reescreve
-- linha nenhuma.
-- ============================================================================

-- Alteração ADITIVA em `player_club_spells` (Etapa B, já aplicada) — só
-- pra permitir a FK composta abaixo. Não reescreve nenhum dado; um índice
-- único sobre (id, person_id, club_id) é trivialmente satisfeito porque
-- `id` sozinho já é PK (então já é único) — isso só GARANTE em nível de
-- schema o que já era verdade, viabilizando referenciar as 3 colunas
-- juntas de outra tabela.
alter table public.player_club_spells
  add constraint player_club_spells_id_person_club_key unique (id, person_id, club_id);

create table if not exists public.player_club_stats (
  -- id usa DEFAULT gen_random_uuid() — mesma justificativa de
  -- player_positions: a chave natural (person_id, club_id, spell_id) é
  -- genuinamente estável (nenhum desses 3 valores é "refinado" depois,
  -- diferente de datas em player_club_spells) — nenhum registry
  -- necessário. appearances/goals mudarem de valor NUNCA move a chave.
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people(id),
  club_id uuid not null references public.clubs(id),
  -- NULL = CLUB_TOTAL. NOT NULL = SPELL (a passagem específica).
  spell_id uuid,
  stats_scope text not null check (stats_scope in ('CLUB_TOTAL', 'SPELL')),

  appearances integer check (appearances >= 0),
  goals integer check (goals >= 0),

  verification_status text not null check (verification_status in ('VERIFIED', 'PARTIAL')),
  -- SNAPSHOT = valor capturado num momento (o único modo usado nesta
  -- etapa). LIVE fica reservado pra Etapa E — reservado no schema, não
  -- usado nesta leva. Invariante que a Etapa E precisa respeitar (ver
  -- também player_club_stat_sources.source_role=BASELINE):
  --   current = baseline.appearances
  --           + count(distinct partidas posteriores a baseline.as_of_date)
  -- NUNCA `current += 1` cego a cada sync — rodar a sync 10x tem que
  -- produzir o MESMO current (idempotente), porque o cálculo sempre parte
  -- do MESMO baseline fixo + contagem de partidas distintas, nunca soma
  -- incremental sobre o valor anterior. Ex.: Tadeu 400 (baseline,
  -- 2026-08-28) + 1 partida nova distinta = 401; rodar de novo sem
  -- partida nova adicional continua 401, nunca 402.
  data_mode text not null default 'SNAPSHOT' check (data_mode in ('SNAPSHOT', 'LIVE')),
  as_of_date date,
  as_of_match_id text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- CLUB_TOTAL <=> spell_id null; SPELL <=> spell_id not null.
  check (stats_scope <> 'CLUB_TOTAL' or spell_id is null),
  check (stats_scope <> 'SPELL' or spell_id is not null),
  -- nunca uma linha 100% vazia — pelo menos appearances OU goals conhecido
  -- (NULL = não sabemos; uma linha sem nenhum dos dois não tem propósito).
  check (appearances is not null or goals is not null),

  -- Integridade SPELL garantida pelo BANCO, não só pelo gerador do seed:
  -- FK composta (spell_id, person_id, club_id) -> player_club_spells(id,
  -- person_id, club_id). MATCH SIMPLE (padrão do Postgres) faz a
  -- constraint ser automaticamente satisfeita quando QUALQUER uma das 3
  -- colunas é NULL — como spell_id É null em toda linha CLUB_TOTAL, essas
  -- linhas nunca são checadas contra player_club_spells (correto, não
  -- deveriam ser). Em linhas SPELL, spell_id/person_id/club_id nunca são
  -- null, então a FK É enforced de verdade: seria estruturalmente
  -- IMPOSSÍVEL inserir spell_id do Walter com person_id de outra pessoa —
  -- o banco rejeita, não só o gerador.
  constraint player_club_stats_spell_coherence_fkey
    foreign key (spell_id, person_id, club_id)
    references public.player_club_spells (id, person_id, club_id)
);

comment on table public.player_club_stats is
  'Estatística AGREGADA (jogos/gols) de uma pessoa num clube — CLUB_TOTAL '
  '(spell_id null, total conhecido, pode não ser distribuível entre '
  'passagens) ou SPELL (spell_id preenchido, número de UMA passagem '
  'específica, só quando a fonte realmente fornece esse número). NUNCA '
  'derivar SPELL de CLUB_TOTAL por diferença/proporção. NUNCA estatística '
  'de partida — isso é player_match_appearances, tabela futura própria. '
  'Coerência (spell_id, person_id, club_id) é garantida por FK composta '
  'contra player_club_spells, não só pelo gerador do seed.';
comment on column public.player_club_stats.appearances is
  'NULL = não sabemos. 0 = sabemos que é zero (ex.: Walter 2019 — '
  'passagem real, reintegrado ao elenco, mas suspensão por doping '
  'ampliada antes de reestrear — 0 jogos oficiais é um fato, não '
  'ausência de dado). NUNCA transformar ausência em zero.';
comment on column public.player_club_stats.verification_status is
  'VERIFIED = aprovado pra persistência canônica por fonte estruturada '
  'confiável (career_players.aggregate_stats/club_career, squad_members.'
  'club_history com data_quality=verified) OU override humano explícito '
  '(ex.: liveDataBaseline do Tadeu). NÃO significa "confirmado por 2+ '
  'fontes". PARTIAL = evidência real, mas a própria fonte sinaliza '
  'divergência/incerteza concreta (ex.: nota "há ledger com 98/48" no '
  'aggregate do Walter, ou data_quality=partial em squad_members) — ver '
  'player_club_stats_seed_stats.json#partialDivergences pro valor '
  'concorrente e motivo de cada PARTIAL, nunca escolhido silenciosamente.';
comment on column public.player_club_stats.data_mode is
  'SNAPSHOT = valor capturado num momento fixo (as_of_date/'
  'as_of_match_id). LIVE = recalculado continuamente a partir de partidas '
  '(Etapa E, ainda não implementada) — reservado no schema, não usado '
  'nesta leva. Ver invariante de recálculo no comentário da coluna acima.';
comment on column public.player_club_stats.as_of_date is
  'Data de referência do valor (ex.: 2026-08-28 pro Tadeu=400) — quando a '
  'fonte não data o número (a maioria dos aggregate_stats históricos), '
  'fica NULL, nunca inventada.';
comment on column public.player_club_stats.as_of_match_id is
  'Só preenchido quando existe um ID de partida canônico real '
  'correspondente (ex.: passport_matches do Tadeu) — nunca inventado só '
  'porque as_of_date existe.';

-- Garante em banco que existe no máximo 1 CLUB_TOTAL canônico por
-- (person_id, club_id), e no máximo 1 stat por spell_id. Índices
-- PARCIAIS de propósito — um UNIQUE(person_id, club_id, spell_id) comum
-- NÃO bastaria: Postgres trata cada NULL como distinto entre si, então
-- 2 linhas CLUB_TOTAL (spell_id null nas duas) para a MESMA pessoa
-- passariam batido num UNIQUE cru. Os índices parciais abaixo filtram por
-- stats_scope antes de aplicar a unicidade, fechando esse buraco.
create unique index if not exists player_club_stats_club_total_idx
  on public.player_club_stats (person_id, club_id)
  where stats_scope = 'CLUB_TOTAL';
create unique index if not exists player_club_stats_spell_idx
  on public.player_club_stats (spell_id)
  where stats_scope = 'SPELL';

create index if not exists player_club_stats_person_id_idx
  on public.player_club_stats (person_id);
create index if not exists player_club_stats_club_id_idx
  on public.player_club_stats (club_id);

-- Proveniência — mesmo padrão de player_position_sources: privada,
-- granular. Uma linha CLUB_TOTAL derivada de 2+ segmentos (ex.: soma de
-- passagens) tem 1 linha de provenance POR SEGMENTO (source_role=
-- DERIVED_COMPONENT), nunca um blob opaco só — dá pra reconstruir
-- exatamente "segmento A + segmento B -> CLUB_TOTAL" consultando esta
-- tabela.
create table if not exists public.player_club_stat_sources (
  id uuid primary key default gen_random_uuid(),
  player_club_stat_id uuid not null references public.player_club_stats(id) on delete cascade,
  source_type text not null,
  source_ref text not null,
  -- Objeto bruto da fonte (appearances/goals/note originais, ANTES de
  -- qualquer interpretação) — auditável sem depender só do valor já
  -- resolvido na linha principal.
  raw_value jsonb not null,
  source_role text not null check (source_role in ('PRIMARY', 'CORROBORATING', 'DERIVED_COMPONENT', 'BASELINE')),
  as_of_date date,
  notes text,
  created_at timestamptz not null default now(),
  unique (player_club_stat_id, source_type, source_ref)
);

comment on table public.player_club_stat_sources is
  'Proveniência de cada player_club_stats — 1 linha por (fonte, registro), '
  'com o objeto bruto original em raw_value (jsonb). SEM leitura pública '
  'de propósito.';
comment on column public.player_club_stat_sources.source_role is
  'PRIMARY = fonte direta que sustenta o stat (total explicitamente '
  'afirmado, ou única entrada conhecida). CORROBORATING = fonte adicional '
  'concordante (ex.: os club_career[i] que somam exatamente o aggregate_'
  'stats já afirmado — não são a origem do total, só confirmam). '
  'DERIVED_COMPONENT = registro que PARTICIPOU de uma soma derivada (o '
  'total só existe porque somamos estes componentes — sem agregação '
  'explícita em nenhum lugar). BASELINE = snapshot explicitamente '
  'escolhido como ponto de partida pra sincronização viva futura (Etapa '
  'E) — a Etapa E precisa achar isso objetivamente por este campo, NUNCA '
  'inferir por nome de source_type ou por texto de notes.';

alter table public.player_club_stats enable row level security;
alter table public.player_club_stat_sources enable row level security;

-- ============================================================================
-- Permissões EXPLÍCITAS
-- ============================================================================

revoke all on table public.player_club_stats from anon, authenticated;
grant select on table public.player_club_stats to anon, authenticated;

drop policy if exists "read player club stats" on public.player_club_stats;
create policy "read player club stats" on public.player_club_stats
  for select using (true);

revoke all on table public.player_club_stat_sources from anon, authenticated;

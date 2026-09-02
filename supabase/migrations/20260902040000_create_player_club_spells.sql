-- ============================================================================
-- Cria `public.player_club_spells` + `public.player_club_spell_sources` —
-- modela a relação temporal Pessoa <-> Clube <-> Passagem. Uma pessoa pode
-- ter 2+ spells no MESMO clube (ex.: Walter no Goiás: 2012-2013, 2016-2017,
-- 2019) — nunca consolidados numa linha só.
--
-- spell != appearance. Esta tabela responde "houve uma passagem/vínculo
-- nesse período?", nunca "quantos jogos ele fez?" — sem appearances/goals/
-- assists/minutes/starts/shirt_number (tabelas futuras). Um spell com ZERO
-- jogos oficiais é um caso VÁLIDO (ver Walter 2019).
--
-- spell = período CONTÍNUO de vínculo, NÃO um contrato individual. Uma
-- mudança de natureza contratual (empréstimo -> compra definitiva,
-- renovação, troca administrativa) dentro da MESMA passagem contínua NÃO
-- cria um 2º spell — por isso relationship_type NÃO existe nesta tabela,
-- só em player_club_spell_sources (por registro-fonte, onde é um fato
-- real e imutável sobre aquele registro específico).
--
-- Também NÃO tem posição (VOL/LD/MC etc.) — atributo de uso, não de
-- identidade do spell (ver Dieguinho). Isso é player_positions, tabela
-- futura própria.
--
-- Migration ADITIVA: não altera `people`, `clubs`, `person_aliases` nem
-- nenhuma tabela existente. `career_players`/`squad_members`/
-- `guess_players`/`lineup_matches` NÃO ganham person_id nesta etapa.
-- ============================================================================

create table if not exists public.player_club_spells (
  -- id NÃO usa DEFAULT gen_random_uuid() — precisa ser ESTÁVEL entre runs
  -- do gerador. id = uuidv5(SPELLS_UUID_NAMESPACE, canonicalSpellKey),
  -- canonicalSpellKey vem de um registry persistido
  -- (tooling/multiclub/spells_registry.json). O MATCH de um candidate novo
  -- contra uma entrada existente do registry é por SOBREPOSIÇÃO TEMPORAL
  -- dentro do mesmo (pessoa, clube) — NUNCA por índice de array de
  -- nenhuma fonte (reordenar career_players.club_career não pode trocar
  -- spell_id nenhum). Ver spell_registry.mjs pro algoritmo completo.
  id uuid primary key,
  person_id uuid not null references public.people(id),
  club_id uuid not null references public.clubs(id),

  start_year int not null,
  start_month int,
  start_date date,
  start_precision text not null check (start_precision in ('YEAR', 'MONTH', 'DATE', 'UNKNOWN')),

  is_ongoing boolean not null default false,
  end_year int,
  end_month int,
  end_date date,
  -- end_precision é NULL exatamente quando is_ongoing=true — não existe
  -- "data final desconhecida" nesse caso, simplesmente não há fim ainda.
  -- Quando is_ongoing=false, end_precision é sempre um dos 4 valores
  -- (UNKNOWN incluso: "sabemos que terminou, não sabemos quando").
  end_precision text check (end_precision in ('YEAR', 'MONTH', 'DATE', 'UNKNOWN')),

  spell_order int not null,

  verification_status text not null check (verification_status in ('VERIFIED', 'PARTIAL')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (person_id, club_id, spell_order),

  check (start_month is null or start_month between 1 and 12),
  check (end_month is null or end_month between 1 and 12),

  check (not is_ongoing or (end_year is null and end_month is null and end_date is null and end_precision is null)),
  check (is_ongoing or end_precision is not null),

  check (start_precision <> 'YEAR' or (start_month is null and start_date is null and start_year is not null)),
  check (start_precision <> 'MONTH' or (start_date is null and start_month is not null and start_year is not null)),
  check (start_precision <> 'DATE' or start_date is not null),
  check (start_precision <> 'UNKNOWN' or (start_year is null and start_month is null and start_date is null)),

  check (end_precision <> 'YEAR' or (end_month is null and end_date is null and end_year is not null)),
  check (end_precision <> 'MONTH' or (end_date is null and end_month is not null and end_year is not null)),
  check (end_precision <> 'DATE' or end_date is not null),
  check (end_precision <> 'UNKNOWN' or (end_year is null and end_month is null and end_date is null))
);

comment on table public.player_club_spells is
  'Uma linha = um período CONTÍNUO de vínculo de uma pessoa com um clube, '
  'independente de ter jogado. spell != appearance E spell != contrato: '
  'uma troca de natureza contratual (empréstimo->compra) dentro do MESMO '
  'vínculo contínuo não cria uma 2ª linha (ver relationship_type em '
  'player_club_spell_sources). Nunca consolidar 2 passagens REALMENTE '
  'distintas (com saída de fato no meio) numa linha só.';
comment on column public.player_club_spells.start_precision is
  'Precisão do início, independente do fim (ex.: início DATE, fim ainda só '
  'YEAR, sem mentir nem perder informação). Nunca inventar 01/01 quando só '
  'se sabe o ano.';
comment on column public.player_club_spells.end_precision is
  'NULL sse is_ongoing=true (vínculo ativo, fim não existe ainda, não é '
  '"desconhecido"). Quando preenchido: YEAR/MONTH/DATE/UNKNOWN (UNKNOWN = '
  'sabemos que terminou, não sabemos quando — reservado, nenhuma linha usa '
  'ainda).';
comment on column public.player_club_spells.spell_order is
  '1, 2, 3... em ordem cronológica dentro do MESMO (person_id, club_id). '
  'Pode ser renumerado no futuro se uma passagem mais antiga ainda não '
  'catalogada for descoberta — por isso NUNCA faz parte do id do spell.';
comment on column public.player_club_spells.verification_status is
  'VERIFIED = período aprovado para persistência canônica porque veio de '
  'fonte estruturada considerada confiável (career_players.club_career, '
  'squad_members.club_history) OU override humano explícito — NÃO '
  'significa "confirmado por 2+ fontes externas independentes", significa '
  '"a fronteira temporal em si é confiável o bastante pra virar dado '
  'canônico". PARTIAL = há evidência de vínculo, mas a fronteira temporal '
  'não está suficientemente estabelecida pra virar período canônico '
  'definitivo (hoje: só quando derivado de datas de partidas em '
  'lineup_matches, nunca de career_players/squad_members/override).';

create index if not exists player_club_spells_person_id_idx
  on public.player_club_spells (person_id);
create index if not exists player_club_spells_club_id_idx
  on public.player_club_spells (club_id);

-- Proveniência — mesmo padrão de person_alias_sources: privado, o app
-- nunca precisa dela pra mostrar uma passagem, só pra auditoria/backend.
-- relationship_type mora AQUI (por registro-fonte), não em
-- player_club_spells — é um fato real e imutável sobre aquele registro
-- específico (career_players.club_career[i].loan, squad_members.
-- club_history[i].loan etc.), nunca sobre o spell mesclado como um todo.
create table if not exists public.player_club_spell_sources (
  id uuid primary key default gen_random_uuid(),
  spell_id uuid not null references public.player_club_spells(id) on delete cascade,
  source text not null,
  source_record_key text not null,
  evidence_type text not null check (evidence_type in ('PRIMARY', 'CORROBORATING')),
  relationship_type text not null check (relationship_type in ('PERMANENT', 'LOAN', 'UNKNOWN')),
  created_at timestamptz not null default now(),
  unique (spell_id, source, source_record_key)
);

comment on table public.player_club_spell_sources is
  'Proveniência de cada player_club_spells — 1 linha por (fonte, registro) '
  'que contribuiu pro spell. PRIMARY = registro cuja janela NÃO está '
  'contida na união dos outros do mesmo spell (evidência não-redundante). '
  'CORROBORATING = janela inteiramente contida em outro(s) registro(s) do '
  'mesmo spell. relationship_type = natureza contratual DAQUELE registro '
  'específico (pode diferir entre 2 fontes do MESMO spell — ex. Tadeu: uma '
  'fonte LOAN, outra PERMANENT, mesmo vínculo contínuo). SEM leitura '
  'pública de propósito.';

alter table public.player_club_spells enable row level security;
alter table public.player_club_spell_sources enable row level security;

-- ============================================================================
-- Permissões EXPLÍCITAS
-- ============================================================================

revoke all on table public.player_club_spells from anon, authenticated;
grant select on table public.player_club_spells to anon, authenticated;

drop policy if exists "read player club spells" on public.player_club_spells;
create policy "read player club spells" on public.player_club_spells
  for select using (true);

revoke all on table public.player_club_spell_sources from anon, authenticated;

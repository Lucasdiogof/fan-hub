-- ============================================================================
-- Cria `public.player_match_appearances` + `public.player_match_appearance
-- _sources` — UMA pessoa em UMA partida por UM clube. Fato PRIMÁRIO, não
-- estatística agregada (isso é player_club_stats) nem posição geral (isso
-- é player_positions) nem carreira/spell.
--
-- participation_status distingue STARTED / SUBSTITUTE_USED (contam como
-- appearance) de UNUSED_SUBSTITUTE (relacionado, não jogou — NÃO conta).
-- Regra de contagem sempre `participation_status IN ('STARTED',
-- 'SUBSTITUTE_USED')` — nunca um campo counts_as_appearance persistido
-- (seria redundante com o próprio status, poderia dessincronizar).
--
-- NÃO tem gol (isso é evento de partida, tabela futura match_events se/
-- quando precisarmos) nem contador nenhum (isso é player_club_stats).
--
-- Migration ADITIVA: não altera `people`, `clubs`, `player_club_spells`,
-- `player_positions`, `player_club_stats`, `matches` nem nenhuma tabela
-- existente.
-- ============================================================================

create table if not exists public.player_match_appearances (
  -- id usa DEFAULT gen_random_uuid() — mesma justificativa das etapas
  -- anteriores: a chave natural (person_id, club_id, canonical_match_id)
  -- é genuinamente estável, nenhum registry necessário.
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people(id),
  club_id uuid not null references public.clubs(id),
  canonical_match_id uuid not null references public.matches(id),
  -- NULLABLE — só preenchido quando a data da partida cai dentro do
  -- período de EXATAMENTE 1 spell real da pessoa naquele clube (validado
  -- em tooling, nunca uma suposição; ver build_player_match_appearances_
  -- seed.mjs). Ambiguidade (2+ spells possíveis, ou nenhum) fica NULL.
  spell_id uuid,

  participation_status text not null check (participation_status in ('STARTED', 'SUBSTITUTE_USED', 'UNUSED_SUBSTITUTE')),
  -- Mesmo catálogo canônico da Etapa C (player_positions) — nunca um
  -- vocabulário paralelo. Posição USADA nesta partida específica, não
  -- altera nem é alterada por player_positions (capacidade geral).
  position_code text check (position_code in (
    'GOL', 'ZAG', 'LD', 'LE', 'ALD', 'ALE', 'VOL', 'MC', 'MEI', 'MD', 'ME', 'PD', 'PE', 'SA', 'ATA'
  )),
  -- Snapshot da partida — o número usado NESTE jogo específico, nunca o
  -- número "global" da pessoa (esse não existe como conceito aqui).
  shirt_number integer check (shirt_number > 0),

  verification_status text not null check (verification_status in ('VERIFIED', 'PARTIAL')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Regra crítica: a MESMA pessoa não pode ganhar 2 linhas pra MESMA
  -- partida+clube. Uma correção de status (UNUSED_SUBSTITUTE ->
  -- SUBSTITUTE_USED, quando o provider atualiza) é UPDATE desta MESMA
  -- linha, nunca uma 2ª inserção.
  unique (person_id, club_id, canonical_match_id),

  -- Integridade SPELL garantida pelo BANCO — mesmo padrão exato da Etapa
  -- D (player_club_stats_spell_coherence_fkey). MATCH SIMPLE (padrão do
  -- Postgres): satisfeita automaticamente quando spell_id é NULL; quando
  -- preenchido, person_id/club_id TÊM que bater com o spell real —
  -- estruturalmente impossível inserir spell_id de uma pessoa com
  -- person_id de outra.
  constraint player_match_appearances_spell_coherence_fkey
    foreign key (spell_id, person_id, club_id)
    references public.player_club_spells (id, person_id, club_id)
);

comment on table public.player_match_appearances is
  'UMA pessoa em UMA partida por UM clube — fato primário, nunca agregado
  (isso é player_club_stats) nem posição geral (isso é player_positions)
  nem gol/evento de partida (isso é match_events, tabela futura). Regra de
  contagem como appearance: participation_status IN (STARTED,
  SUBSTITUTE_USED) — UNUSED_SUBSTITUTE nunca conta, mesmo estando
  relacionado/no banco de reservas.';
comment on column public.player_match_appearances.participation_status is
  'STARTED = começou em campo (conta). SUBSTITUTE_USED = entrou durante a
  partida (conta). UNUSED_SUBSTITUTE = ficou no banco, não entrou (NÃO
  conta) — nunca inferir esse status sem a fonte distinguir titular de
  reserva explicitamente.';
comment on column public.player_match_appearances.spell_id is
  'NULL por padrão — só preenchido quando a data da partida cai dentro do
  período de EXATAMENTE 1 spell real (validação de tooling, nunca CHECK
  de banco simples, porque compara uma data contra um boundary de
  precisão variável). Ambiguidade nunca é resolvida silenciosamente.';
comment on column public.player_match_appearances.position_code is
  'Posição USADA nesta partida específica — pode diferir de
  player_positions (capacidade geral) sem que uma altere a outra. Mesmo
  catálogo canônico de 15 códigos da Etapa C, nunca um vocabulário
  paralelo.';

create index if not exists player_match_appearances_person_id_idx
  on public.player_match_appearances (person_id);
create index if not exists player_match_appearances_club_id_idx
  on public.player_match_appearances (club_id);
create index if not exists player_match_appearances_match_id_idx
  on public.player_match_appearances (canonical_match_id);

-- Proveniência — mesmo padrão granular das etapas anteriores.
create table if not exists public.player_match_appearance_sources (
  id uuid primary key default gen_random_uuid(),
  player_match_appearance_id uuid not null references public.player_match_appearances(id) on delete cascade,
  source_type text not null,
  source_ref text not null,
  raw_value jsonb not null,
  -- Roles PRÓPRIOS desta tabela — não reaproveita o enum de
  -- player_club_stat_sources (aquele tem BASELINE, que é um conceito de
  -- ESTATÍSTICA AGREGADA, não de fato-de-partida-individual; não pertence
  -- semanticamente a uma appearance). PRIMARY = evidência original que
  -- gerou a linha (ex.: lineup_matches). CORROBORATING = uma 2ª fonte
  -- independente confirma a MESMA appearance (não gera linha nova, só
  -- provenance adicional). CORRECTION = uma fonte posterior que revisa um
  -- valor já gravado (ex.: status corrigido de UNUSED_SUBSTITUTE pra
  -- SUBSTITUTE_USED quando o provider atualiza) — preserva o valor
  -- ANTERIOR em raw_value, nunca apaga o histórico da correção.
  source_role text not null check (source_role in ('PRIMARY', 'CORROBORATING', 'CORRECTION')),
  observed_at date,
  notes text,
  created_at timestamptz not null default now(),
  unique (player_match_appearance_id, source_type, source_ref)
);

comment on table public.player_match_appearance_sources is
  'Proveniência granular de cada player_match_appearances — inclui
  raw_player_identifier/raw_position/raw_status originais em raw_value
  (jsonb), nunca só o valor já resolvido. SEM leitura pública de
  propósito. IDs de provider externo (OneFootball etc.) ficam aqui como
  dado de auditoria, NUNCA viram a identidade canônica da appearance.';

alter table public.player_match_appearances enable row level security;
alter table public.player_match_appearance_sources enable row level security;

-- ============================================================================
-- Permissões EXPLÍCITAS
-- ============================================================================

revoke all on table public.player_match_appearances from anon, authenticated;
grant select on table public.player_match_appearances to anon, authenticated;

drop policy if exists "read player match appearances" on public.player_match_appearances;
create policy "read player match appearances" on public.player_match_appearances
  for select using (true);

revoke all on table public.player_match_appearance_sources from anon, authenticated;

-- ============================================================================
-- Cria `public.player_positions` + `public.player_position_sources` —
-- modela QUAIS posições uma pessoa PODE exercer num clube (capacidade),
-- NUNCA identidade (não são 3 pessoas, é 1 pessoa versátil) e NUNCA
-- observação pontual de partida (isso é player_match_appearances.position,
-- tabela futura própria — uma partida como LD não apaga VOL/MC da lista
-- geral).
--
-- position_code é um catálogo FECHADO (CHECK, não tabela — 15 valores
-- fixos, já são o mesmo enum `PlayerPosition` em produção em
-- lib/shared/domain/player_position.dart, usado por crowd_lineup/
-- formation.dart/position_compatibility.dart). Nunca um catálogo paralelo.
--
-- Migration ADITIVA: não altera `people`, `clubs`, `person_aliases`,
-- `player_club_spells` nem nenhuma tabela existente.
-- ============================================================================

create table if not exists public.player_positions (
  -- id usa DEFAULT gen_random_uuid() — diferente de player_club_spells,
  -- aqui EXISTE uma chave natural genuinamente estável: (person_id,
  -- club_id, spell_id, position_code) nunca muda de significado (o código
  -- é um valor fechado de catálogo, não um dado observado que se refina).
  -- Nenhum registry é necessário — provenance resolve por JOIN nessa
  -- chave natural, mesmo padrão de person_aliases.
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people(id),
  club_id uuid not null references public.clubs(id),
  -- NULL = posição geral da pessoa naquele clube (o caso de TODAS as
  -- linhas desta primeira leva — nenhuma fonte atual dá posição no grão
  -- de spell). NOT NULL fica reservado pra quando uma fonte futura der
  -- posição já datada/vinculada a uma passagem específica.
  spell_id uuid references public.player_club_spells(id),
  position_code text not null check (position_code in (
    'GOL', 'ZAG', 'LD', 'LE', 'ALD', 'ALE', 'VOL', 'MC', 'MEI', 'MD', 'ME', 'PD', 'PE', 'SA', 'ATA'
  )),
  -- 1 = principal, 2 = secundária, 3 = terciária... Só confiável quando
  -- verification_status=VERIFIED vindo de goias_squad.dart (fonte humana
  -- ordenada) ou de uma única posição sem ambiguidade. Quando
  -- verification_status=PARTIAL, a ordem reflete frequência de observação
  -- entre fontes, NUNCA uma hierarquia confirmada — ver comment abaixo.
  position_order int not null check (position_order > 0),
  verification_status text not null check (verification_status in ('VERIFIED', 'PARTIAL')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (person_id, club_id, spell_id, position_code),
  unique (person_id, club_id, spell_id, position_order)
);

comment on table public.player_positions is
  'Quais posições uma pessoa PODE exercer num clube — capacidade, nunca '
  'identidade (versatilidade não vira 2ª pessoa) nem observação de '
  'partida específica (isso é player_match_appearances.position, tabela '
  'futura). Uma posição observada 1x numa partida NUNCA apaga/substitui '
  'as demais desta lista.';
comment on column public.player_positions.spell_id is
  'NULL = posição geral do (person_id, club_id) — todas as linhas desta '
  'primeira leva usam NULL, porque nenhuma fonte atual dá posição no grão '
  'de spell (career_players.position é por pessoa inteira, não por '
  'club_career[i]; goias_squad.dart não tem data). A coluna existe pra '
  'aceitar precisão futura, não pra fingir uma precisão que os dados de '
  'hoje não têm.';
comment on column public.player_positions.position_order is
  '1=principal, 2=secundária, 3=terciária... Confiável (reflete '
  'hierarquia real) quando verification_status=VERIFIED. Quando PARTIAL, '
  'é só frequência de observação entre fontes sem fonte-ouro ordenada — '
  'nunca tratar como hierarquia confirmada nesse caso.';
comment on column public.player_positions.verification_status is
  'VERIFIED = veio de lib/features/crowd_lineup/domain/goias_squad.dart '
  '(lista humana curada e ordenada) OU todas as fontes estruturadas '
  'concordam num único código, sem ambiguidade. PARTIAL = 2+ códigos '
  'distintos observados sem uma fonte-ouro que ordene — versatilidade '
  'real, mas sem hierarquia confiável entre fontes (mesma semântica de '
  'player_club_spells.verification_status: aprovado pra persistência '
  'canônica vs. evidência real mas fronteira/hierarquia não definitiva).';

-- Garante em banco (não só no gerador) que a posição geral (spell_id null)
-- de um (person_id, club_id) nunca duplica código nem ordem — índices
-- parciais porque NULL não colide com NULL num UNIQUE comum.
create unique index if not exists player_positions_general_code_idx
  on public.player_positions (person_id, club_id, position_code)
  where spell_id is null;
create unique index if not exists player_positions_general_order_idx
  on public.player_positions (person_id, club_id, position_order)
  where spell_id is null;

create index if not exists player_positions_person_id_idx
  on public.player_positions (person_id);
create index if not exists player_positions_club_id_idx
  on public.player_positions (club_id);

-- Proveniência — mesmo padrão de person_alias_sources/player_club_spell_
-- sources: privado, resolve por JOIN na chave natural (nunca UUID
-- pré-computado), o app nunca precisa dela pra mostrar uma posição.
create table if not exists public.player_position_sources (
  id uuid primary key default gen_random_uuid(),
  player_position_id uuid not null references public.player_positions(id) on delete cascade,
  -- source_type/source_ref substituem o par (source, source_record_key)
  -- dos outros *_sources — aqui guardamos a evidência GRANULAR completa
  -- (raw_value, match_id, observed_at), não só uma chave composta opaca.
  source_type text not null,
  source_ref text not null,
  -- Texto/código EXATO como apareceu na fonte, ANTES do mapeamento pro
  -- catálogo canônico (ex.: "Meia-atacante", "LD/MC", "vol") — nunca
  -- reescrito, mesmo quando 1 raw_value composto gera 2+ linhas (1 por
  -- código resolvido).
  raw_value text not null,
  -- Só preenchido quando a evidência vem de uma partida específica
  -- (lineup_matches) — NULL pra squad_members/guess_players/
  -- career_players/goias_squad_dart, nunca inventado.
  match_id text,
  -- Só preenchido quando a fonte tem data própria (lineup_matches.
  -- match_date) — NULL quando a fonte não data a informação.
  observed_at date,
  evidence_type text not null check (evidence_type in ('PRIMARY', 'CORROBORATING')),
  -- Nota gerada automaticamente quando raw_value é composto ("X / Y",
  -- "LD/MC") — nunca prosa humana livre inventada, só metadado mecânico.
  notes text,
  created_at timestamptz not null default now(),
  unique (player_position_id, source_type, source_ref, match_id)
);

-- match_id NULL não colide entre si num UNIQUE comum (semântica padrão de
-- NULL) — este índice parcial garante em banco que, pras fontes SEM
-- partida (match_id is null), ainda assim não duplica (player_position_id,
-- source_type, source_ref).
create unique index if not exists player_position_sources_no_match_idx
  on public.player_position_sources (player_position_id, source_type, source_ref)
  where match_id is null;

comment on table public.player_position_sources is
  'Proveniência GRANULAR de cada player_positions — 1 linha por (fonte, '
  'registro[, partida]) que corroborou aquele código, com o valor bruto '
  'original preservado em raw_value. PRIMARY/CORROBORATING seguem o mesmo '
  'sentido de player_club_spell_sources. SEM leitura pública de propósito.';
comment on column public.player_position_sources.raw_value is
  'Valor EXATO da fonte antes do mapeamento — nunca editado/normalizado '
  'aqui. É o que permite auditar CADA decisão de mapeamento (ex.: por que '
  '"Meia-atacante" virou MEI) sem depender só do código já resolvido.';
comment on column public.player_position_sources.match_id is
  'ID da partida em lineup_matches, só quando a evidência vem de lá. '
  'NULL pras outras fontes — nunca inventado.';

alter table public.player_positions enable row level security;
alter table public.player_position_sources enable row level security;

-- ============================================================================
-- Permissões EXPLÍCITAS
-- ============================================================================

revoke all on table public.player_positions from anon, authenticated;
grant select on table public.player_positions to anon, authenticated;

drop policy if exists "read player positions" on public.player_positions;
create policy "read player positions" on public.player_positions
  for select using (true);

revoke all on table public.player_position_sources from anon, authenticated;

-- ============================================================================
-- Cria `public.matches` + `public.match_source_refs` — fundação MÍNIMA de
-- identidade canônica de partida, necessária pra `player_match_appearances`
-- (Etapa E). Nenhuma tabela existente (`passport_matches`, `lineup_matches`)
-- serve pra isso hoje — ver auditoria completa em
-- data_export/goias/player_reconciliation/match_identity_audit.json —
-- resumo:
--   - passport_matches.id (`pe_*`) é ESTÁVEL, mas o schema inteiro é
--     construído do ponto de vista do Goiás (goias_is_home, goias_score,
--     opponent) — sem home_club_id/away_club_id simétricos, um 2º clube
--     que jogasse a MESMA partida não teria como apontar pra essa linha.
--   - lineup_matches.id é um slug próprio, sem ponte NENHUMA com
--     passport_matches (cross-check real: só 15 das 31 partidas batem
--     1:1 por data+oponente) nem com qualquer provider.
--   - OneFootball (Worker) só cobre 1 competição atual por vez, sem
--     histórico, e o id é amarrado ao provider (trocar de provider troca
--     o id inteiro).
-- Nenhuma delas é multi-clube-safe nem estável o bastante pra virar a
-- identidade primária de `player_match_appearances.canonical_match_id`.
--
-- `matches` NÃO substitui nem reescreve `passport_matches`/
-- `lineup_matches` — cada um continua sendo a fonte de verdade do que já
-- é (catálogo do Passaporte / dataset do jogo Adivinhe a Escalação). Esta
-- tabela é só a camada de identidade CRUZADA.
--
-- `matches.id` NÃO usa DEFAULT gen_random_uuid() — precisa ser ESTÁVEL
-- entre runs do gerador, exatamente como people/clubs/player_club_spells.
-- id = uuidv5(MATCHES_UUID_NAMESPACE, canonicalMatchKey), canonicalMatchKey
-- vem de um registry persistido (tooling/multiclub/matches_registry.json).
-- Resolução em 2 ETAPAS (ver match_registry.mjs pro algoritmo completo):
--   1) anchor exato — sobreposição de (source_namespace, source_ref) via
--      match_source_refs — a evidência mais forte.
--   2) SÓ quando nenhum anchor bate: candidato estrutural — identidade de
--      clube (home/away) + sobreposição de intervalo de kickoff +
--      competição/temporada como evidência de apoio, NUNCA placar. Existe
--      justamente pro cenário multi-clube: 2 fontes de 2 clubes diferentes,
--      SEM nenhum anchor em comum, descrevendo a MESMA partida real.
-- Corrigir data/horário/nomes/placar/competição, ou ligar uma 2ª/3ª fonte
-- à mesma partida depois (por qualquer uma das 2 etapas), NUNCA troca
-- matches.id.
--
-- IDs de fonte externa (passport_matches.id, lineup_matches.id slug, um
-- futuro id de provider) NÃO ficam em colunas desta tabela — ficam em
-- `match_source_refs`, uma linha por (fonte, partida). Isso é o que
-- permite o cenário multi-clube: quando o Juventude importar sua própria
-- base e encontrar a MESMA partida (Goiás x Juventude), a fonte dele vira
-- uma NOVA linha em match_source_refs apontando pro MESMO match_id — nunca
-- uma 2ª linha em `matches`. Um match com 2+ candidatos ambíguos (por
-- anchor OU por atributo estrutural) nunca é resolvido sozinho — fica
-- BLOCKED_AMBIGUOUS_MATCH no relatório do gerador, nunca escolhido.
--
-- Migration ADITIVA: não altera nenhuma tabela existente.
-- ============================================================================

create table if not exists public.matches (
  id uuid primary key,
  -- Ambos NULLABLE de propósito — hoje só existe 1 clube (Goiás) em
  -- `clubs`. O lado adversário fica sem club_id até esse clube ser
  -- onboardado (fora de escopo desta etapa) — nome do time sempre
  -- preservado em home_team_name/away_team_name, nunca perdido.
  home_club_id uuid references public.clubs(id),
  away_club_id uuid references public.clubs(id),
  home_team_name text not null,
  away_team_name text not null,

  -- Precisão temporal EXPLÍCITA — nunca alegar mais precisão do que a
  -- fonte realmente tem (mesma filosofia de player_club_spells.
  -- start_precision). YEAR = só o ano é confiável — lineup_matches.
  -- match_date tem 10 casos reais no padrão "YYYY-01-01" (mês E dia
  -- fabricados, não só o dia — confirmado por auditoria: datas de
  -- Brasileirão/Copa do Brasil em "01/janeiro" não fazem sentido de
  -- calendário). MONTH = mês/ano confiáveis, só o dia é placeholder
  -- (padrão "YYYY-MM-01" com MM plausível, ex. "2006-02-01"). DATE = dia
  -- real confirmado, sem horário. DATETIME = horário real confirmado (só
  -- ocorre hoje via passport_matches.date_precision='datetime', copiado
  -- de passport_matches.kickoff_at). NUNCA promovido automaticamente —
  -- só um link passport_matches com data confirmada promove a precisão.
  --
  -- CORREÇÃO desta revisão: kickoff_date NÃO é mais NOT NULL, e NÃO existe
  -- sentinela nenhum (nem dia=1, nem mês=1) — se a fonte só sabe o ano,
  -- kickoff_date fica genuinamente NULL. Um valor fabricado "YYYY-01-01"
  -- persistido como se fosse dado real foi identificado como o mesmo erro
  -- que este documento inteiro existe pra evitar (o problema do "Tadeu
  -- 398x400", só que aplicado a data em vez de estatística). Ordenação
  -- cronológica com precisão mista usa `tooling/multiclub/kickoff_
  -- precision.mjs` (intervalos [inicio,fim] por precisão), nunca uma
  -- coluna fabricada — ver comentário de kickoff_year abaixo.
  kickoff_year int not null,
  -- NULL exatamente quando kickoff_precision='YEAR'.
  kickoff_month int,
  -- NULL quando kickoff_precision IN ('YEAR','MONTH') — nunca um
  -- placeholder de dia. Quando NOT NULL, coerente com kickoff_year/
  -- kickoff_month (CHECK abaixo).
  kickoff_date date,
  -- NOT NULL somente quando kickoff_precision='DATETIME' (reforçado pelo
  -- CHECK abaixo) — nunca um horário inventado.
  kickoff_at timestamptz,
  kickoff_precision text not null check (kickoff_precision in ('YEAR', 'MONTH', 'DATE', 'DATETIME')),

  competition text,
  season text,
  home_score integer,
  away_score integer,
  verification_status text not null check (verification_status in ('VERIFIED', 'PARTIAL')),
  -- Mesma convenção de passport_matches.data_notes — caveat legível
  -- quando algo precisa de contexto, nunca prosa usada pra decidir dado.
  data_notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- pelo menos um lado precisa ser um clube que já conhecemos — senão a
  -- linha não serve pro propósito desta tabela (identidade de partida
  -- ENVOLVENDO um clube do nosso catálogo).
  check (home_club_id is not null or away_club_id is not null),
  -- quando os 2 lados são conhecidos, nunca podem ser o MESMO clube.
  check (home_club_id is null or away_club_id is null or home_club_id <> away_club_id),
  -- kickoff_at só existe quando a precisão declarada é DATETIME.
  check ((kickoff_precision = 'DATETIME') = (kickoff_at is not null)),
  -- kickoff_date só existe em DATE/DATETIME — nunca em YEAR/MONTH (sem
  -- sentinela de dia).
  check ((kickoff_precision in ('DATE', 'DATETIME')) = (kickoff_date is not null)),
  -- kickoff_month só existe em MONTH/DATE/DATETIME — NULL exatamente em YEAR.
  check ((kickoff_precision = 'YEAR') = (kickoff_month is null)),
  -- quando kickoff_date existe, tem que ser coerente com kickoff_year/
  -- kickoff_month (nunca 2 fontes de verdade discordando).
  check (kickoff_date is null or extract(year from kickoff_date)::int = kickoff_year),
  check (kickoff_date is null or kickoff_month is null or extract(month from kickoff_date)::int = kickoff_month)
);

comment on table public.matches is
  'Identidade CANÔNICA de partida — multi-clube desde a fundação
  (home_club_id/away_club_id simétricos, nunca "goias + adversário"). Não
  substitui passport_matches/lineup_matches, só dá uma identidade neutra
  que player_match_appearances pode referenciar sem depender do ponto de
  vista de um único clube ou de um provider específico. IDs de fonte
  externa vivem em match_source_refs, nunca em colunas desta tabela.';
comment on column public.matches.id is
  'Vem do match registry (tooling/multiclub/matches_registry.json) —
  NUNCA gen_random_uuid(). uuidv5(MATCHES_UUID_NAMESPACE,
  canonicalMatchKey), canonicalMatchKey sequencial e imutável. Corrigir
  data/horário/nomes/placar/competição, ou ligar uma fonte nova (mesmo de
  um 2º clube, por anchor exato OU por candidato estrutural) à mesma
  partida, NUNCA troca este id.';
comment on column public.matches.kickoff_date is
  'NULL quando a precisão é YEAR/MONTH — NUNCA um placeholder de dia
  (ex.: "YYYY-01-01" fabricado). Só preenchido quando o dia é
  genuinamente conhecido (DATE/DATETIME). Ordenação cronológica com
  precisão mista usa tooling/multiclub/kickoff_precision.mjs (intervalos),
  nunca esta coluna sozinha quando ela é NULL.';

create index if not exists matches_home_club_id_idx on public.matches (home_club_id);
create index if not exists matches_away_club_id_idx on public.matches (away_club_id);
create index if not exists matches_kickoff_date_idx on public.matches (kickoff_date);
create index if not exists matches_kickoff_year_month_idx on public.matches (kickoff_year, kickoff_month);

alter table public.matches enable row level security;

revoke all on table public.matches from anon, authenticated;
grant select on table public.matches to anon, authenticated;

drop policy if exists "read matches" on public.matches;
create policy "read matches" on public.matches
  for select using (true);

-- ============================================================================
-- `match_source_refs` — identidade de FONTE separada da identidade
-- canônica de partida. Cada linha é uma ponte auditável (fonte, partida) ->
-- matches.id. Nunca a identidade primária em si (isso é matches.id).
--
-- `source_type` é classificação SEMÂNTICA (LINEUP_MATCH/PASSPORT_MATCH/
-- PROVIDER_FIXTURE) — NUNCA o namespace de identidade. `source_namespace`
-- é o namespace real (ex.: 'goias_lineup_curated', 'goias_passport',
-- 'juventude_passport', 'onefootball'). Isso evita a premissa errada de
-- que um source_type inteiro é um namespace global único: 2 clubes podem
-- ter cada um sua própria fonte PASSPORT_MATCH (namespaces
-- 'goias_passport'/'juventude_passport' diferentes) sem colidir, mesmo
-- compartilhando o mesmo source_type.
--
-- UNIQUE(source_namespace, source_ref): garante que a MESMA identidade de
-- fonte nunca aponte pra 2 matches diferentes, DENTRO do namespace certo —
-- 'goias_passport:abc' e 'juventude_passport:abc' podem coexistir (times
-- diferentes, ids que só coincidem por acaso), mas 'goias_passport:abc'
-- nunca pode apontar pra 2 matches.
--
-- external_match_id foi REMOVIDA desta revisão: nas 2 fontes reais de
-- hoje (LINEUP_MATCH, PASSPORT_MATCH) ela sempre guardava exatamente o
-- MESMO valor de source_ref — 2 colunas pro mesmo dado, nunca usadas de
-- forma distinta. Se um provider futuro realmente precisar de um id bruto
-- diferente do source_ref interno (ex.: source_ref é um slug nosso,
-- construído; o id bruto do provider é outra coisa), essa coluna volta
-- numa migration própria, com um caso real que justifique a distinção —
-- não antecipada aqui sem uso.
-- ============================================================================

create table if not exists public.match_source_refs (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  source_type text not null check (source_type in ('LINEUP_MATCH', 'PASSPORT_MATCH', 'PROVIDER_FIXTURE')),
  source_namespace text not null,
  source_ref text not null,
  -- Clube do PONTO DE VISTA de quem trouxe esta fonte — nullable/
  -- informativo, fora da constraint de unicidade (o namespace já
  -- resolve o escopo).
  source_club_id uuid references public.clubs(id),
  created_at timestamptz not null default now(),

  unique (source_namespace, source_ref)
);

comment on table public.match_source_refs is
  'Proveniência de IDENTIDADE de partida — liga cada fonte externa
  (lineup_matches, passport_matches, um provider futuro) ao matches.id
  canônico correspondente. É esta tabela, não `matches`, que cresce
  quando uma nova fonte (inclusive a base própria de um 2º clube
  encontrando a MESMA partida) é ligada — matches.id nunca muda por isso.
  SEM leitura pública de propósito — tooling/backend apenas.';
comment on column public.match_source_refs.source_type is
  'Classificação SEMÂNTICA (LINEUP_MATCH/PASSPORT_MATCH/PROVIDER_FIXTURE)
  — NUNCA o namespace de identidade. 2 clubes podem compartilhar o mesmo
  source_type com source_namespace diferente sem colidir.';
comment on column public.match_source_refs.source_namespace is
  'O namespace REAL de identidade — ex. "goias_lineup_curated",
  "goias_passport", "juventude_passport", "onefootball". Junto com
  source_ref, forma a chave de unicidade real.';

create index if not exists match_source_refs_match_id_idx on public.match_source_refs (match_id);

alter table public.match_source_refs enable row level security;

revoke all on table public.match_source_refs from anon, authenticated;

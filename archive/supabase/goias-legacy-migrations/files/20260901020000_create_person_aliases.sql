-- ============================================================================
-- Cria `public.person_aliases` + `public.person_alias_sources` — normaliza
-- os nomes/apelidos que hoje estão espalhados em canonical_aliases.json,
-- career_players.accepted_answers, guess_players.aliases, squad, lineup e
-- overrides humanos numa tabela global de aliases de PESSOA (nunca de
-- clube — isso é escopo de outra tabela, sem relação nenhuma aqui).
--
-- Migration ADITIVA: não altera `people` nem nenhuma tabela existente.
-- Sem seed nesta migration — ver 20260901030000_seed_goias_person_aliases.sql.
--
-- ALIAS NÃO É IDENTIDADE. Um alias pode legitimamente apontar pra 2+
-- pessoas diferentes (ex.: "Nicolas" -> Nicolas Godinho Johann E Nicolas
-- Vichiatto da Silva, dois jogadores reais e distintos do Goiás em épocas
-- diferentes) — por isso NUNCA existe `unique(normalized_alias)` global
-- nesta tabela. Todo consumidor precisa tratar um lookup por
-- normalized_alias como podendo devolver 0, 1 ou 2+ linhas, e recusar
-- decidir sozinho quando vier mais de 1 person_id — exatamente como
-- `canonical_aliases.json` já faz hoje (`status: AMBIGUOUS_ALIAS`).
--
-- ACESSO ASSIMÉTRICO entre as duas tabelas, de propósito: `person_aliases`
-- é pública (é o que o app lê pra resolver um nome); `person_alias_sources`
-- é proveniência/auditoria — o app nunca precisa dela pra resolver alias
-- nenhum, então fica só pra service_role/backend, sem GRANT nem policy
-- pública nenhuma (ver seção de permissões abaixo).
-- ============================================================================

create table if not exists public.person_aliases (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people(id),
  alias text not null,
  normalized_alias text not null,
  -- CHECK em vez de enum Postgres, de propósito — evoluir uma lista de
  -- valores permitidos com CHECK é `alter table ... drop constraint` +
  -- `add constraint`, sem precisar de `alter type ... add value` (que tem
  -- restrições próprias, ex. não pode rodar dentro de uma transação em
  -- versões antigas do Postgres) nem migrar todo dado existente.
  alias_type text not null check (alias_type in (
    'LEGAL_NAME',      -- nome civil pesquisado/confirmado por humano com evidência externa
    'FULL_NAME',        -- nome completo de campo estruturado da fonte (squad_members.full_name etc.), sem pesquisa externa
    'DISPLAY_NAME',      -- people.display_name, quando difere do canonical_name
    'NICKNAME',          -- apelido informal, não é substring/abreviação do nome completo
    'SHORT_NAME',        -- forma curta que É parte do nome completo (ex.: "Baier" de "Paulo César Baier")
    'SOURCE_VARIANT',    -- como uma fonte específica (não squad_members/guess_players) chama a pessoa
    'MISSPELLING'        -- grafia alternativa/erro conhecido — reservado, nenhuma linha usa isso ainda (não inventamos erro de grafia sem evidência)
  )),
  is_preferred boolean not null default false,
  created_at timestamptz not null default now(),
  -- Impede duplicata INÚTIL da MESMA pessoa (5 fontes concordando em
  -- "Tadeu" não viram 5 linhas) — mas NÃO impede a mesma string de
  -- apontar pra pessoas DIFERENTES (isso é o comportamento desejado, ver
  -- comentário acima). alias_type/source não entram na constraint: são
  -- metadado sobre COMO o alias foi visto, não parte da identidade do
  -- alias em si — repetir (person_id, normalized_alias) com alias_type
  -- diferente não é uma 2ª verdade, é a mesma verdade vista de outro
  -- ângulo, e a proveniência de cada fonte já fica preservada em
  -- person_alias_sources.
  unique (person_id, normalized_alias)
);

comment on table public.person_aliases is
  'Nomes/apelidos conhecidos de uma pessoa, agregados a partir de todas as '
  'fontes reconciliadas. Alias NÃO é identidade — o mesmo texto pode '
  'legitimamente apontar pra pessoas diferentes (ver caso "Nicolas"). '
  'Nunca decidir um lookup ambíguo escolhendo uma linha sozinho.';
comment on column public.person_aliases.normalized_alias is
  'Forma normalizada pra lookup — Unicode NFKD, minúsculas, combining '
  'marks removidos (acento sai, LETRA nunca sai: "ø"/"ł" ficam intactos, '
  'não são combining marks), pontuação/hífen/apóstrofo viram espaço, '
  'espaços colapsados. Ver normalizeAlias() em '
  'tooling/multiclub/normalize_alias.mjs, mesma função usada pra gerar '
  'este dado, nunca reimplementada em SQL.';
comment on column public.person_aliases.is_preferred is
  'true só na linha cujo normalized_alias bate com people.display_name '
  'daquela pessoa (ou com canonical_name, quando os dois são iguais) — '
  'nunca escolhida por comprimento/tipo, só por bater com o campo que '
  'people já define como "nome público". No máximo 1 por person_id, '
  'GARANTIDO em banco pelo índice único parcial abaixo, não só pelo '
  'gerador.';

-- GARANTE em banco (não só no gerador) que no máximo 1 linha por pessoa
-- é is_preferred=true — índice único PARCIAL (só sobre as linhas
-- is_preferred=true), não um unique(person_id) cru, que impediria a
-- pessoa de ter QUALQUER outro alias.
create unique index if not exists person_aliases_one_preferred_per_person
  on public.person_aliases (person_id)
  where is_preferred;

-- Índice de LOOKUP — é o padrão de acesso central desta tabela ("dado um
-- nome, quem pode ser?"), diferente de toda outra tabela deste projeto
-- (nenhuma tem um índice secundário próprio hoje porque nenhuma outra
-- precisa buscar por um campo que não é a PK). Sem isso, um lookup por
-- normalized_alias faria sequential scan — o índice único composto
-- (person_id, normalized_alias) não ajuda aqui porque person_id não é
-- conhecido ANTES da busca, é o que se está procurando.
create index if not exists person_aliases_normalized_alias_idx
  on public.person_aliases (normalized_alias);

-- Proveniência NORMALIZADA (não um `source text` que sobrescreveria a
-- origem anterior) — um mesmo alias pode ter sido visto em várias fontes
-- ao mesmo tempo (ex.: "Tadeu" em career_players E squad_members E
-- guess_players simultaneamente), e todas precisam sobreviver.
create table if not exists public.person_alias_sources (
  id uuid primary key default gen_random_uuid(),
  person_alias_id uuid not null references public.person_aliases(id) on delete cascade,
  source text not null,
  source_record_key text not null,
  created_at timestamptz not null default now(),
  unique (person_alias_id, source, source_record_key)
);

comment on table public.person_alias_sources is
  'Proveniência de cada person_aliases — 1 linha por (fonte, registro) '
  'que corroborou aquele alias. Preserva TODAS as fontes, nunca só a '
  'mais recente. SEM leitura pública de propósito (revoke all + sem '
  'policy) — é metadado de auditoria/backend, o app nunca precisa dela '
  'pra resolver um alias, só lê person_aliases.';
comment on column public.person_alias_sources.source_record_key is
  'Formato "source:sourceId" (ex.: "career_players:tadeu") — mesma chave '
  'usada em candidates.json/canonical_people_candidates.json durante a '
  'reconciliação, mecanicamente rastreável até o registro original.';

alter table public.person_aliases enable row level security;
alter table public.person_alias_sources enable row level security;

-- ============================================================================
-- Permissões EXPLÍCITAS — não depender só do comportamento implícito do
-- default ACL do schema `public` (conferido diretamente no projeto real:
-- hoje `anon`/`authenticated` têm privilégio amplo por default nesse
-- schema; RLS sem policy de escrita já bloqueia, mas não queremos que
-- tabela de identidade dependa só disso). REVOKE ALL primeiro, depois só
-- o GRANT explicitamente necessário — nunca o inverso. `service_role`/dono
-- da tabela não são afetados (REVOKE aqui só atinge `anon`/`authenticated`
-- por nome, nunca é um REVOKE FROM PUBLIC/owner).
-- ============================================================================

-- person_aliases — leitura de cliente É o propósito desta tabela.
revoke all on table public.person_aliases from anon, authenticated;
grant select on table public.person_aliases to anon, authenticated;

drop policy if exists "read person aliases" on public.person_aliases;
create policy "read person aliases" on public.person_aliases
  for select using (true);

-- person_alias_sources — metadado de auditoria/proveniência, NUNCA
-- necessário pro app resolver um alias (o app só lê person_aliases). Sem
-- GRANT nenhum pra anon/authenticated e SEM policy de select — mesmo que
-- alguém descubra um jeito de bypassar o RLS de algum outro ângulo, o
-- privilégio de tabela em si já não existe pra esses dois roles. Acesso
-- só via service_role/owner (dashboard, tooling de backend).
revoke all on table public.person_alias_sources from anon, authenticated;

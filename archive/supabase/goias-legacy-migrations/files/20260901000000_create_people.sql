-- ============================================================================
-- Cria `public.people` — primeira peça do modelo multi-clube de identidade
-- de jogador (ver docs/multiclub/08_multiclub_data_contract.md). Migration
-- ADITIVA: não altera nenhuma tabela existente, não migra dado nenhum.
--
-- `people` representa a PESSOA, nunca a relação dela com um clube — jogos,
-- gols, período, posição etc. pertencem à passagem (clube × pessoa) e serão
-- modelados depois numa tabela separada (`player_club_spells` ou
-- equivalente), uma vez que o relatório de reconciliação
-- (tooling/multiclub/reconcile_players.mjs,
-- docs/multiclub/15_player_reconciliation_report.md) tiver sido revisado
-- por humano e a gente souber de fato quais registros das fontes atuais
-- (squad_members/career_players/guess_players/lineup_matches/
-- player_identity_references) correspondem a qual pessoa.
--
-- Schema deliberadamente mínimo — sem nascimento/nacionalidade/altura/pé:
-- não temos esse dado com confiança suficiente pra 250+ pessoas (só pro
-- elenco atual, via "pesquisa web inicial", não verificado), e "não
-- inventar dado" vale tanto pra valor quanto pra afirmar implicitamente
-- "este campo é conhecido" com uma coluna vazia por design. Campos
-- biográficos entram numa migration futura, só quando houver fonte
-- confiável o bastante pra justificar a coluna.
--
-- `id` é `uuid` gerado pelo banco — nunca um slug. Slugs existentes
-- (squad_members.id, career_players.id, guess_players.id etc.) continuam
-- só como atributo auxiliar nas tabelas de origem, nunca como chave de
-- identidade — é exatamente o padrão que causou a colisão "danilo" =
-- duas pessoas diferentes hoje.
--
-- NENHUM INSERT nesta migration. Tabela fica vazia até o relatório de
-- reconciliação ser revisado e aprovado.
-- ============================================================================

create extension if not exists "pgcrypto";

create table if not exists public.people (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null,
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.people is
  'Pessoa (jogador/técnico) como identidade global, independente de clube. '
  'Nunca guarda jogos/gols/período — isso é da passagem clube×pessoa, '
  'modelada em outra tabela quando o mapeamento de reconciliação for '
  'aprovado. Ver docs/multiclub/15_player_reconciliation_report.md.';
comment on column public.people.canonical_name is
  'Nome de referência interno, escolhido na reconciliação — não '
  'necessariamente igual ao nome exibido em nenhuma fonte específica.';
comment on column public.people.display_name is
  'Nome mostrado ao usuário — pode divergir do canonical_name (ex.: '
  'apelido consagrado vs. nome completo).';

alter table public.people enable row level security;

drop policy if exists "read people" on public.people;
create policy "read people" on public.people
  for select using (true);

-- Sem policy de insert/update/delete pro cliente de propósito — por
-- enquanto só escrita via dashboard/service role, igual o resto do
-- conteúdo editorial do app (squad_members, career_players etc.).

-- ============================================================================
-- Etapa F1 — adiciona identidade canônica a `public.career_players` (Adivinhe
-- o Jogador), SEM remover nada do modelo atual. `career_players` continua
-- existindo e sendo lido normalmente pela feature — esta coluna é só a
-- ponte pra `people`, consumida quando fizer sentido (ex.: cross-feature,
-- futuras etapas F2+), nunca obrigatória pra a feature funcionar hoje.
--
-- person_id NULLABLE de propósito: 9 de 30 linhas ainda não
-- têm identidade canônica APROVADA o bastante pra persistir com segurança
-- (ver career_players_person_mapping_stats.json — todas classificadas
-- UNRESOLVED, nenhuma resolvida "pelo nome parecido"). NUNCA forçar NOT
-- NULL só pra fechar a migration — isso escancararia exatamente o erro que
-- a reconciliação inteira (Etapas A-E) existe pra evitar.
--
-- UNIQUE(person_id): auditado, não suposto — career_players é hoje
-- genuinamente 1 linha por jogador (id text primary key, um "elenco" de
-- 30 jogadores editorialmente selecionados pro jogo, nunca uma linha por
-- trajetória/edição) e as 21 linhas RESOLVED desta migration têm
-- 21 person_id distintos, sem nenhuma colisão (ver
-- career_players_person_mapping_stats.json.duplicatePersonIdIssues, vazio).
-- UNIQUE permite múltiplos NULL sem conflito (semântica padrão do
-- Postgres), então não trava as linhas UNRESOLVED.
--
-- SEM índice adicional: UNIQUE(person_id) já cria seu próprio índice
-- (btree) no Postgres — um `create index` extra na mesma coluna seria
-- puramente redundante, nunca usado pelo planner sobre o índice da
-- constraint.
--
-- Migration ADITIVA: não altera nenhuma linha, nenhuma RLS/policy/grant,
-- nenhuma outra tabela.
-- ============================================================================

alter table public.career_players
  add column if not exists person_id uuid references public.people(id);

alter table public.career_players
  add constraint career_players_person_id_key unique (person_id);

comment on column public.career_players.person_id is
  'Identidade canônica (Etapa F1) — aponta pra people.id quando existe
  exatamente 1 pessoa canônica APROVADA reconciliada pra este jogador
  (ver tooling/multiclub/career_players_person_mapping.json). NULL quando
  ainda não há identidade segura o bastante (nunca resolvido por nome
  parecido) — career_players.name continua a fonte de exibição enquanto
  person_id for NULL. NUNCA usar career_players.name como FK lógica pra
  decidir "é a mesma pessoa" em código novo — use person_id.';

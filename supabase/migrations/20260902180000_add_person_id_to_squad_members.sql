-- ============================================================================
-- Etapa F4 — adiciona identidade canônica a `public.squad_members` (Elenco
-- profissional ATUAL), SEM remover nada do modelo atual. `squad_members`
-- continua existindo e sendo lido normalmente pela feature — esta coluna é
-- só a ponte pra `people`, nunca obrigatória pra a feature funcionar hoje.
-- `squad_members.id` continua sendo a chave interna/editorial da feature
-- (usada por squadPhotoAssets e por outras features via o mesmo slug, ver
-- relatório) — NUNCA substituída por person_id em nenhum contrato
-- existente.
--
-- person_id NULLABLE — mesmo com 31/31 RESOLVED nesta auditoria
-- (elenco atual, 100% já aprovado na fundação canônica), NÃO forçamos NOT
-- NULL nesta migração: é uma migração PARALELA, reversível por design —
-- NOT NULL pode ser considerado numa migração própria e futura, depois de
-- confirmar que nada mais pode inserir uma linha sem person_id resolvido.
--
-- UNIQUE(person_id): auditado nos 2 sentidos, não suposto — nenhuma das
-- 31 linhas RESOLVED reusa um person_id já usado por outra
-- (squad_members_person_mapping_stats.json.personIdReusedAcrossRows,
-- vazio), e nenhuma pessoa canônica tem 2+ members source='squad_members'
-- (mesmo arquivo, .reverseMultiMembership, vazio). Reforçado por evidência
-- estrutural: os 31 squad_members têm 31 nomes completos
-- distintos (0 duplicata) — é o elenco profissional atual, 1 linha por
-- atleta, nunca uma linha por edição/temporada.
--
-- SEM índice adicional: UNIQUE(person_id) já cria seu próprio índice
-- (btree) no Postgres.
--
-- Migration ADITIVA: não altera nenhuma linha, nenhuma RLS/policy/grant,
-- nenhuma outra tabela.
-- ============================================================================

alter table public.squad_members
  add column if not exists person_id uuid references public.people(id);

alter table public.squad_members
  add constraint squad_members_person_id_key unique (person_id);

comment on column public.squad_members.person_id is
  'Identidade canônica (Etapa F4) — aponta pra people.id quando existe
  exatamente 1 pessoa canônica APROVADA reconciliada pra este atleta (ver
  tooling/multiclub/squad_members_person_mapping.json). squad_members.id
  continua a chave interna/editorial da feature (nome exibido, foto via
  squadPhotoAssets, etc.) — NUNCA usar squad_members.name/full_name como
  FK lógica pra decidir "é a mesma pessoa" em código novo, use person_id.';

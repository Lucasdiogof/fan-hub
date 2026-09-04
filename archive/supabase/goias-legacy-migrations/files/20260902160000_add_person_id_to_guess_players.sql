-- ============================================================================
-- Etapa F3 — adiciona identidade canônica a `public.guess_players` (Quem
-- Vestiu o Manto), SEM remover nada do modelo atual. `guess_players`
-- continua existindo e sendo lido normalmente pela feature — esta coluna
-- é só a ponte pra `people`, consumida quando fizer sentido, nunca
-- obrigatória pra a feature funcionar hoje.
--
-- person_id NULLABLE de propósito: 81 de 173 linhas ainda não
-- têm identidade canônica APROVADA o bastante pra persistir com segurança
-- (ver guess_players_person_mapping_stats.json). NUNCA forçar NOT NULL só
-- pra fechar a migration.
--
-- UNIQUE(person_id): auditado, não suposto — cardinalidade real verificada
-- nos 2 sentidos: (a) nenhuma das 92 linhas RESOLVED reusa um
-- person_id já usado por outra (guess_players_person_mapping_stats.json.
-- personIdReusedAcrossRows, vazio); (b) nenhuma pessoa canônica tem 2+
-- members source='guess_players' em canonical_people_candidates.json
-- (checado diretamente, 0 casos). Reforçado por evidência estrutural do
-- próprio dataset: as 173 linhas têm 173 display_name distintos (0
-- duplicata) — não há "edições"/"eras" do mesmo jogador modeladas como
-- linhas separadas nesta feature, ao contrário do que se cogitou auditar.
--
-- SEM índice adicional: UNIQUE(person_id) já cria seu próprio índice
-- (btree) no Postgres.
--
-- Migration ADITIVA: não altera nenhuma linha, nenhuma RLS/policy/grant,
-- nenhuma outra tabela.
-- ============================================================================

alter table public.guess_players
  add column if not exists person_id uuid references public.people(id);

alter table public.guess_players
  add constraint guess_players_person_id_key unique (person_id);

comment on column public.guess_players.person_id is
  'Identidade canônica (Etapa F3) — aponta pra people.id quando existe
  exatamente 1 pessoa canônica APROVADA reconciliada pra este jogador
  (ver tooling/multiclub/guess_players_person_mapping.json). NULL quando
  ainda não há identidade segura o bastante (nunca resolvido por nome
  parecido) — guess_players.name/display_name continuam a fonte de
  exibição enquanto person_id for NULL. NUNCA usar guess_players.name como
  FK lógica pra decidir "é a mesma pessoa" em código novo — use person_id.';

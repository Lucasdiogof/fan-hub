# Etapa M2.2A — Additive Tenant Schema

Data: 2026-09-02
Status: **APPLIED — as 6 migrations foram aplicadas com sucesso ao Supabase real em 2026-09-02 (§38-39). `git push` segue não autorizado.**

---

## 1. Commit M2.1

`96731dc` — `docs(multiclub): audit tenant scope compatibility`.

## 2. Migrations antes desta rodada

35 migrations aplicadas (`20260830220000` … `20260902210000`), todas `local=remote` (confirmado via `npx supabase migration list`).

## 3-4. Precondition — `clubs` único

```sql
select id, slug from public.clubs;
```
Resultado real: **exatamente 1 linha** — `id=4c16340d-300c-5ab2-903f-17519db9b146`, `slug=goias`. Precondition satisfeita — prossegui.

## 5. Tabelas candidatas (24) — derivadas do output real da M2.1, nunca lista cega

Elegibilidade = `rowScopeProblem === true` E não é `INHERITS_FROM_*` E não é `KEEP_GLOBAL` E não é Passaporte. Testado programaticamente que o plano gerado bate exatamente com essa derivação (`test_multiclub_m2_2a_migrations.mjs`, seção 1).

| Grupo | Tabelas |
|---|---|
| A — Conteúdo | career_players, guess_players, squad_members, lineup_matches, quiz_questions |
| B1 — Arena/Quiz/Identidade | user_game_item_progress, score_events, quiz_question_progress, quiz_active_session, arena_selected_content, arena_achievements, player_identity_results, tactical_identity_results |
| B2 — Carreira/Escalação + votos | career_path_progress, lineup_match_progress, match_lineup_votes |
| B3 — Ingressos/Loja | ticket_checkin_decisions, ticket_orders, tickets, store_orders |
| C — Sócio Torcedor | supporter_memberships |
| D — Notificações | user_notification_preferences, match_monitor_sessions, notification_events |

## 6. Tabelas excluídas (8)

| Tabela | Razão |
|---|---|
| passport_matches | `PASSPORT_OUT_OF_SCOPE_THIS_ROUND` (`NEEDS_PRODUCT_DECISION`) |
| passport_attendances | idem (herda via passport_matches) |
| passport_memorable_matches | idem (herda via passport_matches) |
| store_order_items | `NO_ROW_SCOPE_PROBLEM` (herda via `order_id` → store_orders) |
| notification_deliveries | `NO_ROW_SCOPE_PROBLEM` (herda via `event_id` → notification_events) |
| user_notification_tokens | `NO_ROW_SCOPE_PROBLEM` (`KEEP_GLOBAL`, `fcm_token` é físico do device) |
| profiles | `NO_ROW_SCOPE_PROBLEM` (identidade global do usuário) |
| delivery_addresses | `NO_ROW_SCOPE_PROBLEM` (endereço global do usuário) |

## 7. Row counts reais (consultados ao vivo, `npx supabase db query --linked`, 2026-09-02)

| Tabela | Linhas |
|---|---|
| career_players | 30 |
| guess_players | 173 |
| squad_members | 31 |
| lineup_matches | 31 |
| quiz_questions | 60 |
| passport_matches | 1697 |
| user_game_item_progress | 211 |
| score_events | 262 |
| quiz_question_progress | 160 |
| quiz_active_session | 9 |
| lineup_match_progress | 34 |
| career_path_progress | 40 |
| arena_selected_content | 9 |
| arena_achievements | **0** |
| player_identity_results | 1 |
| tactical_identity_results | 1 |
| passport_attendances | 7 |
| passport_memorable_matches | 1 |
| match_lineup_votes | 3 |
| ticket_checkin_decisions | 1 |
| ticket_orders | **0** |
| tickets | **0** |
| store_orders | **0** |
| store_order_items | **0** |
| supporter_memberships | **0** |
| user_notification_tokens | 2 |
| user_notification_preferences | **0** |
| match_monitor_sessions | 1 |
| notification_events | **0** |
| notification_deliveries | **0** |
| profiles | 14 |
| delivery_addresses | **0** |

Todas as 32 tabelas do universo M2.1 reportadas, `0` incluído onde é o caso real (7 tabelas com 0 linhas). Snapshot congelado em `data_export/goias/player_reconciliation/multiclub_m2_2a_row_counts.json`.

## 8-9. Estratégia nullable vs NOT NULL — recomendação: **Opção B**

Comparado:
- **Opção A** (nullable → backfill → set not null → FK): mais passos, mais superfície de erro, útil quando o backfill precisa de lógica condicional ou a tabela é grande o bastante pra um `UPDATE` em massa preocupar.
- **Opção B** (`ADD COLUMN club_id uuid NOT NULL DEFAULT '<goias>'::uuid REFERENCES clubs(id)` num único statement): desde o **Postgres 11**, `ADD COLUMN` com um `DEFAULT` **literal/não-volátil** evita o heap rewrite tradicional — o valor fica resolvido no catálogo pras linhas já existentes, e só linhas novas materializam o default de verdade. **Correção da rodada de revisão**: isso NÃO significa "zero lock" nem "instantâneo garantido" — é uma DDL de **lock breve orientado a metadado, nesta escala atual** (a linguagem anterior do relatório estava otimista demais). A FK contra `clubs(id)` ainda precisa validar cada valor já existente na tabela referenciante contra `clubs` — o custo disso é irrelevante hoje porque a maior tabela candidata (`score_events`) tem 262 linhas e todas recebem o mesmo UUID válido, não porque `clubs` ter 1 linha torna a validação grátis por si só.

**Recomendação: Opção B para todas as 24 tabelas** — não há tabela grande o bastante pra justificar a Opção A nesta rodada, e a Opção B reduz o número de statements (logo, a superfície de erro). Rollback também é mais simples num único `ADD COLUMN` do que numa sequência de 4 passos.

## 10. `TRANSITIONAL_COMPATIBILITY_DEFAULT`

Documentado explicitamente no cabeçalho de cada uma das 6 migrations: o `DEFAULT Goiás` é deliberadamente temporário, existe só enquanto há 1 clube real, e precisa ser reavaliado/removido na M2.2B (depois da M3 fazer o app sempre mandar `club_id` explícito). Nunca tratado como permanente.

## 11. Migration groups e nomes

6 arquivos, timestamps sequenciais após os 35 existentes:

```
20260902220000_add_multiclub_content_tenant_scope.sql                    (5 tabelas)
20260902230000_add_multiclub_arena_quiz_progress_tenant_scope.sql        (8 tabelas)
20260902240000_add_multiclub_career_lineup_progress_tenant_scope.sql     (3 tabelas)
20260902250000_add_multiclub_tickets_store_tenant_scope.sql              (4 tabelas)
20260902260000_add_multiclub_membership_tenant_scope.sql                 (1 tabela)
20260902270000_add_multiclub_notifications_tenant_scope.sql              (3 tabelas)
```
Nomes descritivos, nunca `fix_multiclub`/`migration36` — testado (`test_multiclub_m2_2a_migrations.mjs`, seção 11).

## 12. Conteúdo — migration A

`career_players`, `guess_players`, `squad_members`, `lineup_matches`, `quiz_questions`. `id text` legado preservado; `UNIQUE(person_id)` de career_players/guess_players/squad_members (F1/F3/F4) **não tocado**.

## 13. Progresso — migrations B1/B2/B3

B1 (Arena/Quiz/Identidade): `user_game_item_progress`, `score_events`, `quiz_question_progress`, `quiz_active_session`, `arena_selected_content`, `arena_achievements`, `player_identity_results`, `tactical_identity_results`. B2 (Carreira/Escalação): `career_path_progress`, `lineup_match_progress`, `match_lineup_votes`. B3 (Ingressos/Loja): `ticket_checkin_decisions`, `ticket_orders`, `tickets`, `store_orders`. PKs compostas atuais (`(user_id, game_id, item_id)` etc.) **preservadas intactas** — só ganham a coluna nova.

## 14. Membership — migration C

`supporter_memberships` (achado CRITICAL da M2.1) — 0 linhas hoje. `get_my_membership()` **não alterado** nesta rodada (ver §16).

## 15. Notificações — migration D

`user_notification_preferences`, `match_monitor_sessions`, `notification_events`. `notification_events.UNIQUE(event_type, dedupe_key)` **não tocado** — dedupe continua global/legacy durante a transição, seguro enquanto há 1 clube (redesenho é M2.2B, per M2.1 §16).

## 16. Proposta de compatibilidade de RPC — **design apenas, NÃO implementado nesta rodada**

Avaliei implementar overloads/variantes tenant-aware para `get_my_membership`, `arena_record_score`, `arena_ranking`/`arena_my_rank`/`arena_user_detail`, `crowd_lineup` — e decidi **não gerar nenhuma alteração de RPC nesta M2.2A**, por 3 razões:
1. O pedido é explícito e repetido pra cada RPC ("Não implementar se não for necessário nesta fase", item 14; "você pode PROPOR" — nunca "deve implementar", itens 12-13) — nenhuma delas precisa mudar hoje porque só existe 1 clube.
2. As assinaturas exatas que a M3 vai precisar (overload com `p_club_id` opcional? uma função nova com sufixo? RLS-based?) dependem de decisões de runtime que a M3 ainda não tomou — desenhar agora arriscaria ter que redesenhar depois, tocando uma RPC `security definer` em produção duas vezes por nada.
3. Zero risco > zero benefício nesta etapa: nenhuma RPC muda de comportamento sem uma mudança de Flutter consumindo isso, e Flutter está explicitamente fora de escopo (item 34).

**Recomendação registrada para a M3** (não implementada): para `get_my_membership()`, a Opção **A** (manter a legacy assumindo Goiás + adicionar `get_my_membership_for_club(p_club_id)` nova) é mais segura que a Opção B (overload por tipo de parâmetro) porque PL/pgSQL overloads por assinatura podem ficar ambíguos em chamadas RPC via PostgREST (o cliente Supabase resolve por nome de função + payload JSON, não por assinatura C-like) — overload arriscaria quebrar a chamada legacy sem intenção. Mesmo padrão (função nova nomeada, nunca overload posicional) recomendado para as demais RPCs da lista. **Contrato duro, válido desde já**: quando existir um 2º clube, nenhuma chamada pode depender do default Goiás — a M2.2B remove o fallback.

## 17. Assinaturas antigas preservadas

Trivialmente verdadeiro: **nenhuma das 6 migrations contém `CREATE OR REPLACE FUNCTION`/`DROP FUNCTION`** — testado explicitamente (`test_multiclub_m2_2a_migrations.mjs`, seção 7). `get_my_membership`, `arena_record_score`, `arena_ranking`, `arena_my_rank`, `arena_user_detail`, `crowd_lineup` continuam byte-idênticas às hoje aplicadas.

## 18. PKs preservadas

Testado: **0 ocorrência** de `DROP CONSTRAINT`/`DROP COLUMN`/`ALTER COLUMN`/`PRIMARY KEY` em qualquer uma das 6 migrations — a única ação de DDL em cada bloco é `ALTER TABLE ... ADD COLUMN club_id` (mais os índices auxiliares).

## 19. UNIQUEs preservadas

Testado: **0 ocorrência** de `UNIQUE(...)` novo ou alterado. `UNIQUE(person_id)` (career_players/guess_players/squad_members), `UNIQUE(match_id, user_id)` (match_lineup_votes), o índice parcial de `tickets`, e `UNIQUE(order_number)`/`UNIQUE(event_type, dedupe_key)` (KEEP_GLOBAL/NEEDS_REDESIGN, ambos intocados por decisão) continuam exatamente como estão.

## 20. Passaporte intocado

Testado: **0 menção** a `passport_matches`/`passport_attendances`/`passport_memorable_matches` em qualquer uma das 6 migrations.

## 21. RLS inalterado

Nenhuma das 6 migrations contém `CREATE POLICY`/`DROP POLICY`/`ALTER POLICY` — confirmado por inspeção (nenhum desses tokens aparece em nenhum arquivo). `auth.uid() = user_id` (OWNER) e `PUBLIC_READ` seguem exatamente como estavam.

## 22. Preconditions — **endurecido na rodada de revisão**

Cada uma das 24 tabelas tem, antes do próprio `ADD COLUMN`:
- checagem de idempotência via `information_schema.columns` (aborta com `RAISE EXCEPTION` se `club_id` já existir — nunca `ADD COLUMN IF NOT EXISTS` silencioso; um `club_id` pré-existente indica migration parcialmente replicada ou mudança manual, estado que deve travar a migration, não ser absorvido).

**Removido desta rodada**: a precondition de `row count` contra o snapshot literal (`multiclub_m2_2a_row_counts.json`). Essas 24 tabelas são vivas — progresso/votos/scores mudam a cada uso do app — e uma precondition de contagem exata faria a migration falhar por atividade normal do usuário entre a geração dos arquivos e o `db push`, sem que isso indicasse qualquer corrupção real. O snapshot **continua existindo como evidência de auditoria** em `data_export/goias/player_reconciliation/multiclub_m2_2a_row_counts.json`, só deixou de ser uma condição executável.

2 preconditions **globais**, repetidas em cada um dos 6 arquivos:
- `count(*) from public.clubs = 1`;
- **endurecido**: o clube existe com `id = <UUID Goiás> AND slug = 'goias'` juntos (não mais só o UUID isolado) — evita o caso em que o UUID existe mas o `slug` foi renomeado/diverge do esperado.

## 23. Postconditions — **endurecido na rodada de revisão**

Por tabela, contra o **estado real da tabela na própria transação** (nunca contra o snapshot congelado): 0 `club_id` NULL, 0 `club_id` órfão (LEFT JOIN contra `clubs`), 0 linhas com `club_id <> Goiás` (prova, no momento real, que só o `DEFAULT` escreveu o valor — nenhuma outra origem).

**Removida** a postcondition de `row count` antes/depois contra o snapshot — o invariante real ("`ADD COLUMN` não pode apagar/inserir linha") já é garantido estruturalmente: nenhuma das 6 migrations contém `INSERT`/`UPDATE`/`DELETE`/`TRUNCATE` (testado explicitamente, `test_multiclub_m2_2a_migrations.mjs` seção 5) — verificação estática substitui a runtime check, evitando complicar o SQL por uma garantia que já existe por construção.

## 24. Análise de lock — **linguagem corrigida na rodada de revisão**

Todas as 24 tabelas são pequenas hoje (máx. 262 linhas, `score_events`). `ADD COLUMN ... DEFAULT <literal> NOT NULL` em Postgres 11+ evita o heap rewrite tradicional — mas isso não é "zero lock" nem "instantâneo garantido" (correção explícita: a formulação original do relatório superestimava a garantia). É um DDL **de curta duração orientado a metadado, nesta escala atual** — ainda adquire lock durante a execução, só não precisa reescrever cada linha existente. A validação da FK contra `clubs(id)` precisa varrer os valores já existentes na tabela referenciante — o custo é irrelevante hoje porque a maior tabela candidata tem 262 linhas, não porque `clubs` ter 1 linha isenta a validação. `CREATE INDEX` (sem `CONCURRENTLY`) toma um lock de escrita breve — aceitável dado o volume atual; se o volume crescer muito antes da aplicação real, `CREATE INDEX CONCURRENTLY` (fora de uma transação) seria a alternativa, mas não é necessário hoje — documentado, não implementado.

## 25. Rollback

Por grupo, reversível com um `ALTER TABLE ... DROP COLUMN club_id` (não escrito nesta rodada — nunca gerar rollback destrutivo sem necessidade, per item 30). Como toda linha hoje é Goiás e nenhuma FK entrante depende de `club_id` ainda, o rollback desta fase é conceitualmente trivial: a coluna nunca é lida por nenhum código Flutter (M3 ainda não existe), então removê-la não quebra nada em produção. Não gerado como SQL porque a etapa pede só o plano, não a execução.

## 26. Matriz de compatibilidade

| Cliente | DB atual (35 migrations) | DB M2.2A (41 migrations, proposta) |
|---|---|---|
| App publicado atual | ✅ | ✅ (toda escrita cai em Goiás via DEFAULT, sem enviar `club_id`) |
| App M3 futuro (ainda não existe) | ❌ | ✅ preparado (coluna existe, mas nada consome ainda) |

**`SECOND_CLUB_BLOCKED = true`** — mesmo com `club_id` presente em 24 tabelas, o KEY_SCOPE (PKs/UNIQUEs legadas ainda globais) não está resolvido; um 2º clube colidiria em qualquer `id text` reaproveitado (`career_players.id`, `quiz_questions.id`, etc.) ou em qualquer PK composta sem `club_id`. Só destrava depois de M3 (runtime consumindo `club_id`) + M2.2B (enforcement de KEY_SCOPE).

## 27. Testes estáticos

`tooling/multiclub/test_multiclub_m2_2a_migrations.mjs` — **30 testes** (23 da 1ª rodada + 7 novos da rodada de revisão, ver §36): elegibilidade das 24 tabelas derivada do audit M2.1 (nunca lista cega), 8 exclusões com razão correta, `supporter_memberships` (CRITICAL) incluída, grupos 5/8/3/4/1/3, `club_id uuid NOT NULL DEFAULT Goiás REFERENCES clubs(id)` nas 24, índice por tabela, 0 PK/UNIQUE alterada, 0 INSERT/UPDATE/DELETE/TRUNCATE (4 testes separados), 0 namespace de id legado, 0 RPC tocada, guarda de idempotência nas 24, **ausência** de precondition/postcondition hardcoded contra o snapshot, precondition `id+slug` Goiás, índices confirmados plain single-column (nunca compostos/UNIQUE), reprodutibilidade byte-a-byte do plano e das migrations, nomenclatura/timestamps corretos.

**Correção feita durante a construção (1ª rodada)**: as migrations novas elevaram a contagem total de arquivos em `supabase/migrations/` de 35 para 41, o que quebrou 6 testes JÁ COMMITADOS de etapas anteriores (F2, F5, F6, F7, M1, M2.1) que comparavam esse total contra um `35` hardcoded como prova de "esta etapa não gerou nenhuma migration". Corrigido nos 6 arquivos: a comparação agora filtra por `timestamp <= 20260902210000` (o baseline real da F4.5) em vez do total absoluto — preserva o que cada teste realmente afirmava sem quebrar de novo a cada etapa futura que legitimamente adicionar migrations.

## 28. `flutter analyze` / `flutter test`

`flutter analyze`: **0 issues**. Nenhum arquivo Dart tocado nesta etapa (`git status` confirma) — baseline de `flutter test` continua **769 passed / 1 skip** (herdado da M2.1, não re-executado porque não há mudança Dart que pudesse afetá-lo).

## 29. JS total

**577 passando, 0 falhando** em `tooling/multiclub/test_*.mjs` (18 arquivos) — eram 570 antes da rodada de revisão (547 antes da 1ª geração da M2.2A), +7 líquidos nesta rodada (adicionados testes de ausência de row-count hardcoded, precondition id+slug, índices plain, e o split de INSERT/UPDATE/DELETE/TRUNCATE em 4 testes — 1 teste antigo removido por ficar obsoleto com a mudança de estratégia).

## 30. `npx supabase migration list` (antes da geração)

35 migrations, todas `local=remote`.

## 31. `db push --dry-run`

```
Would push these migrations:
 • 20260902220000_add_multiclub_content_tenant_scope.sql
 • 20260902230000_add_multiclub_arena_quiz_progress_tenant_scope.sql
 • 20260902240000_add_multiclub_career_lineup_progress_tenant_scope.sql
 • 20260902250000_add_multiclub_tickets_store_tenant_scope.sql
 • 20260902260000_add_multiclub_membership_tenant_scope.sql
 • 20260902270000_add_multiclub_notifications_tenant_scope.sql
```
Exatamente as 6 esperadas — nenhuma outra listada, nenhum drift contra as 35 já aplicadas.

## 32-33. `git diff --stat` / `git status`

```
 tooling/multiclub/test_career_players_canonical_consumption.mjs | 10 ++++++++--
 tooling/multiclub/test_crowd_lineup_person_mapping.mjs          |  8 ++++++--
 tooling/multiclub/test_goias_players_person_mapping.mjs         |  7 +++++--
 tooling/multiclub/test_lineup_matches_canonical_mapping.mjs     |  7 +++++--
 tooling/multiclub/test_multiclub_foundation.mjs                 |  8 ++++++--
 tooling/multiclub/test_multiclub_tenant_constraints.mjs         |  8 ++++++--
 6 files changed, 36 insertions(+), 12 deletions(-)
```
(diff só das 6 correções do item 27; as migrations/tooling/docs novos são untracked, não aparecem em `git diff --stat` de arquivos existentes.)

```
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, não tocado)
 M tooling/multiclub/test_career_players_canonical_consumption.mjs
 M tooling/multiclub/test_crowd_lineup_person_mapping.mjs
 M tooling/multiclub/test_goias_players_person_mapping.mjs
 M tooling/multiclub/test_lineup_matches_canonical_mapping.mjs
 M tooling/multiclub/test_multiclub_foundation.mjs
 M tooling/multiclub/test_multiclub_tenant_constraints.mjs
?? data_export/goias/player_reconciliation/multiclub_m2_2a_plan.json
?? data_export/goias/player_reconciliation/multiclub_m2_2a_row_counts.json
?? supabase/migrations/20260902220000_add_multiclub_content_tenant_scope.sql
?? supabase/migrations/20260902230000_add_multiclub_arena_quiz_progress_tenant_scope.sql
?? supabase/migrations/20260902240000_add_multiclub_career_lineup_progress_tenant_scope.sql
?? supabase/migrations/20260902250000_add_multiclub_tickets_store_tenant_scope.sql
?? supabase/migrations/20260902260000_add_multiclub_membership_tenant_scope.sql
?? supabase/migrations/20260902270000_add_multiclub_notifications_tenant_scope.sql
?? tooling/multiclub/build_multiclub_m2_2a_plan.mjs
?? tooling/multiclub/generate_multiclub_m2_2a_migrations.mjs
?? tooling/multiclub/test_multiclub_m2_2a_migrations.mjs
```
(a lista das 6 correções de teste no `git diff --stat` do §32-33 permanece a mesma — nenhum dos 6 arquivos de teste de etapas anteriores foi tocado de novo nesta rodada de revisão.) Untracked não relacionados a esta etapa (pré-existentes): `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md`.

## 34. `0 db push` / `0 DML manual` / `0 Git push`

Confirmado — nenhum comando de aplicação foi executado. Só leitura (`migration list`, `db push --dry-run`, `db query --linked` read-only) e geração local de arquivos.

## 35. `SECOND_CLUB_BLOCKED = true`

Ver §26 — gate explícito, permanece `true` até M3 + M2.2B.

## 36. Rodada de revisão (2026-09-02) — hardenings aplicados

Usuário confirmou independentemente: `clubs=1` (Goiás), contagens das 24 candidatas batendo com o relatório, `club_id` = 0 colunas hoje nas 24 tabelas (estado limpo). Apontou 1 problema real: **preconditions/postconditions comparando `count(*)` contra o snapshot literal congelado quebrariam a migration por atividade normal do usuário** (ex.: alguém joga entre a geração dos arquivos e o `db push`, `score_events` passa de 262 pra 263, a migration falharia sem existir corrupção). Aplicado:

1. **Removida** toda precondition/postcondition que comparava `count(*)` contra o número do snapshot (`multiclub_m2_2a_row_counts.json`) — nas 24 tabelas.
2. **Snapshot preservado** como evidência de auditoria (arquivo intocado), só deixou de controlar se a migration executa.
3. **Preconditions semânticas preservadas/endurecidas**: `clubs=1` mantida; UUID do Goiás agora checado **junto com `slug='goias'`** (não mais isolado).
4. **Guard de idempotência preservado**: `club_id` já existente continua abortando com `RAISE EXCEPTION` (nunca `ADD COLUMN IF NOT EXISTS` silencioso) — estado inesperado deve travar, não ser absorvido.
5. **Postconditions reformuladas pro estado real da transação**: 0 NULL, 0 órfão, 0 linha com `club_id <> Goiás` — usando `count(*)` do momento real, nunca um número congelado. Removida a checagem de "row count antes==depois" (o invariante já é garantido estruturalmente por 0 INSERT/UPDATE/DELETE/TRUNCATE nas 6 migrations, agora provado por teste estático em vez de runtime check).
6. **`TRANSITIONAL_COMPATIBILITY_DEFAULT` mantido, aprovado sem mudança.**
7. **Linguagem da FK corrigida**: a validação é rápida porque a maior tabela candidata tem 262 linhas, não porque `clubs` ter 1 linha isenta a validação — Postgres ainda varre os valores existentes da tabela referenciante.
8. **Estratégia Opção B mantida, aprovada** — terminologia de lock corrigida de "instantâneo"/"zero lock" pra "DDL de lock breve orientado a metadado, nesta escala atual".
9. **Índices listados explicitamente** (ver §37) — confirmado que são todos `INDEX` simples de 1 coluna, nenhum `UNIQUE`/composto que antecipe KEY_SCOPE (isso continua M2.2B).
10. **6 migrations regeneradas** com os mesmos 6 timestamps (`20260902220000`-`270000`) — nunca aplicadas antes, então regenerar os arquivos locais foi seguro.
11. **7 testes estáticos novos líquidos** provando a ausência do padrão antigo + os novos guards (§27, §29).

## 37. Índices criados por esta etapa (todos plain, single-column)

```
career_players_club_id_idx           on career_players (club_id)
guess_players_club_id_idx            on guess_players (club_id)
squad_members_club_id_idx            on squad_members (club_id)
lineup_matches_club_id_idx           on lineup_matches (club_id)
quiz_questions_club_id_idx           on quiz_questions (club_id)
user_game_item_progress_club_id_idx  on user_game_item_progress (club_id)
score_events_club_id_idx             on score_events (club_id)
quiz_question_progress_club_id_idx   on quiz_question_progress (club_id)
quiz_active_session_club_id_idx      on quiz_active_session (club_id)
arena_selected_content_club_id_idx   on arena_selected_content (club_id)
arena_achievements_club_id_idx       on arena_achievements (club_id)
player_identity_results_club_id_idx  on player_identity_results (club_id)
tactical_identity_results_club_id_idx on tactical_identity_results (club_id)
career_path_progress_club_id_idx     on career_path_progress (club_id)
lineup_match_progress_club_id_idx    on lineup_match_progress (club_id)
match_lineup_votes_club_id_idx       on match_lineup_votes (club_id)
ticket_checkin_decisions_club_id_idx on ticket_checkin_decisions (club_id)
ticket_orders_club_id_idx            on ticket_orders (club_id)
tickets_club_id_idx                  on tickets (club_id)
store_orders_club_id_idx             on store_orders (club_id)
supporter_memberships_club_id_idx    on supporter_memberships (club_id)
user_notification_preferences_club_id_idx on user_notification_preferences (club_id)
match_monitor_sessions_club_id_idx   on match_monitor_sessions (club_id)
notification_events_club_id_idx      on notification_events (club_id)
```
24 índices, 1 por tabela, todos `CREATE INDEX IF NOT EXISTS ... (club_id)` — nenhum `UNIQUE`, nenhum composto (`(club_id, person_id)` etc. continuam fora de escopo, isso é M2.2B). Confirmado por teste estático (`test_multiclub_m2_2a_migrations.mjs`, seção 9b).

---

## 38. Aplicação — 2026-09-02

**Preflight imediatamente antes do push** (todos read-only, todos confirmados verdes):
- `public.clubs` count = 1.
- `id = 4c16340d-300c-5ab2-903f-17519db9b146 AND slug = 'goias'` confirmado.
- `club_id` = 0 colunas nas 24 tabelas candidatas (estado limpo confirmado de novo, não só assumido da rodada anterior).

**`migration list` imediatamente antes**: 35 local=remote, as 6 novas só local — sem drift. **`db push --dry-run` imediatamente antes**: listou exatamente as 6 migrations esperadas, na mesma ordem, nenhuma inesperada.

**`db push` executado**: sucesso — as 6 migrations aplicaram sem nenhum `RAISE EXCEPTION`:
```
Applying migration 20260902220000_add_multiclub_content_tenant_scope.sql...
Applying migration 20260902230000_add_multiclub_arena_quiz_progress_tenant_scope.sql...
Applying migration 20260902240000_add_multiclub_career_lineup_progress_tenant_scope.sql...
Applying migration 20260902250000_add_multiclub_tickets_store_tenant_scope.sql...
Applying migration 20260902260000_add_multiclub_membership_tenant_scope.sql...
Applying migration 20260902270000_add_multiclub_notifications_tenant_scope.sql...
```
Nenhuma falha — o fluxo de tratamento de erro (migration repair/SQL manual/dashboard, tudo proibido pelo pedido) não precisou ser usado.

## 39. Validação pós-push (tudo consultado ao vivo, nada assumido)

**`migration list` final**: **41 migrations, todas `local=remote`** — as 6 novas aparecem aplicadas.

**Estrutural — 24/24 tabelas**: `data_type=uuid`, `is_nullable=NO`, `column_default='4c16340d-300c-5ab2-903f-17519db9b146'::uuid` em TODAS as 24 (query única, 24 linhas retornadas, nenhuma divergente). **24/24 FK** confirmadas via `pg_constraint`/`pg_class` contra `clubs`.

**Dados — por tabela, 0/0/0**: NULL count, orphan count (LEFT JOIN real contra `clubs`, não só confiança na FK) e "`club_id` ≠ Goiás" count — **todos 0 nas 24 tabelas**, verificado tabela por tabela e depois com uma checagem agregada única de órfãos (`total_orphans = 0`).

**Contagens atuais (auditoria, não requisito de row count)**:

| Tabela | Antes (snapshot) | Depois (real) |
|---|---|---|
| career_players | 30 | **30** |
| guess_players | 173 | **173** |
| squad_members | 31 | **31** |
| lineup_matches | 31 | **31** |
| quiz_questions | 60 | **60** |
| user_game_item_progress | 211 | **211** |
| score_events | 262 | **262** |
| quiz_question_progress | 160 | **160** |
| quiz_active_session | 9 | **9** |
| arena_selected_content | 9 | **9** |
| arena_achievements | 0 | **0** |
| player_identity_results | 1 | **1** |
| tactical_identity_results | 1 | **1** |
| career_path_progress | 40 | **40** |
| lineup_match_progress | 34 | **34** |
| match_lineup_votes | 3 | **3** |
| ticket_checkin_decisions | 1 | **1** |
| ticket_orders | 0 | **0** |
| tickets | 0 | **0** |
| store_orders | 0 | **0** |
| supporter_memberships | 0 | **0** |
| user_notification_preferences | 0 | **0** |
| match_monitor_sessions | 1 | **1** |
| notification_events | 0 | **0** |

Nenhuma divergência — os 5 datasets críticos (`career_players`, `guess_players`, `squad_members`, `lineup_matches`, `quiz_questions`) batem exatamente com os números pré-push. Nenhum `id`/`person_id`/`answer`/`lineup`/`score`/dado de membership/notification foi alterado (a única coluna nova em qualquer linha é `club_id`).

**PK/UNIQUE legacy preservadas**: confirmado ao vivo via `pg_constraint` — `career_players`/`guess_players`/`squad_members` continuam `PRIMARY KEY (id)` + `UNIQUE (person_id)`; `lineup_matches`/`quiz_questions` continuam `PRIMARY KEY (id)`. Nenhuma virou composta. **KEY_SCOPE continua NÃO resolvido**, como esperado.

**RPCs preservadas**: assinaturas de `arena_record_score`, `arena_ranking`, `arena_my_rank`, `arena_user_detail`, `get_my_membership`, `crowd_lineup` consultadas via `pg_proc` — **idênticas** às documentadas nos `.sql` fonte, nenhum `p_club_id` adicionado em nenhuma.

**RLS preservada**: 0 `CREATE POLICY`/`DROP POLICY`/`ALTER POLICY` nas 6 migrations (confirmado estaticamente antes do push) — `pg_policies` conta **89 policies** no schema `public` no estado pós-push, coerente com nenhuma alteração.

**Passaporte intocado**: `passport_matches`/`passport_attendances`/`passport_memorable_matches` confirmadas com **0 coluna `club_id`** — continuam `NEEDS_PRODUCT_DECISION`.

**Compatibilidade com o app atual**: `flutter analyze` → **0 issues**. `flutter test` → **769 passed, 1 skip** — idêntico ao baseline pré-M2.2A, provando concretamente (não só inferindo) que o app publicado atual continua funcionando byte-a-byte igual contra o schema novo.

**JS**: **577 passando, 0 falhando** em `tooling/multiclub/test_*.mjs` — mesmo total de antes do push (nenhuma mudança de comportamento, só o estado remoto mudou).

**Default de compatibilidade — validado estruturalmente, sem INSERT manual**: as 24 colunas têm `column_default = '4c16340d-300c-5ab2-903f-17519db9b146'::uuid` no catálogo (consulta acima) — isso garante, sem precisar simular, que qualquer INSERT do app atual (que nunca envia `club_id`) cairá em Goiás automaticamente.

**`SECOND_CLUB_BLOCKED = true`** — continua verdadeiro: PKs/UNIQUEs legacy globais confirmadas intactas, RPCs sem `p_club_id`, repositórios Flutter sem filtro de `club_id` (0 arquivo Dart tocado), default Goiás ainda em vigor. M2.2A não torna o sistema pronto pra um 2º clube — só prepara o schema.

---

## Resumo — o que esta etapa fez / não fez (limites respeitados)

**Fez**: adicionou `club_id` (uuid, NOT NULL, default Goiás, FK→clubs) + 1 índice em 24 tabelas, aplicado com sucesso ao Supabase real.

**Não fez**:
- 0 DML manual em produção (o preenchimento veio inteiramente do `DEFAULT` da própria coluna).
- 0 mudança de PK/UNIQUE existente (KEY_SCOPE segue M2.2B) — confirmado pós-push.
- 0 índice composto/UNIQUE que antecipe KEY_SCOPE.
- 0 mudança de RPC — confirmado pós-push, assinaturas idênticas.
- 0 mudança de Flutter/consumer (M3) — confirmado, `flutter analyze`/`test` idênticos ao baseline.
- 0 tabela de Passaporte tocada — confirmado pós-push.
- 0 RLS/policy alterada.
- 0 precondition/postcondition hardcoded contra o snapshot congelado (removida na rodada de revisão, antes do push).
- 0 `git push`.

## 40. Commit

`0d5db94` — `feat(multiclub): add additive tenant schema`. 18 arquivos (6 migrations + 3 tooling novos + 2 JSON de plano/snapshot + este relatório + os 6 testes de etapas anteriores corrigidos para não depender mais de "35 migrations" hardcoded). `store_entry_card.dart`/`_competitions_pkg/`/`migration_dump.txt`/`docs/multiclub/19_etapa_e_v4_applied_report.md`/`supabase/.temp/` confirmados fora do commit.

`git status` pós-commit: só as exclusões padrão permanecem (`store_entry_card.dart` modificado-mas-não-staged, `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md` untracked) — nenhum arquivo de M2.2A pendente.

**`git push` NÃO executado** — nunca sem pedido explícito.

---

**APPLIED e commitada (`0d5db94`). `git push` não autorizado.**

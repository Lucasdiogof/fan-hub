# M2.1 — Tenant Scope & Legacy Key Compatibility (AUDITORIA + DESIGN, NÃO aplicado)

Data: 2026-09-02
Status: **PARADO PARA REVISÃO. 0 migrations, 0 `db push`, 0 DML, 0 commit da M2, 0 `git push`, 0 consumidor Flutter migrado.**

Rodada de **auditoria/modelagem/tooling/plano de migration** — o design tem de ser aprovado ANTES de tocar o banco. Nenhum 2º clube foi nomeado/cadastrado/pressuposto — `clubRegistry` continua com 1 entrada (`goias`). Todos os exemplos usam `clubA`/`clubB`/`<club_id>`.

---

## 1. Hash da M1

M1 commitada nesta sessão: **`2a8e152`** — `feat(multiclub): add club configuration foundation`. `0 git push` (nunca houve push neste projeto). Endurecimentos de fechamento incluídos no commit: nomes de clube real removidos do teste (placeholders neutros), contagens do relatório corrigidas (27 tabelas / 25 testes), achado `UNIQUE(person_id)` como 2º eixo de KEY_SCOPE, constraints estruturadas por tabela.

## 2. `git status` pós-M1

Working tree após o commit da M1 continha só os arquivos deliberadamente fora de escopo (nada da M1 pendente):
```
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, nunca staged)
?? _competitions_pkg/                                              (excluído por padrão)
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (pré-existente)
?? migration_dump.txt                                              (excluído por padrão)
```
Depois, a M2.1 acrescentou só os próprios artefatos read-only (2 scripts + 2 JSON + este relatório).

## 3. Total de tabelas auditadas na M2.1

**32 tabelas** verificadas contra o schema real (`0 stale`), distribuídas em 5 grupos:

| grupo | nº | tabelas |
|---|---|---|
| CONTENT (editorial club-specific) | 6 | career_players, guess_players, squad_members, lineup_matches, quiz_questions, passport_matches |
| PROGRESS (user-state club-scoped) | 18 | user_game_item_progress, score_events, quiz_question_progress, quiz_active_session, lineup_match_progress, career_path_progress, arena_selected_content, arena_achievements, player_identity_results, tactical_identity_results, passport_attendances, passport_memorable_matches, match_lineup_votes, ticket_checkin_decisions, ticket_orders, tickets, store_orders, store_order_items |
| MEMBERSHIP | 1 | supporter_memberships |
| NOTIFICATIONS/infra | 5 | user_notification_tokens, user_notification_preferences, match_monitor_sessions, notification_events, notification_deliveries |
| USER_GLOBAL | 2 | profiles, delivery_addresses |

**Invariante (testado)**: `soma dos grupos (6+18+1+5+2) == totalTables == 32`, `verified == 32`, `0 stale`.

**A lista do item 10 não era completa** (aviso do pedido, confirmado): a M2.1 descobriu, não presumidas — `player_identity_results`, `tactical_identity_results`, `notification_events`, `notification_deliveries`, `user_notification_preferences`, `passport_memorable_matches`, `store_order_items`, `quiz_active_session`, `arena_achievements`, `delivery_addresses`. A fundação canônica (people/clubs/player_club_*/matches/...) fica FORA do universo de remediação — já é club-safe (M1 §16, provado nos 2 eixos).

## 4. Constraints completas por tabela

Extraídas do schema real e gravadas em `data_export/goias/player_reconciliation/multiclub_tenant_constraints_audit.json` (campos `pk`/`uniques`/`fks`/`inboundFks`/`checks`/`rls`/`rpcReads`/`rpcWrites`/`repos` por tabela). Resumo dos PKs e o eixo de cada tabela:

| tabela | PRIMARY KEY | UNIQUE relevante | ROW_SCOPE | KEY_SCOPE |
|---|---|---|---|---|
| career_players | `id text` | `UNIQUE(person_id)` | problema | **problema (2 fontes)** |
| guess_players | `id text` | `UNIQUE(person_id)` | problema | **problema (2 fontes)** |
| squad_members | `id text` | `UNIQUE(person_id)` | problema | **problema (2 fontes)** |
| lineup_matches | `id text` | — | problema | problema |
| quiz_questions | `id text` | — | problema | problema |
| passport_matches | `id text` | — | problema | problema (assimetria) |
| user_game_item_progress | `(user_id, game_id, item_id)` | — | problema | problema (item_id) |
| score_events | `id uuid` | — | problema | ok (uuid) |
| quiz_question_progress | `(user_id, question_id)` | — | problema | problema |
| quiz_active_session | `(user_id, difficulty)` | — | problema | ok (difficulty enum) |
| lineup_match_progress | `(user_id, match_id)` | — | problema | problema |
| career_path_progress | `(user_id, player_id)` | — | problema | problema |
| arena_selected_content | `(user_id, game_id)` | — | problema | problema (nem tem item_id) |
| arena_achievements | `(user_id, achievement_id)` | — | problema | problema |
| player_identity_results | `user_id` | — | problema | ok |
| tactical_identity_results | `user_id` | — | problema | ok |
| passport_attendances | `id uuid` | `UNIQUE(user_id, match_id)` | problema | ok (herda via FK) |
| passport_memorable_matches | `user_id` | — | problema | ok (herda via FK) |
| match_lineup_votes | `id uuid` | `UNIQUE(match_id, user_id)` | problema | problema |
| ticket_checkin_decisions | `(user_id, match_id)` | — | problema | problema |
| ticket_orders | `id uuid` | — | problema | ok (uuid) |
| tickets | `id uuid` | índice parcial `(user_id, match_id)` | problema | problema |
| store_orders | `id uuid` | `UNIQUE(order_number)` | problema | ok (global) |
| store_order_items | `id uuid` | — | ok (herda) | ok |
| supporter_memberships | `id uuid` | — | **problema (CRITICAL)** | ok |
| user_notification_tokens | `id uuid` | `UNIQUE(fcm_token)` | ok | ok (global) |
| user_notification_preferences | `user_id` | — | problema | ok |
| match_monitor_sessions | `match_id text` | — | problema | problema |
| notification_events | `id uuid` | `UNIQUE(event_type, dedupe_key)` | problema | **problema (dedupe global)** |
| notification_deliveries | `id uuid` | `UNIQUE(event_id, token_id)` | ok (herda) | ok |
| profiles | `id uuid` | — | GLOBAL | ok |
| delivery_addresses | `id uuid` | — | GLOBAL | ok |

## 5. UNIQUE "globais" problemáticas (item 13)

Toda `UNIQUE` classificada em `KEEP_GLOBAL` / `NEEDS_CLUB_SCOPE` / `NEEDS_REDESIGN` — **nem toda UNIQUE precisa mudar**:

| UNIQUE | tabela | classificação | por quê |
|---|---|---|---|
| `UNIQUE(person_id)` | career_players/guess_players/squad_members | **NEEDS_CLUB_SCOPE** | vira `unique(club_id, person_id) where person_id is not null` — permite a mesma pessoa em clubes diferentes, mantém 1:1 dentro de um clube |
| `UNIQUE(match_id, user_id)` | match_lineup_votes | **NEEDS_CLUB_SCOPE** | vira `unique(club_id, match_id, user_id)` — senão o voto de um clube bloqueia o do outro no mesmo match_id |
| índice parcial `(user_id, match_id) where origin='membership_check_in'` | tickets | **NEEDS_CLUB_SCOPE** | idem, ganha club_id |
| `UNIQUE(user_id, match_id)` | passport_attendances | **NEEDS_CLUB_SCOPE_VIA_MATCH** | seguro assim que `match_id` for tenant-safe (herda de passport_matches) |
| `UNIQUE(order_number)` | store_orders | **KEEP_GLOBAL** | sequência global `store_order_number_seq` — prefixo+sequência já é único global |
| `UNIQUE(fcm_token)` | user_notification_tokens | **KEEP_GLOBAL** | token de device é único por natureza (1 device → 1 conta) |
| `UNIQUE(event_id, token_id)` | notification_deliveries | **KEEP_GLOBAL** | uuids reais, herda tenancy do evento |
| `UNIQUE(event_type, dedupe_key)` | notification_events | **NEEDS_REDESIGN** | dedupe GLOBAL: um "goal" de fixture X de 2 clubes com dedupe_key colidente se anularia — a dedupe_key precisa incluir club_id (ou provar namespace global do provider) |

## 6. FKs inbound/outbound

- **Outbound reais**: quase toda tabela de user-state tem `user_id → auth.users(id) on delete cascade`. Conteúdo: career/guess/squad têm `person_id → people(id)` (série F). passport_matches → `venue_id → venues(id)`. tickets → `order_id → ticket_orders(id)`. store_order_items → `order_id → store_orders(id)`. notification_deliveries → `event_id → notification_events`, `token_id → user_notification_tokens`. passport_attendances/passport_memorable_matches → `match_id → passport_matches(id)`.
- **As 6 tabelas de conteúdo NÃO têm FK real de progresso apontando pra elas** (exceto passport_matches, com 2) — a ligação conteúdo↔progresso é 100% convenção/RPC (`arena_record_score` faz `exists(select 1 from <tabela> where id=p_item_id)`), nunca constraint de banco. Isso é o que torna a colisão de KEY_SCOPE silenciosa.
- **passport_matches**: 2 inbound FKs reais — `passport_attendances.match_id` e `passport_memorable_matches.match_id`. **Correção sobre o relatório M1**: a 2ª tabela chama-se `passport_memorable_matches` (o `passport_trajectory` é o nome da feature/arquivo Flutter, não da tabela).

## 7. RLS matrix (item 24) — usuário ≠ tenant

Gravada em `multiclub_tenant_constraints_audit.json → rlsMatrix`. Modelos encontrados:

| modelo RLS | tabelas | separa usuário? | separa clube? |
|---|---|---|---|
| `OWNER` (`auth.uid() = user_id`) | todas as de progress/user-state | **sim** | **NÃO** |
| `PUBLIC_READ` (`using (true)`) | as 6 de conteúdo + venues | n/a (leitura pública) | **NÃO** |
| `SERVICE_ROLE` (`using (false)`) | match_monitor_sessions, notification_events, notification_deliveries | n/a | **NÃO** (tenancy só por coluna) |

**Achado central de RLS — 3 conceitos SEPARADOS (o Postgres NÃO lê `APP_CLUB`)**. `APP_CLUB` existe no Flutter/build; numa policy RLS o banco só conhece `auth.uid()`, o JWT e os dados da linha — ele **não sabe qual flavor está chamando** só porque o app tem `APP_CLUB=...`. Separar:

1. **USER SECURITY** — `auth.uid() = user_id`. A RLS **garante** (usuário A não vê linha do usuário B).
2. **APPLICATION TENANT FILTER** — `.eq('club_id', activeClubId)`. O **repository Flutter** garante (o app do clubA não pede linhas do clubB).
3. **DATABASE-ENFORCED TENANT IDENTITY** — RLS/RPC exigindo `club_id` a partir de uma **fonte confiável no servidor** (claim de clube no JWT, contexto de RPC confiável, ou proibir acesso direto e passar tudo por RPC). **NÃO existe hoje — não inventar agora**; exige uma decisão adicional de auth/contexto.

**Consequência**: para dados do MESMO usuário em 2 clubes, `auth.uid() = user_id` **não impede o próprio usuário** de ler seus registros do outro clube numa query manual sem filtro. Isso **não é vazamento ENTRE usuários** — é isolamento de PRODUTO/tenant dentro da mesma identidade. **Primeiro gate obrigatório desta arquitetura**: repositories SEMPRE filtram `club_id` + RPCs recebem `p_club_id` + constraints incluem `club_id`. Enforcement estrito no próprio RLS fica **registrado como decisão FUTURA** de auth/contexto confiável — nunca se cria a falsa impressão de que a RLS "lê APP_CLUB". Conteúdo PUBLIC_READ nunca ganha ROW_SCOPE por RLS — o filtro vem da query/app.

## 8. RPC matrix (item 8)

| RPC | lê | escreve | precisa de club_id? |
|---|---|---|---|
| `arena_record_score` (security definer) | valida `exists` na tabela de conteúdo; lê user_game_item_progress `for update` | upsert em user_game_item_progress + insert em score_events | **SIM** — `p_club_id`, validação com club_id, e club_id nas 2 escritas |
| `arena_ranking` / `arena_my_rank` (security definer) | soma `score_events`/`user_game_item_progress` SEM filtro de clube; join em profiles | — | **SIM** — `where/group by club_id` (hoje agregaria cross-club) |
| `arena_user_detail` | soma user_game_item_progress por game_id | — | **SIM** |
| `get_my_membership` (security definer) | supporter_memberships `order by created_at desc limit 1` | — | **SIM (CRITICAL)** — `p_club_id` |
| `crowd_lineup(p_match_id)` (security definer) | agrega match_lineup_votes por match_id | — | **SIM** — `p_club_id` no filtro |
| `create_store_order` (roda como caller) | — | insert store_orders + store_order_items | SIM — club_id na linha do pedido |
| `passport_save_attendances` / `passport_ranking` / `passport_my_rank` | passport_attendances/passport_matches | passport_attendances | SIM — via club_id de passport_matches |
| `generate_store_order_number` | sequência | — | não (prefixo vem de ClubConfig em M3/M4) |
| triggers `delivery_address_*` | delivery_addresses do próprio user | delivery_addresses | não (USER_GLOBAL) |

## 9. Repository/runtime matrix (item 9)

Mapeado por grep em `lib/` (`.from('<tabela>')` e nomes de RPC). Tabelas lidas/escritas direto pelo Flutter: tickets (7), ticket_checkin_decisions (5), quiz_question_progress (5), delivery_addresses (5), arena_selected_content (4), quiz_active_session/profiles/lineup_match_progress/career_path_progress (3), user_notification_tokens/preferences/ticket_orders/tactical_identity_results/store_orders/player_identity_results/match_lineup_votes/arena_achievements (2), squad_members/quiz_questions/lineup_matches/guess_players/career_players (1). RPCs citados no app: `arena_ranking` (15 arquivos), `crowd_lineup` (21), `arena_record_score` (2), `get_my_membership` (2), `passport_ranking` (7), `create_store_order` (1), etc. **Nenhum consumidor foi tocado nesta rodada** — mapa só pra dimensionar o M3.

## 10. Problemas de ROW_SCOPE

**27 das 32** tabelas têm ROW_SCOPE resolvível por `club_id` (`rowScopeProblemTables` no stats). As 5 que NÃO precisam: `store_order_items` (herda de store_orders via FK), `user_notification_tokens` (device global), `notification_deliveries` (herda do evento), `profiles` e `delivery_addresses` (USER_GLOBAL — identidade/endereço da pessoa não é de clube).

## 11. Problemas de KEY_SCOPE

**17 das 32** têm KEY_SCOPE real (`keyScopeProblemTables`): as 6 de conteúdo, mais user_game_item_progress, quiz_question_progress, lineup_match_progress, career_path_progress, arena_selected_content, arena_achievements, ticket_checkin_decisions, match_lineup_votes, tickets, match_monitor_sessions, notification_events. As demais são ok (PK uuid própria, ou herdam por FK, ou UNIQUE global legítima). **ROW_SCOPE e KEY_SCOPE classificados independentemente** — várias tabelas têm um sem o outro (ex.: score_events tem ROW_SCOPE mas não KEY_SCOPE; store_orders idem).

## 12. Conteúdo editorial — estratégia por tabela

Todas as 6 continuam `EDITORIAL_SNAPSHOT` (F2/F7 intactas) — `club_id` é só tenancy, não transforma em canônico nem faz consumir `player_club_stats` ao vivo.

| tabela | estratégia | detalhe |
|---|---|---|
| career_players | COMPOSITE_PK ou SURROGATE + `unique(club_id, person_id)` | 2 fontes de KEY_SCOPE (id + person_id) |
| guess_players | idem | idem |
| squad_members | idem | sem cadeia de progresso — a mais simples |
| lineup_matches | COMPOSITE_PK ou SURROGATE (tenancy da LINHA) | JSON dos 11 permanece editorial e **SEM** person_id — F7 preservada |
| quiz_questions | COMPOSITE_PK ou SURROGATE | — |
| passport_matches | **NEEDS_PRODUCT_DECISION** | ver §19 (A/B/C) |

**Correção obrigatória sobre F7 (`lineup_matches`)**: `club_id` aqui é **só tenancy da LINHA** (COMPOSITE_PK ou SURROGATE). O **JSON dos 11 jogadores permanece editorial e SEM `person_id`** — a decisão F7 é justamente que **`person_id` NUNCA entra em cada slot do jsonb**; a identidade canônica futura mora em `player_match_appearances`/provenance/`people`, nunca no slot. Não se toca no JSON, não se toca na F7. (Não há eixo `UNIQUE(person_id)` aqui — diferente de career/guess/squad, que têm a coluna.) **Esta correção supera a frase imprecisa do relatório M1 `28_etapa_m1_report.md` §16-ter** ("person_id vive dentro do jsonb de slot"), que dizia o oposto da F7 e deve ser lida com esta correção — o doc 28 já está commitado (`2a8e152`) e fica fora do escopo deste commit, então a correção fica registrada aqui (padrão de nota de supersessão, igual ao doc 09).

## 13. Progress/ranking — estratégia por tabela

- **COMPOSITE_PK** (club_id entra na PK): user_game_item_progress, quiz_question_progress, quiz_active_session, lineup_match_progress, career_path_progress, arena_selected_content, arena_achievements, ticket_checkin_decisions, player_identity_results, tactical_identity_results (PKs (user, ...) ou user_id ganham club_id).
- **TENANT_COLUMN_ONLY** (só coluna + filtro na RPC, PK uuid já não colide): score_events, ticket_orders, store_orders, supporter_memberships.
- **NEEDS_CLUB_SCOPE em UNIQUE**: match_lineup_votes, tickets (índice parcial).
- **INHERITS via FK** (não ganha club_id próprio): store_order_items, passport_attendances, passport_memorable_matches, notification_deliveries.
- **Regra de cadeia**: club_id tem de viajar TODA a cadeia — conteúdo → progress → user_game_item_progress → score_events → RPC. Propagar só numa ponta reabre o vazamento no meio.

## 14. `arena_record_score` (item 19 do pedido / §8 aqui)

SQL real auditado (`supabase/arena_ranking.sql`). Hoje: `security definer`, valida `item_id` por `exists(select 1 from <content> where id = p_item_id)` **sem club_id**, faz upsert em `user_game_item_progress` (PK user/game/item) com `score = greatest(prev, candidate)` (monotônico, anti-replay via `v_is_replay` + `v_cap`), e insert append-only em `score_events`. **Idempotência/dedupe**: a PK composta + `greatest()` garante que reabrir/repetir nunca re-credita do zero. **Futuro (M3 introduz o `p_club_id`; M2.2B endurece a assinatura — não alterado agora)**: ganhar `p_club_id`, `exists(... where id = p_item_id and club_id = p_club_id)`, club_id nas 2 escritas, e as agregações de ranking (`arena_ranking`/`arena_my_rank`/`arena_user_detail`) ganham `where/group by club_id`. Sem isso, dois clubes somam pontos no mesmo ranking. Na M2.2A a RPC não pode quebrar — mantém o contrato antigo assumindo Goiás enquanto só há 1 tenant.

## 15. Membership (CRITICAL)

`supporter_memberships` — PK `id uuid`, index `(user_id)`, RLS OWNER (select/insert próprios, sem update/delete), `get_my_membership()` security definer faz `where user_id = auth.uid() order by created_at desc limit 1` **sem filtro de clube**. Num Supabase compartilhado, com um 2º clube, isso devolveria a assinatura mais recente de QUALQUER clube — vazamento de status de sócio. Estratégia: **TENANT_COLUMN_ONLY** (club_id na tabela) + contrato `get_my_membership(p_club_id)` explícito. Não existe `APP_CLUB` dentro do Postgres — nunca confiar em "o servidor sabe qual flavor chamou". Dívida correlata: `arena_ranking.is_member` está hardcoded `false` (comentário obsoleto — membership já é real; conserto separado, M3).

## 16. Notifications

- `user_notification_tokens`: `fcm_token` UNIQUE — **KEEP_GLOBAL** (device global). Não ganha club_id.
- `user_notification_preferences`: PK user_id — **provavelmente vira `(user_id, club_id)`**. `matches_enabled`/`tickets_enabled` são por-clube: "mesmo usuário, clubA jogos ON, clubB jogos OFF" é estado perfeitamente válido. Entra no design de KEY_SCOPE/tenant (não é só ROW_SCOPE) — o token segue GLOBAL, mas as PREFERÊNCIAS não.
- `match_monitor_sessions`: `match_id text` PK, service_role — depende da proveniência do match_id (§18).
- `notification_events`: `UNIQUE(event_type, dedupe_key)` — **NEEDS_REDESIGN**: dedupe é GLOBAL; eventos de clubes diferentes com dedupe_key colidente se anulariam. A dedupe_key precisa incluir club_id (ou o namespace do provider ser provado globalmente único). `GOIAS_TEAM_ID=1863` + copy `'GOOOOL DO GOIÁS!'` + canal `goias_matches` continuam hardcoded (M3/M4).
- `notification_deliveries`: `UNIQUE(event_id, token_id)` de uuids — **KEEP_GLOBAL**, herda do evento.
- **Sem tópicos FCM** (entrega por token direto) — mais fácil de estender por clube que tópicos seriam.

## 17. Store / `order_number`

`order_number` = `'GOI-' || ano || sequência global` (`generate_store_order_number()` + `store_order_number_seq`). Unicidade por sequência é **global → KEEP_GLOBAL**, não vira `unique(club_id, order_number)`. O prefixo `'GOI-'` é o único acoplamento — em M3/M4 vem de `ClubConfig.integrations.orderPrefix`, não agora. `store_orders` ganha `club_id` (ROW_SCOPE, TENANT_COLUMN_ONLY); `store_order_items` herda via `order_id` (FK real). `create_store_order` roda como caller (sem security definer) — a policy de insert já garante `auth.uid()`; só precisa passar a gravar club_id.

## 18. Match / vote / session IDs (item 23)

`match_id` texto aparece em: lineup_match_progress, ticket_checkin_decisions, ticket_orders, tickets, match_lineup_votes, match_monitor_sessions, e passport_matches (id próprio `pe_...`). **Proveniência**: partidas ao vivo vêm do **OneFootball** (slug `goias-1863`, team id `1863` — confirmado no Worker `src/football/_lib/config.ts`, com `isGoias` no normalizado). O passaporte usa id próprio `pe_...`. **`match_id` NÃO tem namespace globalmente provado único entre clubes** (`externalKeyProvenance.match_id.globallyUniqueProven = false`). Consequência: `club_id` precisa entrar na key dessas tabelas (ou a origem tem de ser provada globalmente única antes de confiar) — **nunca presumir que ids de provider são iguais/distintos entre clubes sem provar**. `crowd_lineup(p_match_id)` agrega por match_id sem club — colisão misturaria as escalações da torcida de 2 clubes.

## 19. Passaporte — design A/B/C (NÃO implementar)

`passport_matches` é a única `NEEDS_PRODUCT_DECISION`: schema **assimétrico** (`opponent`/`goias_is_home`/`goias_score`/`opponent_score`) + 2 FKs reais (`passport_attendances`, `passport_memorable_matches`). Já carrega, em paralelo, `home_team`/`away_team`/`home_score`/`away_score` (meio caminho pro simétrico). Três caminhos, recomendação separada, sem implementar:

- **A — semântica "our club"**: `club_id uuid` + renomear `goias_*` → `club_is_home`/`club_score`/`opponent...`. Menor migração; mantém o formato "nosso clube + adversário". Custo: perde simetria; consultas cross-clube (clássico entre 2 clubes cadastrados) ficam esquisitas.
- **B — modelo futebolístico genérico**: `home_club_id`/`away_club_id` (ou home/away team) + `home_score`/`away_score` + `club_id` do PRODUTO/passaporte (a qual passaporte a linha pertence). Simétrico como a tabela canônica `matches`. Mais migração (reescreve colunas + backfill de `goias_is_home` → home/away), mas é o modelo correto a longo prazo e reaproveita o que a fundação canônica já fez.
- **C — consumir mais da canônica `matches`**: `passport_matches` mantém só metadata editorial/passaporte (venue, notas, source) e referencia `matches` pra placar/mandante. Menos duplicação, mas acopla o passaporte à cobertura da canônica (que hoje não cobre 2000–2026 inteiro).

**Recomendação TÉCNICA (não é a decisão)**: **B** a longo prazo (simétrico, alinhado à canônica), com **A** como ponte se precisar de migração mínima primeiro. **C** só quando a canônica `matches` cobrir o histórico do passaporte.

**Status: PENDENTE DE DECISÃO DE PRODUTO — NÃO escolher B definitivamente ainda.** O Passaporte já tem **1697+ registros reais** (partidas 2000–2026) + 2 FKs dependentes → impacto grande de compatibilidade. **Nenhuma migration de passport entra na M2.2A sem aprovação de PRODUTO separada.** A recomendação técnica acima não substitui essa decisão.

## 20. Composite PK vs surrogate — por tabela de conteúdo

Comparação (impacto em repos/upserts/RPC/FK/progress/ranking/seed/back-compat), **recomendação individual, nunca uma solução única pra todas**:

| tabela | A: `PRIMARY KEY (club_id, id)` | B: `row_id uuid PK` + `unique(club_id, id)` | recomendação |
|---|---|---|---|
| career_players | id continua sendo a chave de negócio; RPC `exists(... id and club_id)` direto | surrogate desnecessário; nada referencia por FK | **A** (mais simples, sem FK externa) |
| guess_players | idem | idem | **A** |
| squad_members | idem; sem cadeia de progresso | idem | **A** |
| lineup_matches | idem | idem | **A** |
| quiz_questions | idem | idem | **A** |
| passport_matches | 2 FKs reais apontam pra `id` — mudar a PK obriga as FKs a virarem `(club_id, id)` compostas nos 2 dependentes | surrogate `row_id` deixaria as FKs por `id` mas exigiria `id` único global (contradiz multi-club) | **decidir junto com §19** — se B (simétrico), a PK provavelmente vira surrogate + unique natural; se A, as 2 FKs viram compostas |

**Nunca** `namespace:id` (`'goias:tadeu'`) — quebraria progress/ranking/RPC/usuários. As tabelas de progresso que referenciam por convenção (item_id/match_id/player_id) acompanham a escolha do conteúdo: com PK composta `(club_id, id)`, o par `(club_id, item_id)` entra na PK do progresso.

## 21. Backfill Goiás (item 25)

**Design, não executado** (M2.1 não roda `db query`). Regra: como `clubs` tem exatamente 1 linha (Goiás), toda linha existente de toda tabela TENANT_* recebe `club_id = 4c16340d-300c-5ab2-903f-17519db9b146` (100% das linhas). **Precondition**: `clubs` = 1 (confirmado pela fundação). **Postcondition**: `club_id not null` em todas as linhas TENANT_*, 0 órfã. **Contagens exatas por tabela**: deferidas pra a 1ª subetapa da **M2.2A** (`npx supabase db query`, read-only), antes de qualquer migration — nunca chutadas aqui.

## 22. Roadmap faseado — a ordem é o que importa (correção obrigatória)

**Não dá pra transformar `PRIMARY KEY(user_id, game_id, item_id)` em `PRIMARY KEY(club_id, user_id, game_id, item_id)` nem obrigar as RPCs a `p_club_id` ANTES do app publicado mandar `club_id`.** Por isso a sequência é dividida em 4 fases (nomes podem variar; a ORDEM não):

### M2.2A — Additive Tenant Schema (DB primeiro, SÓ compatível)
- `add column club_id uuid NULLABLE default <goias>` em todas as TENANT_*; backfill `= <goias>`; `FK references clubs(id)`; indexes auxiliares.
- **NÃO** remove PK/UNIQUE antiga que quebre o client atual; **NÃO** endurece assinatura de RPC de forma incompatível. Se uma RPC mudar aqui, continua aceitando o contrato antigo (assume Goiás enquanto só há 1 tenant real).
- **Objetivo: `old app + new DB` = funciona.** Tudo `BACKWARD_COMPATIBLE`.

### M3 — Tenant-Aware Runtime (Flutter passa a mandar club_id)
- Consumidores migram pra `ClubConfig.identity.canonicalClubId`; repositories filtram `.eq('club_id', activeClubId)`; RPCs novas recebem `p_club_id`; writes gravam `club_id`; colapsar os 3 `isGoias` → `isOurClub(config)`, `Team.goiasId` → `ClubConfig.integrations.oneFootballTeamId`.
- DB ainda mantém compatibilidade com a versão antiga (PK/UNIQUE ainda as antigas).
- **Objetivo: `new app + transitional DB` = funciona E `old app + transitional DB` = funciona.** `REQUIRES_DUAL_READ_WRITE`.

### M2.2B — Tenant Enforcement (SÓ depois do app novo implantado/adotado)
- Trocar PKs → compostas/surrogate (club_id na chave); trocar UNIQUEs (`person_id` → `(club_id, person_id)`; match_lineup_votes/tickets etc.); NOT NULL definitivo; endurecer assinaturas de RPC (`p_club_id` obrigatório); remover compatibilidade legacy; endurecer constraints/RLS.
- **Objetivo: o DB agora PODE exigir tenancy explicitamente.** `REQUIRES_APP_DEPLOY_FIRST` — gate: app que manda club_id publicado e adotado.

### M4 — Flavors / integrações externas
- Pipeline de flavor (Android/iOS/web), Worker generalizado por club_id, avaliar onboarding de um 2º clube real (decisão de produto separada).

`passport_matches` tem sua própria decisão (§19) ANTES de qualquer enforcement. `notification_events.dedupe_key` (redesign) entra em M2.2B.

## 23. Compatibilidade com app instalado (itens 26/27) — gate obrigatório

O usuário que já tem progresso/ranking/membership/passaporte/votos/pedidos **não pode perder dado**. Por fase:
- **M2.2A** (coluna nullable → backfill → not null+FK): `BACKWARD_COMPATIBLE` — app publicado ignora a coluna, continua funcionando (club_id default Goiás). **`old app + new DB`**: ok.
- **M3** (app tenant-aware): `REQUIRES_DUAL_READ_WRITE` — **`new app + transitional DB`** e **`old app + transitional DB`**: ambos ok (club_id redundante mas inofensivo enquanto a PK for a antiga).
- **M2.2B** (PK/UNIQUE compostas + RPC endurecida): `REQUIRES_APP_DEPLOY_FIRST` — é o ponto onde um app antigo quebraria; só entra depois do app novo publicado e adotado.

**Contrato de compat de RPC na M2.2A** (documentar, não decidir implementação): `arena_record_score` / `get_my_membership` / `crowd_lineup` / `passport_*` / `create_store_order` **não podem quebrar**. Estratégia transitória: RPC legacy assume Goiás enquanto só há 1 tenant real; RPC nova recebe `p_club_id` explícito (overload/versionamento OU um default que resolve pro único clube). **Regra dura**: quando existir um 2º clube, **nenhuma chamada pode depender do default Goiás** — o gate de M2.2B/M4 remove o fallback.

**Rollout específico do `supporter_memberships` (CRITICAL)**: M2.2A adiciona `club_id` + backfill Goiás → M3 o repository chama membership com `activeClubId` (e `get_my_membership(p_club_id)`) → M2.2B remove o contrato antigo sem club_id. Nunca quebrar o app publicado abruptamente.

## 24. Proposta de rollout (nomes)

`M2.2A — Additive Tenant Schema` → `M3 — Tenant-Aware Runtime` → `M2.2B — Tenant Enforcement` → `M4 — Flavors / external integrations`. Cada uma exige autorização própria; a M2.2A (aditiva, sem risco) só começa depois desta revisão da M2.1. **Release gate**: quando existir o 1º 2º flavor, todo pipeline passa `APP_CLUB=<clube>` explícito — nunca depender do default Goiás.

## 25. Migrations propostas nesta rodada

**ZERO.** M2.1 termina com DESIGN aprovado antes de tocar o banco. `0 db push`, `0 DML`, `0 migration gerada`.

## 26. Tooling

- `tooling/multiclub/audit_multiclub_tenant_constraints.mjs` — read-only, verifica cada padrão citado contra o `.sql` real (staleness guard), classifica 32 tabelas nos 2 eixos + UNIQUE + estratégia, monta cadeias de progresso, RLS matrix + o modelo de 3 conceitos (userSecurity/applicationTenantFilter/databaseEnforcedTenantIdentity), proveniência de match_id, plano de backfill, roadmap faseado (M2.2A/M3/M2.2B/M4), contrato de compat de RPC e a decisão pendente do passaporte. Outputs: `multiclub_tenant_constraints_audit.json` + `multiclub_tenant_constraints_stats.json` (reproduzíveis byte a byte).
- `tooling/multiclub/test_multiclub_tenant_constraints.mjs` — **28 testes**, 0 falha (22 + 6 dos endurecimentos de fechamento: invariante 32/PROGRESS=18, roadmap faseado, F7 preservada, RLS 3-conceitos, passaporte pendente, prefs por-clube).

## 27. JS total

`tooling/multiclub/test_*.mjs` completo: **547 passaram, 0 falharam** (519 pós-M1 + 28 da M2.1).

## 28. Flutter status

**0 arquivo Dart tocado na M2.1** (design/auditoria puro). Baseline da M1 mantido: `flutter analyze` **0 issues**, `flutter test` **769 passed / 1 skip**.

## 29. `git diff --stat`

Só o arquivo pré-existente fora de escopo:
```
 lib/features/store/presentation/widgets/store_entry_card.dart | 2 +-
```
Os artefatos da M2.1 são todos novos (untracked): 2 scripts, 2 JSON, este relatório.

## 30. `git status`

```
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, nunca staged)
?? _competitions_pkg/                                              (excluído)
?? migration_dump.txt                                              (excluído)
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (pré-existente)
?? data_export/goias/player_reconciliation/multiclub_tenant_constraints_audit.json
?? data_export/goias/player_reconciliation/multiclub_tenant_constraints_stats.json
?? tooling/multiclub/audit_multiclub_tenant_constraints.mjs
?? tooling/multiclub/test_multiclub_tenant_constraints.mjs
?? docs/multiclub/29_etapa_m2_1_report.md
```

---

## Limites respeitados

- 0 migration gerada, 0 `db push`, 0 DML, 0 commit da M2, 0 `git push`.
- 0 consumidor Flutter migrado — nenhum repository começou a filtrar club_id (a coluna nem existe).
- Nenhum 2º clube nomeado/cadastrado/pressuposto — `clubRegistry` = 1 (goias).
- F1-F7 e M1 semanticamente intactas — `club_id` é tenancy, ortogonal a `person_id`/feature id.
- Ids legados preservados — nenhuma proposta de renomear/namespacing.

**PARADO PARA REVISÃO. M2.2A (additive migrations) NÃO iniciada — aguardando revisão do roadmap corrigido (M2.2A → M3 → M2.2B) antes de tocar o Supabase.**

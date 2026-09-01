# 06 — Auditoria do Banco de Dados (Supabase)

> Cobertura: todos os 31 `.sql` soltos, os 9 arquivos em `migrations/`, as 5 Edge Functions, `config.toml` e `MIGRATIONS.md`. Gerado em 2026-09-01.

## 1. Contexto (`MIGRATIONS.md`)

Desde 2026-08-30, toda mudança de schema/RPC/policy deve ir por `supabase/migrations/<timestamp>_nome.sql` (convenção Supabase CLI) — nunca mais editar direto os scripts soltos em `supabase/*.sql`. Os scripts soltos continuam como referência histórica de como cada tabela nasceu e **não** foram retroativamente convertidos em migrations. Reconstruir um ambiente do zero exige rodar os scripts soltos primeiro (em ordem de dependência) e depois as migrations em ordem cronológica. O CLI nunca foi de fato executado a partir deste ambiente de dev — as migrations foram escritas manualmente no formato certo mas nunca aplicadas via `supabase db push` localmente.

## 2. `config.toml`

Mínimo — só `project_id = "yonozsdgyrhgqrvydbnr"`. As seções `[api]`/`[db]`/`[studio]`/`[auth]` que um `supabase init` normal geraria foram deliberadamente omitidas (o projeto não usa `supabase start`/Docker local). **Nenhuma config de bucket de Storage ou de auth está declarada em lugar nenhum do repo** — isso só existe no dashboard ao vivo.

## 3. Storage

Única referência a Storage em todo o repo: `supabase/functions/delete-account/index.ts:57,60` chama `adminClient.storage.from('avatars').list(uid)`/`.remove(paths)` pra apagar avatar do usuário na exclusão de conta. **Nenhum SQL cria o bucket `avatars` ou qualquer policy de `storage.objects`** — foi criado direto no dashboard. **Gap pro plano de migração**: bucket + sua RLS precisam ser recuperados do dashboard antes de qualquer plano de migração ser considerado completo.

## 4. Tabelas não rastreadas (criadas fora do repo)

Duas tabelas são referenciadas o tempo todo mas **não têm `CREATE TABLE` em lugar nenhum do repo**:
- **`public.profiles`** — referenciada em `account_deletion_cascade_check.sql`, `profiles_signup_fields.sql` (adiciona `marketing_opt_in`, `cpf` + índice único, RPC `cpf_is_taken()`), `signup_audit_introspection.sql`, `arena_ranking.sql`/`passport_esmeraldino_functions.sql` (join pra `full_name`/`avatar_url` em rankings).
- **`public.user_addresses`** — referenciada só em `account_deletion_cascade_check.sql` (checagem de FK cascade).

Ambas foram criadas direto no dashboard. Existe também um trigger `handle_new_user` em `auth.users` mencionado em comentário, cuja definição **não está no repo**.

**Ação recomendada**: puxar esses 3 objetos ao vivo (pg_dump ou export de schema do dashboard) antes de fechar o plano de migração multi-clube.

## 5. Inventário tabela a tabela

### Identidade / ciclo de vida de conta
- **`account_deletion_cascade_check.sql`** — sem tabela nova; blocos `DO` idempotentes forçando FKs de `profiles.id`/`user_addresses.user_id` pra `ON DELETE CASCADE`. Infraestrutura global.
- **`profiles_signup_fields.sql`** — `ALTER TABLE profiles ADD marketing_opt_in`; índice único parcial em `cpf`; RPC `cpf_is_taken(text)` (`SECURITY DEFINER`).
- **`cleanup_unconfirmed_signups_cron.sql`** — RPC `list_unconfirmed_signups_for_cleanup()` (`SECURITY DEFINER`, só `service_role`); cron horário → Edge Function homônima.
- **`signup_audit_introspection.sql`** — script de diagnóstico read-only, não define schema.

### Notificações (push)
- **`notifications.sql`** → `user_notification_tokens` (tokens FCM, único por token, multi-device), `user_notification_preferences` (opt-out), `match_monitor_sessions` (1 linha por fixture monitorado, `service_role`-only), `notification_events` (append-only, único em `(event_type, dedupe_key)`), `notification_deliveries` (registro de envio por destinatário). RLS de owner nas tabelas de usuário; as 3 operacionais são `service_role`-only.
- **`notifications_cron.sql`** — schema `private` + `private.notifications_service_role_key()` (lê secret do Vault); agenda 3 cron jobs (ver §8).

### Arena (minigames) — conteúdo + progresso
- **`quiz_questions`** — id, difficulty (`torcedor`/`esmeraldino`/`fanatico`), question, options jsonb, correct_index, sort_order. Leitura pública. Conteúdo Goiás.
- **`career_players`** — id, answer, accepted_answers, club_career jsonb, national_teams jsonb, sort_order. Leitura pública. Migration `20260831020000_career_players_revalidated_v2.sql` adiciona `aggregate_stats jsonb` e re-seeda 30 jogadores.
- **`guess_players`** — id, name, aliases jsonb, `data_status` (`verified`/`review`/`incomplete`), `photo_key`. Leitura pública.
- **`lineup_matches`** — id, competition, season, formation, `formation_confidence`, `lineup` jsonb curado à mão. Leitura pública.
- **`arena_progress.sql`** → 6 tabelas todas RLS'd por `auth.uid() = user_id`: `quiz_question_progress`, `quiz_active_session`, `lineup_match_progress`, `career_path_progress`, `arena_selected_content`, `arena_achievements`.
- **`arena_ranking.sql`** — **removeu o sistema antigo de pontuação** (`arena_leaderboard`, `arena_save_best`, tabela `arena_scores`). Cria `user_game_item_progress` (score definitivo por item, PK `(user_id, game_id, item_id)`, sem policy de escrita do cliente) e `score_events` (histórico append-only). RPC central `arena_record_score(...)` (`SECURITY DEFINER`) valida que o `item_id` existe de verdade na tabela de conteúdo correspondente, calcula pontos server-side com teto anti-replay. **Hardcoda os 4 game_ids** (`quiz`, `career_path`, `guess_player`, `lineup`) — **principal ponto de atrito multi-tenant** desta função.
- **`player_identity_results.sql`** / **`tactical_identity_results.sql`** — resultado de "teste de perfil" (PK `user_id`, upsert de última resposta), RLS de owner padrão. Genéricas, o `answers` jsonb não referencia dado de clube diretamente além de ids de arquétipo/jogador.
- **`crowd_lineup.sql`** → `match_lineup_votes` (PK `(match_id, user_id)`). RPC `crowd_lineup(match_id)` (`SECURITY DEFINER`, `sql`) agrega votos anônimos. Mecanismo genérico, `match_id` é só texto.
- **`checkup.sql`** — diagnóstico read-only (union-all de validações), confirma lista de tabelas esperada e que `passport_matches` deveria ter exatamente 1697 linhas.

### Passaporte Esmeraldino
- **`passport_esmeraldino.sql`** → `venues` (catálogo de estádio, leitura pública), `passport_matches` (catálogo 2000–2026, `id` é chave estável `pe_xxxxxxxxxxxxxxxx`, leitura pública), `passport_attendances` (PK-less único `(user_id, match_id)`, **só select** pro owner — escrita só via RPC), `passport_sync_runs` (log operacional, `service_role`-only).
- **`passport_esmeraldino_functions.sql`** — RPCs `passport_seasons()`, `passport_matches_for_year()`, `passport_summary()`, `passport_save_attendances(jsonb)`, `passport_my_attendances_for_year()`, `passport_ranking()`, `passport_my_rank()`. Todas `SECURITY DEFINER`. Sistema de ranking totalmente separado do Arena.
- **`passport_trajectory.sql`** — `passport_memorable_matches` (PK `user_id`, select-only). RPCs `passport_set_memorable_match`, `passport_attended_matches`, `passport_stadium_summary`.
- **`passport_esmeraldino_import.sql`** (797KB, só dados) — INSERTs do dataset de 1.697 partidas.
- **Migration `20260831010000`** — nova RPC `passport_attendance_breakdown()`.
- **Migration `20260831030000`** — RPCs de trajetória ganham `p_user_id` opcional (visualizar trajetória de outro usuário via ranking).
- **Migration `20260831040000_passport_venue_audit.sql`** (996KB) — `ALTER TABLE passport_matches ADD venue_confidence, venue_audit_status`; insere ~160 estádios; `UPDATE` em massa corrigindo data/status/placar/venue_id/mando de campo pra todo o dataset (ver `07_data_coverage.md` pra números exatos).
- **Migration `20260831050000`** — rename cosmético de um venue (Serrinha → Hailé Pinheiro, sem sufixo).

### Conteúdo do clube (editorial)
- **`squad_members.sql`** → `squad_members` (id text PK, shirt_number, position, position_group, club_history jsonb, instagram_url). Leitura pública.
- **`squad_members_instagram.sql`** / **`squad_members_position_groups.sql`** / **`squad_members_seed.sql`** (59KB) — dados/colunas complementares, 31 jogadores atuais seedados.
- **`club_board.sql`** → `club_board_sections`, `club_board_members` (FK cascade). Leitura pública, seed inline (diretoria do Goiás).
- **`club_transparency.sql`** → `club_transparency_topics`, `club_transparency_documents` (FK cascade). Leitura pública, links de PDF do goiasec.com.br seedados inline.
- **`membership_content.sql`** (80KB) → `membership_faq_categories`, `membership_faq_items`, `membership_regulation_versions` (id/version/effective_at espelham uma constante Dart — comentário avisa que os dois precisam ser sincronizados manualmente). Conteúdo 100% "Sócio Esmeralda" — prosa específica do clube, não só dado.

### Comércio / sócio / ingressos
- **`store_orders.sql`** — sequence + `generate_store_order_number()` (**prefixo "GOI" hardcoded**, específico do clube), `store_orders` (snapshots jsonb, imutável), `store_order_items`. RPC `create_store_order(...)`.
- **`delivery_addresses.sql`** → `delivery_addresses`, RLS full CRUD de owner, triggers de endereço-padrão. Totalmente genérica.
- **`supporter_memberships.sql`** → `supporter_memberships` (plan_id/plan_name, started_at/expires_at). RPC `get_my_membership()` calcula `is_active` server-side.
- **Migration `20260830220002_subscribe_to_plan_rpc.sql`** — nova RPC `subscribe_to_plan(p_plan_id)` (`SECURITY DEFINER`, lock advisory por usuário, **hardcoda os 6 ids/nomes de plano** — `nossa-gente`, `nossa-historia`, `nossa-garra`, `nossa-gloria`, `nossa-familia`, `plano-vip` — espelhando um catálogo Dart, 30 dias fixos). **Segundo maior ponto de atrito multi-tenant.**
- **`tickets.sql`** → `ticket_checkin_decisions`, `ticket_orders`, `tickets` (índice único parcial limitando um ticket de check-in ativo por usuário+partida). Migration `20260831000000` adiciona `refunded_at`.

### Migrations de hardening/bugfix (sem tabela nova)
- **`20260830220000_baseline_marker.sql`** — marcador no-op.
- **`20260830220001_arena_record_score_item_validation.sql`** — já aplicado, fecha exploit de `item_id` fabricado; corpo idêntico já vive em `arena_ranking.sql`.

## 6. Edge Functions

| Função | Propósito | Chamadas externas | Cron | Específica do Goiás? |
|---|---|---|---|---|
| `cleanup-unconfirmed-signups` | Apaga `auth.users` não confirmado há >48h | Nenhuma (só Admin API) | Horária | Não — genérica, reaproveitável |
| `delete-account` | Exclusão de conta self-service | Storage + Admin API | Nenhum | Não — genérica (confirmar convenção de bucket por tenant) |
| `notifications-sync-and-check-access` | Acha próximo jogo via Worker, mantém `match_monitor_sessions`, cria evento de abertura de acesso 48h antes | `GET .../api/football/team/goias` (URL hardcoded) | */30 min | **Sim** — Worker URL + rota `/team/goias` hardcoded |
| `notifications-poll-live-match` | Polling de partida ao vivo, detecta gol/fim de jogo | `GET .../api/football/fixtures/onef-<id>`, `GOIAS_TEAM_ID = 1863` hardcoded | */1 min | **Sim** — mesma URL + id numérico OneFootball hardcoded |
| `notifications-dispatch` | Envia push via FCM v1, respeita preferências, mensagem sócio-aware | `fcm.googleapis.com` | */5 min (safety net) | Mecanismo genérico; copy da mensagem ("GOOOOL DO GOIÁS!") e `channel_id: 'goias_matches'` hardcoded |

## 7. Inventário consolidado de tabelas

```
club_board_sections             — catálogo de seções da diretoria          — RLS: sim (leitura pública) — club-specific — adicionar club_id
club_board_members               — pessoas por seção                        — RLS: sim (leitura pública) — club-specific — adicionar club_id
club_transparency_topics         — tópicos de transparência                 — RLS: sim (leitura pública) — club-specific — adicionar club_id
club_transparency_documents      — PDFs por tópico                          — RLS: sim (leitura pública) — club-specific — adicionar club_id
squad_members                    — elenco atual                             — RLS: sim (leitura pública) — club-specific — adicionar club_id
quiz_questions                   — trivia do Quiz do Verdão                 — RLS: sim (leitura pública) — club-specific — adicionar club_id
career_players                   — dataset "Adivinhe o Jogador"             — RLS: sim (leitura pública) — club-specific — adicionar club_id
guess_players                    — catálogo "Quem Vestiu o Manto"           — RLS: sim (leitura pública) — club-specific — adicionar club_id
lineup_matches                   — dataset "Adivinhe a Escalação"           — RLS: sim (leitura pública) — club-specific — adicionar club_id
membership_faq_categories        — categorias FAQ Sócio Esmeralda           — RLS: sim (leitura pública) — club-specific — adicionar club_id
membership_faq_items             — itens FAQ (rich text)                    — RLS: sim (leitura pública) — club-specific — adicionar club_id
membership_regulation_versions   — regulamento versionado                   — RLS: sim (leitura pública) — club-specific — adicionar club_id
venues                           — catálogo de estádios (cross-partida)     — RLS: sim (leitura pública) — global-candidate — manter global, mas considerar escopo por clube se listas divergirem
passport_matches                 — histórico Goiás 2000–2026 (1697 linhas)  — RLS: sim (leitura pública) — club-specific — adicionar club_id
passport_attendances             — presença auto-declarada                  — RLS: sim (só select, RPC escreve) — dado de usuário ligado a partida club-specific — adicionar club_id via FK
passport_sync_runs               — log de import/sync                       — RLS: sim (sem policies = service-role) — operacional — adicionar club_id
passport_memorable_matches       — "partida mais marcante" escolhida        — RLS: sim (só select) — adicionar club_id via FK
user_game_item_progress          — score cross-game Arena por user/game/item — RLS: sim (só select, RPC escreve) — mecanismo global, mas namespace de game_id é compartilhado — revisar: club_id ou namespacing por tenant
score_events                     — histórico append-only Arena              — RLS: sim (só select) — mesma ressalva acima — revisar
match_lineup_votes               — votos da Escalação da Torcida            — RLS: sim (full owner CRUD) — dado de usuário, partidas club-specific — adicionar club_id
user_notification_tokens         — tokens FCM por usuário                   — RLS: sim (full owner CRUD) — global-candidate — manter global
user_notification_preferences    — opt-in/out de push                       — RLS: sim (full owner CRUD) — global-candidate — manter global
match_monitor_sessions           — estado de polling ao vivo (service-role) — RLS: sim (sem policies) — club-specific (1 clube de fixtures) — adicionar club_id
notification_events              — eventos detectados (service-role)        — RLS: sim (sem policies) — club-specific — adicionar club_id
notification_deliveries          — registro de entrega por destinatário     — RLS: sim (sem policies) — mecanismo global — manter global
quiz_question_progress           — histórico de resposta por usuário        — RLS: sim (full owner CRUD) — mecanismo global, ids de pergunta club-specific — revisar
quiz_active_session               — sessão de quiz em progresso              — RLS: sim (full owner CRUD) — revisar
lineup_match_progress             — estado de progresso da Escalação        — RLS: sim (parcial) — revisar
career_path_progress              — estado de progresso do Adivinhe o Jogador — RLS: sim (parcial) — revisar
arena_selected_content            — última partida/jogador visto por jogo   — RLS: sim (parcial) — revisar
arena_achievements                — conquistas desbloqueadas                — RLS: sim (select/insert) — revisar
player_identity_results           — resultado do "Que craque..." (1/user)   — RLS: sim (full owner CRUD) — arquétipos club-specific — revisar
tactical_identity_results         — resultado da "Identidade Futebolística" — RLS: sim (full owner CRUD) — ids de técnico club-specific — revisar
delivery_addresses                — endereços de entrega da Goiás Store     — RLS: sim (full owner CRUD) — global-candidate — manter global
store_orders                      — pedidos da loja                         — RLS: sim (select/insert) — número do pedido tem prefixo "GOI" hardcoded — revisar
store_order_items                 — itens por pedido                        — RLS: sim (select/insert) — manter global
supporter_memberships             — assinaturas Sócio Torcedor              — RLS: sim (só select, RPC escreve) — `subscribe_to_plan()` hardcoda 6 planos Goiás — revisar (catálogo de plano precisa virar tabela ou ser parametrizado por clube)
ticket_checkin_decisions          — decisão de check-in por partida (mock)  — RLS: sim (full owner CRUD) — ids de partida club-specific — revisar
ticket_orders                     — pedidos de ingresso mock                — RLS: sim (select/insert/update) — revisar
tickets                           — ingressos emitidos                      — RLS: sim (select/insert/update) — revisar
profiles                          — perfil do usuário — NÃO DEFINIDA NO REPO — RLS: desconhecida — global-candidate — puxar definição ao vivo primeiro
user_addresses                    — endereço residencial — NÃO DEFINIDA NO REPO — RLS: desconhecida — global-candidate — puxar definição ao vivo primeiro
arena_scores                      — REMOVIDA (dropada por arena_ranking.sql, leaderboard legado) — n/a — só histórico, não recriar
```

**Nota importante sobre as tabelas marcadas "revisar"**: elas são estruturalmente genéricas (chaveadas por `user_id` + `game_id`/`match_id`/`item_id` texto), mas todo `game_id`/`item_id`/`plan_id` em uso hoje vem de um catálogo de conteúdo exclusivamente Goiás. A multi-tenancy depende menos de adicionar `club_id` isoladamente nessas tabelas de progresso e mais de escopar por `club_id` primeiro as tabelas de conteúdo que elas referenciam, propagando esse escopo pelas RPCs que fazem join com elas (`arena_record_score`, `subscribe_to_plan`, o prefixo do número de pedido em `create_store_order`, e as duas Edge Functions de notificação com Worker URL/team id hardcoded).

## 8. Cron jobs (`pg_cron` + `pg_net`)

| Job | Agenda | Chama |
|---|---|---|
| `cleanup-unconfirmed-signups` | `0 * * * *` (horária) | Edge Function `cleanup-unconfirmed-signups` |
| `notifications-sync-and-check-access` | `*/30 * * * *` | Edge Function homônima |
| `notifications-poll-live-match` | `* * * * *` (todo minuto) | Edge Function homônima |
| `notifications-dispatch-safety-net` | `*/5 * * * *` | Edge Function `notifications-dispatch` |

Todos autenticam via secret do Vault (`notifications_service_role_key`), nunca hardcodeado em SQL.

## 9. Gaps explícitos — não verificáveis só pelo repo

1. Schema de **`public.profiles`** e **`public.user_addresses`** (colunas, constraints, RLS) — só existem no dashboard.
2. Trigger **`handle_new_user`** em `auth.users` — corpo não está no repo.
3. Bucket de Storage **`avatars`** — sem SQL de criação/policy no repo.
4. Se existem outros buckets de Storage — nada no SQL sugere, mas só confirmável no dashboard.
5. `config.toml` não define auth/rate-limit/redirect-URL — provavelmente só no dashboard também.

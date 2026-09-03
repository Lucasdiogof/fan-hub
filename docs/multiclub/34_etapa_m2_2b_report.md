# M2.2B — Tenant-Aware Physical Keys, Constraints & Enforcement

Data: 2026-09-02
Status: **M2.2B-A APLICADO (4 bridge migrations pushed, 50/50 local=remote, 18 tenant-aware unique indexes ativos, TODAS as chaves legacy preservadas, 0 dado alterado). 0 git push, 0 Edge/Worker deploy, 0 M3.4, 0 M2.2B-B, 0 M4, 0 segundo clube. `SECOND_CLUB_BLOCKED=true`.**

Duas fases documentadas aqui: (1ª rodada) AUDIT → DESIGN → BRIDGE MIGRATIONS locais → correção; (2ª rodada) **APLICAÇÃO da M2.2B-A** com preflight + revalidação ao vivo + push + validação pós-push. Nenhum 2º clube cadastrado (`clubRegistry` = 1).

## APLICAÇÃO M2.2B-A (2026-09-02)
- **Preflight**: HEAD `35357bd`, 50 local / 46 remote / 4 pending, dry-run = exatamente as 4. ✅
- **Precondition ao vivo (imediatamente antes)**: clubs=1, Goiás presente, 0 null/wrong/orphan club_id, 0 colisões (person career/guess/squad, ugip, arena_selected, votes, notif_events), **0 dos 18 bridge indexes existiam remotamente**. ✅
- **`npx supabase db push`**: as 4 migrations aplicadas sem erro (`content`→`progress`→`engagement`→`notification`). 0 seed, 0 role, 0 DDL manual, 0 DROP/CASCADE.
- **Pós-push**: `migration list` **50/50 local=remote**, dry-run "Remote database is up to date" (0 pending/mismatch).
- **18/18 índices** confirmados ao vivo com `indisvalid=true`, `indisready=true`, `indisunique=true`. Person = `(club_id, person_id)` sem predicate; tickets = `(club_id, user_id, match_id) WHERE origin='membership_check_in'`.
- **Legacy INTACTAS** (nada substituído): `ugip_pk(user_id,game_id,item_id)`, `asc_pk(user_id,game_id)`, `pir_pk/tir_pk/unp_pk(user_id)`, `mlv_uniq(match_id,user_id)`, `tcd_pk(user_id,match_id)`, `tickets_user_match_checkin_uidx(user_id,match_id) WHERE ...`, `career/guess/squad UNIQUE(person_id)`.
- **Row counts idênticos** (0 DML): passport 1697, career 30, guess 173, squad 31, lineup 31, quiz 60, ugip 211, score 262, qqp 160, cpp 40, lmp 34.
- **Estados**: `ROW_SCOPE_READY=true` · `KEY_SCOPE_BRIDGED=true` · `KEY_SCOPE_FINAL=false` · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` · `SECOND_CLUB_BLOCKED=true`.
- **Compat**: Old App + DB50 ✅ · M3.3 App + DB50 ✅ (nenhuma legacy removida) · M3.4 App + DB50 = preparado (M3.4 ainda não existe).
- Baselines pós-push: flutter analyze 0, flutter test 865/1 skip, JS 686/0. Edge/Worker/Passaporte intocados.

O restante do documento é a auditoria/design da 1ª rodada que fundamentou a aplicação.

---

## 1. HEAD inicial
`35357bd` — `docs(multiclub): record M3.3 commit hash and edge functions deploy status`. Log confirmou M3.1 (`f69b4b1`), M3.2 (`96a813b`), M3.3 (`1856581`) aplicados.

## 2. git status inicial
Só os arquivos de exclusão pré-existentes: `M lib/features/store/presentation/widgets/store_entry_card.dart`, `M data_export/goias/player_reconciliation/multiclub_hardcode_audit_stats.json`, e untracked `_competitions_pkg/`, `docs/multiclub/19_etapa_e_v4_applied_report.md`, `migration_dump.txt`. Preservados intactos.

## 3. migrations 46/46
`npx supabase migration list` → **46 local = 46 remote**, todas pareadas. Confirmado antes de qualquer trabalho.

## 4. Tabelas auditadas
**26 tabelas / 29 constraints tenant-relevantes**, capturadas AO VIVO de `information_schema`/`pg_catalog` (não dos relatórios antigos). Inventário: 24 tabelas com `club_id NOT NULL DEFAULT Goiás` (M2.2A) + 4 canônicas (`player_club_*`/`player_positions`/`player_match_appearances`, `club_id NOT NULL` sem default) + globais (profiles, delivery_addresses, user_notification_tokens, store_order_items, notification_deliveries) + passaporte (sem `club_id`, deferido).

## 5. PK inventory (ao vivo)
Conteúdo: career/guess/squad/lineup/quiz = `PK(id)`. Progresso: `user_game_item_progress(user_id,game_id,item_id)`, `quiz_question_progress(user_id,question_id)`, `quiz_active_session(user_id,difficulty)`, `career_path_progress(user_id,player_id)`, `lineup_match_progress(user_id,match_id)`, `arena_selected_content(user_id,game_id)`, `arena_achievements(user_id,achievement_id)`, `player_identity_results(user_id)`, `tactical_identity_results(user_id)`. uuid próprio: score_events, match_lineup_votes, ticket_orders, tickets, store_orders, store_order_items, supporter_memberships, notification_events, notification_deliveries. Outros: `ticket_checkin_decisions(user_id,match_id)`, `user_notification_preferences(user_id)`, `match_monitor_sessions(match_id)`.

## 6. UNIQUE inventory (ao vivo)
`career/guess/squad UNIQUE(person_id)`; `match_lineup_votes UNIQUE(match_id,user_id)`; `store_orders UNIQUE(order_number)`; `user_notification_tokens UNIQUE(fcm_token)`; `notification_events UNIQUE(event_type,dedupe_key)`; `notification_deliveries UNIQUE(event_id,token_id)`; `passport_attendances UNIQUE(user_id,match_id)`.

## 7. Partial unique index inventory (ao vivo)
`tickets_user_match_checkin_uidx (user_id,match_id) WHERE origin='membership_check_in'`; `profiles_cpf_unique_idx (cpf) WHERE cpf IS NOT NULL`. (As parciais canônicas — player_club_stats/player_positions/person_aliases — já são club-scoped ou humanas; fora de escopo.)

## 8. Incoming FK inventory
Apontam pra: `clubs(id)`, `people(id)`, `auth.users(id)`, `passport_matches(id)` (← passport_attendances, passport_memorable_matches), `store_orders(id)` (← store_order_items), `ticket_orders(id)` (← tickets), `notification_events(id)` (← notification_deliveries), `user_notification_tokens(id)` (← notification_deliveries), `venues(id)`. **Nenhuma FK aponta pras chaves legadas compostas que a M2.2B pretende trocar** (nenhuma referencia user_game_item_progress, career_players.id como conflict, etc.) — logo os swaps de PK/UNIQUE do enforcement são FK-safe.

## 9. Outgoing FK inventory
Toda tabela de user-state: `user_id → auth.users(id) ON DELETE CASCADE`. Conteúdo: `club_id → clubs(id)`, `person_id → people(id)`. Herança por FK: store_order_items→store_orders, tickets→ticket_orders, notification_deliveries→(events,tokens), passport_*→passport_matches.

## 10. RLS inventory (ao vivo)
Conteúdo (career/guess/squad/lineup/quiz): **PUBLIC_READ** (`using(true)`). User-state: **OWNER** (`auth.uid()=user_id`). Service (match_monitor_sessions, notification_events, notification_deliveries): **`using(false)`** (só service_role). **Nenhuma policy referencia `club_id`.**

## 11. onConflict inventory (app Flutter, grep determinístico)
`user_id,match_id`(×4), `user_id`(×4), `user_id,game_id`(×2), `user_id,question_id`, `user_id,player_id`, `user_id,difficulty`, `user_id,achievement_id`, `match_id,user_id`, `fcm_token`. **Nenhum inclui `club_id`** — nem no app M3.3 atual. Esta é a prova central de compatibilidade (§34-35).

## 12. RPC dependency inventory
Banco tem **legacy + `_for_club` coexistindo** (arena_record_score, arena_ranking, arena_my_rank, arena_user_detail, create_store_order, crowd_lineup, get_my_membership, subscribe_to_plan). App M3.3 chama os `_for_club`. **`arena_record_score_for_club` valida conteúdo com `where id=p_item_id and club_id=p_club_id` (KEY_SCOPE-aware) MAS ainda faz `on conflict (user_id, game_id, item_id)` — a PK legada.** Logo até a RPC nova depende da chave legada pra escrever.

## 13. Edge dependency inventory
3 Edge Functions M3.3 no ar (notifications-poll-live-match, notifications-sync-and-check-access, notifications-dispatch) escrevem `notification_events`/`match_monitor_sessions` (service_role). M3.3 já embutiu o código do clube na STRING `dedupe_key` como ponte. O drop das UNIQUEs legadas dessas tabelas = `REQUIRES_EDGE_UPDATE`. 0 deploy nesta rodada.

## 14. person_id global uniques
`career_players`, `guess_players`, `squad_members` — `UNIQUE(person_id)` GLOBAL. Ao vivo: 0 person_id duplicado; person_id NULL: career=9, guess=81, squad=0. **Target (corrigido): `UNIQUE(club_id, person_id)` — SEM predicate parcial.** Um UNIQUE normal do PostgreSQL já trata NULLs como distintos, então `(club_id, person_id)` já permite múltiplos person_id NULL no mesmo clube E a mesma pessoa em clubes diferentes, sem `WHERE`. Índice COMPLETO (não-parcial) é melhor pra futura inferência de `ON CONFLICT (club_id, person_id)` e promoção a constraint em M2.2B-B. Nunca `NULLS NOT DISTINCT` (mudaria a semântica). Bridges completos criados. A `UNIQUE(person_id)` legada continua intocada na M2.2B-A → old app funciona e 2º clube segue bloqueado (esperado).

## 15. user_game_item_progress
PK `(user_id, game_id, item_id)`. Escrito SÓ pela RPC `arena_record_score_for_club` (`on conflict (user_id, game_id, item_id)`). Target `(club_id, user_id, game_id, item_id)`. 211 linhas, 0 colisão prospectiva ao vivo. Bridge `ugip_club_user_game_item_uidx` criado; drop da PK legada = `REQUIRES_RPC_UPDATE` + `REQUIRES_OLD_APP_RETIREMENT`.

## 16. arena_selected_content
PK `(user_id, game_id)`. App M3.3 ainda upserta `onConflict: 'user_id,game_id'` (career_path + lineup storage). Target `(club_id, user_id, game_id)`. Bridge `asc_club_user_game_uidx`. Drop = `REQUIRES_NEW_APP` + `REQUIRES_OLD_APP_RETIREMENT` — exatamente o caso que quebraria o app publicado.

## 17. Identity result keys
`player_identity_results` / `tactical_identity_results` = `PK(user_id)`, onConflict `'user_id'`. Target `(user_id, club_id)`. Bridges `pir_user_club_uidx`/`tir_user_club_uidx`. Drop = `REQUIRES_NEW_APP`.

## 18. Notification preferences
`PK(user_id)`, onConflict `'user_id'`. Target `(user_id, club_id)` — "mesmo user: clubA ON, clubB OFF" é válido. Bridge `unp_user_club_uidx`. **Estado: `ROW_SCOPE_READY`, `KEY_SCOPE_NOT_YET_READY`** (0 linhas hoje). `user_notification_tokens` continua GLOBAL.

## 19. Notification events dedupe
`UNIQUE(event_type, dedupe_key)` GLOBAL. Target `(club_id, event_type, dedupe_key)`. Bridge `ne_club_event_dedupe_uidx`. M3.3 já pôs club code na string dedupe (ponte lógica); bridge dá a chave física. `notification_deliveries` NÃO muda (FK event_id → PK uuid, herda). Escrito por Edge = `REQUIRES_EDGE_UPDATE`.

## 20. match_lineup_votes
`UNIQUE(match_id, user_id)`, onConflict `'match_id,user_id'`. Target `(club_id, match_id, user_id)`. Bridge `mlv_club_match_user_uidx`. `crowd_lineup(_for_club)` agrega por match_id. Drop = `REQUIRES_NEW_APP`.

## 21. ticket_checkin_decisions
`PK(user_id, match_id)`, onConflict `'user_id,match_id'`. Target `(club_id, user_id, match_id)`. Bridge `tcd_club_user_match_uidx`. Drop = `REQUIRES_NEW_APP`.

## 22. tickets partial unique — REQUIRES_RPC_UPDATE (não é onConflict comum)
`(user_id, match_id) WHERE origin='membership_check_in'`, onConflict `'user_id,match_id'`. Target `(club_id, user_id, match_id) WHERE origin='membership_check_in'` — **parcial de propósito** (o usuário pode ter outros tickets `origin='purchase'` pra a mesma partida; o UNIQUE só vale pro check-in). Bridge `tickets_club_user_match_checkin_uidx` mantido parcial. **Reclassificado: `REQUIRES_RPC_UPDATE` (além de `REQUIRES_NEW_APP` + `REQUIRES_OLD_APP_RETIREMENT`).** Motivo: um índice único PARCIAL **NÃO é inferível pelo `onConflict:` do PostgREST/Supabase Flutter**, que só expressa colunas, nunca o predicate. Trocar o Flutter pra `onConflict: 'club_id,user_id,match_id'` seria **insuficiente** — o Postgres precisa do predicate na inferência: `ON CONFLICT (club_id, user_id, match_id) WHERE origin='membership_check_in'`. Design M3.4: uma RPC tenant-aware específica pro check-in de sócio com esse `ON CONFLICT ... WHERE`, identidade via `auth.uid()`, obedecendo a regra de segurança M3.2 (`REVOKE PUBLIC/anon/service_role`, `GRANT authenticated`, search_path seguro, relations schema-qualified, `has_function_privilege` pós-push). NÃO implementada agora — só reclassificada. A tooling marca `partialOnConflictRequiresPredicate=true` (não escondido no grupo genérico dos 12 onConflict).

## 23. Quiz progress
`quiz_question_progress PK(user_id,question_id)` onConflict `'user_id,question_id'` → target `(club_id,user_id,question_id)`, bridge `qqp_...`. `quiz_active_session PK(user_id,difficulty)` onConflict `'user_id,difficulty'` → target `(club_id,user_id,difficulty)`, bridge `qas_...`. Ambos `REQUIRES_NEW_APP`.

## 24. Career progress
`career_path_progress PK(user_id,player_id)` onConflict `'user_id,player_id'` → target `(club_id,user_id,player_id)`, bridge `cpp_...`. `REQUIRES_NEW_APP`.

## 25. Lineup progress
`lineup_match_progress PK(user_id,match_id)` onConflict `'user_id,match_id'` → target `(club_id,user_id,match_id)`, bridge `lmp_...`. `REQUIRES_NEW_APP`.

## 26. Arena achievements
`PK(user_id,achievement_id)` onConflict `'user_id,achievement_id'` → target `(club_id,user_id,achievement_id)`, bridge `aa_...`. `REQUIRES_NEW_APP`.

## 27. Membership
`supporter_memberships PK(id uuid)`, index `(user_id)`, RLS OWNER, `get_my_membership_for_club(p_club_id)` já escopa read por clube. "1 membership ativa por (user,club)" = derivado de `expires_at>now`, NÃO é constraint estática → fica na RPC. Mesmo user PODE ter membership em clubes diferentes (`club_id` já na coluna). **Classificação: PRODUCT_DECISION** — constraint física opcional é decisão de produto, não gerada.

## 28. Store order_number / GOI-
`UNIQUE(order_number)` alimentado por sequência global (`store_order_number_seq`) + prefixo `'GOI-'`. **IDENTITY SCOPE = KEEP_GLOBAL** (unicidade global é tecnicamente saudável; nº de pedido pode ser global). **BRANDING PREFIX** (`GOI-`) é o único acoplamento — vai pra `ClubConfig.integrations.orderPrefix` em M4, não agora. Sequence não tocada. Nenhum bridge.

## 29. match_id scope
`match_id` texto aparece em lineup_match_progress, ticket_checkin_decisions, ticket_orders, tickets, match_lineup_votes, match_monitor_sessions; passaporte usa id próprio `pe_...`. Proveniência: OneFootball (slug `goias-1863`, id `1863`, Worker `src/football/_lib/config.ts`). **NÃO há prova de namespace globalmente único entre clubes** — runtime já usa `club_id + match_id`; a chave física precisa incluir `club_id` (bridges criados). IDs editoriais/canônicos NÃO alterados.

## 30. DEFAULT Goiás dependencies
24 tabelas com `club_id NOT NULL DEFAULT Goiás` (transitional, M2.2A). Classificação: **LEGACY_APP_DEPENDENCY** — o app publicado ainda insere SEM `club_id` em várias tabelas (via upsert/RPC legacy), dependendo do DEFAULT pra gravar Goiás. `DROP DEFAULT` quebraria isso. **Nenhum DEFAULT removido nesta rodada.** Remoção é M2.2B-B/M4, quando o app novo enviar club_id explícito e o legacy for retirado. Marcado `TRANSITIONAL_COMPATIBILITY_DEFAULT`.

## 31. Collision SQL + resultados (ao vivo, read-only)
`GROUP BY <prospective_key> HAVING count(*)>1` + null/wrong club_id, rodados ao vivo:
- **integrity_all_clean = true** (0 club_id null, 0 club_id≠Goiás nas 24 tabelas).
- dup_person_id: career 0 / guess 0 / squad 0.
- dup prospective: user_game_item_progress 0, match_lineup_votes 0, notification_events 0.
Como só há 1 clube, a chave prospectiva `(club_id, legacy)` tem o MESMO perfil da legada — e a legada já é única → 0 colisão. **Rechecado ao vivo APÓS a rodada de correção das migrations** (2026-09-02, DDL ainda não aplicado): clubs=1, Goiás presente, dup_ugip=0, dup_arena_selected=0, dup_notif_events=0, dup_votes=0, dup_person(career/guess/squad)=0, null_or_wrong_club=0. Reconferir de novo antes de aplicar M2.2B-B.

## 32. wrong/null/orphan club_id
**0 null, 0 wrong (≠Goiás), 0 orphan** (todo club_id referencia clubs(id) via FK, e clubs tem só Goiás). 100% das linhas = Goiás.

## 33. FK dependency risks
Nenhuma FK aponta pras chaves legadas a serem trocadas (§8). Os swaps de PK/UNIQUE de progresso/conteúdo/votos/tickets são **FK-safe**. As PKs uuid com FKs entrantes (store_orders, ticket_orders, notification_events, user_notification_tokens) **não são trocadas**.

## 34. Legacy app conflict-target risks
O app PUBLICADO usa onConflict legacy (`user_id`, `user_id,game_id`, `user_id,match_id`, `match_id,user_id`, ...). PostgREST/Postgres exige UNIQUE/PK compatível com o `ON CONFLICT(cols)`. Dropar a chave legada faz o app antigo receber "no unique constraint matching" → **quebra imediata**. Por isso todo drop é `REQUIRES_OLD_APP_RETIREMENT`.

## 35. New app conflict-target requirements
O app M3.3 ATUAL **também** usa onConflict legacy (0 onConflict com club_id — provado). Logo o enforcement exige um **app novo (M3.4)** que reponte cada `.upsert(onConflict:)` e o `ON CONFLICT` das RPCs `_for_club` pras chaves compostas (bridges), publicado ANTES do drop. `REQUIRES_NEW_APP`.

## 36. Matriz old/new app × DB
| | Old App (publicado) | M3.3 App (atual) | M3.4 App (futuro) |
|---|---|---|---|
| **DB atual (46)** | ✅ | ✅ | — |
| **DB + Bridge (50, M2.2B-A)** | ✅ (legada intacta) | ✅ | ✅ |
| **DB Final (M2.2B-B, legada dropada)** | ❌ quebra onConflict | ❌ quebra onConflict | ✅ |
Conclusão: bridge é seguro pra TODA combinação atual; o DB Final só depois do M3.4 publicado E do app antigo retirado.

## 37. SAFE_NOW items
**0.** Nenhuma mudança destrutiva é "segura agora" — todas ou são aditivas (bridge) ou dependem de app/RPC/Edge.

## 38. BRIDGE_FIRST items (18)
Os 18 índices únicos compostos criados (person_id ×3; progresso ×9; crowd/tickets ×3; notifications/monitor/prefs ×3). Aditivos, validados, redundantes-até-o-swap (custo consciente do bridge).

## 39. REQUIRES_NEW_APP items (12)
Tabelas com onConflict de app: quiz_question_progress, quiz_active_session, career_path_progress, lineup_match_progress, arena_selected_content, arena_achievements, player_identity_results, tactical_identity_results, match_lineup_votes, ticket_checkin_decisions, **tickets** (esta ALÉM disso é `REQUIRES_RPC_UPDATE` — parcial, §22), user_notification_preferences. (`user_game_item_progress` é `REQUIRES_RPC_UPDATE` via a RPC, não onConflict de app.)

## 40. REQUIRES_OLD_APP_RETIREMENT items (13)
Os 12 acima + user_game_item_progress (via RPC legacy). O app publicado usa a chave legada; drop exige retirar/forçar upgrade.

## 41. PRODUCT_DECISION items (2)
`passport_matches` (PASSPORT_TENANCY_DEFERRED, sem club_id, A/B/C pendente) e `supporter_memberships` (constraint de "1 ativa por clube" é semântica de produto, hoje na RPC).

## 42. RLS ROW_SCOPE
**READY.** `club_id` existe em todas as tabelas TENANT_*; app (M3) + RPCs `_for_club` filtram/gravam club_id. A separação de linhas por clube funciona via filtro de aplicação.

## 43. RLS KEY_SCOPE
**BLOCKED.** As chaves FÍSICAS (PK/UNIQUE) ainda são legadas (sem club_id) em 23 constraints. Bridges preparam; enforcement (drop+swap) é M2.2B-B após M3.4. `SECOND_CLUB_BLOCKED = true`.

## 44. RLS AUTH_SCOPE
**BLOCKED (`AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED`).** Nenhuma policy conhece um "active club" confiável. RLS só conhece `auth.uid()`. Enforcement de tenant no próprio RLS exigiria fonte confiável (JWT claim de clube / contexto de RPC confiável / acesso só via RPC) — **não existe hoje, não inventado**.

## 45. Trusted tenant context existe?
**NÃO.** O cliente escolhe `club_id` livremente; o banco não tem um active-club vinculado ao servidor. Portanto o 1º gate de isolamento é de APLICAÇÃO (repositories filtram + RPCs recebem p_club_id + constraints incluem club_id), não RLS. Enforcement RLS estrito fica registrado como decisão futura de auth.

## 46. Subfases M2.2B propostas (derivadas do estado real)
- **M2.2B-A — Additive bridge constraints (ESTA rodada, migrations locais):** as 4 migrations `prepare_tenant_aware_*_keys` (18 índices únicos compostos, aditivos). Aplicáveis com segurança na janela single-club. `old app + bridge DB` = ✅.
- **M3.4 — App/RPC tenant-aware conflict targets (roadmap CORRIGIDO — NÃO é "trocar todo onConflict pra adicionar club_id"):**
  - **A. upserts PostgREST diretos** → mudar `onConflict` pras colunas tenant-aware **só onde existe UNIQUE NÃO-parcial inferível** (progresso/identity/prefs/votos/checkin).
  - **B. `arena_record_score_for_club`** → mudar o SQL `ON CONFLICT` pra chave composta (bridge) `(club_id, user_id, game_id, item_id)`.
  - **C. tickets check-in de sócio** → RPC/SQL específico com o predicate parcial no `ON CONFLICT (club_id, user_id, match_id) WHERE origin='membership_check_in'` (o `onConflict:` de colunas do PostgREST NÃO expressa isso).
  - **D. dedupe das Edge notifications** → atualizar conforme o bridge físico `(club_id, event_type, dedupe_key)`.
  - **E. provar `new app + bridge DB` ANTES de qualquer DROP.**
- **M2.2B-B — Enforcement:** só após M3.4 adotado E app antigo retirado — swap de PK conteúdo (`(club_id,id)`, ENFORCE_IN_B), drop `UNIQUE(person_id)`→promover `UNIQUE(club_id,person_id)`, promover os bridges a constraint/PK, endurecer RPC (`p_club_id` obrigatório), `REQUIRES_EDGE_UPDATE` das dedupes. `DROP DEFAULT` Goiás. Aí `SECOND_CLUB` pode abrir.
- **M4 — flavors / Worker / 2º clube real.**

## 47. Migrations locais criadas
4 (todas ADITIVAS, NÃO aplicadas): `20260903050000_prepare_tenant_aware_content_keys.sql` (3), `..060000_..progress_keys.sql` (9), `..070000_..engagement_keys.sql` (3), `..080000_..notification_keys.sql` (3). Cada uma com guard `clubs=1` + Goiás (roda ANTES de qualquer CREATE, faz `RAISE EXCEPTION`, sem DML, sem criar clube, sem DROP/CASCADE); **`CREATE UNIQUE INDEX` SEM `IF NOT EXISTS`** (fail loud em drift — nunca silenciar um objeto de mesmo nome com definição errada); zero DROP/ALTER-DROP/DELETE/UPDATE/TRUNCATE/CASCADE. **Correção desta rodada**: os 3 índices de person_id perderam o `WHERE person_id IS NOT NULL` (índice completo); `tickets` mantém o parcial `WHERE origin='membership_check_in'`; datas de validação ao vivo corrigidas pra 2026-09-02 (os FILENAMES `20260903*` NÃO foram renomeados, por instrução). Editadas as 4 existentes — nenhuma 5ª migration.

## 48. Migration dry-run
`npx supabase db push --dry-run` → "Would push these migrations" listou **exatamente as 4** bridge; `{"dryRun":true, "seeds":[], "roles":[]}`. **0 aplicada.**

## 49. Tooling metrics
`multiclub_key_scope_stats.json`: 29 constraints / 26 tabelas; 23 KEY_SCOPE_BLOCKED; 18 BRIDGE_FIRST; 5 ENFORCE_IN_B; 4 KEEP_GLOBAL; 2 PRODUCT_DECISION; 12 REQUIRES_NEW_APP; 13 REQUIRES_OLD_APP_RETIREMENT; **2 REQUIRES_RPC_UPDATE** (`user_game_item_progress` via RPC + `tickets` via parcial); 2 REQUIRES_EDGE_UPDATE; **`partialOnConflictRequiresPredicateTables=['tickets']`**; `appOnConflictKeysWithClub=[]`; `liveCollisionZero=true`; `secondClubBlocked=true`. Detector com casos sintéticos fabricados (global UNIQUE(user_id); chave sem club_id; KEEP_GLOBAL; **parcial + onConflict só de colunas → `PARTIAL_ON_CONFLICT_REQUIRES_PREDICATE`**) — não é um "sempre true".

## 50. Flutter analyze
**0 issues.**

## 51. Flutter tests
**865 passed / 1 skip** (baseline mantido — 0 Dart tocado nesta rodada).

## 52. JS tests
`tooling/**/test_*.mjs`: **686 passaram, 0 falharam** (663 baseline + 23 em `test_multiclub_key_scope.mjs` — 18 da 1ª rodada + 5 da correção: person sem partial, tickets parcial/REQUIRES_RPC_UPDATE, sem `CREATE UNIQUE INDEX IF NOT EXISTS`, detector de parcial fabricado).

## 53. Worker untouched
✅ Nenhum arquivo `src/` tocado. `WORKER_DEPLOY_PENDING_GIT_PUSH = true` preservado. Vitest não re-rodado (sem mudança).

## 54. Edge untouched
✅ 3 Edge Functions M3.3 no ar, 0 deploy. Dependência futura (`REQUIRES_EDGE_UPDATE` das dedupes) documentada, não aplicada.

## 55. Passaporte untouched
✅ `passport_matches`/`passport_attendances`/`passport_memorable_matches` sem club_id, fora de toda migration. `PASSPORT_TENANCY_DEFERRED`. 1697 partidas reais confirmadas ao vivo.

## 56. Legacy RPC debt untouched
✅ RPCs legacy (arena_record_score, get_my_membership, crowd_lineup, ...) intactas — coexistem com `_for_club`. `LEGACY_RPC_PUBLIC_EXECUTE_DEBT` não mexido. Nenhuma depende de constraint removida (nada removido).

## 57. Worker deploy pending preserved
✅ `WORKER_DEPLOY_PENDING_GIT_PUSH = true`.

## 58. SECOND_CLUB_BLOCKED
**= true.** Enquanto existir 1 constraint global bloqueando repetição de key (UNIQUE(person_id), PKs de progresso sem club_id), um 2º clube não pode reusar chaves. Ter `club_id` na coluna (M2.2A) NÃO é multi-tenant completo.

## 59. git diff --stat
Tracked modificados (pré-existentes, fora de escopo): `lib/features/store/presentation/widgets/store_entry_card.dart`, `data_export/goias/player_reconciliation/multiclub_hardcode_audit_stats.json`. Todo o trabalho da M2.2B é arquivo novo (untracked): 2 tooling scripts, 2 JSON, 4 migrations, este relatório.

## 60. git status
`M store_entry_card.dart` · `M multiclub_hardcode_audit_stats.json` · `?? _competitions_pkg/` · `?? migration_dump.txt` · `?? docs/multiclub/19_etapa_e_v4_applied_report.md` · `?? tooling/multiclub/audit_multiclub_key_scope.mjs` · `?? tooling/multiclub/test_multiclub_key_scope.mjs` · `?? data_export/.../multiclub_key_scope_audit.json` · `?? data_export/.../multiclub_key_scope_stats.json` · `?? supabase/migrations/2026090305/06/07/08*.sql` · `?? docs/multiclub/34_etapa_m2_2b_report.md`.

## 61. db push  ·  ## 62. commit  ·  ## 63. 0 git push
**M2.2B-A APLICADO** via `npx supabase db push` (as 4 bridge migrations, autorizado). Commit local `feat(multiclub): add tenant-aware key bridges` (ver seção de aplicação). **0 git push, 0 DML, 0 migration repair, 0 Edge/Worker deploy, 0 seed/role.**

---

## Critérios de sucesso
✅ 100% constraints inventariadas (ao vivo). ✅ 100% onConflict mapeados. ✅ collision checks ao vivo, 0 colisão. ✅ FK deps mapeadas. ✅ matriz old/new app × DB. ✅ classificação SAFE/BRIDGE/NEW_APP/OLD_APP_RETIREMENT/RPC/PRODUCT. ✅ M2.2B-A **aplicado e validado ao vivo** (18/18 índices, legacy intactas, 0 DML). ✅ roadmap M2.2B-A→M3.4→M2.2B-B→M4.

**PARADO.** M2.2B-A aplicado e commitado localmente. NÃO iniciar M3.4, M2.2B-B nem M4. NÃO cadastrar 2º clube. 0 git push. Aguardando autorização para a próxima etapa.

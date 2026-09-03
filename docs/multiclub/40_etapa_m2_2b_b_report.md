# M2.2B-B — Final Key Enforcement

Data: 2026-09-03
Status: **APLICADO EM PRODUÇÃO (RODADA 2).** As 3 migrations foram commitadas (`5bfa77b`) e aplicadas via `npx supabase db push` real. Validação pós-apply completa, 0 divergência. `0 git push` ainda — aguardando autorização separada. `0 M4`, `0 segundo clube`.

Autorizado pelo Post-Rollout Legacy Retirement Gate (`docs/multiclub/39_post_rollout_legacy_retirement_gate.md`): APK `1.0.1+2` gerado e confirmado entregue às ~3 pessoas com o `1.0.0+1` legacy → `LEGACY_VERSION_SUPPORT_ENDED=true` → `POST_ROLLOUT_RETIREMENT_READY=true` → `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=false`. Isso desbloqueia a *possibilidade* de M2.2B-B — a execução em si continua exigindo autorização própria, separada, ainda não dada.

---

## 0-1. Preflight

`HEAD == origin/main == 22f58fd` confirmado. `git status` limpo (só exclusões-padrão + os arquivos legítimos desta rodada, ainda sem commit). `npx supabase migration list`: **53 local = 53 remote, 0 pending** antes de criar qualquer migration nova.

## 2. Revalidação ao vivo — nada mudou silenciosamente

- **18/18 bridges** confirmadas: `indisunique=true, indisvalid=true, indisready=true` em todas.
- **24/24 tabelas** com `DEFAULT '4c16340d-300c-5ab2-903f-17519db9b146'::uuid` em `club_id` — mesma lista de sempre, reconfirmada.
- **8/8 RPCs legacy** existem e executáveis: `has_function_privilege` confirma `anon=true, authenticated=true, service_role=true, public=true` nas 8 (assinaturas exatas capturadas — necessárias pro `REVOKE` preciso).
- **`clubs` = 1 linha, `goias`** — confirmado de novo.

## 3. Revalidação do current app

- `currentAppUsesLegacyRpcs` = **false** (grep individual por nome nas 8, não uma alternação só — 0 caller no HEAD atual).
- `currentAppDependsOnGoiasDefaults` = **false** (todo insert que hoje depende do DEFAULT já manda `club_id` explícito — grep no Dart + `pg_proc.prosrc` das 3 RPCs `_for_club`).
- `NEW_RUNTIME_CONFLICT_TARGETS_ARE_TENANT_AWARE` = **true** (os 11+ onConflicts diretos do M3.4 já usam as chaves bridge).

---

## 4. M2.2B-B — escopo físico exato (18 objetos)

### PK promovida (DROP legacy PK → bridge vira PK, `ADD CONSTRAINT ... PRIMARY KEY USING INDEX`) — 12 tabelas

| Tabela | PK legacy (definição real) | Bridge promovida | Ação |
|---|---|---|---|
| `arena_achievements` | `PRIMARY KEY (user_id, achievement_id)` | `aa_club_user_achievement_uidx` | `PROMOTE_TENANT_KEY` |
| `arena_selected_content` | `PRIMARY KEY (user_id, game_id)` | `asc_club_user_game_uidx` | `PROMOTE_TENANT_KEY` |
| `career_path_progress` | `PRIMARY KEY (user_id, player_id)` | `cpp_club_user_player_uidx` | `PROMOTE_TENANT_KEY` |
| `lineup_match_progress` | `PRIMARY KEY (user_id, match_id)` | `lmp_club_user_match_uidx` | `PROMOTE_TENANT_KEY` |
| `player_identity_results` | `PRIMARY KEY (user_id)` | `pir_user_club_uidx` | `PROMOTE_TENANT_KEY` |
| `quiz_active_session` | `PRIMARY KEY (user_id, difficulty)` | `qas_club_user_difficulty_uidx` | `PROMOTE_TENANT_KEY` |
| `quiz_question_progress` | `PRIMARY KEY (user_id, question_id)` | `qqp_club_user_question_uidx` | `PROMOTE_TENANT_KEY` |
| `tactical_identity_results` | `PRIMARY KEY (user_id)` | `tir_user_club_uidx` | `PROMOTE_TENANT_KEY` |
| `ticket_checkin_decisions` | `PRIMARY KEY (user_id, match_id)` | `tcd_club_user_match_uidx` | `PROMOTE_TENANT_KEY` |
| `user_game_item_progress` | `PRIMARY KEY (user_id, game_id, item_id)` | `ugip_club_user_game_item_uidx` | `PROMOTE_TENANT_KEY` |
| `user_notification_preferences` | `PRIMARY KEY (user_id)` | `unp_user_club_uidx` | `PROMOTE_TENANT_KEY` |
| `match_monitor_sessions` | `PRIMARY KEY (match_id)` | `mms_club_match_uidx` | `PROMOTE_TENANT_KEY` |

**Efeito colateral do Postgres, documentado**: `ADD CONSTRAINT ... PRIMARY KEY USING INDEX <bridge>` **renomeia** o índice bridge pro nome da nova constraint (ex.: `aa_club_user_achievement_uidx` → `arena_achievements_pkey`). Comportamento padrão, não um bug — mas qualquer tooling futuro que procure pelo nome antigo da bridge vai precisar saber disso.

### UNIQUE legacy dropada (surrogate `id` como PK, intocado) — 5 tabelas

| Tabela | UNIQUE legacy | Bridge (mantida, nome inalterado) | Ação |
|---|---|---|---|
| `match_lineup_votes` | `UNIQUE (match_id, user_id)` | `mlv_club_match_user_uidx` | `DROP_LEGACY_KEY` |
| `career_players` | `UNIQUE (person_id)` | `career_players_club_person_uidx` | `DROP_LEGACY_KEY` |
| `guess_players` | `UNIQUE (person_id)` | `guess_players_club_person_uidx` | `DROP_LEGACY_KEY` |
| `squad_members` | `UNIQUE (person_id)` | `squad_members_club_person_uidx` | `DROP_LEGACY_KEY` |
| `notification_events` | `UNIQUE (event_type, dedupe_key)` | `ne_club_event_dedupe_uidx` | `DROP_LEGACY_KEY` |

### Índice parcial legacy dropado (nunca era uma constraint) — 1 tabela

| Tabela | Índice legacy | Bridge (parcial, mantida) | Ação |
|---|---|---|---|
| `tickets` (check-in) | `tickets_user_match_checkin_uidx` — `UNIQUE (user_id, match_id) WHERE origin='membership_check_in'` | `tickets_club_user_match_checkin_uidx` — mesma predicate + `club_id` | `DROP_LEGACY_KEY` (`DROP INDEX`, não `ALTER TABLE ... DROP CONSTRAINT` — nunca foi uma constraint) |

**Total: 12 + 5 + 1 = 18** — bate exatamente com as 18 bridges da M2.2B-A.

## 5. Conteúdo — `person_id` (career_players/guess_players/squad_members)

Confirmado: `DROP UNIQUE(person_id)` legacy, bridge `UNIQUE(club_id, person_id)` (índice **completo**, não parcial) mantida como estava desde M2.2B-A. **Nenhum `NULLS NOT DISTINCT`** usado em lugar nenhum — Postgres já trata `NULL` como distinto por padrão, e essa decisão foi tomada (e confirmada correta) na própria M2.2B-A.

## 6. User-state keys — matriz completa

As 12 tabelas de user-state (`user_game_item_progress`, `arena_selected_content`, `player_identity_results`, `tactical_identity_results`, `user_notification_preferences`, `quiz_question_progress`, `quiz_active_session`, `career_path_progress`, `lineup_match_progress`, `arena_achievements`, `match_lineup_votes`, `ticket_checkin_decisions`) — todas cobertas na §4, nenhuma tabela inventada, todas confirmadas ao vivo antes de entrar na migration.

## 7. Tickets — semântica parcial preservada

A bridge `tickets_club_user_match_checkin_uidx` — `UNIQUE (club_id, user_id, match_id) WHERE origin = 'membership_check_in'` — **não foi tocada**. Só o índice legacy (mesma predicate, sem `club_id`) foi removido. **Nunca virou `UNIQUE` completo.**

## 8. `user_game_item_progress` e o guard `key_scope_collision`

A RPC `arena_record_score_for_club` já usa `ON CONFLICT (club_id, user_id, game_id, item_id)` — confirmado (M3.4). A migration §4 remove a PK legacy `(user_id, game_id, item_id)`, liberando isso de vez.

**Achado novo desta rodada, não corrigido (fora do escopo — DDL apenas)**: o corpo da RPC tem **3 leituras** que NÃO filtram por `club_id`:
1. `select * into v_prev from user_game_item_progress where user_id=v_uid and game_id=p_game_id and item_id=p_item_id` (a query que o guard `key_scope_collision` protege).
2. A subquery de `total_score` no `return query` (`sum(score) where user_id=v_uid`).
3. A subquery de `game_score` no `return query` (`sum(score) where user_id=v_uid and game_id=p_game_id`).

Hoje, com `SECOND_CLUB_BLOCKED=true`, isso é inofensivo (só existe 1 clube, então qualquer linha que bater em `user_id+game_id+item_id` É do Goiás). **Mas a troca de PK, sozinha, NÃO torna o guard redundante** — ele continua pego pela mesma lógica de hoje, e as 2 subqueries de soma **continuam vulneráveis a somar entre clubes** assim que existir um 2º clube de verdade. Classificação: **`KEEP_TEMPORARILY`** (não remover o guard nesta rodada) + **achado registrado como pré-requisito obrigatório antes de M4**: adicionar `and club_id = p_club_id` nas 3 leituras. Nenhuma alteração de corpo de função foi feita nesta rodada (fora do escopo — só DDL).

## 9. `DROP DEFAULT` — 24 tabelas

Revalidado: **24/24 `DROP_IN_M2_2B_B`**. `ALTER TABLE ... ALTER COLUMN club_id DROP DEFAULT` pras 24, `NOT NULL` e a FK pra `clubs(id)` **intocados** em todas.

## 10. Legacy RPC retirement — ACL final

As 8 RPCs (`arena_record_score`, `arena_ranking`, `arena_my_rank`, `arena_user_detail`, `crowd_lineup`, `get_my_membership`, `subscribe_to_plan`, `create_store_order`): HEAD atual chama **0**. ACL objetivo: `PUBLIC=false, anon=false, authenticated=false`. Pra `service_role`: **auditado antes de decidir** (não assumido) — `grep` em `supabase/functions/` e `src/` (Worker, os 2 únicos lugares que usam credencial `service_role` neste projeto) → **0 ocorrências** dos 8 nomes. Sem uso de admin/backend encontrado → **recomendado revoke também pra `service_role`**.

## 11. REVOKE, não DROP

A migration usa **`REVOKE EXECUTE`** nas 8, nunca `DROP FUNCTION` — confirmado pelo próprio tooling desta rodada (`rpcMigrationUsesRevoke=true`, `rpcMigrationUsesDropFunction=false`, depois de corrigir um falso-positivo do detector que tinha pego a MENÇÃO a "DROP FUNCTION" dentro do comentário explicando que não é usado). Preserva rollback/debug; `postgres`/owner nunca é afetado por `REVOKE`.

## 12. Constraints GLOBAIS — confirmadas intocadas

| Tabela | Constraint | Definição real |
|---|---|---|
| `store_orders` | `store_orders_order_number_key` | `UNIQUE (order_number)` |
| `user_notification_tokens` | `user_notification_tokens_fcm_token_key` | `UNIQUE (fcm_token)` |
| `profiles` | `profiles_cpf_unique_idx` | `UNIQUE (cpf) WHERE (cpf IS NOT NULL)` |
| `notification_deliveries` | `notification_deliveries_event_id_token_id_key` | `UNIQUE (event_id, token_id)` |

Nenhum desses 4 nomes aparece em nenhuma das 3 migrations — verificado por grep no tooling (`globalConstraintsPreserved=true`).

## 13. Passaporte

`PASSPORT_TENANCY_DEFERRED` mantido — `passport_matches`/`passport_attendances`/`passport_memorable_matches`/`passport_sync_runs` não aparecem em nenhuma migration (`passportUntouched=true`).

## 14. RLS

**0** menção a `policy`/`row level security` nas 3 migrations (`rlsUntouched=true`). M2.2B-B fecha `KEY_SCOPE`, não `AUTH_SCOPE` — `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` continua exatamente como estava, nenhum enforcement de clube ativo foi inventado.

---

## 15. Estado esperado depois de M2.2B-B aplicada (FUTURO — não aplicado agora)

```
ROW_SCOPE_READY = true
KEY_SCOPE_BRIDGED = false   (as bridges deixam de ser "bridge" — viram a chave real)
KEY_SCOPE_FINAL = true
LEGACY_VERSION_SUPPORT_ENDED = true
```

**Cuidado explícito, conforme pedido**: não marcar "2º clube pronto" só por causa da chave física. Separando:

```
KEY_SCOPE_SECOND_CLUB_BLOCKER = false   (a chave física deixa de ser o obstáculo)
SECOND_CLUB_PRODUCT_READY = false        (M4 tem escopo próprio: config, Passaporte,
                                            fix pré-M4 do §8, decisão de produto —
                                            nada disso é resolvido só pela DDL)
```

## 16. Compatibility matrix FINAL (depois de M2.2B-B aplicada)

| Cliente | DB final (pós M2.2B-B) |
|---|---|
| Legacy `1.0.0+1` (as ~3 pessoas, já substituídas) | ❌ esperado — writes falham (`42883`/NOT NULL), reads continuam |
| M3.4 `1.0.1+2` (produção atual, PWA + as ~3 pessoas) | ✅ |
| Futuro 2º clube (M4, ainda não iniciado) | Chave física preparada (`KEY_SCOPE_SECOND_CLUB_BLOCKER=false`) — produto/config/Passaporte/RPC fix (§8) ainda pendentes |

Essa quebra do legacy é **deliberada e autorizada pelo dono** (confirmação explícita de entrega do `1.0.1+2`, Post-Rollout Retirement Gate).

## 17. Collision checks ao vivo (antes de escrever as migrations)

18 tabelas checadas (as 18 do escopo físico): **0 nulls, 0 wrong club_id** em todas. `clubs` = 1 linha, Goiás. "Orphan club_id" é estruturalmente impossível (FK pra `clubs(id)` já impede, não só observado — garantido pelo próprio Postgres). Nenhum problema encontrado — se tivesse encontrado, o plano seria parar aqui, nunca autocorrigir dado.

---

## 18. Migrations locais criadas (NÃO aplicadas)

3 arquivos, cada um com seu próprio guard de segurança (§19), pequenos e auditáveis por responsabilidade:

1. **`supabase/migrations/20260903120000_finalize_tenant_aware_keys.sql`** — os 18 objetos do §4 (12 promoções de PK + 5 UNIQUE dropadas + 1 índice parcial dropado).
2. **`supabase/migrations/20260903130000_drop_transitional_club_defaults.sql`** — as 24 `DROP DEFAULT` do §9.
3. **`supabase/migrations/20260903140000_retire_legacy_rpc_execute_grants.sql`** — os 8 `REVOKE EXECUTE` do §10-11.

## 19. Guard de segurança — decisão explícita

**Decidido: SIM, todas as 3 migrations levam o guard** (`clubs` = 1 linha E é exatamente Goiás, senão `RAISE EXCEPTION` e aborta antes de qualquer DDL). Justificativa: DDL estrutural desse tamanho (remover 18 chaves + 24 defaults + revogar 8 RPCs) é o tipo de operação onde "seguro por enquanto" não é suficiente — o guard custa 4 linhas por arquivo e garante que, se por qualquer motivo um 2º clube real tiver sido registrado entre agora e a aplicação (nunca deveria acontecer, mas nunca é o tipo de coisa pra confiar de memória), a migration falha alto e limpo em vez de aplicar mesmo assim. Mesmo padrão já usado nas 4 migrations de bridge da M2.2B-A — não é uma decisão nova, é consistência com o que já funcionou.

## 20. Fail-loud — 0 `IF EXISTS`

Confirmado (`anyIfExists=false`) — todo `DROP`/`ALTER` mira um objeto que esta auditoria confirmou existir ao vivo nesta sessão (§2). Se algum não existir no momento da aplicação real, a migration falha e avisa — nunca finge sucesso.

## 21. Tooling detecta os 9 casos pedidos

`audit_multiclub_final_key_enforcement.mjs` cobre explicitamente: chave legacy que ficou (`tenantKeysReady` != `legacyKeysToDrop`), bridge ausente (implícito na comparação por nome exato), DEFAULT não removido (`goiasDefaultsToDrop` != 24), constraint GLOBAL removida por engano (`globalConstraintsPreserved`), ticket parcial virando completo (comparação literal do texto do índice, nunca `UNIQUE (user_id, match_id)` sem `WHERE`), RPC legacy ainda executável por `authenticated` (`legacyRpcAuthenticatedExecuteRemaining`), decisão de `service_role` documentada (§10, citada explicitamente no tooling), Passaporte tocado (`passportUntouched`), RLS alterada (`rlsUntouched`), `DROP CASCADE` (`anyForbiddenDdl`).

## 22. Proibições confirmadas

**0** `CASCADE`, **0** `TRUNCATE`, **0** `DELETE`/`UPDATE`/`INSERT` (fora de comentário) nas 3 migrations — confirmado pelo tooling (`anyForbiddenDdl=false`, `anyDml=false`), com um bug real de falso-positivo achado e corrigido no processo (o detector inicial pegava a MENÇÃO a essas palavras dentro dos comentários que explicam que elas não são usadas — corrigido pra sempre comparar só código, nunca comentário).

## 23. Tooling — métricas finais

```json
{
  "legacyKeysToDrop": 18,
  "tenantKeysReady": 18,
  "goiasDefaultsToDrop": 24,
  "legacyRpcsToRetire": 8,
  "legacyRpcAuthenticatedExecuteRemaining": 0,
  "globalConstraintsPreserved": true,
  "passportUntouched": true,
  "rlsUntouched": true,
  "currentAppSurvivesFinalSchema": true,
  "legacyAppExpectedToFail": true,
  "anyForbiddenDdl": false,
  "anyDml": false,
  "anyIfExists": false,
  "guardPresentInAllThree": true,
  "keyScopeFinalReady": true
}
```

`tooling/multiclub/audit_multiclub_final_key_enforcement.mjs` + `test_multiclub_final_key_enforcement.mjs` (16 testes, incluindo 3 fabricados que provam o detector reprova quando deveria).

## 24. Baselines

`flutter analyze`: **0 issues**. `flutter test`: **896/1 skip** (inalterado — 0 `.dart` tocado, conforme esperado pra uma rodada de M2.2B-B). JS: **777 passed / 0 failed** (761 + 16 novos). Worker/`tsc`: não re-rodado (0 arquivo `src/` tocado). DB: **53/53** antes, **56 local/53 remote/3 pending** depois de criar os 3 arquivos — nenhum aplicado.

## 25. Dry-run

```
npx supabase migration list -> 56 local / 53 remote / 3 pending
npx supabase db push --dry-run ->
  20260903120000_finalize_tenant_aware_keys.sql
  20260903130000_drop_transitional_club_defaults.sql
  20260903140000_retire_legacy_rpc_execute_grants.sql
```

Exatamente as 3, nada mais. **0 aplicação.**

---

## 27. Respostas objetivas (1-30)

1. HEAD/origin: `22f58fd` == `22f58fd`. 2. DB baseline: 53/53 antes, 56/53/3 pending depois de criar os arquivos. 3. Bridges live: 18/18 `indisunique=indisvalid=indisready=true`. 4. Collision results: 0 nulls, 0 wrong club_id, 18/18 tabelas limpas. 5. Legacy key inventory: 12 PK + 5 UNIQUE + 1 índice parcial = 18 (§4). 6. Target tenant key inventory: as mesmas 18 bridges, já ativas desde M2.2B-A. 7. Person_id globals: `career_players`/`guess_players`/`squad_members`, `DROP UNIQUE(person_id)`, sem `NULLS NOT DISTINCT`. 8. UGIP: PK trocada, guard `KEEP_TEMPORARILY` com fix pré-M4 registrado (§8). 9. Ticket partial: preservada como parcial na bridge, só o legacy índice sai. 10. 24 defaults: 24/24 `DROP_IN_M2_2B_B`. 11. Current app default dependence: `false`, confirmado por grep+`pg_proc.prosrc`. 12. 8 legacy RPC callers no HEAD: **0**. 13. ACL atual das 8: `anon=authenticated=service_role=public=true` (a dívida real). 14. `service_role` usage: 0 achado em Edge/Worker — recomendado revoke também. 15. Revoke design: `REVOKE` nas 4 roles, nunca `DROP FUNCTION`. 16. Global constraints preserved: os 4 citados, confirmados intocados. 17. Passaporte: intocado. 18. RLS: intocada. 19. `key_scope_collision` guard: `KEEP_TEMPORARILY`, fix pré-M4 documentado, não aplicado. 20. Migrations novas: as 3 do §18. 21. `FORBIDDEN_DDL=0, DML=0, CASCADE=0, IF_EXISTS=0` (§22) — correção de wording: esta etapa CONTÉM DDL destrutivo deliberado sobre o contrato legacy (`DROP CONSTRAINT`/`DROP INDEX`/`DROP DEFAULT`/`REVOKE EXECUTE`, todos intencionais); "0" nunca significou "0 DDL destrutivo", significa "0 das operações PROIBIDAS" (CASCADE/TRUNCATE/DML/IF EXISTS escondendo drift). 22. Tooling metrics: §23. 23. JS: 777/0. 24. Flutter analyze: 0 issues. 25. Flutter test: 896/1 skip. 26. Dry-run: §25, exatamente as 3. 27. `KEY_SCOPE_FINAL_READY`: **true** (nome real da métrica: `keyScopeFinalReady`). 28. **0 db push.** 29. **0 commit** (aguardando autorização, mesmo padrão de toda etapa anterior). 30. **0 git push.**

---

## RODADA 2 — APPLICATION (2026-09-03)

Autorização: **"M2.2B-B — AUTORIZADA APLICAÇÃO FINAL"**, dono validou independentemente as 12/12 bridges + 0 FKs de entrada + 24 defaults/8 RPCs antes de autorizar.

### 0. Correção de wording (antes de tudo)

Resposta #21 (§27 acima) corrigida: `"Destructive DDL inventory: 0"` → `FORBIDDEN_DDL=0, DML=0, CASCADE=0, IF_EXISTS=0`. Esta etapa **contém** DDL destrutivo deliberado (`DROP CONSTRAINT`/`DROP INDEX`/`DROP DEFAULT`/`REVOKE EXECUTE`) — "0" nunca significou ausência de DDL destrutivo, significa 0 das operações proibidas (CASCADE/TRUNCATE/DML/IF EXISTS escondendo drift). Wording-only, nenhum SQL alterado.

### 1-2. Preflight + revalidação final

`HEAD == origin/main == 22f58fd`. `git status` limpo (só os 8 artefatos M2.2B-B pendentes de commit + exclusões-padrão + leftovers legítimos de rodadas anteriores, deixados de fora deste commit por escopo). `migration list`: 56 total / 53 remote / 3 pending — mesmos 3 arquivos. `db push --dry-run`: confirma exatamente os 3, nada a mais.

Revalidação ao vivo (imediatamente antes do push, não reaproveitada de relatório anterior): `clubs=1/goias` · 18/18 bridges `unique=valid=ready=true` · `defaults_count=24` · `rpc_count=8` · **collisions 18/18 tabelas: 0 nulls, 0 wrong club_id**.

### 3. Revalidação específica das 12 bridges de PK

Para as 12 tabelas cuja PK legacy seria trocada: 12/12 `btree`, `unique=true`, `valid=true`, `ready=true`, **`partial=false`**, **`expression=false`** (colunas simples). **Incoming FKs para as 12 PKs legacy: 0** (`pg_constraint` com `contype='f'` e `confrelid` em qualquer uma das 12 → 0 linhas). Nenhum bloqueio estrutural encontrado.

### 4-5. Commit do design + repreflight

Staged explicitamente (nunca `git add .`): as 3 migrations, `audit_multiclub_final_key_enforcement.mjs`, `test_multiclub_final_key_enforcement.mjs`, os 2 JSONs gerados, este relatório. Commit `5bfa77b` — `"feat(multiclub): finalize tenant-aware database keys"`. Repreflight pós-commit: `git status` confirma só os 8 arquivos saíram da lista de untracked/modified; `migration list` e `db push --dry-run` reconfirmam 56/53/3 pending, mesmos 3 arquivos — 0 divergência.

### 6. Aplicação real

`npx supabase db push` (sem dry-run) — **as 3 migrations aplicaram em sequência sem erro**: `20260903120000` → `20260903130000` → `20260903140000`. `{"upToDate":false,"dryRun":false,...}` confirmando as 3 no payload de resposta. Nenhuma falha, nenhum estado parcial a reportar.

### 7. Migration history pós-push

`migration list`: **56 local = 56 remote, 0 pending**. `db push --dry-run`: `{"upToDate":true,"migrations":[],"message":"Remote database is up to date."}`.

### 8. As 12 PKs promovidas — validadas pela definição FINAL (não pelo nome antigo da bridge)

Postgres renomeia o índice promovido para `<tabela>_pkey` — confirmado nas 12, com a composição de colunas tenant-aware esperada:

| Tabela | PK final |
|---|---|
| `arena_achievements` | `PRIMARY KEY (club_id, user_id, achievement_id)` |
| `arena_selected_content` | `PRIMARY KEY (club_id, user_id, game_id)` |
| `career_path_progress` | `PRIMARY KEY (club_id, user_id, player_id)` |
| `lineup_match_progress` | `PRIMARY KEY (club_id, user_id, match_id)` |
| `player_identity_results` | `PRIMARY KEY (user_id, club_id)` |
| `quiz_active_session` | `PRIMARY KEY (club_id, user_id, difficulty)` |
| `quiz_question_progress` | `PRIMARY KEY (club_id, user_id, question_id)` |
| `tactical_identity_results` | `PRIMARY KEY (user_id, club_id)` |
| `ticket_checkin_decisions` | `PRIMARY KEY (club_id, user_id, match_id)` |
| `user_game_item_progress` | `PRIMARY KEY (club_id, user_id, game_id, item_id)` |
| `user_notification_preferences` | `PRIMARY KEY (user_id, club_id)` |
| `match_monitor_sessions` | `PRIMARY KEY (club_id, match_id)` |

12/12 confirmadas.

### 9. As 6 bridges tenant-unique restantes (não promovidas) — nomes originais preservados

`career_players_club_person_uidx`, `guess_players_club_person_uidx`, `mlv_club_match_user_uidx`, `ne_club_event_dedupe_uidx`, `squad_members_club_person_uidx`, `tickets_club_user_match_checkin_uidx` — 6/6 `unique=valid=ready=true`. A bridge de `tickets` continua **parcial** (`partial=true`) — nunca virou unique completa, como exigido.

### 10. 18/18 chaves legacy confirmadas removidas

As 5 constraints UNIQUE legacy + 1 índice parcial legacy (`tickets_user_match_checkin_uidx`) buscados por nome: **0 encontrados**. Combinado com §8 (as 12 antigas PKs agora têm definição nova sob o mesmo nome de constraint), os 18 objetos legacy físicos não existem mais.

### 11. 4 constraints globais — intactos

`store_orders_order_number_key`, `user_notification_tokens_fcm_token_key`, `notification_deliveries_event_id_token_id_key` (constraints) + `profiles_cpf_unique_idx` (índice parcial) — 4/4 presentes, definições inalteradas.

### 12. 24 DEFAULTs removidos, NOT NULL + FK preservados

24/24 tabelas: `column_default=null`, `is_nullable=NO`. FK para `clubs(id)` reconfirmada presente nas 24 (`contype='f'` com `confrelid=clubs`) — 24/24.

### 13. Sobrevivência do app atual — reconfirmada

Grep direto (não reaproveitado) por `.rpc('<nome_legacy>'` nas 8 RPCs: **0 chamadas reais** no `lib/` atual (as 2 ocorrências de texto encontradas são comentários de documentação, não chamadas). `currentAppDependsOnGoiasDefaults=false`, `currentAppUsesLegacyRpcs=false` seguem válidos.

### 14. ACL final das 8 RPCs legacy

`has_function_privilege` pós-push: **8/8 com `anon=authenticated=service_role=public=false`**. `REVOKE` funcionou nas 4 roles, nas 8 funções, sem exceção.

### 15. As 9 variantes `_for_club` — ACL NÃO afetada colateralmente

9/9 confirmadas com `authenticated=true, anon=false, service_role=false, public=false` — idêntico ao estado pré-push. O `REVOKE` da migration 3 mirou exclusivamente as 8 assinaturas legacy exatas, sem colateral nas variantes `_for_club`.

### 16-17. Passaporte e RLS — intocados

Grep das 3 migrations por `policy`/`passaporte`/`passport`: **0 ocorrências**. Contagem de RLS policies em `public`: 90 (nenhuma criada/removida/alterada — as migrations não contêm nenhum `CREATE POLICY`/`ALTER POLICY`/`DROP POLICY`).

### 18. Row counts — 0 DML confirmado

Grep das 3 migrations por `INSERT INTO`/`UPDATE `/`DELETE FROM`: **0 ocorrências**. Migrations são DDL puro (constraints/defaults/grants) — contagens de linha das 18 tabelas afetadas capturadas pós-push só como evidência complementar, não como prova (a prova real é a ausência estrutural de DML no SQL aplicado).

### 19. Recheck final de colisão/integridade

18/18 tabelas tenant-scoped: **0 nulls, 0 wrong club_id, 0 orphan club_id** — pós-push, idêntico ao pré-push.

### 20. `key_scope_collision` guard — mantido, novo blocker formal registrado

Guard **não removido** (fora do escopo DDL desta etapa, como já registrado na rodada 1). Estados formalmente registrados:

- `KEY_SCOPE_FINAL=true`
- `ARENA_RPC_CROSS_CLUB_READ_FIX_PENDING=true`
- `M4_BLOCKED_BY_ARENA_RPC_FIX=true`

(`arena_record_score_for_club` tem 3 leituras não filtradas por `club_id` no corpo da função — inofensivo hoje só porque `SECOND_CLUB_BLOCKED=true`; vira bloqueador formal de M4 a partir de agora.)

### 21. Estados finais — lista exata

Ver seção **Estados** abaixo, atualizada.

### 22. Matriz de compatibilidade — formalizada estruturalmente

`1.0.0+1` (legacy) + schema pós-M2.2B-B (56 migrations) = ❌ esperado (writes sem `club_id` explícito falham contra as novas PKs/NOT NULL sem DEFAULT). `1.0.1+2`/PWA M3.4 (HEAD atual) + schema pós-M2.2B-B = ✅ confirmado (§13). Formalizado via catálogo/tooling (`currentAppDependsOnGoiasDefaults=false`, `currentAppUsesLegacyRpcs=false`) — nunca testado escrevendo de fato com um cliente legacy real.

### 23. Gates de código

`flutter analyze`: **0 issues**. Suíte JS (`tooling/**/test_*.mjs`, 27 arquivos): **777 passaram, 0 falharam** — bate exatamente com a baseline. `src/` (Worker) não foi tocado nesta rodada → `vitest`/`tsc` do Worker não rodados (não aplicável).

### 24. Tooling que referenciava os 12 nomes antigos de bridge — avaliado, nenhuma mudança necessária

`audit_multiclub_conflict_targets.mjs` e `audit_multiclub_key_scope.mjs` citam os 12 nomes de bridge, mas apenas como metadado descritivo — o `onConflict` que o Flutter realmente envia ao Supabase é a **lista de colunas** (`'club_id,user_id,achievement_id'`, etc.), não o nome do índice/constraint. Resolução `ON CONFLICT` no Postgres casa por conjunto de colunas, não por nome — a renomeação (`<tabela>_pkey`) é transparente para o app e para os scripts. Ambos os scripts rodados pós-apply: `exit=0`, suite completa (777/0) inclui os testes desses 2 arquivos sem falha. `audit_multiclub_final_key_enforcement.mjs` referencia os nomes antigos ao ler o **texto das migrations** (correto — é isso que as migrations dizem: `USING INDEX aa_club_user_achievement_uidx`), não o estado ao vivo — segue válido sem alteração. Nenhum código ou tooling precisou de atualização.

### 25. Este documento

Seção RODADA 2 adicionada (esta seção).

### 26. Commit de acompanhamento

Não necessário — nenhuma mudança de código/tooling foi exigida por §24. Commit `5bfa77b` já cobre o design + este relatório atualizado ficará para um commit docs-only separado, se autorizado.

### 27. Git push

**Não executado.** Aguardando autorização explícita e separada, conforme instrução do dono.

---

## Estados

`KEY_SCOPE_FINAL=true` (aplicado em produção, validado ao vivo) · `ARENA_RPC_CROSS_CLUB_READ_FIX_PENDING=true` (novo — bloqueador formal) · `M4_BLOCKED_BY_ARENA_RPC_FIX=true` (novo) · `POST_ROLLOUT_RETIREMENT_READY=true` (inalterado) · `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=false` (inalterado) · `LEGACY_CONTRACT_RETIREMENT_READY=true` (inalterado) · `RPC_ONLY_MIGRATION_REQUIRED=false` (inalterado) · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` (inalterado — M2.2B-B não mexeu em RLS/auth scope) · `KEY_SCOPE_SECOND_CLUB_BLOCKER=false` (o problema físico de chaves está resolvido) · `SECOND_CLUB_PRODUCT_READY=false` (**nunca colapsar com o campo acima** — falta ainda o fix da Arena RPC, o M4 em si, o Passaporte, e decisões de produto) · `GIT_PUSH_PENDING=true` (aguardando autorização separada).

---

**APLICADO EM PRODUÇÃO.** As 3 migrations foram commitadas e aplicadas via `db push` real, validação pós-apply completa e limpa em todos os pontos (7-19). `0 git push` ainda. **PARE. Não iniciar M4. Não cadastrar segundo clube.**

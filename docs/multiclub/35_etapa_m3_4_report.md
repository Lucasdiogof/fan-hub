# M3.4 — Tenant-Aware Conflict Targets + RPC/Edge Bridge Adoption

Data: 2026-09-02 (rodada 1: audit+implement+test) / 2026-09-03 (rodada 2: aplicação+deploy+commit)
Status: **APLICADO. DB 52/52. Edge 2/2 deployado. Commit local feito. 0 git push, 0 M2.2B-B, 0 M4, 0 DROP legacy, 0 DROP DEFAULT, 0 segundo clube.**

Objetivo: o NOVO runtime (Flutter + RPC + Edge) passa a escrever/upsertar pelas chaves tenant-aware (bridges M2.2B-A) SEM remover nenhuma chave legacy. Old App e M3.3 App continuam usando as chaves legadas — coexistência. Nenhum 2º clube (`clubRegistry` = 1).

---

## 1. HEAD inicial
`5e93b85` (M2.2B-A `8d64316` + docs). Log confirmou M3.1/M3.2/M3.3 + M2.2B-A.

## 2. git status inicial
Só os fora-de-escopo pré-existentes (`store_entry_card.dart`, `multiclub_hardcode_audit_stats.json`, `_competitions_pkg/`, `migration_dump.txt`, `19_etapa_e_v4_applied_report.md`). Preservados.

## 3. DB 50/50 inicial
`npx supabase migration list` → **50 local = 50 remote**. Confirmado antes de tocar código.

## 4. 18 bridges live
Reauditadas ao vivo (`pg_index`): **18/18** com `indisunique=indisvalid=indisready=true`. Ordens de coluna confirmadas (ex.: `pir/tir/unp = (user_id, club_id)`; demais `club_id` primeiro). Nenhum onConflict foi apontado pra bridge inexistente.

## 5. Inventory completo de `onConflict` (após M3.4)
| tabela | onConflict M3.4 | bridge | escopo |
|---|---|---|---|
| arena_achievements | `club_id,user_id,achievement_id` | aa_… | TENANT |
| career_path_progress | `club_id,user_id,player_id` | cpp_… | TENANT |
| arena_selected_content (×2) | `club_id,user_id,game_id` | asc_… | TENANT |
| lineup_match_progress | `club_id,user_id,match_id` | lmp_… | TENANT |
| quiz_question_progress | `club_id,user_id,question_id` | qqp_… | TENANT |
| quiz_active_session | `club_id,user_id,difficulty` | qas_… | TENANT |
| match_lineup_votes | `club_id,match_id,user_id` | mlv_… | TENANT |
| ticket_checkin_decisions (×2) | `club_id,user_id,match_id` | tcd_… | TENANT |
| player_identity_results | `user_id,club_id` | pir_… | TENANT |
| tactical_identity_results | `user_id,club_id` | tir_… | TENANT |
| user_notification_preferences | `user_id,club_id` | unp_… | TENANT |
| tickets (check-in) | — (RPC dedicada) | tickets_…_checkin | PARTIAL_RPC |
| user_notification_tokens | `fcm_token` | — | GLOBAL |
| profiles | `user_id` | — | GLOBAL |

**11 upserts diretos tenant-aware prontos (11/11), 0 legacy remanescente no novo runtime.**

## 6. GLOBAL vs TENANT
Distinguidos explicitamente — `fcm_token` (token de device) e `profiles.user_id` (identidade humana, tabela sem club_id) permanecem globais; nunca "zerar strings cegamente". Tooling marca `TENANT_CONFLICT`/`GLOBAL_CONFLICT`/`PARTIAL_RPC`.

## 7-15. Alvos por tabela (Flutter)
- **7. quiz_question_progress** → `club_id,user_id,question_id` (payload já tinha club_id/M3.2).
- **8. quiz_active_session** → `club_id,user_id,difficulty`.
- **9. career_path_progress** → `club_id,user_id,player_id` (player_id gameplay intacto).
- **10. lineup_match_progress** → `club_id,user_id,match_id` (match_id igual).
- **11. arena_selected_content** (2 owners: career_path + lineup storage) → `club_id,user_id,game_id`.
- **12. arena_achievements** → `club_id,user_id,achievement_id` (catálogo intacto).
- **12b. player/tactical identity** → `user_id,club_id` (ordem exata da bridge pir/tir).
- **13. user_notification_preferences** → `user_id,club_id`; `user_notification_tokens` intocado (GLOBAL).
- **14. match_lineup_votes** → `club_id,match_id,user_id`.
- **15. ticket_checkin_decisions** (check-in + decline) → `club_id,user_id,match_id` (bridge completa, PostgREST direto).

## 16-17. tickets — RPC dedicada
O índice do check-in de sócio é PARCIAL (`WHERE origin='membership_check_in'`) → o `onConflict:` do PostgREST só expressa colunas, nunca o predicate. Criada **`upsert_membership_checkin_ticket_for_club`** (migration `…100000`): recebe `p_club_id`, deriva o usuário de `auth.uid()` (nunca aceita `p_user_id`), valida `p_club_id`, faz `ON CONFLICT (club_id, user_id, match_id) WHERE origin='membership_check_in'`, cria/atualiza SOMENTE `origin='membership_check_in'` (nunca toca `purchase` — que segue no fluxo próprio de pedido, com club_id direto em cada linha), preserva os mesmos campos do upsert antigo, retorna a linha. O Flutter (`checkIn`) passou a chamar essa RPC.

## 18. Segurança da nova RPC
`SECURITY INVOKER` (roda como o chamador, igual `create_store_order` — a RLS OWNER de `tickets` já autoriza o próprio usuário), `set search_path = pg_catalog, public, pg_temp`, relações `public.*` schema-qualified. **ACL (regra M3.2)**: `REVOKE EXECUTE FROM public, anon, service_role` + `GRANT EXECUTE TO authenticated`, com a assinatura exata, na mesma migration (pg_default_acl reconcede default — nunca confiar).

## 19. `arena_record_score_for_club` — ON CONFLICT tenant
Migration `…090000`: `CREATE OR REPLACE` mudando SÓ o target físico do upsert em `user_game_item_progress` de `ON CONFLICT (user_id, game_id, item_id)` → **`ON CONFLICT (club_id, user_id, game_id, item_id)`** (bridge `ugip_…`). Preservados byte-a-byte: assinatura, retorno, score/cap/replay, `auth.uid()`, validação item+club, totais de ranking, `security definer`, `search_path`. ACL reafirmado no fim (revoke public/anon/service_role, grant authenticated).

## 20. `key_scope_collision` guard
**MANTIDO.** Enquanto a PK legada `(user_id, game_id, item_id)` existir, um INSERT de outro clube com a mesma (user, game, item) violaria a PK; o guard dá erro claro ANTES. Hoje nunca dispara (1 clube). Vira redundante só na M2.2B-B (quando a PK legada for trocada). Não removido nesta rodada.

## 21. ACL no CREATE OR REPLACE
Reafirmado explicitamente nas 2 migrations (mesmo em função já existente) — `REVOKE public/anon/service_role`, `GRANT authenticated`, com assinatura exata. Tooling valida o ACL esperado. (Verificação ao vivo `has_function_privilege` fica pra quando for aplicado.)

## 22. Edge — `notification_events`
`notifications-poll-live-match` (goal + full_time) e `notifications-sync-and-check-access` (match_access_open): `onConflict: 'event_type,dedupe_key'` → **`'club_id,event_type,dedupe_key'`** (bridge `ne_…`). O dedupe-lookup de goal (`.update().eq('event_type').eq('dedupe_key')`) ganhou `.eq('club_id', session.club_id)`. Payloads já tinham club_id (M3.3). **3 ocorrências tenant-aware, 0 legacy.**

## 23. Edge — `match_monitor_sessions`
NÃO tem upsert-onConflict — usa select-then-insert já filtrado por `club_id + match_id` (M3.3). Nada a mudar no conflict target; a bridge `mms_…` fica disponível pra futuro. Existência/update já club-scoped.

## 24. `notification_deliveries`
Inalterado — `onConflict: 'event_id,token_id'` (uuids), KEEP_GLOBAL/INHERITED. Não ganha club_id.

## 25. Content person call sites
`career_players`/`guess_players`/`squad_members` têm `UNIQUE(club_id, person_id)` (bridge), mas o runtime NÃO faz upsert por `person_id` (conteúdo é seed via SQL, read-only no app). Auditado: 0 call site de upsert por person_id → nada a mudar. O drop do `UNIQUE(person_id)` é M2.2B-B.

## 26. Legacy RPCs intocadas
`arena_record_score`/`crowd_lineup`/`get_my_membership`/`subscribe_to_plan`/`create_store_order`/… não modificadas. `LEGACY_RPC_PUBLIC_EXECUTE_DEBT` fora. Só as `_for_club` necessárias tocadas (arena) + 1 nova (ticket check-in).

## 27. Defaults intocados
Os 24 `DEFAULT Goiás` permanecem (LEGACY_APP_DEPENDENCY). 0 `DROP DEFAULT`.

## 28. RLS intocada
`ROW_SCOPE_READY=true`, `KEY_SCOPE_BRIDGED=true`, `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true`. Nenhuma policy criada/alterada; M3.4 não inventa active-club confiável.

## 29. Compatibility matrix
| | DB50 Bridge (remoto atual) |
|---|---|
| Old App (publicado) | ✅ (usa chave legada, intacta) |
| M3.3 App | ✅ (usa chave legada, intacta) |
| M3.4 App | ✅ esperado (usa bridge tenant-aware) |
E: **M3.4 App + DB46 (sem bridge) = ❌** (os novos conflict targets dependem das bridges). Logo `M3_4_DEPLOY_ORDER = DB_BRIDGES_FIRST` — **já satisfeito** (M2.2B-A remoto). As 2 migrations RPC (`…090000/…100000`) também precisam estar aplicadas antes do app M3.4 chamar a RPC do ticket / gravar arena pelo novo ON CONFLICT.

## 30. Deploy order (registrado, não executado)
`M2.2B-A (bridges) já remoto` → aplicar as 2 migrations RPC M3.4 (`db push`) → deploy das 3 Edge Functions → publicar o app M3.4. Nenhuma etapa distribui app nesta rodada.

## 31-34. Testes de request REAL (CapturingHttpClient + club-b sintético)
Novo grupo em `test/core/club/club_scoped_user_state_test.dart` (+8 testes, Goiás e `syntheticClubBConfig`): prova que o `on_conflict=` da query REAL agora inclui club_id (`match_lineup_votes` → `on_conflict=club_id,match_id,user_id`; `user_notification_preferences`/`player_identity` → `user_id,club_id`) e que para club-b o valor de club_id difere do UUID do Goiás (**33. teste negativo**: mesma chave lógica, club_id diferente → conflict identity diferente). **34.** check-in: `ticket_checkin_decisions` com `on_conflict=club_id,user_id,match_id` E a RPC `upsert_membership_checkin_ticket_for_club` com `p_club_id` correto e **sem `p_user_id`**. Arena já mandava `p_club_id` (M3.2) — mantido.

## 35. Testes SQL estáticos
`test_multiclub_conflict_targets.mjs`: arena com `ON CONFLICT (club_id, user_id, game_id, item_id)` (SQL real, comentários à parte) + guard mantido; ticket RPC com o predicate parcial + `auth.uid()` sem `p_user_id` + só membership; **fabricados** (não só "true"): ON CONFLICT sem club_id → reprova; ticket sem predicate → reprova; grant a anon → reprova.

## 36. Testes Edge
A lógica de conflict/dedupe das Edge está inline no entrypoint (index.ts), não extraída em módulo puro — o audit valida por grep (3× tenant, 0 legacy, deliveries global). Não transformei os entrypoints só pra teste (conforme pedido).

## 37. Migrations novas
2 (adoção, aditivas): `20260903090000_update_arena_score_tenant_conflict.sql` (CREATE OR REPLACE arena RPC) + `20260903100000_add_membership_checkin_ticket_rpc.sql` (nova RPC). Agrupadas por dependência lógica.

## 38. Migration safety
0 DROP / CASCADE / TRUNCATE / DELETE / DROP DEFAULT / DROP CONSTRAINT — verificado por teste. São compatibilidade/adoção, não enforcement.

## 39. RPC default ACL
As 2 migrations `REVOKE public/anon/service_role` + `GRANT authenticated` explicitamente (pg_default_acl reconcede) — testado.

## 40. Tooling M3.4
`audit_multiclub_conflict_targets.mjs` + `test_multiclub_conflict_targets.mjs` (17 testes). Outputs `multiclub_conflict_targets_audit.json`/`_stats.json` (reproduzíveis byte a byte).

## 41. Métricas
`directTenantUpsertsAudited=11`, `directTenantUpsertsReady=11`, `legacyConflictTargetsRemainingInNewRuntime=[]`, `partialConflictTargets=['tickets']`, `rpcConflictTargetsReady=true`, `edgeConflictTargetsReady=true`, `arenaScoreUsesTenantConflict=true`, `ticketsUsesDedicatedRpc=true`, `ticketsPartialPredicatePresent=true`, `notificationEventsTenantConflictReady=true`, `matchMonitorTenantConflictReady=true`, `bridgeDependencyCount=12`, `dbBridgePreconditionSatisfied=true`, `keyScopeCollisionGuardKept=true`, `secondClubBlocked=true`.

## 42. GLOBAL vs TENANT no tooling
Distinção explícita — ver §6. `fcm_token` e `profiles.user_id` como GLOBAL_CONFLICT, nunca marcados como falta de club_id.

## 43. RLS
Não tocada — 3 estados preservados (§28).

## 44. SECOND_CLUB
`SECOND_CLUB_BLOCKED=true` — as chaves legacy globais ainda existem e bloqueiam repetição física. Só M2.2B-B remove.

## 45-47. Worker / Passaporte / Store
**45. Worker** intocado (0 arquivo `src/`), `WORKER_DEPLOY_PENDING_GIT_PUSH=true`. **46. Passaporte** intocado (`PASSPORT_TENANCY_DEFERRED`, 1697 partidas). **47. Store** `GOI-`/`order_number`/sequence intocados (M3.4 é conflict-target adoption).

## 48. Baselines finais
`flutter analyze` **0 issues** · `flutter test` **873 passed / 1 skip** (baseline 865 + 8 do novo grupo M3.4) · JS `tooling/**/test_*.mjs` **703 passed / 0 fail** (686 + 17 do conflict_targets; 2 tooling de etapas anteriores atualizados — ver "Autoconsertos"). Worker vitest **não re-rodado** (0 arquivo `src/`).

## 49. Supabase
`migration list` **52 local / 50 remote / 2 pending**; `db push --dry-run` lista EXATAMENTE as 2 migrations M3.4, `seeds:[] roles:[]`. **0 db push.**

## Autoconsertos de tooling de etapas anteriores (M3.4 os invalidou legitimamente)
- `test_multiclub_key_scope.mjs` (M2.2B) afirmava `appOnConflictKeysWithClub===[]` ("nenhum onConflict do app tem club_id"). A M3.4 tornou-os tenant-aware de propósito → o grep ao vivo passou a incluir club_id. Congelei `appOnConflicts` como **snapshot histórico PRÉ-M3.4** no `audit_multiclub_key_scope.mjs` (com nota apontando pra este doc), pra o audit da M2.2B seguir sendo um registro fiel da sua rodada. O gate de compat da M2.2B (o app PUBLICADO usa chave legada) continua verdadeiro.
- `audit_multiclub_runtime_user_state_scope.mjs` (M3.2) esperava `tickets` como upsert direto. A M3.4 moveu o check-in pra RPC (`upsert_membership_checkin_ticket_for_club`); o audit passou a reconhecer esse caminho + a janela do `purchase` (que segue gravando club_id direto em cada linha). 33/33→35/35.

## Estados
`ROW_SCOPE_READY` ✅ · `KEY_SCOPE_BRIDGED=true` · `KEY_SCOPE_FINAL=false` · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` · `SECOND_CLUB_BLOCKED=true` · `NEW_RUNTIME_CONFLICT_TARGETS_ARE_TENANT_AWARE=true`.

## git diff --stat / status
Modificados: 9 repos Flutter (onConflict), 2 Edge (notification_events), o teste (+8), 2 tooling de etapas anteriores + seus JSONs. Novos (untracked): 2 migrations M3.4, 2 tooling conflict_targets, 2 JSONs, este relatório. Fora-de-escopo pré-existentes preservados. **0 arquivo `src/` (Worker).**

## 49-51. 0 db push · 0 commit · 0 git push
Confirmados. Também: 0 Edge deploy, 0 Worker deploy, 0 DROP legacy/DEFAULT, 0 M2.2B-B, 0 M4, 0 segundo clube.

---

## RODADA 2 — Aplicação + Edge deploy + commit (2026-09-03)

Autorização do usuário: "M3.4 — AUTORIZADA APLICAÇÃO + EDGE DEPLOY + COMMIT" (32 pontos). Entrada: DB=50/50, 18 bridges ativos, M3.4 local 52/50/2 pending, flutter 873/1 skip, JS 703/0.

### 1. Preflight
HEAD `5e93b85` confirmado. `git status` bateu exatamente com o inventário da rodada 1. `migration list` → 52 local / 50 remote / 2 pending. `db push --dry-run` listou EXATAMENTE `20260903090000` e `20260903100000`.

### 2. Bridges live
18/18 índices com `indisunique=indisvalid=indisready=true`, incluindo os 2 críticos revalidados por definição: `ugip_club_user_game_item_uidx` e `tickets_club_user_match_checkin_uidx`.

### 3. Tickets precondition
Policies confirmadas idênticas (`insert own tickets` WITH CHECK `auth.uid()=user_id`; `read own tickets` USING `auth.uid()=user_id`; `update own tickets` USING+WITH CHECK `auth.uid()=user_id`). `authenticated` com SELECT/INSERT/UPDATE (+DELETE/REFERENCES/TRIGGER/TRUNCATE) em `public.tickets`.

### 4. Arena pré-push
`pg_get_functiondef` capturado: `security definer`, `search_path=pg_catalog,public,pg_temp`, `on conflict (user_id, game_id, item_id)` (target legado — ainda não migrado). ACL pré: authenticated=true, anon=false, service_role=false, public=false.

### 5. Ticket RPC não existia
`count(*) = 0` confirmado antes do primeiro push.

### 6. INCIDENTE — `FIRST_DB_PUSH_PARTIAL_SUCCESS`
`npx supabase db push` (1ª tentativa) aplicou `20260903090000` com sucesso, mas falhou em `20260903100000` com:
```
ERROR: function public.upsert_membership_checkin_ticket_for_club(uuid, text, text, text, integer, text, integer, integer, timestamp with time zone, ...) does not exist (SQLSTATE 42883)
At statement: revoke execute on function ...
```
**Causa raiz**: drift de tipo na posição 8 do parâmetro entre o `CREATE FUNCTION` (real: `..., int, text, timestamptz, ...` — `p_away_team_name text`) e o `REVOKE`/`GRANT EXECUTE` (referenciava `..., int, int, timestamptz, ...` — `int` duplicado por engano). Como nenhuma função com essa assinatura existia, o Postgres recusou o `REVOKE` e a transação da migration inteira foi revertida.
**Resultado imediato**: `20260903090000` aplicada e permaneceu aplicada (transação própria, não afetada pelo erro do arquivo seguinte); `20260903100000` **0% aplicada** — `count(*) from pg_proc` confirmou **zero** objeto parcial/órfão deixado. **Nenhum conserto ao vivo, nenhum `migration repair`, nenhum DDL manual foram tentados** — parei exatamente conforme instruído e reportei o estado exato antes de qualquer ação.

### Correção (arquivo local ainda não aplicado, sem migration nova)
Editada SOMENTE a linha do `REVOKE`/`GRANT` em `20260903100000_add_membership_checkin_ticket_rpc.sql`, trocando o `int` da posição 8 por `text` — nenhuma mudança de nome/ordem/tipo de parâmetro do `CREATE FUNCTION`, nenhuma mudança de corpo, `SECURITY INVOKER`, `search_path` ou predicate do `ON CONFLICT`.

### Detector novo — `FUNCTION_SIGNATURE_ACL_MATCH`
Adicionado a `audit_multiclub_conflict_targets.mjs` (`checkFunctionSignatureAclMatch`): extrai os tipos de parâmetro do `CREATE FUNCTION` e de cada ocorrência de `REVOKE`/`GRANT EXECUTE` no mesmo arquivo, normaliza aliases (`integer↔int`, `timestamp with time zone↔timestamptz`, etc.) e compara posição a posição. `audit.arena.functionSignatureAclMatch` e `audit.ticketRpc.functionSignatureAclMatch` (+ gate agregado `stats.functionSignatureAclMatchAll`) agora fazem parte do audit padrão. Provado com **3 casos fabricados** em `test_multiclub_conflict_targets.mjs`: (a) reprodução exata do bug real (posição 8 `text`→`int`) — reprova com o mismatch exato reportado; (b) número de parâmetros divergente — reprova por `reason: 'length'`; (c) aliases de tipo equivalentes — não gera falso positivo. Este detector teria pego o bug real ANTES do `db push`.

### 4 (retomado). Suíte JS completa
`tooling/**/test_*.mjs` (23 arquivos) → **709 passed / 0 failed** (baseline 703 + 6 novos testes do detector). Nenhum outro teste regrediu.

### 5 (retomado). Repreflight
`migration list` → 52 local / 51 remote / 1 pending. `db push --dry-run` listou EXATAMENTE `20260903100000_add_membership_checkin_ticket_rpc.sql` — nada mais (090000 não reapareceu).

### 6 (retomado). Estado remoto confirmado antes do retry
Arena já com `on conflict (club_id, user_id, game_id, item_id)`, guard mantido, `security definer=true`; ticket RPC `count=0`. Estado parcial (090000 aplicada / 100000 não) confirmado.

### 7. Arena revalidada (já aplicada, antes do 2º push)
`pg_get_functiondef`: `tenant_conflict=true`, `guard_kept=true`, `prosecdef=true`, `search_path=pg_catalog,public,pg_temp`. ACL via `has_function_privilege`: authenticated=true, anon=false, service_role=false, public=false.

### 8. Retry do `db push`
`npx supabase db push` (2ª tentativa) aplicou SOMENTE `20260903100000_add_membership_checkin_ticket_rpc.sql`. **Sucesso, sem erro.**

### 9. Pós-push
`migration list` → **52 local / 52 remote / 0 pending / 0 mismatch**. `db push --dry-run` → `"Remote database is up to date."`.

### 10-11. Ticket RPC — existência, assinatura, SQL real
Exatamente 1 função, `p_club_id uuid` como 1º parâmetro, **sem `p_user_id`**. `pg_get_functiondef` confirma `v_uid uuid := auth.uid();` como única fonte do usuário, `on conflict (club_id, user_id, match_id) where origin = 'membership_check_in'`, e `origin` fixado como literal `'membership_check_in'` no INSERT (nunca vindo de parâmetro do cliente) — nunca toca `origin='purchase'`.

### 12. SECURITY INVOKER
`prosecdef=false`, `search_path=pg_catalog,public,pg_temp`, `public.tickets`/`public.clubs` schema-qualified.

### 13. ACL efetivo (ticket RPC)
`has_function_privilege`: authenticated=true, anon=false, service_role=false, public=false. Não inferido do SQL da migration — validado ao vivo.

### 14. RLS e legacy
3 policies de `tickets` idênticas antes/depois (0 criada/alterada). `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` continua.

### 15. Legacy RPC intacta
`arena_record_score` (legacy) existe e não foi tocada — só `arena_record_score_for_club` mudou.

### 16. Legacy keys intactas
`user_game_item_progress_pkey` = `PRIMARY KEY (user_id, game_id, item_id)` presente. `tickets_user_match_checkin_uidx` (parcial legado, `(user_id, match_id) WHERE origin='membership_check_in'`) presente JUNTO com `tickets_club_user_match_checkin_uidx` (tenant). **0 DROP em M3.4.**

### 17. Sem dados artificiais
Nenhum ticket/score/user/club-b/evento fabricado no Supabase — toda validação foi leitura (`pg_get_functiondef`, `pg_proc`, `pg_policy`, `pg_indexes`, `has_function_privilege`) + suíte local.

### 18. Edge diff
`git status` confirmou SOMENTE `notifications-poll-live-match/index.ts` e `notifications-sync-and-check-access/index.ts` modificados; `notifications-dispatch/index.ts` sem diff.

### 19. `notification_events` pré-deploy
3 ocorrências de `onConflict: 'club_id,event_type,dedupe_key'` (2 em poll-live-match, 1 em sync-and-check-access), 0 ocorrência do legacy `event_type,dedupe_key` (grep direto no diretório).

### 20. `match_monitor_sessions`
Confirmado: nenhum `.upsert`/`onConflict` — só `.select`/`.insert` (select-then-insert club-scoped, herdado da M3.3). Nenhuma mudança oportunista.

### 21. Edge deploy
`npx supabase functions deploy notifications-poll-live-match notifications-sync-and-check-access` — SOMENTE as 2. `notifications-dispatch`, `delete-account`, `cleanup-unconfirmed-signups` NÃO deployadas.

### 22. Edge pós-deploy
`functions list`: `notifications-poll-live-match` e `notifications-sync-and-check-access` → **v4**, mesmo `updated_at` (deploy desta rodada). `notifications-dispatch` v3, `delete-account` v2, `cleanup-unconfirmed-signups` v1 — `updated_at` anteriores, confirmadamente não tocadas. CLI não oferece logs de invocação em tempo real (mesma limitação documentada na M3.3) — nenhum evento artificial gerado pra contornar.

### 23. Flutter
`flutter analyze` → **0 issues**. `flutter test` → **873 passed / 1 skip** — idêntico ao esperado.

### 24. JS
`tooling/**/test_*.mjs` → **709 passed / 0 failed** (703 + 6 do detector novo).

### 25. CapturingHttpClient
`test/core/club/club_scoped_user_state_test.dart` mantém as 19 ocorrências de `p_club_id`/onConflict tenant (11 diretos + ticket RPC `p_club_id` sem `p_user_id` + club-b sintético nunca usa Goiás) — cobertura não reduzida pós-deploy.

### 26. Compatibility matrix pós-M3.4 server
Old App + DB52 = ✅ · M3.3 App + DB52 = ✅ · M3.4 App + DB52 = ✅ (legacy constraints e RPCs continuam existindo). M3.4 App + DB46 = ❌ continua sendo fato histórico de deploy order (bridges precisam vir primeiro).

### 27. Estados pós-M3.4
`ROW_SCOPE_READY=true` · `KEY_SCOPE_BRIDGED=true` · `NEW_RUNTIME_CONFLICT_TARGETS_ARE_TENANT_AWARE=true` · `KEY_SCOPE_FINAL=false` · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` · `SECOND_CLUB_BLOCKED=true`.

### 28. Gate novo — app ainda não distribuído
`M3_4_CODE_COMPLETE=true` · `M3_4_DB_APPLIED=true` · `M3_4_EDGE_DEPLOYED=true` · `M3_4_APP_DISTRIBUTED=false` → **`M2_2B_B_BLOCKED_BY_APP_ROLLOUT=true`**. M2.2B-B (remoção de constraints legacy) só pode começar depois de: (1) app M3.4 publicado de verdade para usuários finais, (2) estratégia de retirar/bloquear versões antigas, (3) confirmação de adoção/versão mínima. **Commit local NÃO conta como distribuição.**

### 29. Worker
Não tocado — 0 arquivo em `src/` (Worker). `WORKER_DEPLOY_PENDING_GIT_PUSH=true` continua.

### 30. Passaporte / Store / Defaults / RLS
Todos intocados nesta rodada: `PASSPORT_TENANCY_DEFERRED`, `GOI-`/`order_number` intactos, 24 `DEFAULT Goiás` intactos, RLS intacta (§14).

### 31. Commit
Todos os critérios de "tudo verde" satisfeitos: DB 52/52 ✅ · 2 RPCs corretas ✅ · ACL efetivo 2/2 ✅ · RLS intacta ✅ · legacy intacta ✅ · Edge deploy 2/2 ✅ · Flutter green ✅ · JS green ✅. Commit local feito com paths explícitos (nunca `git add .`); hash registrado em follow-up de docs. **0 git push.**

## Estados finais (rodada 2)
`ROW_SCOPE_READY=true` · `KEY_SCOPE_BRIDGED=true` · `KEY_SCOPE_FINAL=false` · `NEW_RUNTIME_CONFLICT_TARGETS_ARE_TENANT_AWARE=true` · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` · `SECOND_CLUB_BLOCKED=true` · `M3_4_CODE_COMPLETE=true` · `M3_4_DB_APPLIED=true` · `M3_4_EDGE_DEPLOYED=true` · `M3_4_APP_DISTRIBUTED=false` · `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=true` · `WORKER_DEPLOY_PENDING_GIT_PUSH=true`.

---

**APLICADO E COMMITADO LOCALMENTE.** Não iniciar M2.2B-B (bloqueado por rollout do app). Não iniciar M4. Não cadastrar segundo clube. `0 git push` — aguardando instrução explícita para push, se/quando desejado.

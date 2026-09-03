# Legacy Contract Retirement Audit — WEB/PWA-first

Data: 2026-09-03
Status: **AUDIT ONLY. 0 db push, 0 commit, 0 git push, 0 Edge deploy, 0 M2.2B-B, 0 DROP, 0 REVOKE remoto, 0 segundo clube.**

Pergunta central: o fechamento das constraints/DEFAULT legacy que M2.2B-B já tinha no escopo (PK/UNIQUE swap + `DROP DEFAULT`) é, sozinho, **tecnicamente suficiente** pra aposentar os writes do PWA publicado — sem precisar converter tudo pra RPC-only?

**Resposta: sim.** `rpcOnlyMigrationRequired = false`, `legacyContractRetirementReady = true` (sentido técnico — ver ressalva no final, não reabre `M2_2B_B_BLOCKED_BY_APP_ROLLOUT`).

---

## 0. Baseline

`origin/main` = `613874a7e00073c19560f8a9ebe0325efc395c0a` ("Update X posts feed", 2026-09-02 13:07 UTC). `HEAD` = `21555d903b52ada7e181e5ffd78f63fb54a013a3`. **35 commits atrás** — a mesma baseline confirmada no rollout gate (é literalmente o código que o deployment web ao vivo roda).

---

## 1. Matriz completa — feature × old vs M3.4

| Feature | Tabela | Old mechanism | Old target | M3.4 mechanism | M3.4 target | Fecha por |
|---|---|---|---|---|---|---|
| Arena — conquista 100% | `arena_achievements` | upsert onConflict | `user_id,achievement_id` | upsert onConflict | `club_id,user_id,achievement_id` | **KEY** |
| Arena — progresso Quem Vestiu | `career_path_progress` | upsert onConflict | `user_id,player_id` | upsert onConflict | `club_id,user_id,player_id` | **KEY** |
| Arena — jogo selecionado (career_path) | `arena_selected_content` | upsert onConflict | `user_id,game_id` | upsert onConflict | `club_id,user_id,game_id` | **KEY** |
| Arena — progresso Escalação | `lineup_match_progress` | upsert onConflict | `user_id,match_id` | upsert onConflict | `club_id,user_id,match_id` | **KEY** |
| Arena — jogo selecionado (lineup) | `arena_selected_content` | upsert onConflict | `user_id,game_id` | upsert onConflict | `club_id,user_id,game_id` | **KEY** |
| Arena — Que Craque Você É | `player_identity_results` | upsert onConflict | `user_id` | upsert onConflict | `user_id,club_id` | **KEY** |
| Arena — Quiz (progresso) | `quiz_question_progress` | upsert onConflict | `user_id,question_id` | upsert onConflict | `club_id,user_id,question_id` | **KEY** |
| Arena — Quiz (sessão) | `quiz_active_session` | upsert onConflict | `user_id,difficulty` | upsert onConflict | `club_id,user_id,difficulty` | **KEY** |
| Arena — Identidade Tática | `tactical_identity_results` | upsert onConflict | `user_id` | upsert onConflict | `user_id,club_id` | **KEY** |
| Escalação da Torcida — voto | `match_lineup_votes` | upsert onConflict | `match_id,user_id` | upsert onConflict | `club_id,match_id,user_id` | **KEY** |
| Preferências de notificação | `user_notification_preferences` | upsert onConflict | `user_id` | upsert onConflict | `user_id,club_id` | **KEY** |
| Ingresso — check-in (decisão) | `ticket_checkin_decisions` | upsert onConflict | `user_id,match_id` | upsert onConflict | `club_id,user_id,match_id` | **KEY** |
| Ingresso — recusa (decisão) | `ticket_checkin_decisions` | upsert onConflict | `user_id,match_id` | upsert onConflict | `club_id,user_id,match_id` | **KEY** |
| Arena — pontuação (`user_game_item_progress`) | `user_game_item_progress` | RPC `arena_record_score` | `on conflict (user_id,game_id,item_id)` | RPC `arena_record_score_for_club` | `on conflict (club_id,user_id,game_id,item_id)` | **KEY** |
| Arena — pontuação (`score_events`) | `score_events` | RPC `arena_record_score` (insert simples) | nenhum | RPC `arena_record_score_for_club` | club_id explícito | DEFAULT (redundante — a transação já falha antes) |
| Loja — criação de pedido | `store_orders` | RPC `create_store_order` (insert simples) | nenhum | RPC `create_store_order_for_club` | club_id explícito | **DEFAULT** |
| Loja — itens do pedido | `store_order_items` | insert simples (via RPC) | nenhum (tabela sem `club_id`) | idem | escopo via FK `order_id` | fora de escopo (sem coluna) |
| Sócio Torcedor — assinatura | `supporter_memberships` | RPC `subscribe_to_plan` (insert simples) | nenhum | RPC `subscribe_to_plan_for_club` | club_id explícito | **DEFAULT** |
| Ingresso — pedido de compra | `ticket_orders` | insert simples | nenhum | insert simples | club_id explícito | **DEFAULT** |
| Ingresso — linhas de compra | `tickets` (`origin=purchase`) | insert simples | nenhum | insert simples | club_id explícito | **DEFAULT** |
| Ingresso — check-in (o ingresso em si) | `tickets` (`origin=membership_check_in`) | upsert onConflict | `user_id,match_id` | RPC dedicada `upsert_membership_checkin_ticket_for_club` | predicate parcial | **JÁ QUEBRADO** (achado desta rodada, ver §8) |
| Token de push (FCM) | `user_notification_tokens` | upsert onConflict | `fcm_token` | idem | `fcm_token` | fora de escopo (GLOBAL) |
| Perfil do usuário | `profiles` | upsert onConflict | `user_id` | idem | `user_id` | fora de escopo (GLOBAL) |

---

## 2. Direct PostgREST legacy writes — `AUTO_RETIRED_BY_KEY_ENFORCEMENT`

**14 writes** (13 diretos do Flutter + 1 dentro da RPC `arena_record_score`) usam `ON CONFLICT`/`onConflict:` numa chave que M2.2B-B troca. Verificado o mecanismo Postgres exato: depois da troca de PK/UNIQUE, `INSERT ... ON CONFLICT (colunas-antigas)` deixa de casar com QUALQUER constraint única existente e o Postgres recusa com `SQLSTATE 42883`/`42P10` ("there is no unique or exclusion constraint matching the ON CONFLICT specification") — falha limpa, alta, nunca grava dado errado silenciosamente. **Nenhuma RPC nova precisa ser criada só pra impedir isso — a própria troca de chave já impede, naturalmente.**

## 3. RPC legacy — inventário completo

Extraído via `git show origin/main:<file>` (reproduzível, ver tooling §12) contra o mesmo grep em HEAD:

| RPC legacy | Tipo | Substituta M3.2/M3.4 | HEAD ainda chama a legacy? | Classificação |
|---|---|---|---|---|
| `arena_record_score` | WRITE | `arena_record_score_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `arena_ranking` | READ | `arena_ranking_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `arena_my_rank` | READ | `arena_my_rank_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `arena_user_detail` | READ | `arena_user_detail_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `crowd_lineup` | READ (tally) | `crowd_lineup_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `get_my_membership` | READ | `get_my_membership_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `subscribe_to_plan` | WRITE | `subscribe_to_plan_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `create_store_order` | WRITE | `create_store_order_for_club` | Não | `SAFE_TO_REVOKE_AFTER_WEB_ROLLOUT` |
| `cpf_is_taken` | READ | — (nunca precisou de club) | Sim | `STILL_REQUIRED` |
| `passport_*` (11 RPCs) | 9 READ + 2 WRITE | — | Sim | `STILL_REQUIRED` (`OUT_OF_SCOPE_PASSPORT_DEFERRED` — as tabelas de passaporte não têm `club_id`, deferido desde M2.2B round 1) |
| `upsert_membership_checkin_ticket_for_club` | WRITE | — (nova) | Sim | Não existe em `origin/main` — M3.4 |

**8 RPCs "dual-track"** (legacy existe + `_for_club` existe, HEAD só chama a `_for_club`) — todas foram criadas já na **M3.2** ("scope user state runtime by club"), não na M3.4. **Nenhuma foi revogada nesta rodada** (`safeToRevokeLegacyRpcs=0`) — o cliente legacy (PWA ao vivo) ainda depende delas hoje. Elas se tornam candidatas a `REVOKE EXECUTE` só depois que o retirement de verdade acontecer (fora desta rodada).

## 4. Legacy direct INSERT sem onConflict — os casos perigosos

**5 writes** são `INSERT` simples, sem `ON CONFLICT` nenhum, e por isso **sobrevivem à mera remoção da chave legacy**:

1. `score_events` (dentro de `arena_record_score`) — redundante na prática (a mesma transação já falha antes, no insert de `user_game_item_progress`).
2. `store_orders` (dentro de `create_store_order`).
3. `supporter_memberships` (dentro de `subscribe_to_plan`).
4. `ticket_orders` (compra de ingresso).
5. `tickets` com `origin='purchase'` (linhas de compra).

Classificação: `LEGACY_WRITE_SURVIVES_KEY_ENFORCEMENT=true` pra estes 5 — **key-drop sozinho NÃO os impede.** Nenhuma RPC nova foi criada pra fechá-los (conforme instruído) — o que os fecha é o item §5.

## 5. DEFAULT Goiás — `AUTO_RETIRED_BY_DEFAULT_REMOVAL`

Todos os 5 writes do §4 nunca incluem `club_id` no payload (o conceito não existia em `origin/main`) — dependem inteiramente do `DEFAULT '4c16340d-300c-5ab2-903f-17519db9b146'::uuid`. Confirmado ao vivo: `store_orders`, `supporter_memberships`, `ticket_orders`, `tickets`, `score_events` estão TODAS nas 24 tabelas com esse DEFAULT. **Se M2.2B-B fizer `DROP DEFAULT`** (que já estava no escopo original do M2.2B-B, junto com os swaps de PK — ver `project_goias_app_multiclub_audit` memory), esses 5 `INSERT`s passam a omitir uma coluna `NOT NULL` sem default → **`NOT NULL violation`, falha limpa** → `AUTO_RETIRED_BY_DEFAULT_REMOVAL=true` pros mesmos 5.

**Juntando §2 (14 fecham por KEY) + §5 (5 fecham por DEFAULT) = 19 dos 20 writes tenant-scoped fecham tecnicamente, sem nenhuma RPC nova.** O 20º (`tickets` check-in) já está morto por outro motivo — ver §8.

---

## 6. PWA stale cache — o gate real nunca é "novo PWA foi deployado"

Confirmado o raciocínio pedido: mesmo que um browser mantenha um bundle antigo em cache por muito tempo (o build publicado TEM o service worker padrão do Flutter, `flutter_service_worker.js`, confirmado HTTP 200 no deployment ao vivo — ver §10), a classificação inteira desta auditoria **nunca depende de saber se o cliente atualizou**. O fechamento é 100% server-side (KEY+DEFAULT) — um bundle antigo que nunca vai atualizar sozinho continua tentando escrever exatamente como sempre escreveu, e o SERVIDOR é quem recusa. Isso é a definição certa de `SERVER_ENFORCED_CONTRACT` (§7).

## 7. `CLIENT_VERSION_SIGNAL != SERVER_ENFORCED_CONTRACT` — mantido

Nenhum design desta rodada depende de o cliente declarar sua versão/build. Toda a classificação KEY/DEFAULT funciona **mesmo que o bundle antigo minta sobre quem é** — porque a decisão nunca está no cliente. Isso é consistente com a correção conceitual da rodada anterior ([[project-goias-app-rollout-gate]]).

---

## 8. Achado incidental — ticket check-in JÁ está quebrado em produção

Durante a auditoria do write #20 (tickets, check-in), a `EXPLAIN` (read-only, nenhuma escrita real) do exato SQL que `origin/main`'s `.upsert({...}, onConflict: 'user_id,match_id')` gera contra a tabela `tickets` retornou:

```
ERROR: 42P10: there is no unique or exclusion constraint matching the ON CONFLICT specification
```

**Causa**: a ÚNICA unique constraint cobrindo `(user_id, match_id)` em `tickets` é **parcial** (`tickets_user_match_checkin_uidx ... WHERE origin = 'membership_check_in'`) — e Postgres só aceita um índice parcial como árbitro de `ON CONFLICT (colunas)` se a cláusula tiver o `WHERE` explícito batendo com o predicado do índice; `onConflict:` do PostgREST só expressa colunas, nunca predicate (a mesma limitação que a M3.4 já tinha identificado — e corrigido — pra chave NOVA, sem perceber que a chave LEGACY tem o mesmo problema).

**Isso não foi introduzido pelo trabalho multiclub.** A constraint já nasceu parcial (`supabase/tickets.sql` linha 110-112, comentário original da própria migration já dizia "permite `upsert(onConflict: 'user_id,match_id')`" — uma suposição que se mostra incorreta sob este teste). **Consequência real**: hoje, qualquer usuário tentando fazer check-in de sócio pelo PWA publicado recebe um erro — a feature não funciona, independente de M2.2B-B. Achado incidental, fora do escopo desta rodada consertar (0 db push/commit) — registrado aqui pra o dono decidir quando tratar.

---

## 9. Critério de fechamento

```
OLD_DIRECT_UPSERTS_BLOCKED_BY_KEY_REMOVAL = true   (14/14 dos writes por onConflict)
OLD_LEGACY_RPCS_BLOCKED_BY_REVOKE = false          (0 RPC revogada nesta rodada — nenhuma REVOKE remota, por instrução)
OLD_DEFAULT_DEPENDENT_WRITES_BLOCKED = true        (5/5, SE DROP DEFAULT acontecer junto do PK swap)
OLD_UNVERSIONED_WRITES_REMAINING = 0
```

→ **`RPC_ONLY_MIGRATION_REQUIRED = false`**

Nenhum write residual exige nova arquitetura RPC. `OLD_LEGACY_RPCS_BLOCKED_BY_REVOKE=false` é esperado e correto — REVOKE remoto estava explicitamente proibido nesta rodada, não é uma lacuna técnica, é a regra desta auditoria.

---

## 10. Worker/PWA — mecanismo real do deploy (auditado, 0 push)

- **Build command** (Cloudflare dashboard, git-integrado): `flutter build web --release` + `npm install` — baixa o SDK Flutter do zero a cada build (~2-3min). ([[reference-goias-app-cloudflare-worker]])
- **Publica `build/web`**: sim — `wrangler.toml` `[assets] directory = "build/web"`, `not_found_handling = "single-page-application"`.
- **Worker e PWA sobem juntos?** Sim — é **um único** `wrangler deploy` atômico: os assets estáticos (Flutter web) E as rotas `/api/football/*`/etc. do mesmo `fetch()` handler sobem na mesma operação. Não dá pra atualizar um sem o outro.
- **Cache purge**: não automático — `CACHE_VERSION` em `wrangler.toml [vars]` precisa ser bumped manualmente quando o *formato* de uma resposta de API muda (não afeta os assets do Flutter, só os endpoints `/api/*`). Os assets do Flutter web em si usam `Cache-Control: public, max-age=0, must-revalidate` (confirmado nos headers ao vivo) — Cloudflare CDN pode cachear (`CF-Cache-Status`), mas `max-age=0` força revalidação a cada request, então o CDN não é o principal risco de staleness aqui.
- **`version.json`**: gerado automaticamente pelo `flutter build web` (não é código deste projeto) — contém `app_name`/`version`/`build_number`/`package_name`, sempre reflete o `pubspec.yaml` do commit que gerou o build.
- **Service worker Flutter**: **sim, existe** — `flutter_service_worker.js` confirmado `HTTP 200` no deployment ao vivo, registrado pelo `flutter_bootstrap.js` padrão (`_flutter.loader`, com timeout de 4000ms pra ativação). Isso significa que um browser que já visitou o app pode continuar servindo o bundle JS antigo do cache do service worker por um tempo, mesmo depois de um redeploy — reforça a conclusão do §6 (o gate real tem que ser server-side, nunca "o PWA foi atualizado").

---

## 11. Números reais (origin/main diff)

- **Commits atrás**: 35.
- **Arquivos afetando writes** (diff `origin/main..HEAD` em `lib/features/*/data/*.dart` + `lib/features/arena/ranking/data/*` + `lib/features/ticket/data/*`): 17 arquivos modificados que tocam pelo menos 1 write.
- **Legacy RPC call sites**: 20 nomes distintos de RPC chamados por `origin/main` (9 dual-track write/read + `cpf_is_taken` + 11 `passport_*`).
- **Legacy onConflict call sites**: 16 (`.upsert(..., onConflict: ...)` diretos no Flutter — 13 tenant + 2 global + 1 já quebrado).
- **Legacy direct writes** (insert/update/delete sem onConflict, em tabelas tenant-scoped): 5 fecham só por DEFAULT + `store_order_items` (fora de escopo, sem coluna `club_id`) + updates/deletes por `WHERE` (não dependem de KEY nem DEFAULT — `undoCheckIn`, `clearCheckInDecision`, deativar token, editar perfil, endereço de entrega — inertes a este audit, continuam funcionando de qualquer jeito, sem risco de dado cruzado enquanto `SECOND_CLUB_BLOCKED=true`).

---

## 12. Tooling

`tooling/multiclub/audit_legacy_contract_retirement.mjs` + `test_legacy_contract_retirement.mjs` (16 testes). A extração dos nomes de RPC é feita via `git show origin/main:<file>` + regex tolerante a generics aninhados (`.rpc<Map<String, dynamic>>(...)`), e verificada contra o inventário manual (`rpcInventoryMatchesCode=true` — o inventário bate com o código real, não foi hardcoded às cegas). Métricas finais:

```json
{
  "oldDirectUpserts": 16,
  "autoRetiredByKeyEnforcement": 14,
  "legacyRpcsUsed": 8,
  "legacyRpcsUsedWrites": 3,
  "safeToRevokeLegacyRpcs": 0,
  "legacyWritesSurvivingKeyEnforcement": 5,
  "defaultDependentLegacyWrites": 5,
  "autoRetiredByDefaultRemoval": 5,
  "unversionedLegacyWritesRemaining": 0,
  "alreadyBrokenIndependentOfM2_2bB": 1,
  "outOfScopeNoClubIdColumn": 1,
  "globalWritesOutOfScope": 2,
  "rpcOnlyMigrationRequired": false,
  "legacyContractRetirementReady": true,
  "commitsBehindOriginMain": 35,
  "rpcInventoryMatchesCode": true
}
```

Não manipulado pra dar verde — o script tem um caso fabricado (§9 do arquivo de teste) provando que ele REPROVARIA se existisse 1 write real sem cobertura de KEY nem DEFAULT.

## 13. Resultado — não forçado

`legacyContractRetirementReady=true` é o resultado REAL desta auditoria, não um ajuste. Se tivesse dado `false`, o relatório listaria só os writes residuais (nenhum existe desta vez).

## 14. Baselines (inalterados — 0 arquivo Flutter tocado nesta rodada)

`flutter analyze`: **0 issues**. `flutter test`: **894 passed / 1 skip** (reconfirmado — nenhum `.dart` tocado nesta etapa). JS: **743 passed / 0 failed** (727 da rodada anterior + 16 novos desta). DB: **53 local / 52 remote / 1 pending** (a migration do release gate, ainda local — nada mudou aqui, nenhuma migration nova desta rodada).

---

## 15. Respostas objetivas (1-25)

1. `origin/main` = `613874a7e00073c19560f8a9ebe0325efc395c0a`. 2. `HEAD` = `21555d903b52ada7e181e5ffd78f63fb54a013a3`. 3. **35 commits atrás**. 4. Old onConflict: 16 call sites (§1/§2). 5. New onConflict: as mesmas 14 tabelas com `club_id` prefixado/sufixado + 2 globais inalteradas + 1 virou RPC dedicada. 6. Old RPC: 20 nomes (§3). 7. RPC substituta: 8 têm `_for_club` (§3); `passport_*`/`cpf_is_taken` não têm (fora de escopo). 8. Direct inserts: 6 (`score_events`, `store_orders`, `store_order_items`, `supporter_memberships`, `ticket_orders`, `tickets`-compra). 9. Updates: `ticket_checkin_decisions`→`declined`, `tickets`→`cancelled`, `user_notification_tokens`→`is_active=false`, `profiles` — nenhum depende de KEY/DEFAULT (são `UPDATE...WHERE`, não `INSERT`). 10. Deletes: `ticket_checkin_decisions`, `user_addresses`/`delivery_addresses` — mesma observação. 11. Dependências de DEFAULT: 5 writes tenant-scoped (§5), confirmadas ao vivo nas 24 tabelas com `DEFAULT <GoiasUUID>`. 12. Writes auto-retirados por key-drop: 14 (§2). 13. Writes auto-retirados por DROP DEFAULT: 5 (§5). 14. RPCs seguras pra revoke (candidatas pós-rollout, NENHUMA revogada agora): 8. 15. Writes que sobrevivem a M2.2B-B (key+default juntos): **0** (§9). 16. PWA stale cache: gate real é server-side, nunca "app atualizou" (§6). 17. Cloudflare: build+deploy atômico, `build/web` publicado junto com a API, cache purge manual só pra `/api/*`, service worker Flutter real e ativo (§10). 18. Service worker: confirmado `HTTP 200`, padrão Flutter (`flutter_bootstrap.js`+`_flutter.loader`). 19. `rpcOnlyMigrationRequired = false`. 20. `legacyContractRetirementReady = true` (técnico — ver ressalva). 21. JS: **743/0**. 22. DB: **53 local/52 remote/1 pending**, inalterado. 23. **0 db push.** 24. **0 commit.** 25. **0 git push.**

---

## Ressalva final — não confundir "tecnicamente fechável" com "seguro executar agora"

`legacyContractRetirementReady=true` responde exatamente a pergunta técnica desta rodada: **não precisamos de RPC-only**. Isso **não** flipa `M2_2B_B_BLOCKED_BY_APP_ROLLOUT` pra `false`. Esse gate (da rodada anterior) é sobre **impacto no usuário** de um deployment AO VIVO — mesmo que o fechamento seja tecnicamente limpo (erro claro, não dado corrompido), rodar M2.2B-B hoje faria toda escrita do PWA publicado começar a **falhar visivelmente pra quem estiver usando** (check-in, compra, quiz, tudo) sem nenhum aviso, sem redeploy prévio, sem tela de manutenção. Isso continua sendo uma decisão de produto separada, não resolvida por esta auditoria — que só prova que, QUANDO essa decisão for tomada, a arquitetura já está pronta sem precisar de trabalho extra de RPC.

---

## Estados

`RPC_ONLY_MIGRATION_REQUIRED=false` · `LEGACY_CONTRACT_RETIREMENT_READY=true` (técnico) · `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=true` (inalterado — não é o mesmo gate) · `LEGACY_CLIENTS_IN_THE_WILD=true` (inalterado) · `SECOND_CLUB_BLOCKED=true` · `WORKER_DEPLOY_PENDING_GIT_PUSH=true`.

---

**PARADO PARA REVISÃO.** 0 M2.2B-B iniciada. 0 write convertido pra RPC. 0 REVOKE remoto. 0 DROP. Achado incidental (ticket check-in quebrado) registrado, não consertado. Aguardando decisão do dono sobre: (1) quando/como tratar o bug do check-in (fora do escopo desta etapa), (2) a decisão de produto sobre retirar/redeployar o cliente legacy ao vivo antes de M2.2B-B.

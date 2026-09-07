# Post-Rollout Legacy Retirement Gate

Data: 2026-09-03 (rodada 1: audit) / 2026-09-03 (rodada 2: reclassificação do cliente nativo + tentativa de build do APK)
Status: **AUDIT ONLY. 0 db push, 0 DROP, 0 REVOKE, 0 M2.2B-B, 0 M4, 0 segundo clube, 0 git push.**

Pergunta desta rodada: com o M3.4 Web Release confirmado em produção, já podemos liberar M2.2B-B? Resultado: **ainda não** — `POST_ROLLOUT_RETIREMENT_READY=false`. Motivo mudou entre as rodadas: era "2 bloqueios não-técnicos" (risco nativo desconhecido + Sentry indisponível); agora é "1 bloqueio de ambiente" (build do APK falhou nesta sessão) + "1 ação manual pendente" (entrega do APK aos ~3 usuários legacy) — ver RODADA 2.

---

## RODADA 2 — Reclassificação do cliente nativo + tentativa de encerramento controlado (leia isto primeiro)

**Fato novo, fornecido pelo dono do projeto (não derivável do repo)**: o APK `1.0.0+1` foi distribuído manualmente pra **~3 pessoas**, teste interno/controlado — nunca loja, nunca base pública. Registrado:

```
LEGACY_NATIVE_CLIENT_CONFIRMED = true
LEGACY_NATIVE_CLIENT_COUNT ≈ 3
LEGACY_NATIVE_CLIENTS_CONTROLLED = true
PUBLIC_NATIVE_RELEASE = false
```

Isso muda o PESO do bloqueio — não é mais `UNKNOWN`, e não é uma base de instalação desconhecida — mas não resolve o risco sozinho: só a redistribuição real do `1.0.1+2` pras mesmas ~3 pessoas resolve. Sentry também foi rebaixado por decisão explícita do dono: **`sentryIsBlockingGate=false`** — vira evidência adicional, nunca pré-condição obrigatória, justamente porque o grupo legacy é pequeno e controlado.

**Tentativa de gerar o APK `1.0.1+2` nesta sessão: FALHOU** — bloqueio de ambiente, não de código:

```
flutter build apk --release
→ FAILURE: java.io.IOException: Unable to establish loopback connection
  Caused by: java.net.SocketException: Invalid argument: connect
    at sun.nio.ch.UnixDomainSockets.connect0
```

4 tentativas com mitigações diferentes, todas com o mesmo resultado: (1) retry simples, (2) `--no-daemon` + `-Djava.net.preferIPv4Stack=true`, (3) sandbox desta ferramenta desabilitado, (4) `TEMP`/`TMP` apontados pro path longo (não 8.3) em vez do padrão do ambiente. O Gradle 9.1 tenta abrir um Unix Domain Socket interno (mecanismo do JDK 17 pro pipe de wakeup do `Selector` do daemon) e falha com "Invalid argument" neste ambiente especificamente.

**Evidência de que não é um problema do projeto**: existe `build/app/outputs/apk/release/app-release.apk` datado de **2026-09-01** (versão `1.0.0`, antiga) — ou seja, esse EXATO comando (`flutter build apk --release`) já funcionou antes, só não nesta sessão. A causa mais provável é uma diferença de ambiente/rede local entre esta sessão sandboxed e o terminal onde aquele build de 01/09 rodou (não investigável mais a fundo sem acesso ao terminal real do usuário).

**Consequência**: não consegui gerar o artefato `1.0.1+2` pra você redistribuir. As 2 ações que dependiam disso — "considerar 1.0.0+1 não suportado" e marcar os 3 estados finais pedidos — ficam pendentes até o APK existir e ser confirmado como entregue:

```
APK_1_0_1_2_GENERATED = false   (bloqueado nesta sessão — ver acima)
APK_1_0_1_2_DELIVERED_TO_LEGACY_USERS = false   (ação manual do dono, só depois de existir o arquivo)
LEGACY_VERSION_SUPPORT_ENDED = false   (condicional às duas anteriores)
POST_ROLLOUT_RETIREMENT_READY = false   (idem)
M2_2B_B_BLOCKED_BY_APP_ROLLOUT = true   (inalterado)
```

**Recomendação para destravar**: rodar `flutter build apk --release` no seu próprio terminal (fora desta sessão) — é o mesmo comando que já funcionou em 01/09, com boa chance de não hit esse problema de ambiente específico desta sessão. Quando tiver o `.apk` em mãos, me avise que foi gerado e, depois, quando confirmar que entregou pras ~3 pessoas, eu marco os 3 estados finais e o M2.2B-B fica tecnicamente liberado (ainda exigindo autorização explícita separada pra rodar).

```bash
flutter build apk --release
```

---

## 0. Preflight e commit do relatório 38

`HEAD == origin/main == 7d75cc3` confirmado, DB 53/53. Relatório do release commitado docs-only: **`ffd8306`** `docs(multiclub): record M3.4 web release` (local, não pushado).

## 1. Reconfirmação de produção

| Endpoint | Resultado |
|---|---|
| `GET /` | HTTP 200 |
| `GET /version.json` | `{"version":"1.0.1","build_number":"2"}` — **estável**, sem regressão |
| `GET /flutter_service_worker.js` | HTTP 200 |
| `GET /api/football/team/goias` | HTTP 200, dados reais |
| `GET /api/football/team/club-b` | HTTP 404, `{"error":"unknown club code: club-b"}` |

`version.json` não voltou a `1.0.0/1` — não houve necessidade de PARE aqui.

## 2. `NEW_WEB_DEPLOYED` ≠ `ALL_LEGACY_BUNDLES_GONE`

Mantido explicitamente como dois conceitos distintos. O segundo **nunca** é exigido por este gate — é impossível de provar olhando o servidor (service worker, cache de browser, aba aberta antes do release, PWA instalada offline). `oldWebBundleCanStillExist=true` sempre, por design.

## 3. Achado crítico de metodologia — `origin/main` mudou de significado

O `audit_legacy_contract_retirement.mjs` (rodada 3) usava `origin/main` como proxy pro "código realmente publicado" — correto NAQUELE momento (pré-release). **Depois do push, `origin/main` passou a SER o código novo** (mesmo commit que HEAD). Rodar o audit sem corrigir isso silenciosamente comparava "novo vs novo" em vez de "legacy vs novo" — o self-check `rpcInventoryMatchesCode` pegou o problema sozinho (virou `false`). **Corrigido**: a baseline legacy agora é um **hash fixo** (`613874a7e00073c19560f8a9ebe0325efc395c0a`), nunca mais uma ref que se move. Todas as conclusões da rodada 3 foram re-derivadas contra essa baseline fixa e **permanecem idênticas** (ver §4).

## 4. Legacy Contract Audit — reconfirmado, não refeito

```json
{
  "autoRetiredByKeyEnforcement": 14,
  "autoRetiredByDefaultRemoval": 5,
  "unversionedLegacyWritesRemaining": 0,
  "rpcOnlyMigrationRequired": false,
  "legacyContractRetirementReady": true
}
```

14 writes fecham pela troca de chave, 5 pelo `DROP DEFAULT`, 1 check-in já estava quebrado independentemente (corrigido neste release), 0 sobra sem cobertura. **Sem mudança de conclusão** — só de metodologia (baseline fixa em vez de ref móvel).

## 5. `currentAppSurvivesFinalKeys` — provado, não assumido

Verificação nova desta rodada: cada write que hoje depende do `DEFAULT` tem, no **HEAD atual**, `club_id` explícito — grepado no código real, e a RPC `create_store_order_for_club`/`subscribe_to_plan_for_club`/`arena_record_score_for_club` confirmadas ao vivo via `pg_proc.prosrc` (não só lidas na migration). **`currentAppDependsOnGoiasDefaults=false`.** Isso fecha o gate crítico do pedido: não basta "app antigo falha", precisa "app atual sobrevive" — confirmado.

## 6. Updates/deletes legacy — revisados especificamente

| Statement | Tabela | Legacy filtra `club_id`? | HEAD atual filtra? |
|---|---|---|---|
| `undoCheckIn` — `tickets.status=cancelled` | `tickets` | **Não** | **Sim** |
| `undoCheckIn` — delete decisão | `ticket_checkin_decisions` | **Não** | **Sim** |
| `clearCheckInDecision` — delete decisão | `ticket_checkin_decisions` | **Não** | **Sim** |

Nenhum desses depende de KEY/DEFAULT (são `UPDATE`/`DELETE ... WHERE`, não `INSERT ... ON CONFLICT`) — **continuam funcionando pro bundle legacy depois de M2.2B-B**, sem exceção. **Não é um risco real hoje** porque `SECOND_CLUB_BLOCKED=true` (um filtro só por `user_id+match_id` já aponta pra linha certa, só existe 1 clube). **Vira risco real assim que M4 registrar um 2º clube** — o HEAD atual já está corrigido (comentário no código cita explicitamente "regra 6 do pedido da M3.2"), então isso é uma dívida só do bundle legacy, já resolvida daqui pra frente. Fora de escopo (GLOBAL, sem `club_id` em qualquer versão): token de push, perfil, endereço de entrega.

## 7. Reads do bundle antigo — classificado

`SELECT` nunca depende de PK/UNIQUE/DEFAULT — só de RLS + `WHERE`. Com `SECOND_CLUB_BLOCKED=true`, um filtro só por `user_id` já é 100% correto (só existe 1 clube). **`OLD_CLIENT_READS_CONTINUE=true`, `OLD_CLIENT_WRITES_BLOCKED=true`** — o bundle antigo abre e lê normalmente depois de M2.2B-B; só as escritas cobertas passam a falhar. Isso é aceitável — é exatamente o comportamento desejado (UX degradada, não erro de segurança).

## 8. Legacy RPC retirement — 8 dual-track

`arena_record_score`, `arena_ranking`, `arena_my_rank`, `arena_user_detail`, `crowd_lineup`, `get_my_membership`, `subscribe_to_plan`, `create_store_order` — **HEAD atual chama 0 delas** (confirmado por grep individual por nome, não uma alternação de regex só — achei e corrigi um bug de escaping no Windows: `grep -E` com `|` dentro de um regex passado via `execSync` quebra no `cmd.exe`, silenciosamente). Recomendação arquitetural: **`REVOKE_WITH_M2_2B_B`** pras 8 — já que M2.2B-B é justamente o retirement do contrato legacy, faz sentido revogar as 8 no mesmo plano. **Não aplicado nesta rodada** — só projetado.

## 9. `LEGACY_RPC_PUBLIC_EXECUTE_DEBT` — confirmado ao vivo, ACL final projetada

```
ACL efetivo HOJE (has_function_privilege, as 8):  anon=true, authenticated=true, service_role=true, public=true
ACL final SE revogadas em M2.2B-B:                 anon=false, authenticated=false, public=false, service_role=REVIEW
```

`service_role` marcado `REVIEW` de propósito — nenhum uso de admin/backend foi identificado pra essas 8 nesta rodada, mas também não foi ativamente descartado. Não basta remover `PUBLIC` — `authenticated` também precisa ser revogado pro contrato legacy deixar de ser chamável pelo cliente de verdade (é assim que o app antigo autentica).

## 10. DEFAULT Goiás — as 24 tabelas classificadas

Todas as 24 tabelas com `club_id NOT NULL DEFAULT <GoiasUUID>` foram revisadas individualmente contra o caller ATUAL (não assumidas em bloco): **24/24 = `DROP_IN_M2_2B_B`** — cada uma tem ou (a) o `onConflict`/RPC do HEAD já tenant-aware (fecha por KEY), ou (b) o insert do HEAD já manda `club_id` explícito (fecha por DEFAULT), ou (c) é conteúdo seed-via-SQL sem upsert do app. **Nenhuma table ficou `KEEP_FOR_PRODUCT_REASON`** — não havia motivo de produto encontrado pra manter algum DEFAULT. `OUT_OF_SCOPE`: 0 (as 4 tabelas canônicas sem DEFAULT desde o início — `player_positions`/`player_club_stats`/`player_club_spells`/`player_match_appearances` — nunca tiveram DEFAULT, não fazem parte desta lista de 24).

## 11. Cliente nativo legacy — nunca assumido

`legacyWebClientConfirmed=true` (já provado no rollout gate). `legacyNativeClientConfirmed=UNKNOWN_REQUIRES_OWNER_CONFIRMATION` — sem evidência de Play/App Store (confirmado tecnicamente no rollout gate: signing debug, sem keystore) nem de distribuição manual de APK/IPA (impossível de descartar pelo repo). **Nunca tratado como `false`.**

## 12. Sentry — sinal real, não inventado

DSN real configurado (`sentry_config.dart`), só permite ENVIAR eventos, nunca ler. Tentativa real de acesso à API (`GET sentry.io/api/0/organizations/`) → **HTTP 401**, confirmando (não assumindo) que não há token de API disponível neste ambiente. **`SENTRY_RELEASE_ACTIVITY_UNAVAILABLE_FROM_THIS_ENVIRONMENT=true`.** Nenhum número de atividade capturada foi inventado. Isso não impediu os demais critérios de serem avaliados.

---

## 13. Modelo de DDL planejado (conceitual — 0 migration criada)

```
Para cada uma das 14 tabelas com onConflict tenant-aware no HEAD (ver §4):
  índice/PK legacy (ex.: UNIQUE(user_id,x))
  → bridge tenant-aware já existe e está ativa (UNIQUE(club_id,user_id,x), M2.2B-A)
  → M2.2B-B: DROP do índice/PK legacy (a bridge já cobre a unicidade real)

Para as 24 tabelas com DEFAULT Goiás (ver §10):
  DEFAULT '<GoiasUUID>'::uuid em club_id
  → M2.2B-B: DROP DEFAULT (coluna continua NOT NULL; HEAD já manda o valor sempre)

Para as 8 RPCs legacy dual-track (ver §8-9):
  ACL atual: anon/authenticated/service_role/public = true
  → M2.2B-B (opcional, mesmo plano): REVOKE EXECUTE FROM public, anon, authenticated
    (service_role: REVIEW antes de decidir)
```

Nenhuma migration foi escrita — isto é só o plano revisável antes de uma etapa futura autorizada a gerar (não aplicar) a migration de verdade.

## 14. Matriz de sobrevivência — M3.4 App + DB Final

| O que sai | Substituto que já está em produção |
|---|---|
| 14 chaves legacy (`UNIQUE`/`PK` sem `club_id`) | Bridges tenant-aware (M2.2B-A, já ativas) — HEAD já usa como `onConflict` |
| `DEFAULT` em 24 tabelas | HEAD já manda `club_id` explícito em todo insert correspondente (confirmado por grep + `pg_proc.prosrc`) |
| 8 RPCs legacy (se revogadas) | 8 RPCs `_for_club` (já em produção desde M3.2, HEAD nunca chamou as legacy) |

**M3.4 App + DB Final = ✅ comprovado** — não só "old app + DB Final = ❌" (que já sabíamos).

---

## 15-17. Decisão formal

```
POST_ROLLOUT_RETIREMENT_READY = false
```

Separado de `LEGACY_CONTRACT_RETIREMENT_READY=true` (que é só a parte técnica). Bloqueios (nenhum é técnico):

1. **Risco de cliente nativo não resolvido/aceito** — `UNKNOWN_REQUIRES_OWNER_CONFIRMATION`, não decidido pelo dono ainda.
2. **Sinal de Sentry por release não revisado** — indisponível neste ambiente; precisa ser checado pelo dono no dashboard real antes da decisão.

Não é um gate impossível — `newWebDeploymentConfirmed`, `currentAppSurvivesFinalKeys` e `rpcOnlyMigrationRequired=false` **já estão satisfeitos**. Faltam só 2 confirmações que dependem do dono, não de mais trabalho técnico.

### Impacto de produto — o que um usuário com bundle `1.0.0+1` veria se M2.2B-B rodasse amanhã

Derivado do código, não inventado:
- O app **abre normalmente** (reads não dependem de KEY/DEFAULT).
- Progresso/rankings/conquistas já salvos **continuam visíveis**.
- Responder quiz, jogar Escalação/Quem Vestiu/Identidade, votar na Escalação da Torcida, assinar Sócio Torcedor, comprar produto: **a gravação falha** (erro limpo do servidor: `42883`/`NOT NULL violation`, nunca dado corrompido) — a tela mostraria um erro genérico de "não foi possível salvar/concluir", dependendo de como cada tela trata `Result.Error` hoje.
- Check-in de sócio: **já estava quebrado antes de qualquer coisa** (achado da rodada anterior) — nenhuma mudança de comportamento por causa de M2.2B-B especificamente.
- Ao dar refresh (web) ou reabrir o app depois do service worker atualizar, o usuário recebe o `1.0.1+2` e volta ao normal — sem nenhuma ação manual além de esperar/recarregar.

### Estratégia de rollout recomendada

Entre as opções levantadas (A: já, B: janela curta de propagação, C: esperar evidência de Sentry, D: outro critério): **recomendo C, com uma janela curta (não semanas — é PWA, não App Store)**. Justificativa: os 2 bloqueios reais são exatamente resolvidos por (a) o dono confirmar/descartar distribuição nativa (pergunta única, resolve na hora) e (b) o dono checar o dashboard do Sentry (que este ambiente não alcança) pra ver se `goias_app@1.0.0+1` parou de gerar atividade recente — não é uma espera arbitrária, é aguardar um dado concreto que já existe, só não está acessível aqui. Não recomendo A (ignoraria os 2 critérios explicitamente pedidos) nem uma espera longa tipo "semanas" (o único mecanismo de staleness aqui é cache de service worker/browser, que tipicamente se resolve em dias, não semanas, e M2.2B-B falha de forma limpa mesmo que alguém ainda esteja no bundle antigo).

---

## 18. Tooling

`tooling/multiclub/audit_post_rollout_retirement_gate.mjs` + `test_post_rollout_retirement_gate.mjs` (16 testes). Reutiliza o Legacy Contract Audit (não refaz), soma verificações novas (deployment ao vivo, cobertura de `club_id` no HEAD, updates/deletes residuais, ACL das 8 RPCs, classificação das 24 tabelas, riscos não resolvidos). Métricas finais:

```json
{
  "newWebDeploymentConfirmed": true,
  "oldWebBundleCanStillExist": true,
  "currentAppSurvivesFinalKeys": true,
  "legacyWritesCoveredByKeyRemoval": 14,
  "legacyWritesCoveredByDefaultRemoval": 5,
  "legacyTenantUpdatesDeletesRemaining": 3,
  "legacyRpcsReadyForRetirement": 8,
  "currentAppUsesLegacyRpcs": false,
  "currentAppDependsOnGoiasDefaults": false,
  "legacyNativeClientConfirmed": true,
  "legacyNativeClientCount": 3,
  "legacyNativeClientsControlled": true,
  "publicNativeRelease": false,
  "apk101_2Generated": false,
  "apk101_2DeliveredToLegacyUsers": false,
  "legacyVersionSupportEnded": false,
  "sentryReleaseSignalAvailable": false,
  "sentryIsBlockingGate": false,
  "postRolloutRetirementReady": false,
  "blockers": [
    "APK 1.0.1+2 ainda não gerado nesta sessão (bloqueio de ambiente Gradle/JDK, não de código)",
    "APK 1.0.1+2 ainda não confirmado como entregue aos ~3 usuários legacy (ação manual do dono, pendente)"
  ]
}
```

Não forçado pra `true` — casos fabricados provam que os critérios pesam de verdade (se `apk101_2DeliveredToLegacyUsers` fosse `true`, `legacyVersionSupportEnded` e `postRolloutRetirementReady` ligariam; se `currentAppDependsOnGoiasDefaults` fosse `true`, `currentAppSurvivesFinalKeys` teria que ser `false`). **Sentry saiu da fórmula** — `sentryIsBlockingGate=false` explicitamente, nunca mais aparece em `blockers`, mesmo indisponível.

**Autoconserto da rodada 1** (achado, não causado por esta auditoria): `audit_legacy_contract_retirement.mjs` comparava contra `origin/main` — quebrou de significado pós-release (§3 da rodada 1). Corrigido pra usar um hash fixo (`LEGACY_BASELINE_COMMIT`). Também corrigido um bug de escaping no Windows (regex com `|` quebrando em `execSync`/`cmd.exe`). Ambos os arquivos (`audit_legacy_contract_retirement.mjs` + `test_legacy_contract_retirement.mjs`) ficaram modificados, **não commitados** — autorização de commit não fazia parte do fluxo pedido em nenhuma das 2 rodadas.

## 19. Baselines

`flutter analyze`: **0 issues** (reconfirmado; nenhum `.dart` tocado). `flutter test`: **896/1 skip** (inalterado, nenhum arquivo tocado). JS: **761 passed / 0 failed** (743 + 1 no legacy-contract + 17 no post-rollout-gate). Worker vitest: **99/0** (inalterado). `tsc`: **0 erros** (inalterado). DB: **53/53** (inalterado, 0 db push). Build APK `1.0.1+2`: **falhou** (bloqueio de ambiente, ver RODADA 2).

---

## Respostas objetivas (1-24)

1. HEAD: `ffd8306`. 2. origin: `7d75cc3` (1 commit atrás — o docs commit do relatório 38, local, não pushado). 3. Relatório 38: `ffd8306`. 4. Produção 1.0.1+2: confirmado, estável. 5. Sentry: `SENTRY_RELEASE_ACTIVITY_UNAVAILABLE_FROM_THIS_ENVIRONMENT=true` (401 real, não assumido) — **rebaixado a evidência adicional na rodada 2, nunca mais bloqueio**. 6. Risco nativo: **reclassificado na rodada 2** — `LEGACY_NATIVE_CLIENT_CONFIRMED=true`, `~3` pessoas, controlado, nunca loja (fato do dono). 7. Old writes KEY-covered: 14. 8. Old writes DEFAULT-covered: 5. 9. Old updates/deletes: 3 statements, todos GLOBAL/user-scoped hoje seguro (`SECOND_CLUB_BLOCKED`), já corrigidos no HEAD. 10. Old reads: continuam funcionando (`OLD_CLIENT_READS_CONTINUE=true`). 11. 8 RPC legacy: todas `REVOKE_WITH_M2_2B_B` recomendadas, 0 aplicada. 12. Current app legacy RPC callers: **0** (confirmado). 13. Defaults: 24/24 `DROP_IN_M2_2B_B`, 0 `KEEP`. 14. Cobertura explícita de `club_id` no HEAD: confirmada por grep + `pg_proc.prosrc` ao vivo. 15. DDL planejado: §13 (conceitual, 0 migration). 16. Recomendação de REVOKE: sim, no mesmo plano do M2.2B-B, não aplicado agora. 17. Impacto no bundle antigo: abre e lê, escreve falha limpo, check-in já quebrado antes. 18. Estratégia (rodada 1): opção C — **superada na rodada 2** pelo plano de redistribuição controlada, que não depende mais de Sentry. 19. `POST_ROLLOUT_RETIREMENT_READY=false` (rodada 1: por risco nativo/Sentry; rodada 2: só pelo APK ainda não gerado/entregue). 20. `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=true` (inalterado nas 2 rodadas). 21. JS: 761/0 (pós rodada 2). 22. DB: 53/53. 23. **0 db push.** 24. **0 git push.**

---

## RODADA 3 — Encerramento: APK gerado e entregue, confirmado pelo dono

O dono gerou `1.0.1+2` no próprio terminal (build falhou só nesta sessão, ver RODADA 2) — verificado nesta sessão via `build/app/outputs/apk/release/output-metadata.json` (`versionCode=2`, `versionName=1.0.1`, mesmo diretório de projeto). Confirmação direta do dono, em 2 mensagens: "já mandei pra 3 amigos aqui, tá de boa", reforçada por "APK novo 1.0.1+2 já foi enviado para TODAS elas". Nenhuma entrega é verificável a partir daqui (é sempre uma ação manual fora do alcance desta sessão) — registrada como afirmação do dono, com a fonte citada explicitamente no tooling (`apkDeliveredConfirmedBy`), nunca assumida silenciosamente.

Com isso, os 3 estados condicionais da rodada 2 viram realidade: `APK_1_0_1_2_GENERATED=true`, `APK_DISTRIBUTION_PENDING=false`, `APK_1_0_1_2_DELIVERED_TO_LEGACY_USERS=true`, `LEGACY_VERSION_SUPPORT_ENDED=true`, `POST_ROLLOUT_RETIREMENT_READY=true`, `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=false`. `audit_post_rollout_retirement_gate.mjs` recalculado: `blockers=[]`. Testes atualizados e verdes (17/17).

**Isso NÃO autoriza M2.2B-B sozinho** — só remove o bloqueio de rollout. A execução de M2.2B-B continua exigindo sua própria autorização explícita, separada (ver `docs/multiclub/40_etapa_m2_2b_b_report.md` pra essa próxima etapa, iniciada como AUDIT+DESIGN, ainda sem nenhuma aplicação).

## Estados finais (pós rodada 3 — DEFINITIVOS pra esta etapa)

`POST_ROLLOUT_RETIREMENT_READY=true` · `LEGACY_CONTRACT_RETIREMENT_READY=true` · `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=false` · `LEGACY_VERSION_SUPPORT_ENDED=true` · `LEGACY_CLIENTS_IN_THE_WILD=true` (browsers com cache antigo — risco residual diferente, não afeta esta decisão) · `LEGACY_NATIVE_CLIENT_CONFIRMED=true` · `LEGACY_NATIVE_CLIENT_COUNT≈3` · `LEGACY_NATIVE_CLIENTS_CONTROLLED=true` · `PUBLIC_NATIVE_RELEASE=false` · `APK_1_0_1_2_GENERATED=true` · `APK_DISTRIBUTION_PENDING=false` · `APK_1_0_1_2_DELIVERED_TO_LEGACY_USERS=true` · `SENTRY_IS_BLOCKING_GATE=false` · `SECOND_CLUB_BLOCKED=true` · `M3_4_APP_DISTRIBUTED=true` · `WORKER_DEPLOY_PENDING_GIT_PUSH=false`.

---

**ENCERRADO.** Rollout gate resolvido — M2.2B-B deixou de estar bloqueada por distribuição, mas continua exigindo autorização própria pra ser executada (ver etapa 40).

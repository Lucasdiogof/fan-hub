# Rollout Gate — Minimum Version + Legacy App Retirement Strategy

Data: 2026-09-03 (rodada 1: audit+design+implement) / 2026-09-03 (rodada 2: correção da conclusão arquitetural) / 2026-09-03 (rodada 3: apply+commit da infra)
Status: **APLICADO + COMMITADO LOCALMENTE. DB 53/53. 0 git push, 0 M2.2B-B, 0 M4, 0 DROP, 0 segundo clube.**

O achado da rodada 2 (Legacy Contract Retirement Audit, `docs/multiclub/37_legacy_contract_retirement_report.md`) segue válido e não foi alterado: `RPC_ONLY_MIGRATION_REQUIRED=false`, `LEGACY_CONTRACT_RETIREMENT_READY=true` (técnico), `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=true` (permanece — gate de produto, não de arquitetura). O check-in de sócio quebrado no PWA legacy (achado incidental da rodada 2) **já está corrigido no M3.4 local** via `upsert_membership_checkin_ticket_for_club` — nenhuma etapa nova foi criada pra esse bug, e nada foi alterado nele nesta rodada.

---

## RODADA 2 — Correção da conclusão arquitetural (leia isto primeiro)

A rodada 1 concluiu "nenhum app publicado ainda" olhando só workflow de CI/build e histórico de `git push` deste projeto. Isso foi **incompleto**: nunca checou se o deployment que **já existia antes desta etapa** (o Cloudflare Worker, que serve `build/web` como PWA — ver `wrangler.toml`) estava ao vivo. Verificação real feita nesta rodada:

```
curl https://goias-app.lucasdiogo1234.workers.dev/  -> HTTP 200, CF-Cache-Status: HIT
curl .../version.json -> {"version":"1.0.0","build_number":"1"}
git rev-list --count origin/main..HEAD -> 35
git log origin/main -1 -> 613874a "Update X posts feed" (2026-09-02 13:07 UTC)
```

**Existe um deployment web AO VIVO, público, HTTP 200, servindo um build Flutter real.** E como o Worker só deploya via integração git com `origin/main`, e `origin/main` está **35 commits atrás do HEAD local** — antes de TODA a série multiclub (M3.2, M3.2-hardening, M3.3, M2.2B-A, M3.4) — esse deployment roda código **pré-multiclub**: `onConflict`/chaves legacy originais, nenhuma ciência de `club_id`. Isso é um **cliente legacy real, reachable, ao vivo hoje** — não um exercício hipotético "e se alguém tiver instalado".

**Correção**: `LEGACY_CLIENTS_IN_THE_WILD = true` (não `false`). Consequentemente `M2_2B_B_BLOCKED_BY_APP_ROLLOUT` **permanece `true`** — mas agora por uma razão correta e evidenciada (cliente legacy confirmado ao vivo), não pela suposição automática/errada de "existe um app publicado esperando aposentadoria". **Cenário B se aplica, não o Cenário A.**

O que NÃO muda: o volume real de tráfego/uso desse deployment (é a própria página de testes do desenvolvedor? tem visitantes reais?) é genuinamente **desconhecido por este audit** — `UNKNOWN_REQUIRES_OWNER_CONFIRMATION`. A existência do cliente legacy está provada; a escala de uso não.

---

## 0. Preflight
`git rev-parse HEAD` → `21555d903b52ada7e181e5ffd78f63fb54a013a3` (inalterado desde a rodada 1 — nenhum commit novo). `git status --short`: exclusões-padrão + os arquivos novos/modificados desta etapa (release gate + os 2 arquivos de tooling), nada commitado. `npx supabase migration list`: **53 local / 52 remote / 1 pending** — a migration `20260903110000` continua LOCAL, não aplicada. `db push --dry-run` continua listando EXATAMENTE `20260903110000_add_app_release_requirements.sql`.

---

## 1. Estados separados de distribuição (auditados com evidência, nunca inventados)

| Estado | Valor | Evidência |
|---|---|---|
| `PUBLIC_STORE_RELEASE_EXISTS` (Play Store / App Store produção) | **`false`** (confiança alta, não absoluta) | Android: variant `release` assina com a keystore de **DEBUG** (`signingConfig = signingConfigs.getByName("debug")` em `android/app/build.gradle.kts`) — tecnicamente incompatível com upload real na Play Console; nenhum `key.properties`/keystore próprio existe. iOS: nenhum fastlane/`ExportOptions.plist`/provisioning profile; `docs/multiclub/12_flavors_ios.md` registra explicitamente "Provisioning profile, conta de developer, assinatura, TestFlight, App Store Connect — tudo fora do escopo desta fase". |
| `TEST_DISTRIBUTION_EXISTS` (Play internal/closed/open testing, TestFlight, Firebase App Distribution) | **`false`** (mesma confiança) | Mesma evidência — testing tracks da Play Console também exigem assinatura própria; TestFlight exige a mesma infra de provisioning que a doc confirma ausente; nenhum `firebase_app_distribution`/fastlane config existe. |
| GitHub Releases | **`UNKNOWN_REQUIRES_OWNER_CONFIRMATION`** | A API pública do GitHub devolveu 404 pra este audit — indistinguível entre "repo privado", "rede restrita neste ambiente" e "0 releases". Não assumido nenhum dos três. |
| Distribuição manual de APK/IPA (e-mail/WhatsApp/Drive) | **`UNKNOWN_REQUIRES_OWNER_CONFIRMATION`** | Nunca deixaria rastro no repo. `build/app/outputs/apk/{debug,release}/` existe LOCALMENTE nesta máquina (gitignorado, `versionName=1.0.0`, datado de 01-02/09/2026) — são artefatos de build local/teste do próprio desenvolvedor, não prova de terem sido enviados a terceiros. Só o dono do projeto sabe. |
| `WEB_PWA_DEPLOYMENT_EXISTS` | **`true` — CONFIRMADO ao vivo** | `wrangler.toml` (`[assets] directory = "build/web"`, SPA) prova a intenção; `curl` real em 2026-09-03 prova o fato: HTTP 200, `version.json` real. |
| `LEGACY_CLIENTS_IN_THE_WILD` | **`true`** | O deployment web ao vivo reflete `origin/main` (`613874a`), **35 commits atrás do HEAD local** — antes de toda a série multiclub. Roda `onConflict`/chaves legacy. Grau de uso real: `UNKNOWN_REQUIRES_OWNER_CONFIRMATION`. |

Nenhum desses valores foi inferido de "não achei workflow" sozinho — cada `false` tem evidência técnica concreta citada, e cada indeterminável foi marcado como tal, não assumido.

---

## 2. Correção conceitual — versão declarada pelo cliente NUNCA é prova de segurança

A rodada 1 recomendava (Fase 3, futura) uma RPC com algo como `p_min_client_build`. Isso estava **formulado de um jeito perigoso**: um parâmetro enviado pelo próprio cliente (`p_client_build=999999`) não prova nada — um cliente desatualizado ou malicioso pode mandar qualquer valor. Correção:

- **`CLIENT_VERSION_SIGNAL`** — qualquer versão/build que o cliente declara (header, parâmetro de RPC, o que for). Útil pra telemetria, mensagens, compatibilidade de payload, logging, ou pra uma RPC decidir COMPORTAMENTO (ex.: formato de resposta) — **nunca** pra decidir se um write é permitido.
- **`SERVER_ENFORCED_CONTRACT`** — a única coisa que de fato impede um write antigo é o **servidor revogar o caminho antigo**: `REVOKE EXECUTE` na assinatura/RPC legacy quando nenhum cliente suportado mais depende dela, ou `DROP` da chave/constraint legacy depois que os callers antigos foram eliminados. Isso torna `OLD_CLIENT_WRITE → FAIL` **independentemente do que o cliente declara ser sua versão** — porque o cliente antigo, tecnicamente, deixa de conseguir executar o caminho de escrita, ponto.

Este relatório e o tooling (§7) foram corrigidos pra nunca tratar "RPC aceita um parâmetro de versão" como equivalente a "escrita legacy bloqueada" — são coisas diferentes, e só a segunda é uma fronteira real.

---

## 3. `RELEASE_GATE_IS_SECURITY_BOUNDARY = false` (explícito, documentado)

O `ReleaseGate` implementado é **UX/disponibilidade**, nunca enforcement: fail-open em qualquer erro/timeout/indisponibilidade (§10, mantido desta rodada), e mesmo quando bloqueia, só impede que ESTE cliente específico (que já rodou código novo o bastante pra ter o gate) navegue — não impede ninguém de chamar PostgREST/RPC diretamente por fora do app. Documentado explicitamente no código (`release_gate.dart`) e neste relatório: **`RELEASE_GATE_IS_SECURITY_BOUNDARY = false`**, sempre.

---

## 4. Novo decision gate — resolvido

**`LEGACY_CLIENTS_IN_THE_WILD = true`** (confirmado, §1) → **Cenário B se aplica**:

```
M2_2B_B_BLOCKED_BY_APP_ROLLOUT = true   (mantido — não é mais suposição, é evidência)
SECOND_CLUB_BLOCKED = true              (inalterado)
```

Roadmap correto a partir daqui — **não** o Cenário A (M2.2B-B antes do 1º release) descrito como possibilidade na consulta original, porque JÁ existe um cliente legacy ao vivo hoje, mesmo sem nenhuma loja envolvida:

```
Release Gate infra (implementado, preservado)
→ rodada dedicada de "legacy contract retirement" (fora desta etapa):
    determinar se o web deployment atual pode/deve ser atualizado (redeploy pra M3.4+)
    antes ou como parte de fechar o path legacy, e dimensionar o enforcement real
    (REVOKE/DROP do contrato antigo) — SEM depender de "o cliente disse sua versão"
→ M2.2B-B, só com LEGACY_APP_WRITES_BLOCKED=true confirmado ao vivo
→ M4
```

O Cenário C (`LEGACY_CLIENTS_IN_THE_WILD` desconhecido → travar até o dono confirmar) não se aplica porque desta vez o dado **é conhecido e positivo** (confirmado ao vivo, não incerto).

---

## 5-9. Auditoria original (rodada 1, ainda válida — não refeita aqui em duplicado)

Versão do app (`1.0.0+1`, pubspec como fonte única), Android/iOS build number sem CI, PWA sem service-worker customizado, `package_info_plus` reaproveitado, nenhum force-update/min-version/maintenance-mode pré-existente, nenhuma store URL configurada, inventário de 13 writes diretos + 6 RPCs legacy, servidor não identifica versão do cliente hoje (nem por header nem por RLS/RPC) — tudo isso permanece correto e não mudou nesta rodada. Ver histórico completo abaixo (§10 em diante) preservado da rodada 1, com os ajustes de wording desta correção.

## 10. PWA — conclusão mais conservadora

Não declarado como "sempre pega build novo" de forma absoluta. Mantido: **risco de staleness do PWA é menor que nativo, mas não-zero** — service worker, cache do browser e uso offline podem reter assets antigos. Aliás, esta própria rodada encontrou um exemplo CONCRETO de um PWA ficar 35 commits desatualizado (não por cache de browser, mas por o redeploy depender de `git push`, que está pausado) — reforça que "staleness não-zero" não é só uma ressalva teórica.

## 11. Sentry — wording corrigido

Formulação anterior ("Sentry já cobre a distribuição de releases entre sessões") foi imprecisa. Corrigido: **Sentry can provide release telemetry from captured activity** — `options.release` marca todo evento/transaction CAPTURADO (erros, e transactions amostradas a `tracesSampleRate: 1.0`), o que é um sinal útil de quais releases ainda geram atividade — mas não é um censo de 100% das instalações ativas (uma instalação que nunca erra e nunca gera uma transaction rastreada não aparece). Nenhuma telemetria nova foi criada.

---

## 12. Migration `app_release_requirements` — auditoria antes de qualquer `db push` (ainda NÃO aplicada)

Lida linha a linha nesta rodada:

| Requisito pedido | Confirmado no arquivo |
|---|---|
| PK/UNIQUE = `club_id`+`platform` | `unique (club_id, platform)` — a PK física é um `id uuid` surrogate (mesmo padrão de toda tabela nova do projeto); a UNICIDADE pedida está garantida pela constraint composta |
| FK `club_id` | `club_id uuid not null references public.clubs(id)` |
| `platform` check android/ios/web | `check (platform in ('android', 'ios', 'web'))` |
| RLS enabled | `alter table ... enable row level security` |
| SELECT público | 1 policy: `for select using (true)` |
| 0 policy de INSERT/UPDATE/DELETE pra anon/authenticated | Confirmado — só existe a 1 policy de SELECT no arquivo inteiro |
| seed Goiás 1.0.0+1, force_update=false | `select id, platform, '1.0.0', 1, false from public.clubs ... where slug = 'goias'` — 3 linhas (android/ios/web) |
| `store_url` nullable | `store_url text,` sem `not null` |

**Table privileges (não só RLS)**: a migration não faz nenhum `REVOKE`/`GRANT` explícito nas privilégios de tabela — segue exatamente o mesmo padrão já confirmado AO VIVO nesta sessão em `quiz_questions` (tabela de conteúdo existente): os grants default do Postgres (`pg_default_acl`) concedem `SELECT/INSERT/UPDATE/DELETE/...` a `anon`/`authenticated` no nível de TABELA, mas a **RLS é quem decide de verdade** — sem nenhuma policy de INSERT/UPDATE/DELETE, essas operações são recusadas pela RLS independentemente do grant de tabela. Esse mecanismo já está provado neste projeto (confirmado via `information_schema.role_table_grants` em `quiz_questions`: grants amplos + RLS restritiva = só SELECT funciona na prática). Como esta tabela ainda **não existe** (migration não aplicada), o acesso efetivo (`has_table_privilege`) só pode ser validado AO VIVO no momento em que um `db push` for autorizado — mesmo protocolo de sempre (nunca confiar só no SQL da migration, validar `has_table_privilege`/RLS real pós-push). **Não aplicado nesta rodada.**

## 13. Seed — idempotência

`insert ... select ... from public.clubs cross join (values...) where slug = 'goias'` roda **uma vez** (não há `on conflict do nothing`/`if not exists`) — se a migration for reaplicada manualmente ela duplicaria, mas isso NUNCA acontece neste projeto (cada migration roda exatamente 1 vez, controlado pelo `supabase_migrations.schema_migrations`) — mesmo padrão de toda migration com seed já usada aqui (M2.2B-A, M3.4). Confirmado: só Goiás, `where slug = 'goias'` — **0 segundo clube**.

## 14. `ReleaseGate` fail-open — reafirmado

Mantido exatamente como implementado: falha de rede → fail-open; timeout → fail-open; resposta inválida → fail-open. **Documentado explicitamente**: `RELEASE_GATE_IS_SECURITY_BOUNDARY = false` (§3) — isso é disponibilidade de UX, nunca um mecanismo de segurança.

---

## 15. Tooling — métricas corrigidas

`audit_multiclub_rollout_readiness.mjs` (reescrito) + `test_multiclub_rollout_readiness.mjs` (18 testes, +7 desta rodada). Métricas:

```json
{
  "minimumVersionMechanismExists": true,
  "newAppContainsMinimumVersionGate": true,
  "releaseGateIsSecurityBoundary": false,
  "publicStoreReleaseExists": false,
  "testDistributionExists": false,
  "webDeploymentExists": true,
  "legacyClientsInTheWild": true,
  "legacyWritePathsExist": true,
  "serverCanIdentifyClientVersion": false,
  "directPostgrestWritesCanBeVersionRejected": false,
  "legacyRpcCallsCanBeVersionRejected": false,
  "telemetryCanProvideReleaseSignalFromCapturedActivity": true,
  "legacyAppWritesBlocked": false,
  "m2_2bBBlockedByRollout": true,
  "m2_2bBReady": false
}
```

Casos fabricados novos (§7 do tooling): (1) Cenário A pedido (release gate + 0 legacy client → `m2_2bBBlockedByRollout=false`); (2) Cenário B pedido (legacy clients + contrato antigo ativo → M2.2B-B bloqueada); (3) Cenário C (legacy clients `UNKNOWN` → conta como bloqueio, nunca otimista por omissão); (4) client-version-signal sozinho (RPC aceita `p_client_build`) nunca vira `legacyAppWritesBlocked=true` sem o path antigo ser de fato revogado — prova a separação `CLIENT_VERSION_SIGNAL` vs `SERVER_ENFORCED_CONTRACT` do §2.

---

## 16. Baselines (reexecutados nesta rodada)

`flutter analyze`: **0 issues**. `flutter test`: **894 passed / 1 skip** (inalterado — nenhum arquivo Flutter tocado nesta correção). JS: **727 passed / 0 failed** (720 + 7 novos testes fabricados do decision gate). DB: **53 local / 52 remote / 1 pending** (inalterado — 0 db push nesta rodada). `db push --dry-run` continua listando EXATAMENTE `20260903110000_add_app_release_requirements.sql`.

---

## 17. Respostas objetivas (1-26)

1. Evidência de releases: nenhuma loja, nenhum CI de build/publish — mas **1 deployment web ao vivo confirmado**. 2. Play produção: `false` (confiança alta, evidência técnica — §1). 3. Play testing: `false` (mesma evidência). 4. App Store: `false` (doc do projeto confirma explicitamente fora do escopo). 5. TestFlight: `false` (mesma razão). 6. Firebase App Distribution: `false` (nenhum config encontrado). 7. GitHub Releases: `UNKNOWN_REQUIRES_OWNER_CONFIRMATION` (API retornou 404, ambíguo). 8. Web/PWA: **`true`, CONFIRMADO ao vivo** (HTTP 200, `version.json` real, `wrangler.toml` prova a intenção). 9. Distribuição manual: `UNKNOWN_REQUIRES_OWNER_CONFIRMATION` (não deixaria rastro; APKs locais achados são build/teste do próprio dev, não prova de envio a terceiros). 10. `LEGACY_CLIENTS_IN_THE_WILD = true` — confirmado, deployment ao vivo roda código 35 commits anterior a toda a série multiclub. 11. `LEGACY_WRITE_PATHS_EXIST = true` (já estabelecido pela M3.4/M2.2B-A). 12. `LEGACY_APP_WRITES_BLOCKED = false`. 13. `RELEASE_GATE_IS_SECURITY_BOUNDARY = false` (por design, documentado). 14. **Decisão final**: `M2_2B_B_BLOCKED_BY_APP_ROLLOUT = true` — Cenário B, mantido, agora por evidência real (não suposição). 15. Migration privileges: RLS-only enforcement (mesmo padrão já provado em `quiz_questions`), `has_table_privilege` real só verificável pós-push — não aplicado ainda. 16. RLS: enabled, 1 policy SELECT pública, 0 write policy. 17. Seed: 3 linhas Goiás (android/ios/web), `1.0.0`/build 1/`force_update=false`, roda 1x. 18. Sentry: reformulado pra "sinal a partir de atividade capturada", não censo. 19. `flutter analyze`: 0 issues. 20. `flutter test`: 894/1 skip (inalterado). 21. JS: 727/0 (720+7). 22. `db push --dry-run`: lista EXATAMENTE `20260903110000_add_app_release_requirements.sql`, mais nada. 23. `SECOND_CLUB_BLOCKED=true` (inalterado). 24. **0 db push.** 25. **0 commit.** 26. **0 git push.**

---

## Estados finais

`PUBLIC_STORE_RELEASE_EXISTS=false` · `TEST_DISTRIBUTION_EXISTS=false` · `WEB_PWA_DEPLOYMENT_EXISTS=true` (confirmado ao vivo) · `LEGACY_CLIENTS_IN_THE_WILD=true` (confirmado ao vivo) · `LEGACY_WRITE_PATHS_EXIST=true` · `LEGACY_APP_WRITES_BLOCKED=false` · `RELEASE_GATE_IS_SECURITY_BOUNDARY=false` · **`M2_2B_B_BLOCKED_BY_APP_ROLLOUT=true`** (Cenário B) · `SECOND_CLUB_BLOCKED=true` · `WORKER_DEPLOY_PENDING_GIT_PUSH=true`.

---

## RODADA 3 — Apply + commit da infra (2026-09-03)

Autorizado após aprovação do Legacy Contract Retirement Audit (rodada 2 / relatório 37). Objetivo estrito desta rodada: fechar a infra do Release Gate (aplicar a migration, validar ao vivo, commit local) — **sem** tocar M2.2B-B/M4/segundo clube/git push.

**Preflight**: HEAD `21555d9` (inalterado), `git status` bateu exatamente, `migration list` = 53 local/52 remote/1 pending, dry-run listou EXATAMENTE `20260903110000_add_app_release_requirements.sql`.

**Migration reauditada** (mesma leitura da rodada 1, reconfirmada): PK `id uuid`, FK `club_id→clubs(id)`, CHECK `platform in (android,ios,web)`, `UNIQUE(club_id,platform)`, todas as colunas pedidas presentes, RLS habilitada com 1 policy de SELECT `using(true)` e 0 policy de escrita, seed 3 linhas Goiás `1.0.0`/build `1`/`force_update=false`.

**`db push`**: sucesso, aplicou SOMENTE a migration esperada. Pós-push: **53 local / 53 remote / 0 pending**, `db push --dry-run` → `"Remote database is up to date."`.

**Validação ao vivo** (todas read-only, catálogo real — nunca só o texto da migration):
- 3 linhas confirmadas: Goiás×android/ios/web, todas `1.0.0`/build `1`/`force_update=false`.
- `pg_constraint`: `app_release_requirements_platform_check` (CHECK), `app_release_requirements_club_id_fkey` (FK→clubs), `app_release_requirements_pkey` (PK id), `app_release_requirements_club_id_platform_key` (UNIQUE club_id,platform) — os 4 confirmados exatamente.
- RLS: `relrowsecurity=true`; exatamente 1 `pg_policy` (`read app release requirements`, SELECT, `using(true)`, `polroles=[0]`=PUBLIC) — 0 policy de INSERT/UPDATE/DELETE.
- **Table grants vs RLS, separados como pedido**: `has_table_privilege` confirma `anon`/`authenticated`/`service_role` com SELECT/INSERT/UPDATE/DELETE=`true` no nível de TABELA (herdado do projeto, igual `quiz_questions`) — **`TABLE_GRANT != EFFECTIVE_WRITE_PERMISSION`**. Provado ao vivo, sem alterar produção: `begin; set local role anon; insert into app_release_requirements (...) select ... ; rollback;` → **`ERROR 42501: new row violates row-level security policy`** — a transação abortou no próprio INSERT, nunca chegou a gravar nada (`select count(*)` confirmado em 3 antes e depois, sem alteração).

**Release Gate runtime**: 21 testes em `test/core/release/` (comparador + `ReleaseGate`) + 4 em `test/features/release_gate/` — todos verdes, cobrindo exatamente os 6 cenários pedidos (força-update false não bloqueia, falha de rede fail-open, timeout fail-open, force_update=true+abaixo do mínimo bloqueia, force_update=true+no mínimo não bloqueia, `PopScope(canPop:false)` sem botão de saída). Comparador reconfirmado (`1.10.0 > 1.9.0`, build number como critério primário). `RELEASE_GATE_IS_SECURITY_BOUNDARY=false` mantido no código/docs — nenhum `p_client_build` foi adicionado como segurança.

**Baselines**: `flutter analyze` 0 issues · `flutter test` **894 passed / 1 skip** · JS **743 passed / 0 failed**.

**Commit autorizado — tudo verde**: DB 53/53 ✅, seed correto ✅, RLS/grants provados ✅, Release Gate tests verdes ✅, Flutter verde ✅, JS verde ✅. Commit local com paths explícitos (nunca `git add .`) — arquivos do Release Gate (Flutter + migration + testes + l10n + wiring) + tooling/report dos audits 36/37: **`<hash registrado no follow-up de docs>`** — `feat(multiclub): add app release gate`. Exclusões-padrão preservadas fora do stage. **0 git push** — o próximo push é uma operação de release separada (dispara Cloudflare: rebuild Flutter web + publica PWA novo + publica o Worker M3.3 que ainda está pendente), deliberadamente não misturada a esta rodada.

## Estados finais (rodada 3)

`RELEASE_GATE_DB_APPLIED=true` · `RELEASE_GATE_CODE_COMPLETE=true` · `LEGACY_CLIENTS_IN_THE_WILD=true` · `M3_4_APP_DISTRIBUTED=false` · `M2_2B_B_BLOCKED_BY_APP_ROLLOUT=true` · `RPC_ONLY_MIGRATION_REQUIRED=false` · `LEGACY_CONTRACT_RETIREMENT_READY=true` (técnico) · `SECOND_CLUB_BLOCKED=true` · `WORKER_DEPLOY_PENDING_GIT_PUSH=true`.

---

**APLICADO E COMMITADO LOCALMENTE.** Não iniciar M2.2B-B. Não iniciar M4. Não cadastrar segundo clube. **0 git push** — o próximo será tratado como sua própria operação de release, numa rodada dedicada.

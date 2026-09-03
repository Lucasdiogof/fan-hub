# M3.4 Web Release — Controlled Release Operation

Data: 2026-09-03
Status: **PUBLICADO EM PRODUÇÃO.** PWA M3.4+ e Worker M3.3 ao vivo, confirmados por evidência objetiva. `M2.2B-B` continua bloqueada — decisão de produto separada, não resolvida por este release.

---

## 1. HEAD inicial
`4bfe062` (docs follow-up do Release Gate).

## 2. `origin/main` inicial
`613874a` ("Update X posts feed", bot `sync_x_posts.yml`).

## 3. Commits à frente
37 no preflight → 39 depois do fix de tooling + version bump.

## 4. Versão anterior
`1.0.0+1` — igual ao PWA legacy publicado (por isso o bump era obrigatório antes do push).

## 5. Version bump
`pubspec.yaml`: `1.0.0+1` → **`1.0.1+2`**. Confirmado ao vivo que o Release Gate DB (mínimo `1.0.0`/build `1`, `force_update=false` nas 3 plataformas) não bloqueia essa versão — nem alterado.

## 6. Tests Flutter
`flutter analyze`: 0 issues. `flutter test`: **896 passed / 1 skip** (894 + 2 novos: comparador `1.0.1+2 >= 1.0.0+1`, e `ReleaseGate` com a config real publicada). Reconfirmado idêntico depois do merge com `origin/main`.

## 7. JS
`tooling/**/test_*.mjs`: **743 passed / 0 failed**. Um bug de design foi achado e corrigido nesta rodada: 2 audits (`test_multiclub_rollout_readiness.mjs`, `test_legacy_contract_retirement.mjs`) comparavam o JSON de saída byte a byte incluindo um campo **deliberadamente ao vivo** (contagem de commits à frente de `origin/main`) — quebrava a cada novo commit local, não por regressão real. Corrigido isolando esse campo da comparação (commit `f8ffc8b`, separado do version bump).

## 8. Worker vitest
**99 passed / 0 failed** — igual ao baseline M3.3. Reconfirmado idêntico após o merge.

## 9. `tsc`
**0 erros** (`npx tsc --noEmit -p tsconfig.json`). Reconfirmado idêntico após o merge.

## 10. Build web
`flutter build web --release` — sucesso, sem alterar `wrangler.toml`/build command (mesmo comando que o Cloudflare roda). `build/web` nunca staged (gitignorado, artefato).

## 11. `version.json` local
```json
{"app_name":"goias_app","version":"1.0.1","build_number":"2","package_name":"goias_app"}
```

## 12. Commit release-prep
2 commits distintos (nenhum `git add .`):
- `f8ffc8b` `fix(multiclub): stop asserting a live commit-drift count as a fixed snapshot` — fix de tooling achado ao rodar os gates, não causado pelo version bump, commitado separadamente.
- `b846058` `chore(release): bump app version to 1.0.1+2` — só `pubspec.yaml` + os 2 testes de comparador/gate que validam a versão real.

## 13. Push — **divergência real encontrada e reconciliada**

Primeira tentativa de `git push` foi **rejeitada** (non-fast-forward): `origin/main` tinha avançado 1 commit (`613874a`, "Update X posts feed", bot automático — só `src/social/data/x_posts.json`, zero sobreposição com qualquer um dos 39 commits locais). Não era um erro de configuração nem exigia `--force` — era uma divergência real de duas linhas de commit a partir de um ancestral comum (`c07c4e0`).

**Decisão do usuário**: merge controlado (`git merge origin/main`), não rebase — preserva os hashes de TODOS os ~39 commits já citados em `docs/multiclub/*.md` e nas memórias salvas (M3.2, M3.3, M2.2B-A, M3.4, Release Gate). Rebase teria reescrito todos esses hashes desnecessariamente.

Executado exatamente como especificado: `git fetch origin` → `git status` → `git log --left-right` (confirmou 39 local-only / 1 remote-only) → `git merge origin/main` — **sem conflito** (arquivo isolado, zero sobreposição), merge commit `7d75cc3`. Pós-merge: `remote-only=0`, `local-only=40` (39 + o merge). Todos os gates (analyze/test/JS/Worker/tsc/build web) reexecutados e reconfirmados idênticos após o merge, antes de tentar o push de novo.

**`git push`** (2ª tentativa, depois do merge): **sucesso** — `613874a..7d75cc3 main -> main`. Sem `--force`, sem `--force-with-lease`.

## 14. HEAD/origin pós-push
```
HEAD         = 7d75cc35471f0b4cbbc29312a8f9ecd1535fe46e
origin/main  = 7d75cc35471f0b4cbbc29312a8f9ecd1535fe46e
```
`HEAD == origin/main` confirmado. `git rev-list --count origin/main..HEAD` = 0 nos dois sentidos.

## 15. Cloudflare/PWA HTTP
Poll a cada 15s em `/version.json` — o novo build apareceu **~5 minutos** depois do push (20ª tentativa). `GET /` → **HTTP 200** antes e depois.

## 16. `version.json` produção
**Antes do push**: `{"version":"1.0.0","build_number":"1"}` (legacy). **Depois** (confirmado, request fresh): **`{"version":"1.0.1","build_number":"2"}`** — o marcador objetivo principal do novo release, confirmado.

Evidência adicional (secundária, nunca a prova principal — minificação poderia remover): `main.dart.js` do bundle ao vivo contém `update-required` (2×), `upsert_membership_checkin_ticket_for_club` (1×) e `app_release_requirements` (1×) — confirma que o código M3.4 (Release Gate + RPC de check-in dedicada) está genuinamente no bundle publicado, não é coincidência de versão.

## 17. Worker — rota Goiás
`GET /api/football/team/goias` → **HTTP 200**, dados reais do próximo jogo (upstream OneFootball respondendo normalmente). `GET /api/football/team/goias/season` → HTTP 200.

## 18. Worker — clube desconhecido
`GET /api/football/team/club-b` (placeholder sintético, nunca Juventude/RB Bragantino) → **HTTP 404**, `{"error":"unknown club code: club-b"}` — **prova viva do comportamento M3.3**: sem fallback silencioso pro Goiás. `clubRegistry`/`SERVER_CLUB_CODES` continuam com 1 entrada só.

## 19. Service worker
`flutter_service_worker.js` → **HTTP 200**, confirmado no ar. Registrado explicitamente: browsers que já visitaram o app antes podem continuar servindo o bundle antigo do cache do service worker por um tempo — `NEW_WEB_DEPLOYED=true` **não** significa `ALL_LEGACY_BUNDLES_GONE=true`. É exatamente por isso que `LEGACY_CLIENTS_IN_THE_WILD` continua `true` mesmo com o release confirmado.

## 20. Release Gate não bloqueando
Config ao vivo inalterada (mínimo `1.0.0`/build `1`, `force_update=false`, 3 plataformas) + app real agora `1.0.1`/build `2` → o app abre normalmente, sem redirecionar pra `/update-required`. Confirmado por unit test (`ReleaseGate` com a config real) e pela lógica do comparador (build 2 ≥ build 1). Nenhum teste manual de produção foi feito (não é possível/desejável simular um usuário real só pra isso) — a garantia vem do teste automatizado + do fato de `force_update=false` nunca bloquear, por design, independente de versão.

## 21. Check-in fix presente no release
Não executado check-in real em produção (dado fake proibido). Confirmado por evidência de bundle (§16): `upsert_membership_checkin_ticket_for_club` presente no `main.dart.js` publicado — a RPC já está aplicada no banco desde a M3.4 (`db push` da rodada correspondente). O bug do check-in legacy (achado no Legacy Contract Retirement Audit, `docs/multiclub/37_legacy_contract_retirement_report.md` §8) está, portanto, **corrigido neste release** — nenhuma etapa nova foi criada pra ele, nenhuma RPC foi alterada nesta rodada.

## 22. Estados finais

```
M3_4_APP_DISTRIBUTED = true
WEB_PWA_M3_4_DEPLOYED = true
WORKER_DEPLOY_PENDING_GIT_PUSH = false

LEGACY_CLIENTS_IN_THE_WILD = true   (browsers com bundle antigo em cache — não confundir com "app não publicado")
M2_2B_B_BLOCKED_BY_APP_ROLLOUT = true   (inalterado — release concluído não é o mesmo que decisão de retirement)

RPC_ONLY_MIGRATION_REQUIRED = false
LEGACY_CONTRACT_RETIREMENT_READY = true   (técnico, inalterado)

SECOND_CLUB_BLOCKED = true
```

---

## Respostas objetivas (1-24)

1. HEAD pré-release: `4bfe062`. 2. `origin/main` pré-release: `613874a`. 3. Commits à frente: 37 no preflight, 39 antes do merge. 4. Version bump: `1.0.0+1` → `1.0.1+2`. 5. `flutter analyze`: 0 issues. 6. `flutter test`: 896/1 skip. 7. JS: 743/0 (com 1 fix de tooling no meio do caminho, commitado à parte). 8. Worker tests: 99/0. 9. `tsc`: 0 erros. 10. Web build: sucesso. 11. `version.json` local: `1.0.1`/`2`. 12. Commit release: `b846058` (+ `f8ffc8b` fix de tooling, + merge `7d75cc3`). 13. `git push`: rejeitado 1ª vez (divergência real, resolvida por merge conforme decisão do usuário), sucesso na 2ª. 14. `HEAD==origin`: confirmado, `7d75cc3` nos dois. 15. Production HTTP: 200 antes e depois. 16. Production `version.json`: `1.0.0/1` → **`1.0.1/2`** confirmado ao vivo. 17. Worker Goiás: HTTP 200, dados reais. 18. Worker clube desconhecido: **HTTP 404**, sem fallback. 19. Service worker: HTTP 200, ao vivo. 20. `ReleaseGate`: não bloqueia (config atual + versão nova). 21. `M3_4_APP_DISTRIBUTED`: **true**. 22. `WORKER_DEPLOY_PENDING_GIT_PUSH`: **false**. 23. `M2_2B_B_BLOCKED_BY_APP_ROLLOUT`: **true** (inalterado — release não é retirement). 24. `git status`: limpo, só exclusões-padrão (`store_entry_card.dart`, `multiclub_hardcode_audit_stats.json`, `_competitions_pkg/`, `migration_dump.txt`, `19_etapa_e_v4_applied_report.md`).

---

## Próximo gate — não iniciado nesta rodada

**POST-ROLLOUT LEGACY RETIREMENT GATE** (rodada futura, curta): decidir QUANDO executar M2.2B-B, usando (1) este release confirmado, (2) atividade capturada pelo Sentry por release (`goias_app@1.0.1+2` vs `@1.0.0+1`), (3) o risco residual de PWA stale (service worker/cache de browser), (4) o plano de retirement server-side já auditado (`docs/multiclub/37_legacy_contract_retirement_report.md` — key+DEFAULT já são suficientes, 0 RPC-only necessário). **Não iniciado nesta rodada.**

---

**PARADO.** 0 M2.2B-B iniciada. 0 M4 iniciada. 0 segundo clube cadastrado.

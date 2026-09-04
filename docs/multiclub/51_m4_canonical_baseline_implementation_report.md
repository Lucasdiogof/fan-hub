# M4 — Canonical Baseline: implementação (Fase 1, até antes do primeiro db push real)

Data: 2026-09-04
Status: **IMPLEMENTADO localmente. 0 db push real, 0 escrita em qualquer Supabase remoto.** Goiás (`yonozsdgyrhgqrvydbnr`) tocado só em leitura o tempo todo. Bragantino (`yrgyzkaaudyzmsqwzecj`) nunca tocado nesta rodada — nem leitura, nem escrita, nem dry-run (faltou `BRAGANTINO_DB_URL`, ver item 12).

## 1) Arquivos criados

```
infra/supabase/canonical/supabase/.gitignore              (gerado por `supabase init`, já cobre .temp/.branches/.env*)
infra/supabase/canonical/supabase/config.toml              (mínimo, project_id="canonical-baseline" — nunca um ref real)
infra/supabase/canonical/supabase/migrations/
  20260904000000_canonical_baseline.sql                    (2507 linhas — ver item 3/4)
infra/supabase/clubs/README.md
infra/supabase/clubs/goias/bootstrap.sql                   (não aplicado — Goiás já tem a linha real via supabase/migrations/)
infra/supabase/clubs/bragantino/bootstrap.sql               (não aplicado)
tooling/multiclub/supabase_projects_registry.json           (registry: quais projetos existem, qual workdir/env var cada um usa)
tooling/multiclub/db_target_resolver.mjs                    (módulo compartilhado — resolve alvo com segurança)
tooling/multiclub/db-status.mjs                              (leitura, os 2 clubes)
tooling/multiclub/db-push.mjs                                (escrita — goias BLOQUEADO, bragantino exige --yes)
tooling/multiclub/audit_canonical_baseline.mjs               (10 checagens A-J)
tooling/multiclub/test_canonical_baseline.mjs                (13 testes)
tooling/multiclub/test_db_target_resolver.mjs                (7 testes — segurança do tooling em si)
data_export/goias/player_reconciliation/canonical_baseline_audit.json
docs/multiclub/48/49/50 (rodadas anteriores, já existiam)
docs/multiclub/52_m4_auth_config_checklist.md
docs/multiclub/51 (este arquivo)
```
**Modificado**: `tooling/multiclub/clubs_registry.json` (Bragantino canonizado, ver item 6). **Nada em `supabase/`/`supabase/migrations/` (raiz, histórico Goiás) foi tocado.**

## 2) Estrutura do canonical workdir

`infra/supabase/canonical/supabase/config.toml` só tem `project_id = "canonical-baseline"` — nenhum projeto real linkado, nenhum `--linked` usado em lugar nenhum (todo comando remoto usa `--workdir` + `--db-url` explícitos, ver docs/multiclub/50). Confirmado reconhecido pelo CLI (checagem J, ver item 11): `migration list --workdir infra/supabase/canonical --db-url <inválida>` falha por CONEXÃO, não por config/workdir — prova de que a estrutura está correta.

## 3) Baseline criado — como, de verdade

**`supabase db dump` não está disponível neste ambiente** — exige Docker, confirmado indisponível (`docker --version` → command not found), e `pg_dump` nativo também não está no PATH. Reportado como bloqueio de ambiente, não contornado com gambiarra.

Caminho real usado: introspecção SQL direta contra o Goiás vivo (`npx supabase db query --linked`, já usado nas rodadas anteriores), em 7 queries cobrindo colunas (`information_schema.columns`), constraints (`pg_get_constraintdef`), índices (`pg_get_indexdef`), RLS (`pg_policies`), grants de tabela (`information_schema.role_table_grants`), corpo de função (`pg_get_functiondef`) e grants de função por role (`has_function_privilege` × 4 roles). Um script Node monta o SQL a partir desses 7 conjuntos — **nunca `migration squash`, nunca concatenação das 60 migrations**.

## 4) Fontes usadas por bloco

| Bloco | Fonte |
|---|---|
| 55 tabelas (colunas/PK/FK/UNIQUE/CHECK/índices/RLS/grants) | Introspecção ao vivo do Goiás, `public` schema |
| `profiles`/`user_addresses` | Mesma introspecção — são `public`, só nunca tiveram migration (achado dos relatórios 48-50); a introspecção resolve isso sozinha, sem bloco especial |
| `handle_new_user()` + trigger `on_auth_user_created` | Capturados em rodada anterior via `pg_get_functiondef`/`pg_get_triggerdef` — escritos à mão no baseline porque um dump filtrado em `public` não captura um trigger anexado a `auth.users` (schema diferente) |
| Storage (2 buckets + 4 policies) | Capturado em rodada anterior (`storage.buckets`, `pg_policies where schemaname='storage'`) — escrito à mão, DML explicitamente permitido pelo pedido (infraestrutura genérica) |
| 25 funções (RPCs) | `pg_get_functiondef` ao vivo, revisadas uma a uma (ver item 5) |

## 5) Objetos que ficaram PROPOSITALMENTE fora — revisão consciente, não dump cego

- **`store_orders`/`store_order_items`** (tabelas) — a coluna `order_number` tem `DEFAULT generate_store_order_number()`.
- **`generate_store_order_number`** (function) — corpo tem literal `'GOI-'` hardcoded. Débito já registrado desde M4.1 (REQUIRES_REDESIGN, vira `ClubConfig.orderPrefix`).
- **`create_store_order_for_club`** (function) — `RETURNS store_orders` + `INSERT` nas 2 tabelas acima; excluída junto (checado via grep no corpo das 36 funções ao vivo: nenhuma outra função referencia essas 2 tabelas).
- **`subscribe_to_plan_for_club`** (function) — corpo hardcoda os 6 planos reais do Sócio Esmeralda (`'nossa-gente'` → `'NOSSA GENTE'` etc.) — conteúdo editorial, não estrutura. **Achado que uma busca por UUID/nome de clube nunca pegaria** — só apareceu numa revisão de corpo função por função.
- **8 RPCs legadas** (`arena_my_rank`, `arena_ranking`, `arena_record_score`, `arena_user_detail`, `create_store_order`, `crowd_lineup`, `get_my_membership`, `subscribe_to_plan`) — já sem NENHUM grant de EXECUTE ao vivo (M4.1c revogou todos) — vestigiais, confirmado que um projeto novo nunca precisaria delas.

`hasStore=false`/`hasMembership=false` no Bragantino hoje — nenhuma dessas exclusões bloqueia o app.

**Aceito, mas flagado como débito de nomenclatura** (não é identidade de clube pelos critérios pedidos — não é UUID/nome/DEFAULT de club_id — mas é nome semanticamente ligado ao Goiás):
- Colunas `goias_is_home`/`goias_score` (`passport_matches`) e `goias_debut_year` (`guess_players`) — no modelo de 1-Supabase-por-clube, isolamento físico já elimina o risco de vazamento cross-clube que essas colunas representariam num banco compartilhado; fica só confuso quando o Bragantino popular essas colunas com o próprio dado. Não renomeado (redesign de schema fora do escopo pedido).
- `CHECK (difficulty in ('torcedor','esmeraldino','fanatico'))` — decisão já tomada antes (`docs/multiclub/10_club_config.md §4`): enum interno, nunca cru ao usuário. Mantido.

**Passaporte (12 RPCs) INCLUÍDO** estruturalmente, apesar de `PASSPORT_TENANCY_DEFERRED` continuar `true` — no modelo multi-projeto, "não ter `club_id`" deixou de ser um risco de vazamento (cada projeto só tem o dado do próprio clube). `hasPassport=false` no Bragantino, feature inalcançável no app de qualquer forma.

## 6) UUID Bragantino — final, registry atualizado

Validado do zero nesta rodada (não reaproveitado de preview anterior sem reconferir):
```
namespace:  8c1f4e6a-2d9b-4a3c-9e7f-1b6d8a4c2f9e
Goiás:      uuidV5(namespace, "goias-app:multiclub:club:1") = 4c16340d-300c-5ab2-903f-17519db9b146
            (idêntico ao valor real ao vivo — MATCH confirmado)
Bragantino: uuidV5(namespace, "goias-app:multiclub:club:2") = 51683d2a-ea1d-57c6-8014-996146f242e7
```
**Canonizado de verdade**: rodei `registerNewClub()`+`saveClubRegistry()` (as funções REAIS, não mais preview) contra `tooling/multiclub/clubs_registry.json` — `nextSequence` avançou de 2 pra 3, integridade validada (`validateClubRegistryIntegrity`, roda automático no save). **Isto é uma escrita LOCAL only** (arquivo JSON no repo, não Supabase remoto) — dentro do escopo autorizado.

## 7) Bootstrap por clube

`infra/supabase/clubs/{goias,bragantino}/bootstrap.sql` — cada um standalone, fora de qualquer `supabase/migrations/`, nunca aplicado. O do Goiás existe só por paridade/documentação (o Goiás já tem a linha real aplicada via `supabase/migrations/20260902030000_seed_clubs.sql`, histórico, intocado) — nunca deveria rodar contra o projeto real. O do Bragantino é o que rodaria de verdade, DEPOIS do baseline, numa etapa própria com autorização própria.

## 8) Auth checklist

`docs/multiclub/52_m4_auth_config_checklist.md` — estrutura (SHARED/PER_CLUB/PER_ENVIRONMENT) pras configs que vivem fora de SQL (Site URL, redirect URLs, templates de e-mail, OTP, providers, SMTP, JWT/sessão, CAPTCHA). **Nenhum valor real preenchido** — não são lidos via `db query` (são config gerenciada do dashboard/Management API, fora do alcance de SQL) e nenhum foi copiado do Goiás sem confirmação.

## 9) Storage esperado — provado pelas 2 provas (A+B), não só `db diff`

- **A (schema)**: 2 buckets (`avatars`, `email-assets`) + 4 policies (`avatars_public_read`/`avatars_write_own`/`avatars_update_own`/`avatars_delete_own`) escritos explicitamente no baseline, texto EXATO capturado ao vivo (`qual`/`with_check` byte a byte, incluindo o `with_check` de `avatars_write_own` que só existe nesse INSERT, não nos outros 3).
- **B (auditoria estruturada)**: `audit_canonical_baseline.mjs` checa G) contando exatamente 2 buckets + 4 policies com os nomes esperados, comparando contra o gabarito capturado do Goiás — não depende de `db diff` (que tem limitação conhecida com Storage, ver relatório 50).

## 10) Tooling criado

`db_target_resolver.mjs` (módulo compartilhado) + `db-status.mjs` (leitura) + `db-push.mjs` (escrita). Garantias implementadas e TESTADAS (não só declaradas):
- `db-push goias` — bloqueado 2x (código hardcoded + `registry.writable=false`), **impossível mesmo com `--yes`**.
- Env var ausente — fail-loud, nunca pede senha, nunca usa outro clube, mensagem cita exatamente `<CLUBE>_DB_URL_REQUIRED=true`.
- Clube desconhecido — fail-loud, nunca resolve por padrão; chaves internas do registry (`_comment`) nunca aparecem como clube válido (bug pequeno achado e corrigido nesta rodada).
- **Mismatch de host/ref** — se `BRAGANTINO_DB_URL` apontar pro ref do Goiás por engano, falha alto. **Bug real encontrado e corrigido nesta rodada**: a extração de ref da connection string usava uma regex que não lidava com o formato real `postgres.<ref>:<senha>@host` (senha no meio) — trocada por parsing de verdade via `new URL()`.
- Escrita real sem `--yes` — bloqueada; `--dry-run` roda livre.
- Connection string nunca aparece inteira em nenhuma saída — só host sanitizado.

## 11) Resultados dos testes

- `audit_canonical_baseline.mjs` — 10/10 checagens A-J verdes (`baselineReady: true`).
- `test_canonical_baseline.mjs` — **13/13 passaram** (10 reais + 3 fabricados).
- `test_db_target_resolver.mjs` — **7/7 passaram** (achou e corrigiu 1 bug real de parsing de URL antes de qualquer uso contra banco de verdade).
- Suíte completa `tooling/multiclub/test_*.mjs` — **928/928 passaram, 0 falhas** (era 921 antes desta rodada + os 7 novos).
- `flutter analyze`/`flutter test` — **não rodados nesta rodada** — confirmado via `git status` que 0 arquivo `.dart` foi tocado (o único `.dart` no diff é `store_entry_card.dart`, exclusão padrão pré-existente e não relacionada).
- Bugs reais encontrados e corrigidos SÓ por causa dos testes, antes de qualquer escrita remota: (1) GRANT/REVOKE sem assinatura de função (todas as 26 funções seriam SQL inválido se aplicadas assim); (2) parsing de connection string que não detectava mismatch de projeto quando a senha está presente (formato normal).

## 12) Resultado do `db push --dry-run`

**Não rodado.** `BRAGANTINO_DB_URL` não está presente neste ambiente (`env | grep BRAGANTINO_DB_URL` vazio). Confirmado o comportamento fail-loud correto: `db-push.mjs bragantino --dry-run` sem a env var reporta exatamente:
```
BRAGANTINO_DB_URL_REQUIRED=true
```
Nenhuma senha foi pedida, nada foi inventado, o Goiás nunca foi usado no lugar.

## 13) Blockers/secrets necessários pra próxima etapa

- **`BRAGANTINO_DB_URL`** — precisa ser exportada no ambiente antes do próximo passo (dry-run real contra o Bragantino). Pegar em Dashboard do projeto `yrgyzkaaudyzmsqwzecj` → Settings → Database → Connection string (pooler de sessão, percent-encoded).
- Docker/`pg_dump` continuam indisponíveis neste ambiente — se uma comparação `db diff --from/--to` remoto-a-remoto (relatório 50, item 2) for necessária depois, confirmar se isso também precisa de Docker ou se `--from`/`--to` com 2 URLs reais funciona sem shadow database (não testado ainda, sem conexão real disponível).
- Auth checklist (`docs/multiclub/52`) tem várias linhas `PER_CLUB` sem valor real — precisa de alguém com acesso ao dashboard do Goiás pra preencher antes do Bragantino ser inicializado de verdade.
- `create_store_order_for_club`/Membership real (`subscribe_to_plan`) ficam bloqueados até uma etapa própria de redesign (`ClubConfig.orderPrefix`, tabela `membership_plans` club-scoped) — não é um blocker desta Fase 1, só registrado pra não ser esquecido.

## 14) git status final

```
 M data_export/.../multiclub_legacy_contract_retirement_{audit,stats}.json    (NÃO relacionado — outra etapa)
 M data_export/.../multiclub_post_rollout_retirement_gate_{audit,stats}.json  (NÃO relacionado)
 M data_export/.../multiclub_rollout_readiness_audit.json                     (NÃO relacionado)
 M docs/multiclub/39_post_rollout_legacy_retirement_gate.md                   (NÃO relacionado)
 M lib/features/store/presentation/widgets/store_entry_card.dart              (exclusão padrão, sempre preservada)
 M tooling/multiclub/audit_post_rollout_retirement_gate.mjs                   (NÃO relacionado)
 M tooling/multiclub/test_post_rollout_retirement_gate.mjs                    (NÃO relacionado)
 M tooling/multiclub/clubs_registry.json                                     (Bragantino canonizado — item 6)
?? infra/                                                                     (workdir canônico + bootstrap — itens 1-2-3-7)
?? tooling/multiclub/{audit,test}_canonical_baseline.mjs                      (item 10-11)
?? tooling/multiclub/db-status.mjs / db-push.mjs / db_target_resolver.mjs     (item 10)
?? tooling/multiclub/test_db_target_resolver.mjs                             (item 11)
?? tooling/multiclub/supabase_projects_registry.json                         (item 10)
?? data_export/.../canonical_baseline_audit.json                             (saída do audit)
?? docs/multiclub/48/49/50/51/52                                             (documentação)
?? _competitions_pkg/, migration_dump.txt, docs/multiclub/19_...             (exclusões padrão, sempre preservadas)
```
Nenhum arquivo de outra etapa foi tocado/staged. Nada commitado ainda (a rodada não pediu commit).

---

**0 db push real. 0 escrita em Supabase remoto (nem Goiás nem Bragantino). 0 migration repair. 0 mover migrations. 0 git push. 0 commit.**

PARE.

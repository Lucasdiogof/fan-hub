# 53 — Canonical baseline: correção redonda 3 (nomes goias_*, Store, Membership)

Este documento CORRIGE/SUPERA partes específicas de
[51_m4_canonical_baseline_implementation_report.md](51_m4_canonical_baseline_implementation_report.md).
Não reescreve o 51 — o 51 continua sendo o relato fiel de como o baseline foi
construído (introspecção viva, exclusões originais, bug do GRANT/REVOKE sem
assinatura, etc.). Este doc 53 registra o que mudou depois, nesta rodada de
correção, e por quê. As seções abaixo são numeradas 1–8 para bater
exatamente com o pedido do usuário.

Constraints que seguem valendo, intocadas, para esta rodada e até nova
autorização explícita:
**0 DDL, 0 DML, 0 migration repair, 0 rename, 0 push contra o Goiás
(`yonozsdgyrhgqrvydbnr`)** — o Goiás ao vivo mantém `goias_is_home` /
`goias_score` / `goias_debut_year`, o prefixo `GOI-` hardcoded e o catálogo
de planos hardcoded, até um futuro cutover (Fase 2) separadamente
autorizado. **0 db push Bragantino, 0 dry-run remoto, 0 git push, 0
commit** nesta rodada — só o arquivo do baseline canônico, tooling, testes,
docs e bootstrap local foram tocados.

## 1) Decisão sobre `goias_*`

Opção **A** adotada, conforme preferência explícita do usuário: renomear
para nomes genéricos **só no canonical baseline**, já que o Bragantino está
vazio e qualquer novo clube nasce direto com o nome certo.

Renomeações aplicadas em
`infra/supabase/canonical/supabase/migrations/20260904000000_canonical_baseline.sql`:

| Legado (Goiás ao vivo, intocado) | Canonical baseline |
|---|---|
| `passport_matches.goias_is_home` | `passport_matches.club_is_home` |
| `passport_matches.goias_score` | `passport_matches.club_score` |
| `guess_players.goias_debut_year` | `guess_players.club_debut_year` |

O mapping fica documentado no cabeçalho do próprio arquivo `.sql` — é o que
a Fase 2 (cutover futuro do Goiás, via `migration repair`, ainda não
autorizada) vai precisar para migrar as colunas reais sem depender de
memória/reconstrução. As 6 RPCs que liam/escreviam essas colunas
(`passport_summary`, `passport_seasons`, `passport_attendance_breakdown`,
`passport_attended_matches`, `passport_matches_for_year`,
`passport_my_attendances_for_year`) foram atualizadas junto — corpo E
`RETURNS TABLE(...)`.

Zero alteração no schema real do Goiás. As colunas antigas continuam lá,
intocadas, com os nomes de sempre.

## 2) Schema canônico resultante

Sem mudança estrutural fora das renomeações acima e da seção Store/Membership
(itens 3–4): 55 tabelas, agora **29 funções** (eram 26 no relatório 51 —
+3: `generate_store_order_number`, `create_store_order_for_club`,
`subscribe_to_plan_for_club`, todas reintroduzidas e redesenhadas
genéricas). `public.clubs` ganhou 1 coluna nova: `order_prefix text`
(nullable, sem DEFAULT — nunca populada pelo baseline, só por bootstrap
per-club futuro).

## 3) Tratamento definitivo — Store

Princípio aplicado (explícito do usuário): **SCHEMA CAPABILITY ≠ PRODUCT
CAPABILITY**. Como não existe sistema de migrations modulares, a tabela e a
função precisam existir pra qualquer clube — `hasStore=false` no
`ClubCapabilities` do Bragantino continua controlando só UI/rotas/API, nunca
a existência do schema.

Mudanças no baseline:
- `store_orders` e `store_order_items` **reintroduzidas** (antes excluídas
  por completo).
- `store_orders.order_number` deixou de ter
  `DEFAULT generate_store_order_number()` (função sem argumento não serve
  como default parametrizado por clube) — agora é preenchida
  explicitamente por `create_store_order_for_club` antes do INSERT.
- `generate_store_order_number(p_club_id uuid)` **reescrita**: lê
  `clubs.order_prefix`, com fallback `upper(left(slug, 3))` se
  `order_prefix` for NULL — nenhum `GOI-` hardcoded restante.
- `create_store_order_for_club` **reintroduzida**, chamando a função acima
  para preencher `order_number` antes do INSERT.
- `create sequence public.store_order_number_seq` adicionada (1 sequence
  por PROJETO — não por clube — é suficiente no modelo multi-Supabase, já
  que cada clube tem seu próprio banco).

Zero conteúdo de loja inserido pelo baseline. `store_orders`/
`store_order_items` nascem vazias em qualquer clube novo.

## 4) Tratamento definitivo — Membership

Também tratado como SCHEMA CAPABILITY. **Implementado nesta rodada** — não
ficou como blocker (a expansão de escopo permitida pelo usuário como escape
hatch não foi necessária).

- Nova tabela `public.membership_plans` (`club_id`, `plan_key`, `name`,
  `duration_days`, `is_active`, `sort_order`, `created_at`), PK composta
  `(club_id, plan_key)`, FK para `clubs(id)`, RLS com leitura pública
  (`select` para `anon`/`authenticated`), escrita só `service_role`.
  **Nasce vazia** — zero planos inseridos pelo baseline (conteúdo de plano é
  bootstrap/produto per-club, fora de escopo desta rodada).
- `subscribe_to_plan_for_club` **reescrita**: em vez do `CASE` hardcoded com
  os 6 pares `nossa-gente`/`NOSSA GENTE`/etc. e `interval '30 days'` fixo,
  agora faz `select mp.name, mp.duration_days from public.membership_plans
  where club_id = p_club_id and plan_key = p_plan_id and is_active` e
  calcula `expires_at` a partir de `duration_days`. Lock advisory, checagem
  de assinatura ativa duplicada e `SECURITY DEFINER` preservados
  idênticos ao original.

## 5) Novos blockers

**Nenhum.** `CANONICAL_BASELINE_BLOCKERS` (lista mecanizável em
`tooling/multiclub/audit_canonical_baseline.mjs`) está vazia — Store e
Membership saíram ambos como schema genérico real, não como blocker. O
mecanismo fica registrado e testado (ver item 7) para qualquer rodada futura
que precise adiar algo por escopo: nesse caso o nome da function/tabela e o
motivo entram nessa lista, nunca apenas implícito por uma capability
desligada.

## 6) Resultado do audit `baselineReady`

`node tooling/multiclub/audit_canonical_baseline.mjs` — todas as checagens,
incluindo as 4 novas desta rodada, retornam `true`:

```json
{
  "a_noForbiddenClubLiterals": true,
  "a2_noForbiddenIdentifiers": true,
  "b_noRealClubUuid": true,
  "c_noHardcodedClubIdDefault": true,
  "d_rpcAclClean": true,
  "functionCount": 29,
  "e_hasProfilesTable": true,
  "e_hasUserAddressesTable": true,
  "e_hasHandleNewUserFn": true,
  "f_hasAuthTrigger": true,
  "g_storageBucketsOk": true,
  "g_storagePoliciesOk": true,
  "h_zeroEditorialSeeds": true,
  "j_canonicalConfigExists": true,
  "j_workdirRecognized": true,
  "l_noEditorialPlanContent": true,
  "m_storeSchemaGeneric": true,
  "n_membershipOkOrBlocked": true,
  "baselineReady": true
}
```

Checks novos desta rodada (A2, L, M, N) descritos no item 7 de
[51](51_m4_canonical_baseline_implementation_report.md#pendências) como
gap — agora fechados:
- **A2** — nenhum identifier (não só literal string) com `goias`/
  `bragantino`/`GOI-` embutido, em qualquer lugar do SQL.
- **L** — nenhum dos 6 literais de plano editorial (`'nossa-gente'`,
  `'plano-vip'`, etc., maiúsculo/minúsculo) aparece em lugar nenhum.
- **M** — `store_orders`/`store_order_items` presentes, função de número de
  pedido com assinatura `(p_club_id uuid)`, `create_store_order_for_club`
  presente, `clubs.order_prefix` existe.
- **N** — `membership_plans` presente E `subscribe_to_plan_for_club` prova
  ser data-driven (lê da tabela, não tem CASE hardcoded) — OU, como
  alternativa válida não usada nesta rodada, um `CANONICAL_BASELINE_BLOCKER`
  registrado.

`baselineReady=true` só é permitido, pela regra do próprio script, se
**todos** os checks A–N + as validações pré-existentes (E/F/G/H/J)
passarem — nenhum caminho aceita `true` com blocker pendente.

## 7) Testes

`tooling/multiclub/test_canonical_baseline.mjs`: **21 passaram, 0
falharam** (eram 13 antes desta rodada — 8 novos: 1 real + 1 fabricado para
A2, 1 real + 1 fabricado para L, 1 real (4 asserts) + 1 fabricado para M, 1
real (5 asserts) + 1 fabricado para N; `functionCount` atualizado 26→29).

Suíte completa de tooling (`tooling/multiclub/test_*.mjs`, 34 arquivos):
todos com exit 0, 0 `FAIL` em qualquer um. Nenhum outro arquivo de teste
precisou de ajuste — o redesenho ficou isolado ao baseline canônico e ao seu
próprio audit/test.

Dart/Flutter (`flutter analyze`/`flutter test`): **não rodados** — 0
arquivos `.dart` tocados nesta rodada (trabalho é puramente SQL do
canonical baseline + tooling Node), consistente com a convenção já
estabelecida na Fase 1.

## 8) git diff / status

`git status --porcelain` real, nenhum commit feito. `infra/supabase/` inteiro
segue **não-rastreado** (`??`) porque nunca foi commitado em nenhuma rodada
anterior — os edits desta rodada (rename `goias_*`→`club_*`, Store,
Membership, `order_prefix` nos 2 bootstraps) estão dentro dele, mas o git
não distingue "arquivo novo modificado de novo" de "arquivo novo", ambos
aparecem como `??`:

```
 M tooling/multiclub/clubs_registry.json          (canonizado na rodada Fase 1, inalterado nesta)
?? infra/supabase/canonical/                       (contém o baseline.sql com as 3 correções desta rodada)
?? infra/supabase/clubs/                            (os 2 bootstrap.sql com order_prefix desta rodada)
?? tooling/multiclub/audit_canonical_baseline.mjs   (checks A2/L/M/N desta rodada)
?? tooling/multiclub/test_canonical_baseline.mjs    (8 testes novos desta rodada)
?? tooling/multiclub/db-push.mjs                    (Fase 1, inalterado nesta)
?? tooling/multiclub/db-status.mjs                  (Fase 1, inalterado nesta)
?? tooling/multiclub/db_target_resolver.mjs         (Fase 1, inalterado nesta)
?? tooling/multiclub/supabase_projects_registry.json(Fase 1, inalterado nesta)
?? tooling/multiclub/test_db_target_resolver.mjs    (Fase 1, inalterado nesta)
?? docs/multiclub/48_...50_....md                   (rodadas de design anteriores)
?? docs/multiclub/51_m4_canonical_baseline_implementation_report.md (Fase 1)
?? docs/multiclub/52_m4_auth_config_checklist.md    (Fase 1, inalterado nesta)
?? docs/multiclub/53_m4_canonical_baseline_correction_round3.md (este arquivo)
```

Note também `M docs/multiclub/39_...md`, `M tooling/multiclub/audit_post_rollout_retirement_gate.mjs`
e `M tooling/multiclub/test_post_rollout_retirement_gate.mjs` no status —
**não fazem parte desta rodada**, são estado pré-existente de trabalho
anterior não relacionado a multi-Supabase, não tocados aqui.

Zero DDL/DML/migration repair/rename/push contra o Goiás. Zero db push
Bragantino. Zero dry-run remoto. Zero git push. Zero commit.

PARE.

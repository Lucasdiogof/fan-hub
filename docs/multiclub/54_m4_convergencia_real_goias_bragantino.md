# 54 — Convergência real Goiás ↔ Bragantino (execução das Etapas 1-10)

Data: 2026-09-04. Autorização explícita do usuário: alterar schema/RPCs/
colunas/contratos do Goiás em produção, dado que "ninguém está usando o
app" — confirmado por dado real (`store_orders`/`store_order_items`/
`supporter_memberships` com 0 linhas ao vivo antes desta rodada; 17 usuários
reais em `auth.users`, nunca tocados).

Constraints respeitadas o tempo todo: fail-loud, validação a cada etapa,
zero fallback cross-club, **0 git push/commit** (só sugestão no final).

## 1) Dry-run Bragantino

Primeiro dry-run falhou 2x com bugs reais no canonical baseline (nunca
detectados por dry-run, só pelo push real — motivo exato de nunca pular
essa etapa):
- 20 FKs inline referenciando tabelas criadas depois no arquivo (ordem
  alfabética da introspecção) → movidas pra um bloco único ao final.
- 2 colunas com o pseudo-tipo `ARRAY` (limitação do `information_schema`)
  → corrigidas pra `text[]`.

Terceiro dry-run: limpo.

## 2) Baseline real Bragantino

Push aplicado com sucesso (depois de mais um bug real — `handle_new_user`
definida 2x no arquivo, idempotente mas redundante, deduplicada;
`functionCount` correto é **28**, não 29). Validação estrutural ao vivo
(`tooling/multiclub/validate_bragantino_live.mjs`, novo): 58 tabelas, 85
FK / 58 PK / 19 UNIQUE, 152 índices (75 explícitos + 58 de PK + 19 de
UNIQUE — bate exato), RLS em 100% das tabelas, 2 buckets + 4 policies de
Storage, `clubs`/`membership_plans`/`store_orders`/`store_order_items`/
`auth.users` todas vazias, zero literal "goias". `VALIDATION_OK=true`.

## 3) Bootstrap Bragantino

`infra/supabase/clubs/bragantino/bootstrap.sql` aplicado (2 statements
separados — `db query --file` não aceita múltiplos statements). `select *
from public.clubs` → exatamente 1 linha: id `51683d2a-ea1d-57c6-8014-
996146f242e7`, slug `bragantino`, `order_prefix=null` (DATA_GAP real).

## 4) Migration aplicada no Goiás

3 migrations novas em `supabase/migrations/` (histórico de 60 arquivos
nunca alterado):
- `20260904190000_multiclub_canonical_convergence.sql` — renames + Store +
  Membership + remoção de 8 functions legadas.
- `20260904220000_harden_legacy_rpc_acl_parity.sql` — ACL de 14 functions
  pré-existentes, endurecida pra bater com o canonical.
- `20260904230000_align_function_body_order_with_canonical.sql` — 2
  functions com statements reordenados pra bater byte-a-byte com o
  canonical.

Todas com dry-run limpo antes do push real. 1 bug real achado e corrigido
no meio do caminho: `CREATE OR REPLACE FUNCTION` não pode renomear colunas
de saída (`RETURNS TABLE`) — Postgres exige `DROP + CREATE` (SQLSTATE
42P13). Migration inteira é transacional — o primeiro erro reverteu tudo
sozinho, confirmado (`goias_is_home` ainda lá depois do rollback).

## 5) Renames executados

`passport_matches.goias_is_home → club_is_home`, `.goias_score →
club_score`, `guess_players.goias_debut_year → club_debut_year`. Só 3
functions de fato referenciavam essas colunas ao vivo (`passport_
attendance_breakdown`, `passport_attended_matches`, `passport_matches_
for_year` — confirmado por scan de `prosrc`, não presumido a partir do
canonical). Zero alteração no schema legado histórico — Goiás manteve seu
próprio `supabase/migrations/`.

## 6) Store genérica

`clubs.order_prefix` adicionado (`'GOI'` pro Goiás). `generate_store_
order_number()` → `generate_store_order_number(p_club_id uuid)`, lê
`clubs.order_prefix` com fallback pro slug — zero `'GOI-'` hardcoded
restante. `create_store_order_for_club` atualizada pra computar
`order_number` explicitamente (não é mais `DEFAULT` de coluna). 0 linhas
existentes — nada a migrar de dado real.

## 7) Membership genérica

`membership_plans` criada e **populada com os 6 planos reais** extraídos
do `CASE` hardcoded original (`nossa-gente`/`nossa-historia`/`nossa-garra`/
`nossa-gloria`/`nossa-familia`/`plano-vip`, todos `duration_days=30` — era
o valor fixo já usado pra todos, preservado, não inventado).
`subscribe_to_plan_for_club` reescrita data-driven. 0 memberships
existentes — nada a migrar.

## 8) Schema diff Goiás × Bragantino

`tooling/multiclub/diff_schema_goias_bragantino.mjs` (novo) — comparação
estrutural completa: tabelas, colunas, `clubs` (estrutura, nunca linha),
constraints, índices, RLS, policies, functions (assinatura + corpo +
ACL), triggers, sequences, Storage (buckets + policies).

Passou por 3 rodadas de correção real até zerar:
- **48 diffs** iniciais: 14 functions pré-existentes do Goiás com ACL
  solta (`pub=true`, nunca endurecida historicamente) + 3 triggers em
  `delivery_addresses` que existiam no Goiás mas **faltavam no canonical
  baseline** (gap real da construção original — corrigido nos dois
  lugares: arquivo base + migration de correção pro Bragantino já
  aplicado) + 17 diffs de corpo de function que eram só CRLF/whitespace.
- **3 diffs** depois de corrigir triggers + ACL: 3 functions com
  diferença REAL de texto (ordem de `declare`/statements independentes,
  zero diferença de comportamento) — alinhadas ao canonical.

```
SCHEMA_DIFF=0
SCHEMA_EQUAL=true
```

## 9) Supabase por flavor + Flutter

- `ClubIntegrations` ganhou `supabaseUrl`/`supabasePublishableKey`/
  `supabaseRedirectUrl` (nullable, mesmo padrão de `workerBaseUrl`).
- `goias_club_config.dart`: valores reais preenchidos (os mesmos que
  antes eram `defaultValue` hardcoded em `SupabaseConfig`).
- `bragantino_club_config.dart`: `supabaseUrl` preenchido (dado público,
  deriva só do project ref); `supabasePublishableKey`/`supabaseRedirectUrl`
  **`null` — DATA_GAP real**: a chave publishable/anon do projeto
  Bragantino nunca foi compartilhada nesta sessão (só a senha de banco,
  que NUNCA vai pro Flutter). `canonicalClubId` atualizado do placeholder
  `00000000-...` pro UUID real já aplicado.
- `SupabaseConfig` reescrita: de `String.fromEnvironment` com
  `defaultValue` do Goiás → `configure(ClubConfig)` chamado 1x em
  `main()`, lança `StateError` claro se o clube ativo não tiver
  `supabaseUrl`/`supabasePublishableKey` — **nunca cai pro Goiás**.
  Rodar o flavor `bragantino` hoje falha loud nesse ponto (esperado, até a
  chave real ser preenchida).
- `goias_is_home`/`goias_score`/`goias_debut_year` (Dart) → `club_is_home`/
  `club_score`/`club_debut_year` em 12 arquivos (entities, repository,
  cubits, widgets, `guess_player_catalog.dart` com 150+ ocorrências do
  mesmo campo). `flutter analyze`: limpo.

## 10) Auth por projeto

Confirmado: `SupabaseConfig.configure` resolve `auth` para o projeto do
clube ativo automaticamente (é o mesmo client Supabase que faz DB + Auth).
Goiás → `yonozsdgyrhgqrvydbnr`, Bragantino → `yrgyzkaaudyzmsqwzecj`
(quando a chave publishable for preenchida). `auth.users` fisicamente
separado por projeto — mesmo e-mail/CPF podem existir nos dois sem
conflito, é uma propriedade estrutural da arquitetura, não precisou de SQL
adicional. Checklist de config manual de Dashboard (Site URL, Redirect
URLs, templates de e-mail, SMTP) segue documentado e **pendente de
preenchimento manual** em `docs/multiclub/52_m4_auth_config_checklist.md`
— nenhum valor foi inventado.

## 11) Migration history / cutover — BLOQUEADO, reportando conforme pedido

Estado exportado antes de qualquer decisão:
- Goiás: **63** versões em `supabase_migrations.schema_migrations` (60
  históricas + as 3 desta rodada).
- Bragantino: **2** versões (`20260904000000_canonical_baseline`,
  `20260904210000_add_delivery_address_triggers`).

Dúvida real encontrada: o cutover original (docs 49/50) previa Goiás
terminando equivalente a "canonical_baseline + 1 fix", mas a convergência
real do Goiás aconteceu em **3 migrations incrementais** (rename, ACL,
alinhamento) sobre um histórico de 60 arquivos já existentes — não em 2
arquivos que espelham o canonical. Um `migration repair` que tentasse
mapear as 63 versões do Goiás pras 2 do canonical apagaria o registro
real de COMO a convergência aconteceu, mesmo o SCHEMA resultante sendo
idêntico agora. Não decidi essa modelagem sozinho.

**Não executei nenhum `migration repair`.** Conforme instruído: "se houver
qualquer dúvida real nessa etapa: PARE antes do repair e reporte." Fica
como decisão em aberto pra uma rodada futura, separadamente autorizada.

## 12) Testes — todos rodados, resultado

| Suite | Resultado |
|---|---|
| `flutter analyze` | limpo |
| `flutter test` | **995 passaram**, 1 skip (smoke test antigo, já `skip: true` antes desta rodada) |
| `npx tsc --noEmit` (Worker) | limpo |
| `npx vitest run` (Worker) | **141 passaram** (19 arquivos) |
| `tooling/multiclub/test_*.mjs` (34 arquivos) | **33 arquivos 100% verdes**; 1 falha não-regressão (ver abaixo) |
| `audit_canonical_baseline.mjs` | `baselineReady: true` |
| `test_canonical_baseline.mjs` | 21 passaram |
| `test_db_target_resolver.mjs` | 8 passaram (reescrito — `goias` agora é write target válido, mesmas guardas do `bragantino`) |
| `diff_schema_goias_bragantino.mjs` | `SCHEMA_DIFF=0` |

**1 falha não-regressão**: `test_fix_ambiguous_id_membership_rpcs.mjs`
verifica que `supabase/migrations/` está com `git status` limpo (uma
premissa de uma rodada anterior já finalizada). Falha porque as 3
migrations desta rodada estão genuinamente não-commitadas ainda — some
assim que o commit for autorizado, não é um problema no código.

## 13) Arquivos alterados (só os desta fase — resto do working tree preservado)

**Modificados:**
```
lib/core/club/bragantino_club_config.dart
lib/core/club/club_integrations.dart
lib/core/club/goias_club_config.dart
lib/core/config/supabase_config.dart
lib/main.dart
lib/features/arena/games/guess_player/data/guess_player_catalog.dart
lib/features/arena/games/guess_player/data/guess_player_repository.dart
lib/features/arena/games/guess_player/domain/guess_comparison.dart
lib/features/arena/games/guess_player/domain/guess_player.dart
lib/features/arena/games/guess_player/widgets/guess_comparison_table.dart
lib/features/passport/domain/entities/passport_match.dart
lib/features/passport/presentation/cubit/passport_state.dart
lib/features/passport/presentation/pages/passport_trajectory_page.dart
lib/features/passport/presentation/widgets/passport_memorable_match_picker.dart
test/features/arena/guess_player/guess_player_test.dart
test/features/passport/passport_cubit_test.dart
test/features/passport/passport_trajectory_cubit_test.dart
test/widget_test.dart
infra/supabase/canonical/supabase/migrations/20260904000000_canonical_baseline.sql
tooling/multiclub/supabase_projects_registry.json
tooling/multiclub/db-push.mjs
tooling/multiclub/test_db_target_resolver.mjs
```

**Novos:**
```
supabase/migrations/20260904190000_multiclub_canonical_convergence.sql
supabase/migrations/20260904220000_harden_legacy_rpc_acl_parity.sql
supabase/migrations/20260904230000_align_function_body_order_with_canonical.sql
infra/supabase/canonical/supabase/migrations/20260904210000_add_delivery_address_triggers.sql
tooling/multiclub/diff_schema_goias_bragantino.mjs
tooling/multiclub/validate_bragantino_live.mjs
docs/multiclub/54_m4_convergencia_real_goias_bragantino.md
```

**NÃO fazem parte desta fase (preservados, não tocados)**: `lib/features/
store/presentation/widgets/store_entry_card.dart`, `docs/multiclub/39_...`,
`tooling/multiclub/audit_post_rollout_retirement_gate.mjs`, `tooling/
multiclub/test_post_rollout_retirement_gate.mjs`, os 5 `data_export/.../
multiclub_*retirement*/*rollout*.json`, `_competitions_pkg/`,
`migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md` —
estado pré-existente de trabalho anterior não relacionado.

`tooling/multiclub/clubs_registry.json` segue modificado de uma rodada
anterior (canonização do Bragantino) — não tocado nesta, mas pertence à
mesma feature, incluído na sugestão de commit abaixo.

## 14) Migrations criadas (resumo)

4 arquivos `.sql` novos no total — 3 no Goiás real (`supabase/migrations/`)
+ 1 no canonical baseline (`infra/supabase/canonical/`), listados no item
13.

## 15) git status

Ver item 13 (lista completa e classificada). Nenhum `git add`/`commit`
executado.

## 16) Commits sugeridos

Ordem sugerida (nunca executado — aguardando autorização):

1. `fix: correct canonical baseline table order, ARRAY type and duplicate handle_new_user` — `infra/supabase/canonical/supabase/migrations/20260904000000_canonical_baseline.sql`.
2. `feat: add missing delivery_addresses triggers to canonical baseline` — `infra/supabase/canonical/supabase/migrations/20260904210000_add_delivery_address_triggers.sql`.
3. `feat: converge Goiás schema to canonical (rename, generic store/membership, ACL parity)` — os 3 arquivos em `supabase/migrations/2026090419-23*`.
4. `fix: correct tooling/multiclub write targets and workdir resolution for goias` — `tooling/multiclub/supabase_projects_registry.json`, `db-push.mjs`, `test_db_target_resolver.mjs`.
5. `feat: add live Bragantino validation and Goiás/Bragantino schema diff tooling` — `tooling/multiclub/validate_bragantino_live.mjs`, `diff_schema_goias_bragantino.mjs`.
6. `feat: resolve Supabase config per club flavor (no Goiás fallback)` — `lib/core/config/supabase_config.dart`, `lib/core/club/club_integrations.dart`, `lib/core/club/goias_club_config.dart`, `lib/core/club/bragantino_club_config.dart`, `lib/main.dart`, `test/widget_test.dart`.
7. `refactor: rename goias_* columns/fields to club_* across Flutter` — os 12 arquivos de `lib/features/{passport,arena}/**` + os 3 de `test/features/**`.
8. `docs: multi-Supabase convergence report` — `docs/multiclub/54_m4_convergencia_real_goias_bragantino.md`.

PARE antes de git push — nenhum commit/push executado.

# 55 — Migration-history cutover: Goiás e Bragantino, uma única cadeia

Data: 2026-09-04. Pré-condição comprovada antes de começar: `SCHEMA_DIFF=0`
entre Goiás e Bragantino (ver [docs/multiclub/54](54_m4_convergencia_real_goias_bragantino.md)).
Autorização explícita: "ninguém está usando o app... não precisamos
preservar a cadeia legacy como cadeia operacional."

## 1) Snapshot pré-repair

Capturado em `docs/multiclub/migration_history_snapshot_pre_repair_2026-09-04.json`
antes de qualquer `migration repair`: 63 versões do Goiás (version, name,
contagem de statements, md5 dos statements — sem connection string/senha),
2 do Bragantino. `SCHEMA_DIFF=0` reconfirmado como precondição imediatamente
antes.

## 2) Archive criado

`archive/supabase/goias-legacy-migrations/` — os 63 arquivos `.sql`
(`git mv`, histórico de rename preservado), `README.md` explicando o
porquê, `files_sha256_manifest.json` (hash+tamanho de cada arquivo local),
`last_remote_state_before_cutover.json` (cópia da seção Goiás do snapshot
do item 1). Estrutura sem `config.toml` em nenhum nível — o Supabase CLI
nunca reconhece esse diretório como um workdir, mesmo com "supabase" no
caminho.

## 3) Estrutura final de `supabase/migrations/`

```
supabase/migrations/
  20260904000000_canonical_baseline.sql
  20260904210000_add_delivery_address_triggers.sql
```

Cópia byte-idêntica do que estava em `infra/supabase/canonical/supabase/
migrations/` (confirmado via `diff`) — depois copiado, `infra/supabase/
canonical/` foi removida por inteiro (nunca tinha sido commitada, conteúdo
100% duplicado, zero perda de histórico). `infra/supabase/clubs/`
(bootstrap de identidade por clube) não foi tocada — é uma preocupação
separada, não faz parte da cadeia de migrations.

## 4) Migration repair executado

Dois `supabase migration repair` contra o Goiás real (`yonozsdgyrhgqrvydbnr`,
confirmado via banner de alvo sanitizado antes de cada um, senha nunca
impressa):

```
migration repair <63 versões> --status reverted --workdir . --db-url $GOIAS_DB_URL
migration repair 20260904000000 20260904210000 --status applied --workdir . --db-url $GOIAS_DB_URL
```

Ambos metadata-only — nenhum DDL executado, nenhum `db push` rodou de
novo. O schema do Goiás não foi tocado por este passo (já estava
convergido desde a rodada anterior).

## 5-6) `migration list` — Goiás e Bragantino

Idêntico nos dois, depois do repair:

```json
{"migrations":[
  {"local":"20260904000000","remote":"20260904000000","time":"2026-09-04 00:00:00"},
  {"local":"20260904210000","remote":"20260904210000","time":"2026-09-04 21:00:00"}
]}
```

## 7) MIGRATION_HISTORY_EQUAL

```
MIGRATION_HISTORY_EQUAL=true
```

Nenhuma migration Goiás-only pendente, nenhuma canonical pendente.

## 8) SCHEMA_DIFF pós-cutover

Reconfirmado depois do repair (que é metadata-only, não deveria mudar
nada — confirmação de que nada quebrou):

```
SCHEMA_DIFF=0
SCHEMA_EQUAL=true
```

## 9) Tooling atualizado

`tooling/multiclub/supabase_projects_registry.json`: `goias.workdir` e
`bragantino.workdir` agora são o mesmo (`.` — raiz do repo). `db-push.mjs`
já não tinha mais o bloqueio hardcoded de `goias` (removido na rodada
anterior); nenhuma mudança adicional necessária além do registry, já que
os wrappers já eram genéricos por clube. Novo teste em
`test_db_target_resolver.mjs`:

```
MIGRATION_SOURCE_EQUAL_FOR_ALL_CLUBS=true
```

(`registry.goias.workdir === registry.bragantino.workdir`, com um teste
fabricado provando que a checagem reprova se algum dia voltarem a
divergir).

**Efeito colateral real do reorganize**: ~40 scripts em `tooling/multiclub/`
(a maioria `test_*.mjs`/`audit_*.mjs` de etapas anteriores, mais alguns
`generate_*.mjs`) liam arquivos de migration específicos direto de
`supabase/migrations/<nome>.sql` — todos precisaram ser corrigidos pra ler
do novo local no archive. Um desses (`audit_multiclub_runtime_user_state_
scope.mjs`) tinha um bug real: um `fs.existsSync()` que, ao não achar o
arquivo no caminho antigo, silenciosamente pulava (`continue`) o cálculo
de ACL efetivo em vez de falhar — produzindo um resultado ACL incorreto
sem erro nenhum. Corrigido junto.

## 10) Gates

| Suite | Resultado |
|---|---|
| `flutter analyze` | limpo |
| `flutter test` | 995 passaram, 1 skip (mesmo skip de sempre) |
| `npx tsc --noEmit` | limpo |
| `npx vitest run` | 141 passaram (19 arquivos) |
| `tooling/multiclub/test_*.mjs` (34 arquivos) | **34/34 verdes**, incluindo a falha de git-hygiene da rodada anterior — reescrita pra checar `git ls-files` no novo caminho do archive em vez de exigir working tree limpo |
| `audit_canonical_baseline.mjs` | `baselineReady: true` (lendo os 2 arquivos de `supabase/migrations/`, concatenados — só ler o primeiro ignoraria silenciosamente o 2º, outro bug real corrigido nesta rodada) |
| `diff_schema_goias_bragantino.mjs` | `SCHEMA_DIFF=0` |
| `migration list` (os 2 projetos) | idênticos |

## 11) Commits criados (nenhum push)

5 commits locais, cada um com `git add <paths exatos>`, nunca `git add .`/
`-A`:

1. `9df5aea` — promoção do canonical + archive das 63 migrations legadas.
2. `f6d396c` — convergência de migration history + unificação do tooling.
3. `d4c6583` — Supabase por flavor no Flutter.
4. `8780ccb` — rename `goias_*` → `club_*` no Flutter.
5. `0bc893f` — docs 48-54.

Preservados intactos, fora de qualquer commit: `lib/features/store/
presentation/widgets/store_entry_card.dart`, `docs/multiclub/39_...`,
`tooling/multiclub/audit_post_rollout_retirement_gate.mjs`, `tooling/
multiclub/test_post_rollout_retirement_gate.mjs`, `_competitions_pkg/`,
`migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md`.

## 12) git status final

```
 M docs/multiclub/39_post_rollout_legacy_retirement_gate.md
 M lib/features/store/presentation/widgets/store_entry_card.dart
 M tooling/multiclub/audit_post_rollout_retirement_gate.mjs
 M tooling/multiclub/test_post_rollout_retirement_gate.mjs
?? _competitions_pkg/
?? docs/multiclub/19_etapa_e_v4_applied_report.md
?? migration_dump.txt
```

Só trabalho alheio, não tocado. `git log --oneline -5` mostra os 5 commits
acima, em ordem.

## 13) Blocker Bragantino publishable key

```
BRAGANTINO_SUPABASE_PUBLISHABLE_KEY_REQUIRED=true
```

Segue exatamente como no relatório anterior — nunca inventada. É
configuração de Flutter/cliente, não de schema, e não bloqueou nada deste
cutover.

PARE antes de git push.

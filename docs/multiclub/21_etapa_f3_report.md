# 21 — Etapa F3: migrar `guess_players` (Quem Vestiu o Manto) para `person_id`

> Migração PARALELA de identidade — nada removido, nada aplicado no Supabase, nada commitado. **PARE — aguardando revisão.**

## 1. Runtime real de `guess_players`

- **Fonte da verdade em runtime**: tabela real `public.guess_players` no Supabase, lida por `GuessPlayerRepository.load()` ([guess_player_repository.dart](goias-app/lib/features/arena/games/guess_player/data/guess_player_repository.dart)) via `.from('guess_players').select(...).eq('is_active', true).order('sort_order')`.
- **Fallback**: `final guessPlayerCatalog` em [guess_player_catalog.dart](goias-app/lib/features/arena/games/guess_player/data/guess_player_catalog.dart) (2071 linhas, 173 entradas) — usado quando a query falha OU devolve 0 linhas.
- **Feature/tela**: "Quem Vestiu o Manto?", dentro da Arena — `guess_player_page.dart` + `guess_player_cubit.dart` + `guess_autocomplete_field.dart`.
- **Tooling de geração**: `supabase/guess_players.sql` — **igual ao padrão do `career_players.sql` pré-F1**: script histórico "rode no SQL Editor", **não está em `supabase/migrations/`**, nunca fez parte das 29 migrations aplicadas. Diferente de `career_players`, não existe uma "revalidação v2" — este arquivo continua sendo o único registro histórico do seed atual. O export canônico `data_export/goias/guess_players.json` (173 linhas) já reflete o estado real.
- **Progresso/ranking**: `guess_player_storage.dart` (progresso, chaveado por `guess_players.id`) + `ranking.recordScore(itemId: secret.id, ...)` — mesma separação chave-de-jogo/identidade-de-pessoa da F1, confirmada no código (`won = guess.id == secret.id`, nunca por nome).

## 2. Quantidade e estrutura

| | Valor |
|---|---|
| Linhas no Supabase (ao vivo) | **173** |
| Linhas no fallback Dart | **173** |
| IDs batem 1:1? | **Sim** (mesmos 173 ids, confirmado via `data_export/goias/guess_players.json`, que é o espelho do banco) |

Colunas reais (`information_schema.columns`, confirmado ao vivo): `id text PK`, `name text not null`, `display_name text not null`, `aliases jsonb`, `position text`, `shirt_number int`, `academy_club text`, `nationality_code text`, `nationality_name text`, `goias_debut_year int`, `photo_key text`, `data_status text` (`verified`/`review`/`incomplete`), `is_active boolean`, `sort_order int`, `created_at`. Usados pela UI/gameplay: `position`, `shirt_number`, `academy_club`, `goias_debut_year` (as 4 pistas comparadas — POS/CAMISA/BASE/ESTREIA), `display_name`/`aliases` (autocomplete/resposta), `photo_key` (resolvido pra asset local, só o elenco atual tem foto). `nationality_code`/`nationality_name` existem mas **não são mais usados** na comparação/pistas (comentário do próprio `GuessPlayer.nationalityCode` confirma isso). `academy_history` existe no model Dart mas não tem coluna equivalente no banco (sempre `const []` vindo do repository).

## 3-7. RESOLVED / AMBIGUOUS / UNRESOLVED / OUT_OF_SCOPE

Reconciliação **já existia** — os 173 `guess_players` já são `member`s de `canonical_people_candidates.json` (`source='guess_players'`), a mesma fundação usada pela F1 (e visível também em `person_aliases` já aplicada, que tem entradas `source='guess_players'` pros homônimos Danilo/Nicolas — `20260901030000_seed_goias_person_aliases.sql:207-217`). Não construí reconciliação nova — só classifiquei os 173 contra `people_insert_plan.json` (o `player_reconciliation_overrides.json`/`people_registry.json` já estão incorporados no `canonical_people_candidates.json` final, não precisei consultá-los separadamente).

| Status | Contagem |
|---|---|
| **RESOLVED** | **92** |
| **AMBIGUOUS** | **0** |
| **UNRESOLVED** | **81** |
| **OUT_OF_SCOPE** | 0 (nenhuma linha `is_active=false` hoje) |

Os 81 UNRESOLVED: 0 têm zero candidato (todos os 173 já tinham exatamente 1 pessoa candidata via reconciliação); os 81 têm 1 candidato cuja identidade cross-source nunca chegou a `APPROVED` — mesmo padrão da F1 (achado sobre o projeto inteiro, não sobre `guess_players`).

## 8. Mapping completo

`data_export/goias/player_reconciliation/guess_players_person_mapping.json` (173 entradas, formato exato pedido) + `guess_players_person_mapping_stats.json`. Gerado por `tooling/multiclub/build_guess_players_person_mapping.mjs`, reprodutível byte-a-byte (verificado).

## 9. Casos sensíveis / homônimos

| `guess_players.id` | Nome atual | `person_id` esperado | `canonicalName` | Status | Motivo |
|---|---|---|---|---|---|
| `michael` | Michael | `13c239d9-...` | **Michael Richard Delgado de Oliveira** | RESOLVED | EXACT_IDENTITY, APPROVED — nunca o histórico de 1999 |
| `danilo_cunha_da_silva` | Danilo | `34d6fed1-...` | **Danilo Cunha da Silva** | RESOLVED | EXACT_IDENTITY, APPROVED |
| `danilo_portugal` | Danilo Portugal | — | Danilo Portugal | **UNRESOLVED** | Achado NOVO desta etapa: uma **3ª** pessoa "Danilo", distinta de Gabriel e Cunha, nunca antes investigada — `AMBIGUOUS_IDENTITY`/`BLOCKED_AMBIGUOUS`. Nunca herda `person_id` de nenhum dos outros 2. |
| `nicolas_vichiatto_da_silva` | Nicolas | `a597dae2-...` | **Nicolas Vichiatto da Silva** | RESOLVED | EXACT_IDENTITY, APPROVED. **Nicolas Godinho não existe em `guess_players`** — confirmado por ausência. |
| `fabiano` | Fabiano | `063cc04f-...` | **Fabiano Cézar Viegas** | RESOLVED | EXACT_IDENTITY, APPROVED (o "zagueiro" investigado na v3 da reconciliação) — sem nenhum "Fabiano Monroe" concorrente em `guess_players` |
| `walter` | Walter | `828c3bc8-...` | **Walter Henrique da Silva** | RESOLVED | EXACT_IDENTITY, APPROVED |
| `tadeu_antonio_ferreira` | Tadeu | `e2507d62-...` | **Tadeu Antônio Ferreira** | RESOLVED | EXACT_IDENTITY, APPROVED |
| `marcelo_rangel` | Marcelo Rangel | — | Marcelo Rangel | **UNRESOLVED** | Mesma ambiguidade cross-source da F1 (`AMBIGUOUS_IDENTITY`/`BLOCKED_AMBIGUOUS`) |
| `apodi` | Apodi | — | Apodi | **UNRESOLVED** | Idem |
| `harlei` | Harlei | `66e38ffb-...` | **Harlei** | RESOLVED | EXACT_IDENTITY, APPROVED |
| `dill` | — | — | — | **N/A** | `dill` **não existe** em `guess_players` — confirmado por ausência, não suposto |

Nenhum nome curto ambíguo foi "escolhido" — os 81 UNRESOLVED (incluindo os 3 novos casos acima) ficam genuinamente `NULL`.

## 10. Cardinalidade pessoa ↔ guess_player — auditada, não suposta

Verificado nos **2 sentidos**, não só contado:
1. **Direto**: das 92 linhas RESOLVED, `personIdReusedAcrossRows` (guess_players_person_mapping_stats.json) = **`[]`** — nenhum `person_id` aparece em 2+ linhas.
2. **Reverso**: varri `canonical_people_candidates.json` procurando qualquer pessoa canônica com 2+ `members` de `source='guess_players'` — **0 casos**.
3. **Evidência estrutural independente**: as 173 linhas têm **173 `display_name` distintos** (0 duplicata) — o próprio dataset não modela "edições"/"eras" do mesmo jogador como linhas separadas (diferente do que se cogitou auditar).

**Conclusão**: cardinalidade real hoje é 1 `guess_player` = 1 pessoa, nos 2 sentidos, sem exceção.

## 11. Decisão sobre `UNIQUE(person_id)`

**Adicionada**, com a mesma disciplina da F1, mas com a auditoria específica do item 10 acima documentada na própria migration (não só assumida por analogia com career_players). Se a cardinalidade tivesse mostrado reuso, o gerador (`generate_guess_players_person_migration.mjs`) **aborta e não gera a migration** — checagem automática (`stats.personIdReusedAcrossRows.length > 0` → erro), não só uma decisão manual.

## 12. Campos duplicados vs. tabelas canônicas

| `guess_players` atual | equivalente canônico | migrar agora? |
|---|---|---|
| identidade (`id`+`name`+`display_name`+`aliases`) | `people` | **SIM** — é exatamente esta etapa |
| `position` | `player_positions` | NÃO — F2/futura |
| `shirt_number` | (nenhuma tabela agrega "número mais representativo"; `player_match_appearances.shirt_number` é snapshot por partida, semântica diferente) | NÃO |
| `academy_club`/`goias_debut_year` | (nenhuma tabela canônica — dado de formação/estreia específico desta feature) | NÃO |
| `photo_key` | (asset Flutter local via `squadPhotoAssets`, nunca um conceito de banco) | NÃO aplicável |
| `data_status` (verified/review/incomplete) | (curadoria própria do JOGO — confiança nos 4 atributos usados como pista) | NÃO — editorial da feature |

## 13. Mudanças Flutter (feitas)

- `GuessPlayer` ganhou `final String? personId` ([guess_player.dart](goias-app/lib/features/arena/games/guess_player/domain/guess_player.dart)) — nullable, zero mudança visual (a classe não usa `Equatable`, nada de `props` pra atualizar).
- `GuessPlayerRepository._map()` agora lê `row['person_id']` e passa pro model — `select()` inclui `person_id`.
- Fallback `guess_player_catalog.dart`: as 173 entradas ganharam `personId: '<uuid>'` (92) ou `personId: null` (81), gerado programaticamente, verificado 1:1.
- **Nenhuma UI, ordem, imagem, resposta aceita, pontuação, navegação, dificuldade ou gameplay foi alterada.** `guess_players.id` continua a chave do jogo (progresso/ranking) — não substituída por `person_id` em lugar nenhum.
- Mesma dependência de ordem de deploy da F1: o `.select('...person_id')` só funciona depois da migration aplicada; até lá, cai no fallback local (mesmo comportamento de "sem rede").

## 14. Comparações textuais perigosas — classificadas

Revisei toda comparação de nome/slug/aliases dentro do fluxo de `guess_players`:

| Local | Classificação | Nota |
|---|---|---|
| `GuessPlayerCubit`: `player.id == id`, `won = guess.id == secret.id`, `ranking(itemId: secret.id)` | — (usa `id`, não nome) | Seguro, mesma separação chave-de-jogo/identidade da F1 |
| `guess_comparison.dart` (`comparePosition`/`compareShirtNumber`/`compareAcademy`/`compareDebutYear`) | **GAMEPLAY** | Compara VALORES de atributo (posição/camisa/base/estreia) pra gerar as pistas — nunca decide "é a mesma pessoa" |
| `GuessAutocompleteField._resolveMap`/`_suggestions` (`normalizeName(displayName/name/alias)`) | **GAMEPLAY** | Resolve o texto digitado pro `GuessPlayer` certo dentro do PRÓPRIO catálogo — não decide identidade entre registros, só faz o de-para texto→objeto pro campo de chute |

**Nenhuma `IDENTITY_LOGIC` perigosa encontrada** dentro do fluxo de `guess_players` — ao contrário da F1 (que achou o merge `career_players`+`goias_players.dart`), aqui não há nenhuma comparação decidindo "estes 2 registros são a mesma pessoa real" usando texto.

## 15. Autocomplete

**Auditado — `guess_players` NÃO participa de nenhum autocomplete fundido com outro dataset.** `GuessAutocompleteField` (usada só por esta feature) constrói `_resolveMap`/`_suggestions` **exclusivamente** a partir de `widget.catalog`, que por sua vez vem só de `GuessPlayerCubit.catalog` (`guessPlayerCatalog`/repository) — confirmado lendo `guess_player_page.dart:205-210`. Diferente do achado da F1 (`career_path_page.dart` fundia com `goias_players.dart`), aqui o autocomplete é **self-contained**. Nada a reportar como risco, nada a corrigir.

## 16. Migration proposta

Duas migrations aditivas, **NÃO aplicadas**:

**`20260902160000_add_person_id_to_guess_players.sql`**
```sql
alter table public.guess_players
  add column if not exists person_id uuid references public.people(id);

alter table public.guess_players
  add constraint guess_players_person_id_key unique (person_id);
```
`person_id` nullable (81 de 173 ainda não resolvidas). Sem índice adicional (mesmo endurecimento da F1 — `UNIQUE` já cria o seu).

**`20260902170000_backfill_guess_players_person_id.sql`** — mesmo padrão endurecido da F1: `DO $$ ... END $$` com pré-condição (173 linhas totais; os 92 ids esperados existem antes) e pós-condição (cada uma das 92 termina com o UUID EXATO esperado; NOT NULL=92/NULL=81/DISTINCT=92) — `RAISE EXCEPTION` em qualquer divergência, nunca um backfill parcialmente "verde". Nunca `ilike`/`display_name`/`aliases` pra resolver.

## 17. RLS/grants

Auditado, **igual ao padrão pré-F1 de `career_players`** (mesma dívida pré-existente):
```
relrowsecurity: true
pg_policies: "read guess players" (SELECT) — a única
role_table_grants (anon/authenticated): INSERT/SELECT/UPDATE/DELETE/
  TRUNCATE/REFERENCES/TRIGGER — grant amplo pré-existente
```
As 2 migrations F3 propostas **não tocam GRANT/POLICY nenhum** — reportando como dívida preexistente, não corrigindo misturado nesta etapa (conforme pedido).

## 18. Testes JS

`tooling/multiclub/test_guess_players_person_mapping.mjs` — **25 testes, 0 falhando**: números gerais, cardinalidade (auditada nos 2 sentidos + evidência estrutural), os 11 casos sensíveis do pedido (incluindo o achado novo `danilo_portugal` e a confirmação de ausência de `dill`/Nicolas Godinho), UNRESOLVED sempre com motivo, SQL sem `ilike`/`display_name`/`aliases`, `DO` block com pré/pós-condição, schema sem índice redundante, nenhuma tabela canônica tocada.

**Suíte completa `tooling/multiclub/test_*.mjs`: 323 passando, 0 falhando** (298 da F1 + 25 novos).

## 19. `flutter analyze`

```
Analyzing goias-app...
No issues found! (ran in 11.2s)
```

## 20. `flutter test`

```
00:21 +729 ~1: All tests passed!
```
729 passando, 1 skip — idêntico ao estado pré-F3, nenhuma regressão.

## 21. `git diff --stat`

```
 lib/.../guess_player/data/guess_player_catalog.dart     | 173 ++
 lib/.../guess_player/data/guess_player_repository.dart  |   3 +-
 lib/.../guess_player/domain/guess_player.dart            |   8 +
 lib/.../store_entry_card.dart                            |   2 +-  (pré-existente, fora de escopo)
 4 files changed, 184 insertions(+), 2 deletions(-)
```

## 22. `git status`

```
 M lib/features/arena/games/guess_player/data/guess_player_catalog.dart
 M lib/features/arena/games/guess_player/data/guess_player_repository.dart
 M lib/features/arena/games/guess_player/domain/guess_player.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente)
?? _competitions_pkg/                                              (pré-existente)
?? data_export/goias/player_reconciliation/guess_players_person_mapping.json
?? data_export/goias/player_reconciliation/guess_players_person_mapping_stats.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (Etapa E, decisão separada pendente)
?? migration_dump.txt                                              (padrão de exclusão)
?? supabase/migrations/20260902160000_add_person_id_to_guess_players.sql
?? supabase/migrations/20260902170000_backfill_guess_players_person_id.sql
?? tooling/multiclub/build_guess_players_person_mapping.mjs
?? tooling/multiclub/generate_guess_players_person_migration.mjs
?? tooling/multiclub/test_guess_players_person_mapping.mjs
```
Nada staged, nada commitado, nada aplicado no Supabase.

---

**PARE.** F2, F4, `lineup_matches`, live sync e flavors — nenhum tocado, conforme instruído.

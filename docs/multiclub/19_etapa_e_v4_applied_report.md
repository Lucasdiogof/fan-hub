# 19 — Etapa E v4: gate final, commit e aplicação no Supabase

> Etapa E **APLICADA**. Commit criado, 4 migrations rodadas contra o banco linkado, todas as validações abaixo executadas por consulta real (não suposição). Nenhum Git push. Nenhum Flutter/flavors/live sync tocado.

## 1. Hash do commit

```
8601bb3 feat(multiclub): add canonical match appearances
```
26 arquivos, 11744 inserções, 35 deleções — só arquivos da Etapa E (ver seção 19).

## 2. Resultado do teste `INSUFFICIENT_MATCH_IDENTITY`

Gate implementado em `tooling/multiclub/match_registry.mjs` (`resolveMatchCandidate`): 1 candidato estrutural sozinho só vira `EXISTING_MATCH` quando os 2 lados (candidate novo E entrada existente) têm precisão `DATE`/`DATETIME`. Quando um dos lados é `YEAR`/`MONTH`, o resultado é `insufficient` → `BLOCKED_INSUFFICIENT_MATCH_IDENTITY` (nem `EXISTING_MATCH`, nem `NEW_MATCH`).

5 testes novos (`test_player_match_appearances.mjs`, seção 15d), todos passando:
- **coarse unique candidate**: Goiás x Juventude/Brasileirão/2024/YEAR já registrado; fonte independente idêntica em precisão YEAR, zero anchors → `BLOCKED_INSUFFICIENT_MATCH_IDENTITY`. `registry.entries.length` continua 1 (nunca criou 2º match).
- **exact independent candidate**: mesmo cenário com `DATE`/`DATETIME` nos 2 lados → `EXISTING_MATCH`, mesmo `matchId`.
- **coarse + explicit anchor**: mesmo match `YEAR`, mas `source_namespace`/`source_ref` já conhecido → `EXISTING_MATCH` pela ETAPA 1 (anchor exato é soberano, nunca chega na etapa 2/gate de precisão).
- **ambiguous**: 2 candidatos compatíveis (mesmo com `DATE` forte) → `BLOCKED_AMBIGUOUS_MATCH` — contagem de candidatos decide ANTES do gate de precisão.
- **31 matches reais inalterados**: `byResultKind.NEW_MATCH === 31`, `blockedInsufficientMatchIdentity.length === 0` — confirmado que nenhum dos 3 pares ida/volta do dataset real (Independiente/2010, Vasco/2013, Atlético-GO/2026) colide estruturalmente (mando de campo sempre invertido entre as pernas, comparação de lado é estrita).

## 3. Migration list PRÉ-push

```
23 migrations locais = remotas (20260830220000 .. 20260902090000)
4 migrations locais SEM remote (pendentes):
  20260902100000
  20260902110000
  20260902120000
  20260902130000
```

## 4. Dry-run

```
Would push these migrations:
 • 20260902100000_create_matches.sql
 • 20260902110000_seed_goias_matches.sql
 • 20260902120000_create_player_match_appearances.sql
 • 20260902130000_seed_goias_player_match_appearances.sql
```
Exatamente as 4 esperadas, nada mais.

## 5. `db push`

```
Applying migration 20260902100000_create_matches.sql...
Applying migration 20260902110000_seed_goias_matches.sql...
Applying migration 20260902120000_create_player_match_appearances.sql...
Applying migration 20260902130000_seed_goias_player_match_appearances.sql...
{"upToDate":false,"dryRun":false,...,"message":"Finished supabase db push."}
```
Nenhum erro. `--include-seed`/`migration repair`/`db pull`/`db reset --linked` — nenhum usado.

## 6. Migration list PÓS-push

**27 migrations, todas `local === remote`.**

## 7. Matches / source refs (consulta real)

| Métrica | Esperado | Confirmado no banco |
|---|---|---|
| `matches` | 31 | **31** |
| `match_source_refs` | 46 | **46** |
| `goias_lineup_curated` | 31 | **31** |
| `goias_passport` | 15 | **15** |
| `(source_namespace, source_ref)` duplicado | 0 | **0** |
| source_ref apontando pra 2 matches | 0 | **0** |

## 8. Precisões temporais (consulta real)

| Precisão | Esperado | Confirmado |
|---|---|---|
| YEAR | 10 | **10** |
| MONTH | 0 | **0** |
| DATE | 6 | **6** |
| DATETIME | 15 | **15** |

Violações de nullability por precisão: `year_violations=0`, `month_violations=0`, `date_violations=0`, `datetime_violations=0`. **`year_rows_with_any_date_value = 0`** — confirmação explícita de 0 datas-sentinela fabricadas em rows YEAR.

## 9. Sentinel audit

Coberto na seção 8 acima (`year_rows_with_any_date_value = 0`) — nenhuma linha `YEAR` tem `kickoff_date` preenchido no banco.

## 10. Registry / UUID

```
db_ids_count: 31
registry_active_entries: 31
registry_distinct_uuids: 31
db_ids === registry_ids (conjunto exato): true
```
`information_schema.columns` confirma `matches.id` sem `column_default` (nenhum `gen_random_uuid()`).

## 11. Appearances / sources

```
appearances_count: 162
sources_count: 162
```

## 12. Statuses

```
status_STARTED: 162
SUBSTITUTE_USED: 0 (nenhuma linha — implícito)
UNUSED_SUBSTITUTE: 0 (nenhuma linha — implícito)
```
Correto pro seed histórico disponível — nenhum banco de reservas inventado.

## 13. Spell linkage

```
distinct_people: 62
with_spell: 80
without_spell: 82
```
Os 82 continuam 100% categoria A (`spellDecomposition: {A:82, B:0, C:0, D:0}` em `player_match_appearances_seed_stats.json`, inalterado desde a v2/v3). Grace de 6 meses: confirmado estrutural E comportalmente (seção 8 do relatório v3, `18_etapa_e_v3_report.md`) que **nunca** participa de link automático — só `classifySpellGap` (diagnóstico) o usa; `resolveSpellForDate`/`overlapCandidates` (que decidem `spell_id` de fato) nunca referenciam a constante.

## 14. Homônimos (consulta real)

```
godinho_count: 2
vichiatto_count: 2
overlap_godinho_vichiatto: 0   <- Nicolas Godinho != Nicolas Vichiatto, confirmado no banco
danilo_gabriel_count: 2
danilo_cunha_count: 0          <- Danilo Cunha não vazou nenhuma appearance
michael1999_count: 0           <- Michael histórico (PROVISIONAL) não vazou pro Michael moderno
```
Nenhuma appearance foi criada por "primeiro alias encontrado" — todas vieram de `person.members` já reconciliados manualmente na Etapa A/v3.1, nunca de resolução por nome cru.

## 15. Integridade (consulta real)

```
dup_person_club_match: 0
orphan_person: 0
orphan_club: 0
orphan_match: 0
orphan_source: 0
```

**Teste ao vivo da FK composta** — INSERT combinando `spell_id` do Walter (`e206ba3e-a45f-5229-8abf-77ffde1d6ee0`) com `person_id` do Tadeu:
```
ERROR: 23503: insert or update on table "player_match_appearances" violates
foreign key constraint "player_match_appearances_spell_coherence_fkey"
DETAIL: Key (spell_id, person_id, club_id)=(e206ba3e-..., e2507d62-..., 4c16340d-...)
is not present in table "player_club_spells".
```
Rejeitado, exatamente como esperado. `select count(*) from player_match_appearances` confirmado **162** logo depois — nenhum lixo inserido.

## 16. Match constraints (consulta real)

```
both_null_club: 0
same_club_both_sides: 0
at_least_one_club_known: 31
```

## 17. RLS (consulta real)

```
relrowsecurity: matches=true, match_source_refs=true,
                 player_match_appearances=true, player_match_appearance_sources=true

pg_policies:
  matches                       -> "read matches" (SELECT)
  player_match_appearances      -> "read player match appearances" (SELECT)
  match_source_refs              -> (nenhuma linha — 0 policies)
  player_match_appearance_sources -> (nenhuma linha — 0 policies)

role_table_grants (anon/authenticated):
  matches                  -> anon:SELECT, authenticated:SELECT
  player_match_appearances -> anon:SELECT, authenticated:SELECT
  match_source_refs                -> (nenhuma linha — 0 privilégios)
  player_match_appearance_sources  -> (nenhuma linha — 0 privilégios)
```
Exatamente como pedido nos itens 16/17 da revisão anterior.

## 18. Baseline/delta do Tadeu

Consulta real (`player_club_stats`, `stats_scope='CLUB_TOTAL'`):
```
appearances: 400
as_of_date: 2026-08-28
as_of_match_id: pe_cb52680435343cc4
data_mode: SNAPSHOT
```
**Inalterado** — a Etapa E não tocou `player_club_stats` (a tabela nem aparece em nenhuma das 4 migrations aplicadas). `recompute_player_club_stats.mjs` continua puramente conceitual — não é chamado por nenhuma migration/seed/app, não escreveu no banco (confirmado: `player_club_stats` não faz parte do diff de nenhuma migration desta etapa).

Testes conceituais (seção 4-7 de `test_player_match_appearances.mjs`, parte dos 264 abaixo):
- appearance histórica anterior ao baseline → 400 (não soma).
- appearance do próprio baseline → 400 (não soma de novo).
- 1 STARTED futuro → 401.
- rerodar 10x com o mesmo dado → 401 (idempotente).
- 1 UNUSED_SUBSTITUTE futuro → 400 (não soma).

## 19. Testes totais

**264 passando, 0 falhando** (era 259 antes do gate; +5 dos testes novos da seção 15d) — rodado uma última vez DEPOIS do push, contra o dado real já aplicado:

| Suite | Passou |
|---|---|
| `test_identity_stability.mjs` | 8 |
| `test_live_data_model.mjs` | 13 |
| `test_person_aliases.mjs` | 31 |
| `test_player_club_spells.mjs` | 41 |
| `test_player_club_stats.mjs` | 45 |
| `test_player_match_appearances.mjs` | 91 |
| `test_player_positions.mjs` | 35 |
| **Total** | **264** |

## `git status` final

```
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, nunca tocado por este projeto)
?? _competitions_pkg/                                              (pré-existente, fora de escopo)
?? migration_dump.txt                                              (padrão de exclusão — nunca incluído)
```
Working tree limpa pra tudo relacionado à Etapa E. **Nenhum `git push` foi feito.**

---

**PARE.** Etapa E aplicada e validada. Não iniciei Flutter, flavors, nem sincronização viva real — fora de escopo desta etapa, conforme instruído.

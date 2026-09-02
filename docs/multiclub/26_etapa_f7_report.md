# Etapa F7 — `lineup_matches` histórico → ponte com a camada canônica (auditoria + tooling)

Data: 2026-09-02
Status: **APROVADA E COMMITADA.** 0 migrations, 0 `db push`, 0 `git push`.

---

## 1. Runtime real de `lineup_matches` ("Adivinhe a Escalação")

- **Tabela Supabase real**: `public.lineup_matches` (`supabase/lineup_matches.sql`) — `id text primary key, competition, season, phase, match_date date, venue, home_team, away_team, home_score, away_score, formation, formation_confidence check(confirmed/probable/estimated), lineup jsonb, display_order int, is_active boolean`. RLS on, SELECT público, escrita só dashboard/admin.
- **Fallback Dart**: `lib/features/arena/games/lineup/lineup_matches.dart` — const `lineupMatches`/`orderedLineupMatches` (31 entradas), gerado a partir do mesmo dataset que produz o `.sql` (`scripts/gen_lineup_matches_sql.mjs` lê o Dart e imprime o SQL — o `.sql` é output, não fonte).
- **Repository**: `LineupMatchRepository` — Supabase primeiro (`is_active=true`, `order by display_order`), cai pro Dart const em qualquer erro OU se vier 0 linhas ativas. Erros vão pro Sentry, nunca travam o usuário.
- **Achado importante não previsto**: `LineupPage` tem um 2º caminho — quando aberta por deep-link direto (sem `cubit` pré-carregado), ela monta o `LineupCubit` com `orderedLineupMatches` **direto, sem passar pelo repository nem pelo Supabase**. Deep-link nunca lê o banco.
- **Progresso**: `public.lineup_match_progress` (`user_id, match_id, game_state jsonb, status, completed_at`), PK `(user_id, match_id)` — `match_id` = `lineup_matches.id` (o slug da feature). "Última partida vista" em `public.arena_selected_content` (`game_id='lineup'`).
- **Ranking**: `public.user_game_item_progress`/`public.score_events`, `item_id = lineup_matches.id`, via RPC `arena_record_score` — que **valida contra a própria tabela `lineup_matches`** (`exists (select 1 from lineup_matches where id = p_item_id)`) antes de creditar qualquer pontuação.
- **Mecanismo de acerto**: compara só contra `puzzleAnswer`/`normalizedAnswer` (Wordle-style, 2 passadas, acentos removidos). `LineupPlayer.aliases` existe no model mas **nunca é usado pra validar** — reservado "pra busca ou estatísticas futuras" (comentário do próprio código).

## 2. Schema/shape real

`lineup jsonb` — array de exatamente 11 objetos por partida:
```json
{ "pos": "ZAG", "no": null, "name": "Jorge Batata", "answer": "JORGE BATATA", "aliases": ["J. Batata"] }
```
Não existe `sort_order` explícito — a **posição no array** é a ordem (consumida posicionalmente contra `FormationLayoutService.positionsFor(formation)`). Colunas de partida: `id, competition, season, phase, match_date, venue, home_team, away_team, home_score, away_score, formation, formation_confidence, display_order, is_active`.

## 3. Quantidade real

**31 partidas, 341 slots (31×11 exato, sem exceção — confirmado programaticamente, `Counter({11: 31})`)**. 0 reservas — o dataset é estruturalmente só titulares. `formation_confidence`: estimated 15 / probable 9 / confirmed 7.

## 4. As 3 identidades

Confirmadas e nunca confundidas nesta etapa (testado):
- `lineup_matches.id` — chave da feature (progress/ranking) — **intocada**.
- `canonicalMatchId` (`matches.id`) — resolvido só por leitura de `matches_seed.json`/`match_source_refs`, nunca recalculado aqui.
- `personId` (`people.id`) — resolvido só reusando a reconciliação já aprovada, nunca por nome cru.

## 5-6. Ponte via `match_source_refs` + coverage

Mecanismo autorizado usado exatamente como pedido: `matches_seed.json` já carrega, por linha, `lineupMatchId` + `matchId` (canônico) — resolvido pela Etapa E via anchor `source_namespace='goias_lineup_curated'`, `source_ref=lineup_matches.id`. F7 só **lê** isso.

```
totalLineupMatches: 31
matchesWithCanonical: 31
matchesWithoutCanonical: 0
matchesWith2PlusCanonical: 0
```
**31/31 — nenhum bloqueio, nenhuma partida nova criada, nenhuma reconciliação refeita.**

## 7. Pares ida/volta — reconfirmados

| par | canonicalMatchId A | canonicalMatchId B | distintos? |
|---|---|---|---|
| Independiente 2010 (final ida/volta) | `8b85a8ae-...` | `ad4be142-...` | ✅ |
| Vasco 2013 (quartas ida/volta) | `e2aab068-...` | `fea69f06-...` | ✅ |
| Atlético-GO 2026 (final ida/volta) | `21078bdc-...` | `40c6b119-...` | ✅ |

Nenhum dos 3 pares depende de placar/nome — resolvido só por `match_source_refs`.

## 8-13. Slots — classificação (341 total)

```
RESOLVED_EXISTING_APPEARANCE : 162
UNRESOLVED_PERSON            :  96
AMBIGUOUS_PERSON             :  83
RESOLVED_PERSON_NO_APPEARANCE:   0
SOURCE_MISMATCH               :   0
```
**162 bate exatamente com o total real de `player_match_appearances_seed.json`** (não assumido — confirmado). **0 gaps** (nenhuma pessoa aprovada+slot legítimo sem appearance correspondente) e **0 divergências de integridade** (nenhuma provenance apontando pra dado diferente do slot real hoje). Dos 83 `AMBIGUOUS_PERSON`, **100% vêm da própria pessoa canônica candidata ter `identity=AMBIGUOUS_IDENTITY`** (nenhum caso do padrão "0 candidatos, homônimo sem dado" — esse padrão só apareceu no `goias_players.dart` da F6, não aqui).

## 14. Provenance — granularidade real

`player_match_appearance_sources` já preserva `sourceRef = "<lineupMatchId>:<answer_lowercase>"` + `raw_value` = **o objeto do slot inteiro** (`pos`, `no`, `name`, `answer`, `aliases`). Isso já é granular o bastante pra servir de bridge — usado diretamente nesta etapa (`appearanceSourceRef` no mapping), **nenhuma correspondência por texto escondida foi inventada**.

## 15. Coverage esperada — número real

**162** (não 341, não forçado a bater com nada) — confirmado igual ao valor já existente em `player_match_appearances_seed_stats.json`, nada recalculado.

## 16. STARTED ligadas à fonte lineup

**162/162 (100%)** — 0 appearance órfã (toda linha rastreia de volta a um slot real de hoje).

## 17. Homônimos obrigatórios

| caso | resultado |
|---|---|
| Danilo 2003 (2 partidas) | → **Danilo Gabriel de Andrade**, nunca Cunha ✅ |
| "Danilo Portugal" (4 partidas, 2005-2006) | **AMBIGUOUS_PERSON**, `personId=null` — nunca fundido ✅ |
| Michael 1999 | **UNRESOLVED_PERSON** — nunca vaza pro Michael Richard Delgado de Oliveira (moderno) ✅ |
| Fabiano 2006 (3 partidas) | → **Fabiano Cézar Viegas**, nunca Monroe ✅ |
| Nicolas (4 partidas) | 2021→**Godinho**, 2026→**Vichiatto**, 2 `personId` distintos, nunca por escolha de texto ✅ |
| "Carlos Eduardo" bare (2018) | **AMBIGUOUS_PERSON** — 2 pessoas reais no elenco, nunca 1 escolhida sozinha ✅ |
| Luiz Felipe / Murilo / Murillo | **0 ocorrências** em `lineup_matches` — ausência confirmada, não presumida |

## 18. Diff de posição

```
MATCH: 152, CANONICAL_NULL: 10, SOURCE_NULL: 0, DIVERGENCE: 0
```
Os 10 `CANONICAL_NULL` são exatamente os casos já conhecidos da Etapa E (posição composta como "LD/MC" do Dieguinho, ou fragmento genérico como "DEF"/"ALA") — `position_code` canônico fica `NULL` de propósito, nunca um valor forçado. **0 divergência real** — quando existe `position_code`, ele sempre bate com o `pos` bruto do slot.

## 19. Diff de camisa

```
MATCH: 162, CANONICAL_NULL: 0, DIVERGENCE: 0
```
100% dos `shirt_number` batem — esperado, já que a Etapa E copia esse valor direto do slot.

## 20. Duplicatas

**0** — nenhuma pessoa com `personId` conhecido aparece 2x na mesma escalação.

## 21. Sanity de data/metadata

15 partidas linkadas a `passport_matches` — **100% batem** em data, placar E competição (checagem factual independente, nunca usada como identidade). `formation`/`home_team`/`away_team`/score são copiados 1:1 de `lineup_matches.json` pra `matches_seed.json` quando esse é o anchor fundador — não é uma checagem independente pra esses campos especificamente (só a data pode ser sobrescrita por um link passport, e isso já é auditado acima).

## 22. Modelo Flutter atual

`LineupMatch` (`id, competition, season, phase, date, venue, homeTeam, awayTeam, scores, teamToGuess, formation, formationConfidence, players`) + `LineupPlayer` (`id, position, x/y, shirtNumber, fullName, displayName, puzzleAnswer, answerParts, normalizedAnswer, aliases, sourceUrl`). **Nenhum campo de identidade canônica existe hoje** — e, pelas razões da seção 24, **nenhum foi adicionado nesta rodada** (auditoria não tocou Flutter, `personId`/`canonicalMatchId` não viraram campos de model ainda).

## 23. Proposta de ponte (implementada, read-only)

`tooling/multiclub/build_lineup_matches_canonical_mapping.mjs` (novo) — lê `lineup_matches.json` + `matches_seed.json` + `canonical_people_candidates.json` + `people_insert_plan.json` + `player_match_appearances_seed.json` + `player_match_appearance_sources_seed.json` + `passport_matches.json`, escreve **só** `lineup_matches_canonical_mapping.json`/`_stats.json`. Testado estaticamente (regex no próprio código-fonte) e dinamicamente (hash antes/depois) que **nunca escreve** em `people`/`matches`/`match_source_refs`/`player_match_appearances`/`*_sources`/`matches_registry.json`/`people_registry.json`/nem em nenhum arquivo da própria feature (`lineup_matches.dart`/`.json`/`.sql`).

## 24. Opção recomendada: **C**

| | A — enriquecer JSON/rows legacy | B — mapping/adapter externo persistido | **C — consumir `player_match_appearances` direto, legacy 100% editorial** |
|---|---|---|---|
| Onde mora `personId` | dentro de `lineup.jsonb`/Dart const/JSON | tabela/arquivo bridge dedicado | não mora em lugar nenhum novo — já existe em `player_match_appearances` |
| Risco de tocar conteúdo editorial | alto — mesmo blob que a UI renderiza, posição no array é significativa | zero | zero |
| Custo de manutenção futura | reescrever a feature inteira toda vez que a reconciliação avançar | manter uma 2ª tabela em sincronia | zero manutenção nova — a fonte de verdade já é mantida pela Etapa E |
| Taxa de resolução hoje | 162/341 = 47% — muito `null` dentro de um dataset editorial | idem, mas fora do editorial | idem, mas nem precisa aparecer como coluna |

**Por que C, não A** (o padrão usado em F1-F6): `career_players`/`guess_players`/`squad_members`/`goiasSquad` são listas PLANAS de pessoas (1 linha = 1 pessoa) — `personId` ali é um enriquecimento 1:1 natural e barato. `lineup_matches` é **2 níveis** (partida → array de 11 slots dentro de um `jsonb` que também dirige o layout do campo por posição no array) — misturar identidade canônica ali é estruturalmente mais arriscado e mais caro de manter. E, crucialmente, **nada no gameplay precisa de `personId`** (confirmado: acerto é só `puzzleAnswer`, aliases nem são usados) — diferente de `career_players`, onde ao menos existe uma lista fixa de 30 "personagens" do jogo. Se um dia a UI quiser mostrar "quem é esse jogador" a partir da tela de escalação, a implementação correta é uma consulta ao vivo em `player_match_appearances`/`people` (via `match_source_refs`), nunca um campo duplicado dentro do `lineup.jsonb`.

**B fica descartado** não por ser errado, mas por ser redundante: criar uma tabela-ponte persistida quando `player_match_appearances` já É essa ponte (tem `person_id` + `canonical_match_id` + provenance até o nível do slot via `sourceRef`) só duplicaria dado que já existe em outro lugar canônico.

## 25. Migrations propostas

**ZERO.** Não há necessidade de schema novo — `player_match_appearances`/`match_source_refs` já cobrem o que a Opção C precisa. `lineup_matches` continua sem `canonical_match_id`/`person_id` como coluna própria.

## 26. Tooling

`build_lineup_matches_canonical_mapping.mjs` (novo, read-only) + `test_lineup_matches_canonical_mapping.mjs` (novo, 27 testes). Outputs: `lineup_matches_canonical_mapping.json` (por partida, com `players[]` por slot — shape igual ao pedido, exceto `appearanceId` substituído por `appearanceSourceRef`: **não existe UUID de appearance conhecido no lado cliente** — `player_match_appearances.id` é `gen_random_uuid()` gerado só no INSERT real, nunca client-side, mesmo padrão de todas as etapas anteriores; `appearanceSourceRef` é o identificador estável e determinístico equivalente) + `lineup_matches_canonical_mapping_stats.json`.

## 27. Testes específicos

27 testes cobrindo: as 3 identidades nunca confundidas, coverage 31/31, os 3 pares ida/volta distintos, soma exata dos 341 slots, os 0 gaps/mismatches, **todos** os homônimos obrigatórios (Danilo/Danilo Portugal/Michael/Fabiano/Nicolas/Carlos Eduardo + confirmação de ausência de Luiz Felipe/Murilo/Murillo), diff de posição/camisa exatos, 0 duplicatas, 0 órfãs, sanity de passport, **read-only** (checagem estática de código + hash antes/depois de 8 arquivos protegidos), feature IDs preservados, reprodutibilidade byte a byte, 0 migrations.

## 28. JS total

**465 passaram, 0 falharam** (438 + 27 novos).

## 29. `flutter analyze`

**Não rodado nesta rodada** — 0 arquivo Dart tocado (confirmado via `git status`), baseline da F6 (0 issues) continua válido.

## 30. `flutter test`

**Não rodado nesta rodada** — mesma razão. Baseline da F6 (758 passed/1 skip) continua válido.

## 31. `git diff --stat`

Vazio — nenhum arquivo tracked foi modificado.

## 32. `git status`

```
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, não tocado)
?? _competitions_pkg/                                              (pré-existente)
?? data_export/goias/player_reconciliation/lineup_matches_canonical_mapping.json
?? data_export/goias/player_reconciliation/lineup_matches_canonical_mapping_stats.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (pré-existente)
?? docs/multiclub/26_etapa_f7_report.md
?? migration_dump.txt                                              (pré-existente)
?? tooling/multiclub/build_lineup_matches_canonical_mapping.mjs
?? tooling/multiclub/test_lineup_matches_canonical_mapping.mjs
```

---

## Limites respeitados

- 0 migrations, 0 `db push`, 0 commit, 0 `git push`.
- Nenhuma partida/pessoa nova criada — só leitura da fundação já aprovada.
- `matches_registry.json`/`match_source_refs` não alterados.
- Nenhuma appearance nova inserida — gaps (0 encontrados) seriam listados, não corrigidos.
- `career_players`/`guess_players`/`squad_members`/`goiasSquad`/`goias_players.dart`/`crowd_lineup` não tocados.
- F2 e live sync (E2) não reabertos.

---

## 33. Endurecimento final — coverage separada por partida (aprovado antes do commit)

Validação independente do usuário no Supabase real (`lineup_matches=31/31 active`, `match_source_refs goias_lineup_curated=31/31`, `player_match_appearances=162 STARTED`, `player_match_appearance_sources source_type=lineup_matches=162`) bateu 100% com a auditoria — mas revelou uma métrica que precisava de nome e prova próprios: **162 appearances não estão distribuídas uniformemente pelas 31 partidas** — 5 delas ficaram com zero.

**3 métricas de coverage agora explícitas e nunca misturadas** (`stats.coverage` em `lineup_matches_canonical_mapping_stats.json`):

```
MATCH IDENTITY COVERAGE
  matchesTotal: 31, matchesWithCanonicalMatchId: 31   -> 31/31

PLAYER IDENTITY COVERAGE BY MATCH
  matchesWithAtLeastOneResolvedAppearance: 26
  matchesWithZeroResolvedAppearances: 5

PLAYER IDENTITY COVERAGE BY SLOT
  totalSlots: 341, resolvedSlots: 162   -> 47,5%
```

### As 5 partidas com zero appearance canônica

| lineupMatchId | data | confronto | competição | breakdown (11 slots) | gap da Etapa E? |
|---|---|---|---|---|---|
| `1990_flamengo_cdb_final_volta` | 1990-11-07 | Goiás x Flamengo | Copa do Brasil 1990 | 4 UNRESOLVED, 7 AMBIGUOUS | **não** |
| `1996_guarani_brA_quartas` | 1996-11-27 | Goiás x Guarani | Brasileiro A 1996 | 6 UNRESOLVED, 5 AMBIGUOUS | **não** |
| `1996_gremio_brA_semi` | 1996-12-08 | Grêmio x Goiás | Brasileiro A 1996 | 6 UNRESOLVED, 5 AMBIGUOUS | **não** |
| `2003_fluminense_brA_reacao` | 2003-01-01 | Goiás x Fluminense | Brasileiro A 2003 | 7 UNRESOLVED, 4 AMBIGUOUS | **não** |
| `2018_aparecidense_goiano_final_volta` | 2018-04-08 | Goiás x Aparecidense | Goiano 2018 | 9 AMBIGUOUS, 2 UNRESOLVED | **não** |

Em todas as 5: `RESOLVED_EXISTING_APPEARANCE = 0` **e** `RESOLVED_PERSON_NO_APPEARANCE = 0` — confirmado, não é gap da Etapa E. Zero appearance existe porque **zero pessoa foi aprovada** naquela escalação (os 11 slots caem inteiramente em `UNRESOLVED_PERSON`/`AMBIGUOUS_PERSON`), nunca porque uma inserção ficou faltando. `anyGapFromEtapaE: false` no stats — testado explicitamente.

### Consequência pra Opção C (continua aprovada)

Nas **26 partidas** com pelo menos 1 slot resolvido, uma UI futura poderia enriquecer PARTE da escalação a partir de `player_match_appearances`. Nas **5 partidas zeradas**, a camada canônica hoje não consegue enriquecer nenhum jogador — mas a feature **continua funcionando normalmente**, porque `lineup_matches` é e continua sendo a fonte editorial/gameplay, nunca dependente da camada canônica. Isso é exatamente a prova de por que a Opção C (legacy 100% editorial, identidade só como enriquecimento opcional via consulta separada) é a escolha certa: se a identidade estivesse embutida no próprio `lineup_matches.lineup`, essas 5 partidas teriam 11 campos `personId: null` cada, sem nenhum ganho — e qualquer melhoria futura de reconciliação exigiria re-tocar o dataset editorial.

Nenhuma pessoa/alias/override/appearance foi criada pra melhorar os números — 96 UNRESOLVED e 83 AMBIGUOUS continuam sendo informação, não uma tarefa pra forçar conclusão.

### Testes novos

9 novos em `test_lineup_matches_canonical_mapping.mjs`: as 3 métricas de coverage com os números reais (nunca hardcoded — derivados do dataset), a lista exata das 5 partidas, confirmação de 0 gap da Etapa E em todas as 5, soma-sempre-11 por partida (nas 5 zeradas E nas 31 totais), 0 `SOURCE_MISMATCH` reconfirmado no nível granular, consistência `hasAtLeastOneResolvedAppearance`/`resolvedAppearanceCount`.

**JS total: 474 passando, 0 falhando** (465 + 9 novos). `flutter analyze`/`flutter test` não re-rodados (0 Dart tocado) — baseline F6 continua válido.

## 34. Commit

```
1b7f3d4a2c9e6081f5d3a7b8c4e2109fa6d5c3b1
docs(multiclub): map historical lineups to canonical data
```

---

**FECHADA. Commitada localmente. Nenhum `git push` feito.**

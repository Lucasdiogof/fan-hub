# Etapa F2 — auditoria de consumo canônico do Career Path

Data: 2026-09-02
Status: **APROVADA. Decisão arquitetural oficial: OPÇÃO B.** 0 migrations, 0 `db push`, 0 `git push`. Commit só de artefatos de auditoria/tooling (nenhum Dart, nenhum SQL).

---

## 1. Runtime completo do Career Path

| Camada | Arquivo | Papel |
|---|---|---|
| Tabela Supabase | `supabase/career_players.sql` (original) **superseded por** `supabase/migrations/20260831020000_career_players_revalidated_v2.sql` (adiciona `aggregate_stats`, reinsere as 30 linhas revalidadas) + `20260902140000_add_person_id_to_career_players.sql`/`20260902150000_backfill_...sql` (F1) | fonte real |
| Fallback Dart | `lib/features/arena/games/career_path/career_players.dart` (30 entradas, bate byte-a-byte com a v2 migration) | fallback local |
| Model | `career_models.dart` — `CareerPlayer`, `CareerEntry`, `CareerAggregateStat` | |
| Repository | `data/career_player_repository.dart` | Supabase → fallback local |
| Progress | `data/supabase_career_path_storage.dart` | 100% Supabase, **sem fallback local** |
| Cubit | `cubit/career_path_cubit.dart` | fluxo do jogo, guess/reveal, ranking |
| Autocomplete | `career_autocomplete.dart` (F6, intocado) | dropdown + resolveMap |
| UI | `pages/career_path_page.dart`, `widgets/career_table.dart` | tela + tabela de carreira |

**Achado importante**: `supabase/career_players.sql` (o arquivo "original") está **superseded** — a fonte real é a migration v2 de 31/08. Qualquer comparação contra "o Supabase" precisa usar a v2, não o `.sql` original (confirmado: o fallback Dart bate exatamente com a v2, não com o original).

**Fallback**: cai pro Dart tanto em erro (`catch` + Sentry) **quanto em resultado vazio-mas-bem-sucedido** (`parsed.isEmpty ? careerPlayers : parsed`) — esse 2º caso NÃO é reportado ao Sentry, é silencioso. Sem bypass de deep-link (diferente do que a F7 achou em `lineup_page.dart`) — `career_path_page.dart` sempre usa o const local quando constrói um Cubit novo, e usa Supabase só via `CareerPlayerRepository` quando pré-carregado por `arena_page.dart`.

## 2. Dataset reconfirmado

**30 rows, 21 com `person_id` RESOLVED, 9 NULL** — confirmado, número idêntico ao já conhecido da F1. Os 9: `grafite, bruno_henrique, pedro_raul, jadilson, souza, roni, vitor, marcelo_rangel, apodi` — **nenhum resolvido nesta F2**, todos continuam `BLOCKED_NO_PERSON_ID`.

## 3-4. Classificação campo por campo

| campo | classificação | justificativa |
|---|---|---|
| `id` | **GAMEPLAY_ONLY** | chave de progresso/ranking, nunca deveria virar `personId` |
| `person_id` | **CANONICAL_EQUIVALENT** | é literalmente `people.id`, 1:1 com a fundação |
| `answer`/`accepted_answers` | **GAMEPLAY_ONLY** | mecanismo de acerto, nunca substituído por nome canônico |
| `position` | **PARTIAL_CANONICAL_EQUIVALENT** | maioria bate (19/21 MATCH_PRIMARY), mas é um rótulo editorial mais rico que às vezes diverge deliberadamente do canônico (Fernandão/Iarley) |
| `club_career` (clubes fora do Goiás) | **NO_CANONICAL_EQUIVALENT** | a fundação é Goiás-centric, não existe nada equivalente |
| `club_career` (entradas Goiás) | **PARTIAL_CANONICAL_EQUIVALENT** | maioria bate com `player_club_spells`, 1 caso onde o canônico é MAIS completo (Walter) |
| `aggregate_stats`/apps-gols Goiás | **PARTIAL_CANONICAL_EQUIVALENT** | maioria bate com `player_club_stats` CLUB_TOTAL, com 1 divergência real (Tadeu, gols) |
| `photo`/`imageAsset` | **EDITORIAL_ONLY** (achado extra, não pedido) | campo existe no model, nunca populado em nenhuma das 30 entradas, nunca selecionado do Supabase, nunca lido na UI — morto, não relacionado à fundação canônica |
| `sort_order`/`is_active` | **GAMEPLAY_ONLY** | controla ordem/visibilidade do catálogo do jogo, sem equivalente canônico nem necessidade de um |

## 5. Auditoria dos 21 RESOLVED

Completa em [career_players_canonical_consumption_audit.json](../../data_export/goias/player_reconciliation/career_players_canonical_consumption_audit.json) — 1 objeto por jogador com `positionComparison`, `goiasSpellComparison`, `editorialTotal` vs `canonicalTotal`, `appearancesComparison`, `goalsComparison`, `safeCanonicalConsumers`. Nunca comparei clube fora do Goiás contra `player_club_spells` (não existe lá).

## 6. Posição — comparação real

```
MATCH_PRIMARY: 19/21
BROADER_EDITORIAL_LABEL: 2/21 (Fernandão, Iarley)
```
Fernandão e Iarley: canônico é **`[ATA]` só** (override humano da Etapa C), editorial continua "Atacante / meia-atacante"/"Meia / atacante" — **F2 não expandiu a posição canônica de volta**, só reportou a diferença como esperado.

## 7-8. Passagens pelo Goiás

```
MATCH: 20/21
LEGACY_MISSING_SPELL: 1/21 (Walter) — categoria NOVA, não estava na taxonomia original
```
8 pessoas têm 2+ spells canônicos no Goiás (Fernandão, Evair, Welliton, Rafael Moura, Araújo, Iarley, Paulo Baier, Walter) — **7 batem exatamente** (mesma contagem, mesmos anos, nunca recombinados num intervalo contínuo). **Walter é o único caso especial**: canônico tem **3** spells (2012-2013, 2016-2017, **2019**), mas o `club_career` editorial só lista **2** entradas Goiás — a passagem de 2019 (0 jogos documentados) simplesmente não existe como linha na carreira editorial. Precisei estender a taxonomia pedida (`MATCH/LEGACY_COMBINED_MULTIPLE_SPELLS/LEGACY_MORE_PRECISE/CANONICAL_MORE_PRECISE/DIVERGENCE/MISSING_CANONICAL`) com uma 6ª categoria — `LEGACY_MISSING_SPELL` — porque nenhuma das 6 originais descreve "o canônico tem uma passagem que o editorial não lista". Documentado no próprio script, nunca escondido.

## 9-10. Stats pelo Goiás

```
appearances: MATCH 20/21, NOT_COMPARABLE 1/21 (Dill)
goals:       MATCH 19/21, CANONICAL_NULL 1/21 (Tadeu), NOT_COMPARABLE 1/21 (Dill)
```
Sempre comparado **só** a entrada Goiás (nunca soma da carreira inteira — testado explicitamente com Danilo, cujo total de carreira somaria 750+ contra os 116 corretos do Goiás). `NULL` nunca virou `0` em lugar nenhum (Dill: null nos dois lados, `NOT_COMPARABLE` honesto, não forçado a `MATCH`).

## 11. O que a UI realmente usa

- **Durante o jogo (antes do acerto)**: `CareerTable` mostra **TODA** a `club_career` (todos os clubes, todas as passagens, sem ocultar nada) + `nationalTeams` + `aggregateStats`, sempre visível desde o primeiro render — **não há progressive disclosure**. `position`/`answer`/`id`/`personId` **nunca** aparecem nesse momento.
- **Depois do acerto/revelação**: `_ResolvedBlock`/`_PlayerReveal` mostram `answer` + `position` (se não-nulo). `CareerTable` continua igual, sem mudança.
- **`imageAsset`/`id`/`personId`**: nunca renderizados em lugar nenhum da feature.

## 12-13. Gameplay e fallback preservados

Confirmado por leitura de `career_path_cubit.dart`: `isCorrect()` compara só `acceptedAnswers` via `normalizeName`; `guess()`/`reveal()` usam `player.id` como `itemId` de ranking/progresso. `person_id` não é lido em nenhum desses métodos. Política de fallback documentada (seção 1), não alterada — F2 é só auditoria.

## 14. Resposta por categoria

| categoria | pode consumir canonical? |
|---|---|
| **IDENTIDADE** | **SIM** — já é isso (`person_id`), 100% seguro, já em produção desde a F1 |
| **POSIÇÃO** | **SIM, só como enrichment/cross-check** — nunca como substituição direta: 2/21 casos (Fernandão/Iarley) mostrariam MENOS informação se a UI trocasse o texto editorial pelo código canônico único |
| **PASSAGENS NO GOIÁS** | **SIM, só como enrichment/sanity** — nunca substituição: o caso Walter prova que trocar cegamente mudaria o CONTEÚDO visível do jogo (uma linha nova apareceria) |
| **CARREIRA EM OUTROS CLUBES** | **NÃO** — confirmado, 0 equivalente canônico hoje, fora de escopo criar um (ver item 17) |
| **STATS GOIÁS** | **SIM como sanity check, NÃO como fonte ao vivo** — ver seção 15/16, é exatamente onde a diferença snapshot-vs-live importa mais |

## 15. Snapshot editorial vs domínio ao vivo

Classificação:
- `career_players` (inteiro) = **EDITORIAL_SNAPSHOT** — um jogo histórico de adivinhação, cujo conteúdo (inclusive os números) faz parte do PUZZLE em si. Mudar silenciosamente muda o desafio.
- `player_club_stats.CLUB_TOTAL` = hoje **EDITORIAL_SNAPSHOT também** (`data_mode` não implementado, tudo é `SNAPSHOT` por enquanto — ver Etapa D), mas **projetado desde a origem pra virar `LIVE_DOMAIN_DATA`** no futuro (o próprio Tadeu já carrega `as_of_date`/`as_of_match_id`, exatamente pra suportar esse futuro).

**Prova concreta do risco**: Tadeu hoje bate 400=400 nos dois lados. Se amanhã o Tadeu jogar de novo e o canônico virar 401 (via o algoritmo baseline+delta já projetado nas Etapas E), **o Career Path NÃO deve mudar sozinho** — é um jogo com resposta fixa, não um placar ao vivo. Isso não foi implementado nem testado nesta rodada (F2 é auditoria), mas fica registrado como a razão arquitetural central da recomendação abaixo.

## 16. Decisão arquitetural oficial: **OPÇÃO B**

> **`career_players` = conteúdo editorial estável do Career Path.**
> **`person_id` = ponte canônica de identidade.**
> **`people`/`player_positions`/`player_club_spells`/`player_club_stats` = validação, auditoria e possível uso futuro fora do puzzle.**
> **O conteúdo editorial do jogo NUNCA é substituído pelos dados canônicos em runtime.**

Nenhuma das divergências encontradas (Fernandão/Iarley, Walter, Tadeu) é um "bug a corrigir" nesta etapa — são exatamente a prova de que substituição direta não é semanticamente neutra.

**Exemplo obrigatório, registrado como referência permanente desta decisão:**
```
Tadeu editorial   = 400
Tadeu canonical   = 400 (hoje)

Tadeu canonical amanhã pode virar 401 (baseline+delta, Etapa E)
Tadeu editorial permanece 400

até que uma atualização EDITORIAL DELIBERADA do conteúdo do jogo decida mudar isso.
```

**A fundação canônica continua útil — só não como fonte automática do conteúdo exibido**. Usos legítimos continuam abertos: identidade, navegação cross-feature futura, auditoria, detecção de inconsistência, ferramentas editoriais, validação antes de publicar novos puzzles.



| | A — substituir runtime por canonical | **B — legacy fica editorial, canonical só identidade/validação** | C — híbrido (alguns enrichments ao vivo) |
|---|---|---|---|
| Risco de drift silencioso | alto — qualquer atualização futura de `player_club_stats` mudaria o puzzle sem aviso | zero | médio — mesmo um "enrichment" pontual (ex.: posição) herdaria o mesmo risco se `player_positions` for editado depois |
| Perda de conteúdo | real — Fernandão/Iarley perderiam o rótulo editorial mais rico; Walter ganharia uma linha que a curadoria original não incluiu | nenhuma | depende de qual campo vira "enrichment" |
| Estabilidade do puzzle | comprometida | preservada | parcialmente comprometida |

**B, não C** (diferente da recomendação da F7): em `lineup_matches`, um enrichment futuro (mostrar "quem é esse jogador") é uma funcionalidade SEPARADA do puzzle em si — o puzzle continua sendo "adivinhar o nome" independente disso. Em `career_players`, **o conteúdo numérico É o puzzle** (a tabela de clubes/jogos/gols é literalmente o que o jogador vê e usa pra deduzir a resposta) — qualquer enrichment ao vivo desses campos específicos arrisca o mesmo problema do item 15, só que na tela principal do jogo em vez de uma tela secundária. `person_id` continua a única ponte viva com a fundação — hoje sem nenhum consumidor real (nem UI nem gameplay o usa), reservado pra uso futuro (ex.: link cross-feature "ver perfil"), exatamente como já é hoje.

## 17. Nenhum modelo genérico de carreira criado

Confirmado — nada como `global_player_career` foi proposto nem implementado. A conclusão "a fundação canônica ainda não representa a carreira inteira fora do Goiás" é aceita como está, não é um problema a resolver aqui.

## 18. Tooling

`audit_career_players_canonical_consumption.mjs` (novo, read-only) + `test_career_players_canonical_consumption.mjs` (novo, 20 testes). Outputs: `career_players_canonical_consumption_audit.json` (shape conforme pedido, com `safeCanonicalConsumers` listando só o que foi PROVADO seguro por comparação real, nunca uma recomendação de substituição) + `_stats.json`.

## 19. Os 9 unresolved

`BLOCKED_NO_PERSON_ID` em todos — testado explicitamente que nenhum tem `personId` preenchido, nenhum foi tocado.

## 20-21. Múltiplas passagens / Walter

Ver seções 7-8/12 acima — testado explicitamente que nenhum spell foi recombinado num intervalo contínuo (checagem de anos únicos por pessoa) e que Walter's CLUB_TOTAL (97) nunca é confundido com a SPELL de 2019 (0).

## 22. Tadeu

Ver seção 13/15 — `appearances` bate (400=400) mas isso é coincidência de timing, não uma garantia estrutural; `goals` diverge (13 vs `NULL`); canônico carrega `as_of_date`/`as_of_match_id` provando que é um snapshot, não um fato atemporal. Nada alterado.

## 23. Flutter

**0 mudanças.** Nenhuma foi necessária nem seria neutra o bastante pra propor sem decisão A/B/C prévia — a própria descoberta do risco de drift (item 15) é argumento pra não tocar nada agora.

## 24. Migrations propostas

**0.** Sob a Opção B, não há necessidade de espelhar nenhum dado canônico dentro de `career_players` — a coluna `person_id` (já existente desde a F1) é suficiente pra qualquer uso futuro de identidade.

## 25. JS total

**494 passaram, 0 falharam** (474 + 20 novos).

## 26. `flutter analyze`/`flutter test`

Não re-rodados — 0 arquivo Dart tocado, baseline da F6 (0 issues, 758 passed/1 skip) continua válido.

## 27. `git diff --stat`

Vazio — nenhum arquivo tracked modificado.

## 28. `git status`

```
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, não tocado)
?? _competitions_pkg/                                              (pré-existente)
?? data_export/goias/player_reconciliation/career_players_canonical_consumption_audit.json
?? data_export/goias/player_reconciliation/career_players_canonical_consumption_stats.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (pré-existente)
?? docs/multiclub/27_etapa_f2_report.md
?? migration_dump.txt                                              (pré-existente)
?? tooling/multiclub/audit_career_players_canonical_consumption.mjs
?? tooling/multiclub/test_career_players_canonical_consumption.mjs
```

---

## Limites respeitados

- 0 migrations, 0 `db push`, 0 commit, 0 `git push`.
- Nenhum dos 9 UNRESOLVED tocado/resolvido.
- `career_autocomplete.dart`/`goias_players.dart` (F6) intocados.
- `guess_players`/`squad_members`/`goiasSquad`/`lineup_matches`/`crowd_lineup` não tocados.
- Nenhum modelo genérico de carreira criado.
- ClubContext/flavors/live sync não iniciados.

---

## Fase F encerrada

Com a F2 aprovada, a série F-series (migração de identidade das features existentes pra `person_id`) está **fechada**:

```
F1  career_players → person_id            ✅
F2  career_players → auditoria de consumo canonical, decisão B ✅
F3  guess_players → person_id             ✅
F4  squad_members → person_id             ✅
F4.5 current squad canonical gaps         ✅
F5  goiasSquad → person_id                ✅
F6  goias_players/autocomplete            ✅
F7  lineup_matches canonical bridge       ✅
```

Próxima fase (não iniciada, aguardando autorização própria): **MULTICLUB CORE** — `ClubContext`/clube ativo, isolamento de configuração e fallbacks.

---

**FECHADA. Commitada localmente. Nenhum `git push` feito.**

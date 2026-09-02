# Etapa F6 — `goias_players.dart` → identidade canônica + fim do merge frágil por nome (design + tooling + Flutter mínimo)

Data: 2026-09-02
Status: **APROVADA E COMMITADA.** 0 migrations, 0 `db push`, 0 `git push`.

---

## 1. Runtime real de `goias_players.dart`

Arquivo: `lib/features/arena/games/career_path/goias_players.dart`.

```dart
class GoiasPlayer {
  const GoiasPlayer({required this.name, this.personId, this.aliases = const []});
  final String name;
  final String? personId; // adicionado nesta etapa
  final List<String> aliases;
}
const goiasPlayers = <GoiasPlayer>[...]; // 215 entradas
```

Consumidores confirmados por busca no repo inteiro (`goias_players|goiasPlayers|GoiasPlayer`): **só 2 arquivos** — `goias_players.dart` (declaração) e `career_path_page.dart` (único consumidor). Nenhum outro jogo, tela ou serviço usa este dataset.

## 2. Quantidade e semântica

**215 entradas reais** (confirma a estimativa "~215" da F1). 16 têm `aliases` (1 alias cada). **231 textos distintos** no total (nomes + aliases), **0 colisão interna** — nenhum texto se repete dentro do próprio arquivo.

**Semântica real, não presumida**: o arquivo é uma lista de nomes históricos do Goiás usada **só pra alargar o autocomplete** do "Adivinhe o Jogador". Nenhuma entrada dele é, por si só, uma resposta válida — o mecanismo de acerto (`CareerPathCubit`/`career_path_cubit.dart:131-133`) compara o texto digitado exclusivamente contra `CareerPlayer.acceptedAnswers` (os 30 jogadores jogáveis), nunca contra `goias_players.dart`. Selecionar um nome que só existe em `goiasPlayers` garante uma tentativa perdida, a menos que o texto coincida com o `acceptedAnswers` real do jogador do round atual — o que **não ocorre hoje** (0 colisões, seção 13). Função real: dar volume/realismo à lista de sugestões (o usuário não consegue inferir "a resposta está entre essas 30" só olhando o dropdown), não fornecer respostas alternativas.

## 3. Merge atual (código LIDO antes de qualquer alteração)

```dart
// ANTES:
final resolve = <String,String>{};
for (goiasPlayers) resolve[normalize(name/alias)] = name;      // 1º
for (players) resolve[normalize(acceptedAnswers)] = answer;     // 2º — SOBRESCREVE em colisão

final names = [];
final seen = {};
for (players) addName(answer);        // 1º — GANHA em colisão (seen.add falha pro 2º)
for (goiasPlayers) addName(name);     // 2º
```

**Por que depende de ordem** (exemplo concreto, reproduzido nos testes): se `goiasPlayers` tivesse uma entrada `"Danilo"` (pessoa A) e `career_players` também tivesse `"Danilo"` (pessoa B), `_resolveMap["danilo"]` acabaria em `player.answer` (pessoa B) só porque o loop de `career_players` roda **depois** e sobrescreve — se a ordem dos dois loops fosse invertida no código-fonte, o resultado mudaria silenciosamente pra pessoa A, sem nenhum sinal de erro. `_suggestions` tem a mesma fragilidade em espelho (primeiro-escreve-vence via `Set`). **Hoje os dois efeitos colaterais coincidem** (ambos favorecem `career_players`), mas isso é acidente de ordem de código, não uma regra decidida em lugar nenhum.

## 4. Separação identidade × texto aceito

Preservada explicitamente no novo modelo (seção 9): `CareerAutocompleteSuggestion.label` (texto exibido) e `.personId` (identidade, nullable) são campos distintos; `normalizeName(a) == normalizeName(b)` nunca implica mesma pessoa por si só — só quando os dois `personId` batem (ou um dos dois é `null`, aí é apenas ampliação de texto, não corroboração de identidade).

## 5. Participação na reconciliação existente

**JÁ RECONCILIADO** — não foi preciso (nem construído) nenhum reconciliador paralelo. `goias_players.dart` já é a 6ª fonte da pipeline existente (`source='goias_players_dart'`, `sourceId=String(índice 0-based)`), confirmado em `docs/multiclub/15_player_reconciliation_report.md` (rodada anterior a esta sessão). **214 dos 215 índices** têm um `member` correspondente em `canonical_people_candidates.json`; o único ausente (índice 178, "Nicolas" bare) foi **deliberadamente** deixado fora de qualquer `member` pelo motor — é o mesmo caso documentado em `player_reconciliation_overrides.json` (`nicolas_split.unassignedMembers`) e em `canonical_aliases.json` (`'nicolas'` já é `AMBIGUOUS_ALIAS` apontando pras 2 pessoas). Reusei essa reconciliação diretamente — `build_goias_players_person_mapping.mjs` só lê e classifica, nunca re-resolve identidade.

## 6-10. Classificação real (215 entradas)

| status | contagem |
|---|---|
| RESOLVED | **41** |
| AMBIGUOUS | **58** (57 pessoas com `identity=AMBIGUOUS_IDENTITY` própria + 1 caso de 0-owner deliberado: "Nicolas") |
| UNRESOLVED | **116** (97 `PROVISIONAL` + 19 `BLOCKED_INSUFFICIENT_IDENTITY`) |
| TEXT_ALIAS_ONLY | **0** — nenhuma entrada de topo é "só um apelido"; os 16 `aliases` são tratados como texto extra da MESMA entrada, nunca uma linha própria |
| OUT_OF_SCOPE | **0** |

Mapping completo: [goias_players_person_mapping.json](../../data_export/goias/player_reconciliation/goias_players_person_mapping.json). Nenhuma pessoa nova criada, nenhum candidato promovido — `RESOLVED` só quando `insert_status='APPROVED'` (mesma regra de F1/F3/F4/F5).

## 11-12. `career_players` intocado

Os 21 `CareerPlayer.personId` já existentes (F1) foram usados diretamente (nunca re-identificados por `answer`). Os 9 UNRESOLVED (`grafite`, `bruno_henrique`, `pedro_raul`, `jadilson`, `souza`, `roni`, `vitor`, `marcelo_rangel`, `apodi`) **continuam UNRESOLVED** — `goias_players.dart` não trouxe nenhuma evidência nova pra nenhum deles (nenhum dos 9 nomes aparece em `goiasPlayers` sob forma alguma).

## 13. Homônimos obrigatórios — auditados

| nome | achado |
|---|---|
| Nicolas | bare, índice 178, **0 owners deliberado**, AMBIGUOUS — nunca Vichiatto nem Godinho |
| Danilo | `career_players.danilo` (RESOLVED → Danilo Gabriel de Andrade) não colide com nada em `goiasPlayers` — só existem `"Danilo Portugal"` (AMBIGUOUS, `identity=AMBIGUOUS_IDENTITY`) e `"Danilo Dias"` (UNRESOLVED, pessoa própria) — nomes diferentes, 0 colisão de texto |
| Michael | **ausente** de `goias_players.dart` (confirmado por busca, não presumido) |
| Fabiano | **ausente** de `goias_players.dart` |
| Carlos Eduardo | bare, AMBIGUOUS — 2 pessoas reais no elenco atual (`Carlos Eduardo Amaral Pereira de Castro` / `Carlos Eduardo de Sousa Leopoldino`) reivindicariam o mesmo texto reduzido, nunca escolhido um sozinho |
| Luiz Felipe | ausente de `goiasPlayers` |
| Murilo/Murillo | só `"Murilo Henrique"` existe (UNRESOLVED, pessoa PROVISIONAL própria) — não colide com `Murilo Câmara` nem `Murillo Victorio` (textos diferentes) |

## 14. Colisões por texto normalizado

**Dentro de `goias_players.dart`**: 231 textos distintos, **0 colisões**.
**Entre `goias_players.dart` e `career_players`** (a fusão real do autocomplete): **0 colisões hoje** — nenhum texto de `goiasPlayers` bate com nenhum `answer`/`acceptedAnswers` de `career_players`. Achado honesto, não forçado: a fragilidade estrutural existe, mas não está sendo exercida pelos dados reais atuais.

**Same-person collisions**: 0. **Cross-person collisions**: 0 (nos dados reais — provado sinteticamente que o mecanismo detecta e reporta quando ocorre, seção 22 dos testes).

## 15-16. Colisões (real): 0 same-person, 0 cross-person

Já cobertos acima — repetido aqui pra manter a numeração pedida.

## 17. Ambiguidade visual

Auditado: **não ocorre hoje** — nenhum par de pessoas diferentes produz o mesmo texto visível em `_suggestions`. Nenhuma copy nova implementada (fora de escopo desta rodada, como pedido) — se um dia ocorrer, o novo índice reporta em `crossPersonCollisions`, nunca silenciosamente.

## 18. Novo modelo de sugestão (implementado)

`lib/features/arena/games/career_path/career_autocomplete.dart` (novo arquivo):

```dart
class CareerAutocompleteSuggestion {
  final String label;
  final String normalizedLabel;
  final String acceptedText;
  final String? personId;
}
class CareerNameTextCollision { ... } // nunca escondida
class CareerAutocompleteIndex {
  final List<CareerAutocompleteSuggestion> suggestions;
  final Map<String, String> resolveMap;
  final List<CareerNameTextCollision> crossPersonCollisions;
}
CareerAutocompleteIndex buildCareerAutocompleteIndex({
  required List<CareerPlayer> careerPlayers,
  required List<GoiasPlayer> goiasPlayers,
});
```

## 19. Nova regra de dedup

Prioridade **explícita** por fonte (`career_players` > `goias_players`), decidida por regra, nunca por ordem de chamada dos `for` — testado diretamente (chamar a função com os mesmos dados dá o mesmo resultado independente de qual dataset "chegaria primeiro" na lógica antiga). Casos tratados:
- **mesma pessoa em 2 datasets** (`personId` igual, ou um dos lados `null`) → nunca é colisão, é corroboração/ampliação — mantém o de maior prioridade.
- **texto igual, `personId` diferentes e não-nulos** (cross-dataset OU dentro do mesmo dataset) → **sempre reportado** em `crossPersonCollisions`, e a fonte de maior prioridade vence a exibição — nunca escondido.

## 20. Comportamento do clique

Auditado e preservado: `onSelected: (selection) => controller.text = selection` — a seleção só preenche o campo de texto (agora com `suggestion.label`, mesmo texto de antes). `personId` **nunca** é enviado a `guess()`/ranking/progresso — só metadado interno da sugestão.

## 21. Impacto no gameplay

**Zero.** `_submitGuess` continua chamando `context.read<CareerPathCubit>().guess(resolved)` com o texto resolvido via `_resolveMap` (agora `index.resolveMap`, construído com a mesma prioridade). O cubit continua comparando contra `acceptedAnswers` via `normalizeName`, sem qualquer mudança.

## 22. Mudanças Flutter

- `lib/features/arena/games/career_path/career_autocomplete.dart` — **novo**, o model+lógica de dedup.
- `lib/features/arena/games/career_path/goias_players.dart` — `GoiasPlayer.personId` (nullable) adicionado; 41 entradas ganharam o valor real, 174 continuam `null`.
- `lib/features/arena/games/career_path/pages/career_path_page.dart` — `initState` reduzido de ~30 linhas de merge manual pra 1 chamada a `buildCareerAutocompleteIndex`; **0 mudança visual** (mesmo `RawAutocomplete<String>`, mesmo `TextField`, mesma UI).
- `test/features/arena/games/career_path/career_autocomplete_test.dart` — **novo**, 15 testes.

Nenhum outro arquivo Dart tocado (`career_players.dart`, `career_models.dart`, `career_path_cubit.dart` intocados).

## 23. Bug pego durante a construção (self-caught, corrigido antes de qualquer teste passar)

A 1ª versão de `buildCareerAutocompleteIndex` chamava `claim(entry.name, 'goias_players', entry.name, null)` — **ignorando `entry.personId` de propósito nenhum**, sempre passando `null`. Isso teria tornado os 41 `personId` recém-injetados em `goiasPlayers` mortos (nunca usados pra detectar colisão nem exibidos na sugestão). Pego pelo teste sintético "career_players sempre vence" (dava 0 colisões em vez de 1), corrigido pra `claim(entry.name, 'goias_players', entry.name, entry.personId)` antes de qualquer commit.

## 24. Migrations — 0, confirmado

`goias_players.dart` é 100% local (const Dart), sem tabela Supabase equivalente. `personId` existe só no lado Dart, igual ao padrão da F5. Nenhuma migration gerada, nenhum `db push`.

## 25. Testes específicos

**JS** (`tooling/multiclub/test_goias_players_person_mapping.mjs`, novo, 21 testes): contagens reais, nenhuma pessoa nova criada, os 3 homônimos obrigatórios (Nicolas/Danilo Portugal/Carlos Eduardo) classificados corretamente, 0 colisão interna, `.dart` real bate com o mapping (personId injetado exatamente nas 41 linhas certas), `career_players.dart` intocado (30/21/9 inalterado), reprodutibilidade + idempotência do apply, 0 migrations.

**Dart** (`test/features/arena/games/career_path/career_autocomplete_test.dart`, novo, 15 testes): 245 sugestões reais (215+30, 0 colisão), personId nunca vira texto de UI, resolução de alias/acceptedAnswers preservada, **colisão sintética Danilo A/B provando que career_players sempre vence independente de ordem**, colisão dentro do mesmo dataset também reportada, mesma-pessoa nunca vira colisão, homônimos Nicolas/Danilo nunca fundidos.

## 26. JS total

**438 passaram, 0 falharam** (417 antes + 21 novos).

## 27. `flutter analyze`

**0 issues.**

## 28. `flutter test`

**752 passed, 1 skip** (era 737/1; +15 novos, todos em `career_autocomplete_test.dart`).

## 29. `git diff --stat`

```
 lib/features/arena/games/career_path/goias_players.dart    | 92 +++++++++---------
 lib/features/arena/games/career_path/pages/career_path_page.dart | 39 ++-------
 lib/features/store/presentation/widgets/store_entry_card.dart    |  2 +- (pré-existente, não tocado)
 3 files changed, 62 insertions(+), 71 deletions(-)
```

## 30. `git status`

```
 M lib/features/arena/games/career_path/goias_players.dart
 M lib/features/arena/games/career_path/pages/career_path_page.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, não tocado)
?? _competitions_pkg/                                              (pré-existente)
?? data_export/goias/player_reconciliation/goias_players_person_mapping.json
?? data_export/goias/player_reconciliation/goias_players_person_mapping_stats.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (pré-existente)
?? lib/features/arena/games/career_path/career_autocomplete.dart
?? migration_dump.txt                                               (pré-existente)
?? test/features/arena/games/career_path/
?? tooling/multiclub/apply_goias_players_person_mapping.mjs
?? tooling/multiclub/build_goias_players_person_mapping.mjs
?? tooling/multiclub/test_goias_players_person_mapping.mjs
```

---

## Limites respeitados

- 0 migrations, 0 `db push`, 0 commit, 0 `git push`.
- `lineup_matches` não tocado.
- `crowd_lineup`/`goiasSquad`/`SquadPlayer` não tocados (F5 permanece fechada).
- F2 (`career_players.club_career`/`aggregate_stats`/`position` → tabelas canônicas) não iniciado.
- Os 9 `career_players` UNRESOLVED continuam UNRESOLVED — reconciliation foundation não reaberta.
- 0 mudança visual — mesmo widget, mesmo comportamento de clique, mesma UI.
- Nenhuma copy nova de desambiguação implementada (não havia necessidade — 0 ambiguidade visual real hoje).

## 31. Endurecimento final — classificação semântica de colisão (aprovado antes do commit)

O ponto de revisão do usuário: "prioridade editorial (`career_players` > `goias_players`)" e "identidade" são 2 decisões DIFERENTES, e a v1 do índice as misturava implicitamente — `personId == null` de um lado nunca podia ser tratado como "mesma pessoa" só por igualdade de texto.

**Correção aplicada** em `career_autocomplete.dart`:
- Novo `enum CareerCollisionType { samePerson, crossPerson, unknownIdentity }`.
- `_classifyCollision(personIdA, personIdB)`: `samePerson` só quando os 2 são não-nulos e iguais; `crossPerson` só quando os 2 são não-nulos e diferentes; **`unknownIdentity` sempre que pelo menos 1 lado é `null`** — nunca inferido como mesma pessoa pelo texto.
- `CareerNameTextCollision` agora carrega `type` (identidade) separado de `displayedLabel`/`displayedPersonId` (**DISPLAY_PRIORITY** — só decide qual texto aparece no dropdown, nunca afirma identidade).
- `CareerAutocompleteIndex` ganhou `collisions` (lista completa, todo tipo) + getters `samePersonCollisions`/`crossPersonCollisions`/`unknownIdentityCollisions`.

**Testes novos** (6, todos em `career_autocomplete_test.dart`): SAME_PERSON sintético (Paulo Baier, mesmo personId nos 2 lados), CROSS_PERSON sintético (Danilo A/B) rodado com os valores de personId trocados de lado (prova que a prioridade é por FONTE, nunca por valor de personId) e com posição embaralhada dentro de cada lista, UNKNOWN com 1 nullable (Nicolas — career_players tem personId real, goias_players não, exatamente o caso real do índice 178), UNKNOWN com 2 nullables (Carlos Eduardo, nenhum lado resolvido).

**Confirmação dos números reais após a mudança** (nada mudou, como esperado — a correção é estrutural, não recalcula reconciliação):
```
goias_players = 215
RESOLVED = 41, AMBIGUOUS = 58, UNRESOLVED = 116, TEXT_ALIAS_ONLY = 0
internal normalized collisions = 0
career × goias collisions (samePerson=0, crossPerson=0, unknownIdentity=0)
```

**Testes finais**: JS **438 passando** (inalterado — nenhum `.mjs` tocado nesta rodada). `flutter analyze`: **0 issues**. `flutter test`: **758 passed, 1 skip** (era 752/1, +6 novos).

## 32. Commit

```
3fd9c99fe85b99f775ee71d698fe94791f772670
feat(multiclub): canonicalize career autocomplete identities
```

---

**FECHADA. Commitada localmente. Nenhum `git push` feito.**

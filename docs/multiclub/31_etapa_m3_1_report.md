# Etapa M3.1 — Tenant-Aware Content Reads + Fallback Isolation

Data: 2026-09-02
Status: **Rodada de hardening pós-review concluída. Ver §40-60 abaixo. Pronto para commit autorizado (lista exata de arquivos), 0 `db push`, 0 `git push`.**

---

**Nota de leitura**: §1-39 abaixo são o relatório da 1ª rodada (arquitetura inicial). A revisão do usuário aprovou a arquitetura e pediu exatamente 2 hardenings antes do commit — cobertos em §40-60, que também trazem os totais finais reais (superam os números de §36-38, que ficam como registro histórico da 1ª rodada).

---

## 0. Confirmação de Git (antes de qualquer alteração)

```
git rev-parse HEAD  →  bd18226744060ec901442370213ec45e75e80d0e
git log -3 --oneline:
  bd18226 docs(multiclub): record M2.2A commit hash and post-push validation
  0d5db94 feat(multiclub): add additive tenant schema
  96731dc docs(multiclub): audit tenant scope compatibility
git status: limpo (só as exclusões padrão — store_entry_card.dart modificado
  não-staged, _competitions_pkg/, migration_dump.txt,
  docs/multiclub/19_etapa_e_v4_applied_report.md untracked)
```

## 1. Escopo exato — respeitado

Só as 5 tabelas de conteúdo (`career_players`, `guess_players`, `squad_members`, `lineup_matches`, `quiz_questions`). Progresso, RPCs, membership, notifications, tickets, store, `crowd_lineup` votes — **nada tocado**, confirmado por teste estático (§8 abaixo).

## 2. Passaporte — intocado

`supabase_passport_repository.dart` confirmado sem `_clubConfig`/`club_id` — segue `NEEDS_PRODUCT_DECISION`.

## 3-4. `ClubConfig` como fonte do UUID + injeção por DI

Todas as 5 queries usam `_clubConfig.identity.canonicalClubId` — nunca o UUID literal reescrito. O UUID continua centralizado em `goias_club_config.dart` (confirmado: 0 ocorrência do literal `4c16340d-...` em qualquer um dos 5 repositories).

`ClubConfig` é injetado pelo **construtor** (`Repository(client, clubConfig)`), resolvido uma vez em `injection_container.dart` (`sl()`, já registrado eager desde a M1) — **nenhum** repository chama `sl<ClubConfig>()`/`GetIt.I` por conta própria (testado explicitamente).

## 5. Supabase read scope — as 5 queries

| Tabela | Filtro adicionado |
|---|---|
| `career_players` | `.eq('club_id', _clubConfig.identity.canonicalClubId)` |
| `guess_players` | idem |
| `squad_members` | idem |
| `lineup_matches` | idem |
| `quiz_questions` | idem |

**Provado contra a URL REAL** que o `postgrest` monta (via `CapturingHttpClient`, um `http.Client` injetado no `SupabaseClient` real que captura a requisição de verdade — nunca um teste que só checa "devolveu dados"): as 5 URLs contêm `club_id=eq.<canonicalClubId>` (`test/core/club/club_scoped_content_repositories_test.dart`, 5 testes dedicados a isso).

## 6. Auditoria de consumers — completa antes de editar

Busca por `.from('<table>')` em todo `lib/` confirmou **exatamente 1 caminho de leitura por tabela** (5 arquivos, 5 ocorrências) — nenhum bypass duplicado/alternativo além do achado no item a seguir.

**Achado crítico não previsto pelo pedido**: `CareerPathPage`, `GuessPlayerPage` e `LineupPage`, quando abertas por **deep link** (sem `cubit` preloaded pela Arena), construíam o Cubit direto com a lista `const` local (`careerPlayers`/`guessPlayerCatalog`/`orderedLineupMatches`) — **nunca chamavam o repository, nunca tocavam o Supabase**. Isso significa que `ALL_RUNTIME_READ_PATHS_SCOPED` seria falso mesmo com os 5 repositories corrigidos: um clube não-Goiás acessando por deep link veria dado do Goiás **pra sempre**, de um jeito ainda pior que um fallback mal isolado (nem chega a tentar o Supabase). Corrigido nas 3 páginas — ver §22-23.

## 7. Fallback isolation — `ClubScopedFallback<T>`

Novo `lib/core/club/club_scoped_fallback.dart` — classe genérica `ClubScopedFallback<T>({Map<String, T> byClubCode})`, método `forClub(code) → T?`. Cada uma das 4 tabelas com fallback (`squad_members` nunca teve, F4) ganhou seu próprio registry:
```dart
final careerPlayersFallback = ClubScopedFallback<List<CareerPlayer>>({'goias': careerPlayers});
final guessPlayerCatalogFallback = ClubScopedFallback<List<GuessPlayer>>({'goias': guessPlayerCatalog});
final orderedLineupMatchesFallback = ClubScopedFallback<List<LineupMatch>>({'goias': orderedLineupMatches});
const quizQuestionsFallback = ClubScopedFallback<List<QuizQuestion>>({'goias': quizQuestions});
```
Um mecanismo só, reutilizável — cadastrar um 2º clube nunca envolve editar `switch(code)` espalhados, só adicionar uma entrada no `Map` de cada registry.

## 8. Fallbacks Goiás registrados

`careerPlayersFallback`, `guessPlayerCatalogFallback`, `orderedLineupMatchesFallback`, `quizQuestionsFallback` — todos com exatamente 1 entrada (`'goias'`), a mesma lista `const`/`final` de sempre, nenhum dado novo.

## 9. Regra crítica — `NO_CROSS_CLUB_FALLBACK`

Nova `lib/core/club/club_data_unavailable_exception.dart` (`ClubDataUnavailableException`, `implements Exception`, sem UI acoplada — per pedido). Lógica em cada repository:
```dart
if (parsed.isNotEmpty) return parsed;
return _fallbackOrThrow(clubCode); // busca SÓ o fallback DESTE clube — nunca outro
```
`_fallbackOrThrow` devolve o fallback do clube ativo se existir; **se não existir, lança `ClubDataUnavailableException`** — nunca devolve o fallback de outro clube.

## 10. Teste com clube sintético

`test/core/club/synthetic_club_config.dart` — `syntheticClubBConfig` (`code: 'club-b'`, UUID `00000000-0000-0000-0000-0000000000b1`, deliberadamente diferente do Goiás) — **nunca cadastrado em `clubRegistry`**, usado só direto em teste. Nenhuma menção a time real.

## 11-13. Prova de `NO_CROSS_CLUB_FALLBACK`

Para as 4 tabelas com fallback: `syntheticClubBConfig` + Supabase vazio (200, `[]`) **e** + falha de rede (exceção simulada) → **ambos** lançam `ClubDataUnavailableException`, nunca devolvem `careerPlayers`/`guessPlayerCatalog`/`orderedLineupMatches`/`quizQuestions` (4+4 = 8 testes). Para `squad_members` (sem fallback): `syntheticClubBConfig` + Supabase vazio → `Success([])` (lista vazia é uma resposta válida, nunca o elenco do Goiás) — confirmado que a própria query já filtrou pelo `club_id` do clube sintético.

## 14. Semântica de resultado vazio vs. erro de rede

Distinguidas explicitamente no código: **0 linhas retornadas** (consulta funcionou) nunca reporta ao Sentry — só cai no mesmo `_fallbackOrThrow`. **Exceção real** (rede/parse/etc.) reporta ao Sentry **e então** cai no mesmo `_fallbackOrThrow`. As duas convergem pro mesmo destino (fallback-ou-exceção), mas só a 2ª é logada como erro — a distinção que o pedido pediu (item 19) está em **como cada caso é observado**, não em desviar o resultado final.

## 15-16. Career/Guess/Squad/Lineup/Quiz — F1-F7 preservados

Confirmado por teste estático (`test_multiclub_runtime_content_scope.mjs`, seção 5) que os campos protegidos continuam nas queries: `career_players` (`id`/`answer`/`accepted_answers`/`club_career`/`person_id`), `guess_players` (`id`/`name`/`display_name`/`person_id`), `quiz_questions` (`id`/`difficulty`/`question`/`options`/`correct_index`), `squad_members` (`.select()` sem lista explícita, igual antes). `lineup_matches.lineup` (jsonb, 11 slots) confirmado **sem `person_id`** no corpo do código (só no comentário explicando a regra F7) — nenhuma identidade canônica entrou no slot. Nenhum campo de negócio alterado em nenhuma das 5 — só a coluna `club_id` foi adicionada ao filtro da query, nunca ao `select`.

## 17. Writes runtime inesperados

**Nenhum encontrado.** As 5 tabelas são 100% leitura nesta etapa — nenhum `INSERT`/`UPDATE`/`DELETE` runtime nos 5 repositories (confirmado por leitura completa dos 5 arquivos).

## 18. Independência do `DEFAULT` transicional da M2.2A

As 5 queries **nunca dependem** do `DEFAULT` Goiás do banco — todas mandam `club_id` explícito via `.eq(...)`. `NO_RUNTIME_WRITES_FOUND` confirmado (item 17) — não havia nenhum INSERT pra provar independência de DEFAULT em escrita, então a checagem é vácua mas a intenção (nunca confiar no DEFAULT) já vale pras leituras.

## 19-20. Semântica vazio vs. erro / dataset ausente

Ver §14. Para o clube sintético sem fallback: `EMPTY/MISSING_DATASET` → `ClubDataUnavailableException` (nunca fallback Goiás). Fallback só existe se explicitamente cadastrado pro `code` daquele clube em cada `ClubScopedFallback`.

## 21. String `'goias'` espalhada

Confirmado: **nenhum** `if (club.code == 'goias')` em nenhum dos 5 repositories — a associação código→fallback é centralizada no `Map` de cada `ClubScopedFallback`, nunca um `if`/`switch` condicional no meio da lógica de leitura.

## 22-23. `AppColors`/`AppAssets`/`isGoias` — fora de escopo, confirmado intocado

Nenhum arquivo de tema/branding tocado. `Team.isGoias`/`_isGoiasHome`/`getGoiasSnapshot()`/`Team.goiasId` **não tocados** — confirmados fora do diff.

## 24. RPCs — fora de escopo, confirmado intocado

Nenhuma RPC alterada — 0 arquivo `.sql` novo, `migration list` continua **41 local=remote** (nenhuma migration nova).

## 25. Banco

0 migration, 0 `db push`, 0 DML. Só Flutter/tooling/tests.

## 26. Teste de escopo da query — prova real, não inferência

`test/core/club/capturing_http_client.dart` — `http.Client` real, injetado via `SupabaseClient(..., httpClient: capturing)` (parâmetro oficial do pacote, sem mock framework nenhum), captura a `Uri` de cada requisição de verdade. **5 testes** (1 por tabela) confirmam `club_id=eq.<canonicalClubId>` literalmente na URL — não apenas "o repository devolveu uma lista".

## 27. Teste de fallback Goiás

**4 testes** (career/guess/lineup/quiz): Goiás + Supabase retornando `[]` → resultado é (`same()`, identidade de objeto, não só igualdade de conteúdo) exatamente a constante `careerPlayers`/`guessPlayerCatalog`/`orderedLineupMatches`/`quizQuestions`. Comparado por identidade de objeto — prova mais forte que comparar conteúdo.

## 28. Teste anti-leak club-b

**8 testes** (4 tabelas × Supabase-vazio + Supabase-falha) confirmam `ClubDataUnavailableException`, nunca o fallback do Goiás — cobrindo TODAS as famílias de fallback migradas, não só uma (item explícito do pedido).

## 29. Dados atuais — Goiás

```
careerPlayers.length         = 30
guessPlayerCatalog.length    = 173
orderedLineupMatches.length  = 31
quizQuestions.length         = 60
```
Idênticos aos números reais consultados na M2.2A — nenhum dataset alterado, testado explicitamente (`test/core/club/club_scoped_content_repositories_test.dart`, grupo "Sanity — datasets de Goiás inalterados").

## 30. DI

5 registrations em `lib/core/di/injection_container.dart` agora passam `sl()` como 2º argumento (resolve `ClubConfig`, já registrado **primeiro**, eager, desde a M1 — `sl.registerSingleton<ClubConfig>(resolveActiveClub())` continua sendo a 1ª linha de `setupDependencies()`). Nenhuma dependência circular — `ClubConfig` não depende de nenhum repository, os repositories dependem dele.
```
CareerPlayerRepository(Supabase.instance.client, sl())
GuessPlayerRepository(Supabase.instance.client, sl())
LineupMatchRepository(Supabase.instance.client, sl())
QuizQuestionRepository(Supabase.instance.client, sl())
SupabaseSquadRepository(Supabase.instance.client, sl())
```

## 31. Modelo de erro

`ClubDataUnavailableException` (`implements Exception`, sem UI/dialog acoplado) — nome literal do exemplo conceitual do pedido. Nenhum handler de UI criado nesta rodada; hoje é inalcançável em produção (Goiás sempre tem dado + fallback), existe pra ficar seguro quando um 2º clube for cadastrado sem fallback ainda.

## 32. Erros reais não escondidos

Nenhum `catch (_) { return []; }` — o `catch` de cada repository continua reportando ao Sentry (como já fazia) e só então decide fallback-ou-exceção pela MESMA lógica do caso "0 linhas" (nunca um catch silencioso que apaga a distinção rede/dataset-ausente/bug).

## 33. Tooling

`tooling/multiclub/audit_multiclub_runtime_content_scope.mjs` — lê os 5 repositories + as 3 páginas + `injection_container.dart` + `club_registry.dart` REAIS (nunca lista assumida), escreve `data_export/goias/player_reconciliation/multiclub_runtime_content_scope_audit.json`. `test_multiclub_runtime_content_scope.mjs` — **21 testes**, provando exatamente os 5 invariantes pedidos: 5/5 tabelas tenant-scoped, 0 UUID Goiás hardcoded em repository, 0 fallback cross-club (mecanismo `ClubScopedFallback` usado, nunca `return <const>` incondicional), 0 segundo clube real (`clubRegistry` com 1 entrada), 0 drift semântico F1-F7 — mais os bônus: bypass de página corrigido, DI correta, escopo estrito (Passaporte/progress/RPC intocados), reprodutibilidade.

## 34. Não alterar `DEFAULT` da M2.2A

Confirmado — nenhuma migration nova, `DEFAULT` Goiás continua no banco (M2.2B decide o futuro dele).

## 35. `KEY_SCOPE` não resolvido

Confirmado — nenhuma PK/UNIQUE tocada (0 arquivo de migration novo). `SECOND_CLUB_BLOCKED` continua `true` — ver §26 do relatório M2.2A, nada mudou nessa frente.

## 36. Testes gerais

`flutter analyze`: **0 issues**. `flutter test`: **787 passed, 1 skip** (era 769/1 — **+18 novos**: 17 em `club_scoped_content_repositories_test.dart` + 1 correção em `quiz_cubit_test.dart` que precisou do 2º argumento novo, sem contar como teste novo). 1 teste pré-existente (`lineup_page_test.dart`) precisou de uma correção de setup (registrar `LineupMatchRepository` fake em vez de deixar `LineupPage` usar a lista local direto) — não é um teste novo, é ajuste de infraestrutura pro mesmo teste continuar provando a mesma coisa.

`tooling/multiclub/test_*.mjs`: **598 passando, 0 falhando** (577 antes desta etapa, +21 novos).

## 37. Banco não mudou

`npx supabase migration list` → **41 migrations, todas `local=remote`** — nenhuma nova (confirmado, mesmo total de antes da M3.1).

## 38. Git — fora de escopo intocado

`store_entry_card.dart`/`_competitions_pkg/`/`migration_dump.txt`/`docs/multiclub/19_etapa_e_v4_applied_report.md` continuam exatamente como estavam (nenhum staged, nenhum tocado).

## 39. Commit — NÃO feito nesta rodada

Conforme pedido — implementado, validado, **PARADO** antes do commit.

---

## `git diff --stat` (arquivos já rastreados)

```
 data_export/.../multiclub_hardcode_audit_stats.json            |  2 +
 lib/core/di/injection_container.dart                            | 10 +--
 .../career_path/data/career_player_repository.dart              | 42 +++++++++--
 .../games/career_path/pages/career_path_page.dart                | 65 +++++++++++-----
 .../guess_player/data/guess_player_repository.dart               | 40 +++++++---
 .../guess_player/pages/guess_player_page.dart                    | 71 ++++++++++------
 .../games/lineup/data/lineup_match_repository.dart                | 42 ++++++++---
 .../arena/games/lineup/pages/lineup_page.dart                     | 64 ++++++++++-----
 .../games/quiz/data/quiz_question_repository.dart                 | 35 +++++++--
 .../squad/data/supabase_squad_repository.dart                     |  9 ++-
 .../presentation/widgets/store_entry_card.dart (pré-existente)     |  2 +-
 .../arena/games/quiz/cubit/quiz_cubit_test.dart                   |  4 +-
 test/features/arena/lineup/lineup_page_test.dart                  | 17 ++++++
 13 files changed, 322 insertions(+), 81 deletions(-)
```

**Nota**: `multiclub_hardcode_audit_stats.json` mudou como efeito colateral **legítimo** — é a M1's `audit_multiclub_hardcodes.mjs` recatalogando `lib/core/club/` (agora com 2 arquivos novos, `club_scoped_fallback.dart`/`club_data_unavailable_exception.dart`), re-executada automaticamente pelo teste de reprodutibilidade de `test_multiclub_foundation.mjs`. Não é uma edição manual — reflete o estado real do diretório.

## `git status`

```
 M data_export/goias/player_reconciliation/multiclub_hardcode_audit_stats.json
 M lib/core/di/injection_container.dart
 M lib/features/arena/games/career_path/data/career_player_repository.dart
 M lib/features/arena/games/career_path/pages/career_path_page.dart
 M lib/features/arena/games/guess_player/data/guess_player_repository.dart
 M lib/features/arena/games/guess_player/pages/guess_player_page.dart
 M lib/features/arena/games/lineup/data/lineup_match_repository.dart
 M lib/features/arena/games/lineup/pages/lineup_page.dart
 M lib/features/arena/games/quiz/data/quiz_question_repository.dart
 M lib/features/squad/data/supabase_squad_repository.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart  (pré-existente, não tocado)
 M test/features/arena/games/quiz/cubit/quiz_cubit_test.dart
 M test/features/arena/lineup/lineup_page_test.dart
?? data_export/goias/player_reconciliation/multiclub_runtime_content_scope_audit.json
?? lib/core/club/club_data_unavailable_exception.dart
?? lib/core/club/club_scoped_fallback.dart
?? test/core/club/capturing_http_client.dart
?? test/core/club/club_scoped_content_repositories_test.dart
?? test/core/club/synthetic_club_config.dart
?? tooling/multiclub/audit_multiclub_runtime_content_scope.mjs
?? tooling/multiclub/test_multiclub_runtime_content_scope.mjs
```
Untracked não relacionados a esta etapa (pré-existentes): `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md`.

---

## Resumo — arquivos alterados/criados nesta etapa (pra revisão do diff)

**Novos (`lib/core/club/`)**: `club_scoped_fallback.dart`, `club_data_unavailable_exception.dart`.

**Repositories alterados (5)**: `career_player_repository.dart`, `guess_player_repository.dart`, `lineup_match_repository.dart`, `quiz_question_repository.dart`, `supabase_squad_repository.dart` — cada um ganhou `ClubConfig` no construtor, `.eq('club_id', ...)` na query, e (exceto squad) o registry `ClubScopedFallback` + `_fallbackOrThrow`.

**Páginas corrigidas (3, achado do audit)**: `career_path_page.dart`, `guess_player_page.dart`, `lineup_page.dart` — o branch de deep-link (sem `cubit` preloaded) agora busca via repository (`FutureBuilder` + `GoiasLoadingIndicator` durante o carregamento), nunca mais a lista `const` local direto.

**DI**: `injection_container.dart` — 5 registrations passam `sl()`.

**Testes novos**: `test/core/club/capturing_http_client.dart`, `synthetic_club_config.dart`, `club_scoped_content_repositories_test.dart` (19 testes) + 1 correção em `quiz_cubit_test.dart` + 1 correção de setup em `lineup_page_test.dart`.

**Tooling novo**: `audit_multiclub_runtime_content_scope.mjs`, `test_multiclub_runtime_content_scope.mjs` (21 testes).

---

## Rodada de hardening pós-review (2026-09-02)

A revisão do usuário aprovou a arquitetura da 1ª rodada (5/5 reads tenant-aware, 0 DB change, 41 migrations local=remote) e pediu exatamente **2 hardenings** antes do commit. Ambos implementados e testados abaixo.

### 40. Hardening 1 — semântica de erro (EMPTY_NO_FALLBACK ≠ REMOTE_FAILURE_NO_FALLBACK)

A 1ª rodada (§14/§31/§32) relatava que sucesso-vazio e falha-real convergiam pro "mesmo destino (fallback-ou-exceção)". A revisão apontou que isso é a conflação errada: **falha remota real** (rede, timeout, HTTP/client error, exceção do `postgrest`, erro de parse/contrato de dado, bug de programação) **nunca é semanticamente igual a** "dataset ausente" (sucesso, 0 linhas).

Reescrito nos 4 repositories com fallback (`career_player_repository.dart`, `guess_player_repository.dart`, `lineup_match_repository.dart`, `quiz_question_repository.dart`) como dois blocos estruturalmente separados, nunca aninhados:

```dart
Future<List<T>> load() async {
  final clubCode = _clubConfig.identity.code;
  List<T> parsed;
  try {
    final rows = await _client.from(table).select(...).eq('club_id', ...)...;
    parsed = <T>[];
    for (final row in rows) { ... }
  } catch (error, stackTrace) {
    unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    final fallback = xFallback.forClub(clubCode);
    if (fallback != null) return fallback;
    Error.throwWithStackTrace(error, stackTrace); // exceção ORIGINAL, stack trace intacto
  }
  if (parsed.isNotEmpty) return parsed;
  final fallback = xFallback.forClub(clubCode);
  if (fallback != null) return fallback;
  throw ClubDataUnavailableException(table: table, clubCode: clubCode); // só aqui, fora do catch
}
```

Resultado, por caso:
- **Goiás + sucesso + 0 linhas** → fallback Goiás (comportamento pré-existente preservado).
- **Goiás + falha remota** → Sentry + fallback Goiás (comportamento pré-existente preservado — compatibilidade mantida).
- **club-b (sem fallback) + sucesso + 0 linhas** → `ClubDataUnavailableException` (correto — dataset genuinamente ausente).
- **club-b (sem fallback) + falha remota** → a exceção **original** relançada intacta via `Error.throwWithStackTrace(error, stackTrace)` — **nunca** `ClubDataUnavailableException`, **nunca** `throw error;` (que perderia o stack trace).

`squad_members` (sem fallback, F4): **não** ganhou nenhuma semântica nova — continua `Success([])`/`Error` do `Result` já existente da feature, exatamente como antes.

### 41. Hardening 2 — testes atualizados pra provar a distinção

**`test/core/club/club_scoped_content_repositories_test.dart`** reescrito com matriz completa 2×2 (Goiás/club-b × sucesso-vazio/falha-de-rede) pras 4 tabelas com fallback + 3 testes de squad — **25 testes** no total (era 21 na 1ª rodada, +4 líquidos apesar da matriz ter crescido bem mais, porque vários testes da 1ª rodada foram consolidados dentro da mesma matriz):
- Goiás + vazio → fallback (identidade de objeto, `same()`).
- Goiás + falha de rede → Sentry + fallback (mesma identidade).
- club-b + vazio → `ClubDataUnavailableException`.
- club-b + falha de rede → a exceção **original** (mesma instância, via `same(originalError)` — prova que o stack trace não foi trocado).
- squad: query real com `club_id`; club-b + vazio → `Success([])`; club-b + falha de rede → `Error`/`ServerFailure` da arquitetura já existente (nova cobertura, nunca elenco do Goiás).

Novo helper `_captureThrow(...)` captura o que `load()` de fato lança/retorna, permitindo `same(error)` em vez de só comparar mensagem/tipo.

**`test/features/arena/deep_link_content_scope_test.dart`** (NOVO) — os testes de widget "obrigatórios" pedidos pela revisão, não apenas grep/tooling estático. Pra `CareerPathPage`/`GuessPlayerPage`/`LineupPage`:
- Dados **sentinela** (`sentinel-career-player`, etc. — claramente diferentes do fallback Goiás) injetados via um repository fake que sobrescreve só `load()`. Abrindo a página **sem** `cubit` preloaded (rota de deep link) e inspecionando o estado do `Cubit` via `BlocProvider.of<T>`, confirma-se que os dados **consumidos** são os sentinela — não a constante local. Se alguém reintroduzir `CareerPathCubit(careerPlayers)` no bypass antigo, esse teste quebra (prova a coisa certa: dado consumido, não só "`repository.called == true`").
- Segundo teste por página: com `cubit` **preloaded** (fluxo normal vindo da Arena), `loadCallCount == 0` no repository — prova que o caminho preloaded nunca refaz fetch.

6 testes novos, todos passando. Bugs corrigidos no caminho: import faltando de `GuessPlayerRoundState`; `unawaited_futures` lint nas cascatas `..loadSelected()`/`..loadSelectedMatch()`; overflow de `RenderFlex` causado por string sentinela longa demais em `LineupPlayer.puzzleAnswer` (encurtada pra `'ABC'`); registro duplicado de `ArenaRankingRepository` no GetIt em 3 corpos de teste (removido, já vinha do `setUp` compartilhado).

### 42. Auditoria de ciclo de vida do `FutureBuilder`

Pedido explícito da revisão: confirmar que o novo `FutureBuilder` não causa `setState` após `dispose`, reload infinito, ou 1 chamada ao repository por rebuild. Nas 3 páginas o `Future` é armazenado como `late final Future<T> _future = _build();` em um campo de `State` (`career_path_page.dart:59`, `guess_player_page.dart:60`, `lineup_page.dart:62`) — **não** é criado dentro de `build()`. Isso garante estruturalmente que `_build()` roda exatamente **uma vez** por instância de `State`, independente de quantas vezes `build()` seja chamado (`setState`, resize, hot reload de widget pai, etc.) — nenhum "refetch a cada rebuild" possível. `setState`-após-`dispose`: não há `setState` manual nesses widgets — o `FutureBuilder` gerencia seu próprio ciclo de vida e descarta o `Future` pendente com segurança ao ser removido da árvore (comportamento padrão do framework, sem callback customizado que pudesse tocar um `State` descartado). `GoiasLoadingIndicator` mantido como estava (fora de escopo — branding).

### 43. Tooling atualizado

`tooling/multiclub/audit_multiclub_runtime_content_scope.mjs`: novos checks estáticos por tabela — `hasErrorPreservingRethrow` (`Error.throwWithStackTrace(error, stackTrace)` presente no `catch`), `hasEmptyResultThrow` (`throw ClubDataUnavailableException(` presente), `catchNeverThrowsClubDataUnavailable` (o bloco `catch` nunca contém `ClubDataUnavailableException(` — checado estruturalmente via regex do corpo do `catch`), consolidados em `emptyAndFailureSemanticsDistinct` por tabela e no invariante global `emptyVsRemoteFailureSemanticsInvariant.holds`. `squad_members` (sem fallback) passa trivialmente (nunca lançou nada).

`tooling/multiclub/test_multiclub_runtime_content_scope.mjs`: nova seção "3.5) EMPTY_NO_FALLBACK != REMOTE_FAILURE_NO_FALLBACK" com 4 testes novos provando o invariante acima — total do arquivo **25 testes** (era 21).

### 44. Totais finais (substituem §36-38)

```
flutter analyze:  0 issues
flutter test:     800 passed, 1 skip, 0 failed   (era 787/1 na 1ª rodada — +13 novos: 4 líquidos em
                                                    club_scoped_content_repositories_test.dart (matriz
                                                    reescrita, 25 testes finais) + 6 em
                                                    deep_link_content_scope_test.dart, novo + 3 de ajuste
                                                    incidental noutros arquivos já existentes na suíte)
tooling/multiclub/test_*.mjs:  602 passando, 0 falhando   (era 598 — +4 líquidos, seção 3.5 nova)
npx supabase migration list:   41 migrations, 41 local=remote, 0 mismatched, 0 nova
```

### 45. F1-F7 — reconfirmados intactos após o hardening

A mudança de estrutura try/catch não tocou nenhum `select(...)`/coluna protegida — reconfirmado rodando de novo `audit_multiclub_runtime_content_scope.mjs` (§33) após as edições: `allRuntimeReadPathsScoped: true`, `hardcodedGoiasUuid: false` nas 5, `bypassFixed: true` nas 3 páginas. Career (`id`/`answer`/`accepted_answers`/`club_career`/`person_id`), Guess (`id`/`name`/`display_name`/`person_id`), Lineup (`lineup` jsonb sem `person_id` no corpo — F7), Quiz (`id`/`difficulty`/`question`/`options`/`correct_index`) — todos confirmados presentes, nenhum campo de negócio alterado.

### 46. Banco — reconfirmado 0 mudança

41 migrations, local=remote (§37 original ainda vale, reconfirmado em §44 acima com a mesma contagem). 0 migration nova nesta rodada de hardening. 0 `db push`.

### 47. Git status — estado final antes do commit autorizado

```
 M data_export/goias/player_reconciliation/multiclub_hardcode_audit_stats.json   (fora do commit — não autorizado)
 M lib/core/di/injection_container.dart
 M lib/features/arena/games/career_path/data/career_player_repository.dart
 M lib/features/arena/games/career_path/pages/career_path_page.dart
 M lib/features/arena/games/guess_player/data/guess_player_repository.dart
 M lib/features/arena/games/guess_player/pages/guess_player_page.dart
 M lib/features/arena/games/lineup/data/lineup_match_repository.dart
 M lib/features/arena/games/lineup/pages/lineup_page.dart
 M lib/features/arena/games/quiz/data/quiz_question_repository.dart
 M lib/features/squad/data/supabase_squad_repository.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart      (excluído do commit, pré-existente)
 M test/features/arena/games/quiz/cubit/quiz_cubit_test.dart
 M test/features/arena/lineup/lineup_page_test.dart
?? _competitions_pkg/                                                  (excluído do commit, pré-existente)
?? data_export/goias/player_reconciliation/multiclub_runtime_content_scope_audit.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                      (excluído do commit, pré-existente)
?? docs/multiclub/31_etapa_m3_1_report.md
?? lib/core/club/club_data_unavailable_exception.dart
?? lib/core/club/club_scoped_fallback.dart
?? migration_dump.txt                                                  (excluído do commit, pré-existente)
?? test/core/club/capturing_http_client.dart
?? test/core/club/club_scoped_content_repositories_test.dart
?? test/core/club/synthetic_club_config.dart
?? test/features/arena/deep_link_content_scope_test.dart
?? tooling/multiclub/audit_multiclub_runtime_content_scope.mjs
?? tooling/multiclub/test_multiclub_runtime_content_scope.mjs
```

### 48. 0 `db push`, 0 `git push`

Confirmado — nenhum dos dois executado nesta rodada.

---

**Commit executado com a lista exata autorizada pelo usuário (21 arquivos, `git add` nomeado, nunca `git add .`).**

```
git rev-parse HEAD (pós-commit M3.1): f69b4b1
commit f69b4b1 — feat(multiclub): scope content runtime by club
  21 files changed, 2020 insertions(+), 84 deletions(-)
```

`git status` pós-commit: limpo em relação aos 21 arquivos do commit — restam só as exclusões padrão não tocadas (`store_entry_card.dart` modificado não-staged, `multiclub_hardcode_audit_stats.json` modificado não-staged, `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md` untracked). **0 `git push`.**

**PARADO. M3.1 encerrada. NÃO iniciar M3.2 ainda.**

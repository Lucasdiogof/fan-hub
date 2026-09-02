# 20 — Etapa F1: migrar `career_players` (Adivinhe o Jogador) para `person_id`

> Migração PARALELA de identidade — nada removido, nada aplicado no Supabase, nada commitado. **PARE — aguardando revisão.**

## 1. Runtime real de `career_players`

Confirmado por leitura direta do código (não suposto):
- **Fonte da verdade em runtime**: tabela real `public.career_players` no Supabase, lida por `CareerPlayerRepository.load()` ([career_player_repository.dart](goias-app/lib/features/arena/games/career_path/data/career_player_repository.dart)) via `.from('career_players').select(...).eq('is_active', true).order('sort_order')`.
- **Fallback**: `const careerPlayers` em [career_players.dart](goias-app/lib/features/arena/games/career_path/career_players.dart) (856 linhas, 30 entradas hardcoded) — usado quando a query falha (catch → Sentry + fallback) OU quando a tabela devolve 0 linhas.
- **Feature/tela**: "Adivinhe o Jogador", dentro da Arena — `career_path_page.dart` + `career_path_cubit.dart` + `career_table.dart`.
- **Tooling de geração do dataset**: `supabase/career_players.sql` (script original "30 jogadores", **HISTÓRICO/SUPERADO** — não está em `supabase/migrations/`, nunca fez parte das 27 migrations aplicadas) e `supabase/migrations/20260831020000_career_players_revalidated_v2.sql` (a versão REAL, aplicada — "revalidação v2", 31/08/2026). O export canônico já existente `data_export/goias/career_players.json` (30 linhas) já reflete a v2 (merge base+correção, mesmo padrão `mergeById` de todo o resto do projeto).

## 2. Tabela / model / fallback

| Camada | Arquivo |
|---|---|
| Tabela Supabase | `public.career_players` (`id text PK`, `answer`, `accepted_answers jsonb`, `position`, `club_career jsonb`, `national_teams jsonb`, `aggregate_stats jsonb`, `is_active`, `sort_order`, `created_at`) |
| Repository | `career_player_repository.dart` |
| Model/entity | `career_models.dart` (`CareerPlayer`, `CareerEntry`, `CareerAggregateStat`) |
| Use case/cubit | `career_path_cubit.dart` |
| Tela/widgets | `career_path_page.dart`, `career_table.dart` |
| Fallback | `career_players.dart` (const) |
| DI | `injection_container.dart:195` (`CareerPlayerRepository(Supabase.instance.client)`) |
| Progresso do usuário | `supabase_career_path_storage.dart` (chaveado por `career_players.id`, nunca tocado nesta etapa) |

## 3. Quantidade de registros

**30** (confirmado ao vivo: `select count(*) from public.career_players` → 30; bate com `career_players.json` e com o fallback Dart).

## 4-6. RESOLVED / AMBIGUOUS / UNRESOLVED

Reconciliação **já existia** — os 30 `career_players` já são `member`s de `canonical_people_candidates.json` (`source='career_players'`), a mesma fundação que alimentou `player_club_spells`/`player_club_stats`/`player_positions`. Não precisei rodar reconciliação nova, só classificar cada linha contra `people_insert_plan.json`:

| Status | Contagem |
|---|---|
| **RESOLVED** | **21** |
| **AMBIGUOUS** | **0** |
| **UNRESOLVED** | **9** |
| **OUT_OF_SCOPE** | 0 (nenhuma linha `is_active=false` hoje) |

Os 9 UNRESOLVED (`grafite`, `bruno_henrique`, `pedro_raul`, `jadilson`, `souza`, `roni`, `vitor`, `marcelo_rangel`, `apodi`) **não são ambíguos dentro do próprio `career_players`** — cada um tem exatamente 1 pessoa canônica candidata. Mas essa pessoa nunca chegou a `insert_status='APPROVED'` porque, olhando o conjunto INTEIRO de fontes (career_players + guess_players + lineup_matches), a identidade ficou `AMBIGUOUS_IDENTITY`/`NEEDS_REVIEW` desde a reconciliação original (Etapa A) — "só o nome bate; nenhuma fonte tem período/posição/camisa suficiente pra corroborar ou refutar". Isso é um achado sobre o PROJETO INTEIRO, não sobre `career_players` — reportando, não corrigindo escondido (item 12 do pedido).

## 7. Mapping completo

`data_export/goias/player_reconciliation/career_players_person_mapping.json` (30 entradas, formato exato pedido) + `career_players_person_mapping_stats.json`. Gerado por `tooling/multiclub/build_career_players_person_mapping.mjs`, reprodutível byte-a-byte (verificado — reroda e diff vazio).

## 8. Homônimos

| Nome curto | career_players resolve pra | Confirmado |
|---|---|---|
| `danilo` | **Danilo Gabriel de Andrade** | ✅ nunca Danilo Cunha da Silva |
| `michael` | **Michael Richard Delgado de Oliveira** | ✅ nunca o Michael histórico de 1999 (PROVISIONAL, nem aparece como candidato) |
| `erik` | **Erik Nascimento de Lima** | ✅ único candidato, RESOLVED |
| `fabiano` | — | **não existe nenhuma linha "fabiano" em `career_players`** — confirmado por ausência, não suposto. Homônimo do pedido não se aplica a este dataset. |
| `nicolas` | — | **não existe nenhuma linha "nicolas"/Nicolas Godinho em `career_players`** — idem, confirmado por ausência. |

Nenhum nome curto ambíguo foi "escolhido" — os 9 UNRESOLVED ficam genuinamente `NULL`.

## 9. Múltiplas passagens

10 dos 30 `career_players` têm 2+ passagens pelo Goiás dentro do próprio `club_career` (ex.: Walter 2012-2013+2016-2017, Paulo Baier 2004-2005+2007-2008, Evair, Welliton, Rafael Moura, Araújo, Iarley — todos RESOLVED). **Confirmado por teste**: cada um continua **1 career_player = 1 person_id único**, nunca fragmentado. (A relação real com `player_club_spells` — que já modela cada passagem como uma linha separada — fica pra F2; aqui só identidade.)

## 10. Campos duplicados vs. tabelas canônicas

| `career_players` atual | equivalente canônico | migrar agora? | manter legado? |
|---|---|---|---|
| `id` | (chave do JOGO — progresso/ranking, nunca "identidade de pessoa") | não é dado de pessoa | **sim, sempre** — nunca reaproveitar |
| `answer`/`accepted_answers` | `people.display_name`/aliases (parcial) | **não** | sim — são conteúdo editorial do JOGO (variações de resposta aceitas), não um espelho de `people` |
| `position` | `player_positions` | não (F2) | sim, por ora |
| `club_career` | `player_club_spells` | **não — semântica NÃO é idêntica**: `club_career` cobre a carreira internacional INTEIRA (todos os clubes), `player_club_spells` hoje só modela passagens pelo GOIÁS. Forçar equivalência 1:1 destruiria informação real. | sim |
| `aggregate_stats` | `player_club_stats` | **não — mesma ressalva**: `player_club_stats` só existe pro Goiás hoje; `aggregate_stats` cobre qualquer clube (ex.: Al-Rayyan do Rodrigo Tabata) | sim |
| `national_teams` | (nenhuma tabela canônica ainda) | não aplicável | sim |

## 11. Mudanças Flutter mínimas necessárias (feitas)

- `CareerPlayer` ganhou `final String? personId` ([career_models.dart](goias-app/lib/features/arena/games/career_path/career_models.dart)) — nullable, incluído em `props`, zero mudança visual.
- `CareerPlayerRepository._map()` agora lê `row['person_id'] as String?` e passa pro model — `select()` inclui `person_id` na lista de colunas.
- Fallback `career_players.dart`: as 30 entradas ganharam `personId: '<uuid>'` (21) ou `personId: null` (9), gerado programaticamente a partir do mapping (nunca digitado à mão), verificado 1:1.
- **Nenhuma UI, navegação, texto visual ou gameplay foi alterado.**

**Dependência de ordem importante**: como a migration `person_id` ainda **não foi aplicada**, o `.select('...person_id')` do repository vai falhar contra o Supabase atual (coluna não existe → PostgREST 400) até a migration rodar — o app cai no fallback local automaticamente (mesmo comportamento de "sem rede", já tratado pelo try/catch existente), então não há crash, só 100% fallback até a migration ser aplicada. Sinalizando isso explicitamente porque é uma dependência real de ordem de deploy, não um bug.

## 12. Comparações por name/slug perigosas encontradas

Revisei toda comparação de nome/slug dentro do fluxo de `career_players`:
- `CareerPathCubit._find(id)`, `_shownThisSession`, progresso, ranking (`itemId: player.id`) — todos usam `player.id` (a CHAVE DO JOGO, slug estável), nunca nome. **Seguro** — é exatamente a separação que o pedido quer (chave de jogo ≠ identidade de pessoa).
- `CareerPathCubit.isCorrect()` compara `normalizeName(guess)` contra `player.acceptedAnswers` — isso é o MECANISMO DE GAMEPLAY (usuário digita um nome, compara com respostas aceitas), não uma decisão de "é a mesma pessoa". **Não é perigoso, é o jogo em si.**
- **Achado real, fora de escopo desta etapa**: `career_path_page.dart` (`_CareerPathViewState.initState`, linhas 74-100) constrói um autocomplete que **funde por nome normalizado** dois datasets DIFERENTES e sem relação de identidade entre si: `goiasPlayers` (a lista de ~215 nomes de `goias_players.dart`, usada por OUTRO minigame) e os 30 `career_players`. Hoje isso não quebra nada porque a ordem de inserção sempre faz `career_players` "vencer" qualquer colisão de nome normalizado (inserido por último no `_resolveMap`, e primeiro no dedup de `_suggestions`) — mas é uma resolução de identidade por TEXTO puro, sem `person_id` nenhum envolvido, estruturalmente frágil se `goias_players.dart` algum dia referenciar uma pessoa DIFERENTE sob um nome curto igual. **Não corrigido nesta etapa** (pertence a quando `goias_players.dart`/F3-F4 também ganharem `person_id` — corrigir agora seria mexer em outra feature, fora do escopo declarado de F1).

## 13. Fallback Dart/local

`career_players.dart` (const `careerPlayers`) recebeu `personId` nas 30 entradas — Supabase runtime e fallback local agora resolvem a MESMA pessoa (quando resolvida), sem remover o fallback (ele continua a rede de segurança de sempre).

## 14. RLS

**Auditado antes E depois — idêntico**, porque as 2 migrations só usam `ALTER TABLE ... ADD COLUMN`/`ADD CONSTRAINT`, nunca tocam GRANT/POLICY:

```
relrowsecurity: true
pg_policies: "read career players" (SELECT) — a única, inalterada
role_table_grants (anon/authenticated): INSERT/SELECT/UPDATE/DELETE/TRUNCATE/
  REFERENCES/TRIGGER — GRANT amplo pré-existente, mais permissivo que o
  padrão "revoke all + grant select" usado desde a Etapa A. Isto é
  PRÉ-EXISTENTE (a tabela nasceu antes desse padrão mais rígido) — não
  faz parte desta migração, não fechei/corrigi agora (mudaria
  comportamento de acesso, que o pedido explicitamente proíbe nesta
  etapa). RLS com política só-SELECT já bloqueia escrita não autorizada
  na prática, apesar do GRANT bruto ser mais largo — sinalizando como
  observação, não como correção.
```

## 15. Migration proposta

Duas migrations aditivas (schema separado do backfill, conforme sugerido):

**`20260902140000_add_person_id_to_career_players.sql`**
```sql
alter table public.career_players
  add column if not exists person_id uuid references public.people(id);

alter table public.career_players
  add constraint career_players_person_id_key unique (person_id);

create index if not exists career_players_person_id_idx on public.career_players (person_id);
```
`person_id` **nullable** (9 de 30 ainda não resolvidas). `UNIQUE(person_id)` — auditado, não suposto: `career_players` é genuinamente 1 linha por jogador (nunca 1 linha por trajetória/edição), e as 21 RESOLVED têm 21 `person_id` distintos, sem colisão nenhuma. `UNIQUE` aceita múltiplos `NULL` (semântica padrão do Postgres), não trava as 9 UNRESOLVED.

**`20260902150000_backfill_career_players_person_id.sql`** — 21 `UPDATE ... SET person_id = '<uuid literal>'::uuid WHERE id = '<slug>'`, um por linha RESOLVED, **nunca** `select`/`ilike`/`canonical_name` — testado explicitamente que o SQL executável não contém nenhum desses padrões.

## 16. Testes JS

`tooling/multiclub/test_career_players_person_mapping.mjs` — **31 testes, 0 falhando**, cobrindo: números gerais, os 10 casos obrigatórios do pedido (incluindo a confirmação explícita de que Nicolas Godinho **não existe** em `career_players`), homônimos (danilo/michael/erik resolvidos certo; fabiano/nicolas confirmados ausentes), múltiplas passagens (10 casos, nunca fragmentadas), os 9 UNRESOLVED com motivo auditável, SQL sem `ilike`/`select`, UUIDs do backfill 100% rastreáveis ao mapping, nenhuma tabela canônica tocada.

**Suíte completa `tooling/multiclub/test_*.mjs`: 295 passando, 0 falhando** (264 anteriores + 31 novos — excede o esperado "≥264").

## 17. `flutter analyze`

```
Analyzing goias-app...
No issues found! (ran in 118.2s)
```

## 18. `flutter test`

```
00:19 +729 ~1: All tests passed!
```
729 passando, 1 skip — nenhuma regressão. Não existem testes Flutter dedicados a `career_path` hoje (confirmado por busca — `test/features/arena/` não tem pasta `career_path`); não criei nenhum nesta etapa (não pedido, e F1 é sobre identidade, não sobre cobertura de teste).

## 19. `git diff --stat` / `git status`

```
 lib/.../career_path/career_models.dart              | 10 ++
 lib/.../career_path/career_players.dart              | 30 ++
 lib/.../career_path/data/career_player_repository.dart|  3 +-
 lib/.../store_entry_card.dart                        |  2 +-  (pré-existente, fora de escopo)
 4 files changed, 43 insertions(+), 2 deletions(-)
```
```
 M lib/features/arena/games/career_path/career_models.dart
 M lib/features/arena/games/career_path/career_players.dart
 M lib/features/arena/games/career_path/data/career_player_repository.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente)
?? _competitions_pkg/                                              (pré-existente)
?? data_export/goias/player_reconciliation/career_players_person_mapping.json
?? data_export/goias/player_reconciliation/career_players_person_mapping_stats.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (Etapa E — ainda não commitado, decisão do usuário)
?? migration_dump.txt                                              (padrão de exclusão)
?? supabase/migrations/20260902140000_add_person_id_to_career_players.sql
?? supabase/migrations/20260902150000_backfill_career_players_person_id.sql
?? tooling/multiclub/build_career_players_person_mapping.mjs
?? tooling/multiclub/generate_career_players_person_migration.mjs
?? tooling/multiclub/test_career_players_person_mapping.mjs
```
Nada staged, nada commitado, nada aplicado no Supabase. As 27 migrations já aplicadas continuam intocadas.

---

**PARE.** Nenhum `db push`/`commit`/`git push` feito. `career_stats` (F2), `squad_members` (F4), `guess_players` (F3), `lineup_matches`, flavors e redesign — nenhum tocado, conforme instruído.

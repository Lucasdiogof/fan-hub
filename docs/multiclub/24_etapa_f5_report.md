# Etapa F5 — `goiasSquad` / Escalação da Torcida → `person_id` (design + tooling, NÃO aplicado)

Data: 2026-09-02
Status: **PARADO PARA REVISÃO. Nenhum `db push` (0 migrations propostas), nenhum commit, nenhum `git push`.**

---

## 1. Runtime completo do `crowd_lineup`

| Arquivo | Papel | Usos de `SquadPlayer.id` |
|---|---|---|
| `domain/goias_squad.dart` | Roster hardcoded (31 jogadores), fonte de verdade dada pelo usuário | define `id` (slug) |
| `domain/squad_player.dart` | Model | campo `id` |
| `domain/position_compatibility.dart` | Camada tática (score de encaixe por posição) | nenhum — opera só em `allowedPositions` |
| `data/supabase_crowd_lineup_repository.dart` | `getMyVote`/`submitVote`/`getCrowdLineup`, serializa `LineupVote.playerIdBySlot` pro Supabase, chama RPC `crowd_lineup`, resolve `squadById[pid]` na leitura | **PERSISTENCE_KEY** (`slots[i].pid`) + **IDENTITY** (lookup pro display) |
| `domain/lineup_vote.dart` | `{formationId, playerIdBySlot: Map<int,String>}` | **GAMEPLAY_KEY** |
| `domain/crowd_lineup.dart` | `CrowdSlotResult.player` (o `SquadPlayer` resolvido) | **DISPLAY** |
| `presentation/cubit/crowd_lineup_cubit.dart` | `selectFormation`/`selectPlayer`/`submit`, usa `squadById[pid]` pra compatibilidade ao trocar formação | **GAMEPLAY_KEY** + **IDENTITY** |
| `presentation/cubit/crowd_lineup_state.dart` | `slots: Map<int,String>`, `pickedIds`, `playerAt()` | **GAMEPLAY_KEY** |
| `presentation/widgets/player_picker_sheet.dart` | Bottom sheet de seleção, retorna `player.id` | **GAMEPLAY_KEY** (`pickedIds.contains`, retorno) + **DISPLAY** |
| `presentation/widgets/escale_tab.dart` | Slot editável, `showPlayerPicker(currentPlayerId: player?.id)` | **GAMEPLAY_KEY** + **DISPLAY** |
| `presentation/widgets/crowd_tab.dart` | Exibe resultado agregado | **DISPLAY** apenas |
| `presentation/widgets/player_avatar.dart` | Foto/fallback por número | **ASSET_KEY** (mas ver item 14 — não usado de fato hoje) |
| `presentation/widgets/formation_selector.dart` | Seletor de formação | `Formation.id`, não relacionado a `SquadPlayer` |
| `presentation/open_crowd_lineup.dart` | Entry point (Arena/Home) | `Match.id`, não relacionado |

Nenhum uso encontrado fora do próprio diretório `lib/features/crowd_lineup/` — confirmado via busca no `lib` inteiro por `goiasSquad`/`squadById`/`SquadPlayer` (9 arquivos, todos dentro da feature).

## 2-5. Números reais

```
goiasSquad:      31 jogadores
squad_members:   31 jogadores
ids compartilhados: 31 / 31 (100% — MESMO id-space exato, nenhuma diferença)
ids só no goiasSquad: 0
ids só em squad_members: 0
RESOLVED (via F4): 31/31
UNRESOLVED/AMBIGUOUS/OUT_OF_SCOPE: 0
```

Achado real (não forçado): `goiasSquad` e `squad_members` usam **exatamente o mesmo conjunto de 31 slugs** — não foi preciso nenhuma heurística de correspondência, o mapping é uma cópia direta `goiasSquad.id → squad_members.id → squad_members.person_id`.

## 6. Mapping

`data_export/goias/player_reconciliation/crowd_lineup_person_mapping.json` — 31 entradas, shape:
```json
{
  "squadPlayerId": "tadeu",
  "personId": "e2507d62-8cb5-5152-af56-f67464196ac6",
  "canonicalName": "Tadeu Antônio Ferreira",
  "source": "squad_members_person_mapping",
  "status": "RESOLVED",
  "notes": null
}
```
`crowd_lineup_person_mapping_stats.json`: `{"total":31,"RESOLVED":31,"UNRESOLVED":0,"AMBIGUOUS":0,"OUT_OF_SCOPE":0,"duplicatePersonIdsAmongResolved":0,"allResolved100pct":true}`.

## 7. Casos sensíveis

| squadPlayerId | canonicalName (F4) | Confere |
|---|---|---|
| nicolas | Nicolas Vichiatto da Silva | ✅ nunca Godinho |
| danilo | Danilo Cunha da Silva | ✅ nunca Gabriel |
| murilo_camara | Murilo Camara Saquetti Chimelo Pereira | ✅ |
| murillo_victorio | Murillo Carvalho Victorio | ✅ UUID distinto de murilo_camara |
| tadeu | Tadeu Antônio Ferreira | ✅ |
| luiz_felipe | Luiz Felipe do Nascimento dos Santos | ✅ |
| rodrigo_soares | Rodrigo Alves Soares | ✅ |
| djalma | Djalma Antônio da Silva Filho | ✅ |
| lourenco | João Paulo Ferreira Lourenço | ✅ |
| lucas_rodrigues | Lucas Rodrigues Moreira Costa | ✅ |

Dieguinho (item 6 do pedido): **confirmado ausente** tanto do `goiasSquad` quanto de `squad_members` (mesma ausência já reportada na F4) — nenhuma divergência de roster a reportar.

## 8. Cardinalidade

`1 goiasSquad.id → 1 person_id`: sim, 31/31 (trivial — é o mesmo mapping 1:1 já provado na F4, herdado, não recalculado). `1 person_id → quantos SquadPlayer`: **0 duplicado** — 31 `personId` distintos pros 31 jogadores (confirmado programaticamente, não assumido).

## 9. Posições — gameplay vs canonical

Diff completo `goiasSquad.allowedPositions` × `player_positions` (via `personId`), por jogador, preservando ordem:

**31/31 = `MATCH_EXACT_ORDER`** (mesma lista, mesma ordem, para todos os 31). Zero `SUBSET`/`SUPERSET`/`DIVERGENCE`.

Isso não é coincidência: o próprio comentário de `player_positions_seed.json` (Etapa C) já documenta `goias_squad.dart` como **fonte-ouro** das posições canônicas do Goiás — ou seja, `player_positions` foi originalmente DERIVADO de `goiasSquad`, não o contrário. Os dois "conceitos" (gameplay vs canônico) hoje descrevem exatamente o mesmo dado porque nasceram da mesma fonte — a separação semântica (item 8 do pedido) segue válida como princípio de design (podem divergir no futuro se um dos dois for editado independentemente), só não há divergência real hoje.

## 10. Mudança proposta em `SquadPlayer`

Aplicada (ver `git diff` no item 23):
```dart
class SquadPlayer {
  const SquadPlayer({
    required this.id,
    required this.personId,
    required this.name,
    required this.shirtNumber,
    required this.allowedPositions,
    this.imageUrl,
  });

  final String id;       // slug — persistência/gameplay, nunca muda
  final String personId; // people.id — identidade real
  ...
}
```
`personId` é **`String` non-null** (não `String?`) — porque a auditoria confirmou 100% do roster resolvido (item 5), condição explícita do pedido pra não usar nullable.

## 11. Persistência atual dos votos

`match_lineup_votes` (Supabase, `supabase/crowd_lineup.sql`): `id uuid, match_id text, user_id uuid, formation text, slots jsonb, created_at, updated_at`, `unique(match_id, user_id)`. `slots` é um array jsonb de `{"i": <slotIndex>, "pid": "<slug>"}` — `pid` é **texto livre dentro do jsonb**, nunca uma coluna tipada, nunca uma FK. A RPC `crowd_lineup(p_match_id)` agrega por `s ->> 'pid'` (texto). Confirmado: **nada no banco depende de `pid` ser um UUID** — é só uma chave de agrupamento textual.

## 12. Confirmação de que o slug permanece

Testado explicitamente (`test/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit_test.dart`): monta um voto completo via `CrowdLineupCubit.selectPlayer` + `submit()`, captura o `LineupVote` que seria enviado ao repositório, e afirma que todo valor em `playerIdBySlot` (a) existe em `squadById` (é um slug conhecido) e (b) **não** casa com o padrão de UUID. `SquadPlayer.id` nunca foi alterado — mesmos 31 slugs de antes da F5 (testado via `test_crowd_lineup_person_mapping.mjs`, seção 4).

## 13. Banco/RPCs relacionados — auditado, nada tocado

- `public.match_lineup_votes`: `id, match_id, user_id, formation, slots (jsonb), created_at, updated_at`. RLS on, 3 policies (`read/insert/update own vote`, todas `auth.uid() = user_id`). Índice em `match_id`. **Nenhuma coluna de player id fora do jsonb** — nada pra migrar.
- `public.crowd_lineup(p_match_id text)`: `security definer`, agrega votos anonimamente, devolve `total_votes`/`formations`/`slots` — opera inteiramente sobre `s ->> 'pid'` (texto), sem qualquer referência a `people`/`person_id`.
- Nenhuma outra tabela/view/function relacionada a `crowd_lineup` encontrada.

## 14. Assets

**Achado não previsto pelo pedido**: `SquadPlayer.imageUrl` existe no model mas **nunca é populado** em `goiasSquad` (nenhum dos 31 construtores passa `imageUrl`) — `PlayerAvatar` sempre cai no fallback de número da camisa. `squadPhotoAssets` (`lib/features/squad/domain/squad_photos.dart`) **não é referenciado em nenhum arquivo de `crowd_lineup`** (confirmado por grep) — diferente do que uma memória de sessão anterior registrava ("3-feature shared photo hub" incluindo crowd_lineup); essa claim estava desatualizada/incorreta pra esta feature especificamente e será corrigida na memória do projeto. F5 não mexeu nisso — `imageUrl` continua `null` sempre, `squadPhotoAssets` continua fora do escopo de `crowd_lineup`.

## 15. Drift `goiasSquad` × `squad_members`

Comparado nome, número de camisa, posição primária e roster membership pros 31 pares:
- **Roster membership**: 31/31 idêntico (item 3).
- **Posição primária**: 31/31 idêntico (item 9 — `MATCH_EXACT_ORDER` inclui a primária).
- **Nome/número de camisa**: não comparado numericamente nesta rodada (fora do escopo estrito do pedido, que pediu "reporte divergências" sem exigir diff formal) — inspeção visual dos 31 pares não achou nenhuma discrepância óbvia de nome/grafia entre `goiasSquad.name` e `squad_members` (ambos escritos pelo mesmo autor/fonte). Se quiser um diff formal número-a-número, é uma extensão pequena pra uma rodada futura.

`squad_members` **não virou runtime source** do `crowd_lineup` — o comentário "`goiasSquad` é fonte da verdade fornecida pelo usuário" continua no arquivo, intocado.

## 16. Tooling criado (`tooling/multiclub/`)

- `build_crowd_lineup_person_mapping.mjs` — lê `squad_members_person_mapping.json` (F4), filtra pros 31 ids do `goiasSquad` (lista literal, comentada como não-fonte-de-parsing do `.dart`), escreve `crowd_lineup_person_mapping.json` + `_stats.json`. Nunca resolve por nome.
- `apply_crowd_lineup_person_mapping.mjs` — injeta `personId: '<uuid>'` após cada `id: '<slug>',` em `goias_squad.dart`. Aborta sem escrever se o mapping não estiver 100% RESOLVED, se algum id do arquivo não tiver entrada RESOLVED, ou **se o arquivo já tiver `personId:`** (guarda de idempotência — bug pego e corrigido durante a construção, ver item 17).
- `test_crowd_lineup_person_mapping.mjs` — 16 testes.

## 17. Testes de mapping (JS) — 16 testes, 0 falhas

Cobre: cardinalidade goiasSquad×squad_members, 100% RESOLVED via F4 (nunca por nome), 0 personId duplicado, os 10 casos sensíveis + Dieguinho, o `.dart` REAL (não só o JSON) batendo 1:1 com o mapping, todos os 31 `id` com `personId` correspondente, os 31 slugs originais preservados, ausência de `person_id` em `supabase/crowd_lineup.sql`, 0 migration nova, reprodutibilidade do builder, e idempotência do apply.

**Bug pego durante a construção**: a 1ª versão de `apply_crowd_lineup_person_mapping.mjs` não detectava reaplicação — rodar 2x duplicaria as linhas `personId:`. Corrigido adicionando uma checagem que aborta se o arquivo já contém `personId:` antes de escrever qualquer coisa; testado explicitamente (o teste roda o apply de novo sobre o arquivo já modificado e confirma que ele aborta E que o arquivo continua com exatamente 31 `personId:`, não 62).

## 18. Teste de persistência mantendo o slug

`test/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit_test.dart` — monta uma escalação completa via `selectPlayer`, chama `submit()`, captura o `LineupVote` no repositório fake e confirma que **todo** valor de `playerIdBySlot` é um slug conhecido (`squadById.containsKey`) e nunca um UUID (regex negativo). 2º teste confirma que, a partir do slug persistido hoje (`'tadeu'`), dá pra resolver `squadById['tadeu']!.personId` == UUID canônico — o "benefício" da F5 (item 23 do pedido) sem alterar o payload.

## 19. `flutter analyze`

```
No issues found!
```
(1 correção necessária: `test/features/crowd_lineup/domain/position_compatibility_test.dart` construía `SquadPlayer` diretamente sem `personId` — ajustado pra passar um valor sintético, já que o campo é non-null.)

## 20. `flutter test`

**737 passed, 1 skipped** (era 729/1 antes da F5 — +8 testes novos: 6 em `goias_squad_test.dart`, 2 em `crowd_lineup_cubit_test.dart`). 0 falhas.

## 21. JS total

**405 passaram, 0 falharam** em `tooling/multiclub/test_*.mjs` (12 arquivos) — eram 389 antes da F5, +16 novos.

## 22. Migrations propostas — **0** (confirmado, não estimado)

Nenhuma migration Supabase foi gerada. `match_lineup_votes.slots` é `jsonb` livre — `pid` nunca foi uma coluna tipada nem uma FK, então não há schema nenhum pra alterar. `personId` existe só no lado Dart (`SquadPlayer`), nunca persistido. Testado explicitamente (`supabase/crowd_lineup.sql` sem `person_id`; contagem de arquivos em `supabase/migrations/` confirmada em 35, igual a antes da F5).

## 23. `git diff --stat`

```
 lib/features/crowd_lineup/domain/goias_squad.dart  | 31 ++++++++++++++++++++++
 lib/features/crowd_lineup/domain/squad_player.dart | 11 ++++++++
 .../presentation/widgets/store_entry_card.dart     |  2 +-  (pré-existente, não relacionado)
 .../domain/position_compatibility_test.dart        |  1 +
 4 files changed, 44 insertions(+), 1 deletion(-)
```

## 24. `git status`

```
 M lib/features/crowd_lineup/domain/goias_squad.dart
 M lib/features/crowd_lineup/domain/squad_player.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, não tocado)
 M test/features/crowd_lineup/domain/position_compatibility_test.dart
?? data_export/goias/player_reconciliation/crowd_lineup_person_mapping.json
?? data_export/goias/player_reconciliation/crowd_lineup_person_mapping_stats.json
?? test/features/crowd_lineup/domain/goias_squad_test.dart
?? test/features/crowd_lineup/presentation/cubit/
?? tooling/multiclub/apply_crowd_lineup_person_mapping.mjs
?? tooling/multiclub/build_crowd_lineup_person_mapping.mjs
?? tooling/multiclub/test_crowd_lineup_person_mapping.mjs
```
Untracked não relacionados a esta etapa (pré-existentes): `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md`.

---

## Limites respeitados

- Zero mudança de UI (campo, formações, bonecos, camisas, percentuais, layout, ranking) — confirmado, nenhum widget de apresentação tocado.
- `lineup_matches` (histórico) não tocado — fora de escopo, etapa separada.
- `goias_players.dart` (risco de autocomplete da F1) não tocado.
- `squad_members` não virou runtime source de `crowd_lineup` — só ganhou um mapping paralelo.
- Nenhum voto histórico migrado, nenhum RPC alterado, nenhum payload mudado.
- `db push`, commit, `git push` **não executados** — aguardando revisão.

---

## 25. Endurecimento final — drift real `name`/`shirtNumber` (aprovado após revisão, antes do commit)

Item 1 do relatório original ("`name`/`shirt_number` — apenas inspeção visual") virou auditoria programática.

**Fonte do lado `squad_members`**: `data_export/goias/squad_members.json` — o MESMO export já usado/validado pela F4 (é a fonte que `build_squad_members_person_mapping.mjs` lê), nunca reimportado. Pareamento sempre `goiasSquad.id -> squad_members.id` (slug->slug), nunca por nome.

**Novo módulo puro** `tooling/multiclub/crowd_lineup_squad_drift.mjs`: `extractSquadPlayerFields(dartSrc)` (lê o `.dart` REAL via regex — `id`, `personId`, `name`, `shirtNumber`), `classifyNameDrift` (`NAME_MATCH` string idêntica / `NAME_FORMAT_ONLY` só acento-caixa-espaço via forma normalizada / `NAME_DIVERGENCE` qualquer outra diferença — abreviação editorial **nunca** auto-classificada como `FORMAT_ONLY`, cai em `DIVERGENCE` pra revisão humana, por design), `classifyShirtDrift` (`SHIRT_MATCH`/`SHIRT_DIVERGENCE`), `computeSquadDrift`.

**Script de auditoria** `tooling/multiclub/audit_crowd_lineup_squad_drift.mjs` — só leitura, nunca corrige `goiasSquad` nem `squad_members.json`; persiste `data_export/goias/player_reconciliation/crowd_lineup_squad_drift_report.json`.

### Resultado real (31/31 slugs compartilhados)

```
NAME_MATCH:        31
NAME_FORMAT_ONLY:   0
NAME_DIVERGENCE:    0

SHIRT_MATCH:       31
SHIRT_DIVERGENCE:   0
```

Nenhuma divergência encontrada — as duas fontes independentes (mantidas manualmente) estão, hoje, 100% alinhadas em nome e número de camisa. Resultado real, não forçado: não houve necessidade de classificar nenhum caso como `NAME_FORMAT_ONLY` (todos os 31 nomes são strings idênticas byte a byte entre `goiasSquad.name` e `squad_members.name`).

**Nenhuma correção automática foi feita** em `goiasSquad` ou `squad_members` — não havia nada pra corrigir.

### Testes adicionados

12 novos em `tooling/multiclub/test_crowd_lineup_person_mapping.mjs` (seção 7): unidade de `classifyNameDrift`/`classifyShirtDrift`/`normalizeNameForComparison` (incluindo o caso de abreviação editorial explicitamente NÃO virando `FORMAT_ONLY`), `extractSquadPlayerFields` no `.dart` real, `computeSquadDrift` no dado real batendo exatamente `{31,0,0,31,0}`, o JSON persistido batendo com o recomputado agora, uma trava pra se algum dia `NAME_DIVERGENCE`/`SHIRT_DIVERGENCE` deixar de ser 0 (o teste falha, nunca silencia um drift futuro), confirmação de que a auditoria não altera nenhum dos 2 arquivos-fonte, e reprodutibilidade byte a byte.

Total `tooling/multiclub/test_*.mjs`: **417 passando, 0 falhando** (405 antes + 12 novas). `flutter analyze`: 0 issues (nenhuma mudança Dart nesta rodada). `flutter test`: 737 passed / 1 skip, inalterado.

**Autorizado**: commit controlado desta etapa (F5 completa, incluindo este endurecimento).

---

**F5 APROVADA E COMMITADA** (ver hash na seção seguinte se este arquivo for atualizado pós-commit; caso contrário, ver mensagem de commit `feat(multiclub): link crowd lineup roster to canonical people`). Nenhum `db push`, nenhum `git push`.

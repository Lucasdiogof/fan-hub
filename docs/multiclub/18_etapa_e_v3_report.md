# 18 — Etapa E v3: resolução em 2 etapas, source_namespace, kickoff sem sentinela

> Responde ponto a ponto às 3 correções finais de fundação recebidas sobre a v2. Nada aplicado no Supabase, nada commitado, nenhum código Flutter tocado, nenhuma das 23 migrations já aplicadas alterada. **PARE — aguardando revisão.**

## 1. Algoritmo real de independent-source match

`tooling/multiclub/match_registry.mjs` ganhou uma 2ª etapa. Fluxo completo em `resolveMatch(registry, {anchors, descriptor})`:

- **Etapa 1 — `resolveMatchAnchors`**: exact match por `(sourceNamespace, sourceRef)` — evidência mais forte, inalterada em espírito da v2 (só a chave de identidade mudou de `sourceType` pra `sourceNamespace`, ver item 3).
- **Etapa 2 — `resolveMatchCandidate`**: só chamada quando a etapa 1 devolve `'new'` (nenhum anchor conhecido). Compara `descriptor` (`homeIdentity`, `awayIdentity`, `kickoff`, `competition`, `season`) contra o `descriptor` guardado em cada entrada ACTIVE do registry:
  - identidade de lado (`sideIdentity({clubCanonicalKey, teamName})`) — compara `clubKey` quando os 2 lados já conhecem o clube, senão cai pro nome normalizado (auxiliar, conforme pedido).
  - sobreposição de intervalo de kickoff (`kickoffIntervalsOverlap`, ver item 6).
  - competição/temporada só DESQUALIFICAM quando os 2 lados conhecem o valor e discordam — nunca exigidos quando um dos lados não sabe.
  - **placar nunca entra na comparação** — testado explicitamente (`resolveMatchCandidate NUNCA usa placar como identidade`).
- Resultado: 0 candidatos → `NEW_MATCH`; 1 → `EXISTING_MATCH` (acrescenta o anchor novo à entrada, `appendAnchors`); 2+ → `BLOCKED_AMBIGUOUS_MATCH`.

## 2. Teste cross-club REAL

`test_player_match_appearances.mjs`, seção 15b, 4 testes novos:
- **`cross-club independente`**: registry só tem uma entrada Goiás (`goias_passport:pe_abc`). Uma 2ª fonte (`juventude_fixture_history:jogo_91827`) chega com **zero** anchors em comum — `resolveMatchAnchors` confirma `'new'` explicitamente antes de tentar a etapa 2 — mas mesmos lados (Goiás/Juventude) e mesma janela de kickoff. `resolveMatchCandidate` e o orquestrador `resolveMatch` completo confirmam `EXISTING_MATCH` com o **mesmo** `matchId`, e `registry.entries.length` continua 1 depois do `appendAnchors`.
- **`cross-club ambíguo`**: Goiás x Juventude ocorreu 2x numa janela `MONTH` compatível (2 entradas já registradas, dados insuficientes pra distinguir por mês). Uma 3ª fonte sem anchor compartilhado → `BLOCKED_AMBIGUOUS_MATCH`, `result.matches.length === 2`, nunca escolhido.
- **`0 candidatos`** → `NEW_MATCH`.
- **`placar nunca é identidade`** → confirmado estruturalmente (a assinatura de `descriptorFor`/`resolveMatchCandidate` nem aceita esse campo).

## 3. `source_namespace`

`match_source_refs` agora tem `source_type` (semântico: `LINEUP_MATCH`/`PASSPORT_MATCH`/`PROVIDER_FIXTURE`, renomeei `ONEFOOTBALL`→`PROVIDER_FIXTURE` pra bater com o exemplo do pedido) **separado** de `source_namespace` (identidade real: `goias_lineup_curated`, `goias_passport`, e o exemplo `juventude_passport`/`onefootball` ficam prontos pro futuro). `UNIQUE(source_namespace, source_ref)` substitui o antigo `UNIQUE(source_type, source_ref)`. Testado: `goias_passport:abc` e `juventude_passport:abc` coexistem sem colisão; o mesmo `(namespace, ref)` reaproveitado por 2 entradas é detectado por `validateMatchRegistryIntegrity` (lança erro).

## 4. Schema final `match_source_refs`

```sql
create table public.match_source_refs (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  source_type text not null check (source_type in ('LINEUP_MATCH','PASSPORT_MATCH','PROVIDER_FIXTURE')),
  source_namespace text not null,
  source_ref text not null,
  source_club_id uuid references public.clubs(id),
  created_at timestamptz not null default now(),
  unique (source_namespace, source_ref)
);
```
**`external_match_id` removida.** Análise pedida (item 9): nas 2 fontes reais de hoje, `external_match_id` sempre guardava exatamente o mesmo valor de `source_ref` — nenhum caso real onde as duas colunas divergiam. Manter as duas seria exatamente o "duas colunas que acabarão guardando o mesmo id" que o pedido queria evitar. Se um provider futuro realmente precisar de um id bruto distinto do `source_ref` interno, a coluna volta numa migration própria, motivada por um caso real — não antecipada aqui sem uso.

## 5. Stable ID — confirmado independente do resolver

`matches.id = uuidV5(MATCHES_UUID_NAMESPACE, canonicalMatchKey)`, `canonicalMatchKey` sequencial, atribuído **uma vez** em `registerNewMatch`. Nem a etapa 1 nem a etapa 2 do resolver participam da geração do UUID — elas só decidem **qual entrada reusar**. Testado (seção 15): corrigir data, adicionar horário, renomear time, reordenar anchors — todos preservam o mesmo `matchId`.

## 6. Schema temporal sem sentinela

`matches.kickoff_date` agora é **NULLABLE**, sem nenhum valor fabricado:

| Precisão | `kickoff_year` | `kickoff_month` | `kickoff_date` | `kickoff_at` |
|---|---|---|---|---|
| YEAR | not null | **NULL** | **NULL** | NULL |
| MONTH | not null | not null | **NULL** | NULL |
| DATE | not null | not null | not null | NULL |
| DATETIME | not null | not null | not null | not null |

4 CHECK constraints impõem exatamente essa tabela (`kickoff_precision='DATETIME' = kickoff_at not null`, `kickoff_precision in ('DATE','DATETIME') = kickoff_date not null`, `kickoff_precision='YEAR' = kickoff_month is null`, mais 2 coerência: quando `kickoff_date` existe, seu ano/mês têm que bater com `kickoff_year`/`kickoff_month`). Testado: `2003_juventude_brA_reacao` (precisão YEAR) tem `kickoffDate: null` no seed real, e um teste dedicado varre **todo** o dataset confirmando 0 sentinelas em qualquer linha YEAR/MONTH — inclusive verificando o SQL gerado linha a linha (`null::date`, nunca uma string de data).

## 7. Regras de precisão pro resolver estrutural

`tooling/multiclub/kickoff_precision.mjs` (novo módulo): kickoff vira um **intervalo** `[inicioDia, fimDia]` — YEAR = ano inteiro, MONTH = mês inteiro, DATE/DATETIME = 1 dia só. `kickoffIntervalsOverlap(a, b)` decide se 2 kickoffs de precisão IGUAL ou DIFERENTE podem representar a mesma janela — usado pela etapa 2 do resolver (item 1). Nunca precisou de range do Postgres — é só aritmética de dias-desde-epoch em JS/comparação de coluna em SQL, como pedido.

## 8. Baseline/delta atualizado

`recompute_player_club_stats.mjs` reescrito em cima de `compareKickoffBoundary(candidateKickoff, baselineKickoff)`:
- candidate estritamente antes → nunca conta.
- `canonicalMatchId === asOfMatchId` → nunca conta de novo.
- candidate estritamente depois → conta (dedup garante idempotência).
- **intervalos se cruzam** (partida coarse cruzando a fronteira do baseline, OU mesmo dia sem DATETIME confiável nos 2 lados) → `AMBIGUOUS_BOUNDARY`, nunca resolvido automaticamente.

Testado explicitamente o caso pedido: um candidate `YEAR 2026` contra um baseline `DATE 2026-08-28` → o intervalo do candidate (jan-dez/2026) cruza o baseline → `AMBIGUOUS_BOUNDARY`, `delta=0`. Partidas históricas `YEAR`/`MONTH` continuam úteis como `player_match_appearances` — só não entram no delta automático quando cruzam a fronteira; longe dela (backfill de anos anteriores) somam como "antes" sem ambiguidade nenhuma, normalmente.

## 9. Confirmação da regra do grace

**Confirmado — grace é 100% diagnóstico, nunca decide linkage.** Extraí a lógica pra um módulo próprio testável, `tooling/multiclub/spell_link.mjs` (antes vivia inline em `build_player_match_appearances_seed.mjs`):
- `resolveSpellForDate`/`overlapCandidates` (decidem o `spell_id` de verdade) **nunca importam nem referenciam** `NEAR_BOUNDARY_GRACE_MONTHS`.
- Só `classifySpellGap`/`nearestBoundaryInfo` (diagnóstico, categorias B vs. C do relatório) usam a constante — e só depois que `resolveSpellForDate` já decidiu `null`.

Prova estrutural automatizada: um teste lê o próprio código-fonte de `spell_link.mjs` e confirma que o corpo de `resolveSpellForDate` não contém a palavra "GRACE". Prova comportamental: um cenário sintético com uma pessoa cujo spell (precisão YEAR) termina em 2020 e uma partida em março/2021 (3 meses de gap, dentro do grace de 6) — `resolveSpellForDate` devolve `null` mesmo assim; só `classifySpellGap` (diagnóstico) classifica isso como categoria B.

## 10. Números de matches/source refs

| Métrica | Valor |
|---|---|
| `matches` | 31 (inalterado) |
| Precisão: YEAR / MONTH / DATE / DATETIME | 10 / 0 / 6 / 15 |
| VERIFIED / PARTIAL | 21 / 10 |
| `match_source_refs` total | 46 |
| `goias_lineup_curated` | 31 |
| `goias_passport` | 15 |
| Matches com 1 fonte / 2+ fontes | 16 / 15 |
| `byResultKind` (este run — 1ª vez, registry vazio) | `NEW_MATCH: 31` (esperado — todas as 31 são vistas pela 1ª vez; a resolução em 2 etapas só produziria `EXISTING_MATCH` num run FUTURO com dado já registrado, exercitado nos testes sintéticos da seção 15b) |

## 11. Appearances

`matches=31`, `appearances=162` — **exatamente os mesmos números da v2**, confirmado por teste dedicado (item 13 do pedido: nada de tentar melhorar cobertura). 100% `STARTED`, 62/96 pessoas, 34 `BLOCKED`, 123 VERIFIED / 39 PARTIAL, 152 com `position_code`.

## 12. Unlinked spells

```
A) sem nenhum spell canônico Goiás .......... 82
B) boundary YEAR a <= 6 meses da partida ..... 0
C) data cai fora de todos os spells .......... 0
D) 2+ spells candidatos ambíguos ............. 0
```
**Confirmado**: idêntico à v2. O grace não interferiu — ver prova estrutural no item 9. 82/82 continua sendo categoria A, honesto (nenhuma pessoa real do dataset caiu em B/C/D nesta leva).

## 13. Testes

**259 passando, 0 falhando** em toda a suíte (`tooling/multiclub/test_*.mjs`) — 86 só em `test_player_match_appearances.mjs` (13 a mais que a v2), cobrindo especificamente:
- independent cross-club source (zero anchors, mesmo match) — seção 15b.
- ambiguous cross-club (zero anchors, 2+ candidatos) — seção 15b.
- source namespaces coexistindo / colidindo dentro do namespace certo — seção 15c.
- nullability temporal completa (YEAR/MONTH sem `kickoff_date`, DATE/DATETIME com, só DATETIME com `kickoff_at`) — seção 11b, varrendo TODO o dataset.
- "no sentinel": YEAR 2003 → `kickoffDate: null` confirmado, e o SQL gerado usa `null::date` literal — seção 11b.
- grace nunca auto-linka (estrutural + comportamental) — seção 8.
- `kickoffIntervalDays`/`kickoffIntervalsOverlap`/`compareKickoffBoundary` — seção 16, incluindo o caso "intervalo cruza a fronteira → AMBIGUOUS".

## 14. Migrations finais

Mesma numeração (conteúdo reescrito, ainda nunca aplicadas):
- `20260902100000_create_matches.sql` — `matches` (kickoff sem sentinela) + `match_source_refs` (source_namespace, sem external_match_id).
- `20260902110000_seed_goias_matches.sql` — regenerada (ordenação agora por intervalo de kickoff, nunca por string de data).
- `20260902120000_create_player_match_appearances.sql` — inalterada desde a v2 (source_role já aprovado, item 10 do pedido — não mexi).
- `20260902130000_seed_goias_player_match_appearances.sql` — regenerada (mesmos 162 valores).

## 15. Confirmação — 23 migrations antigas intactas

```
git ls-files supabase/migrations/ | wc -l   ->  23
git diff --stat -- supabase/migrations/     ->  vazio (só avisos de LF/CRLF do git, 0 diffs de conteúdo)
```

## 16. `git diff --stat`

```
 docs/multiclub/16_live_data_architecture.md        | ...  (inalterado desde a v2 — nenhum item desta rodada exigia mudança lá)
 lib/.../store_entry_card.dart                      |  2 +-  (PRÉ-EXISTENTE, não tocado, exclusão padrão)
 tooling/multiclub/live_data_model.mjs              | ...  (inalterado desde a v2)
```
(mesmo diff da v2 — nada desta rodada mexeu em arquivo tracked além dos 3 já listados na v2)

## 17. `git status`

```
 M docs/multiclub/16_live_data_architecture.md
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, fora de escopo)
?? _competitions_pkg/                                              (pré-existente, fora de escopo)
?? data_export/goias/player_reconciliation/*.json                  (7 arquivos, regenerados)
?? docs/multiclub/17_etapa_e_v2_report.md
?? docs/multiclub/18_etapa_e_v3_report.md
?? migration_dump.txt                                              (padrão de exclusão — nunca incluir)
?? supabase/migrations/20260902100000_create_matches.sql
?? supabase/migrations/20260902110000_seed_goias_matches.sql
?? supabase/migrations/20260902120000_create_player_match_appearances.sql
?? supabase/migrations/20260902130000_seed_goias_player_match_appearances.sql
?? tooling/multiclub/audit_match_identity.mjs
?? tooling/multiclub/build_matches_seed.mjs
?? tooling/multiclub/build_player_match_appearances_seed.mjs
?? tooling/multiclub/generate_matches_seed.mjs
?? tooling/multiclub/generate_player_match_appearances_seed.mjs
?? tooling/multiclub/kickoff_precision.mjs        (NOVO)
?? tooling/multiclub/match_registry.mjs
?? tooling/multiclub/matches_registry.json
?? tooling/multiclub/recompute_player_club_stats.mjs
?? tooling/multiclub/spell_link.mjs               (NOVO)
?? tooling/multiclub/test_player_match_appearances.mjs
```
Nada staged, nada commitado, nada aplicado no Supabase.

## Reprodutibilidade

Registry apagado e todo o pipeline (`build_matches_seed` → `generate_matches_seed` → `build_player_match_appearances_seed` → `generate_player_match_appearances_seed`) rerodado do zero — SQL das 2 migrations de seed e `matches_registry.json` saíram **byte-idênticos** ao run anterior.

**PARE** — aguardando revisão antes de qualquer commit ou `supabase db push`.

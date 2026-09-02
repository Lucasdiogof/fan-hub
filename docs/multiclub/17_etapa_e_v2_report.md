# 17 — Etapa E v2: correção pós-revisão (matches, match_source_refs, player_match_appearances)

> Responde ponto a ponto à revisão de 23 itens recebida sobre a primeira entrega da Etapa E. Nada foi aplicado no Supabase, nada foi commitado, nenhum código Flutter foi tocado, nenhuma das 23 migrations já aplicadas foi alterada. **PARE — aguardando revisão.**

## Decisões fechadas antes do resto (itens 20, 7)

- **`player_external_ids`: confirmado NÃO criado nesta etapa.** O provider atual (OneFootball via Worker) não fornece nenhum id de jogador — só `name`/`jerseyNumber`/`image` (confirmado por leitura direta de `src/football/normalize/match_lineup.ts` + `onefootball_provider.ts`). Documentado como BLOCKER explícito em `docs/multiclub/16_live_data_architecture.md §1.5.1`: quando um provider futuro oferecer `provider`+`external_player_id`, a tabela é criada então. O schema histórico desta etapa não depende disso.
- **`clubs.id`: já era `uuid primary key` desde a Etapa A/B (`20260902020000_create_clubs.sql`, já aplicada).** `clubs.slug text unique` também já existe. Isso NÃO precisou de correção nesta rodada — só foi confirmado e a referência ao rascunho antigo (`09_supabase_migration_plan.md`, que sugeria `clubs.id text`) foi marcada como superada em `16_live_data_architecture.md §1.0`.

## 1. Schema final de `matches`

```sql
create table public.matches (
  id uuid primary key,                          -- literal, do match registry — nunca gen_random_uuid()
  home_club_id uuid references public.clubs(id),
  away_club_id uuid references public.clubs(id),
  home_team_name text not null,
  away_team_name text not null,
  kickoff_year int not null,
  kickoff_month int,                             -- NULL só quando kickoff_precision='YEAR'
  kickoff_date date not null,                     -- placeholder de ordenação quando precisão é coarse
  kickoff_at timestamptz,                         -- só quando kickoff_precision='DATETIME'
  kickoff_precision text not null check (kickoff_precision in ('YEAR','MONTH','DATE','DATETIME')),
  competition text, season text, home_score int, away_score int,
  verification_status text not null check (verification_status in ('VERIFIED','PARTIAL')),
  data_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (home_club_id is not null or away_club_id is not null),
  check (home_club_id is null or away_club_id is null or home_club_id <> away_club_id),
  check ((kickoff_precision = 'DATETIME') = (kickoff_at is not null)),
  check ((kickoff_precision = 'YEAR') = (kickoff_month is null))
);
```
`passport_match_id`/`lineup_match_id` **removidos** — não são mais colunas de `matches` (item 4). Ver `supabase/migrations/20260902100000_create_matches.sql`.

## 2. Estratégia de stable match ID

`matches.id` nunca é derivado de data/horário/nome de time/placar/competição, nem de nenhum id de fonte externa. Vem de um `canonicalMatchKey` sequencial e imutável — `id = uuidV5(MATCHES_UUID_NAMESPACE, canonicalMatchKey)` — exatamente a mesma filosofia de `people`/`clubs`/`player_club_spells`. Matching de um candidate novo contra o registry é por **sobreposição de source anchor** (`sourceType`+`sourceRef`), nunca por atributo de partida. Ver item 18 pros 8 testes que provam isso.

## 3. Registry

`tooling/multiclub/match_registry.mjs` (novo, mesmo padrão de `person_registry.mjs`/`spell_registry.mjs`):
- `resolveMatchAnchors(registry, anchors)` → `matched` (1 entrada casa) / `new` (0 casam) / `ambiguous` (2+ entradas diferentes casam — `BLOCKED_AMBIGUOUS_MATCH`, nunca resolvido sozinho).
- `registerNewMatch`, `appendAnchors` (acrescenta anchor novo a uma entrada já casada — nunca substitui/remove), `supersedeMatch` (SPLIT/MERGE, ACTIVE/SUPERSEDED, mesma filosofia de `spell_registry.mjs`, pronta mas não exercitada nesta etapa).
- Persistido em `tooling/multiclub/matches_registry.json` (31 entradas geradas, `nextSequence=32`), mesmo padrão tracked de `people_registry.json`/`clubs_registry.json`/`spells_registry.json`.
- `validateMatchRegistryIntegrity` garante que nenhum anchor pertence a 2 entradas ACTIVE ao mesmo tempo.

## 4. `match_source_refs`

```sql
create table public.match_source_refs (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  source_type text not null check (source_type in ('LINEUP_MATCH','PASSPORT_MATCH','ONEFOOTBALL')),
  source_ref text not null,
  external_match_id text,
  source_club_id uuid references public.clubs(id),
  created_at timestamptz not null default now(),
  unique (source_type, source_ref)
);
```
**Sobre a constraint** (pedido explícito de análise): optei por `UNIQUE(source_type, source_ref)`, **sem** `source_club_id` — documentado no comentário da migration. Motivo: `LINEUP_MATCH`/`PASSPORT_MATCH` já são namespaces globalmente únicos por natureza (slug curado à mão / hash `pe_*` opaco), e hoje `source_club_id` fica NULL pras duas (não modelamos "de qual clube" por linha ainda). Se eu tivesse escopado por `source_club_id`, múltiplas linhas com `source_club_id NULL` **não colidiriam entre si** em Postgres (NULL nunca é igual a NULL numa UNIQUE) — isso teria **enfraquecido** a garantia, não fortalecido. Quando um provider futuro tiver um namespace que realmente colide entre clubes, a constraint deve ser revisada numa migration própria — não antecipada aqui sem necessidade real.

## 5. Números das source refs

| Métrica | Valor |
|---|---|
| `match_source_refs` total | 46 |
| `LINEUP_MATCH` | 31 |
| `PASSPORT_MATCH` | 15 |
| Matches com 1 fonte | 16 |
| Matches com 2+ fontes | 15 |

Os 15 matches cruzados têm as 2 provenances (testado explicitamente — nenhuma perdida).

## 6. Precisão temporal

`kickoff_precision` agora tem **4** valores, não 3 — descoberta durante a implementação (não estava nos 23 itens originais, mas o item 6 exigia): dos 12 casos "-01" suspeitos, **10** são na verdade `YYYY-01-01` (mês E dia fabricados — confirmado por auditoria: datas de Brasileirão/Copa do Brasil em 1º de janeiro não fazem sentido de calendário), não só o dia. Classificar esses como `MONTH` teria alegado um mês confiável que não existe — exatamente o erro que o item 6 pede pra evitar. Corrigido com um 4º valor:

| Precisão | Critério | Contagem |
|---|---|---|
| `YEAR` | nem mês é confiável (`YYYY-01-01`, sem link passport) | 10 |
| `MONTH` | mês confiável, só dia é placeholder (`YYYY-MM-01` com MM real, sem link passport) | 0 |
| `DATE` | dia confirmado, sem horário | 6 |
| `DATETIME` | horário confirmado (via passport `date_precision='datetime'`) | 15 |

0 casos ficaram em `MONTH` porque os 2 únicos candidatos reais (`2006-02-01`, `2010-12-01`) tinham link passport único que confirmou a data — promovidos pra `DATETIME`. Um link passport, quando existe, é sempre autoritativo sobre `lineup_matches` (nunca o contrário).

## 7. Algoritmo baseline+delta atualizado

`tooling/multiclub/recompute_player_club_stats.mjs`. Casos, em ordem:
1. `matchDate < baseline.asOfDate` → nunca soma (backfill).
2. `canonicalMatchId === baseline.asOfMatchId` → já incluído, nunca soma de novo.
3. `matchDate === baseline.asOfDate` (mesmo dia, partida diferente):
   - **ambos** têm `kickoffAt` confiável → compara timestamp; só soma se estritamente posterior.
   - falta horário confiável de qualquer lado → `AMBIGUOUS_BOUNDARY`, nunca resolvido silenciosamente.
4. `matchDate > baseline.asOfDate` → soma (dedup por `canonicalMatchId`, garante idempotência mesmo processando a mesma partida N vezes).

## 8. Capacidade real do Worker

Preservado explicitamente em `build_player_match_appearances_seed.mjs` (cabeçalho do arquivo) e em `docs/multiclub/16_live_data_architecture.md §1.1`:
- `matchLineup.lineup` → só titulares → gera `STARTED`.
- Eventos de substituição (`playerIn`/`playerOut`) → permitem no futuro identificar `SUBSTITUTE_USED`.
- **Banco completo não existe** no provider atual — `UNUSED_SUBSTITUTE` é suportado pelo schema, mas nenhum sync do OneFootball atual deve inventá-lo. Testado explicitamente (`test_player_match_appearances.mjs`, seção 2: `workerLimitation` documentado + 0 linhas `UNUSED_SUBSTITUTE`/`SUBSTITUTE_USED` no seed histórico, que é 100% `STARTED` por construção).

## 9. Confirmação — `player_external_ids` NÃO criado

Ver decisão no topo. Testado explicitamente (nenhuma das 4 migrations desta etapa cria essa tabela).

## 10. Schema final `player_match_appearances`

```sql
create table public.player_match_appearances (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.people(id),
  club_id uuid not null references public.clubs(id),
  canonical_match_id uuid not null references public.matches(id),
  spell_id uuid,
  participation_status text not null check (participation_status in ('STARTED','SUBSTITUTE_USED','UNUSED_SUBSTITUTE')),
  position_code text check (position_code in ('GOL','ZAG','LD','LE','ALD','ALE','VOL','MC','MEI','MD','ME','PD','PE','SA','ATA')),
  shirt_number integer check (shirt_number > 0),
  verification_status text not null check (verification_status in ('VERIFIED','PARTIAL')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (person_id, club_id, canonical_match_id),
  constraint player_match_appearances_spell_coherence_fkey
    foreign key (spell_id, person_id, club_id)
    references public.player_club_spells (id, person_id, club_id)
);
```
Sem mudança estrutural vs. a v1 (já estava correto) — só a FK `canonical_match_id` que antes referenciava um `matches.id` gerado por `gen_random_uuid()` agora referencia o `id` literal do registry (transparente pro schema, o tipo/FK não muda).

## 11. Roles de provenance

`player_match_appearance_sources.source_role` mudou de `('PRIMARY','CORROBORATING','DERIVED_COMPONENT','BASELINE')` pra **`('PRIMARY','CORROBORATING','CORRECTION')`** — roles próprios desta tabela, não mais reaproveitando o enum de `player_club_stat_sources` (que mantém `BASELINE`, sem mudança — esse é um conceito de ESTATÍSTICA AGREGADA, não pertence semanticamente a uma appearance individual). `DERIVED_OBSERVATION` foi cogitado (pro caso de uma appearance sintetizada a partir de evento de substituição) mas **não criado** — não há necessidade real nesta etapa, só seria especulação. `CORRECTION` cobre o caso de uma fonte posterior revisar um valor já gravado (ex.: `UNUSED_SUBSTITUTE` → `SUBSTITUTE_USED`).

## 12. Decomposição dos 82 sem spell

```
A) sem nenhum spell canônico Goiás .......... 82
B) boundary YEAR a <= 6 meses da partida ..... 0
C) data cai fora de todos os spells .......... 0
D) 2+ spells candidatos ambíguos ............. 0
```
Achado honesto, não fabricado: **100% dos 82 são categoria A** — pessoas cuja ÚNICA evidência estruturada é `lineup_matches` em si nunca tiveram um spell Tier-1 (`career_players`/`squad_members`) construído na Etapa D, porque spells Tier-2 (`lineup_matches` com `matchIdFilter`) só são gerados quando não há Tier-1 — e mesmo aí, o pipeline de spells não necessariamente cobriu todo mundo. Nenhum caso B/C/D apareceu nesta leva porque, pra quem TEM spell, a cobertura resultou limpa (sem sobreposição ambígua nem gap de fronteira). Regra operacional documentada em `build_player_match_appearances_seed.mjs` (`classifySpellGap`, janela de tolerância `NEAR_BOUNDARY_GRACE_MONTHS=6`, auditável, não escondida).

## 13. Números finais

**matches**: 31 total — 15 com link passport, 16 sem — 21 VERIFIED, 10 PARTIAL — por precisão: YEAR=10, MONTH=0, DATE=6, DATETIME=15.

**match_source_refs**: 46 total — 31 LINEUP_MATCH, 15 PASSPORT_MATCH — 16 matches com 1 fonte, 15 com 2+.

**player_match_appearances**: 162 linhas, 100% STARTED — 62/96 pessoas APPROVED com ≥1 appearance, 34 blocked (`NO_LINEUP_EVIDENCE`) — 123 VERIFIED, 39 PARTIAL — 80 com `spell_id`, 82 sem (100% categoria A) — 152 com `position_code`, 10 sem (compostos/genéricos, valor bruto preservado na provenance).

**Testes**: 246 passando, 0 falhando, em todos os `test_*.mjs` do projeto (73 só em `test_player_match_appearances.mjs`, incluindo os 8 novos de estabilidade do match registry).

## 14. Testes

Além dos já existentes (unicidade, FK composta, homônimos, position_code, baseline+delta original), adicionados nesta rodada em `test_player_match_appearances.mjs`:
- stable match ID: corrigir data, adicionar horário, adicionar fonte passport, adicionar provider futuro, renomear texto de time, reordenar anchors — todos preservam o mesmo `matchId` (seção 15, 6 testes).
- cross-club: 2ª fonte encontrando a mesma partida via anchor compartilhado resolve pro MESMO `matchId`, nunca cria um 2º (seção 15).
- source uniqueness: 2 anchors do mesmo candidate resolvendo pra 2 entradas diferentes já registradas → `ambiguous`/BLOCKED (seção 15).
- SPLIT/MERGE: `supersedeMatch` migra anchors, nunca reaproveita `canonicalMatchKey` (seção 15).
- kickoff precision: placeholder `YYYY-01-01` → `YEAR` (nunca MONTH/DATE); `YYYY-MM-01` sem link → nunca promovido sozinho; COM link → promovido; toda `YEAR` é `PARTIAL` (seção 11b).
- same-day exact time (soma) vs. same-day uncertain (`AMBIGUOUS_BOUNDARY`) (seção 5).
- Worker limitation: 0 `UNUSED_SUBSTITUTE`/`SUBSTITUTE_USED` inventados, limitação documentada em `buildStats` (seção 2).
- unlinked spell: 100% dos 82 sem spell têm `category` A/B/C/D populada, soma bate (seção 8).
- substituto que entra conta, não-utilizado nunca conta (seção 7).

## 15. Migrations

Mantida a numeração original (o pedido sugeria renumerar, mas como o CONTEÚDO mudou e os arquivos continuam nunca aplicados, renumerar seria troca cosmética sem ganho — mantive os mesmos 4 nomes, conteúdo reescrito):
- `20260902100000_create_matches.sql` — agora inclui `matches` (schema novo, sem `passport_match_id`/`lineup_match_id`) **+** `match_source_refs`.
- `20260902110000_seed_goias_matches.sql` — `matches.id` literal + seed de `match_source_refs`.
- `20260902120000_create_player_match_appearances.sql` — só mudou `source_role` (item 11).
- `20260902130000_seed_goias_player_match_appearances.sql` — `canonical_match_id` literal, sem JOIN via `lineup_match_id`.

Nenhuma das 23 migrations já aplicadas foi tocada.

## 16. Confirmação — 23 migrations antigas intactas

```
git ls-files supabase/migrations/ | wc -l   ->  23
git diff --stat -- supabase/migrations/     ->  (vazio, nenhuma tracked migration mudou)
```
Confirmado por comando, não por suposição.

## 17. `git diff --stat`

```
 docs/multiclub/16_live_data_architecture.md        | 94 ++++++++++++++--------
 lib/.../store_entry_card.dart                      |  2 +-   (PRÉ-EXISTENTE, não tocado por mim, exclusão padrão)
 tooling/multiclub/live_data_model.mjs              | 18 ++++-
 3 files changed, 78 insertions(+), 36 deletions(-)
```

## 18. `git status`

```
 M docs/multiclub/16_live_data_architecture.md
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente, fora de escopo — padrão de exclusão do projeto)
?? _competitions_pkg/                                              (pré-existente, fora de escopo)
?? data_export/goias/player_reconciliation/match_identity_audit.json
?? data_export/goias/player_reconciliation/match_source_refs_seed.json
?? data_export/goias/player_reconciliation/matches_seed.json
?? data_export/goias/player_reconciliation/matches_seed_stats.json
?? data_export/goias/player_reconciliation/player_match_appearance_sources_seed.json
?? data_export/goias/player_reconciliation/player_match_appearances_seed.json
?? data_export/goias/player_reconciliation/player_match_appearances_seed_stats.json
?? migration_dump.txt                                              (padrão de exclusão do projeto — nunca incluir)
?? supabase/migrations/20260902100000_create_matches.sql
?? supabase/migrations/20260902110000_seed_goias_matches.sql
?? supabase/migrations/20260902120000_create_player_match_appearances.sql
?? supabase/migrations/20260902130000_seed_goias_player_match_appearances.sql
?? tooling/multiclub/audit_match_identity.mjs
?? tooling/multiclub/build_matches_seed.mjs
?? tooling/multiclub/build_player_match_appearances_seed.mjs
?? tooling/multiclub/generate_matches_seed.mjs
?? tooling/multiclub/generate_player_match_appearances_seed.mjs
?? tooling/multiclub/match_registry.mjs
?? tooling/multiclub/matches_registry.json
?? tooling/multiclub/recompute_player_club_stats.mjs
?? tooling/multiclub/test_player_match_appearances.mjs
```
Nada staged, nada commitado, nada aplicado no Supabase.

## Observação fora do pedido original (transparência)

Durante a implementação do item 6, descobri que a heurística original ("dia = 01 é sempre placeholder") estava incompleta: 10 dos 12 casos suspeitos tinham TAMBÉM o mês fabricado (`YYYY-01-01`). Isso exigiu adicionar uma 4ª precisão (`YEAR`) não prevista nos 23 itens — documentado no item 6 acima e testado explicitamente. Sinalizo porque é uma mudança de schema (o `check` de `kickoff_precision`) que vai além do que foi pedido literalmente, mas que segue a mesma regra (nunca alegar mais precisão do que a fonte tem) — na minha leitura, a alternativa (forçar esses 10 casos em `MONTH`) teria violado o próprio item 6.

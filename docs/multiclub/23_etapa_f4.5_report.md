# Etapa F4.5 — Saneamento canônico do elenco atual

Data: 2026-09-02
Status: **REVISADA E APROVADA** (com endurecimentos aplicados antes do push — seção 21).

Disparada diretamente pelos achados da própria F4: das 31 pessoas do elenco atual
já linkadas a `people` via `squad_members.person_id`, 8 não tinham nenhum spell
`is_ongoing=true` no Goiás e 2 não tinham nenhuma linha `player_club_stats`
`CLUB_TOTAL` no Goiás. Esta etapa reconfirma os 8+2 diretamente (não confia só no
relatório da F4), investiga a causa raiz, propõe correções com evidência
explícita e gera (sem aplicar) as migrations correspondentes.

---

## 1. Reconfirmação dos 8 gaps de spell (squad_members → people → player_club_spells)

Re-derivado localmente a partir de `player_club_spells_seed.json` (seed já
aplicado da Etapa B) + `squad_members_person_mapping.json` (F4), filtrando
`clubSlug='goias'` — os mesmos 8 nomes da F4:

| squad_member_id | canonicalName | spells Goiás existentes | is_ongoing hoje |
|---|---|---|---|
| luisao | Luis Fellipe Campos Doria | 1 | false |
| ramon_menezes | Ramon Menezes Roma | 1 | false |
| filipe_machado | Luiz Filipe da Rosa Machado | 1 | false |
| gege | Geirton Marques Aires | 1 | false |
| wellington_rato | Wellington Soares da Silva | 1 | false |
| cadu | Carlos Eduardo Amaral Pereira de Castro | 1 | false |
| felipe_clemente | Luiz Felipe Clemente de Almeida | 1 | false |
| kadu_sousa | Carlos Eduardo de Sousa Leopoldino | 1 | false |

Todos os 8 têm **exatamente 1** spell Goiás (não zero) — descarta de saída a
hipótese "faltava criar um spell novo".

## 2. Evidência coletada por caso — causa raiz é convenção de autoria, não ausência de dado

Para cada um dos 8, o único spell Goiás existente tem `loan=true` e um "fim"
cujo mês/ano é **posterior a hoje (2026-09-02)** — ex. cadu: `fev/2026–dez/2026`;
kadu_sousa: `dez/2025–dez/2026`; filipe_machado: `jan/2026–nov/2026`. Um vínculo
não pode ter terminado numa data que ainda não chegou — o "fim" registrado em
`squad_members.club_history` é o término **contratual** do empréstimo (a data
prevista de expiração), não uma saída já ocorrida.

Reforço cruzado (sem inventar nada, só dado já existente):
- Os 8 estão presentes no elenco atual (`squad_members`, `updated_at=2026-08-24`,
  9 dias antes desta auditoria) — presença ativa confirmada.
- `build_player_club_spells_seed.mjs` (Etapa B) usa checagem literal da string
  `"atual"` pra decidir `isOngoing` — não é bug de código, é que
  `squad_members.club_history` nunca usou essa palavra pros 8 (a fonte foi
  autorada com data de expiração de contrato, não com "atual").
- 3 dos 8 já têm proveniência registrada (`player_club_spell_sources`, fonte
  `squad_members:<id>:club_history:<n>`, `evidence_type=PRIMARY`,
  `relationship_type=LOAN`) — a correção reaproveita a proveniência existente,
  não precisa de linha nova.

Caso adicional: `felipe_clemente` tem uma nota já cadastrada (não pesquisada
agora) em `club_history` — *"Chegou por empréstimo em 21/08/2026; snapshot
antes de estreia oficial pelo Goiás"* — dado real já presente, permitindo
refinar `start_precision` de MONTH para DATE sem fabricar nada.

## 3. Classificação — todos EXTEND_EXISTING_SPELL

Nenhum caso foi classificado `NEW_SPELL` (evitaria criar linha duplicada
fantasma), `BLOCKED_INSUFFICIENT_EVIDENCE` ou `AMBIGUOUS`. Os 8 são
`EXTEND_EXISTING_SPELL`: mesmo `spellId`/`canonicalSpellKey`, apenas
`is_ongoing=true` + os 4 campos de fim nulados (+ refinamento de start só pra
felipe_clemente).

## 4. Precisão temporal proposta

7 casos: sem mudança de precisão de início, apenas remoção do fim (o schema
exige `end_precision IS NULL ⟺ is_ongoing=true`). 1 caso (felipe_clemente):
`start_precision` MONTH → DATE, `start_date='2026-08-21'`, usando a nota já
cadastrada como fonte — nenhuma promoção de YEAR→DATE, nenhuma data fabricada.

## 5. Proveniência

Nenhuma linha nova em `player_club_spell_sources` é necessária — os 8 UPDATEs
reaproveitam a proveniência já registrada na Etapa B (a natureza do vínculo,
`LOAN`, não muda; só o estado ongoing/end muda).

## 6. Auditoria de overlap

Testado programaticamente (`test_current_squad_gap_fixes.mjs`, seção 4): após
simular as 8 correções sobre o seed local, nenhuma pessoa fica com 2 spells
`is_ongoing=true` simultâneos no Goiás, e nenhum spell corrigido colide em
`spellOrder` com outro spell da mesma pessoa+clube.

## 7. Cobertura ongoing — antes/depois (simulado, não aplicado)

`23/31 → 31/31` (as 8 correções fecham 100% do gap; nenhum ficou sem evidência
suficiente, então não houve necessidade de aceitar cobertura parcial).

---

## 8. Reconfirmação dos 2 gaps de stats

Ezequiel e Murillo Victorio — reconfirmado via `player_club_stats_seed.json`
(seed da Etapa D): nenhuma linha `CLUB_TOTAL` no Goiás pra nenhum dos dois.
`squad_members.json` já sinalizava `data_quality: "partial"` com nota
explícita de que o agregador local não exibia total consolidado — evidência
local genuinamente insuficiente, diferente do caso dos spells.

## 9. Evidência de appearances/gols (pesquisa externa autorizada)

Usado `ogol.com.br` (base estruturada de futebol) como fonte primária externa,
priorizada por ser estruturada e verificável:
- **Ezequiel**: "Sem jogos disputados" no time profissional do Goiás em todas
  as temporadas 2023-2026, contra números reais e não-zero em Goiás U23 (2024,
  7 jogos) e U20 (2023, 26 jogos) no mesmo perfil — contraste que reforça que a
  ausência no profissional é real, não dado faltante. Corroborado pelo site
  oficial do clube (perfil sem número listado, não contradiz).
- **Murillo Victorio**: "-" no profissional 2026, contra 12 jogos reais no
  Sub-20 2026 (Brasileiro Sub-20 Série B, Copinha, Copa Goiás, Goiano Sub-20)
  no mesmo perfil. Corroborado por resumo de busca web adicional.

## 10. Valores propostos

`appearances=0, goals=0` pros dois — refletindo ausência **confirmada** de
jogos no profissional, não "desconhecido". `NULL` seguiria sendo usado se a
evidência não desse pra concluir isso com confiança; aqui deu.

## 11. NULLs preservados / independência dos 2 campos

Não se aplica um "must both be known" — os dois casos têm ambos os campos
conhecidos (0 e 0), mas a independência do schema (`check (appearances is not
null or goals is not null)`) continua respeitada; nenhuma das outras 29 linhas
CLUB_TOTAL do elenco atual foi tocada, então nenhum NULL pré-existente virou 0
por engano (testado explicitamente).

## 12. verification_status / data_mode

`verification_status='PARTIAL'` pros dois (fonte externa secundária, nunca
promovida a VERIFIED sem confirmação oficial explícita do clube com o número).
`data_mode='SNAPSHOT'`, `as_of_date='2026-09-02'`, `as_of_match_id=null` — sem
qualquer implementação de sync ao vivo.

## 13. Proveniência de stats

`player_club_stat_sources`, 2 linhas por pessoa (4 no total): a fonte
`ogol.com.br` como `source_role='PRIMARY'` (evidência direta que sustenta o
valor) e a fonte secundária (site oficial / resumo de busca) como
`source_role='CORROBORATING'`. Nenhum uso de `BASELINE` (reservado pra sync ao
vivo, Etapa E — não é o caso aqui) nem `DERIVED_COMPONENT`.
**Correção feita durante a construção**: a primeira versão do gerador gravava
`PRIMARY` nas 4 linhas indistintamente; corrigido antes de finalizar para
mapear `external_verified→PRIMARY` / `external_corroborating→CORROBORATING`,
com um `throw` no gerador se aparecer um `sourceType` não mapeado (nunca
inventa role por default).

## 14. Cobertura CLUB_TOTAL — antes/depois (simulado, não aplicado)

`29/31 → 31/31`.

---

## 15. Tooling criado (todo em `tooling/multiclub/`, não contamina os geradores gerais)

- `audit_current_squad_canonical_gaps.mjs` — re-audita os gaps a partir dos
  exports/seeds já aplicados, escreve `current_squad_canonical_gap_audit.json`.
- `current_squad_gap_evidence.json` — evidência estruturada (humana + pesquisa
  externa), separada da lógica de geração.
- `build_current_squad_gap_fixes.mjs` — combina audit + evidência em
  `current_squad_canonical_gap_fix_plan.json` (shape `{personId, canonicalName,
  gapType, status, ...}` por gap).
- `generate_current_squad_gap_migration.mjs` — serializa o fix plan em SQL
  (não aplica).
- `test_current_squad_gap_fixes.mjs` — 38 testes cobrindo cobertura, invariante
  `is_ongoing⟺end_*null`, overlap, SQL gerado, roles de proveniência,
  NULL≠0 nas 29 linhas não tocadas, F4 intocado, registry intocado,
  reprodutibilidade, evidência sem entradas órfãs, e (rodada de revisão)
  precondition exata por spell, invariante do elenco inteiro, provenance
  preservada, count preservado, ausência de now()/current_date em condição
  de negócio, 2 PRIMARY/2 CORROBORATING, as_of_date literal, sanity
  conceitual baseline+delta.

## 16. Mudanças em registries

Nenhuma. `spells_registry.json` sem diff (`git status --porcelain` confirmado
vazio) — esperado, já que nenhuma spell nova foi criada, só UPDATE em spells
já registradas na Etapa B.

## 17. Migrations propostas (arquivos existem, NÃO aplicadas)

- `supabase/migrations/20260902200000_fix_current_squad_ongoing_spells.sql` —
  `DO $$ ... $$` com pré-condição (8 spells alvo com `is_ongoing=false`),
  8 UPDATEs (cada um comentado com nome + squad_member_id + canonicalSpellKey),
  pós-condições (8 agora `is_ongoing=true`, 0 com algum campo de fim não-nulo).
- `supabase/migrations/20260902210000_add_current_squad_missing_club_total_stats.sql`
  — `DO $$ ... $$` com pré-condição (0 CLUB_TOTAL pré-existente pras 2
  pessoas), 2 INSERTs em `player_club_stats` + 4 INSERTs em
  `player_club_stat_sources`, pós-condições (2 linhas CLUB_TOTAL, 4 linhas de
  proveniência, exatamente 1 PRIMARY por stat novo).

Timestamps seguem os 33 já aplicados (que terminam em `20260902190000`) —
`20260902200000` e `20260902210000`.

## 18. Testes

`node tooling/multiclub/test_current_squad_gap_fixes.mjs` — **38 passaram, 0
falharam** (23 da 1ª rodada + 15 novos da rodada de revisão, seção 21). Suíte
JS completa do multiclub re-executada (`tooling/multiclub/test_*.mjs`, 11
arquivos) — **388 passaram, 0 falharam** (350 pré-existentes + 38 desta
etapa). Nenhum teste Flutter alterado (fora de escopo, nenhuma mudança em
código Dart nesta etapa).

## 21. Rodada de revisão — endurecimentos aplicados antes do push

A F4.5 foi revisada e aprovada com 1 conjunto de endurecimentos finais antes
da autorização de commit+push. Todos aplicados:

1. **Precondition EXATA por spell** (não só "id existe"): a migration de
   spells agora verifica, pra cada um dos 8, `person_id`, `club_id`,
   `is_ongoing=false`, `start_year/month/date/precision`,
   `end_year/month/date/precision` e `verification_status` — o estado EXATO
   auditado em 2026-09-02. Qualquer drift entre a auditoria e o momento do
   push levanta `RAISE EXCEPTION` ANTES de qualquer UPDATE (nenhuma aplicação
   parcial possível — as 8 checagens rodam antes do 1º UPDATE).
2. **Transformação semântica confirmada**: `id`/`canonicalSpellKey`/
   `person_id`/`club_id`/`spell_order` preservados; `is_ongoing=true` +
   `end_year/end_month/end_date/end_precision=NULL`. Nenhum spell novo.
3. **Felipe Clemente**: `start_year=2026, start_month=8,
   start_date=2026-08-21, start_precision=DATE`, mesmo `spellId`
   (`7888b147-6881-56cd-8c19-8bd94bc2ea20`), mesma `canonicalSpellKey`
   (`goias-app:multiclub:spell:41`) — confirmado no SQL gerado.
4. **Provenance da expiração contratual preservada**: os 8 spells têm,
   cada um, exatamente 1 linha em `player_club_spell_sources`
   (`source_record_key=squad_members:<id>:club_history:<n>`,
   `evidence_type=PRIMARY`, `relationship_type=LOAN`) — confirmado via
   `player_club_spell_sources_seed.json` antes de gerar qualquer UPDATE.
   `build_current_squad_gap_fixes.mjs` agora aborta com erro explícito se
   algum spell alvo tiver 0 linhas de proveniência (nunca apagaria a única
   evidência do vínculo sem antes preservá-la). A migration em si nunca
   escreve/apaga em `player_club_spell_sources` — só lê pra confirmar
   count antes==depois. A informação de "fim contratual previsto" continua
   integralmente disponível em `squad_members.club_history` (fonte bruta,
   intocada por esta etapa) — nada foi perdido, só a leitura canônica
   derivada mudou.
5. **Pós-condição valida o ELENCO INTEIRO (31 pessoas)**, não só os 8
   corrigidos: exatamente 1 spell Goiás `is_ongoing=true` por pessoa (0 com
   nenhum, 0 com 2+), e 0 pares de spells Goiás sobrepostos por pessoa
   (checagem em granularidade de mês, conservadora — mês ausente tratado
   como o mais abrangente possível pra cada lado).
6. **Ezequiel e Murillo Victorio, `0/0` aprovado** com semântica explícita:
   0 aparições PROFISSIONAIS (STARTED/SUBSTITUTE_USED, mesma semântica de
   `player_match_appearances` da Etapa E) — nunca "0 relacionado em súmula"
   nem "0 jogos de base" (ambos têm minutos reais na base/sub-20/sub-23,
   documentado explicitamente no comentário da migration e na evidência).
   `UNUSED_SUBSTITUTE` nunca conta como appearance — reafirmado, não
   reinterpretado (a fonte usada, ogol.com.br, já reporta no nível de
   aparição real, não de súmula/relacionado — nenhuma página da CBF com
   súmulas foi usada como fonte).
7. **`as_of_date='2026-09-02'` literal e obrigatório** nos 2 INSERTs em
   `player_club_stats` (nunca `current_date`) — confirmado via teste que lê
   o valor literal gravado no SQL.
8. **Precondition explícita nos stats**: `person_id` existe em `people`,
   `club_id` (Goiás) existe em `clubs`, 0 `CLUB_TOTAL` pré-existente —
   `RAISE EXCEPTION` se qualquer uma falhar, nunca overwrite/upsert
   silencioso.
9. **Pós-condição de stats ampliada**: 2 `CLUB_TOTAL` novos, 0 duplicado por
   pessoa, 4 linhas de provenance, exatamente 1 `PRIMARY` por stat —
   confirmado **2 PRIMARY / 2 CORROBORATING** de fato no fix plan (não
   forçado a 4 nem a nenhum outro número).
10. **`verification_status='PARTIAL'` mantido** (não promovido a VERIFIED) —
    confirmado como decisão deliberada, não esquecimento.
11. **As outras 29 `CLUB_TOTAL` continuam intocadas** — 0 UPDATE/DELETE em
    `player_club_stats` na migration de stats (só 2 INSERT), confirmado por
    teste estrutural no SQL gerado.
12. **`spells_registry.json`**: confirmado que guarda só identidade/anchors
    (`canonicalSpellKey`↔`spellId`), nenhum metadado mutável de
    temporalidade — corretamente NÃO alterado (misturar registry de
    identidade com estado mutável seria um erro de design, evitado).
13. **Reprodutibilidade**: `audit_current_squad_canonical_gaps.mjs`,
    `build_current_squad_gap_fixes.mjs` e
    `generate_current_squad_gap_migration.mjs` confirmados sem nenhuma
    referência a `new Date()`/`Date.now()`/`current_date` — a data de
    snapshot (`2026-09-02`) é sempre um literal já auditado, nunca calculada
    em tempo de execução. Todo o pipeline (audit → fix plan → migrations)
    re-executado e confirmado byte-idêntico.
14. **Sanity conceitual baseline+delta** (Etapa E/D, não implementado aqui —
    só validado como preparação): usando `recomputeTotal()` de
    `recompute_player_club_stats.mjs` com um baseline sintético
    `{appearances:0, asOfDate:'2026-09-02'}` + 1 appearance futura
    (`2026-09-15`, `STARTED`) → `total=1`. Reprocessar a MESMA appearance
    (simulando uma sync rodando de novo) continua `total=1`; reprocessar a
    mesma lista 2x também não duplica (dedup por `canonicalMatchId`) — a
    arquitetura existente já suporta esse "0" corretamente, nenhuma mudança
    de código necessária.

## 19. `git diff --stat` / `git status`

```
 lib/features/store/presentation/widgets/store_entry_card.dart | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
(mudança pré-existente, não relacionada a esta etapa — não tocada por mim.)

Untracked relevantes a esta etapa:
```
data_export/goias/player_reconciliation/current_squad_canonical_gap_audit.json
data_export/goias/player_reconciliation/current_squad_canonical_gap_fix_plan.json
supabase/migrations/20260902200000_fix_current_squad_ongoing_spells.sql
supabase/migrations/20260902210000_add_current_squad_missing_club_total_stats.sql
tooling/multiclub/audit_current_squad_canonical_gaps.mjs
tooling/multiclub/build_current_squad_gap_fixes.mjs
tooling/multiclub/current_squad_gap_evidence.json
tooling/multiclub/generate_current_squad_gap_migration.mjs
tooling/multiclub/test_current_squad_gap_fixes.mjs
docs/multiclub/23_etapa_f4.5_report.md (este arquivo)
```

Untracked **não relacionados** a esta etapa (pré-existentes, não tocados,
não fazem parte do escopo F4.5): `_competitions_pkg/`, `migration_dump.txt`,
`docs/multiclub/19_etapa_e_v4_applied_report.md` (já existia da Etapa E v4,
nunca commitado).

## 20. Compatibilidade e limites respeitados

- Nenhuma migration já aplicada foi reescrita.
- Nenhum UUID de spell antigo alterado; nenhum `canonicalSpellKey` alterado.
- Nenhuma schema nova (nenhuma coluna/tabela criada) — puro DML, como esperado.
- Nenhuma das outras 29 linhas CLUB_TOTAL tocada (Tadeu, Walter, Paulo Baier,
  Rafael Moura e demais continuam intactos — verificado por teste).
- Nenhuma mudança em código Flutter (`SquadMember`, `career_players`,
  `guess_players`, `crowd_lineup`, `goiasSquad`, assets, UI) — zero.
- `squad_members.person_id` (F4) confirmado intocado — 31 RESOLVED, casos
  sensíveis (Nicolas→Vichiatto, Danilo→Cunha, Murilo Câmara≠Murillo Victorio)
  seguem corretos.
- Revisada e aprovada 2026-09-02 com os endurecimentos da seção 21 — commit
  controlado + `supabase db push` autorizados a seguir. `git push` segue
  **não autorizado** (nunca fazer sem pedido explícito).

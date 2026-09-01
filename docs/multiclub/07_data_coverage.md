# 07 — Matriz de Cobertura dos Dados

> Números medidos DIRETO dos arquivos exportados em `data_export/goias/` (gerados por `tooling/multiclub/export_seed_data.mjs`, que lê os `.sql` de `supabase/`), não estimados. Gerado em 2026-09-01. Nenhum campo foi preenchido artificialmente — onde o dado não existe, o export mantém `null`.

## Partidas (`passport_matches.json`, 1.697 registros)

| Campo | Cobertura | Observação |
|---|---|---|
| match_date | 100,0% | — |
| status | 100,0% | 1697/1697 `FINISHED` (a última linha, ainda `SCHEDULED` na importação original, foi corrigida pela migration de auditoria — ver `06_database_audit.md §5`) |
| competition / competition_code / round | 100,0% | — |
| home_team / away_team | 100,0% | — |
| home_score / away_score / outcome | 100,0% | — |
| **match_time / kickoff_at / display_timezone** | **85,9%** (1458/1697) | Nulos juntos nas 239 partidas com `date_precision='date_only'` — a fonte nunca informou horário pra elas (majoritariamente Goianão antigo) |
| **venue_id** | 100,0% (após migration) | **Era 0% na importação original** — só passou a 100% com a migration `20260831040000_passport_venue_audit.sql` de 31/08. Comentários antigos no código dizem "sempre vazio" — estão desatualizados, ver `06_database_audit.md §4` |
| venue_confidence | 100,0% | HIGH 772 / MEDIUM 426 / LOW 499 |
| venue_audit_status | 100,0% | **CONFIRMED_MATCH_SPECIFIC 772 (45,5%)** vs. **RECONSTRUCTED_HISTORICAL 925 (54,5%)** — pra mais da metade das partidas o estádio foi inferido por mando/época, não confirmado pra aquela partida específica |
| source_match_id | 97,8% (1659/1697) | Nulo nas 38 partidas com `source_provider='RSSSF Brasil'` (2000-2001, Goianão), que não têm id numérico de partida |
| **referee, attendance, lineup, cartões, eventos** | **0% — não existem no schema** | Não são colunas de `passport_matches`. Só existem pra partidas ao vivo/futuras (via Worker/OneFootball), nunca pro histórico. |

**Distribuições:**
- `competition_code`: BRASILEIRO_A 668, GOIANO 498, BRASILEIRO_B 329, COPA_DO_BRASIL 118, SUL_AMERICANA 40, COPA_VERDE 24, COPA_DOS_CAMPEOES 10, LIBERTADORES 10
- `source_provider`: oGol 1659 (97,8%), RSSSF Brasil 38 (2,2%)
- `date_precision`: datetime 1458 (85,9%), date_only 239 (14,1%)

## Elenco atual (`squad_members.json`, 31 registros)

| Campo | Cobertura |
|---|---|
| name / full_name / shirt_number / position / position_group / birth_date / nationality / club_history | 100,0% |
| height_cm | 93,5% (29/31) |
| **foot** (pé preferido) | **64,5% (20/31)** — 11 jogadores sem essa informação registrada |

## Quem Vestiu o Manto (`guess_players.json`, 173 registros)

| Campo | Cobertura |
|---|---|
| nationality_code / nationality_name | 100,0% |
| goias_debut_year | 94,2% (163/173) |
| academy_club | 82,1% (142/173) |
| shirt_number | 56,6% (98/173) — esperado: muitos históricos não têm número catalogado |
| **photo_key** | **17,9% (31/173)** — a grande maioria não tem foto associada |

`data_status`: incomplete 83 (48,0%), verified 63 (36,4%), review 27 (15,6%) — quase metade do catálogo é auto-classificada como incompleta pelo próprio dataset.

## Adivinhe o Jogador (`career_players.json`, 30 registros)

`position` e `aggregate_stats` 100% preenchidos (dataset pequeno e curado à mão). `club_career`/`national_teams` (jsonb) sempre presentes, mas `appearances`/`goals` individuais às vezes `null` dentro de uma passagem quando a fonte só fecha o total combinado (ver `aggregate_stats`) — não é uma lacuna, é intencional (ver comentário na migration v2).

## Adivinhe a Escalação (`lineup_matches.json`, 31 partidas)

`formation_confidence`: estimated 15 (48,4%), probable 9 (29,0%), confirmed 7 (22,6%) — menos de um quarto das escalações históricas tem a formação confirmada com certeza; a maioria é estimativa/provável.

## Estádios (`venues.json`, 160 registros)

Todos os 160 têm `canonical_name`/`display_name`/`city`/`state`/`country` — schema também prevê `latitude`/`longitude`/`aliases`, mas nenhuma linha da migration de auditoria os popula (ficam null; não fazem parte do payload que gerou essa migration).

## Diretoria / Transparência / FAQ do Sócio

Conteúdo editorial curado à mão (não há "cobertura" no sentido estatístico — são poucos registros, todos completos por construção): 6 seções/18 membros de diretoria, 22 tópicos/122 documentos de transparência, 10 categorias/33 itens de FAQ, 1 versão de regulamento vigente.

## O que NÃO está no `data_export/` (fonte é Dart, não SQL)

Ver `02_goias_data_inventory.md` pro índice completo — resumindo, ficaram de fora deste export porque não vêm de tabela Supabase:
- Catálogo da loja (104 produtos, JSON local)
- Planos de sócio, regulamento (gerado de Markdown), contato
- História/timeline/hino/títulos do clube
- `goias_players.dart` (215 nomes, autocomplete)
- `goias_squad.dart` (cópia hardcoded do elenco pra Escalação da Torcida)
- Datasets de referência dos quizzes de perfil (12 técnicos, 21 jogadores-estilo)
- Fixture de setores/preços de ingresso

# 02 — Base de Dados: Goiás App

> Documento consolidado — "isso é tudo que precisamos procurar para construir outro clube". Gerado em 2026-09-01. Cada seção diz o que existe, quantos registros, de onde vem, e aponta pro JSON exportado (`data_export/goias/`) ou pro documento de detalhe correspondente.

## Clube

- **História e linha do tempo**: hardcoded Dart (`club_history_data.dart`, `club_timeline_data.dart`), fonte citada em comentário como goiasec.com.br/historia. Sem export JSON — é prosa narrativa, não dado tabular.
- **Diretoria**: Supabase, 6 seções / 18 membros → `club_board_sections.json` / `club_board_members.json`.
- **Transparência**: Supabase, 22 tópicos / 122 documentos (PDFs do goiasec.com.br) → `club_transparency_topics.json` / `club_transparency_documents.json`.
- **Hino/músicas**: hardcoded Dart (`club_songs_data.dart`, ~15 letras completas). Sem export — conteúdo protegido/extenso, ver arquivo fonte diretamente se precisar.
- **Títulos**: hardcoded Dart (`club_titles_data.dart`) + refletido na estrutura de pastas de asset do `pubspec.yaml` (campeonato-goiano, libertadores-2006, copa-do-brasil-1990, sula-2010, brasileirao-2005).

## Jogadores

**Seis fontes independentes, três esquemas de ID, sem chave de junção comum** — ver análise completa em `03_data_sources.md`.

| Fonte | Export | Registros |
|---|---|---|
| Elenco atual | `squad_members.json` | 31 |
| Adivinhe o Jogador (histórico) | `career_players.json` | 30 |
| Quem Vestiu o Manto | `guess_players.json` | 173 |
| Autocomplete (nomes só) | não exportado — `goias_players.dart`, Dart | 215 |
| Escalação da Torcida (cópia hardcoded do elenco) | não exportado — `goias_squad.dart`, Dart, verificado idêntico ao squad_members | 31 |
| Que Craque Esmeraldino É Você (referência de estilo) | não exportado — `player_identity_references.dart`, Dart | 21 |

**Estimativa total**: ~230–260 indivíduos únicos (sem normalização de nome real entre fontes — esse trabalho não existe hoje). Ver `07_data_coverage.md` pra cobertura de campo detalhada e divergências nomeadas (Tadeu, Walter, Erik, colisão "Danilo").

## Trajetórias de clube (por jogador)

Vêm embutidas como jsonb dentro de `squad_members.club_history` e `career_players.club_career`/`national_teams` — não são uma tabela separada. Estrutura: `period, team, appearances, goals, loan, is_goias` (+ `data_quality`/`notes` no squad). Ver os próprios JSONs exportados.

## Partidas

- **Histórico (2000–2026)**: Supabase `passport_matches`, 1.697 registros → `passport_matches.json`. Fonte original: JSON fornecido pelo usuário (RSSSF/oGol por linha), nunca scraping do próprio app. Corrigido por uma migration de auditoria de estádios/datas/placares (31/08/2026) — já mesclado no export.
- **Ao vivo / próximas**: nunca persistidas — sempre buscadas do Worker (`goias-app.lucasdiogo1234.workers.dev`, que proxia OneFootball). Sem export (dado transiente, não faz sentido "exportar").
- **Eventos de partida (gols, cartões), escalação, árbitro, público**: **não existem no schema de `passport_matches`** — só disponíveis pras partidas ao vivo via Worker, e só enquanto a partida está no radar. Ver `07_data_coverage.md`.

## Competições

Derivadas de `passport_matches.competition_code` (8 valores distintos: BRASILEIRO_A, GOIANO, BRASILEIRO_B, COPA_DO_BRASIL, SUL_AMERICANA, COPA_VERDE, COPA_DOS_CAMPEOES, LIBERTADORES). Não existe uma tabela `competitions` separada — cada partida carrega o nome/código da competição diretamente.

## Temporadas

Derivadas de `passport_matches.season` (int, 2000–2026). Sem tabela separada.

## Estádios

Supabase `venues`, 160 registros (populados só a partir da migration de auditoria de 31/08 — na importação original o campo não existia preenchido) → `venues.json`.

## Técnicos

Só existem como dataset de referência de ESTILO pro quiz "Identidade Futebolística" — 12 técnicos, hardcoded Dart (`tactical_coach_references.dart`), recalibrado v2 em 2026-09-01. Não é um histórico factual de todos os técnicos que o Goiás já teve — é um dataset editorial pra fins de comparação no jogo. Sem export SQL (não é Supabase).

## Títulos

Hardcoded Dart (`club_titles_data.dart`). Sem export.

## Arena (datasets dos jogos)

| Jogo | Export | Registros |
|---|---|---|
| Quiz do Verdão | `quiz_questions.json` | 60 |
| Adivinhe o Jogador | `career_players.json` | 30 |
| Quem Vestiu o Manto | `guess_players.json` | 173 |
| Adivinhe a Escalação | `lineup_matches.json` | 31 partidas |
| Escalação da Torcida | não exportado (`goias_squad.dart`, Dart) — votos ficam em `match_lineup_votes`, não é conteúdo de referência | 31 jogadores |
| Identidade Futebolística | não exportado (`tactical_coach_references.dart`, Dart) | 12 técnicos |
| Que Craque Esmeraldino É Você | não exportado (`player_identity_references.dart`, Dart) | 21 jogadores |

Todo progresso/pontuação do usuário fica em tabelas Supabase separadas (`user_game_item_progress`, `score_events` etc.) — nunca exportado aqui porque é dado de usuário, não de conteúdo do clube.

## Quiz

Ver "Arena" acima — `quiz_questions.json`, 60 perguntas, 3 níveis de dificuldade (torcedor/esmeraldino/fanático).

## Passaporte

Ver "Partidas" acima. Ranking e presenças (`passport_attendances`) são dado de usuário, não exportados.

## Loja

Catálogo: JSON local (`lib/assets/content/store_products.json`, 104 produtos) — **não é Supabase-backed**, então não passa pelo script de exportação (já é JSON, mas fora do escopo de `data_export/goias/` por já viver no próprio app). Pedidos/endereços são dado de usuário.

## Sócio

Planos: hardcoded Dart (`membership_plans_catalog.dart`, 6 planos). FAQ: Supabase, 10 categorias/33 itens → `membership_faq_categories.json`/`membership_faq_items.json`. Regulamento: gerado de Markdown, 1 versão vigente → `membership_regulation_versions.json`.

## Fontes — de onde cada informação veio

Ver `04_external_integrations.md` pro detalhe completo. Resumo:

| Fonte | Tipo | Estabilidade |
|---|---|---|
| JSON fornecido pelo usuário (partidas 2000-2026) | Importação manual única | Alta — imutável, já dentro do banco |
| Site oficial (goiasec.com.br) | Scraping ao vivo (notícias) | Frágil — quebra a qualquer mudança de template |
| OneFootball (via Worker) | API não-documentada, reverse-engineered | Média — já trocou de provedor antes |
| Apify → Instagram | Scraping-as-a-service, 3x/dia | Média — sujeita a bloqueio da Meta |
| YouTube Data API | API oficial | Alta |
| X/Twitter | **JSON estático, sync manual offline** | Muito baixa — não é ao vivo |
| ViaCEP / IBGE | APIs públicas oficiais | Alta |
| Futebol de Goyaz | Pipeline pausado, nunca chegou ao app | N/A — não em uso |

---

## Índice de arquivos exportados (`data_export/goias/`)

```
squad_members.json                    31 registros
career_players.json                   30 registros
guess_players.json                    173 registros
lineup_matches.json                   31 registros
quiz_questions.json                   60 registros
club_board_sections.json              6 registros
club_board_members.json               18 registros
club_transparency_topics.json         22 registros
club_transparency_documents.json      122 registros
membership_faq_categories.json        10 registros
membership_faq_items.json             33 registros
membership_regulation_versions.json   1 registro
venues.json                           160 registros
passport_matches.json                 1.697 registros
```

Gerados por `tooling/multiclub/export_seed_data.mjs` — reaproveitável, roda de novo se os `.sql` em `supabase/` mudarem (`node tooling/multiclub/export_seed_data.mjs`).

## Outros documentos desta auditoria

- `01_current_architecture.md` — arquitetura geral
- `03_data_sources.md` — mapa feature-a-feature + auditoria de jogadores
- `04_external_integrations.md` — integrações externas em detalhe
- `05_goias_hardcodes.md` — hardcodes de marca e regras específicas
- `06_database_audit.md` — inventário completo do Supabase
- `07_data_coverage.md` — matriz de cobertura de campo

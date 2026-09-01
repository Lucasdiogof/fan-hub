# 08 — Contrato de Dados Universal (multi-clube)

> Proposta de modelo capaz de atender Goiás + Juventude + Mirassol + Cuiabá + outros, desenhada em cima dos dados REAIS encontrados na auditoria (não no escuro). Gerado em 2026-09-01. Isto é uma PROPOSTA — nada aqui foi implementado.

## Critério de classificação

Uma entidade é **GLOBAL** se o mesmo registro faz sentido pra qualquer clube sem duplicação (ex.: um estádio existe independente de quem joga nele). É **CLUB-SCOPED** se o conteúdo em si é a identidade de um clube (elenco, quiz, produtos). É um **RELACIONAMENTO** quando liga uma entidade global a um clube (ex.: "este técnico passou por ESTE clube nesta época"). É **USER-SCOPED + CLUB-SCOPED** quando é progresso/dado pessoal de um torcedor amarrado ao conteúdo de um clube específico.

## GLOBAL

Entidades que já são (ou deveriam virar) independentes de clube — um Mirassol e um Goiás compartilham a MESMA linha, nunca duplicam.

| Entidade | Hoje | Proposta |
|---|---|---|
| `venues` (estádios) | Já é uma tabela única, sem `club_id`, correta | Manter como está — 160 estádios do histórico do Goiás já cobrem grande parte do futebol brasileiro; crescer organicamente conforme outros clubes importarem histórico |
| `people` (pessoas — jogadores/técnicos como indivíduos) | **Não existe** — cada feature tem sua própria cópia de "jogador" | **Nova tabela.** Um jogador é uma PESSOA (nome, nascimento, nacionalidade) independente de qual clube ele jogou. Ver `club_player_stints` abaixo pra ligar pessoa↔clube↔período. |
| `competitions` (campeonatos) | Só existe como string livre em `passport_matches.competition`/`competition_code` | **Nova tabela.** Brasileirão Série A/B, Copa do Brasil, Libertadores etc. já são as mesmas competições pra qualquer clube brasileiro — não devem ser reinventadas por clube. |
| `seasons` | Só existe como int em `passport_matches.season` | Pode continuar como campo simples (int), não precisa virar tabela — não há dado adicional a pendurar nela hoje. |
| Mecanismo de ranking (`user_game_item_progress`/`score_events`) | Genérico na estrutura, mas o namespace de `game_id` é compartilhado entre clubes hoje (problema, ver `09`) | Manter o MECANISMO global; resolver o namespace via `club_id` na tabela de conteúdo referenciada, não aqui |
| `user_notification_tokens` / `user_notification_preferences` | Já genéricas | Manter global |
| `delivery_addresses` / `store_order_items` | Já genéricas | Manter global |
| ViaCEP/IBGE/FCM/Sentry (integrações) | Já genéricas | Nenhuma mudança |

## CLUB-SCOPED

Entidades que são a IDENTIDADE de um clube — cada linha pertence a exatamente um `club_id`.

```
clubs                          -- nova tabela raiz: id, slug, name, short_name, founded_year, ...
squad_members                  -- + club_id
quiz_questions                 -- + club_id
career_players                 -- + club_id
guess_players                  -- + club_id
lineup_matches                 -- + club_id
passport_matches                -- + club_id
club_board_sections/members     -- + club_id
club_transparency_topics/docs   -- + club_id
membership_faq_categories/items -- + club_id
membership_regulation_versions  -- + club_id
store_orders                    -- + club_id (o prefixo "GOI-" do número de pedido também precisa virar `clubs.order_prefix`)
tickets / ticket_orders / ticket_checkin_decisions -- + club_id
match_monitor_sessions / notification_events        -- + club_id
tactical_coach_references / player_identity_references -- hoje em Dart, precisam virar tabela + club_id se forem multi-clube
```

Conteúdo hoje só em Dart hardcoded (história, hino, títulos, planos de sócio, produtos da loja) — **precisa migrar pra tabela CLUB-SCOPED no Supabase** antes de existir um segundo clube, porque hoje são literalmente compilados no binário do app (impossível ter conteúdo diferente por build sem recompilar tudo, o que já é verdade, mas pelo menos fica centralizado e auditável).

## RELACIONAMENTOS

Ligam uma entidade GLOBAL a um clube, com contexto temporal.

```
club_player_stints             -- person_id, club_id, period, appearances, goals, loan, position
                                --   (substitui o jsonb `club_history`/`club_career` espalhado
                                --    em squad_members/career_players hoje — mesma ideia, só
                                --    normalizada numa tabela, permitindo consultar "todo mundo
                                --    que já jogou nos dois clubes X e Y", por exemplo)
club_coach_stints               -- person_id, club_id, period, x, y, hidden dims (tactical_identity)
club_competitions                -- club_id, competition_id, seasons_participated[]
```

## USER-SCOPED + CLUB-SCOPED

Dado de um torcedor específico, sempre amarrado ao conteúdo de UM clube (o clube do app que ele está usando).

```
passport_attendances            -- já é user+match; falta club_id explícito (via match ou direto)
ranking_scores (user_game_item_progress/score_events) -- falta o game_id/item_id apontarem
                                --   pra conteúdo já club-scoped, o que resolve o isolamento
quiz_progress (quiz_question_progress) -- idem
supporter_memberships            -- + club_id (hoje aponta pra um dos 6 planos hardcoded do Goiás)
```

**Princípio de isolamento**: nenhuma RPC deve poder retornar/gravar dado de um `club_id` diferente do clube do app que está chamando. Na prática (ver `09_supabase_migration_plan.md`), isso significa toda RPC `SECURITY DEFINER` que hoje confia implicitamente em "só existe um clube" precisa passar a filtrar por `club_id` explicitamente — nunca inferido.

## O que muda pro modelo de Jogador especificamente

A auditoria (`03_data_sources.md`) achou 6 fontes de jogador com 3 esquemas de ID e divergências reais de dado pro mesmo jogador. O contrato universal força uma decisão: **uma pessoa é uma linha em `people`, ponto** — `career_players`, `guess_players`, `squad_members` deixam de guardar dado biográfico duplicado e passam a ser **catálogos de referência pro CONTEÚDO DE UM JOGO** (ex.: "guess_players" é a lista de quem aparece no jogo Quem Vestiu o Manto, não uma segunda fonte de biografia) que referenciam `people.id` por FK. Isso elimina a colisão de nome ("danilo" = duas pessoas diferentes hoje) e as divergências de número de jogos (Tadeu 398 vs 400) de uma vez, porque passa a existir só UMA linha de verdade por passagem clube-jogador (`club_player_stints`), nunca duas cópias divergentes.

Isso é uma mudança de schema real, não cosmética — recomendo tratá-la como seu próprio projeto de migração de dado (mapear os ~230-260 nomes pra `people`, decidir critério de match/dedupe, escrever a migração), não algo pra fazer de passagem dentro da migração multi-clube. Ver `09_supabase_migration_plan.md` pra sequenciamento sugerido.

## Diagrama simplificado

```
clubs (global, raiz)
  ├─ squad_members, quiz_questions, career_players, guess_players,
  │  lineup_matches, passport_matches, club_board_*, club_transparency_*,
  │  membership_*, store_orders, tickets*                      (club-scoped)
  │
  ├─ club_player_stints ─── people (global)
  ├─ club_coach_stints  ─── people (global)
  └─ club_competitions  ─── competitions (global) ─── venues (global, via passport_matches)

user (auth.users)
  ├─ passport_attendances ─── passport_matches (club-scoped)
  ├─ user_game_item_progress ─── quiz_questions/career_players/... (club-scoped)
  └─ supporter_memberships ─── clubs (club-scoped)
```

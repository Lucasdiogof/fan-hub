# 09 — Plano de Migração Supabase (multi-clube)

> Proposta — nada aqui foi executado. Parte de um único projeto Supabase existente (`yonozsdgyrhgqrvydbnr`), preservando free tier via multi-tenant (`club_id`), conforme preferência explícita. Gerado em 2026-09-01.

> **STATUS: HISTORICAL / NEEDS_RECONCILIATION** (nota adicionada na M1, 2026-09-02). Este documento é anterior à série F e à M1 — a decisão de fundo (Supabase compartilhado, multi-tenant via `club_id`) **continua válida e foi revalidada na M1** (`docs/multiclub/28_etapa_m1_report.md`), mas 2 detalhes concretos deste plano estão SUPERSEDED pelo schema real construído desde então:
> 1. **Passo 1 propõe `clubs.id text primary key` (slug)** — o `clubs` real (`supabase/migrations/20260902020000_create_clubs.sql`) usa **`id uuid primary key` + `slug text unique` separado**. Qualquer `club_id` novo deve ser `uuid references clubs(id)`, nunca `text references clubs(slug)`.
> 2. **A tabela "Passo 2" trata `career_players`/`guess_players`/`squad_members`/`lineup_matches`/`passport_matches` como 🟢 "simples"** — a auditoria da M1 mostrou que adicionar `club_id` a essas tabelas resolve só ROW_SCOPE (filtro), nunca KEY_SCOPE sozinho (a PK continua sendo só `id` texto — `'tadeu'` ainda colidiria entre 2 clubes sem uma PK composta ou um id surrogate). Não é "simples" como rotulado aqui.
>
> A migração real de identidade de jogador (`people`/`club_player_stints`) também já aconteceu, mas por um desenho DIFERENTE do proposto aqui (ver Etapas B-F7 e `28_etapa_m1_report.md`) — `career_players` etc. nunca ganharam FK pra `people`, só um `person_id` nullable opcional. Ver `28_etapa_m1_report.md` pra o desenho de M2 que reconcilia este plano com o que foi construído.

## Princípio geral

Um projeto Supabase só, uma tabela `clubs` na raiz, `club_id` (FK pra `clubs.id`) em toda tabela de conteúdo, RLS reforçada pra nunca vazar dado entre clubes. **Nenhuma tabela muda de nome** (evita quebrar RPCs/repositórios existentes desnecessariamente) — a mudança é aditiva: nova coluna `club_id` + novo índice + RLS atualizada.

## Passo 0 — pré-requisitos (bloqueantes)

Antes de qualquer coisa, resolver os 3 gaps encontrados em `06_database_audit.md §4/§9`:
1. Recuperar o schema real de `public.profiles` e `public.user_addresses` (pg_dump ou export do dashboard) — hoje não existem no repo.
2. Recuperar a definição do trigger `handle_new_user`.
3. Confirmar/documentar o bucket `avatars` do Storage (criação + policy).

Sem isso, qualquer migration escrita corre risco de assumir uma coluna/policy que não bate com o ambiente real.

## Passo 1 — tabela raiz `clubs`

```sql
create table public.clubs (
  id text primary key,              -- slug, ex.: 'goias', 'juventude'
  name text not null,
  short_name text not null,
  order_prefix text not null,       -- substitui o "GOI-" hardcoded em generate_store_order_number()
  onefootball_slug text,
  onefootball_competition_slug text,
  created_at timestamptz not null default now()
);
```
Seed inicial: uma linha só, `('goias', 'Goiás Esporte Clube', 'Goiás', 'GOI', 'goias-1863', 'brasileirao-serie-b-superbet-119')`.

## Passo 2 — tabela por tabela

Legenda: 🟢 adicionar `club_id` (simples) · 🟡 adicionar `club_id` + revisar RPC que a referencia · 🔴 requer decisão de produto antes de migrar · ⚪ manter global, sem mudança

| Tabela | Ação | Por quê |
|---|---|---|
| `squad_members` | 🟢 | conteúdo puramente club-scoped, sem RPC complexa em cima |
| `quiz_questions` | 🟢 | idem |
| `career_players` | 🟢 | idem |
| `guess_players` | 🟢 | idem |
| `lineup_matches` | 🟢 | idem |
| `club_board_sections`/`club_board_members` | 🟢 | idem |
| `club_transparency_topics`/`documents` | 🟢 | idem |
| `membership_faq_categories`/`items`/`regulation_versions` | 🟢 | idem |
| `venues` | ⚪ | GLOBAL por design — ver `08_multiclub_data_contract.md` |
| `passport_matches` | 🟢 | club-scoped, sem RPC complexa além de leitura filtrada |
| `passport_attendances`/`passport_memorable_matches`/`passport_sync_runs` | 🟡 | `club_id` via FK de `match_id` já resolve isolamento de leitura, mas as RPCs (`passport_save_attendances` etc.) precisam validar que o `match_id` recebido pertence ao clube do app chamador |
| `user_game_item_progress`/`score_events` | 🟡 | **precisa de decisão**: ou o `game_id` passa a ser namespaced por clube (`goias:quiz` vs `juventude:quiz`), ou a tabela ganha `club_id` direto. Recomendo `club_id` direto — mais simples de indexar/filtrar que parsear string |
| `arena_record_score` (RPC) | 🔴 | **reescrever** — hoje hardcoda os 4 `game_id`s e assume que "o" `career_players`/`quiz_questions`/etc. é de um clube só. Precisa receber `club_id` e validar `item_id` dentro da tabela de conteúdo DAQUELE clube |
| `subscribe_to_plan` (RPC) | 🔴 | **reescrever** — hoje hardcoda os 6 planos do Sócio Esmeralda dentro do corpo da função. Precisa: (a) planos virarem uma tabela `membership_plans` club-scoped, (b) a RPC receber `club_id`+`plan_id` e validar contra essa tabela em vez de uma lista fixa |
| `supporter_memberships` | 🟢 | segue a mudança acima |
| `store_orders`/`store_order_items` | 🟡 | `generate_store_order_number()` precisa ler `clubs.order_prefix` em vez do literal `"GOI"` |
| `delivery_addresses` | ⚪ | genuinamente global (endereço não pertence a clube) |
| `tickets`/`ticket_orders`/`ticket_checkin_decisions` | 🟢 | club-scoped via `match_id`, mas considerar `club_id` direto pra simplificar RLS |
| `user_notification_tokens`/`preferences` | ⚪ | global |
| `match_monitor_sessions`/`notification_events`/`notification_deliveries` | 🟡 | as Edge Functions que escrevem aqui hoje têm o Worker URL + `team/goias` + `GOIAS_TEAM_ID=1863` hardcoded — precisam de `club_id` propagado desde a config do Worker (ver abaixo) |
| `tactical_identity_results`/`player_identity_results` | ⚪ (tabela) / 🔴 (dataset de referência) | a tabela de RESULTADO do usuário já é genérica; o dataset de REFERÊNCIA (12 técnicos, 21 jogadores) está em Dart hoje — precisa virar tabela `club_coach_references`/`club_player_style_references` club-scoped se cada clube tiver seu próprio |
| `profiles`/`user_addresses` | ⚪ | genuinamente global — 1 pessoa pode torcer/usar apps de clubes diferentes com a mesma conta (decisão de produto a confirmar, mas tecnicamente não há motivo pra duplicar perfil por clube) |

## Passo 3 — Worker Cloudflare (fora do Supabase, mas parte do mesmo fluxo)

O Worker já parametriza `GOIAS_ONEFOOTBALL_SLUG`/`ONEFOOTBALL_COMPETITION_SLUG` via `wrangler.toml` — bom precedente. Falta generalizar:
- Rotas: `/api/football/team/goias` → `/api/football/team/:clubSlug`, resolvendo o slug do OneFootball a partir de `clubs.onefootball_slug` (via uma chamada rápida ao Supabase, ou um mapa estático no Worker se preferir não dar ao Worker acesso de leitura ao Supabase).
- Chaves de cache: `football.team.goias` → `football.team.${clubSlug}`.
- Scraper de notícias: **não generaliza automaticamente** — cada clube com site oficial diferente precisa de um parser HTML novo (ver `04_external_integrations.md`). Não é uma migration, é trabalho de engenharia por clube.
- Edge Functions de notificação (`notifications-sync-and-check-access`, `notifications-poll-live-match`): trocar a URL hardcoded do Worker + `GOIAS_TEAM_ID=1863` por parâmetros lidos de `clubs`.

## Passo 4 — RLS

Padrão novo pra toda tabela club-scoped com leitura pública: manter `for select using (true)` (leitura pública já é aceitável — não há dado sensível em conteúdo de jogo/quiz), mas a APLICAÇÃO (Flutter) sempre filtra por `club_id` na query — nunca confia em "só existe uma linha possível". Pra tabelas de progresso/user-scoped, RLS já é `auth.uid() = user_id`; adicionar `club_id` não muda a policy em si, só o índice/query pattern.

## Passo 5 — sequenciamento recomendado

1. Passo 0 (gaps) + Passo 1 (`clubs`) + seed do Goiás.
2. Migrations 🟢 em lote (são todas o mesmo padrão: `alter table ... add column club_id text not null default 'goias' references clubs(id)`, depois `alter column ... drop default` quando tudo estiver migrado).
3. Migração de dado de jogador pra `people`/`club_player_stints` (ver `08_multiclub_data_contract.md`) — projeto à parte, não misturar com o rollout de `club_id`.
4. Reescrever as 2 RPCs 🔴 (`arena_record_score`, `subscribe_to_plan`) + criar `membership_plans`.
5. Generalizar o Worker (rotas + Edge Functions).
6. Só então: `ClubConfig` no Flutter (ver `10_club_config.md`) consumindo `club_id` fixo por flavor.

## O que NÃO fazer

- Não criar `supabase-goias`/`supabase-juventude` como projetos separados — confirmado, contraria a preferência explícita e o objetivo de continuar no free tier.
- Não migrar tabelas ⚪ (genuinamente globais) — adicionar `club_id` nelas seria complexidade sem benefício.
- Não misturar a migração de `club_id` com a migração de jogador pra `people` — são dois problemas diferentes, resolver juntos aumenta o risco de regressão sem necessidade.

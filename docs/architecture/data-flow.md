# Fluxos de dados e de execução

> Cada diagrama foi rastreado no código pela auditoria e conferido por amostragem (ver [README](README.md)). Quando um trecho não foi lido, aparece **NÃO VERIFICADO**. Os diagramas são Mermaid; caminhos são relativos à raiz do repositório.

## Índice
1. [Inicialização](#1-inicialização)
2. [Autenticação](#2-autenticação)
3. [Home](#3-home)
4. [Partidas e partida ao vivo](#4-partidas-e-partida-ao-vivo)
5. [Elenco](#5-elenco)
6. [Notificações push (app + servidor)](#6-notificações-push)
7. [Arena e ranking](#7-arena-e-ranking)
8. [Sócio torcedor](#8-sócio-torcedor)
9. [Ingressos e check-in](#9-ingressos-e-check-in)
10. [Loja e pedidos](#10-loja-e-pedidos)
11. [Passaporte](#11-passaporte)
12. [Entradas por link](#12-entradas-por-link)
13. [Pipeline de conteúdo e dados](#13-pipeline-de-conteúdo-e-dados)
14. [Build e deploy por clube](#14-build-e-deploy-por-clube)

---

## 1. Inicialização

```mermaid
sequenceDiagram
  participant M as main
  participant S as SentryFlutter
  participant F as Firebase
  participant SB as Supabase
  participant DI as get_it
  participant A as GoiasApp
  participant R as GoRouter
  participant SP as SplashVideoPage
  M->>M: resolveActiveClub (APP_CLUB)
  M->>S: init com appRunner
  S->>M: executa appRunner
  M->>F: initializeApp e onBackgroundMessage (so fora do web, com try/catch)
  M->>SB: SupabaseConfig.configure e initialize (SessionAwareHttpClient)
  M->>DI: setupDependencies
  M->>A: runApp
  A->>DI: AuthCubit, Theme, Locale, ClubConfig, AccountSessionCacheGuard, PushNotificationService
  A->>R: createAppRouter com SplashGate e ReleaseGate
  R->>SP: redirect para splash
  SP->>DI: pre-carrega HomeCubit e MembershipStatusCubit (se logado)
  SP->>DI: ReleaseGate.ensureChecked (timeout 3 s)
  SP->>R: SplashGate.complete (fim do video ou fallback de 7 s)
  R->>R: vai para home, login ou update-required
```

Regras relevantes: `APP_CLUB` vazio resolve para Goiás; valor desconhecido lança `StateError` (*fail-fast*). `SupabaseConfig.configure` lança `StateError` se o clube não tiver URL/chave — **nunca** cai no Goiás.

Arquivos: `lib/main.dart`, `lib/core/club/resolve_active_club.dart`, `lib/core/config/{supabase,sentry}_config.dart`, `lib/core/di/injection_container.dart`, `lib/core/router/{app_router,splash_gate}.dart`, `lib/core/release/release_gate.dart`, `lib/features/splash/presentation/pages/splash_video_page.dart`, `lib/core/network/session_aware_http_client.dart`.

## 2. Autenticação

```mermaid
flowchart TD
  A["Splash completa"] --> B{"AuthCubit.state"}
  B -- "Authenticated: sessao restaurada pelo SDK" --> H["Home"]
  B -- "Unauthenticated" --> L["login"]
  L -- "signInWithPassword ok" --> E["evento signedIn"] --> H
  L -- "Criar conta" --> R["register em 3 passos"]
  R -- "RPC cpf_is_taken" --> R
  R -- "signUp com metadata" --> C["check-email"]
  C -- "verifyOTP signup" --> V["verifyEmailOtp: copia metadata para profiles e limpa metadata"]
  V --> E
  L -- "Esqueci a senha" --> P["resetPasswordForEmail"] --> Q["evento passwordRecovery: reset-password"] --> S["updatePassword e signOut"] --> L
  H -- "Sair" --> O["signOut: AuthUnauthenticated"] --> L
  H -- "Excluir conta" --> D["re-autentica senha, Edge delete-account e signOut"] --> L
  H -- "refresh falha de vez" --> X["signedOut sessionExpired: AuthSessionExpired, bottom sheet e login"]
  O --> G["AccountSessionCacheGuard limpa cache local e carrinho"]
  X --> G
  O --> T["PushNotificationService desativa o token"]
```

Notas: o cadastro pendente **não** é retomado; a limpeza de cadastros não confirmados é server-side (`supabase/functions/cleanup-unconfirmed-signups`, cron horário). A exclusão de conta identifica o usuário só pelo JWT. A persistência da sessão usa o padrão do `supabase_flutter` (storage customizado **NÃO VERIFICADO**).

Arquivos: `features/auth/data/{auth_remote_data_source,auth_repository_impl,auth_error_mapper}.dart`, `features/auth/presentation/cubit/{auth_cubit,register_cubit}.dart`, `lib/core/session/*`, `lib/shared/widgets/{session_expiry_listener,session_expired_sheet}.dart`, `supabase/functions/{delete-account,cleanup-unconfirmed-signups}/index.ts`.

## 3. Home

```mermaid
sequenceDiagram
  participant SH as HomeShellPage
  participant HC as HomeCubit
  participant FR as FootballRepository
  participant W as Worker team
  participant CL as CrowdLineupRepository
  SH->>HC: aba Home ativa
  HC->>FR: getActiveClubSnapshot
  FR->>W: GET /api/football/team/clube
  W-->>HC: proximo jogo, resultados recentes e competicao
  HC->>HC: escolhe a partida (ao vivo ou intervalo, depois recem-encerrada, depois proxima)
  HC->>CL: getMyVote se a partida esta aberta
  SH->>HC: LiveMatchPoller faz poll a cada 45 s e recarrega ao fim da partida
```

Arquivos: `features/home/presentation/{pages/home_shell_page,pages/home_page,cubit/home_cubit}.dart`, `features/match/data/**`, `features/match/presentation/widgets/live_match_poller.dart`.

## 4. Partidas e partida ao vivo

```mermaid
sequenceDiagram
  participant G as GamesPage
  participant D as MatchDetailsPage
  participant C as MatchDetailsCubit
  participant R as FootballRepository
  participant W as Worker fixtures
  G->>D: abrir partida (rota match com fixtureId)
  D->>C: cria cubit e carrega
  C->>R: getMatchDetails
  R->>W: GET /api/football/fixtures/id
  W-->>C: partida, eventos, escalacoes e estatisticas
  C->>C: se ao vivo ou intervalo, Timer.periodic de 45 s
  C->>C: pausa e retoma conforme o ciclo de vida
  C->>C: para quando o status deixa de ser ao vivo
```

Rotas relacionadas: `/games/competitions` e `/games/competitions/:id` (classificação e mata-mata via `/api/football/standings`). Arquivos: `features/match/presentation/{cubit/match_details_cubit,pages/match_details_page,pages/games_page}.dart`, `src/football/*.ts`.

## 5. Elenco

`SquadListPage` (`/squad`, `SquadCubit` por factory) → `SupabaseSquadRepository` (tabela `squad_members`) → `/squad/:memberId`, que recebe o `SquadMember` por `state.extra`. A rota nunca é gateada por capability. O detalhe das *queries* é **NÃO VERIFICADO**.

## 6. Notificações push

### 6.1 No app

```mermaid
sequenceDiagram
  participant AC as AuthCubit
  participant PS as PushNotificationService
  participant FM as FirebaseMessaging
  participant NR as SupabaseNotificationRepository
  participant UI as GoRouter
  AC-->>PS: AuthAuthenticated
  PS->>FM: requestPermission (se negada, encerra)
  PS->>FM: token APNs no iOS e depois getToken
  PS->>NR: registerToken (upsert em user_notification_tokens)
  FM-->>PS: onMessage em foreground
  PS->>UI: bottom sheet proprio com titulo, corpo e acao
  FM-->>PS: onMessageOpenedApp ou getInitialMessage
  PS->>UI: partida vai para match, checkin e tickets vao para tickets
  AC-->>PS: Unauthenticated ou SessionExpired
  PS->>NR: deactivateToken (is_active falso)
```

### 6.2 No servidor (Edge Functions + Worker)

```mermaid
sequenceDiagram
  participant CR as pg_cron
  participant SY as notifications-sync-and-check-access
  participant PO as notifications-poll-live-match
  participant W as Worker
  participant DB as Postgres
  participant DI as notifications-dispatch
  participant FCM as FCM v1
  CR->>SY: a cada 30 min
  SY->>W: GET /api/football/team/clube
  SY->>DB: grava match_monitor_sessions e evento de acesso a 48 h do jogo
  CR->>PO: a cada 1 min
  PO->>W: GET /api/football/fixtures/id (so na janela do jogo)
  PO->>PO: detecta kickoff, gol, intervalo, 2o tempo e fim por transicao de status
  PO->>DB: grava notification_events e atualiza a sessao
  PO->>DI: dispara o envio
  CR->>DI: a cada 5 min reprocessa eventos presos
  DI->>DB: le preferencias, tokens e socios
  DI->>FCM: envia
  DI->>DB: grava notification_deliveries e invalida token invalido
```

O push **não** sai do Worker; o Worker só serve dados à Edge Function. Todas as funções do pipeline usam `rejectUnlessServiceCaller`. O app só trata rotas de partida e de ingressos; background handler é vazio.

## 7. Arena e ranking

```mermaid
sequenceDiagram
  participant AP as ArenaPage
  participant GM as Pagina e Cubit do jogo
  participant ST as Storage do jogo
  participant RK as SupabaseArenaRankingRepository
  participant DB as Supabase RPCs
  AP->>GM: abrir jogo (gate por enabledArenaGames)
  GM->>ST: carrega banco e progresso
  GM->>GM: resposta persiste progresso
  GM-->>RK: recordScore sem esperar
  RK->>DB: rpc arena_record_score_for_club
  DB-->>RK: points_delta, item_score, total_score
  AP->>RK: RankingCubit consulta arena_ranking_for_club e arena_my_rank_for_club
```

`recordScore` é chamado pelos cubits de quiz, career_path, guess_player e lineup, e pelas páginas de resultado de player_identity e tactical_identity. O **Penalty não pontua**. A pontuação é calculada no servidor, mas parâmetros como `p_event_type` e `p_attempt_number` são declarados pelo cliente (ver [security-overview.md](security-overview.md), S-05).

## 8. Sócio torcedor

```mermaid
sequenceDiagram
  participant U as Usuario
  participant P as Paginas de membership
  participant MS as MembershipStatusCubit
  participant MR as SupabaseMembershipRepository
  MS->>MR: getMyMembership no login (rpc get_my_membership_for_club)
  U->>P: planos, plano, cadastro
  P->>P: formulario com CEP (ViaCEP e IBGE) e regulamento aceito
  P->>MR: submitRegistration (rpc subscribe_to_plan_for_club)
  MR-->>MS: membership ativa
  MS-->>P: isMember propaga para Home, ingresso, ranking e perfil
```

Os planos **não** vêm do servidor (`ClubConfig.membershipProgram.plans`); `checkIn` do repositório de membership é *stub*; modo de comércio `demo`.

## 9. Ingressos e check-in

```mermaid
sequenceDiagram
  participant TP as TicketsPage
  participant TR as MockTicketRepository
  participant FR as FootballRepository
  participant CI as CheckInCubit
  participant DB as Supabase
  TP->>TR: getFeaturedEvent
  TR->>FR: getActiveClubSnapshot (partida real)
  TR-->>TP: evento com setores e precos de fixture
  TP->>CI: tela de check-in
  CI->>TR: checkIn (partida, setor, titular)
  TR->>DB: upsert em ticket_checkin_decisions
  TR->>DB: rpc upsert_membership_checkin_ticket_for_club
  DB-->>CI: ingresso exibido com PDF e QR
```

A compra insere em `tickets`/`ticket_orders` direto do app, sem gateway. Disponível em Goiás e Vila Nova. Observação de clube: o QR do PDF usa o prefixo fixo `GOIAS-EC-` (`DEMO-GOIAS-EC-` em modo demo, que é o modo de todos os clubes hoje) — ver [multi-club.md](multi-club.md).

## 10. Loja e pedidos

```mermaid
sequenceDiagram
  participant SH as Paginas da loja
  participant SR as MockStoreRepository
  participant CC as CartCubit
  participant CK as CheckoutCubit
  participant OR as SupabaseStoreOrdersRepository
  participant DB as Supabase
  SH->>SR: getProducts (JSON de assets do clube)
  SH->>CC: adicionar item
  CK->>SR: frete e cupom simulados
  CK->>OR: createOrder
  OR->>DB: rpc create_store_order_for_club
  DB-->>CK: numero e data do pedido
```

Existe um ramo local acima da RPC cuja condição **NÃO foi verificada**. Loja desabilitada no Vila Nova.

## 11. Passaporte

```mermaid
sequenceDiagram
  participant AP as Arena ou Perfil
  participant PG as PassportPage e PassportCubit
  participant PR as SupabasePassportRepository
  participant DB as Supabase RPCs
  AP->>PG: abrir (gate hasPassport)
  PG->>PR: temporadas e jogos do ano
  PR->>DB: passport_seasons e passport_matches_for_year
  PG->>PR: resumo
  PR->>DB: passport_summary e passport_stadium_summary
  PG->>PR: marcar presenca ou jogo marcante
  PR->>DB: passport_save_attendances e passport_set_memorable_match
  PG->>PR: ranking e trajetoria
  PR->>DB: passport_ranking, passport_my_rank, passport_attended_matches, passport_attendance_breakdown
```

São 11 RPCs `passport_*`. Atenção a segurança: ver S-01 em [security-overview.md](security-overview.md).

## 12. Entradas por link

Não há deep link nativo. As entradas por link são: (a) **web**, onde a URL é a rota `go_router`; (b) **push**, via `_navigate`; (c) **e-mail** de reset/confirmação, via `SupabaseConfig.redirectUrl`. Detalhes em [navigation.md](navigation.md).

## 13. Pipeline de conteúdo e dados

O conteúdo canônico (pessoas, partidas, passagens de jogadores, passaportes históricos, elencos, quizzes) **não** nasce no app: é gerado por scripts em `tooling/`, vira SQL e é aplicado em cada projeto Supabase.

```mermaid
flowchart LR
  SRC["Fontes externas: ogol, sites oficiais, Wikipedia, esmeraldino"] --> COL["tooling/*: coleta e validacao"]
  COL --> REG["registries JSON (clubs, matches, people, spells)"]
  REG --> GEN["generate_*_seed.mjs e generate_*_migration.mjs"]
  GEN --> SQL["supabase/*.sql soltos e supabase/migrations"]
  SQL --> RUN["tooling/multiclub/run-sql-file.mjs e db-push.mjs (exigem --yes)"]
  RUN --> DB[("Supabase de cada clube")]
  AUD["audit_*.mjs e test_*.mjs"] -.-> REG
  AUD -.-> SQL
```

- `db-push.mjs <clube>` aplica **somente** `supabase/migrations/`; seeds soltos vão por `run-sql-file.mjs`. Ambos validam o *project ref* contra `tooling/multiclub/supabase_projects_registry.json` e exigem `--yes` para escrever.
- Cada pasta de `tooling/` e o que ela alimenta está descrita em [backend-integrations.md](backend-integrations.md) §6.
- Cuidado conhecido: as migrations de correção de dados do Goiás (`20260930…` a `20261002…`) estão na **mesma** cadeia aplicada a todos os clubes (ver [technical-debt.md](technical-debt.md)).

## 14. Build e deploy por clube

```mermaid
flowchart TD
  Q["flutter build com --flavor X e --dart-define=APP_CLUB=X"] --> APK["Android APK ou AAB por flavor"]
  Q --> IOS["iOS por scheme"]
  WB["node tool/build_web_flavor.mjs X"] --> WEB["build/flavors/web/X"]
  WEB --> WK["Worker X: ASSETS + /api (wrangler)"]
  CFB["Cloudflare Workers Builds: tool/cloudflare_build_web_flavor.sh X"] --> WEB
  MIG["supabase/migrations (cadeia unica)"] --> DBX["db-push.mjs X"] --> SBX["Supabase X"]
  EFD["Edge Functions: deploy manual (colar no dashboard)"] --> SBX
```

Não existe CI de testes nem de deploy no repositório; o único workflow é `.github/workflows/sync_x_posts.yml`. O deploy das Edge Functions é manual, segundo comentários nos próprios arquivos.

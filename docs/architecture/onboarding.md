# Onboarding técnico

> Guia para quem está chegando ao `fan-hub`. Combina o roteiro guiado do grafo de conhecimento (`/understand-onboard`) com as auditorias desta análise. Comandos foram retirados do `README.md`, do `package.json` e de `tool/flavor_build_commands.json`; nenhum foi executado aqui. O que não foi confirmado está marcado **NÃO VERIFICADO**.

## 1. Em cinco ideias

1. **Um código, três clubes.** Goiás EC, RB Bragantino e Vila Nova FC saem da mesma base. O clube ativo é escolhido em **build** por `--dart-define=APP_CLUB=<code>` e descrito por um `ClubConfig` (`lib/core/club/`).
2. **Capabilities decidem o que existe.** Cada clube liga/desliga features (loja, ingressos, escalação da torcida…) em `ClubCapabilities`; o router e a Home respeitam essas flags.
3. **Duas fontes de dados.** Dados esportivos, notícias e social vêm do **Worker Cloudflare** (`src/`, via Dio); dados do usuário e conteúdo do clube vêm do **Supabase** (RLS + RPCs). Um Worker e um projeto Supabase **por clube**.
4. **Cubits + `get_it` + `go_router`.** Estado só com Cubits; repositórios devolvem `Result<T>`; dependências em `lib/core/di/injection_container.dart`.
5. **Comércio é demo.** Ingressos e loja usam repositórios `Mock*` sem pagamento real, mas **persistem pedidos e check-ins no Supabase**.

## 2. Preparando o ambiente

```bash
# Flutter fixado em 3.44.1 (.fvmrc); Dart ^3.12.1
flutter pub get
flutter analyze
flutter test
```

Rodar o app (o `README` mostra `flutter run`; para escolher o clube de forma explícita use o par abaixo — **sempre os dois juntos**, ver §6):

```bash
flutter run --flavor goias --dart-define=APP_CLUB=goias
flutter run --flavor bragantino --dart-define=APP_CLUB=bragantino
flutter run --flavor vilanova --dart-define=APP_CLUB=vilanova
```

Worker (Cloudflare):

```bash
npm install
npm run dev:worker      # ambiente local
npm run test:worker     # vitest (inclui helpers das Edge Functions)
```

Web por clube: `node tool/build_web_flavor.mjs <clube>` (saída em `build/flavors/web/<clube>`).

Pré-requisitos extras: assinatura de release Android exige `android/key.properties` (não versionado); iOS usa *schemes* por flavor; Supabase CLI **não** é usado localmente (não há `supabase start`).

## 3. Roteiro guiado (15 passos)

| # | Passo | Onde olhar |
|---|---|---|
| 1 | Visão geral | `README.md`, `pubspec.yaml`, `CHANGELOG.md` |
| 2 | Bootstrap do app | `lib/main.dart`, `core/config/{supabase,sentry}_config.dart` |
| 3 | Flavors e configuração multi-clube | `core/club/{club_config,club_registry,resolve_active_club}.dart` e as 3 `*_club_config.dart` |
| 4 | Flavors nas plataformas nativas | `android/app/build.gradle.kts`, `ios/Flutter/Flavors/*.xcconfig`, `ios/Runner/Firebase/*`, `tool/web_flavors/*.json` |
| 5 | DI e erros | `core/di/injection_container.dart`, `core/error/{result,failures}.dart`, `core/network/*` |
| 6 | Router, splash e sessão | `core/router/{app_router,splash_gate}.dart`, `core/club/capability_route_gate.dart`, `core/session/account_session_cache_guard.dart` |
| 7 | Design system e widgets | `core/theme/*`, `shared/state/load_status.dart`, `shared/widgets/state_message.dart` |
| 8 | Partidas: domínio e dados | `features/match/{domain,data}/**` |
| 9 | Ingressos ponta a ponta | `features/ticket/**` |
| 10 | Autenticação | `features/auth/**` |
| 11 | Supabase: schema e migrations | `supabase/migrations/20260904000000_canonical_baseline.sql`, `infra/supabase/clubs/*/bootstrap.sql` |
| 12 | Cloudflare Workers | `src/index.ts`, `src/football/_lib/*`, `wrangler*.toml` |
| 13 | Edge Functions e push | `supabase/functions/_shared/*`, `notifications-*` |
| 14 | Testes | `test/core/club/*`, `test/features/*/fakes/*`, `src/**/*.test.ts` |
| 15 | Tooling, CI e docs | `tooling/multiclub/*`, `.github/workflows/sync_x_posts.yml`, `docs/multiclub/*` |

O tour completo (com descrições) está no grafo: `/understand-dashboard`.

## 4. Mapa de arquivos por camada

| Camada (grafo) | Arquivos | Onde começar |
|---|---:|---|
| Core e Shared | 104 | `core/club/*`, `core/di/*`, `core/router/*`, `core/error/*`, `shared/*` |
| Apresentação das Features | 375 | `features/<feature>/presentation/{cubit,pages,widgets}` |
| Domínio das Features | 122 | `features/<feature>/domain/{entities,repositories}` (puro Dart) |
| Dados das Features | 100 | `features/<feature>/data/**` (Supabase, Dio, catálogos) |
| Banco de Dados Supabase | 127 | `supabase/migrations/*`, `supabase/*.sql` (referência e seeds) |
| Backend Edge e Workers | 63 | `src/**`, `supabase/functions/**` |
| Testes | 207 | `test/**`, `src/**/*.test.ts` |
| Tooling e Scripts | 178 | `tooling/**`, `scripts/**`, `tool/**` |
| Plataformas, CI e Configuração | 87 | `android/`, `ios/`, `web/`, `wrangler*.toml`, `.github/` |
| Documentação | 76 | `docs/**`, `README.md` |

Para um mapa por feature veja [feature-map.md](feature-map.md); para rotas, [navigation.md](navigation.md).

## 5. Tarefas comuns

**Adicionar uma tela/feature.** Siga o padrão `presentation/` + `domain/` + `data/`; registre repositórios em `injection_container.dart`; crie a rota em `app_router.dart` e, se for opcional por clube, adicione a capability em `ClubCapabilities` e o gate em `capability_route_gate.dart`. Prefira passar dados por parâmetros de rota em vez de `state.extra!` (ver §6).

**Ligar/desligar algo para um clube.** Edite `capabilities` no `*_club_config.dart` correspondente. A matriz atual está em [feature-map.md](feature-map.md) §1.

**Adicionar uma migration.** Crie o arquivo em `supabase/migrations/` (regra de `supabase/MIGRATIONS.md`) e aplique por clube com `node tooling/multiclub/db-push.mjs <clube> --dry-run` antes de `--yes`. Cuidado: a cadeia é **compartilhada** pelos três projetos; migrations de dados específicas do Goiás hoje estão misturadas (ver [technical-debt.md](technical-debt.md) A2). `MIGRATIONS.md` está parcialmente desatualizado (usa `db-push.mjs` e o baseline canônico, que ele não cita).

**Rodar um seed/SQL solto.** `node tooling/multiclub/run-sql-file.mjs <clube> <arquivo.sql> --yes` (exige `<CLUBE>_DB_URL` no ambiente; nunca commite connection strings).

**Adicionar uma rota ao Worker.** `src/index.ts` (+ handler em `src/football|news|social|media`); lembre do `CACHE_VERSION` em `wrangler*.toml` e dos testes `*.test.ts` ao lado do código.

**Adicionar um clube novo.** Os pontos de contato (verificados em [multi-club.md](multi-club.md)): `ClubConfig` + registro Dart, `ClubServerConfig` no Worker e nas Edge Functions, `wrangler.<clube>.toml`, flavor Android/iOS/web, Firebase (app por pacote/bundle), projeto Supabase + `supabase_projects_registry.json` + `infra/supabase/clubs/<clube>/bootstrap.sql`, e seeds. Há um plano em `docs/multiclub/14_juventude_onboarding_plan.md` e o contrato de dados em `docs/multiclub/08_multiclub_data_contract.md`; o runbook do Vila Nova (`docs/multiclub/60_vilanova_seeds_runbook.md`) é o exemplo mais recente.

**Alterar conteúdo de dados (jogadores, passaportes, quizzes).** O conteúdo é gerado por `tooling/` e `scripts/` (ver [data-flow.md](data-flow.md) §13); não edite os JSON de `data_export/` à mão.

## 6. Armadilhas conhecidas

1. **`--flavor` sem `APP_CLUB`** gera um app com a identidade de um clube e a configuração do Goiás (nada cruza os dois). Passe sempre os dois.
2. **Recarregar uma rota com `state.extra!`** no web quebra a tela (24 usos em `app_router.dart`).
3. **`sl<T>()` fora da composição** (páginas, router e até uma entidade de domínio da loja) cria um ciclo de 12 arquivos; evite acrescentar mais.
4. **`audit_*.mjs` gravam em `data_export/`:** rodá-los suja o working tree.
5. **Migrations só-Goiás** na cadeia comum podem abortar um `db-push` em outro clube.
6. **"Mock" ≠ em memória:** `MockTicketRepository` e `MockStoreRepository` persistem no Supabase.
7. **Dados do Goiás aparecendo em outros clubes:** Career Path (`goiasPlayers`) e o QR/PDF do ingresso — ver [multi-club.md](multi-club.md) §2.
8. **Projeto Firebase e Sentry únicos** para os 3 clubes.
9. **Pacote e classe raiz ainda se chamam `goias_app`/`GoiasApp`.**
10. **Não há CI**; rode `flutter analyze`, `flutter test` e `npm run test:worker` localmente antes de abrir PR.

## 7. Pontos de complexidade (onde ir com cuidado)

O grafo marca 305 arquivos como `complex` (152 em `lib/`). Os que mais importam, por tamanho e/ou dependência:

| Arquivo | Por quê |
|---|---|
| `core/router/app_router.dart` (852 linhas) | 87 rotas, `redirect` de 6 estágios, 24 `state.extra!`, 0 testes |
| `core/di/injection_container.dart` | 132 dependentes e parte do ciclo |
| `core/club/*_club_config.dart` | muito conteúdo por clube, placeholders e `DATA_GAP` |
| `features/store/presentation/pages/checkout_page.dart` (1.367) e `product_detail_page.dart` (1.142) | páginas gigantes; checkout sem teste |
| `features/passport/presentation/pages/passport_trajectory_page.dart` (1.133) | página grande, duas variantes de UI (v1/v2) |
| `features/arena/games/guess_player/data/guess_player_catalog.dart` (2.259) | catálogo de dados em código |
| `supabase/migrations/20260904000000_canonical_baseline.sql` (2.807) | schema canônico, RPCs `SECURITY DEFINER` |

## 8. Segurança em uma linha

Chaves no repositório são só as públicas por desenho (Supabase *publishable*, Firebase cliente, Sentry DSN); **nunca** use `service_role` no cliente. O item de maior atenção é o baseline reintroduzir RPCs `passport_*` legíveis por `anon`: leia [security-overview.md](security-overview.md) antes de criar um projeto Supabase novo.

## 9. Para ir além

- [architecture-overview.md](architecture-overview.md) → visão geral e diagramas
- [data-flow.md](data-flow.md) → fluxos rastreados no código
- [backend-integrations.md](backend-integrations.md) → Supabase, Worker, Firebase, tooling
- [testing-overview.md](testing-overview.md) → o que existe e o que falta
- [technical-debt.md](technical-debt.md) → o que corrigir primeiro
- `docs/multiclub/*` → histórico detalhado do rollout multi-clube
- Grafo interativo: `/understand-dashboard` (arquivos em `.ua/`)

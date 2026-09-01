# 01 — Arquitetura Atual (goias-app)

> Gerado em 2026-09-01 a partir de auditoria automatizada do código. Todas as afirmações citam arquivo/linha; nada aqui foi inferido sem evidência.

## 1. Estrutura de `lib/`

```
lib/
  assets/        assets estáticos (audio, branding, club, content, games, legal, sponsors, squad, store, videos)
  core/           infraestrutura (config, di, error, l10n, mock, network, router, session, theme)
  features/       17 pastas de feature (ver tabela abaixo)
  l10n/           .arb + arquivos gerados (pt/en/es)
  shared/         domínio/estado/utils/validação/widgets cross-feature
  main.dart
```

`lib/core/`:
- `config/` — `supabase_config.dart`, `sentry_config.dart` (constantes com override via `--dart-define`)
- `di/` — `injection_container.dart` (setup GetIt)
- `error/` — `result.dart` (`Result<T>`), `failures.dart` (hierarquia `Failure`)
- `network/` — `api_client.dart` (Dio pro Worker), `session_aware_http_client.dart` (wrapper de refresh de sessão Supabase)
- `router/` — `app_router.dart` (GoRouter)
- `theme/` — `app_colors.dart`, `app_assets.dart`, `app_spacing.dart`, `app_theme.dart` — **seam crítico de branding, ver §4**

`lib/shared/` — value objects cross-feature, `load_status.dart` (enum genérico), `app_validators.dart`/`field_touch.dart`, ~20 widgets reutilizáveis incluindo `club_badge.dart` (ver 05_goias_hardcodes.md).

### As 17 pastas de `lib/features/`

| Pasta | Descrição |
|---|---|
| `arena` | Hub de minigames ("Arena Esmeraldina") — hospeda 7 sub-jogos, ranking cross-game, progresso compartilhado |
| `auth` | Login/cadastro/recuperação de senha (Supabase Auth) |
| `club` | Conteúdo institucional: história, diretoria, títulos, transparência, hino |
| `crowd_lineup` | Escalação votada pela torcida, vinculada a uma partida |
| `home` | Shell/navegação por abas |
| `match` | Partidas/resultados, calendário, classificação |
| `membership` | "Sócio Torcedor" — planos, cadastro, FAQ, busca de endereço |
| `news` | Lista de notícias, artigo, visualizador de PDF |
| `notifications` | Preferências de push + serviço FCM |
| `partners` | Listagem de patrocinadores |
| `passport` | "Passaporte" — histórico de presença/trajetória + ranking |
| `profile` | Conta: dados pessoais, endereço, segurança, tema, idioma, documentos legais |
| `social` | Feed social agregado (YouTube/X/Instagram) |
| `splash` | Tela de splash em vídeo |
| `squad` | Elenco atual |
| `store` | Catálogo, carrinho, checkout, pedidos, endereços de entrega |
| `ticket` | Compra de ingresso, meus ingressos/pedidos, check-in |

Os 7 minigames aninhados em `lib/features/arena/games/`: `career_path`, `guess_player`, `lineup`, `penalty`, `player_identity`, `quiz`, `tactical_identity` — cada um com sua própria estrutura `data/`/`domain`/`cubit`/`pages`.

## 2. Injeção de dependência (`lib/core/di/injection_container.dart`)

GetIt (`final GetIt sl = GetIt.instance;`), configurado numa função só (`setupDependencies()`), chamada em `main()` após `Supabase.initialize`.

- **`registerLazySingleton`** — a maioria: todos os repositórios, data sources, cubits que precisam sobreviver à navegação (`CartCubit`, `HomeCubit`, `NewsCubit`, etc.)
- **`registerFactory`** — cubits de escopo de uma tela só (`SquadCubit`, `PassportCubit`, `GamesCubit`, etc.)
- Cubits que exigem argumento de construtor por chamada (id de produto, categoria) **não são registrados no GetIt** — construídos direto no call site.

O cliente Supabase **não é registrado no GetIt** — repositórios chamam `Supabase.instance.client` diretamente dentro do closure de registro. `Dio` (pro Worker) é registrado: `sl.registerLazySingleton<Dio>(ApiClient.create)`.

Não existe nenhum switch de flavor/ambiente alimentando este arquivo — é uma lista de registro plana, single-tenant.

## 3. Roteamento (`lib/core/router/app_router.dart`)

`GoRouter` construído em `createAppRouter(AuthCubit, SplashGate)`. `redirect` trata: deep link de recuperação de senha, splash-gate, rotas públicas (termos/privacidade), redirecionamento auth. A maior parte das ~70 rotas fica dentro de um `ShellRoute` único (mantém rail lateral persistente no desktop/web, no-op no mobile). Muitas rotas passam dados tipados via `state.extra` em vez de serializar em path/query — **limitação a marcar** para uma futura migração de flavor/URL-scheme, já que `state.extra` não sobrevive a um load de URL a frio.

## 4. Theming/branding — seção crítica pro multi-clube

Tudo hoje vive em `lib/core/theme/`, como **constantes Dart em tempo de compilação**, single-club, sem camada de abstração.

### `app_colors.dart`
`AppColors` é um `ThemeExtension<AppColors>` (bom sinal — já é o padrão certo do Flutter pra multi-tema, então trocar de marca é estruturalmente parecido com trocar de light/dark). Só **duas instâncias estáticas const**: `AppColors.light` e `AppColors.dark`, ambas paletas verde-Goiás hardcoded como `Color(0xFF...)`. Ver valores exatos e nomenclatura em `05_goias_hardcodes.md §2`.

### `app_theme.dart`
`AppTheme.light`/`.dark` chamam `_themeFor(AppColors.light/.dark, brightness)` — **o único lugar** que referencia as instâncias estáticas estruturalmente. Seam limpo pra trocar por paleta de outro clube.

### `app_assets.dart`
`AppAssets` é uma classe const de paths literais (`goiasCrest`, `goiasCrestBadge`, `loginBackground`, `storeBanner`, etc.) — sem indireção nenhuma, cada asset é Goiás-específico por nome e conteúdo. Ver inventário completo em `05_goias_hardcodes.md §3`.

### `app_spacing.dart`
`AppSpacing`/`AppRadius` — tokens de design puros, não específicos de clube, reaproveitáveis sem mudança.

**Conclusão pro plano de migração**: existe exatamente um seam (`AppColors.light`/`.dark` → `AppTheme`) e um seam (`AppAssets`) que carregam a marca Goiás. Nenhum dos dois é parametrizado por instância hoje — todo widget referencia `AppColors`/`AppAssets` como singleton estático global, não como estado injetado. Introduzir um flavor exige transformar os dois em objeto de instância (ou registrado no GetIt) escolhido no bootstrap, e depois auditar cada call site de `AppAssets.xxx`/`AppColors.light`.

## 5. Padrões arquiteturais comuns

### `Result<T>`/`Success`/`Error`
`lib/core/error/result.dart`: `sealed class Result<T>` com `Success<T>`/`Error<T>`. `Failure` (`lib/core/error/failures.dart`) é `Equatable` com subclasses `ServerFailure`, `UnexpectedFailure`, `NetworkFailure`, `AuthFailure`. Usado consistentemente em toda interface de repositório.

### State management
Bloc/Cubit em tudo (`flutter_bloc: ^9.1.1`), sem `setState` de lógica de negócio na camada de arquitetura. Padrão: `Cubit<FeatureState>` + `FeatureState` (frequentemente com `copyWith` + `LoadStatus`).

### Camadas típicas — dois exemplos

**`squad`** (feature simples, só leitura):
```
domain/repositories/squad_repository.dart   → interface abstrata
domain/squad_member.dart                    → entidade
data/supabase_squad_repository.dart         → implementação, try/catch + Sentry, retorna Success/Error
presentation/cubit/squad_cubit.dart         → load()/refresh(), chamado manualmente pelo widget (nunca no construtor, evita fetch duplicado concorrente)
```

**`club`** (feature maior, mista estática+remota): mesma camada `data/domain/presentation`, mas alguns `data/*_data.dart` são conteúdo estático hardcoded (`club_history_data.dart`, `club_songs_data.dart`, `club_titles_data.dart`, `club_timeline_data.dart`) enquanto outros são repositórios Supabase (`supabase_club_board_repository.dart`, `supabase_club_transparency_repository.dart`) — ambos implementando interfaces em `domain/repositories/`. Esse mix estático/remoto dentro de uma mesma feature é digno de nota pro plano multi-clube, já que os arquivos estáticos são 100% conteúdo Goiás embutido direto no fonte Dart.

## 6. `pubspec.yaml` — dependências chave

```yaml
environment:
  sdk: ^3.12.1   # só constraint de Dart SDK; sem constraint explícita de Flutter SDK
```

- `supabase_flutter: ^2.17.2` — backend principal
- `dio: ^5.9.0` — HTTP pro Worker (fora do Supabase)
- `http: ^1.6.0` — usado dentro de `SessionAwareHttpClient`
- `sentry_flutter: 9.28.0` / `sentry_dio: 9.28.0` — versão exata fixa (não caret)
- `firebase_core: ^3.8.0` / `firebase_messaging: ^15.1.6` — push
- `get_it: ^8.0.3`, `flutter_bloc: ^9.1.1`, `equatable: ^2.0.8`, `go_router: ^18.0.0`
- `flame: ^1.38.0` — engine do minigame Pênaltis
- dev: um segundo pacote `supabase: ^2.16.1` (não-Flutter, provavelmente tooling/scripts), `flutter_launcher_icons`/`flutter_native_splash` — ambos com config de ícone/splash único, sem por-flavor.

## 7. Ambiente/config

**Não existe `env.json`** neste projeto (diferente do padrão `--dart-define-from-file=env.json` usado no fisioterapia_pelvica/Aura). Padrão aqui: **default hardcoded + override via `String.fromEnvironment`**, em três lugares:

- `lib/core/config/supabase_config.dart` — `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_REDIRECT_URL` (todos com default embutido)
- `lib/core/config/sentry_config.dart` — `SENTRY_DSN` (default embutido, comentário explica que DSN não é secret), `SENTRY_ENVIRONMENT` (default `'production'` — comentário confirma que não existe build de flavor/QA hoje)
- `lib/core/network/api_client.dart` — `API_BASE_URL` (default `''` no web / URL de produção do Worker fora do web)

`Supabase.initialize` acontece em `main()` antes de `setupDependencies()`, passando só `url`/`publishableKey`/`httpClient` (sem `redirectUrl` no init). `main()` também roda `Firebase.initializeApp()` (dentro de try/catch, nunca derruba o boot) e `SentryFlutter.init(...)` envolvendo `runApp`.

## 8. Infra de multi-ambiente/flavor existente

**Nenhuma.** Especificamente:

- **Android** (`android/app/build.gradle.kts`): `defaultConfig` único, `applicationId = "br.com.goiasec.goias_app"`. Zero `productFlavors`/`flavorDimensions`. Só as pastas padrão de build type (`debug`/`main`/`profile`).
- **iOS**: um scheme só (`ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`), um `Info.plist`.
- **Identidade do app**: `pubspec.yaml` `name: goias_app`, um ícone (`assets_gen/app_icon.png`), uma cor de background (`#004C1B`), um splash (`#F6F8F7`).
- **CI**: único workflow (`.github/workflows/sync_x_posts.yml`) é o cron de sync do X, não relacionado a build de app.
- **Worker Cloudflare** (repo compartilhado, fora de `lib/`): também single-tenant hoje (1 Worker, 1 namespace KV).

**Conclusão**: o app hoje é 100% single-tenant — um applicationId, um bundle id, um ícone, um projeto Supabase, uma paleta de cor/asset. Uma migração de flavor não tem nenhum andaime existente pra construir em cima; precisa ser criada do zero (Gradle product flavors + Xcode schemes/configs + uma camada de club-config em runtime substituindo os singletons estáticos `AppColors`/`AppAssets` + valores `--dart-define` ou config JSON por clube em build-time).

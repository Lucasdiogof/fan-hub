# M4.3A — Flavor Pipeline: Audit & Design

Data: 2026-09-03
Escopo desta rodada: **só auditoria e design.** 0 flavor real criado, 0 Red Bull Bragantino, 0 Firebase novo, 0 package/bundle real novo, 0 cadastro novo em `clubs`. Todo o desenho usa só o `club-b` sintético/conceitual já existente em `test/core/club/synthetic_club_config.dart` (M4.2A).

Existe prior art parcial de 2026-09-01 (`docs/multiclub/10-13`), anterior à implementação real de `ClubConfig`/`APP_CLUB`/`ClubCapabilities`. Onde esses documentos citam `CLUB_ID`/`Juventude`, isso está **superseded** pelo contrato real (`APP_CLUB`, `club-b` como nome de trabalho) — usados aqui só como estrutura de raciocínio já validada, revalidados contra o código atual.

## 1) Android — estado atual

- `applicationId`/`namespace`: `br.com.goiasec.goias_app` (`android/app/build.gradle.kts:9,20`). Sem `productFlavors`/`flavorDimensions` — confirmado ausente.
- App label: `android:label="goias_app"` **hardcoded direto no manifest** (`AndroidManifest.xml:8`), não é `@string/app_name` — não existe `strings.xml` com esse recurso.
- Ícones: um set só (`mipmap-*/ic_launcher.png` + `mipmap-anydpi-v26/ic_launcher.xml` + `drawable-*/ic_launcher_foreground.png`), gerado por `flutter_launcher_icons` a partir de config única no `pubspec.yaml`.
- `google-services.json` (`android/app/google-services.json`): `project_id=goias-app-4ef7e`, `package_name=br.com.goiasec.goias_app`. Plugin `com.google.gms.google-services` aplicado incondicionalmente.
- Deep links: **nenhum** `intent-filter` com `scheme`/`host` existe hoje — só o `MAIN`/`LAUNCHER` padrão.
- Signing: `release { signingConfig = signingConfigs.getByName("debug") }` (`build.gradle.kts:29-35`) — release assina com a chave de debug hoje. **Gap pré-existente, não introduzido por multiclube**, mas relevante porque bloqueia qualquer release real, inclusive de um 2º clube.
- `APP_CLUB`: zero referências em todo `android/` — nenhuma ponte dart-define→build nativo existe.
- Outros hardcodes "goias": `MainActivity.kt` (canal de notificação `"goias_matches"` / `"Partidas do Goiás"`).
- Build: nenhum workflow do GitHub Actions builda APK/AAB; único workflow existente (`sync_x_posts.yml`) é do feed do X, não relacionado.
- Existe proposta prévia em `docs/multiclub/11_flavors_android.md` (2026-09-01) com estrutura de `productFlavors` — plausível, mas usa `applicationIdSuffix`/nomenclatura antiga (`CLUB_ID`); a estrutura de flavors em si continua válida, só o nome da variável (`APP_CLUB`, não `CLUB_ID`) precisa ser corrigido ao implementar.

## 2) iOS — estado atual

- Bundle id: `br.com.goiasec.goiasApp` (`project.pbxproj` — Debug/Release/Profile, todas idênticas). **Nota**: casing diferente do Android (`goiasApp` camelCase vs `goias_app` snake_case) — inconsistência cosmética pré-existente, não bloqueante, mas vale padronizar ao nomear o 2º clube.
- Um scheme só: `Runner.xcscheme`. 3 Build Configurations padrão (Debug/Release/Profile), sem variante por clube.
- Nenhum `.xcconfig` próprio do projeto — só os 3 auto-gerados pelo Flutter (`Debug.xcconfig`, `Release.xcconfig`, `Generated.xcconfig`), todos sob `ios/Flutter/`.
- Display name: `CFBundleDisplayName="Goias App"` hardcoded no `Info.plist` (não é variável de build).
- Ícones: um `AppIcon.appiconset` só.
- `GoogleService-Info.plist`: `BUNDLE_ID=br.com.goiasec.goiasApp`, `PROJECT_ID=goias-app-4ef7e` — mesmo projeto Firebase do Android.
- URL schemes/deep links: **nenhum** `CFBundleURLTypes` no `Info.plist`. **Nenhum arquivo `.entitlements` existe em todo `ios/`** — a capability de Push Notification (`aps-environment`) não está versionada; se está habilitada, é só dentro do projeto Xcode local, não no repo. Isso precisa ser confirmado antes de qualquer 2º target real (ver Blockers).
- `APP_CLUB`: zero referências nativas — confirmado que é 100% Dart-side (`String.fromEnvironment`), nada no `AppDelegate.swift` lê isso.
- Prior art: `docs/multiclub/12_flavors_ios.md` propõe duplicar o target `Runner` + `.xcconfig` por clube — estrutura correta, mesma ressalva de nomenclatura do Android.

## 3) Web — estado atual

- `web/manifest.json`/`web/index.html` ainda estão nos **valores literais padrão do `flutter create`** — `"name": "goias_app"`, `"short_name": "goias_app"`, `<title>goias_app</title>`, `description: "A new Flutter project."`. Nunca foram customizados nem pro próprio Goiás (achado de baixo risco, sinalizado, não corrigido nesta rodada por estar fora do escopo de auditoria).
- `background_color`/`theme_color` no manifest já é `#004C1B` (certo); `theme-color` no `<head>` já tem par claro/escuro (`#F6F8F7`/`#09110C`) — só falta virar variável por clube.
- Service worker: só o `flutter_service_worker.js` auto-gerado pelo build; nenhum customizado sob `web/` fonte.
- **Deploy é UM Cloudflare Worker só** (`wrangler.toml`): `name="goias-app"`, `main="src/index.ts"`, bloco `[assets]` aponta `directory="build/web"` com `not_found_handling="single-page-application"` — serve o Flutter web build E as rotas `/api/*` do mesmo `fetch()` handler. Sem bloco `routes`/domínio customizado no `wrangler.toml` — responde só no subdomínio padrão `*.workers.dev`.
- Deploy é **git-integrado pelo dashboard da Cloudflare**, não há workflow do GitHub Actions fazendo `wrangler deploy` — não está versionado no repo, só configurado no dashboard (fora do meu alcance de auditoria de código).
- **Nenhum mecanismo de variável de build por clube existe hoje** — zero uso de `--dart-define` em qualquer script/`package.json`/`tooling/`. `APP_CLUB` nunca é passado a nenhum build atual.
- `?club=` (server-side, Worker): `resolveRequestedClubCode()` (`src/football/_lib/club_server_config.ts:59-61`) lê o query param, fallback `NEWS_SOCIAL_CONFIGURED_CLUB_CODE='goias'` quando ausente. `resolveClubServerConfig()` (linhas 63-82) faz um check hardcoded `clubCode !== 'goias'` → `UnknownClubError` — funciona como allowlist de fato, mas não é um array iterável genérico (ver item 9).
- Prior art: `docs/multiclub/13_flavors_web.md` propõe template+substituição (`manifest.template.json`, script de pre-build) — abordagem correta dado que Flutter web não tem templating nativo pra esses arquivos.

## 4) Firebase — estado atual

- **Nenhum** `firebase_options.dart`/`firebase.json`/`.firebaserc` existe — configuração é 100% via arquivos nativos (`google-services.json` + `GoogleService-Info.plist`), um projeto Firebase só: `goias-app-4ef7e`.
- `Firebase.initializeApp()` em `main.dart` sem options explícitas, dentro de try/catch (config ausente não derruba o app).
- Produtos usados: só `firebase_core` + `firebase_messaging` (pubspec). **Sem** `firebase_crashlytics`/`firebase_analytics` — erro é 100% via Sentry, não Firebase.
- FCM é explicitamente pulado no Web (`push_notification_service.dart:57` — `if (_initialized || kIsWeb) return;`) — web nunca precisou de config Firebase própria.
- Entrega de push é **majoritariamente customizada**: `notifications-dispatch` (Supabase Edge Function) lê `FCM_SERVICE_ACCOUNT_JSON` do ambiente e chama a API HTTP v1 do FCM diretamente (`fcm.googleapis.com/v1/projects/<id>/messages:send`) — o Firebase aqui é só transporte de envio, toda lógica de token/despacho é tabela Supabase + Edge Function, não Firebase Console/Cloud Functions.

## 5) Estratégia recomendada de Firebase

**Mesmo Firebase project + múltiplos Firebase Apps** (um app novo por `applicationId`/bundle id, registrado dentro do projeto `goias-app-4ef7e` existente) — não um projeto separado por clube.

Motivos:
- Nenhum produto usado (`Analytics`, `Crashlytics`) tem valor em ficar isolado por clube hoje — não há dashboard que precise de separação.
- FCM HTTP v1 é escopado por **projeto**, não por app — um único `FCM_SERVICE_ACCOUNT_JSON` já em uso no `notifications-dispatch` continua funcionando pra enviar a QUALQUER app (`applicationId`/bundle id) registrado dentro do mesmo projeto Firebase, sem duplicar credenciais/secrets por clube.
- `notifications-dispatch` já resolve `clubConfig` via `resolveClubServerConfigByClubId(event.club_id)` (Edge, `_shared/club_server_config.ts:73-75`) — adicionar um 2º app ao mesmo projeto não exige nenhuma mudança nessa lógica, só um novo `google-services.json`/`GoogleService-Info.plist` do novo app.
- Consistente com a filosofia já estabelecida no projeto ("Supabase compartilhado, multi-tenant via `club_id`", `09_supabase_migration_plan.md`) — evitar fragmentar infraestrutura só porque o produto ganhou um 2º clube.

**Trade-off aceito**: se um clube parceiro real algum dia exigir posse/billing próprios do Firebase (conta própria), migrar pra projeto separado depois é possível, mas não é o caminho de menor atrito agora — decisão a revisitar só se/quando isso for pedido de verdade.

Impacto por área:
- **FCM**: sem impacto — 1 service account, N apps, `notifications-dispatch` já despacha por `club_id`.
- **Crashlytics/Analytics**: não usados, sem impacto, sem decisão a tomar.
- **Config files**: cada clube ganha seu próprio `google-services.json`/`GoogleService-Info.plist` (tied ao seu `applicationId`/bundle id), mas dentro do MESMO `project_id`.
- **Service accounts**: continua 1 só.
- **Edge notifications**: zero mudança de código — a Edge já é multi-club-aware nesse ponto.
- **Operação/manutenção**: 1 console Firebase pra administrar tudo, menor superfície operacional.

## 6) Supabase / Auth

Confirmado (código real, não suposição): **um projeto Supabase só, um `auth.users` global, zero scoping por clube em qualquer camada de Auth.** `AuthRepositoryImpl`/`AuthRemoteDataSource` (`lib/features/auth/`) nunca filtram/passam `club_id`; `injection_container.dart` inicializa um único `Supabase.instance.client` incondicionalmente, não ramificado por `APP_CLUB`. `SupabaseConfig.url`/`.publishableKey` são `String.fromEnvironment` com um único default, também não derivado de identidade de clube.

Isso é a decisão já validada desde M1 (`09_supabase_migration_plan.md`, `28_etapa_m1_report.md`) — flavors separados continuam apontando pro MESMO backend Supabase/Auth; o que muda por flavor é só `APP_CLUB` (compilado) selecionando `ClubConfig`, nunca o projeto Supabase. Uma pessoa pode, tecnicamente, logar com a mesma conta em um app-Goiás e um futuro app-clubB — decisão de produto já aceita implicitamente pelo desenho atual (`profiles`/`user_addresses` marcados ⚪ globais no plano original), não redesenhada aqui.

**RLS não redesenhada nesta rodada**, conforme instruído.

## 7) Storage / isolamento de sessão

**Nativo (Android/iOS): sandbox automático, garantido pelo SO.** Cada `applicationId`/bundle id diferente já é, por definição da plataforma, um app diferente — `SharedPreferences`/`UserDefaults`/qualquer storage local nativo é automaticamente isolado por instalação, sem nenhuma config extra necessária. Isso vale assim que os flavors tiverem `applicationId`/bundle id realmente distintos (item 1/2).

**`ClubScopedStorageKey`** (`lib/core/club/club_scoped_storage_key.dart:17-29`) — prefixa toda chave local com `'${clubConfig.identity.code}:'` (ex.: `goias:foo`). O próprio comentário do arquivo já documenta a intenção certa: no nativo isso é defesa redundante (o SO já isola), existe pra o app "não depender silenciosamente" só do isolamento do SO.

**Web é o caso diferente e crítico**: hoje TODO o app roda de UMA origem só (um Worker, um domínio). Nesse cenário, `ClubScopedStorageKey` **não é redundância — é a ÚNICA coisa** que impedira uma sessão web-goias de colidir/vazar pra dentro de uma futura sessão web-clubB no MESMO navegador/domínio. Se o design final de deploy web (item 3/item 9 abaixo) usar domínios ou subdomínios DIFERENTES por clube (recomendado), cada origem já ganha seu próprio `localStorage` pelo browser — nesse caso o prefixo volta a ser defesa redundante, igual ao nativo. Se em algum cenário futuro dois clubes compartilhassem a MESMA origem web (não recomendado, não meu approach preferido — ver item 9), o prefixo seria a única barreira, e isso precisaria de auditoria própria antes de confiar nele sozinho.

**Conclusão prática**: recomendar domínio/subdomínio distinto por clube no Web (ver item 9) torna o isolamento web equivalente ao nativo (por origem), com `ClubScopedStorageKey` como defesa em profundidade em ambas as plataformas — nunca a única linha de defesa.

## 8) Contrato `APP_CLUB`

Já implementado e correto hoje (`lib/core/club/resolve_active_club.dart:25-38`), só falta ser **formalizado como regra de processo de build**, não mudar de código:

- Ausente (`String.fromEnvironment` vazio) → `clubRegistry['goias']!` — **compatibilidade do Goiás atual**, nenhum flavor hoje passa `APP_CLUB`.
- Presente mas desconhecido → `StateError` (fail-loud), nunca cai pro Goiás.

**Contrato final proposto**:
```
flavor goias  -> --dart-define=APP_CLUB=goias   (EXPLÍCITO, não confiar no fallback)
flavor club-b -> --dart-define=APP_CLUB=club-b  (EXPLÍCITO)
```
O fallback de ausência continua existindo **só** pelo build não-flavored de hoje (o que roda em dev/preview sem `--flavor`). **Nenhum flavor NOVO pode depender dele** — todo comando de build de um flavor real (Android `--flavor <nome>`, iOS `--flavor <nome>`, Web via script de prepare) deve passar `APP_CLUB` explicitamente, sempre. Isso já é reforçável por lint/CI simples (grep no script de build por `--flavor` sem `APP_CLUB` correspondente) — não implementado nesta rodada, só desenhado.

## 9) Registry matrix

Registros que precisam de uma entrada nova quando um clube REAL entrar (nenhum criado agora):

| Registro | Local | Estado atual | Observação |
|---|---|---|---|
| `DB clubs` | `supabase/migrations/20260902020000_create_clubs.sql` | 1 linha (`goias`, uuid) | PK `uuid`, `slug` único — novo clube = novo `insert` |
| `Flutter clubRegistry` | `lib/core/club/club_registry.dart:9-11` | `{'goias': goiasClubConfig}` | novo clube = nova entrada `const Map` + novo arquivo `<clube>_club_config.dart` |
| `Worker registry` | `src/football/_lib/club_server_config.ts:40,64-66` | `SERVER_CLUB_CODES=['goias']` + check hardcoded `!== 'goias'` | **precisa generalizar** de check-único pra lookup de array antes de um 2º clube real — hoje tecnicamente funciona como allowlist(1), mas o código está escrito como caso especial, não como iteração |
| `Edge registry` | `supabase/functions/_shared/club_server_config.ts:71` | `SERVER_CLUB_REGISTRY=[GOIAS_SERVER_CONFIG]` | já é um array de verdade com lookup por id/code — só precisa de nova entrada, sem generalizar código |
| `Android flavors` | `android/app/build.gradle.kts` | nenhum | novo `productFlavors { create("clubB") {...} }` |
| `iOS schemes` | `ios/Runner.xcodeproj/xcshareddata/xcschemes/` | só `Runner` | novo target+scheme (ou config+xcconfig, ver item 2) |
| `Web build configs` | `wrangler.toml` (proposto) | 1 deploy default, sem `[env.*]` | novo bloco `[env.clubb]` (ver abaixo) |
| `Firebase apps` | Console Firebase, projeto `goias-app-4ef7e` | 2 apps (Android+iOS do Goiás) | novo app por `applicationId`/bundle id novo, mesmo projeto (item 5) |
| `Release requirements` | Play Console / App Store Connect | só Goiás (parcial — release ainda assina com debug key) | conta/ficha de loja/política de privacidade por app — fora do código |

**Web, detalhe de implementação recomendado**: usar `wrangler.toml` `[env.<nome>]` (mecanismo nativo de múltiplos ambientes da Cloudflare) — cada ambiente com seu próprio `assets.directory` (apontando pro `build/web` daquele clube), `vars` (`GOIAS_ONEFOOTBALL_SLUG`→equivalente do clube), e nome/rota própria — em vez de duplicar `src/index.ts`/o repo inteiro. Isso mantém 1 código-fonte, N deploys isolados. **Ressalva de operação**: como o deploy hoje é 100% dashboard-git-integrado (nenhum workflow do GitHub Actions), múltiplos `[env.*]` normalmente exigem OU múltiplos projetos Cloudflare Dashboard apontando pro mesmo repo (cada um rodando `wrangler deploy --env <nome>`), OU migrar pra um workflow `wrangler-action` que decide o(s) ambiente(s) a implantar por push — essa é uma decisão de infraestrutura, não só de código, que fica pra M4.3B decidir explicitamente.

## 10) Tooling proposto (desenho, não implementado)

Checker único (`tooling/multiclub/audit_m4_3_flavor_registry_drift.mjs`, a construir em rodada própria) que lê, ao vivo:

- `FLUTTER_REGISTRY` — chaves de `clubRegistry` (grep/parse estático do `.dart`, mesmo padrão já usado em `audit_m4_2_club_capabilities.mjs`).
- `DB_REGISTRY` — linhas de `clubs` (via `data_export`/dump já existente ou nova leitura, nunca *live* sem ser pedido).
- `WORKER_REGISTRY` — `SERVER_CLUB_CODES` (`club_server_config.ts`).
- `EDGE_REGISTRY` — `SERVER_CLUB_REGISTRY` (`_shared/club_server_config.ts`).
- `ANDROID_FLAVORS` — nomes em `productFlavors` do `build.gradle.kts` (quando existir).
- `IOS_SCHEMES` — arquivos em `xcshareddata/xcschemes/` (quando existir).
- `WEB_BUILD_CONFIGS` — blocos `[env.*]` do `wrangler.toml` (quando existir).

Sinaliza `registryDrift=true` sempre que o **conjunto de códigos de clube** não bater entre todos os 7 registros (ex.: DB tem `club-b` mas Worker não, ou Android tem o flavor mas Flutter `clubRegistry` não). Hoje, com N=1 em todos, o check é trivialmente consistente — o valor dele aparece só quando um 2º clube real começar a ser cadastrado incrementalmente (nem todo registro muda no mesmo commit necessariamente). Fica desenhado aqui pra ser construído na primeira rodada que efetivamente adicionar um registro novo.

## 11) Blockers por categoria

**`BLOCKER_BEFORE_SYNTHETIC_FLAVOR`** (impede até um flavor técnico/sintético compilar com `APP_CLUB` distinto):
- Android: `android:label` precisa virar `@string/app_name` (hoje é literal) antes de `resValue` por flavor funcionar.
- iOS: `CFBundleDisplayName` precisa virar `$(VARIÁVEL)` resolvida por `.xcconfig` (hoje é literal no `Info.plist`).
- Web: `manifest.json`/`index.html` precisam do mecanismo de template+substituição (não existe hoje, nem para o próprio Goiás).
- Nenhum comando de build hoje passa `--dart-define=APP_CLUB=...` — os scripts/flavors em si (Android `productFlavors`, iOS target/scheme, script de prepare web) precisam existir antes de qualquer coisa compilar como um "2º app".

**`BLOCKER_BEFORE_REAL_FLAVOR`** (flavor sintético já compila, mas falta pra um clube REAL existir de verdade):
- `applicationId`/bundle id reais definidos junto com o clube parceiro.
- Registro de novo app Firebase (mesmo projeto, item 5) com `google-services.json`/`GoogleService-Info.plist` reais.
- Assets/ícones reais do clube.
- Generalizar `Worker registry` de check-único pra array (item 9) — pequeno, mas necessário antes do 2º código real.
- Signing de release real (hoje release assina com debug key — pré-existente, mas bloqueia release de QUALQUER app, inclusive um 2º clube).
- Confirmar/criar `.entitlements` de push no Xcode antes de um 2º target iOS real (hoje não versionado, status desconhecido a partir só do repo).

**`BLOCKER_BEFORE_PUBLIC_RELEASE`** (flavor real existe, mas não pode ir ao público):
- Passaporte sem tenancy (12 RPCs) — **só bloqueia se `hasPassport=true` pro 2º clube**; `ClubCapabilities` já permite lançar com `false` (M4.2A).
- Store com `GOI-` hardcoded no SQL — **só bloqueia se `hasStore=true`**; idem, mitigável via capability.
- RLS sem `club_id` — bloqueia qualquer feature que dependa de isolamento de LEITURA por clube além do que a query já filtra client-side; não bloqueia a criação técnica do flavor em si.
- Contas de developer (Play Console/App Store Connect), ficha de loja, política de privacidade por app — fora do código, fora de escopo aqui.
- Domínio/DNS real do 2º clube no Web (se a decisão do item 9 for domínio próprio).

**`DEFERRED_FEATURE_SPECIFIC`** (não bloqueiam nada da pipeline de flavor, já mitigados via capability, ficam pra depois):
- `TicketFixture` hardcoded — mitigado por `hasTickets=false`.
- `SupabaseCrowdLineupRepository`→`goiasSquad` — mitigado por `hasCrowdLineup=false`.

**Importante, conforme instruído**: `ClubCapabilities` (M4.2A) já reduz drasticamente quais desses blockers realmente impedem a criação TÉCNICA de um flavor — um 2º clube pode nascer tecnicamente com Passaporte/Store/Membership desligados, sem esperar as correções de backend. Os blockers de backend continuam reais, só não bloqueiam a pipeline de flavor em si.

## 12) Ordem de implementação recomendada para M4.3B

1. Android: `android:label`→`@string/app_name` + `productFlavors`/`flavorDimensions` (sintético, sem novo `applicationId` real ainda — pode usar um id de teste local).
2. iOS: `.xcconfig` por variável + `CFBundleDisplayName` dinâmico + scheme/target novo (sintético).
3. Web: template+substituição de `manifest.json`/`index.html` + correção do próprio Goiás (achado de baixo risco já sinalizado) + `wrangler.toml` `[env.*]` (sintético/local).
4. Formalizar o script/comando de build por flavor exigindo `APP_CLUB` explícito (os 3 alvos).
5. `tooling/multiclub/audit_m4_3_flavor_registry_drift.mjs` (item 10) — construir de verdade, ainda com N=1 em todos os registros (garante que a MECÂNICA do checker funciona antes de precisar dela de verdade).
6. Só então, numa etapa própria e com autorização própria: onboarding de um clube real (`BLOCKER_BEFORE_REAL_FLAVOR` da lista acima, um a um).

## 13) FLAVOR_PIPELINE_IMPLEMENTED

**`false`** — nada foi implementado nesta rodada, só auditado/desenhado.

## 14) SYNTHETIC_SECOND_CLUB_FLAVOR_READY

**`false`** — os `BLOCKER_BEFORE_SYNTHETIC_FLAVOR` do item 11 (label/display-name virarem variáveis, template web, scripts de build com `APP_CLUB`) ainda não foram feitos.

## 15) REAL_SECOND_CLUB_ONBOARDING_READY

**`false`** — depende de `SYNTHETIC_SECOND_CLUB_FLAVOR_READY=true` primeiro, mais todos os `BLOCKER_BEFORE_REAL_FLAVOR` do item 11.

## 16-20) Confirmação de escopo

**0 flavor real.** **0 Bragantino** (nenhum nome de clube real usado — só `club-b` conceitual/sintético). **0 db push.** **0 Edge deploy.** **0 git push adicional** após o push da M4.2 (`50b0358`) — esta etapa não produziu nenhum código, só este relatório, que fica **não commitado**, aguardando autorização própria.

PARE.

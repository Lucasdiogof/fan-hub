# M4.3B — Synthetic Flavor Pipeline

Data: 2026-09-03
Escopo desta rodada: implementar e provar a pipeline multi-flavor usando só `goias`/`club-b` sintético. 0 Red Bull Bragantino, 0 clube real novo, 0 insert em `clubs`, 0 Firebase App real novo, 0 db push, 0 Edge deploy, 0 git push. **Implementação NÃO commitada** — aguardando autorização própria (fluxo pedido: relatório 45 commitado → implementação local → testes/builds → relatório 46 → PARE).

## 1) Android flavors

`android/app/build.gradle.kts`: `flavorDimensions += "club"` + `productFlavors { goias, clubb }`. `buildFeatures { buildConfig = true }` ligado (necessário pro canal de notificação por flavor, item 14 abaixo). `android:label` (`AndroidManifest.xml`) trocado de literal `"goias_app"` pra `"@string/app_name"`, resolvido por `resValue("string", "app_name", ...)` de cada flavor. Ícone do `clubb` gerado como flavor source set próprio (`android/app/src/clubb/res/mipmap-*/ic_launcher.png` + `mipmap-anydpi-v26/ic_launcher.xml` + `drawable-*/ic_launcher_foreground.png` + `values/colors.xml` com `ic_launcher_background=#0B3D91`), a partir do mesmo placeholder sintético usado no Flutter — nunca reaproveita o adaptive icon do Goiás.

## 2) IDs (Android)

- `goias`: `applicationId = "br.com.goiasec.goias_app"` — **idêntico** ao de hoje, setado explícito no flavor (não só herdado do `defaultConfig`) pra nunca gerar um app novo por acidente.
- `clubb`: `applicationId = "br.com.goiasec.goias_app.clubb"` — suffix claramente sintético, nunca um package de clube real (nunca Bragantino).

## 3) Firebase Android — `ANDROID_SYNTHETIC_FLAVOR_BLOCKED_BY_FIREBASE_APP=true`

Investigado antes de implementar qualquer contorno. `google-services.json` (`android/app/`) só tem `client[]` pro package `br.com.goiasec.goias_app` — nenhuma entrada pra `br.com.goiasec.goias_app.clubb`. O plugin `com.google.gms.google-services` está aplicado incondicionalmente no módulo `:app` (não é escopado por flavor). O comportamento documentado desse plugin é: cada variante gera uma task `process<Variant>GoogleServices`, e essa task **falha o build** ("No matching client found for package name...") quando o `applicationId` resolvido da variante não bate com nenhum `client[].client_info.android_client_info.package_name` visível (`main`/flavor source set). Não existe mecanismo suportado/documentado pra aplicar o plugin condicionalmente só num flavor sem: (a) registrar um app Firebase real pro `clubb` (proibido nesta rodada) ou (b) um hack não-suportado (parsing de nome de task, exclusão manual de task por linha de comando — frágil, depende do executor lembrar sempre). Por isso: **PAREI aqui, não mexi em `google-services.json`, não inventei credencial, não criei Firebase App.**

**Não pude confirmar isso empiricamente nesta rodada** — `flutter build apk --flavor goias --debug` e `--flavor clubb --debug` FALHARAM os dois no mesmo ponto (`Unable to establish loopback connection`, o mesmo erro de ambiente Gradle já documentado em rodadas anteriores, ocorrendo em ~0.6s, antes de qualquer task de compilação real rodar — não mexi em JDK/Gradle, registrado como problema de ambiente). Sinal parcial positivo: o Gradle conseguiu resolver os nomes das tasks corretamente (`assembleGoiasDebug`/`assembleClubbDebug`) antes de falhar, o que indica que o bloco `productFlavors` em si foi pelo menos PARSEADO com sucesso pela fase de configuração — mas não prova nada sobre o comportamento real do `google-services` plugin. Recomendo ao dono confirmar isto no terminal dele (onde o Gradle funciona) antes de assumir a conclusão acima como definitiva.

## 4) iOS schemes/configs

Menor solução correta escolhida: **sem duplicar o target `Runner`.** Adicionadas 6 novas `XCBuildConfiguration` ao projeto (`Debug-goias`/`Release-goias`/`Profile-goias`/`Debug-clubb`/`Release-clubb`/`Profile-clubb`), tanto no nível do projeto quanto no nível do target `Runner` (Xcode exige o nome da configuration espelhado nos dois níveis), mais 6 arquivos `.xcconfig` novos em `ios/Flutter/Flavors/` (cada um faz `#include` do `Debug.xcconfig`/`Release.xcconfig` original + sobrescreve `PRODUCT_BUNDLE_IDENTIFIER`/`APP_DISPLAY_NAME`/`APP_CLUB`). 2 novos schemes compartilhados (`ios/Runner.xcodeproj/xcshareddata/xcschemes/goias.xcscheme` e `clubb.xcscheme` — nomeados em minúsculo pra bater exatamente com `--flavor goias`/`--flavor clubb`, convenção que o próprio `flutter build ios --flavor <nome>` exige pra resolver o scheme certo automaticamente). `RunnerTests` e o scheme `Runner` original **não foram tocados** — continuam existindo, servindo de fallback não-flavored.

**`IOS_BUILD_NOT_EXECUTED_ENVIRONMENT=true`** — sem Mac/Xcode neste ambiente Windows, não há como rodar `xcodebuild`/`flutter build ios` de verdade. Validação foi só estática: `project.pbxproj` editado à mão (formato OpenStep, não XML/plist padrão — sem parser confiável disponível aqui), verificado por checagem estrutural (chaves/parênteses balanceados: 109/109 e 87/87 respectivamente) e por checagem de referência cruzada (cada um dos 19 IDs novos aparece exatamente o número de vezes esperado — 2x pras configurations, 3x pros file references dos `.xcconfig`). Isso reduz risco de erro grosseiro mas **não substitui abrir o projeto no Xcode** — recomendo ao dono confirmar isso antes de confiar na pipeline iOS pra valer.

## 5) Bundle IDs (iOS)

- `goias`: `PRODUCT_BUNDLE_IDENTIFIER = br.com.goiasec.goiasApp` — **idêntico** ao de hoje.
- `clubb`: `PRODUCT_BUNDLE_IDENTIFIER = br.com.goiasec.goiasApp.clubb` — sintético, nunca um bundle de clube real.

`CFBundleDisplayName` no `Info.plist` trocado de literal `"Goias App"` pra `$(APP_DISPLAY_NAME)`, resolvido pelo `.xcconfig` de cada flavor ("Goiás EC"/"Clube Sintético B").

## 6) Firebase iOS

**Achado que muda a pergunta original**: `GoogleService-Info.plist` (`ios/Runner/`) **não está referenciado em nenhum lugar do `project.pbxproj`** — não existe `PBXBuildFile`/`PBXResourcesBuildPhase` apontando pra ele. Isso significa que, hoje, esse arquivo NÃO é copiado pro bundle do app via nenhum mecanismo nativo do Xcode que eu conseguisse confirmar no repo — nem pro Goiás. (Não posso descartar 100% um "Run Script" phase injetado pelo CocoaPods/`firebase_core` que eu não veria sem rodar `pod install`/inspecionar `ios/Pods` — não tenho como confirmar isso neste ambiente. Reportado como incerteza real, não como fato: `IOS_FIREBASE_CONFIG_WIRING_UNCONFIRMED=true`.)

Dado isso, **não precisei fazer nada especial** pro `clubb` "não herdar" o plist do Goiás — como nenhuma configuration (nem as novas, nem as originais) referencia esse arquivo num build phase, nenhum flavor o inclui hoje. Não criei nenhum plist novo, não editei o existente, não fabriquei credencial. `Firebase.initializeApp()` em `main.dart` já está em try/catch (linha 38-42) — degrada de forma segura independente do resultado dessa investigação.

## 7) Entitlements

**`IOS_PUSH_ENTITLEMENT_STATUS_UNKNOWN=true`** — confirmado de novo (M4.3A já tinha achado isso): zero arquivo `.entitlements` em todo `ios/`. Não criei nenhum — o estado real da capability "Push Notifications" (habilitada ou não pro target `Runner` hoje) só é visível dentro do projeto Xcode aberto, não é derivável do repo. Não inventei `aps-environment`. Isso não bloqueia o flavor sintético: `UIBackgroundModes=[remote-notification]` já está no `Info.plist` (compartilhado, não bloqueado por isso), e o lado Flutter (`firebase_messaging`) já degrada sem crash quando a config nativa está incompleta.

## 8) Web builds

`tool/build_web_flavor.mjs` — `node tool/build_web_flavor.mjs <goias|club-b>`, comando único e reproduzível pros dois clubes (mesmo código, sem caso especial pro Goiás). Mecanismo: 1) backup em memória de `web/manifest.json`/`web/index.html`/`web/icons/*`/`web/favicon.png`; 2) escreve os valores do clube pedido (via `web/manifest.template.json`/`web/index.template.html` + `tool/web_flavors/<clube>.json`); 3) roda `flutter build web --release --dart-define=APP_CLUB=<code> [--dart-define=ENABLE_SYNTHETIC_CLUB=true] -o build/flavors/web/<code>`; 4) `finally`: restaura o backup, sempre, sucesso ou falha.

**Builds executados de verdade, os dois, com sucesso**:
```
node tool/build_web_flavor.mjs goias    -> build/flavors/web/goias/   (93,7s)
node tool/build_web_flavor.mjs club-b   -> build/flavors/web/club-b/  (85,5s)
```
Confirmado via `git diff --stat web/manifest.json web/index.html web/icons/ web/favicon.png` = idêntico ao estado antes de rodar o script pras duas execuções — o working tree nunca ficou "preso" no clube sintético.

## 9) Manifests/títulos

- Corrigido o placeholder do próprio Goiás (pedido explícito do item 7): `web/manifest.json`/`web/index.html` tinham `"goias_app"`/`"A new Flutter project."` — literalmente o default do `flutter create`, nunca customizado. Agora: `name`/`short_name`/`title`/`apple-mobile-web-app-title` = `"Goiás EC"`, `description` = `"Goiás EC - o ecossistema digital do torcedor esmeraldino."` (mesma frase do `pubspec.yaml`).
- `club-b`: `name`/`short_name`/`title` = `"Clube Sintético B"`/`"Clube B"`, `description` explicitamente diz "build sintético... nunca produção", `theme_color`/`background_color` = `#0B3D91` (azul, nunca o verde do Goiás), ícones PWA gerados a partir do mesmo placeholder sintético (192/512/maskable-192/maskable-512 + favicon).

Prova de conteúdo distinto:
```
diff build/flavors/web/goias/manifest.json build/flavors/web/club-b/manifest.json
< "name": "Goiás EC" / "background_color": "#004C1B" / "description": "...esmeraldino."
> "name": "Clube Sintético B" / "background_color": "#0B3D91" / "description": "...nunca produção..."
```
Ícones também diferem em bytes (`Icon-512.png`: md5 `b2ae80...` Goiás vs `6b6f55...` club-b).

## 10) Impacto Cloudflare

**Nenhum.** `wrangler.toml` não foi tocado. O comando que o dashboard da Cloudflare roda (`flutter build web --release` a partir de `web/manifest.json`/`web/index.html` no estado commitado do repo) continua produzindo exatamente o build do Goiás, agora com o placeholder corrigido (item 9) — `push main -> Cloudflare Git integration publica Goiás` **continua o mesmo contrato**, porque `tool/build_web_flavor.mjs` nunca é chamado por nenhum pipeline de deploy, só localmente, e sempre restaura `web/` ao estado do Goiás no `finally`. `0 wrangler deploy`, `0 mudança manual no dashboard`.

## 11) Enforcement de `APP_CLUB`

`lib/core/club/resolve_active_club.dart` reescrito com 3 regras (era 2): ausente→Goiás (compat legado); `APP_CLUB=club-b` sem `ENABLE_SYNTHETIC_CLUB=true`→`StateError` fail-loud citando a flag que falta; presente-e-desconhecido→`StateError` (como já era). `club-b` nunca é adicionado a `clubRegistry` — resolvido por um branch de código separado (`syntheticClubBBuildConfig`, novo arquivo `lib/core/club/synthetic_club_build_config.dart`), nunca por uma entrada no mapa de produção.

Checker construído: `tooling/multiclub/audit_m4_3_flavor_registry_drift.mjs`'s seção `appClubEnforcedEverywhere` — lê `tool/flavor_build_commands.json` (os 4 comandos Android/iOS documentados) confirmando que TODOS citam `APP_CLUB=` (e o `clubb` também cita `ENABLE_SYNTHETIC_CLUB=true`); lê o CÓDIGO REAL de `tool/build_web_flavor.mjs` confirmando que ele injeta `APP_CLUB=${flavor.appClub}` de verdade (não só documenta); lê `tool/web_flavors/*.json` confirmando `appClub` preenchido nos dois. `appClubEnforcedEverywhere=true` hoje.

## 12) Mecanismo de registry sintético

`resolveActiveClub(envValue, syntheticEnabled)` — 2º parâmetro novo, `bool`, default = constante de compilação `enableSyntheticClub` (`bool.fromEnvironment('ENABLE_SYNTHETIC_CLUB')`). `club-b` só resolve se `envValue == 'club-b' && syntheticEnabled == true`; qualquer uma das duas condições faltando é fail-loud. `clubRegistry` (produção) permanece com `{'goias': goiasClubConfig}`, zero mudança.

## 13) Registry drift tooling — construído de verdade

`tooling/multiclub/audit_m4_3_flavor_registry_drift.mjs` + `test_m4_3_flavor_registry_drift.mjs` (13 testes). Separação explícita, conforme pedido:

- **`PRODUCTION_REGISTRY`**: `flutterProdRegistry` (`club_registry.dart`), `workerRegistry` (`SERVER_CLUB_CODES`), `edgeRegistry` (`SERVER_CLUB_REGISTRY`), `dbRegistry` (lido do snapshot já auditado em `data_export/`, nunca consulta live dentro do audit script) — os 4 devem ser `['goias']`, sempre. Hoje: `productionRegistryOnlyGoias=true`.
- **`SYNTHETIC_BUILD_REGISTRY`**: `androidFlavors` (nomes reais em `productFlavors`), `iosSchemes` (arquivos `.xcscheme` reais), `webBuildConfigs` (`tool/web_flavors/*.json` reais) — só precisam conter `goias`+`clubb`/`club-b`, NUNCA comparados contra `PRODUCTION_REGISTRY`. Hoje: `syntheticPresentInAllBuildMechanisms=true`.
- `registryDrift = false` hoje — cai automaticamente se qualquer um dos 2 grupos regredir no futuro (novo clube registrado num lugar e esquecido em outro).

## 14) Capabilities do synthetic clubB

`syntheticClubBBuildConfig` (novo, `lib/core/club/synthetic_club_build_config.dart`) espelha exatamente `test/core/club/synthetic_club_config.dart`: `hasMembership/hasStore/hasTickets/hasCrowdLineup/hasPassport/hasNews/hasSocial=false`, `enabledArenaGames={'quiz'}`. Mesmos 8 assets apontando pro mesmo placeholder sintético (`lib/assets/branding/synthetic_club_b/placeholder.{png,svg}`), nunca um path do Goiás. Nenhum build sintético alcança conteúdo do Goiás — mesma garantia estrutural da M4.2A, agora também válida num build REAL (não só em widget test).

## 15) Isolamento — provado

- **Android**: `applicationId` `br.com.goiasec.goias_app` (goias) vs `br.com.goiasec.goias_app.clubb` (clubb) — confirmado no `build.gradle.kts`, cada flavor com o valor certo, nunca compartilhado.
- **iOS**: `PRODUCT_BUNDLE_IDENTIFIER` `br.com.goiasec.goiasApp` vs `br.com.goiasec.goiasApp.clubb` — confirmado nos 2 pares de `.xcconfig`.
- **Web**: `build/flavors/web/goias/` vs `build/flavors/web/club-b/` — 2 diretórios de saída fisicamente distintos (nunca um sobrescrevendo o outro), com `manifest.json`/`index.html`/ícones com conteúdo (bytes) diferentes, confirmado via `diff`/`md5sum` reais nos artefatos gerados (item 9).

## 16) Builds executados

| Alvo | Resultado |
|---|---|
| Web goias | ✅ sucesso, `build/flavors/web/goias/` |
| Web club-b | ✅ sucesso, `build/flavors/web/club-b/` |
| Android goias (debug) | ❌ `ANDROID_BUILD_NOT_EXECUTED_ENVIRONMENT=true` — mesmo erro de loopback Gradle já documentado, JDK/Gradle NÃO tocado |
| Android clubb (debug) | ❌ idem, mesmo ponto de falha (~0,6s), antes de qualquer task real |
| iOS goias/clubb | `IOS_BUILD_NOT_EXECUTED_ENVIRONMENT=true` — sem Mac/Xcode neste ambiente; validação só estática (item 4) |

## 17) Blockers restantes

- `ANDROID_SYNTHETIC_FLAVOR_BLOCKED_BY_FIREBASE_APP=true` (item 3) — não confirmado empiricamente, baseado em comportamento documentado do plugin; owner deve confirmar.
- `IOS_FIREBASE_CONFIG_WIRING_UNCONFIRMED=true` (item 6) — achado novo, potencialmente relevante mesmo fora do escopo multiclube (Goiás iOS pode já estar sem Firebase bundlado).
- `IOS_PUSH_ENTITLEMENT_STATUS_UNKNOWN=true` (item 7) — sem mudança, só reconfirmado.
- Signing de release Android continua na chave de debug (achado pré-existente, M4.3A §11, não resolvido aqui — fora de escopo).
- Nenhum dos blockers técnicos já documentados na M4-round-1/M4.1/M4.2 (Passaporte, Store SQL `GOI-`, RLS sem `club_id`) foi tocado nesta rodada — continuam de pé.

## 18) FLAVOR_PIPELINE_IMPLEMENTED

**`true`** para Web (única plataforma com build real executado de ponta a ponta, com prova de isolamento nos artefatos). **Parcial** para Android/iOS: toda a estrutura de código (flavors/schemes/configs/ícones/strings) foi implementada e passou nas checagens estáticas disponíveis, mas nenhum build nativo real foi executado com sucesso neste ambiente — considerar `IMPLEMENTED_NOT_VERIFIED` pras 2 plataformas nativas até o dono confirmar num ambiente com Gradle/Xcode funcionando.

## 19) SYNTHETIC_SECOND_CLUB_FLAVOR_READY

**`false`**, geral — Web sozinho não é suficiente pra "pronto": falta confirmação real de Android (bloqueado por ambiente + pela pergunta do Firebase ainda não respondida empiricamente) e iOS (bloqueado por ambiente). A pipeline de CÓDIGO está pronta nas 3 plataformas; a pipeline VERIFICADA só está pronta na Web.

## 20) REAL_SECOND_CLUB_ONBOARDING_READY

**`false`**, sem mudança — depende de `SYNTHETIC_SECOND_CLUB_FLAVOR_READY=true` primeiro (não está), mais todos os `BLOCKER_BEFORE_REAL_FLAVOR` já listados na M4.3A (Firebase App real, generalizar `Worker registry`, signing de release, contas de loja) e agora também da resolução do achado do item 3 (Firebase Android).

## 21) DB

**59/59**, 0 pendente, confirmado ao final desta rodada. Nenhuma migration criada ou tocada.

## 22-25) Confirmação de escopo

**0 db push. 0 Edge deploy. 0 git push. 0 Bragantino** (nenhum nome de clube real usado — só `club-b`, `clubb`, `Clube Sintético B`, sempre explicitamente sintético). Implementação completa **não commitada** — 19 caminhos novos/modificados (listados via `git status --porcelain`, fora do escopo desta etapa: `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_...`, `docs/multiclub/39_...`+tooling de retirement gate, `store_entry_card.dart` — todos preservados intocados, conforme pedido).

PARE.

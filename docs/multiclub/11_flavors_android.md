# 11 — Flavor Android

> Proposta — nada implementado. Baseado no estado real de `android/app/build.gradle.kts` e `AndroidManifest.xml` hoje. Gerado em 2026-09-01.

## Estado atual (confirmado no código)

- `android/app/build.gradle.kts`: `namespace`/`applicationId = "br.com.goiasec.goias_app"`, sem `productFlavors`/`flavorDimensions`. Plugin `com.google.gms.google-services` aplicado incondicionalmente, lendo `android/app/google-services.json` (existe, único arquivo).
- `AndroidManifest.xml`: `android:label="goias_app"` **hardcoded direto no manifest** (não é string resource) — precisa virar `@string/app_name` antes de existir um segundo flavor.
- `android:icon="@mipmap/ic_launcher"` — gerado por `flutter_launcher_icons` a partir de `assets_gen/app_icon.png`, config única no `pubspec.yaml` (`adaptive_icon_background: "#004C1B"`).
- `release` build usa `signingConfig = signingConfigs.getByName("debug")` — **não há assinatura de release configurada ainda**, independente de flavor (gap pré-existente, não introduzido por esta proposta).

## Passo a passo proposto

### 1. `flavorDimensions` + `productFlavors`

```kotlin
android {
    // ...
    flavorDimensions += "club"
    productFlavors {
        create("goias") {
            dimension = "club"
            applicationId = "br.com.goiasec.goias_app"   // mantém o id atual — usuários existentes não perdem o app
            resValue("string", "app_name", "Goiás EC")
            manifestPlaceholders["clubId"] = "goias"
        }
        create("juventude") {
            dimension = "club"
            applicationId = "br.com.jec.juventude_app"    // id novo, a definir junto ao clube
            resValue("string", "app_name", "Juventude EC")
            manifestPlaceholders["clubId"] = "juventude"
        }
    }
}
```
`applicationIdSuffix` não é necessário aqui — cada clube já tem `applicationId` totalmente próprio (faz mais sentido pra apps que vão pra lojas diferentes do que usar sufixo, que é mais comum pra dev/staging do MESMO app).

### 2. Manifest

Trocar `android:label="goias_app"` por `android:label="@string/app_name"` (resolvido por flavor via `resValue` acima). `android:icon` continua `@mipmap/ic_launcher` — o CONTEÚDO desse mipmap é que precisa ser por-flavor (próximo passo).

### 3. Launcher icons por flavor

`flutter_launcher_icons` no formato atual do `pubspec.yaml` só gera pra um alvo. Duas opções:
- (a) Rodar `flutter_launcher_icons` uma vez por clube apontando pra uma pasta de origem diferente (`assets_gen/app_icon_goias.png`/`app_icon_juventude.png`), copiando o output gerado pra `android/app/src/goias/res/mipmap-*/` e `.../src/juventude/res/mipmap-*/` manualmente (build-time source folders do Gradle já pegam esses por flavor automaticamente, sem config extra).
- (b) Usar a config `flavors:` que `flutter_launcher_icons` mais recente já suporta nativamente (gera direto nas pastas `src/<flavor>/res/`). **Recomendado** se a versão do pacote já suportar — checar changelog antes de decidir (a versão no `pubspec.yaml` não foi auditada aqui).

`adaptive_icon_background` (`#004C1B`, cor do Goiás) precisa de um valor por clube — mesma mecânica acima.

### 4. `google-services.json` por flavor

Firebase exige um `google-services.json` por `applicationId`. Com `productFlavors`, o Gradle já resolve automaticamente `android/app/src/goias/google-services.json` e `android/app/src/juventude/google-services.json` (o plugin procura nessas pastas antes do `src/main/`). **Ação**: criar um projeto Firebase novo por clube (ou um projeto com múltiplos apps registrados, um por `applicationId`) e baixar o `google-services.json` de cada um pra pasta certa.

### 5. Deep links

Hoje não há `intent-filter` de deep link além do `MAIN`/`LAUNCHER` padrão (não auditado a fundo neste documento — se existirem em `AndroidManifest.xml` mais abaixo, precisam de `host`/`scheme` por flavor também, já que dois apps não podem reivindicar o mesmo domínio verificado).

### 6. Sentry / env

`SENTRY_DSN`/`SENTRY_ENVIRONMENT` já são `--dart-define` (ver `01_current_architecture.md §7`) — cada clube pode ter um projeto Sentry próprio (recomendado, evita misturar erro de um app no dashboard do outro) via `--dart-define=SENTRY_DSN=...` no comando de build por flavor.

### 7. Assets por clube

`AppAssets`/`ClubAssets` (ver `10_club_config.md`) resolve o PATH em runtime, mas o ARQUIVO em si precisa existir no bundle — Flutter não faz tree-shaking de assets por flavor nativamente. Duas abordagens:
- (a) Empacotar os assets de TODOS os clubes em todo build (mais simples, app maior).
- (b) Usar `flutter build --flavor <nome>` combinado com uma estrutura de asset por pasta e um script de pre-build que só copia os assets do clube ativo pra dentro de `lib/assets/branding/active/` antes do build (mais trabalho, app menor). **Recomendo (a) pra começar** — 2-3 clubes não pesam o suficiente pra justificar a complexidade de (b) ainda.

### 8. Comandos de build

```bash
flutter build apk --flavor goias --dart-define=CLUB_ID=goias --dart-define-from-file=env_goias.json
flutter build apk --flavor juventude --dart-define=CLUB_ID=juventude --dart-define-from-file=env_juventude.json
```
(`env_<clube>.json` — ver nota em `13_flavors_web.md` sobre adotar esse padrão de arquivo, já usado nos projetos irmãos do mesmo autor.)

## Ainda não é publicação

Este documento cobre só a estrutura de build. Conta de developer na Play Store, ficha da loja, política de privacidade por app, etc. ficam fora do escopo desta fase.

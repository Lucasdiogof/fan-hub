# 12 — Flavor iOS

> Proposta — nada implementado. Baseado no estado real de `ios/Runner/Info.plist` e do projeto Xcode hoje. Gerado em 2026-09-01.

## Estado atual (confirmado no código)

- **Um scheme só**: `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`, com as 3 Build Configurations padrão do Flutter (Debug/Profile/Release) — nenhuma configuration extra por clube.
- `CFBundleIdentifier` já usa a variável padrão `$(PRODUCT_BUNDLE_IDENTIFIER)` (resolvida no `.pbxproj`, não hardcoded no `Info.plist`) — bom, é o padrão certo pra multi-target.
- `CFBundleDisplayName = "Goias App"` **hardcoded direto no `Info.plist`**, não via variável de build — precisa virar `$(CLUB_DISPLAY_NAME)` ou equivalente.
- `CFBundleName = "goias_app"` — nome interno, também hardcoded, menor prioridade (não aparece pro usuário).
- `GoogleService-Info.plist` existe em `ios/Runner/`, um arquivo só — precisa de um por clube.
- **Nenhum arquivo `.entitlements` encontrado em `ios/`** — push notification capability (`aps-environment`) não está configurada via entitlements checked-in no repo. Isso é um gap a confirmar (pode estar só nas configurações do Xcode, não versionado, ou pode significar que push iOS ainda não foi totalmente configurado) — vale confirmar direto no Xcode antes de prosseguir com multi-target.
- Sem `.xcconfig` próprio do projeto — só os 3 gerados automaticamente pelo Flutter (`Debug.xcconfig`, `Generated.xcconfig`, `Release.xcconfig`).

## Passo a passo proposto

### 1. Duplicar o target `Runner` por clube

No Xcode: `File > Duplicate...` do target `Runner` pra criar `Runner-Juventude` (ou usar `xcodegen`/edição manual do `.pbxproj` se preferir scriptável). Cada target novo ganha seu próprio:
- `PRODUCT_BUNDLE_IDENTIFIER` (ex.: `br.com.jec.juventude_app`)
- Scheme correspondente (`Runner-Juventude.xcscheme`), compartilhado (`xcshareddata`) pra aparecer nos comandos `flutter build`/`flutter run --flavor`.

### 2. `.xcconfig` por clube

Criar `ios/Flavors/Goias.xcconfig` / `ios/Flavors/Juventude.xcconfig`, cada um definindo:
```
PRODUCT_BUNDLE_IDENTIFIER = br.com.goiasec.goias_app
CLUB_DISPLAY_NAME = Goiás EC
```
Associar cada `.xcconfig` à Build Configuration do target correspondente (Xcode > target > Info > Configurations).

### 3. `Info.plist`

Trocar `CFBundleDisplayName` de `"Goias App"` (string literal) pra `$(CLUB_DISPLAY_NAME)` (variável resolvida pelo `.xcconfig` ativo). Se cada clube tiver seu próprio target (não só configuration), cada target pode até ter seu próprio `Info.plist` — mas reaproveitar um só com variáveis é mais simples de manter.

### 4. Ícone (`AppIcon`)

Duplicar o asset catalog `Assets.xcassets/AppIcon.appiconset` por clube (`AppIcon-Goias.appiconset`/`AppIcon-Juventude.appiconset`), e no target settings de cada um, `ASSETCATALOG_COMPILER_APPICON_NAME` aponta pro catalog certo. `flutter_launcher_icons` — mesma ressalva do Android: checar se a versão do pacote já suporta gerar por flavor nativamente antes de fazer isso manualmente.

### 5. `GoogleService-Info.plist` por clube

Criar um app novo no Firebase Console por `PRODUCT_BUNDLE_IDENTIFIER`, baixar o `.plist` de cada um, colocar em `ios/Runner-Juventude/GoogleService-Info.plist` (ou pasta equivalente), e garantir que o Build Phase "Copy Bundle Resources" de cada target só inclua o `.plist` certo (não os dois).

### 6. Push notifications / entitlements

**Antes de tudo**: confirmar no Xcode se a capability "Push Notifications" já está habilitada pro target `Runner` hoje (o repo não tem `.entitlements` versionado, então isso só é visível dentro do projeto aberto). Uma vez confirmado, cada target novo precisa da mesma capability habilitada individualmente + seu próprio App ID configurado no Apple Developer Portal com Push Notifications ativado + certificado/chave APNs próprio (ou uma chave APNs compartilhada, que a Apple permite reaproveitar entre App IDs do mesmo time).

### 7. Associated Domains / URL Schemes

Não auditados a fundo neste documento (não encontrados no `Info.plist` lido) — se o app usa Universal Links (`applinks:`) ou custom URL scheme pra deep link, cada clube precisa do seu próprio domínio/scheme configurado nas capabilities do target.

### 8. Convivência no mesmo iPhone

Já garantida automaticamente uma vez que cada target tem `PRODUCT_BUNDLE_IDENTIFIER` distinto — o iOS trata bundle ids diferentes como apps diferentes, sem configuração extra necessária.

### 9. Comandos de build

```bash
flutter build ios --flavor goias --dart-define=CLUB_ID=goias --dart-define-from-file=env_goias.json
flutter build ios --flavor juventude --dart-define=CLUB_ID=juventude --dart-define-from-file=env_juventude.json
```
Requer que o `--flavor` bata com o nome do scheme/target no Xcode (Flutter resolve `--flavor <nome>` procurando um scheme com esse nome).

## Ainda não é publicação

Provisioning profile, conta de developer, assinatura, TestFlight, App Store Connect — tudo fora do escopo desta fase.

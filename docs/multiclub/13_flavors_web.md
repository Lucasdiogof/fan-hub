# 13 — Flavor Web / PWA

> Proposta — nada implementado. Baseado no estado real de `web/index.html` e `web/manifest.json` hoje. Gerado em 2026-09-01.

## Estado atual (confirmado no código) — achado extra

`web/manifest.json` e `web/index.html` ainda estão nos **valores padrão do `flutter create`, nunca customizados pro Goiás**:
- `manifest.json`: `"name": "goias_app"`, `"short_name": "goias_app"`, `"description": "A new Flutter project."` — literalmente o placeholder padrão do Flutter.
- `index.html`: `<title>goias_app</title>`, `apple-mobile-web-app-title` = `"goias_app"`.
- `background_color`/`theme_color` no manifest **já é** `#004C1B` (cor certa do Goiás) — só o nome/descrição ficaram esquecidos.
- `theme-color` no `<head>` já está corretamente dividido claro/escuro (`#F6F8F7`/`#09110C`) — bem feito, só precisa virar variável por clube.

**Isso vale a pena corrigir pro próprio Goiás já, independente de multi-clube** — é uma correção de baixo risco (nome/descrição do PWA), sinalizo aqui mas não faço agora (fora do escopo desta auditoria, que pediu pra não alterar nada ainda).

## Passo a passo proposto pra multi-clube

### 1. `index.html`/`manifest.json` viram templates

Como não existe processamento de template nativo do Flutter web pra esses arquivos, a abordagem mais simples é: **build por clube com script de substituição** — antes de `flutter build web --dart-define=CLUB_ID=juventude`, um script (`tool/prepare_web_flavor.sh` ou similar) copia `web/manifest.template.json`/`web/index.template.html` pra `web/manifest.json`/`web/index.html` substituindo placeholders (`{{CLUB_NAME}}`, `{{THEME_COLOR_LIGHT}}`, etc.) pelos valores do `ClubConfig` do clube alvo (extraídos pra um JSON simples lido pelo script, espelhando os campos de `10_club_config.md`).

### 2. Favicon / ícones PWA

`web/favicon.png` e `web/icons/Icon-*.png` (192/512/maskable) precisam de um conjunto por clube — mesmo mecanismo do passo 1 (o script de prepare-flavor copia os arquivos certos pra dentro de `web/icons/` antes do build).

### 3. `--dart-define` no build web

```bash
flutter build web --dart-define=CLUB_ID=goias --dart-define=API_BASE_URL=https://goias-app.lucasdiogo1234.workers.dev
flutter build web --dart-define=CLUB_ID=juventude --dart-define=API_BASE_URL=https://juventude-app.<...>.workers.dev
```
`API_BASE_URL` já é `--dart-define` hoje (`lib/core/network/api_client.dart`) — cada clube aponta pro seu próprio Worker (ou pro mesmo Worker generalizado, ver `09_supabase_migration_plan.md §3`, se a rota vier a suportar `:clubSlug`).

### 4. Domínio / subdomínio

Fora do controle do Flutter em si — decisão de infraestrutura (Cloudflare Pages/Workers, hospedagem). Duas opções mencionadas no pedido original:
- Subdomínios (`goias.app...`/`juventude.app...`) — mais simples de gerenciar sob um domínio raiz só.
- Domínios totalmente separados — mais flexível pra branding independente, mas mais caro/manual de manter (cada um precisa do próprio certificado, DNS, etc.).

Ambas são viáveis com o build por flavor acima — a escolha não afeta o código Flutter, só onde cada build é publicado.

### 5. Service worker / cache

Flutter web já gera um service worker (`flutter_service_worker.js`) por build — como cada clube tem seu próprio build/deploy (domínio ou subdomínio diferente), não há risco de cache cruzado entre clubes por padrão (cada origem tem seu próprio cache do browser). Nenhuma mudança necessária aqui além do que já existe.

## Ainda não é publicação

Configuração de DNS, certificado, CDN — fora do escopo desta fase.

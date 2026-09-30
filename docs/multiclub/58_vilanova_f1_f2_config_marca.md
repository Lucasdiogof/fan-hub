# Vila Nova — F1 (config do clube) + F2 (marca) + fechamento do Firebase do F0

Data: 2026-09-29. Fonte: `docs/vila_nova_data/` (pacote v1.2, estado em `HANDOFF_ESTADO.md`) e o material oficial do clube.

## Pendência do F0 fechada: Firebase
- Apps criados no projeto Fan Hub (`fan-hub-29e9b`) pelo CLI:
  - Android `br.com.fanhub.vilanova`: `1:205743969933:android:c0047e60ae2bb8d044f4c4`;
  - iOS `br.com.fanhub.vilanova`: `1:205743969933:ios:7a7b90c123fa45ad44f4c4`.
- Configs em `android/app/src/vilanova/google-services.json` e `ios/Runner/Firebase/vilanova/GoogleService-Info.plist`.

## F2 — marca (feita antes da F1 porque a config aponta pros assets)
- **Cor oficial única** (manual de identidade visual, pág. 9): **#C33D41** (C0 M93 Y73 K0 / RGB 195,61,65 / PANTONE 18-1563 TPG). O manual não define cor secundária.
  - O próprio material oficial diverge: o PNG do escudo usa #ED3237 e o PDF vetorial usa #EF3746 (o CMYK convertido pra tela) sobre fundo #D32629.
  - Decisão: o tema do app usa o HEX declarado (#C33D41); escudos e ícones mantêm a arte original sem recolorir.
- `tooling/vilanova_brand/build_brand_assets.py` gera tudo a partir do **PDF vetorial oficial**. Os SVGs são as próprias formas do PDF, sem o retângulo de fundo; nada é redesenhado.
  - `crest.svg` (colorido) e `crest_seal.svg` (branco vazado; o selo do cadastro é tingido de branco);
  - `crest_badge.png` e `login_background.png` (gradiente vinho + escudo, provisório no espírito do Bragantino);
  - ícones Android (legacy + foreground adaptativo, fundo `#D32629`), iOS (`AppIcon-VilaNova`) e web, seguindo a "aplicação principal" do manual: escudo colorido sobre o vermelho.
- `placeholder.png/.svg` neutros (cinza) para estádio, lousa tática e loja, até existir arte real.
- `tool/web_flavors/vilanova.json`: tema `#C33D41` / `#F7F7F8` / `#0F0A0B`.

## F1 — `vilaNovaClubConfig`
- `lib/core/club/vilanova_club_config.dart`, registrado no `clubRegistry` (`APP_CLUB=vilanova`).
- **Identidade**: Vila Nova Futebol Clube / Vila Nova / torcida "Colorado" / fundado em 1943 / `canonicalClubId` `3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e` (do F0).
- **Integrações**: OneFootball `2865` / `vila-nova-2865` / `brasileirao-serie-b-superbet-119`, confirmado no site em 2026-09-29 (mesma Série B do Goiás; fecha o REVIEW do pacote). Redes oficiais e site preenchidos. Prefixo de pedido `VIL`. Retirada: `null`.
- **Capabilities**: TODAS `false`, `enabledArenaGames = {}`. Cada área liga na sua fase.
- **Nomes de produto**: Arena do Tigre e Passaporte Colorado (sugestões do pacote); Nação Colorada e Sócio Tigrão (nomes oficiais).
- **Passaporte**: `VilaNovaPassportContent` (pt/en/es) em `lib/features/passport/data/vilanova_passport_content.dart`.
- **Sócio**: programa vazio (`hasMembership=false`) até a F7.
- `team_visual_identity.dart`: sigla `VIL` como clube ativo; a cor do Vila como adversário (builds Goiás/Bragantino) passou a ser a oficial (#C33D41).

## ⚠ O flavor compila, mas ainda não SOBE
`supabaseUrl`/`supabasePublishableKey` estão `null` porque o projeto Supabase do Vila não existe, e `SupabaseConfig.configure` falha alto nesse caso (por design: nunca cai no projeto de outro clube). Para rodar, o usuário precisa criar o projeto. Depois disso: aplicar a baseline + `infra/supabase/clubs/vilanova/bootstrap.sql` e preencher as duas chaves na config.

## Verificação
- `flutter analyze`: 12 issues, **todos pré-existentes**, nenhum em arquivo desta fase.
- `flutter test`: **1533 passaram**, 1 skip. Isso inclui o novo `test/core/club/vilanova_identity_isolation_test.dart`: identidade, cores e integrações distintas de Goiás e Bragantino; nenhum texto vazado; todo asset na pasta do Vila e existente; tudo desligado; ícones distintos; configs do Firebase corretas.
- `tooling/multiclub/test_*.mjs`: **zero falhas novas**. As 13 que falham também falham numa cópia limpa do HEAD (`00ec2fe`).
  - Atenção: rodar essa bateria **reescreve** artefatos rastreados em `archive/` e `data_export/`. Foram restaurados com `git checkout` antes do commit.
- `flutter build apk --debug --flavor vilanova --dart-define=APP_CLUB=vilanova`: ✅ `app-vilanova-debug.apk`.
- `node tool/build_web_flavor.mjs vilanova`: ✅ título "Vila Nova FC", `theme_color` #C33D41, ícones com o escudo oficial.

# Vila Nova — F0: infraestrutura do flavor `vilanova`

Data: 2026-09-29. Fonte dos dados: `docs/vila_nova_data/` (pacote v0.7 da pesquisa, ver `HANDOFF_ESTADO.md` lá).

## Feito
- **Android** (`android/app/build.gradle.kts`): flavor `vilanova`, `applicationId = br.com.fanhub.vilanova`, `app_name = "Vila Nova FC"`, canais `vilanova_matches` / `vilanova_live_match_alerts_v2`. O Gradle reconhece as tasks (`assembleVilanova`, `installVilanovaDebug`...).
- **Ícones PROVISÓRIOS** (cinza `#37474F` + "VN", nunca escudo de outro clube), trocados pelo escudo real na F2:
  - `android/app/src/vilanova/res/` (mipmaps, foreground adaptativo, `colors.xml`);
  - `ios/Runner/Assets.xcassets/AppIcon-VilaNova.appiconset/`;
  - `lib/assets/branding/vilanova/web_icons/`.
- **iOS**: `ios/Flutter/Flavors/{Debug,Profile,Release}-vilanova.xcconfig` (bundle `br.com.fanhub.vilanova`, `APP_CLUB = vilanova`), scheme `vilanova.xcscheme` e, no `project.pbxproj`, 3 file refs + 3 configurações de projeto + 3 do alvo Runner (`AppIcon-VilaNova`) + as entradas de lista, clonadas das do Bragantino com IDs novos. O Run Script existente já escolhe o plist por `APP_CLUB` e falha alto se faltar o de `Runner/Firebase/vilanova/`.
- **Web**: `tool/web_flavors/vilanova.json` (tema neutro provisório), `tool/flavor_build_commands.json` e as allowlists de `tool/build_web_flavor.mjs` e `tool/cloudflare_build_web_flavor.sh`.
- **Identidade de clube**: `tooling/multiclub/clubs_registry.json` ganhou `vilanova` = `goias-app:multiclub:club:3` = **`3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e`** (via `registerNewClub`). `infra/supabase/clubs/vilanova/bootstrap.sql` insere a linha em `public.clubs` (**não aplicado**: o projeto ainda não existe).

## Não feito, de propósito
- **Worker** (`wrangler.vilanova.toml`): depende do registro de clubes do servidor (`src/football/_lib/club_server_config.ts`) e do slug do OneFootball. Vai para a **F8** (jogos, notícias e redes).
- **`supabase_projects_registry.json`**: precisa do project ref, que só existe depois que o projeto for criado.
- **`clubRegistry` do Flutter**: é a **F1**. Até lá, rodar o app com `APP_CLUB=vilanova` não resolve o clube.

## Tarefas do usuário (bloqueiam o build do flavor)
1. **Firebase (projeto Fan Hub `fan-hub-29e9b`)**: adicionar o app Android `br.com.fanhub.vilanova` e o app iOS `br.com.fanhub.vilanova`. Baixar:
   - `google-services.json` → `android/app/src/vilanova/google-services.json`;
   - `GoogleService-Info.plist` → `ios/Runner/Firebase/vilanova/GoogleService-Info.plist`.
2. **Supabase**: criar o projeto do Vila Nova (mesmo padrão do Bragantino) e informar o project ref. Depois: aplicar `supabase/migrations/` (baseline) e então `infra/supabase/clubs/vilanova/bootstrap.sql`.

## Estado das auditorias
As falhas abaixo **já existiam no `main` antes da F0** (conferido rodando as mesmas suítes numa cópia limpa do HEAD):
- `test_m4_3_flavor_registry_drift`: ainda espera o Bragantino fora do servidor, mas ele é servido desde 2026-09-08 (teste desatualizado). Os mecanismos de build já listam `goias`, `bragantino` e `vilanova`.
- `test_ios_firebase_flavor_wiring`, `test_cloudflare_build_web_flavor` (versão do Flutter fixada) e `test_multiclub_foundation` (padrão citado em `src/news/article.ts` que não existe mais).

# M4 — Onboarding REAL do Red Bull Bragantino + rebrand Fan Hub

Data: 2026-09-03
Status: **IMPLEMENTADO (sub-rodada 1: Android + Flutter + configs Fan Hub) — os 2 flavors compilam com os configs oficiais do Fan Hub. 0 db push, 0 Edge deploy, 0 Worker deploy, 0 git push, 0 troca de FCM service account, 0 exclusão de Firebase antigo, 0 deploy web. Baselines: flutter analyze 0, flutter test 956/1, JS 881/0.**

## APLICADO nesta rodada (2026-09-03)
Os 4 arquivos oficiais do Fan Hub (`fan-hub-29e9b`) foram posicionados; o `google-services.json` do Bragantino foi rebaixado (agora tem `fanhub.goias`+`fanhub.bragantino`, sem o `goias_app` antigo). `HANDCRAFTED_SYNTHETIC_GOOGLE_SERVICES_REMOVED=true`, `OLD_FIREBASE_CONFIG_USED_BY_NEW_FLAVORS=false` (nenhum flavor lê mais o projeto antigo).
- **Android**: `namespace`/`applicationId` → `br.com.fanhub.goias`; flavor `clubb`→`bragantino` (`br.com.fanhub.bragantino`, canal `bragantino_matches`, ícone placeholder próprio); `MainActivity.kt` movida pra `br/com/fanhub/goias/`; `src/goias/` + `src/bragantino/google-services.json` oficiais; `google-services.json` da raiz (projeto antigo) REMOVIDO.
- **Flutter**: `bragantinoClubConfig` REAL no `clubRegistry` (capabilities TODAS false, `enabledArenaGames={}`, campos DATA/ASSET_GAP como PLACEHOLDER com TODO — nunca dado/asset do Goiás); path sintético removido de `lib/` (`synthetic_club_build_config.dart`, branch `club-b`, `ENABLE_SYNTHETIC_CLUB`); assets `synthetic_club_b/`→`bragantino/` (placeholders neutros). Fixtures de teste `syntheticClubBConfig` MANTIDAS (test-only).
- **iOS (file-based)**: bundle `goiasApp`→`fanhub.goias` no pbxproj; scheme/xcconfig `clubb`→`bragantino`; plists oficiais em `ios/Runner/Firebase/{goias,bragantino}/`; root plist = Fan Hub goias.
- **Tooling web**: `web_flavors/club-b.json`→`bragantino.json`, `flavor_build_commands.json` + `build_web_flavor.mjs` sem sintético.
- **Server registries (Worker/Edge) INTOCADOS** = só `goias` (Bragantino ainda não é servido — capabilities off, sem OneFootball/notificações/clubs row). Client-registered != server-served.
- Audits M-series atualizados (registry agora {goias,bragantino}; `m4_3_flavor_registry_drift` reescrito pro novo modelo; sanity de "só goias" → "clubes reais conhecidos").

## PENDENTE (sub-rodadas próprias, NÃO feito)
1. **iOS Run Script do plist por flavor** — os 2 plists estão posicionados, mas falta a build phase no Xcode que copia SÓ o do flavor ativo pro bundle. Hoje o root plist é o do Goiás → o build iOS do `bragantino` usaria o Firebase do Goiás até o Run Script existir. (Não verificável sem Mac/Xcode — o usuário está em Android.)
2. **Dados/assets reais do Bragantino** — canonicalClubId (linha `public.clubs`), cores oficiais, escudo, ids OneFootball, conteúdo de Arena → depois ligar capabilities. Ver §8.
3. **Migração FCM** (tokens antigos são do projeto antigo) — fase própria. Ver §7.
4. **Web/Edge/Worker deploy** do Bragantino — fora de escopo.

Decisão de produto: abandonar o `club-b` sintético (M4.3B) e onboardar o Bragantino REAL. Novo projeto Firebase compartilhado = **Fan Hub**. Packages/bundles novos: `br.com.fanhub.goias` e `br.com.fanhub.bragantino`.

## Flags de estado
- `HANDCRAFTED_SYNTHETIC_GOOGLE_SERVICES_REMOVED = true` (feito — `android/app/src/clubb/google-services.json` fabricado removido; nenhum valor reaproveitado).
- `OLD_FIREBASE_CONFIG_USED_BY_NEW_FLAVORS = true` **(AINDA)** — o flavor `goias` continua usando `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` do projeto antigo (`goias-app-4ef7e`). Só vira `false` no fim da rodada de implementação, quando os 4 arquivos oficiais do Fan Hub estiverem no lugar. **NÃO declarar false agora seria mentira.**
- `IOS_FIREBASE_CONFIG_WIRING_UNCONFIRMED = true` (a resolver na implementação — hoje há 1 plist único no Runner, sem seleção por flavor).

---

## 1. Impacto Android
- `namespace` + `defaultConfig.applicationId` = `br.com.goiasec.goias_app` → alvo `br.com.fanhub.goias`.
- `productFlavors`: hoje `goias` (`br.com.goiasec.goias_app`) + `clubb` (`br.com.goiasec.goias_app.clubb`, sintético). Alvo: `goias` (`br.com.fanhub.goias`) + `bragantino` (`br.com.fanhub.bragantino`). Flavor `clubb` **removido**.
- **Kotlin package path**: `android/app/src/main/kotlin/br/com/goiasec/goias_app/MainActivity.kt` (+ `package` decl) — mover pra `br/com/fanhub/goias/` OU manter o namespace do código desacoplado do applicationId (Gradle permite `namespace` != `applicationId`). Decisão de implementação (§10).
- `AndroidManifest.xml` — referências a package/authorities/deep links/FileProvider authorities (se houver `${applicationId}`) recalculam sozinhas; conferir authorities hardcoded.
- Firebase por flavor: `android/app/src/goias/google-services.json` (oficial Fan Hub goias) + `android/app/src/bragantino/google-services.json` (oficial Fan Hub bragantino). Remover o `android/app/google-services.json` da raiz (antigo) OU mantê-lo só como legacy até o cutover (decisão §10). Nenhum flavor pode carregar o JSON do outro — garantido por arquivo por-flavor + teste estático.
- `manifestPlaceholders`/`buildConfigField` de canal de notificação: `goias_matches` (goias) + criar `bragantino_matches` (bragantino). O `clubb`/`club_b_matches` some.
- Ícones: `android/app/src/clubb/res/...` (launcher sintético) → renomear conceito pra `bragantino/res/...` com o crest REAL do Bragantino (asset gap, §8). Nunca reusar o do Goiás.

## 2. Impacto iOS
- `PRODUCT_BUNDLE_IDENTIFIER = br.com.goiasec.goiasApp` (camelCase!) → alvo `br.com.fanhub.goias`. RunnerTests seguem sufixo próprio.
- Schemes: hoje `Runner`, `goias`, `clubb`. Alvo: `goias`, `bragantino` (+ Runner). Scheme `clubb` removido.
- xcconfigs: `ios/Flutter/Flavors/{Debug,Profile,Release}-{goias,clubb}.xcconfig` → trocar `clubb` por `bragantino`, setar `PRODUCT_BUNDLE_IDENTIFIER` e `APP_CLUB` por flavor (via `DART_DEFINES`/xcconfig).
- **Firebase iOS (o `IOS_FIREBASE_CONFIG_WIRING_UNCONFIRMED`)**: hoje **1 único** `ios/Runner/GoogleService-Info.plist` (antigo, na raiz do Runner) — usado por TODOS os schemes, o que é errado num multi-flavor. Alvo: `ios/Runner/Firebase/goias/GoogleService-Info.plist` + `ios/Runner/Firebase/bragantino/GoogleService-Info.plist` (os 2 `.plist` oficiais do Fan Hub) + um **Run Script build phase** (rodando ANTES de "Copy Bundle Resources") que copia SÓ o plist do flavor atual pro bundle como `GoogleService-Info.plist`, escolhendo por `$PRODUCT_BUNDLE_IDENTIFIER`/scheme. Nunca os dois no bundle. Remover o plist único da raiz do Runner do "Copy Bundle Resources".

## 3. Impacto Flutter
- `clubRegistry` (produção): hoje `{ 'goias': goiasClubConfig }`. Alvo: `{ 'goias': goiasClubConfig, 'bragantino': bragantinoClubConfig }` — Bragantino REAL, não sintético.
- `resolve_active_club.dart`: remover o branch sintético (`syntheticClubCode='club-b'`, `enableSyntheticClub`, `syntheticClubBBuildConfig`). Com Bragantino no registry, `APP_CLUB=bragantino` resolve pelo mapa normal. O gate `ENABLE_SYNTHETIC_CLUB` deixa de existir na produção.
- `synthetic_club_build_config.dart` (em `lib/`): **REMOVE_NOW** (era o único config sintético compilável; supersedido pelo Bragantino real).
- `club_scoped_storage_key.dart`: usa `club-b`? auditar — se for só em comentário/exemplo, ajustar; se for lógica, garantir que funciona por `code` genérico (bragantino).
- `goias_club_config.dart`: intocado (Goiás real continua). Criar `bragantino_club_config.dart` com capabilities REAIS (começando desligadas onde falta dado — §8).
- Assets: `lib/assets/branding/synthetic_club_b/` (do sintético) → **REMOVE_NOW**; criar `lib/assets/branding/bragantino/` com crest/badge REAIS (asset gap).

## 4. Arquivos que precisam mudar (inventário)
**Android**: `android/app/build.gradle.kts` (namespace/applicationId/flavors/channels), `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/.../MainActivity.kt` (package path), `android/app/src/clubb/` → `android/app/src/bragantino/` (ícones reais), **novos**: `android/app/src/goias/google-services.json` + `android/app/src/bragantino/google-services.json` (oficiais), **remover**: `android/app/google-services.json` (raiz, antigo) no cutover.
**iOS**: `ios/Runner.xcodeproj/project.pbxproj` (bundle ids, build phase), `xcshareddata/xcschemes/{goias,bragantino}.xcscheme` (renomear clubb), `ios/Flutter/Flavors/*-{goias,bragantino}.xcconfig`, **novos**: `ios/Runner/Firebase/{goias,bragantino}/GoogleService-Info.plist` (oficiais) + script de cópia, **remover** do bundle: `ios/Runner/GoogleService-Info.plist` único.
**Flutter**: `lib/core/club/club_registry.dart`, `lib/core/club/resolve_active_club.dart`, **novo** `lib/core/club/bragantino_club_config.dart`, **remover** `lib/core/club/synthetic_club_build_config.dart`, `lib/assets/branding/bragantino/*` (novos), pubspec assets.
**Tooling**: `check_app_club_enforced.mjs`, `audit_m4_3_flavor_registry_drift.mjs` (+ testes) — trocar `clubb`→`bragantino`, remover `ENABLE_SYNTHETIC_CLUB`. **Test fixtures**: `test/core/club/synthetic_club_config.dart` + os testes que usam `syntheticClubBConfig` — **KEEP_AS_TEST_FIXTURE** (isolamento).

## 5. Synthetic cleanup — classificação (nunca substituição cega)
| item | classificação | ação |
|---|---|---|
| `lib/core/club/synthetic_club_build_config.dart` | **REMOVE_NOW** | apagar (config sintética compilável; supersedida pelo Bragantino real) |
| branch sintético em `resolve_active_club.dart` (`club-b`, `enableSyntheticClub`, `syntheticClubCode`) | **REMOVE_NOW** | remover; Bragantino resolve pelo registry normal |
| `ENABLE_SYNTHETIC_CLUB` (dart-define/gate) | **REMOVE_NOW** | deixa de existir na produção |
| flavor `clubb` (gradle) + scheme `clubb` (iOS) + `*-clubb.xcconfig` | **SUPERSEDED_BY_REAL_BRAGANTINO** | substituir por `bragantino` |
| `br.com.goiasec.goias_app.clubb` | **REMOVE_NOW** | não pode sobrar em lugar nenhum |
| `android/app/src/clubb/res/*` (ícones sintéticos) | **SUPERSEDED_BY_REAL_BRAGANTINO** | virar `bragantino/res/*` com crest real |
| `lib/assets/branding/synthetic_club_b/*` | **REMOVE_NOW** | apagar; criar `bragantino/*` real |
| `test/core/club/synthetic_club_config.dart` (`syntheticClubBConfig`) | **KEEP_AS_TEST_FIXTURE** | fica em `test/` — prova isolamento tenant sem cadastrar clube real; nunca compilado num build |
| testes que usam `syntheticClubBConfig` (m4_1_critical_leakage, capability_route_gate, club_scoped_*, local caches, etc.) | **KEEP_AS_TEST_FIXTURE** | mantêm (isolamento) — podem ganhar um par com `bragantinoClubConfig` real depois |
| `docs/multiclub/45/46_*` (relatórios M4.3A/B) | **KEEP** | registro histórico; nota de supersessão |
| tooling `audit_m4_3_flavor_registry_drift` / `check_app_club_enforced` | **atualizar** | trocar clubb→bragantino, remover ENABLE_SYNTHETIC_CLUB do universo esperado |

Regra respeitada: infra genérica de build (dimensão "club", pipeline de flavor, xcconfig por flavor, cópia de plist) é **reaproveitada**; identidade `clubb` de produção **desaparece**; fixtures de teste sintéticas **permanecem test-only**.

## 6. Plano de Firebase config por flavor
**Android**: cada flavor lê SÓ seu `src/<flavor>/google-services.json` (o plugin Google Services prioriza o arquivo do flavor sobre o da raiz). Colocar os 2 oficiais em `src/goias/` e `src/bragantino/`. Teste estático: cada `google-services.json` tem exatamente 1 client, com `package_name` == applicationId do flavor, e `project_id` == Fan Hub (nunca `goias-app-4ef7e`).
**iOS**: os 2 `.plist` oficiais em `ios/Runner/Firebase/{goias,bragantino}/`; Run Script copia o do flavor ativo pro bundle. Teste: nenhum flavor carrega o plist do outro; `BUNDLE_ID` do plist == bundle do flavor.
**Nunca** editar/gerar credenciais — só posicionar os 4 arquivos que você baixou.

## 7. Plano de migração FCM (fases — NÃO nesta rodada)
Os tokens atuais do Goiás foram emitidos pelo Firebase **antigo** (`goias-app-4ef7e`) e vivem em `user_notification_tokens`. O `notifications-dispatch` (Edge) usa `FCM_SERVICE_ACCOUNT_JSON` do projeto antigo.
- **Fase A (esta rodada)**: só estrutura local + configs Fan Hub + os 2 apps compilando. **0 troca de service account, 0 Edge deploy.** Tokens antigos continuam válidos pro app antigo publicado.
- **Fase B (própria etapa)**: quando o app novo (Fan Hub) começar a rodar, ele registra tokens no projeto **novo**. Coexistência: population de tokens antigos (app antigo) + novos (app novo). O dispatch precisará do service account do Fan Hub — decidir se manda pros dois projetos (dois service accounts) durante a transição ou força upgrade. **Nunca** invalidar tokens antigos abruptamente.
- **Fase C**: aposentar o projeto antigo só depois de migração/adoção comprovada.

## 8. Dados/assets do ClubConfig Bragantino que faltam (não inventar)
`ClubConfig` exige 6 subobjetos. Faltam, para o Bragantino (nunca fallback do Goiás):
- **identity**: `canonicalClubId` → precisa de uma linha REAL em `public.clubs` (uuid) — mas 0 db push nesta rodada → **DATA_GAP** (criar clubs row numa etapa de dados). `code='bragantino'`, `slug`, `displayName='Red Bull Bragantino'`, `shortName`, `fanDemonym` — texto, ok fornecer.
- **branding**: cores light/dark REAIS do Bragantino (vermelho/branco/preto) — **DATA_GAP** (hex exatos, não inventar sem fonte oficial).
- **assets**: `crest` + `crestBadge` (+ outros) — **ASSET_GAP** (imagens do escudo do Bragantino; nunca o do Goiás).
- **integrations**: `oneFootballTeamId`/`oneFootballSlug`/`oneFootballCompetitionSlug` do Bragantino — **DATA_GAP** (ids reais do OneFootball). `orderPrefix`, `pickupAddress` (storeName/street/city/state/zip) — só se `hasStore=true`; como começa `false`, pode ser um placeholder desabilitado (documentar). Social/contact URLs: opcionais (`null`).
- **capabilities** (começam DESLIGADAS onde falta dado): `hasPassport=false`, `hasStore=false`, `hasTickets=false`, `hasCrowdLineup=false`. `hasMembership`/`hasNews`/`hasSocial` — decidir por disponibilidade real de dado/integração (default `false` até provar). `enabledArenaGames` — só jogos com CONTEÚDO do Bragantino no Supabase (career_players/guess_players/lineup_matches/quiz_questions do Bragantino) → **DATA_GAP**; começar `{}` (vazio) até seedar conteúdo.
- **productNames**: `arenaName`/`passportName`/`storeName`/`membershipProgramName` — texto do Bragantino (ou genérico), fornecer.
> Resumo: o que é **texto/decisão** (identity básica, productNames, capabilities=false) dá pra montar já; o que é **DATA_GAP/ASSET_GAP** (canonicalClubId/clubs row, cores oficiais, crest, ids OneFootball, conteúdo de Arena) precisa de dado real fornecido antes.

## 9. Riscos pros usuários Goiás atuais
- **CRÍTICO — mudança de applicationId/bundle** (`br.com.goiasec.goias_app`→`br.com.fanhub.goias`; iOS `goiasApp`→`fanhub.goias`): é um app NOVO nas lojas. O install atual do Goiás **não** atualiza pro novo id automaticamente. Sem transferência de listing (Play/App Store), vira reinstalação: o usuário perde estado LOCAL (SharedPreferences, cache, **sessão Supabase logada** → precisa logar de novo) — dados de servidor (progresso, membership, pedidos) sobrevivem porque estão no Supabase por `user_id`, mas o usuário precisa reautenticar. **Avaliar transferência de app / estratégia de comunicação.**
- **FCM**: tokens antigos são do projeto antigo. Até o dispatch mandar pro projeto novo (Fase B), push do app novo não chega; e push pro app antigo depende de manter o service account antigo. Sem cuidado, um período sem notificação.
- **Deep links / OAuth redirect / Supabase redirect URLs**: se algum usa o applicationId/bundle (ex.: `br.com.goiasec.goias_app://`), quebra — auditar Supabase Auth redirect config + intent filters.
- **Assinatura de release**: o app segue assinando com debug key (gap pré-existente, doc 45 §11) — publicar com nova assinatura/id é outra descontinuidade.

## 10. Ordem exata de implementação (proposta — cada passo é uma sub-rodada revisável)
1. **Posicionar os 4 arquivos oficiais** (você fornece): `src/goias/` + `src/bragantino/` (Android), `Runner/Firebase/{goias,bragantino}/` (iOS). 0 edição de credencial.
2. **Bragantino ClubConfig mínimo** (texto + capabilities=false + `enabledArenaGames={}`), com os DATA_GAPs marcados `TODO`/desabilitados — **sem inventar**. Registrar no `clubRegistry`.
3. **Remover o path sintético** de `lib/` (synthetic_club_build_config, branch club-b, ENABLE_SYNTHETIC_CLUB) — testes de fixture em `test/` permanecem.
4. **Android**: renomear applicationId/namespace/flavors (goias→fanhub.goias, clubb→bragantino), canais de notificação, kotlin package/AndroidManifest, ícones bragantino. Wiring por-flavor do google-services.
5. **iOS**: bundle ids, schemes (clubb→bragantino), xcconfigs, Run Script de cópia do plist por flavor (resolve `IOS_FIREBASE_CONFIG_WIRING_UNCONFIRMED`).
6. **Tooling/testes**: atualizar flavor-drift/enforcement pra {goias,bragantino}; baselines (analyze/test/JS) verdes.
7. **Provar os 2 apps compilando** usando SÓ configs Fan Hub → então `OLD_FIREBASE_CONFIG_USED_BY_NEW_FLAVORS=false`. **PARE.**
8. (Depois, etapas próprias, NÃO agora) criar `clubs` row do Bragantino + seed de conteúdo + cores/crest reais → ligar capabilities; migração FCM (Fase B); deploy web/Edge.

## RODADA 2 — Fechamento (GERAL completa, autorizada explicitamente)

Além da sub-rodada 1 (Android+Flutter+configs Fan Hub, registrada acima), esta rodada também consolidou trabalho que já estava pronto no working tree mas nunca fora commitado, mais correções feitas nesta própria rodada:

- **Visual isolation**: `hasClubContent` (novo campo `ClubCapabilities`) gateando `/clube`+`/partners` via `capabilityGateRedirect` + Home (`ClubEntryCard`); `hasMatches` (novo campo) gateando a aba Jogos/calendário — depende de `ClubIntegrations.workerBaseUrl` configurado; splash por clube (`ClubAssets.splashVideo`, `null` cai pra `StaticLogoSplash`, nunca o vídeo do Goiás); `home_brand_header.dart`/`club_badge.dart` leem `ClubConfig` em vez de string/asset hardcoded; `Team.matchesClub(ClubConfig)` substitui todo `team.id==1863`/`isGoias` de identidade ativa (achados residuais de `isGoias` em `career_models.dart`/`club_history_entry.dart` são flags de CONTEÚDO histórico, não identidade ativa — classificação já registrada em `audit_multiclub_runtime_hardcodes.mjs`, não confundir os dois). Verificado por 2 agentes de auditoria independentes nesta rodada — 0 vazamento encontrado.
- **Football Worker genericizado**: `CLUB_CODE`/`TEAM_ONEFOOTBALL_SLUG`/`PRIMARY_COMPETITION_SLUG`/`PRIMARY_COMPETITION_DISPLAY_NAME` agora vêm 100% de `wrangler.toml`/`wrangler.bragantino.toml` (1 deploy por clube, mesmo `src/`, nunca uma lista hardcoded no código — `SERVER_CLUB_CODES` foi removido). `PRIMARY_COMPETITION_DISPLAY_NAME` usado SÓ em `standings.ts`/`currentRound.ts` — `team.ts`/`teamSeason.ts`/`fixtureDetails.ts` agora preservam a competição REAL de cada partida (`competitionName` vindo do próprio payload do OneFootball), nunca achatando Copa do Brasil/Sudamericana como Brasileirão. `wrangler.bragantino.toml` existe, dry-run validado, **nunca deployado** (comentário no próprio arquivo + `hasMatches=false` garantem isso).
- **Membership RPC fix**: `20260903180000_fix_ambiguous_id_membership_rpcs.sql` — já aplicada, commit `6bfc622` (rodada anterior a esta). Reconfirmada nesta rodada: 60/60 migrations, 0 pending.
- **`ClubProductNaming` parcialmente ligado**: `digital_membership_card.dart`/`membership_success_page.dart` agora leem `productNames.membershipProgramName` — não é mais "0 consumidores" (M4.1 original), tooling atualizada.
- **Tooling corrigida nesta rodada** (regressões de auditoria, não de produto — arquitetura mudou, os checkers estavam desatualizados): `audit_m4_3_flavor_registry_drift.mjs` (workerRegistry via `wrangler.toml` `CLUB_CODE`, não mais array hardcoded), `audit_multiclub_runtime_hardcodes.mjs` (drift check Flutter/Worker/Edge redesenhado — Worker não carrega mais `canonicalClubId`/id numérico do OneFootball, só slug), `test_fix_ambiguous_id_membership_rpcs.mjs` (asserção de `git status` pré-commit virou pós-commit), `test_m4_critical_club_leakage.mjs` (`productNamingConsumers` 0→2).
- **Gates finais desta rodada**: `flutter analyze` 0, `flutter test` 995/1 skip, `tsc --noEmit` 0, `vitest run` 141/141, JS tooling 908/0, `npx wrangler deploy --dry-run` limpo pros 2 configs (Goiás + Bragantino), DB 60/60 (0 pending).
- **Ainda PENDENTE** (inalterado — nenhuma dessas foi tocada nesta rodada, por instrução explícita): dados/assets reais do Bragantino (§8), migração FCM (§7), `clubs` row do Bragantino no Supabase, Store/Sócio/Passaporte do Bragantino, iOS Run Script de plist por flavor (§ "PENDENTE" item 1, segue sem Mac/Xcode pra verificar).

`OLD_FIREBASE_CONFIG_USED_BY_NEW_FLAVORS=false` confirmado (os 2 flavors leem só os arquivos oficiais Fan Hub, `fan-hub-29e9b`).

---

**PARE.** Nada implementado além da remoção do arquivo sintético fabricado. Aguardando revisão deste design e os 4 arquivos oficiais posicionados antes de tocar em qualquer flavor/config.

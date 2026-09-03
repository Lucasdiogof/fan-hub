# M4.1 — Critical Club Leakage Removal

Data: 2026-09-03
Status original (na 1ª entrega desta rodada): **IMPLEMENTAÇÃO LOCAL COMPLETA + TESTADA, `M4_CRITICAL_LEAKAGE_READY=true`.**

## ⚠️ CORREÇÃO — M4.1b (mesmo dia, antes de qualquer deploy)

A 1ª interpretação deste relatório considerava `notifications-dispatch` **resolvido** — errado. A correção da §6 (elegibilidade por usuário via `user_notification_preferences`) é real e continua válida, mas ela só resolve **QUEM** deveria receber um evento, nunca **QUAL TOKEN** é seguro usar pra entregar. `user_notification_tokens` continua sem `club_id`, e um usuário com tokens de dois clubes (cenário só possível quando flavors reais existirem) teria AMBOS os tokens buscados pro evento de qualquer um dos dois clubes — vazamento real, não hipotético, nunca provado como seguro.

Auditoria completa desse gap específico está na seção **"M4.1b — Notification Token Ownership Audit"** ao final deste documento. Os status finais corretos são:

```
M4_1_IMPLEMENTATION_LOCAL_COMPLETE=true   (o código desta rodada foi escrito e testado)
M4_CRITICAL_LEAKAGE_READY=false           (CORRIGIDO — o gap de token não estava provado)
NOTIFICATION_USER_ELIGIBILITY_CLUB_SCOPED=true
NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=false
NOTIFICATION_MULTICLUB_MODEL_READY=false
STORE_SAFE_FOR_CLUB_B=false
```

O restante deste documento (§1-13 abaixo) é preservado **como foi escrito originalmente** — histórico, não reescrito — exceto por esta nota de correção no topo. A seção `M4.1b` no final é a auditoria nova, completa, do problema.

## ✅ M4.1c — implementação do design da M4.1b (mesmo dia)

A migration desenhada na M4.1b foi criada, o Flutter/Edge foram atualizados, tudo testado. **Continua sem aplicar** (`0 db push`, `0 Edge deploy`, `0 git push`) — o código está correto, a produção ainda não. Ver seção **"M4.1c — Notification Token Club Ownership"** ao final. Status atualizados:

## ⚠️ CORREÇÃO — M4.1c-A (mesmo dia, achado do dono ANTES de qualquer `db push`)

A migration descrita originalmente na seção "M4.1c" abaixo (§1-3) fazia `ADD COLUMN` + `SET NOT NULL` + `DROP DEFAULT` na MESMA operação. **Bug de rollout real, pego a tempo**: produção hoje roda `1.0.1+2`, cujo `registerToken` ainda NÃO manda `club_id` — um `DROP DEFAULT` aplicado ANTES desse runtime ser substituído quebraria (violação `NOT NULL`) todo registro/refresh feito pelo cliente antigo. A migration foi corrigida pra **manter o `DEFAULT`** (rollout em 2 fases: A aditiva agora, B remove o `DEFAULT` só depois do runtime novo confirmado em campo). Detalhes completos na seção **"M4.1c-A — Rollout Compatibility Fix"** ao final. Status corrigidos:

```
NOTIFICATION_TOKEN_CLUB_COLUMN_READY=true
NOTIFICATION_TOKEN_CLUB_DEFAULT_TRANSITIONAL=true
NOTIFICATION_TOKEN_DEFAULT_FINAL=false
```

O texto original da seção "M4.1c" (§1-3, que descrevia `DROP DEFAULT` na mesma migration) é preservado abaixo **como histórico**, não reescrito — a versão corrigida está na nova seção final.

```
NOTIFICATION_USER_ELIGIBILITY_CLUB_SCOPED=true
NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=true    (código correto e testado — M4.1c)
NOTIFICATION_MULTICLUB_MODEL_READY=true         (código correto e testado — M4.1c)
NOTIFICATION_SCHEMA_APPLIED_LIVE=false          (0 db push — nunca confundir com o acima)
M4_1_IMPLEMENTATION_LOCAL_COMPLETE=true
M4_CRITICAL_LEAKAGE_READY=true                  (CORRIGIDO DE NOVO — agora reflete o código completo)
STORE_SAFE_FOR_CLUB_B=false                     (inalterado, fora de escopo)
```

---

Autorizada pela auditoria M4 round 1 (`docs/multiclub/42_m4_second_club_product_readiness_audit.md`), focada nos blockers que fariam um segundo clube **realmente exibir/enviar dados do Goiás** — não o backlog inteiro de `SECOND_CLUB_PRODUCT_READY`.

---

## 1. Assets

Auditoria confirmou 12 consumidores reais de `AppAssets.<literal>` fora da própria definição/mock (agent 3 da rodada anterior encontrou 14 arquivos via grep — 2 eram falsos positivos: comentário em doc + a própria definição). Migrados para `sl<ClubConfig>().assets.*`:

| Arquivo | Asset |
|---|---|
| `page_title.dart` | `crestBadge` |
| `goias_loading_indicator.dart` | `crestBadge` |
| `auth_scaffold.dart` (×2) | `stadium`, `crest` |
| `login_page.dart` | `loginBackground` |
| `crowd_lineup_hero_card.dart` | `tacticsBoardIllustration` |
| `arena_spotlight_card.dart` | `arenaStadiumPhoto` |
| `static_logo_splash.dart` (×2) | `crestBadge` |
| `goias_bottom_navigation_bar.dart` | `crestBadge` |
| `live_match_hero.dart` | `matchHero` |
| `next_match_hero.dart` | `matchHero` |
| `passport_cover_v2.dart` | `crestBadge` |
| `passport_trajectory_page.dart` | `crestBadge` |

**Classificação**: todos os 10 campos de `ClubAssets` são `CLUB_ASSET` (identidade visual do clube) — nenhum "asset genérico de UI" foi movido pra `ClubConfig` (ícones Material, texturas, sprites do Arena minigame ficaram como estavam, corretamente `GLOBAL_UI_ASSET`/`FEATURE_CONTENT_ASSET`).

**Exclusão-padrão preservada**: `lib/features/store/presentation/widgets/store_entry_card.dart` (mudança pré-existente não relacionada, nunca tocada em nenhuma rodada) **não foi editado** — continua com `AppAssets.storeBanner` hardcoded. Ferramenta registra isso explicitamente (`storeEntryCardStillExcluded=true`), não como bug desta rodada.

`CLUB_ASSET_RUNTIME_HARDCODES = 0` (fora da exclusão).

## 2. `ClubBranding`

`AppTheme._themeFor` já era parametrizado por `AppColors` — só os 2 getters `AppTheme.light`/`.dark` hardcodavam a constante estática. Viraram métodos com parâmetro opcional (`AppTheme.light([AppColors? colors])`), e `lib/main.dart` agora constrói o tema com `_clubConfig.branding.light`/`.dark`. Isso torna `ClubConfig.branding` realmente consumido pela primeira vez, sem tocar nenhum dos ~200+ call sites de `context.colors` (que continuam lendo do `ThemeExtension` normalmente — a mudança é só na fonte que constrói esse `ThemeData`).

**Não migrado de propósito** (não é uma refatoração de paleta): as ~10 ocorrências de `AppColors.light`/`AppColors.dark` usadas fora do contexto de tema (ex.: `login_page.dart:199`, `passport_level_style.dart`, `app_button_styles.dart` — cores "fixas independente do tema do usuário", um conceito diferente de branding por clube) — mudar essas exigiria decidir se cada uma delas TAMBÉM deveria variar por clube, uma decisão de produto fora do escopo desta rodada.

`CLUB_BRANDING_CONSUMERS`: 0 → **1** (`main.dart`).

## 3. Product naming

**Investigado, não wireado — decisão explícita, documentada**: os nomes reais ("Arena Esmeraldina", "Passaporte Esmeraldino" etc.) vivem inteiramente no l10n (`app_pt.arb`/`app_en.arb`/`app_es.arb`), nunca como string literal solta em nenhum widget. Ligar `ClubProductNaming` exigiria OU (a) tornar o l10n inteiro parametrizável por clube — uma mudança de arquitetura de i18n bem maior que "pequena e focada" — OU (b) uma técnica de substituição de placeholder dentro do l10n que este projeto não usa hoje. `ClubProductNaming` permanece 0 consumidores, deliberadamente, registrado como decisão de M4.2 (junto com a fiação completa de `ClubCapabilities`).

## 4. Config bypasses corrigidos

| Bypass | Correção |
|---|---|
| `MembershipContactConfig` | Vira getters lendo `sl<ClubConfig>().integrations.contactWhatsapp{Number,Url}` — mesma API pública, 0 call site alterado. |
| `PickupInformation` (Store) | Campos passam a `required` (sem default hardcoded); novo `PickupInformation.forActiveClub()` lê `ClubIntegrations.pickupAddress` — 8 call sites de produção migrados (`const PickupInformation()` → `PickupInformation.forActiveClub()`); 3 fixtures de teste passaram a usar valores literais de teste explícitos (não precisam de `ClubConfig`, são só dado de fixture). |
| `SocialLinksData` | `ClubIntegrations` ganhou 6 campos novos (`socialInstagramUrl`/`YoutubeUrl`/`TiktokUrl`/`FacebookUrl`/`XUrl`/`officialSiteUrl`, todos `String?`) — gap real de contrato, não só fiação. `SocialLinksData.all` virou getter que monta a lista só com as redes configuradas (glifo SVG continua estático — é o ícone da PLATAFORMA, não do clube). `SocialEmptyState` (duplicata encontrada na auditoria) migrada do mesmo jeito, mesma fonte. |
| `MaterialApp(title: 'Goiás EC')` | Vira `_clubConfig.identity.displayName`. |
| `passport_match_ticket_v2.dart` | `_isGoias(String team) => team.toLowerCase().contains('goiás')` renomeado `_isActiveClub`, agora compara contra `sl<ClubConfig>().identity.shortName`/`.displayName` — não usa `Team.matchesClub` diretamente porque este widget só recebe nomes de time como `String`, não `Team`, mas a FONTE do valor comparado deixou de ser um literal fixo. |

`CONFIG_BYPASSES_REMAINING = 0` (dos 5 confirmados na auditoria).

## 5. Store — prefixo `GOI-`

**Corrigido**: `supabase_store_orders_repository.dart` (path de demo "pagamento recusado") — `'GOI-${now.year}-...'` → `'${_clubConfig.integrations.orderPrefix}-${now.year}-...'`.

**NÃO corrigido — PARE, design apresentado, aplicação requer decisão própria**: `generate_store_order_number()` (SQL) continua com `'GOI-'` hardcoded. Investigado a fundo: a função é usada como **DEFAULT de coluna** (`order_number text not null unique default public.generate_store_order_number()`), e a RPC `create_store_order_for_club` nunca lista `order_number` no seu próprio INSERT — depende inteiramente do DEFAULT. **Um DEFAULT de coluna no Postgres não tem acesso às OUTRAS colunas da mesma linha sendo inserida** — não existe forma de passar `p_club_id` pra um DEFAULT. Corrigir isso de verdade exigiria:

1. Uma nova coluna `clubs.order_prefix text` (schema novo);
2. Mudar a assinatura de `generate_store_order_number()` para `generate_store_order_number(p_club_id uuid)`, buscando o prefixo em `clubs`;
3. Trocar o DEFAULT por um **trigger BEFORE INSERT** em `store_orders` (único jeito de ter acesso a `NEW.club_id` preservando a ergonomia "só faz insert, o número vem sozinho" — a RPC não precisaria mudar seu INSERT).

Isso é exatamente uma "mudança de assinatura que amplia o escopo" — schema novo + trigger novo, não uma correção pontual. **Não implementado, não migrado, aguardando decisão separada.** A uniqueness global (`UNIQUE(order_number)`) permanece correta e não seria alterada por esse design — só a geração/prefixo passaria a respeitar o clube.

`GOIAS_ORDER_PREFIX_HARDCODES`: 2 → **1** (só o SQL, deliberadamente).

## 6. Notifications — `notifications-dispatch` (prioridade crítica)

**Achado**: `fetchRecipientTokens` buscava TODO token ativo do sistema, subtraindo só quem tinha optado por sair GLOBALMENTE (sem filtro de clube) — um evento do clube A seria despachado pra tokens de usuários do clube B. `isActiveMember` também não filtrava por `club_id`.

**Design escolhido** (evita tanto o vazamento quanto uma regressão de produção pros usuários reais do Goiás hoje, que majoritariamente nunca tocaram nas preferências de notificação): um usuário é candidato ao evento do `clubId` se **(a)** tem uma linha de preferência PARA ESSE clube com a coluna do evento habilitada, **OU (b)** nunca configurou preferência em NENHUM clube ainda (usuário legado/novo — default continua "notificar", só que agora só pro(s) clube(s) que ele nunca tocou nada). Um usuário que já configurou preferência só de OUTRO clube nunca é elegível por omissão pra este. `user_notification_tokens` continua GLOBAL por design (token físico do aparelho) — não ganhou `club_id`.

**Implementação**: lógica extraída pra `supabase/functions/_shared/recipient_eligibility.ts` (testável sem Deno, mesmo padrão de `notification_message_builder.ts` — 0 import Deno-específico, `RecipientEligibilitySource` como interface de dependência). `notifications-dispatch/index.ts` agora só monta o adapter real (`supabaseRecipientEligibilitySource`) e chama a lógica pura. `isActiveMember` corrigido para `.eq('club_id', clubId)`.

**Testes fabricados** (12 casos, `recipient_eligibility.test.ts`, vitest — nunca dispara FCM real):
- event clubA + user A configurado em clubA → recebe.
- event clubA + user B só configurado em clubB → **NÃO recebe** (o bug corrigido).
- o mesmo user B recebe normalmente o evento do SEU clube (clubB).
- usuário nunca configurado em nenhum clube → recebe por default legado (sem regressão).
- opt-out explícito dentro do próprio clube continua funcionando.
- coluna certa por tipo de evento (`tickets_enabled` vs `matches_enabled`).
- `isActiveMember`: membership de clubB não afeta a checagem de clubA, nem a copy da notificação.
- prova explícita de que nenhum `fetch` real é chamado.

## 7. Worker News/Social

**Escolhida Opção B** (capability-gate + unavailable), não A (dimensionar por clubCode): as integrações (site oficial do Goiás, handles de Instagram/YouTube/TikTok/Facebook/X) não têm nenhum equivalente real pra um clubB sintético — dimensionar de verdade exigiria credenciais/endpoints que não existem. Também é consistente com o modelo real de deploy já confirmado (1 Worker por clube — a "genericização" das rotas de futebol na M3.3 é sobre o FORMATO da URL, não sobre um Worker compartilhado servindo múltiplos clubes).

**Design**: novo `resolveRequestedClubCode(request)` + `NEWS_SOCIAL_CONFIGURED_CLUB_CODE = 'goias'` em `club_server_config.ts` (mesmo arquivo do registry de futebol). As 3 rotas (`handleNewsList`, `handleNewsArticle`, `handleSocialFeed`) checam `?club=` (ausente = compat, igual sempre foi) ANTES de qualquer fetch/cache — um `clubCode` diferente do único integrado devolve `{items: [], available: false}`/`{available: false, url: null}`/`{posts: [], available: false}` com HTTP 404, nunca o conteúdo do Goiás. Reusa o mesmo contrato `available: false` que `NewsArticleResult` já tinha (nada novo pro Flutter consumir, se algum dia precisar).

**Testes**: `club_server_config.test.ts` (+3, prova o resolver) + novo `club_gate_handlers.test.ts` (+5, chama os 3 handlers de verdade com `?club=club-b` e confirma 404/unavailable, sem precisar mockar fetch/KV — o gate retorna antes de qualquer I/O).

## 8. `ClubCapabilities` — não ampliado nesta rodada

Usado só onde já era necessário pra evitar fallback incorreto: `SocialLinksData`/`SocialEmptyState` já degradam graciosamente (lista vazia) quando a integração não existe em `ClubIntegrations` — não precisou de um flag de capability novo pra isso, o próprio contrato de URLs opcionais já resolve. A fiação completa de `ClubCapabilities` (ligar as 6 flags a telas reais) fica pra M4.2, como planejado.

## 9. RLS/Auth — intocado

Confirmado: nenhuma mudança em RLS, nenhum JWT claim, nenhuma coluna `profiles.club_id`. `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true`, `RLS_USER_ISOLATION=true`, `RLS_CLUB_ISOLATION=false` continuam exatamente como estavam.

## 10. Passaporte — só o bug pontual

`passport_match_ticket_v2.dart` corrigido (§4). As 12 RPCs, o schema (sem `club_id`), e a ACL aberta (`PUBLIC`/`anon`/`service_role`) **não foram tocados**. `PASSPORT_TENANCY_DEFERRED=true` inalterado.

## 11. Synthetic tests — `syntheticClubBConfig` fortalecido

Reescrito para **não reaproveitar mais nada** do Goiás (branding/assets/integrations/productNames/capabilities todos com valores próprios, distintos) — a versão anterior (M3.1) reaproveitava tudo exceto identidade, o que nunca provaria um bypass como os encontrados nesta auditoria (os dois "clubes" pareceriam idênticos mesmo com o bug presente). Continua **nunca registrado em `clubRegistry`** (confirmado por teste já existente).

Novo `test/core/club/m4_1_critical_leakage_test.dart` (13 testes) prova exatamente as asserções pedidas: branding difere, todo asset difere (e nenhum path contém "goias"), `identity.displayName`/`productNames`/`orderPrefix` diferem, `PickupInformation.forActiveClub()` lê do clube ativo via GetIt, o clube sintético não tem NENHUMA rede social configurada (prova o caminho "indisponível", não fallback), `hasPassport=false` só no sintético.

## 12. Tooling

`tooling/multiclub/audit_m4_critical_club_leakage.mjs` + `test_m4_critical_club_leakage.mjs` (18 testes). **Achado e corrigido durante a escrita do tooling**: um bug real no próprio checker — o pathspec `'lib/**/*.dart'` passado pro `git grep` não confere arquivos direto em `lib/` (sem subpasta), como `lib/main.dart` — silenciosamente fazia `clubBrandingConsumers` contar 0 em vez de 1. Corrigido pra `'lib/'` (pathspec de diretório, recursivo) neste script E no `audit_second_club_product_readiness.mjs` (mesma rodada anterior tinha o mesmo bug, sem impacto nos números finais reportados naquela rodada por coincidência, mas corrigido por consistência).

Métricas: `clubAssetRuntimeHardcodes=[]`, `clubBrandingConsumers=1`, `productNamingConsumers=0`, `configBypassesRemaining=0`, `goiasOrderPrefixHardcodes=1`, `notificationDispatchClubScoped=true`, `notificationMembershipLookupClubScoped=true`, `workerNewsCrossClubFallback=false`, `workerSocialCrossClubFallback=false`, `syntheticClubLeaksGoiasIdentity=false`, `m4CriticalLeakageReady=true`.

## 13. Regressões causadas e corrigidas nesta própria rodada

**35 testes Flutter quebraram e foram corrigidos** — 2 causas, ambas do padrão já conhecido deste projeto:

1. `AppTheme.light`/`.dark` viraram métodos (antes eram getters) — 25 ocorrências em 17 arquivos de teste chamavam `AppTheme.light`/`.dark` como valor (tear-off), precisaram virar `AppTheme.light()`/`.dark()`.
2. **9 arquivos de teste** renderizavam (direta ou transitivamente) um widget que passou a chamar `sl<ClubConfig>()` — nenhum deles tinha `ClubConfig` registrado no GetIt. Corrigido adicionando `sl.registerSingleton<ClubConfig>(goiasClubConfig)` em cada `setUp`, mesmo padrão já estabelecido desde a M3.3 pro `ClubBadge`.

**3 testes JS de rodadas anteriores quebraram e foram corrigidos** — mesmo padrão de supersessão já usado neste projeto (M2.2A/M3.1/M3.2/M3.3): `test_multiclub_foundation.mjs` (M1) e `test_multiclub_runtime_hardcodes.mjs` (M3.3) tinham achados que a M4.1 corrigiu de verdade (`main.dart` title, `passport_match_ticket_v2.dart` isGoias) — marcados `fixedInEtapa: 'M4.1'`, nunca deletados, mantidos como registro histórico. `test_second_club_product_readiness.mjs` (M4 round 1) tinha uma asserção que a M4.1 tornou obsoleta (`hasGoiPrefixInFlutter`) — atualizada com nota de supersessão apontando pro teste real desta rodada.

## Gates

```
flutter analyze: 0 issues
flutter test: 908 passed, 1 skip (896 + 12 novos, 35 corrigidos, 0 falhando)
JS (tooling/**/test_*.mjs): 840 passando, 0 falhando (822 + 18 novos)
Worker (npm run test:worker): 119 passando, 0 falhando (111 + 8 novos)
tsc --noEmit: 0 erros
DB: 57/57 (inalterado — 0 db push nesta rodada)
```

---

## Estados

`M4_CRITICAL_LEAKAGE_READY=true` · `SECOND_CLUB_TECHNICALLY_SAFE` continua `false` no snapshot da auditoria anterior (não recalculado automaticamente — `ClubCapabilities`/flavors/RLS/schema institucional seguem pendentes, nenhum bloqueador restante é dos 3 achados críticos desta rodada) · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` (inalterado) · `PASSPORT_TENANCY_DEFERRED=true` (inalterado) · `FLAVOR_PIPELINE_IMPLEMENTED=false` (inalterado, fora de escopo desta rodada por instrução explícita).

---

**PARE (histórico da 1ª entrega — ver correção no topo do documento).** Não iniciar flavors. Não cadastrar segundo clube. Design do prefixo `GOI-` no SQL apresentado, não aplicado — aguardando decisão separada. Nenhum commit feito nesta rodada (não solicitado). `0 db push`, `0 Edge deploy`, `0 git push`.

---

# M4.1b — Notification Token Ownership Audit

Data: 2026-09-03 (mesmo dia, antes de qualquer Edge deploy/db push/git push da M4.1).

## 1. Schema real (4 tabelas, live)

**`user_notification_tokens`**: `id uuid PK`, `user_id uuid FK→auth.users(id) ON DELETE CASCADE`, `fcm_token text UNIQUE`, `platform text CHECK IN ('android','ios')`, `is_active boolean`, `last_seen_at timestamptz`, `created_at timestamptz`. **Nenhuma coluna de clube.** RLS: 4 policies, todas `auth.uid() = user_id` (padrão de isolamento de usuário, igual toda outra tabela do projeto — nada específico de clube).

**`user_notification_preferences`**: já tem `club_id uuid NOT NULL` (confirmado, base da correção da M4.1 original).

**`notification_events`**: já tem `club_id uuid NOT NULL` (M3.3).

**`notification_deliveries`**: `id`, `event_id FK`, `token_id FK`, `status`, `fcm_message_id`, `error`, `attempted_at`, `created_at` — **sem `club_id` própria**, e está correto ser assim: é uma tabela de junção (`event_id` × `token_id`), herda escopo transitivamente das duas FKs — não precisa de coluna própria, precisa é que o INSERT só junte linhas cujo `event.club_id` bata com o `token.club_id` (hoje impossível de garantir, porque `token.club_id` não existe).

**Token registration path**: `PushNotificationService._initialize()` → `messaging.getToken()` (SDK Firebase) → `_registerToken(token)` → `repository.registerToken(fcmToken, platform)` → `upsert` em `user_notification_tokens` com `onConflict: 'fcm_token'`. Nenhum `club_id` enviado — a classe nem recebe `ClubConfig` injetado hoje.

**Refresh**: `messaging.onTokenRefresh.listen(_registerToken)` — mesmo caminho, cada token novo faz upsert.

**Deactivate**: no logout, `_teardown()` → `repository.deactivateToken(token)` → `update is_active=false where fcm_token=X and user_id=Y`.

**Dispatch lookup**: hoje (`RecipientEligibilitySource.activeTokens()`) busca `select id,user_id,fcm_token,platform from user_notification_tokens where is_active=true` — sem filtro de usuário elegível (isso é aplicado depois, em memória, no `.filter()`) e **sem filtro de clube algum, porque a coluna não existe**.

## 2. Significado real de um token FCM neste projeto

**Resposta: C, refinada por D** — um token representa uma **instalação de app** (mais precisamente: a combinação Firebase App ID, que é 1:1 com o `package_name`/`bundle_id`, + a instância física do app instalado). Não é "usuário global" nem "aparelho global" — é o SDK do Firebase, inicializado com a config específica do app (`google-services.json`/`GoogleService-Info.plist`), que gera um token único pra aquela instalação.

Confirmado ao vivo, sem expor segredos: `android/app/google-services.json` tem **exatamente 1 client entry**, `package_name: "br.com.goiasec.goias_app"`, `project_id: "goias-app-4ef7e"`. `ios/Runner/GoogleService-Info.plist` tem `BUNDLE_ID: br.com.goiasec.goiasApp`. Ou seja: hoje só existe 1 "app" Firebase registrado — todo token gerado é inerentemente desse 1 app.

## 3. Cenário same-user/two-flavors, modelado explicitamente

```
mesmo user_id (Supabase Auth, global)
├── app Goiás (package br.com.goiasec.goias_app) → token A
└── app clubB (package hipotético br.com.goiasec.clubb_app) → token B
```

O Firebase **garante** que A ≠ B (tokens são escopados por app installation — nunca dois apps diferentes, mesmo do mesmo Firebase project, recebem o mesmo token). Isso responde ao "cenário obrigatório" do pedido: hoje, com 0 flavors, esse cenário é IMPOSSÍVEL de ocorrer de verdade (só existe 1 app instalável) — mas o exemplo do dono ("user X, token-goias, 0 preferences, event clubB → elegível por default legado → token-goias pode receber clubB") é **tecnicamente possível hoje mesmo, sem precisar de um 2º flavor**: basta um evento de teste com `club_id` diferente de Goiás ser processado pelo dispatch atual — o token de X seria buscado (`is_active=true`, sem filtro de clube) e uma mensagem seria enviada. A elegibilidade por usuário (M4.1) não impede isso sozinha.

## 4. Onde o banco sabe que token A é Goiás e token B é clubB?

**Em lugar nenhum.** Confirmado — `user_notification_tokens` não tem coluna de clube, código nenhum grava isso. **Registrado como blocker real**: `NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=false`.

## 5. Reavaliação do `GLOBAL_BY_DESIGN`

A decisão original (M3.2: "token FCM é do aparelho, não do clube, nunca ganha `club_id`") fazia sentido num mundo de 1 app só — mover a decisão pra "global por design" era estritamente correto porque não havia com o que confundir. Essa premissa **não se sustenta mais** no desenho de vários flavors: o token não deixa de ser "do aparelho" (continua sendo — o mesmo aparelho físico pode ter N tokens, um por app instalado), mas cada token individual passa a estar amarrado a UM clube específico (o app que o gerou). A tabela precisa de uma dimensão de clube — **não é mais só "global", é "por instalação", e cada instalação é de um clube só.**

## 6. Firebase — projeto único ou múltiplos?

Confirmado ao vivo (sem expor credenciais): **1 Firebase project (`goias-app-4ef7e`), 1 app registrado (`br.com.goiasec.goias_app`)**. Não há evidência de decisão tomada sobre se um futuro clubB usaria o MESMO Firebase project (com um 2º "app" registrado nele, cada um com seu próprio `package_name`) ou um projeto Firebase totalmente separado. **Tecnicamente não muda a resposta desta auditoria**: em qualquer um dos dois casos, cada app (`package_name`/`bundle_id`) tem seu próprio conjunto de tokens, nunca compartilhados — a diferença entre "mesmo projeto, 2 apps" vs "2 projetos" é operacional (quantas service accounts o Edge precisa gerenciar), não afeta o modelo de dados de `user_notification_tokens`.

## 7. Avaliação A/B/C/D

| Opção | Avaliação |
|---|---|
| **A — `club_id` direto em `user_notification_tokens`** | **Recomendada.** Um token é 1:1 com uma instalação, uma instalação é 1:1 com um clube (sob o modelo `APP_CLUB` já existente) — a relação token→clube é estritamente 1:1, não muitos-pra-muitos. Uma coluna simples resolve, é a extensão natural da mesma tabela que já é escrita a cada registro. |
| **B — join table `user_notification_token_clubs`** | Rejeitada — resolveria uma relação muitos-pra-muitos que não existe aqui (um token nunca pertence a 2 clubes ao mesmo tempo). Complexidade sem benefício. |
| **C — outro identificador de app/flavor** | O Firebase SDK não devolve o `package_name`/`bundle_id` pro backend junto com o token — só o app cliente sabe disso (via `ClubConfig` já existente). Então "C" na prática se resolve enviando o `club_id` explicitamente no registro (que é exatamente o que a Opção A propõe) — não é uma alternativa independente, é a mesma solução vista de outro ângulo. |
| **D — manter global** | Rejeitada explicitamente — não existe prova técnica de que um token de um flavor não possa receber mensagem destinada a outro; pelo contrário, o código atual demonstravelmente enviaria pra qualquer token ativo do usuário, sem checagem nenhuma. |

## 8. Design proposto (NÃO implementado — PARE, decisão de schema)

```sql
-- supabase/migrations/<data>_add_club_id_to_notification_tokens.sql (PROPOSTO, NÃO CRIADO)
--
-- guard clubs=1+goias (mesmo padrão de toda migration deste projeto)
--
alter table public.user_notification_tokens
  add column club_id uuid not null
    default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
    references public.clubs(id);
```

**Por que `NOT NULL DEFAULT <goias>` e não nullable + backfill em 2 passos**: hoje existem exatamente **2 linhas** na tabela (2 usuários, 2 tokens ativos, confirmado ao vivo) — **100% inequivocamente Goiás**, sem nenhuma ambiguidade (não existe outro clube pra confundir). Um `DEFAULT` transitório aqui é seguro e seria, de qualquer forma, imediatamente redundante pra escritas NOVAS, já que o path de registro (`PushNotificationService`/`SupabaseNotificationRepository.registerToken`) passaria a enviar `club_id` explícito (precisaria de `ClubConfig` injetado em `PushNotificationService`, hoje ausente).

**Mudanças de código necessárias (design, não implementadas)**: `PushNotificationService` ganha `ClubConfig` no construtor; `NotificationRepository.registerToken`/`SupabaseNotificationRepository` passam `club_id: _clubConfig.identity.canonicalClubId` no upsert; `RecipientEligibilitySource.activeTokens()` ganha um parâmetro `clubId` e filtra `.eq('club_id', clubId)`.

**Efeito colateral importante**: uma vez que o token carregue `club_id`, o "default legado" da elegibilidade por usuário (§7 do pedido) **deixa de ser um risco real por si só** — mesmo um usuário "elegível por omissão" (nunca configurou preferência em nenhum clube) só teria um token daquele clube específico SE realmente tiver instalado o app daquele clube alguma vez (é fisicamente impossível ter um token de clubB sem ter rodado o app de clubB). A entrega real passaria a exigir a INTERSEÇÃO de "usuário elegível" (checagem existente) × "token pertence a este clube" (checagem nova) — as duas continuam necessárias e complementares (a de usuário cobre opt-out dentro do próprio clube; a de token impede vazamento entre clubes), mas a combinação das duas fecha o buraco sem precisar de nenhum backfill de preferências.

## 9. Necessidade de migration

**Sim, 1 migration pequena e não-destrutiva** (`ALTER TABLE ADD COLUMN ... DEFAULT ... REFERENCES`) — design acima, **não criada, não aplicada**. Zero DDL destrutivo, zero DML manual (o `DEFAULT` cobre o backfill das 2 linhas existentes automaticamente).

## 10. Impacto em usuários Goiás atuais

**Nenhum, com o design acima**: os 2 tokens reais existentes recebem `club_id=goias` automaticamente via `DEFAULT`, nenhuma notificação para de funcionar, nenhuma ação manual necessária. O único código que precisaria mudar é o de registro (`PushNotificationService`) — e mesmo sem essa mudança de código, o `DEFAULT` garantiria que registros futuros CONTINUARIAM sendo tratados como Goiás (comportamento idêntico ao de hoje) até que o código de registro seja atualizado pra enviar o valor explícito.

## 11. Métricas novas (tooling)

`audit_m4_critical_club_leakage.mjs` atualizado: `notificationUserEligibilityClubScoped`, `notificationTokenDeliveryClubScoped`, `notificationMulticlubModelReady`, `storeSafeForClubB`, `m4_1ImplementationLocalComplete` — nunca mascarados numa métrica só. 6 testes novos em `test_m4_critical_club_leakage.mjs` (24 no total agora), incluindo 2 fabricados provando que `notificationTokenDeliveryClubScoped` sozinho derruba `m4CriticalLeakageReady` mesmo com tudo mais `true`.

## 12-15. Estados finais desta auditoria

```
NOTIFICATION_USER_ELIGIBILITY_CLUB_SCOPED=true
NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=false
NOTIFICATION_MULTICLUB_MODEL_READY=false
M4_1_IMPLEMENTATION_LOCAL_COMPLETE=true
M4_CRITICAL_LEAKAGE_READY=false
STORE_SAFE_FOR_CLUB_B=false
```

---

**PARE (histórico da M4.1b — ver M4.1c abaixo, mesmo dia).** Auditoria completa, design da migration apresentado e não aplicado. `0 Edge deploy`, `0 db push`, `0 git push`, `0 migration criada`, `0 flavor`, `0 clubB`. Aguardando autorização separada pra criar/aplicar a migration de `user_notification_tokens.club_id` e atualizar o path de registro.

---

# M4.1c — Notification Token Club Ownership

Data: 2026-09-03 (mesmo dia, implementação do design da M4.1b). Status: **migration local + Flutter + Edge + testes prontos. `0 db push`, `0 Edge deploy`, `0 git push`.**

## 1. Migration

`supabase/migrations/20260903160000_add_club_id_to_notification_tokens.sql` (criada, **não aplicada**):

```sql
alter table public.user_notification_tokens
  add column club_id uuid
    references public.clubs(id)
    default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;

alter table public.user_notification_tokens
  alter column club_id set not null;

alter table public.user_notification_tokens
  alter column club_id drop default;
```

`fcm_token` continua a **única** chave de unicidade — nada mudou nela, `club_id` nunca entra na chave.

## 2. Estratégia de backfill

`ADD COLUMN ... DEFAULT <goias>` já faz o backfill das linhas existentes automaticamente (Postgres aplica o default a toda linha já existente no momento do `ALTER`) — não precisou de um `UPDATE` manual separado.

## 3. Decisão sobre o DEFAULT

**Seguida a preferência explícita do dono**: `SET NOT NULL` → `DROP DEFAULT`. Nenhum `DEFAULT` residual fica pra trás — toda escrita nova precisa mandar `club_id` explícito ou falha alto (`NOT NULL` sem `DEFAULT`), mesmo espírito de não recriar o padrão transitório que a M2.2B-B acabou de remover do resto do schema.

## 4. Flutter registration

**Decisão de design, divergindo levemente da literalidade do pedido — sinalizada aqui**: em vez de injetar `ClubConfig` em `PushNotificationService` (que nunca constrói o payload sozinho, só delega pra `_repository.registerToken(...)`), o `club_id` foi adicionado dentro de `SupabaseNotificationRepository.registerToken`, usando o `_clubConfig`/`_clubId` que a classe **já tinha injetado** (mesmo padrão usado por `updatePreferences`, que já fazia isso). Resultado idêntico ao pedido (registro manda `club_id = active ClubConfig.identity.canonicalClubId`), só que sem duplicar a fonte da verdade em 2 lugares (`PushNotificationService` E o repository) — mais consistente com as outras ~10 repositories deste projeto, que sempre resolvem `club_id` internamente, nunca no call site.

## 5. Refresh

`onTokenRefresh.listen(_registerToken)` reusa o mesmíssimo caminho de `registerToken` — herda a correção automaticamente, 0 código extra necessário.

## 6. Upsert

`onConflict: 'fcm_token'` preservado. O mapa upsertado agora inclui `club_id` junto de `user_id`/`platform`/`is_active`/`last_seen_at` — um upsert por PostgREST atualiza TODAS as colunas do mapa em caso de conflito (não é `ignoreDuplicates`), então o `UPDATE` provocado por um refresh atualiza `club_id` corretamente se o clube ativo daquela instalação mudar.

## 7. Dispatch filtering

`_shared/recipient_eligibility.ts`: `activeTokens()` → `activeTokensForClub(clubId)`, filtra `.eq('club_id', clubId)` na query real. `notifications-dispatch/index.ts` atualizado (adapter + join select do `processEvent` também passam a trazer `club_id`). Resultado: `event.club_id → eligible users (camada 1, M4.1) × user_notification_tokens WHERE club_id = event.club_id (camada 2, M4.1c)` — nunca mais "todos os tokens globais do usuário".

## 8. Token counts live (antes da migration)

Confirmado ao vivo: **2 tokens, 2 usuários distintos, ambos `is_active=true`, ambos `android`**, criados em 2026-09-01 — **100% inequivocamente Goiás**, nenhuma ambiguidade. Sem esse resultado, a migration teria sido interrompida (PARE, sem backfill automático) — não foi necessário.

## 9. Impacto em RLS

**Nenhuma mudança.** As 4 policies existentes (`insert/read/update/delete own tokens`, todas `auth.uid() = user_id`) continuam corretas e suficientes — a visibilidade de uma linha por um usuário nunca dependeu de `club_id`, só de ser dona da linha. Adicionar `club_id` à policy não mudaria nenhum comportamento de isolamento (um usuário já só vê as próprias linhas, com ou sem checagem de clube) — seria uma mudança sem efeito prático, então não foi feita. Isto **não é** a etapa de redesenho de `AUTH_SCOPE` multi-clube (que continua bloqueada/fora de escopo, como antes).

## 10. Testes

**TypeScript** (`recipient_eligibility.test.ts`, 14 testes, +6 desde a M4.1b): os 2 cenários obrigatórios do pedido — mesmo `user_id`, `token-goias` (`club_id=clubA`) + `token-clubb` (`club_id=clubB`) — `event clubA` só retorna `token-goias`, `event clubB` só retorna `token-clubb`; `0 preferences` em nenhum clube continua elegível por default legado, mas só dentro do `club_id` do token que existe; teste fabricado com uma fonte quebrada (que ignora `clubId`, reproduzindo o bug da M4.1b) provando que É a filtragem de `activeTokensForClub` que impede o vazamento, não algo em `fetchRecipientTokens`.

**Dart** (`club_scoped_user_state_test.dart`, +4 testes, técnica `CapturingHttpClient` já estabelecida no projeto — captura o payload HTTP real, não confia só em "não lançou"): `registerToken` grava `club_id` do clube ativo pra Goiás E pro `syntheticClubBConfig`; "refresh" simulado (2ª chamada de `registerToken` com clube diferente) atualiza `club_id` corretamente; `on_conflict=fcm_token` confirmado na URL real, nunca `club_id` na chave de conflito.

## 11-14. Flutter analyze / Flutter tests / JS / Edge tests

Ver Gates abaixo.

## 15. Dry-run

```
npx supabase migration list -> 58 local / 57 remote / 1 pending
npx supabase db push --dry-run -> 20260903160000_add_club_id_to_notification_tokens.sql
```

Exatamente a migration desta rodada, nada mais.

## Gates

```
flutter analyze: 0 issues
flutter test: 912 passed, 1 skip (908 + 4 novos)
JS (tooling/**/test_*.mjs): 851 passando, 0 falhando (846 + ~5 líquidos: testes trocados/adicionados na seção 6/10 do M4.1 tooling)
Worker (npm run test:worker, inclui Edge): 121 passando, 0 falhando (119 + 2 líquidos: testes trocados/adicionados em recipient_eligibility.test.ts)
tsc --noEmit: 0 erros
DB: 58 local / 57 remote / 1 pending (migration criada, NÃO aplicada — 0 db push)
```

## Estados finais

```
NOTIFICATION_USER_ELIGIBILITY_CLUB_SCOPED=true
NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=true
NOTIFICATION_MULTICLUB_MODEL_READY=true
NOTIFICATION_SCHEMA_APPLIED_LIVE=false
M4_CRITICAL_LEAKAGE_READY=true
```

---

**PARE (histórico da 1ª versão da M4.1c — ver M4.1c-A abaixo, mesmo dia, corrigida ANTES de qualquer `db push`).** `0 db push`, `0 Edge deploy`, `0 git push`, `0 flavor`, `0 clubB real`. O código está pronto e testado — a produção continua exatamente como estava até uma autorização separada pra aplicar a migration e fazer o deploy da Edge Function.

---

# M4.1c-A — Rollout Compatibility Fix

Data: 2026-09-03 (mesmo dia). Status: **migration A corrigida (mantém `DEFAULT`), migration B projetada (não criada como arquivo), dry-run confirmado. `0 db push`, `0 Edge deploy`, `0 git push`.**

## 1. Migration A corrigida

`supabase/migrations/20260903160000_add_club_id_to_notification_tokens.sql` (reescrita):

```sql
alter table public.user_notification_tokens
  add column club_id uuid
    references public.clubs(id)
    default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;

alter table public.user_notification_tokens
  alter column club_id set not null;

-- DEFAULT MANTIDO DE PROPÓSITO — não remover aqui. Compatibilidade com o
-- runtime 1.0.1+2 em produção, que ainda não manda club_id.
```

Removido: o `alter column club_id drop default;` que estava na 1ª versão. Tudo o mais (guard `clubs=1+goias`, `fcm_token` como única chave, comentários explicando o modelo token↔clube) permanece igual.

## 2. Migration B planejada (NÃO criada como arquivo)

```sql
-- PLANEJADA — supabase/migrations/<data futura>_drop_default_notification_tokens_club_id.sql
-- Só criar/aplicar depois que o rollout do runtime novo estiver confirmado.
alter table public.user_notification_tokens
  alter column club_id drop default;
```

**Decisão deliberada**: não criada como arquivo real em `supabase/migrations/` nesta rodada — se fosse, apareceria como "pending" no MESMO `db push`/dry-run da migration A, o que criaria ambiguidade sobre o que seria de fato aplicado agora. Fica documentada aqui (e no tooling, como um path planejado que o audit confirma NÃO existir como arquivo ainda) até a condição de aplicação ser satisfeita.

## 3. Confirmação de compatibilidade com `1.0.1+2`

Verificado o comportamento do `upsert(onConflict: 'fcm_token')` que o cliente `1.0.1+2` continua chamando (sem `club_id` no payload):

- **Token novo (INSERT)**: o cliente antigo não lista `club_id` no payload → Postgres aplica o `DEFAULT` (Goiás) pra essa coluna → linha gravada com `club_id=goias`, sem erro.
- **Token já existente (UPDATE via `ON CONFLICT DO UPDATE`)**: o PostgREST só inclui, no `SET`, as colunas que vieram no payload do cliente — como o cliente antigo nunca manda `club_id`, o `UPDATE` gerado não toca essa coluna, preservando o valor já populado pelo backfill. Sem erro, sem sobrescrita incorreta.

**Confirmado: migration A é 100% compatível com o runtime `1.0.1+2` em produção**, nos dois caminhos (insert e update).

## 4. Dry-run

```
npx supabase migration list -> 58 local / 57 remote / 1 pending
npx supabase db push --dry-run -> 20260903160000_add_club_id_to_notification_tokens.sql
```

Exatamente 1 migration pendente (a A, corrigida) — a B não aparece, porque não é um arquivo.

## 5. Tooling

`audit_m4_critical_club_leakage.mjs` atualizado: `migration.keepsDefaultForRolloutCompat` (novo, substitui o antigo `dropsDefault` — agora checa a AUSÊNCIA de `DROP DEFAULT`, nunca a presença), `migrationB.createdAsFileYet` (confirma que o path planejado da B não existe como arquivo), e os 3 novos estados de fase de rollout. 6 testes novos em `test_m4_critical_club_leakage.mjs` (32 no total), incluindo um fabricado que reproduz o texto exato do bug de rollout (`DROP DEFAULT` na mesma migration) pra provar que o checker o pegaria se reintroduzido.

## 6. Ordem de rollout recomendada (registrada, não executada)

```
1. migration A (additive) — pronta, aguardando autorização
2. db push
3. validar backfill dos 2 tokens ao vivo
4. deploy notifications-dispatch
5. validar Edge live
6. preparar/publicar Flutter novo (recomendação: 1.0.2+3 — ver §7)
7. confirmar rollout (PWA + APK redistribuído se necessário)
8. só depois: migration B (DROP DEFAULT)
```

## 7. Sobre o bump de versão

**Não aplicado nesta rodada** — nem `pubspec.yaml` foi tocado. A recomendação do dono (`1.0.2+3`, distinguindo `legacy/current = 1.0.1+2` de `M4.1 runtime = 1.0.2+3`) fica registrada aqui como o valor a usar quando esta etapa virar uma rodada de release de verdade (mesmo padrão já usado na M3.4 — o bump de versão acontece junto com a rodada de release, não isolado antes dela). Nada impede decidir o bump antes, mas como esta rodada é só "migration local + Flutter + Edge + testes + dry-run + PARE", editar `pubspec.yaml` agora seria antecipar uma etapa que tem seu próprio ciclo de autorização (visto nas rodadas M3.4/M2.2B-B: bump de versão sempre junto do PUSH real do release, nunca solto antes).

## Estados finais (substituem os da seção M4.1c original)

```
NOTIFICATION_USER_ELIGIBILITY_CLUB_SCOPED=true
NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=true
NOTIFICATION_MULTICLUB_MODEL_READY=true
NOTIFICATION_SCHEMA_APPLIED_LIVE=false
NOTIFICATION_TOKEN_CLUB_COLUMN_READY=true
NOTIFICATION_TOKEN_CLUB_DEFAULT_TRANSITIONAL=true
NOTIFICATION_TOKEN_DEFAULT_FINAL=false
M4_CRITICAL_LEAKAGE_READY=true
```

---

**PARE.** `0 db push`, `0 Edge deploy`, `0 git push`, `0 flavor`, `0 clubB real`, `0 bump de versão aplicado`. Migration A corrigida e pronta; migration B projetada, não criada. Aguardando autorização separada pra aplicar a migration A e iniciar o rollout.

---

# M4.1c-A — Aplicação (server-side rollout)

Data: 2026-09-03. Status: **APLICADO. Migration A ao vivo, `notifications-dispatch` v4 deployada, validado. Flutter/PWA/APK NÃO publicados nesta rodada.**

## 1. Commits locais

`51c9fc0` (`docs(multiclub): audit second club product readiness` — M4 round 1) + `a2276f3` (`feat(multiclub): remove critical club leakage, scope notification tokens by club` — M4.1+M4.1b+M4.1c+M4.1c-A, 73 arquivos). Staged por nome (`git add <arquivo> <arquivo> ...`), nunca `git add .` — confirmado via `git status` antes e depois que as exclusões-padrão (`store_entry_card.dart`, `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md`) e o trabalho não-relacionado ainda em andamento (Rodada 3 do gate de retirada pós-rollout, `docs/multiclub/39_post_rollout_legacy_retirement_gate.md` + tooling correspondente) permaneceram fora, intocados.

## 2. Preflight

```
npx supabase migration list -> 58 local / 57 remote / 1 pending (20260903160000)
npx supabase db push --dry-run -> só 20260903160000_add_club_id_to_notification_tokens.sql
```
Exatamente como esperado.

## 3. `db push`

```
npx supabase db push
Applying migration 20260903160000_add_club_id_to_notification_tokens.sql...
Finished supabase db push.
```

## 4. DB pós-push

`npx supabase migration list` → **58 local / 58 remote, 0 pending.**

## 5. Schema ao vivo

```sql
column_name=club_id, data_type=uuid, is_nullable=NO,
column_default='4c16340d-300c-5ab2-903f-17519db9b146'::uuid
```
`NOT NULL=true`, `DEFAULT` Goiás presente, confirmado via `information_schema.columns`.

## 6. Backfill dos tokens existentes

```sql
total=2, null_club_id=0, goias_club_id=2, distinct_tokens=2
```
2/2 tokens com `club_id=Goiás`, 0 nulo, 0 token perdido (2 distintos = 2 total, sem duplicação).

## 7. `DEFAULT` transicional

Confirmado via `pg_constraint`: `user_notification_tokens_club_id_fkey` (FK → `clubs(id)`), `user_notification_tokens_fcm_token_key` (`UNIQUE(fcm_token)`, sozinho, inalterado) — nenhum `DROP DEFAULT` executado. `NOTIFICATION_TOKEN_CLUB_DEFAULT_TRANSITIONAL=true` confirmado ao vivo, não só no arquivo da migration.

## 8. Edge deploy

```
npx supabase functions deploy notifications-dispatch
Uploading asset: notifications-dispatch/index.ts
Uploading asset: _shared/recipient_eligibility.ts
Uploading asset: _shared/notification_message_builder.ts
Uploading asset: _shared/club_server_config.ts
Deployed Functions: ["notifications-dispatch"]
```
Só esta função foi deployada — confirmado via `functions list` pós-deploy que `delete-account`/`notifications-sync-and-check-access`/`notifications-poll-live-match`/`cleanup-unconfirmed-signups` mantiveram seus `updated_at` antigos, intocados.

## 9. Versão da Edge

`notifications-dispatch`: v3 → **v4**, `updated_at=2026-09-03T14:56:13.226Z`.

## 10. Validação live (sem disparar FCM real)

Sem comando `functions logs` disponível nesta versão do CLI (`supabase functions --help` não lista `logs`) — validação feita por revisão estrutural do CÓDIGO REALMENTE ENVIADO (os mesmos 2 arquivos do passo 8, relidos após o deploy, não uma cópia local presumida):
- **event eligibility = club scoped**: `explicitlyEligibleUserIds(clubId, ...)` → `.eq('club_id', clubId)` em `user_notification_preferences`.
- **token lookup = club scoped**: `activeTokensForClub(clubId)` → `.eq('club_id', clubId)` em `user_notification_tokens`.
- **membership lookup = club scoped**: `activeMembershipCount(userId, clubId)` → `.eq('club_id', clubId)` em `supporter_memberships`.

Nenhum evento de teste foi criado, nenhuma mensagem FCM foi disparada.

## 11. Compatibilidade `1.0.1+2` — reconfirmada

Estrutural (semântica padrão do Postgres/PostgREST, não uma escrita de teste na tabela de produção): INSERT sem `club_id` no payload → coluna cai no `DEFAULT` (Goiás); `UPDATE` via `ON CONFLICT DO UPDATE` só toca as colunas presentes no payload do cliente — um cliente `1.0.1+2` (que nunca manda `club_id`) nunca sobrescreve o `club_id` já populado. Ambos os caminhos confirmados sem erro possível dado o schema real (passo 5-7).

## Gates

```
flutter analyze: 0 issues
flutter test: 912 passed, 1 skip, 0 failed
tooling/multiclub/test_*.mjs: 854 passando, 0 falhando
npm run test:worker (inclui Edge): 121 passando, 0 falhando (16 arquivos)
tsc --noEmit: 0 erros
```

## Estados finais

```
NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=true
NOTIFICATION_MULTICLUB_MODEL_READY=true
NOTIFICATION_SCHEMA_APPLIED_LIVE=true
NOTIFICATION_EDGE_DEPLOYED_LIVE=true
NOTIFICATION_TOKEN_CLUB_DEFAULT_TRANSITIONAL=true
NOTIFICATION_TOKEN_DEFAULT_FINAL=false
M4_CRITICAL_LEAKAGE_READY=true
```

## Git

`git status` limpo quanto a este trabalho — só sobram as exclusões-padrão e a Rodada 3 (não relacionada) do gate de retirada pós-rollout, não tocadas. **0 `git push`.**

---

**PARE.** `0 bump de pubspec`, `0 release PWA`, `0 release APK`, `0 migration B` (`DROP DEFAULT`, projetada não criada), `0 M4.2`, `0 flavor`, `0 clubB real`, `0 git push`. Server-side pronto e validado; o runtime Flutter que manda `club_id` explícito no registro ainda não foi publicado — até lá, o `DEFAULT` transicional continua sendo a rede de segurança real.

---

# M4.1 — Runtime Release 1.0.2+3

Data: 2026-09-03. Status: **PWA publicado e validado em produção. APK falhou nesta sessão (mesmo erro de ambiente já documentado, Gradle) — deixado pro terminal do dono.**

## 1. Version bump

`pubspec.yaml`: `1.0.1+2` → **`1.0.2+3`**. Nenhuma outra mudança de runtime oportunista. Nenhum teste precisou de ajuste — os 2 arquivos que citam `1.0.1+2` (`release_gate_test.dart`, `app_version_comparator_test.dart`) são cenários fixos históricos ("release M3.4 real"), não leem `pubspec.yaml` dinamicamente.

## 2. Gates

```
flutter analyze: 0 issues
flutter test: 912 passed, 1 skip, 0 failed
tooling/multiclub/test_*.mjs: 854 passando, 0 falhando
npm run test:worker: 121 passando, 0 falhando
tsc --noEmit: 0 erros
flutter build web --release: sucesso
build/web/version.json: {"version":"1.0.2","build_number":"3"}
```
Todos batendo com o baseline esperado.

## 3. Commit do bump

`0efe7a5` (`chore(release): bump app version to 1.0.2+3`) — só `pubspec.yaml`, `git add pubspec.yaml` nomeado.

## 4. Pre-push

`git fetch origin` encontrou 1 commit novo em `origin/main` (`c110a1c "Update X posts feed"`, bot `github-actions[bot]`, só `src/social/data/x_posts.json`, 0 sobreposição com qualquer arquivo desta etapa). Merge controlado (`git merge origin/main --no-edit`, sem rebase, sem force) — **0 conflito**. Merge commit `858fe19`.

## 5. `git push`

```
git push origin main
c110a1c..858fe19  main -> main
```

## 6. Produção — validado ao vivo

```
GET /                          -> 200
GET /version.json              -> {"version":"1.0.2","build_number":"3"}  (após ~1min20s de propagação do build Cloudflare)
GET /flutter_service_worker.js -> 200
GET /api/football/team/goias   -> 200
GET /api/football/team/club-b  -> 404
GET /api/news?club=club-b      -> 404, {"items":[],"available":false}
GET /api/news (compat)         -> 200, conteúdo real do Goiás confirmado
GET /api/social/feed?club=club-b -> 404, {"posts":[],"available":false}
```
Nunca vazou conteúdo do Goiás pro `club-b` sintético em nenhuma das 2 rotas — confirmado com o corpo da resposta, não só o status code.

## 7. APK

`flutter build apk --release` falhou nesta sessão com o MESMO erro já documentado na Rodada 2 do gate de retirada pós-rollout (`java.io.IOException: Unable to establish loopback connection`, Gradle 9.1/JDK 17, problema de ambiente desta sessão específica — não do projeto/código). Conforme instrução explícita: **JDK/Gradle não foram tocados**. Build do APK `1.0.2+3` fica pro terminal do próprio dono (mesmo padrão que gerou com sucesso o `1.0.1+2` antes). Envio continua manual, só pras ~3 pessoas já usando os builds internos — nunca Play Store/App Store.

## 8. `DEFAULT` transicional — inalterado

`NOTIFICATION_TOKEN_CLUB_DEFAULT_TRANSITIONAL=true` continua. **0 migration B criada/aplicada** nesta rodada — só depois que o dono confirmar a entrega do APK `1.0.2+3` às ~3 pessoas.

## Estados finais

```
M4_1_RUNTIME_WEB_RELEASED=true
NOTIFICATION_TOKEN_CLIENT_WRITES_CLUB_ID=true
NOTIFICATION_TOKEN_DEFAULT_FINAL=false
M4_1_RUNTIME_APK_RELEASED=false   (build falhou nesta sessão, ambiente — não código)
```

---

**PARE.** PWA `1.0.2+3` publicado e validado. APK não gerado nesta sessão (erro de ambiente, registrado, não contornado). `0 migration B`, `0 M4.2`, `0 flavor real`, `0 Bragantino`. Aguardando: (1) o dono gerar o APK `1.0.2+3` no próprio terminal, (2) confirmar entrega às ~3 pessoas — só então M4.1c-B (`DROP DEFAULT`) pode ser autorizada.

---

# M4.1c-B — Finalizar Notification Token Club Ownership

Data: 2026-09-03. Autorizada pela confirmação do dono: PWA `1.0.2+3` publicado ✅, APK `1.0.2+3` gerado ✅, entregue às ~3 pessoas ✅.

## 1. Migration B

`supabase/migrations/20260903170000_drop_default_notification_tokens_club_id.sql` (nova):
```sql
alter table public.user_notification_tokens
  alter column club_id drop default;
```
Nada além disso — `club_id NOT NULL`, FK → `clubs(id)`, `fcm_token UNIQUE` (sozinho) preservados, nenhum tocado por este arquivo.

## 2. Preflight live (antes de aplicar)

```
DB = 58/58 (0 pending, antes desta migration existir)
club_id: is_nullable=NO, column_default='<goias-uuid>'::uuid
tokens: total=2, null_club_id=0, invalid_club_id=0
```
Runtime `1.0.2+3` reconfirmado (`lib/features/notifications/data/supabase_notification_repository.dart`): `registerToken` grava `'club_id': _clubId` explicitamente no upsert — já é o código publicado/distribuído, confirmado pelo dono.

## 3. Dry-run

```
npx supabase migration list -> 59 local / 58 remote / 1 pending
npx supabase db push --dry-run -> só 20260903170000_drop_default_notification_tokens_club_id.sql
```

## 4. Tooling — 2 achados corrigidos antes do commit

`audit_m4_critical_club_leakage.mjs`: (a) `migrationDesignCorrect` (migration A) não deveria mais depender de `!migrationBFileExists` — essa era uma guarda temporal só da rodada M4.1c-A, agora migration B existe legitimamente; removida. (b) Nova distinção `notificationSchemaAppliedLive` (A, já aplicada) vs. `notificationSchemaBAppliedLive` (B, ainda não) — `notificationTokenClubDefaultTransitional`/`notificationTokenDefaultFinal` agora exigem a migration DESENHADA CORRETAMENTE **e** aplicada ao vivo, nunca só "o arquivo existe". (c) **Falso-positivo de comentário** (mesma classe já documentada neste projeto): o checker `migrationBTouchesOnlyDefault` batia contra o TEXTO do comentário explicativo da própria migration B ("fcm_token continua a única UNIQUE", "NOT NULL sem DEFAULT"), reprovando uma migration correta — corrigido com `stripSqlComments()` (filtra linhas `--` antes de checar), mesmo padrão de `stripComments` já usado nos scripts de tooling Dart deste projeto. 3 testes antigos que assumiam "migration B não é um arquivo ainda"/"0 db push" foram atualizados (nunca deletados) via nota de supersessão — mesmo padrão de M2.2A/M3.1/M3.2/M4.1. +2 testes fabricados novos (escopo da migration B nunca amplia silenciosamente; o falso-positivo de comentário é reproduzido E provado corrigido). `tooling/multiclub/test_m4_critical_club_leakage.mjs`: **34 testes, 0 falhando** (era 32).

## 5. Commit local antes do `db push`

Staged por nome: migration B, os 2 arquivos de tooling atualizados, o relatório 43 (esta seção). `78be21d` (docs-only, resultado do release 1.0.2+3) preservado na linha do tempo — nenhum hash reescrito/amendado.

## 6. `db push`

Ver §"Aplicação" abaixo.

---

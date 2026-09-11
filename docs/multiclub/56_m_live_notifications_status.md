# M-live — Notificações de partida (6 eventos, multi-clube) — status 2026-09-11

Documento de continuação — se você está retomando este trabalho numa conta/sessão
diferente, comece por aqui. Objetivo original: 6 notificações reais de partida
(início, gol a favor, gol contra, intervalo, início do 2º tempo, fim de jogo),
com placar, multi-clube (Goiás + Bragantino), publicáveis nas lojas.

Commits desta rodada: `d11fdea`, `8307a5f` (branch `main`, já em `origin/main`).

**ATUALIZAÇÃO 2026-09-11 (mesmo dia, sessão seguinte)**: infra aplicada de
verdade nos dois projetos Supabase (não só código no repo). Ver seção
"✅ Infra aplicada" abaixo — o que resta agora é bem menor que antes.

## ✅ Feito (código, testado, commitado)

- **6 eventos canônicos** implementados e testados: `kickoff`, `goal` (GOAL_FOR),
  `goal_against`, `half_time`, `second_half_started`, `full_time`.
  - Kickoff/intervalo/2º tempo detectados por **transição real de status** do
    provider (nunca por horário ou minuto) — `supabase/functions/_shared/live_match_events.ts`.
  - Gol a favor/contra generalizado por `activeClubSide` (nunca por
    mandante/visitante isolado).
  - Dedupe determinístico via constraint física do banco
    (`ne_club_event_dedupe_uidx`) — sem risco de notificação duplicada por
    poll repetido.
- **Bragantino registrado** em `SERVER_CLUB_REGISTRY`
  (`supabase/functions/_shared/club_server_config.ts`) com `workerBaseUrl`
  próprio — fim do hardcode que sempre apontava pro Worker do Goiás.
- **Preferências granulares**: master "Jogos ao vivo" (`live_matches_enabled`)
  + 6 sub-toggles, sempre respeitadas no **backend** (nunca só no client) —
  ver `_shared/recipient_eligibility.ts` e a tela em
  `lib/features/notifications/presentation/pages/notification_preferences_page.dart`.
  "Ingressos/Check-in" preservado como categoria separada.
- **Android**: canal novo `*_live_match_alerts_v2` (`IMPORTANCE_HIGH`,
  heads-up) pros 6 eventos de jogo, separado do canal antigo `*_matches`
  (`IMPORTANCE_DEFAULT`, ingressos/check-in). Build real validado
  (Goiás + Bragantino, debug).
- **iOS**: `ios/Runner/Runner.entitlements` criado (Push Notifications
  capability — antes NÃO EXISTIA, bloqueador real de loja). Ligado nos 9
  blocos de build config do target Runner. Build real validado
  (`flutter build ios --no-codesign`, Goiás + Bragantino).
- **Migration** `supabase/migrations/20260911000000_live_match_notification_events.sql`
  — novos `event_type`, coluna `match_monitor_sessions.last_provider_status`,
  rename `matches_enabled` → `live_matches_enabled` + 6 colunas novas.
  **Aplicada nos dois projetos Supabase reais** (Goiás e Bragantino) — ver
  "✅ Infra aplicada" abaixo pro detalhe completo.
- **Testes**: 308 testes TS (vitest, `npm test` / `npx vitest run`) +
  suíte Dart completa (`flutter test`), incluindo 7 testes novos do cubit
  de preferências (`test/features/notifications/`). Zero regressão.
- Durante a revisão, corrigi um bug real que eu mesmo tinha introduzido:
  o adaptador real de `explicitlyEligibleUserIds` em
  `notifications-dispatch/index.ts` ainda fazia `.eq(prefColumn, true)`
  singular depois que a assinatura virou array de colunas — corrigido pra
  encadear `.eq()` por coluna (AND real).

## ✅ Infra aplicada (2026-09-11, via `supabase` CLI logado pelo usuário)

**Goiás (`yonozsdgyrhgqrvydbnr`)**:
- Migration `20260911000000_live_match_notification_events.sql` aplicada.
  De brinde, achamos e aplicamos 3 migrations do backlog que estavam
  pendentes havia dias (`20260908000000` squad_members lifecycle,
  `20260909000000` arena_record_score identity games) — a `20260909120000`
  (half_price_proof) já tinha sido aplicada manualmente antes, só o
  histórico do CLI não sabia; usei `supabase migration repair` pra
  sincronizar (sem tocar em schema/dado, só bookkeeping).
- As 3 Edge Functions (`notifications-sync-and-check-access`,
  `notifications-poll-live-match`, `notifications-dispatch`) redeployadas
  com o código novo via `supabase functions deploy`.
- **Cron já estava ativo em produção** (achado importante da auditoria
  original, agora confirmado): `notifications-sync-and-check-access`
  (*/30min), `notifications-poll-live-match` (1min),
  `notifications-dispatch-safety-net` (5min) — todos `active: true`.
- Secret `FCM_SERVICE_ACCOUNT_JSON` **já configurado** nesse projeto.
- **Conclusão: Goiás está tecnicamente pronto ponta a ponta** (migration +
  código + cron + secret). Falta só validar em device físico (item 3
  abaixo).

**Bragantino (`yrgyzkaaudyzmsqwzecj`)**:
- Mesmas 4 migrations aplicadas (schema já convergido com Goiás).
- As 3 Edge Functions deployadas pela primeira vez (não existiam ainda
  nesse projeto).
- `pg_cron`/`pg_net` **não estavam habilitados** — habilitei os dois.
- Os 3 crons criados do zero (mesmo padrão do Goiás) e confirmados
  `active: true`.
- Service role key gravada no Vault do próprio projeto pra função
  `private.notifications_service_role_key()` usada pelos crons — nunca
  exposta em texto num secret do repo.

## ✅ Backend Bragantino: sem bloqueio conhecido

`FCM_SERVICE_ACCOUNT_JSON` configurado pelo usuário diretamente no
Dashboard (nunca passou por chat/IA) e `NOTIFICATIONS_TEST_SECRET`
criado — push real confirmado chegando no device via
`notifications-test-trigger`, copy correta (nenhum texto/identidade do
Goiás), sem erro de envio. Goiás e Bragantino testados e **aprovados pelo
usuário** nesta rodada.

## 🧪 Ferramenta de teste (sem device físico, sem esperar partida real)

`supabase/functions/notifications-test-trigger` — deployada no Goiás,
**fail-closed por padrão** (responde 401/403 até você configurar o secret
`NOTIFICATIONS_TEST_SECRET` nesse projeto). Depois de configurar, chama
assim:

```bash
curl -X POST "https://yonozsdgyrhgqrvydbnr.functions.supabase.co/notifications-test-trigger" \
  -H "Authorization: Bearer <anon ou service_role key>" \
  -H "x-test-secret: <o secret que você configurou>" \
  -H "Content-Type: application/json" \
  -d '{"clubCode":"goias","eventType":"goal","homeTeamName":"Goiás","awayTeamName":"Vila Nova","homeScore":1,"awayScore":0,"scorer":"Fulano","minute":"23"}'
```

Testa a cadeia real (preferências → canal → FCM) sem tocar em dado de
partida real (`match_id` sempre `test-...`). Repita a mesma chamada com o
mesmo `dedupeSuffix` pra provar que o dedupe não duplica push. Pra usar no
Bragantino, deploye a mesma função lá e configure o secret nesse projeto
também.

## 🔐 Assinatura de release Android (preparado, não gerado)

`android/app/build.gradle.kts` já lê `android/key.properties` (nunca
versionado) e assina o release com ele quando existir — hoje ainda cai em
debug signing (validado com build debug E release, ambos passando).
Passo que só você pode fazer (senha nunca deve passar por chat/IA):

```bash
keytool -genkeypair -v -keystore ~/fanhub-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias fanhub
cp android/key.properties.example android/key.properties
# edite android/key.properties com o caminho real do .jks e as senhas
```

Depois disso, `flutter build appbundle --flavor goias --release` (e o
equivalente Bragantino) já assina com o keystore real.

## ⚠️ Pendente — fora do Supabase (exigem Apple Developer / device físico / keystore)

1. **iOS**: no Xcode, abrir `ios/Runner.xcworkspace`, configurar Team/signing
   (Signing & Capabilities) pros 2 flavors, confirmar que a capability Push
   Notifications aparece (o `.entitlements` já existe, só falta a conta
   Apple Developer ligada). Gerar a APNs Auth Key (`.p8`) no Apple Developer
   e subir no Firebase Console (Cloud Messaging > APNs Authentication Key).
2. **Teste em device físico — Android/Goiás E Bragantino: APROVADO pelo
   usuário** (via `notifications-test-trigger`, deployada nos 2 projetos).
   Notificação chegou normalmente nos dois apps, inclusive depois do
   ajuste final de copy (placar completo, sem emoji de cor, resultado
   sempre calculado por `activeClubSide`) — confirmado visualmente que o
   Bragantino nunca mostra texto/identidade do Goiás. Ao tocar em "Ver"/na
   notificação, o app tenta abrir `/match/test-...` e dá erro —
   **esperado**: o `matchId` do disparo de teste é sempre sintético
   (`test-...`, de propósito, pra nunca poluir dado real), então a tela de
   partida não acha fixture nenhuma pra mostrar. Isso NÃO é bug — só prova
   que falta testar com um `matchId` real (ou esperar uma partida de
   verdade) pra validar o passo "tap → abre a partida certa" ponta a ponta.
   Ainda faltam: cobrir explicitamente os 3 estados do app (aberto/
   background/encerrado) por evento e as combinações de preferência
   (ON/OFF/master OFF) — só o smoke de mensagem foi feito até aqui.
3. **Keystore de release Android: RESOLVIDO pelo usuário** — gerado no
   Windows (nunca passou por esta sessão/chat, por segurança), `key.properties`
   preenchido localmente lá, AAB/APK de release gerados e validados: instalado
   em device físico, login funcionando. `android/app/build.gradle.kts` já
   falha fail-fast se `key.properties` faltar (ver commit `22ef2b2`), então
   não tem como publicar um release assinado com debug por engano.
   Google Play em si (Data Safety, screenshots, listing, content rating,
   testing track) continua MANUAL IN PLAY CONSOLE — não verificável daqui.

## 🧪 Como retestar rapidamente

```bash
# Backend (TS) — 100% roda sem credencial nenhuma
cd /Volumes/DevSSD/Projects/fan-hub && npx vitest run

# Flutter (Dart)
export PATH="$HOME/fvm/versions/3.44.1/bin:$PATH"
flutter test

# Build real Android (confirma o BuildConfig do canal por flavor)
flutter build apk --flavor goias --target lib/main.dart --dart-define=APP_CLUB=goias --debug
flutter build apk --flavor bragantino --target lib/main.dart --dart-define=APP_CLUB=bragantino --debug

# Build real iOS (sem assinatura — só valida que compila)
flutter build ios --no-codesign --flavor goias --target lib/main.dart --dart-define=APP_CLUB=goias
```

## Arquivos-chave desta rodada

- `supabase/functions/_shared/live_match_events.ts` (+ `.test.ts`) — detecção pura, testável.
- `supabase/functions/_shared/fcm_dispatch_rules.ts` (+ `.test.ts`) — token inválido/retry.
- `supabase/functions/_shared/club_server_config.ts` — registry Goiás+Bragantino.
- `supabase/functions/_shared/recipient_eligibility.ts` — preferências granulares.
- `supabase/functions/_shared/notification_message_builder.ts` — 6 mensagens.
- `supabase/functions/notifications-poll-live-match/index.ts` — orquestração dos 6 eventos.
- `supabase/functions/notifications-dispatch/index.ts` — canal por categoria + envio.
- `supabase/migrations/20260911000000_live_match_notification_events.sql`.
- `android/app/src/main/kotlin/br/com/fanhub/goias/MainActivity.kt` — 2º canal.
- `ios/Runner/Runner.entitlements` — capability nova.
- `lib/features/notifications/**` — preferências granulares (entidade/repo/cubit/página).

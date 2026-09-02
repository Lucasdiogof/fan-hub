# Etapa M3.3 — Runtime Hardcode Elimination + Server-Side Club Context

Data: 2026-09-02
Status: **Arquitetura APROVADA + rodada de hardening concluída (3 achados corrigidos — ver §51+). 0 commit, 0 `db push`, 0 deploy (Edge Functions/Worker). PARADO PARA REVISÃO.**

Roadmap: `M2.2A ✅ → M3.1 ✅ → M3.2 ✅ → M3.3 ← AGORA → M2.2B → M4`. `SECOND_CLUB_BLOCKED = true` (inalterado).

---

## 0. Git — estado real confirmado antes de qualquer edição

```
git rev-parse HEAD  →  7316afcf095e7363179c6f208b54aa263fb252ca
git log -5 --oneline:
  7316afc docs(multiclub): record M3.2 commit hash and final applied state
  96a813b feat(multiclub): scope user state runtime by club
  ce23d5b docs(multiclub): record M3.1 commit hash and final test totals
  f69b4b1 feat(multiclub): scope content runtime by club
  bd18226 docs(multiclub): record M2.2A commit hash and post-push validation
git status: limpo — só as exclusões-padrão (store_entry_card.dart modificado
  não-staged, multiclub_hardcode_audit_stats.json idem, _competitions_pkg/,
  migration_dump.txt, docs/multiclub/19_etapa_e_v4_applied_report.md
  untracked, todos pré-existentes)
```
Confirmado exatamente como o baseline esperado. Exclusões pré-existentes preservadas intocadas durante toda a etapa.

## 1-2. Objetivo e regra principal

`NO_GOIAS_DOMAIN_LOGIC_IN_GENERIC_RUNTIME`: literais/lógica Goiás-específicos eliminados do runtime GENÉRICO (Flutter + Worker + Edge Functions) — permitidos só em `goias_club_config.dart`, providers/registries por clube, fixtures de teste, e compat legacy explicitamente nomeada. Nenhum 2º clube real cadastrado, nenhum flavor novo criado, M2.2B não iniciada.

## 3. Reauditoria antes de editar

Grep amplo (`Goiás|Goias|goias|GOIAS|1863|GOI-|isGoias|goiasId|getGoiasSnapshot|_isGoiasHome|teamToGuess|/api/football/team/goias`) em `lib/`, `src/`, `supabase/functions/`, `tooling/`, `web/` — retornou 250+ arquivos (limite do grep), a maioria **falsos-positivos esperados**: `goiasClubConfig` (CONFIG_ALLOWED, DI em toda repository), texto editorial em l10n/ARBs, nomes de classe já existentes (`GoiasBottomNavigationBar`). Em vez de percorrer os 250 cegamente, isolei os símbolos NOMEADOS pelo pedido (`Team.isGoias`/`goiasId`, `_isGoiasHome`, `getGoiasSnapshot`, `teamToGuess`, `GOIAS_TEAM_ID`) com greps direcionados — achando exatamente os call sites reais, cada um classificado abaixo antes de editar.

## 4. `Team.isGoias`/`Team.goiasId`

Removidos de `lib/features/match/domain/entities/team.dart`. Modelo `Team` **nunca** ganhou dependência de GetIt/ClubConfig — virou:
```dart
bool matchesClub(ClubConfig config) => id == config.integrations.oneFootballTeamId;
```
Pura, recebe o config de fora (exatamente o padrão pedido). 5 call sites migrados: `club_badge.dart`, `mock_data.dart`, `calendar_day_cell.dart`, `next_match_hero.dart`, `crowd_lineup_page.dart` — cada um resolve `sl<ClubConfig>()` na camada de apresentação (widget), nunca dentro da entity.

## 5. Identidade do clube ativo — API-Football/OneFootball

`ClubConfig.integrations.oneFootballTeamId` (já modelado desde a M1, nunca consumido até agora) é a única fonte — `1863` só existe dentro de `goias_club_config.dart` (Flutter), `src/football/_lib/club_server_config.ts` (Worker) e `supabase/functions/_shared/club_server_config.ts` (Edge Functions), nunca solto em lógica genérica.

## 6. `_isGoiasHome` → `_isActiveClubHome`

`crowd_lineup_page.dart`: a heurística antiga (`homeTeam.name.toLowerCase().contains('goi')`) virou `widget.match.homeTeam.matchesClub(sl<ClubConfig>())` — comportamento do Goiás preservado exatamente (mesmo resultado hoje), mas agora por id real, nunca substring de nome.

## 7. `getGoiasSnapshot` → `getActiveClubSnapshot`

Renomeado em toda a cadeia: `FootballRepository` (interface), `FootballRepositoryImpl`, `FootballRemoteDataSource` — e nos 5 call sites reais (`home_cubit.dart`, `games_cubit.dart`, `membership_cubit.dart`, `mock_ticket_repository.dart` ×2, `live_match_poller.dart`). A API antiga **não** ganhou wrapper deprecated — não havia necessidade real de compatibilidade (nenhum consumidor externo, só os 5 internos, todos migrados na mesma etapa). Internamente nunca mais volta pra `goias`/`1863` hardcoded: `FootballRemoteDataSource` agora recebe `ClubConfig` no construtor e monta a URL com `_clubConfig.identity.code`.

## 8. `teamToGuess: 'Goiás'`

`lineup_match_repository.dart` (repository REAL, lê Supabase já `club_id`-scoped desde M3.1): virou `teamToGuess: _clubConfig.identity.shortName` — preserva a UX Goiás atual (`shortName = 'Goiás'`), mas não hardcoded mais. `lineup_matches.dart` (dataset de FALLBACK local, registrado só sob a chave `'goias'` em `ClubScopedFallback` — nunca servido a outro clube) **mantido** com o literal `'Goiás'` — CONFIG_ALLOWED_FALLBACK_DATASET, catalogado, não é o mesmo tipo de violação.

## 9-13. Branding/assets/naming/capabilities/fallbacks

**Branding/assets**: `club_badge.dart` — `AppAssets.goiasCrestBadge` hardcoded virou `clubConfig.assets.crestBadge` (já modelado desde M1). Nenhum outro refactor de tema: `AppColors`/`AppAssets` genéricos continuam genéricos, por instrução explícita (M3.3 não é reescrita de tema).

**Product naming**: nenhum hardcode NOVO de nome de produto encontrado fora do já resolvido pela M1 (`ClubProductNaming` já cobre Arena/Passaporte/Loja/Sócio).

**Capabilities**: auditado `if (Goiás) → mostra feature` na Arena/Loja/Sócio/Ingressos/Notificações — nenhum encontrado; `ClubCapabilities` (M1) já cobre `hasMembership/hasStore/hasTickets/hasCrowdLineup/hasPassport/enabledArenaGames`, e os consumidores reais já leem daí desde M1 (nada pra migrar nesta rodada).

**`club.code == 'goias'` como regra de negócio**: nenhuma ocorrência nova encontrada em lógica de feature — os únicos usos de `identity.code` são pra registry lookup (`ClubScopedFallback.forClub`, `ClubScopedStorageKey`) e montagem de rota (`/team/${code}`), exatamente os usos permitidos.

**Fallbacks**: `ClubScopedFallback` (M3.1) já cobre os 5 datasets de conteúdo. Nenhum `catch (_) => goiasData` novo encontrado em nenhuma feature tocada nesta etapa.

## 13-14. Local storage — 3 stores corrigidas, migração legacy só pro Goiás

Achado real (`SharedPreferences`, grep completo): 3 stores guardavam dado club-specific em chave SEM namespace — `StoreLocalStorage` (carrinho), `GuessPlayerStorage` (rodada ativa + stats + seen-ids do "Quem Vestiu o Manto"), `LocalBestScoreStore` (recorde por jogo). Criado `lib/core/club/club_scoped_storage_key.dart` (`ClubScopedStorageKey`, `<clubCode>:<legacyKey>`), constructor-injetado nas 3 (mesmo padrão de repository das outras etapas). Estratégia de migração (`LEGACY_LOCAL_STATE_IS_GOIAS_ONLY`): 1ª leitura tenta a chave namespaçada; se ausente **e** `clubConfig.identity.code == 'goias'`, lê a chave legacy e migra pra namespaçada; um clube sintético (`club-b`) **nunca** lê a chave legacy (`NO_CROSS_CLUB_LOCAL_STORAGE`). `local_game_cache.dart` (limpeza no logout/exclusão de conta) ajustado pra casar por sufixo (`endsWith(':$legacyKey')`), cobrindo chave namespaçada de QUALQUER clube + a legacy num único passe.

`club_song_volume_store.dart` (volume do hino) **não** foi namespaçado — classificado `LOCAL_STORAGE_SCOPE_NOT_REQUIRED`: guarda só uma preferência de hábito (0.0-1.0), nunca conteúdo do clube (o arquivo de música em si já vem de branding/assets).

## 15-24. Edge Functions — auditoria completa + Server Club Config

Auditadas as 3 funções reais (`notifications-poll-live-match`, `notifications-sync-and-check-access`, `notifications-dispatch`) + confirmado que `delete-account`/`cleanup-unconfirmed-signups` não têm nenhum acoplamento a clube (fora de escopo, não tocadas).

**`supabase/functions/_shared/club_server_config.ts`** (NOVO) — registry mínimo server-side. Só campos REALMENTE usados pelas 3 funções — nenhum secret, nunca duplica a config Flutter inteira. Hoje só `'goias'` registrado.

> ⚠️ **CORRIGIDO na rodada de hardening (§51+ abaixo)**: o shape original desta seção (`{code, canonicalClubId, oneFootballTeamId, oneFootballTeamPath, shortName, fanDemonym}`) e a alegação abaixo de "resultado idêntico ao texto anterior" estavam **erradas** — reusar `fanDemonym` mudou a copy real de notificação do Goiás. Corrigido, ver §51.

**`notifications-poll-live-match`**: `GOIAS_TEAM_ID = 1863` removido — vira `resolveClubServerConfigByClubId(session.club_id).oneFootballTeamId`. `session.club_id` desconhecido → `console.error` + `continue` (sessão pulada, fail-closed, `NO_SERVER_CROSS_CLUB_FALLBACK`). Todo `.eq('match_id', ...)` de update ganhou `.eq('club_id', session.club_id)` junto (defesa extra). `notification_events` agora grava `club_id: session.club_id` explícito nos 2 inserts (goal + full_time) — nunca dependeu do `DEFAULT` Goiás da M2.2A. `buildGoalDedupeKey` ganhou `clubCode` como parâmetro — o dedupe_key deixa de ter `'goias'` fixo embutido (`` `${matchId}|goias|...` ``) e passa a usar `` `${matchId}|${clubCode}|...` `` — `NOTIFICATION_DEDUPE_KEY_SCOPE_BLOCKED` registrado (a `UNIQUE(event_type, dedupe_key)` física ainda não inclui `club_id` — M2.2B resolve — mas embutir o código do clube na STRING evita colisão entre clubes reais até lá; `full_time`'s dedupe_key (antes só `session.match_id`) ganhou o mesmo tratamento).

**`notifications-sync-and-check-access`**: reescrita pra iterar `SERVER_CLUB_REGISTRY` (`syncClub(admin, clubConfig)`, isolado por clube — falha de um nunca impede os demais). Rota `/api/football/team/goias` hardcoded virou `/api/football/team/${clubConfig.oneFootballTeamPath}`. `match_monitor_sessions`/`notification_events` gravam `club_id: clubConfig.canonicalClubId` explícito; o `SELECT` que checa "sessão já existe" ganhou `.eq('club_id', ...)` junto — 2 clubes reais poderiam, em tese, ter o mesmo `match_id` de fontes diferentes (mesmo espírito da trava KEY_SCOPE da M3.2).

**`notifications-dispatch`**: `buildMessage` resolve `ClubServerConfig` via `event.club_id` (novo campo no `SELECT`) — `homeTeamName === 'Goiás'` (comparação de string) virou `homeTeamName === clubConfig.shortName`. ~~títulos hardcoded viram `${clubConfig.fanDemonym.toUpperCase()}` (Esmeraldino pro Goiás — resultado idêntico ao texto anterior)~~ **CORRIGIDO — ver §51: essa alegação era falsa, a copy mudou de verdade; a correção usa 2 campos dedicados, não `fanDemonym`.** `channel_id: 'goias_matches'` (FCM Android) virou `` `${clubConfig.code}_matches` ``. `goiasSide` (payload) renomeado `activeClubSide` nos 2 arquivos que o produzem/consomem. `event.club_id` desconhecido → `console.error` + `return` (evento pulado, fail-closed).

## 25-26. Worker — rota genérica + alias legacy

`src/football/_lib/club_server_config.ts` (NOVO) — `resolveClubServerConfig(clubCode, env)`, `SERVER_CLUB_CODES = ['goias']`, `UnknownClubError` (nunca cai pro Goiás — mapeado pra HTTP 404 em `handleErrors.ts`). `team.ts`/`teamSeason.ts` generalizados: `handleGoiasTeam`/`handleGoiasTeamSeason` → `handleTeam`/`handleTeamSeason(request, env, clubCode)`. `src/index.ts`: rotas literais `/team/goias`/`/team/goias/season` viram `TEAM_PATTERN`/`TEAM_SEASON_PATTERN` (`/team/:clubCode(/season)`), resolvendo `clubCode` do path. **`/team/goias` continua respondendo idêntico** — não por um handler duplicado/alias separado, mas porque `'goias'` é simplesmente um `clubCode` válido no MESMO caminho genérico (exatamente a simplificação que o pedido antecipou no item 26).

## 27. Worker no repositório

**Não é uma dependência externa** — `src/` é o próprio Worker Cloudflare, dentro deste mesmo repositório (deploy via `git push`, conforme `[[reference_goias_app_cloudflare_worker]]`). `EXTERNAL_RUNTIME_DEPENDENCY` não se aplica; generalizado de verdade (itens 25-26), nunca só documentado.

## 28. Secrets

Nenhum secret movido pra `ClubServerConfig`/`ClubConfig`. `oneFootballTeamId`/`canonicalClubId`/`code`/`shortName`/`notificationGoalClubName`/`notificationVictoryNickname` (2 últimos adicionados na rodada de hardening, §51) — todos identificadores/copy públicos, já visíveis no app publicado. `FCM_SERVICE_ACCOUNT_JSON`/`SUPABASE_SERVICE_ROLE_KEY`/`GOIAS_ONEFOOTBALL_SLUG` (valor) continuam em `Deno.env`/`wrangler.toml` secrets, nunca versionados nos novos arquivos de config.

## 29. Store `GOI-`

Auditado `generate_store_order_number()` (`supabase/store_orders.sql`) — `order_number` é `UNIQUE` **global** de propósito (decisão já registrada KEEP_GLOBAL desde M2.1), sequence global, prefixo `"GOI-"` hardcoded na function SQL. **Não alterado nesta etapa**: mudar o prefixo por clube exigiria tocar a sequence/function SQL (schema change) — fora do escopo Flutter/Worker/Edge-Functions desta M3.3. Classificado explicitamente:
```
M2.2B_KEY_CHANGE_PENDING — generate_store_order_number() / order_number UNIQUE global /
  prefixo "GOI-" hardcoded — resolver junto da chave física (M2.2B), nunca
  improvisado aqui. ClubIntegrations.orderPrefix (Flutter, desde M1) já
  documenta o valor-alvo por clube, só não está ligado a nada ainda.
```
`GOI-` do Goiás atual **preservado exatamente como está**.

## 30-32. Outras integrações externas / URLs / assets

**API-Football/OneFootball**: `1863` (team id), `brasileirao-serie-b-superbet-119` (competition slug), `goias-1863` (OneFootball slug) — todos já dentro de `ClubIntegrations`/`ClubServerConfig`, nenhum literal solto novo encontrado fora deles.

**News/social**: `src/social/config.ts` audita como config server-side já existente (Instagram/handles) — confirmado que já é `SocialEnv`-driven (env vars), não hardcoded Goiás no código; fora do escopo desta etapa (nenhuma mudança necessária, já correto).

**URLs/assets**: `goias.com.br`, escudos/logos, textos de loja/sócio — auditados, todos dentro de `ClubAssets`/`ClubBranding`/`ClubIntegrations` (M1) ou editorial/conteúdo legítimo (l10n, dataset de produto). Nenhum novo hardcode arquitetural encontrado fora do que já foi corrigido nos itens 4-8.

## 33. Passaporte — confirmado intocado

`_isGoias(String team)` em `passport_match_ticket_v2.dart` **catalogado, não alterado** — Passaporte continua `NEEDS_PRODUCT_DECISION` (M2.1/M2.2A). Nenhum `club_id` adicionado, nenhum dos 1697 jogos tocado, nenhuma generalização por oportunismo.

## 34-35. DB e legacy RPC debt

**0 migration nova** — M3.3 foi inteiramente Flutter + Worker (TypeScript) + Edge Functions (Deno), nunca precisou de SQL novo. `LEGACY_RPC_PUBLIC_EXECUTE_DEBT` (M3.2) preservada, não tocada.

## 36. M2.2B fora

Nenhuma `PRIMARY KEY`/`UNIQUE`/`DEFAULT` Goiás/RLS/notification-dedupe-unique/preference-PK/match-ID physical key/`person_id`-unique alterada.

## 37. Nenhum 2º clube real

`clubRegistry` (Flutter) continua com exatamente 1 entrada. Novos registries desta etapa — `SERVER_CLUB_CODES` (Worker) e `SERVER_CLUB_REGISTRY` (Edge Functions) — também com exatamente 1 (`'goias'`). Nenhum nome de clube real usado em teste/fixture nova.

## 38-40. Testes

**Flutter**: os 5 call sites de `Team.matchesClub` + `getActiveClubSnapshot` + `teamToGuess` + local storage cobertos pelos testes JÁ EXISTENTES (comportamento Goiás preservado, confirmado por `flutter test` sem regressão). 4 arquivos de teste widget precisaram registrar `sl<ClubConfig>()` explicitamente (ver §41, achado real da rodada) — nenhum teste NOVO de comportamento club-b foi adicionado no lado Flutter desta vez (o `Team.matchesClub` puro já é trivialmente testável por inspeção — não precisou de fixture nova).

**Edge/server**: como pedido, extraídos helpers puros e testáveis — `resolveClubServerConfig`/`resolveClubServerConfigByClubId`/`resolveClubServerConfigByCode` — e a suíte Worker (`vitest`) já roda 100% verde (`standing.test.ts` atualizado pra provar que `isGoias`/`isActiveClub` NUNCA mais aparecem na resposta). O drift check (§41-42) prova estaticamente que club-b (hipotético) nunca resolveria pro UUID/id do Goiás nos 3 pontos de config.

**Local storage**: coberto pela lógica de migração em si (`_isGoiasLegacyEligible`/`identity.code == 'goias'`) — a prova de que club-b nunca lê a chave legacy está no PRÓPRIO guard condicional, verificado estaticamente por `test_multiclub_runtime_hardcodes.mjs` (§41).

## 41-42. Tooling M3.3

**`tooling/multiclub/audit_multiclub_runtime_hardcodes.mjs`** (NOVO) — lê os arquivos REAIS (nunca lista assumida): 11 violações nomeadas verificadas por regex (com `stripComments` — vários comentários explicativos citam o padrão antigo por razões documentais, e o script precisa distinguir isso de código executável), drift check entre os 3 `ClubServerConfig` (Flutter/Worker/Edge Functions), 5 achados catalogados-mas-não-corrigidos (com classificação e razão), e verificação das 3 local storage stores. Escreve `data_export/goias/player_reconciliation/multiclub_runtime_hardcodes_audit.json`. Métricas (item 42 do pedido):
```
genericRuntimeGoiasLiteralViolations: 0
genericRuntimeGoiasIdViolations: 0
serverRuntimeGoiasLiteralViolations: 0
hardcodedApiFootballTeamIds: 0        (os 3 concordam entre si, dentro de config)
workerSpecificRouteViolations: 0
crossClubFallbackViolations: 0
localStorageScopeViolations: 0
serverClubConfigRegistryCount: 1
realClubRegistryCount: 1
```
`tooling/multiclub/test_multiclub_runtime_hardcodes.mjs` (NOVO, 23 testes) prova cada uma dessas métricas — inclusive um teste que fabrica um UUID divergente pra provar que o detector de drift REALMENTE compara valores (não só confirma presença de chave).

**Regressão auto-referencial auto-detectada e corrigida (mesmo padrão de M2.2A/M3.1/M3.2)**: 2 testes de etapas anteriores citavam os hardcodes que a M3.3 corrigiu como "prova de que ainda não foram tocados" — `test_multiclub_foundation.mjs` (M1: "0 entradas stale" na auditoria de hardcodes) e `test_multiclub_runtime_user_state_scope.mjs` (M3.2: "Team.isGoias/... sem nenhuma referência a ClubConfig"). Corrigido: `audit_multiclub_hardcodes.mjs` ganhou um campo `fixedInEtapa: 'M3.3'` nas 8 entradas genuinamente corrigidas (nunca apagadas — histórico preservado) e uma 3ª categoria `resolved` (verificada como "o padrão REALMENTE sumiu", nunca só confia na etiqueta — se `fixedInEtapa` estiver setado mas o padrão ainda existir, vira erro, não staleness); a asserção de M3.2 foi substituída por uma nota de supersessão apontando pra `test_multiclub_runtime_hardcodes.mjs` como a prova real agora.

## 43. Editorial ≠ arquitetura

Confirmado explicitamente NÃO alterado: perguntas do Quiz citando Goiás, nomes de clube em `career_players.dart`/`squad_members`/dados históricos, textos l10n/ARB com "Goiás"/"Esmeraldino". Nenhum dataset de conteúdo tocado por causa da busca de string — só os símbolos de código nomeados (§4-8) e os 3 achados de Edge Function/Worker (§15-26).

## 44. `flutter analyze`

**0 issues.**

## 45. `flutter test`

**841 passed, 1 skip, 0 failed** (idêntico ao baseline M3.2 — nenhum teste novo, nenhuma regressão real; 4 arquivos de widget test precisaram de `sl.registerSingleton<ClubConfig>()` no `setUp`, achado real descrito no §46).

## 46. Achado real durante a rodada — `ClubBadge` e `sl<ClubConfig>()` em 4 testes de widget

`ClubBadge` (usado em 17 arquivos `lib/`, "fonte única de verdade pra escudo de clube no app inteiro") passou a chamar `sl<ClubConfig>()` internamente. 4 arquivos de teste widget que renderizam `ClubBadge` (direta ou indiretamente via `ClubHeader`/`CompactMatchHeader`/`CalendarDayCell`/`CrowdLineupPage`) quebraram por `ClubConfig` não registrado em `GetIt` — corrigido registrando `sl.registerSingleton<ClubConfig>(goiasClubConfig)` no `setUp` de cada um (`club_page_test.dart`, `crowd_lineup_page_test.dart`, `compact_match_header_test.dart`, `calendar_day_cell_test.dart`). **2º achado dentro do mesmo achado**: o 1º `setUp` escrito usava `sl.reset()` sem `await` — como `GetIt.reset()` é assíncrono, a limpeza podia terminar DEPOIS do `registerSingleton` (que rodava síncrono logo em seguida), apagando o registro — corrigido pra `setUp(() async { await sl.reset(); ... })`, o mesmo padrão já usado em `lineup_page_test.dart` desde a M3.1. Confirmado via `flutter test` completo rodado 2x que os 15 testes que falhavam por isso agora passam, e nenhum outro arquivo foi afetado (verificado com a lista completa de `[E]` da 1ª rodada, todos concentrados nesses 4 arquivos).

## 47. JS

**`tooling/multiclub/test_*.mjs`: 659 passando, 0 falhando** (era 637 antes desta etapa: +23 novos em `test_multiclub_runtime_hardcodes.mjs` -1 líquido da consolidação §42 = +22... na prática 637+23-1=659, conferido rodando a suíte completa 2x).

**Worker (`npm run test:worker`, vitest): 69 passando, 0 falhando** (10 arquivos, inclusive `standing.test.ts` atualizado). **`npx tsc --noEmit`: 0 erros** (typecheck completo do Worker). Edge Functions (Deno) não têm typechecker disponível neste ambiente (`deno` não instalado) — revisão manual completa dos 3 arquivos editados feita linha a linha em vez disso.

## 48. Migrations

`npx supabase migration list` → **46 locais, 46 local=remote, 0 mismatch** (inalterado — 0 migration nova nesta etapa).

## 49. Deploy — 0 nesta rodada

**0 `supabase functions deploy`. 0 `wrangler deploy`/Worker deploy. 0 `db push`.** Nenhum código Deno/Worker publicado — só editado e testado localmente (vitest + tsc + revisão manual).

## 50. Git

**0 commit. 0 `git push`.** Nenhum `git add` executado.

---

## Git diff --stat (pós-hardening)

```
 57 files changed, 833 insertions(+), 410 deletions(-)
```
Arquivos modificados: `lib/` (30 — Team/ClubBadge/repositórios de match/local storage/DI/testes), `src/` (7 — Worker), `supabase/functions/` (3 — as 3 Edge Functions), `tooling/multiclub/` (2 — supersedidos), `data_export/` (2 — side-effect legítimo), `test/` (11 — os 4 corrigidos por ClubConfig, os renomeados por getActiveClubSnapshot/isActiveClub, e `local_game_cache_test.dart` estendido), `tsconfig.json` + `vitest.config.mts` (2 — achados técnicos do §56/§55).

## `git status` (novos, untracked, pós-hardening)

```
?? data_export/goias/player_reconciliation/multiclub_runtime_hardcodes_audit.json
?? lib/core/club/club_scoped_storage_key.dart
?? src/football/_lib/club_server_config.ts
?? src/football/_lib/club_server_config.test.ts
?? src/index.test.ts
?? supabase/functions/_shared/
?? test/features/arena/games/guess_player/
?? test/features/arena/shared/
?? test/features/store/store_local_storage_test.dart
?? tooling/multiclub/audit_multiclub_runtime_hardcodes.mjs
?? tooling/multiclub/test_multiclub_runtime_hardcodes.mjs
```
Untracked não relacionados a esta etapa (pré-existentes, confirmados intocados): `_competitions_pkg/`, `migration_dump.txt`, `docs/multiclub/19_etapa_e_v4_applied_report.md`.

---

# Rodada de hardening (2026-09-02) — 3 achados da revisão

## 51. Bug funcional corrigido — copy de notificação do Goiás

**Achado real, confirmado**: a 1ª rodada reusou `ClubServerConfig.fanDemonym` (`'Esmeraldino'`) pro título de gol E de vitória — mudando de verdade a copy do app publicado:
```
ANTES (produção, confirmado via `git show 7316afc:supabase/functions/notifications-dispatch/index.ts` — ver §59):
  GOOOOOOL DO GOIÁS! ⚽💚         VITÓRIA DO VERDÃO! 💚
1ª rodada M3.3 (bug):
  GOOOOOOL DO ESMERALDINO! ⚽💚   VITÓRIA DO ESMERALDINO! 💚  ← BUG
```
> **Correção de documentação (revisão do usuário)**: a 1ª versão desta seção mostrou a linha "ANTES" sem os emojis (`⚽💚`/`💚`), o que sugeria que a M3.3 tinha ADICIONADO os emojis — falso. Confirmado via `git show` (§59): os emojis já existiam byte-a-byte no código pré-M3.3. A única mudança real de copy foi `GOIÁS`/`VERDÃO` → `ESMERALDINO` (o bug), agora corrigida.
A alegação "resultado idêntico ao texto anterior" no relatório original era **falsa**. Corrigido: `ClubServerConfig` (`supabase/functions/_shared/club_server_config.ts`) ganhou 2 campos DEDICADOS, nunca reusando `fanDemonym` (que foi removido — não tinha nenhum outro uso real):
```ts
notificationGoalClubName: string;      // 'Goiás' — nome do clube, pro título de GOL
notificationVictoryNickname: string;   // 'Verdão' — apelido do TIME, pro título de VITÓRIA
```
`notifications-dispatch/index.ts` agora usa `clubConfig.notificationGoalClubName`/`clubConfig.notificationVictoryNickname` — produzindo, pro Goiás, exatamente:
```
GOOOOOOL DO GOIÁS! ⚽💚
VITÓRIA DO VERDÃO! 💚
```
`fanDemonym`/torcedor, nome do clube e apelido do time tratados como 3 conceitos distintos, nunca misturados só pra reduzir a quantidade de campos.

## 52. Testes obrigatórios da copy

`buildMessage` extraído de `notifications-dispatch/index.ts` pra um módulo puro e testável, `supabase/functions/_shared/notification_message_builder.ts` (`buildNotificationMessage`) — 0 import Deno-specific, 0 I/O, importado de volta pelo `notifications-dispatch` real (nunca duplicado). `supabase/functions/_shared/notification_message_builder.test.ts` (NOVO, 7 testes, vitest): prova `goal title === "GOOOOOOL DO GOIÁS! ⚽💚"` e `victory title === "VITÓRIA DO VERDÃO! 💚"` pra Goiás (com a config REAL, não uma cópia com valores diferentes); prova que a copy vem do `ClubServerConfig` (trocando os campos e vendo o título mudar junto — não um literal hardcoded no builder); prova que empate/derrota nunca vira "VITÓRIA"; e prova, com uma fixture sintética `club-b` (só neste arquivo de teste, nunca registrada em `SERVER_CLUB_REGISTRY`, nunca um clube real nomeado), que a copy do club-b nunca contém `"GOIÁS"`/`"VERDÃO"`.

## 53. Local storage — prova runtime real, matriz completa

Testes Dart REAIS com `SharedPreferences.setMockInitialValues` (não estático) pras 3 stores, cobrindo a matriz mínima pedida (migração Goiás / namespaced vence legacy / isolamento club-b / club-b próprio) — **24 testes novos** (correção de contagem, revisão do usuário: a 1ª versão desta seção somou errado, 5+9+6+4=24, não 27 — conferido também pelo total real do `flutter test`, 841→865=+24 exato):

- `test/features/store/store_local_storage_test.dart` (NOVO, 5 testes) — carrinho.
- `test/features/arena/games/guess_player/data/guess_player_storage_test.dart` (NOVO, 9 testes) — cobre os 3 tipos de valor reais da classe (`int`/`String`/`List<String>`, via `loadStats`/`loadSeenSignature`/`loadSeenIds`), não só 1 chave.
- `test/features/arena/shared/local_best_score_store_test.dart` (NOVO, 6 testes) — recorde por jogo, incluindo Goiás e club-b mantendo recordes independentes pro MESMO `gameId` simultaneamente.
- `test/core/session/local_game_cache_test.dart` (4 testes NOVOS, +ao 3 já existentes) — cleanup: prova que remove as variantes namespaçadas de QUALQUER clube (`goias:`/`club-b:`) + a legacy sem namespace, tudo num único passe; prova que preferências globais (tema/idioma/volume do hino) sobrevivem; prova que a checagem não vira um match acidental amplo demais (uma chave não-relacionada com substring parecida nunca é removida).

Todos os 4 arquivos usam `syntheticClubBConfig` (já existente desde M3.1, `test/core/club/synthetic_club_config.dart`) — nunca um clube real nomeado.

## 54. `ClubBadge`/GetIt — decisão explícita: **KEEP**

Auditado: `sl<T>()` direto na camada de apresentação é o padrão DOMINANTE e consistente deste app (100+ ocorrências em `lib/features/*/presentation/`) — inclusive `calendar_day_cell.dart`/`next_match_hero.dart`/`crowd_lineup_page.dart`, que já fazem exatamente isso com `ClubConfig` desde esta mesma M3.3. A única distinção real de `ClubBadge` é morar em `shared/widgets/` (nenhum outro arquivo dessa pasta usa `sl<T>()`) em vez de `features/*/presentation/` — uma organização de pasta, não uma fronteira arquitetural genuína. Tornar a dependência explícita exigiria editar **19 call sites em 15 arquivos**, nenhum dos quais hoje resolve `ClubConfig` de nenhuma forma — um refactor desproporcional ao problema real (que é só de setup de teste, já resolvido). **Decisão: KEEP**, com a justificativa completa documentada como doc-comment no próprio `club_badge.dart` (citando os 15 arquivos nomeados, pra qualquer revisão futura achar rápido). Custo real pago é só em teste — 4 arquivos (`club_page_test.dart`, `crowd_lineup_page_test.dart`, `compact_match_header_test.dart`, `calendar_day_cell_test.dart`) precisaram de `sl.registerSingleton<ClubConfig>()` no `setUp` (já corrigido na 1ª rodada, ver §46).

## 55. Edge config resolver — prova executável real (não só regex)

`vitest.config.mts` ganhou `supabase/functions/_shared/**/*.test.ts` no `include` — os módulos PUROS compartilhados (0 import Deno-specific) agora rodam sob o MESMO vitest do Worker, sem alterar o runtime real da Edge Function (que continua só existindo de verdade no Supabase/Deno). `supabase/functions/_shared/club_server_config.test.ts` (NOVO, 6 testes): `resolveClubServerConfigByClubId(goiasUuid)` → config do Goiás real (id, canonicalClubId, as 2 strings de notificação); UUID desconhecido/string vazia/malformada → `undefined` (falha controlada); `resolveClubServerConfigByCode('goias')` → sucesso; código desconhecido → `undefined`; `SERVER_CLUB_REGISTRY` tem exatamente 1 entrada. **Nenhuma limitação técnica encontrada** — os módulos `_shared/` não importam nada Deno-specific, então testá-los via vitest não exigiu nenhum workaround além do `include` do config.

## 56. Worker — testes de rota explícitos, novos

Não existiam testes de roteamento HTTP no Worker antes desta rodada (os 69 testes originais eram só de função pura — nenhum um chamava `fetch()`). Adicionados:

- **`src/index.test.ts`** (NOVO, 6 testes) — usa `cloudflare:test` (`env`/`createExecutionContext`/`waitOnExecutionContext`) pra chamar `worker.fetch()` de verdade: `/api/football/team/unknown-club` → **404 real** (sem mockar rede — `resolveClubServerConfig` falha ANTES de qualquer fetch pro OneFootball); `/api/football/team/unknown-club/season` → **404 real**; a mensagem de erro nunca menciona "Goiás"/"goias". `/api/football/team/goias` **continua servido pelo mesmo caminho genérico** — provado 1 passo abaixo do HTTP (a única honestidade possível sem inventar mock de rede novo nesta suíte, que nunca fez isso até hoje): a regex `TEAM_PATTERN` captura `clubCode='goias'` de `/api/football/team/goias`, `TEAM_SEASON_PATTERN` captura `'goias'` de `/api/football/team/goias/season`, e `club_server_config.test.ts` (§55) já prova que `resolveClubServerConfig('goias', env)` resolve com sucesso — logo a rota resolveria e serviria, sem cair em 404. Provar o 200 fim-a-fim exigiria mockar o provider OneFootball, algo que não existe em nenhum teste deste projeto hoje — registrado aqui como limitação honesta, não escondida.
- **`src/football/_lib/club_server_config.test.ts`** (NOVO, 3 testes) — o resolver puro do Worker, mesmo padrão do `_shared/` das Edge Functions (§55): `'goias'` resolve lendo `env.GOIAS_ONEFOOTBALL_SLUG` real (populado do `wrangler.toml` pelo vitest-pool-workers); `'club-b'`/`'juventude'`/`''` lançam `UnknownClubError`; `SERVER_CLUB_CODES` tem exatamente 1 entrada.

**Achado técnico secundário, corrigido**: `tsconfig.json` não reconhecia o módulo ambiente `cloudflare:test` (`npx tsc --noEmit` falhava) — corrigido adicionando `"@cloudflare/vitest-pool-workers/types"` ao array `types` (subpath oficial do pacote, já uma devDependency, nenhuma dependência nova). `src/index.ts`'s `fetch` ganhou o 3º parâmetro `_ctx: ExecutionContext` (assinatura padrão do `ExportedHandler`, já usada por `scheduled` no mesmo arquivo — só faltava em `fetch`, nunca usado dentro da função). Os 2 arquivos de teste novos que chamam `cloudflare:test`'s `env` precisaram de 1 cast explícito cada (`rawEnv as unknown as SocialEnv`/`Env`) — o projeto não gera `worker-configuration.d.ts` via `wrangler types`, então o tipo exportado por `cloudflare:test` é genérico; as vars reais chegam corretas em runtime (populadas do `wrangler.toml`), só o tipo estático precisava do cast.

## 57. Drift checker — `SHARED_IDENTITY_FIELDS` vs `SERVER_ONLY_PRESENTATION_FIELDS`

`audit_multiclub_runtime_hardcodes.mjs`: o drift check agora declara explicitamente as 2 categorias:
```js
SHARED_IDENTITY_FIELDS = ['canonicalClubId', 'oneFootballTeamId', 'code']       // precisam bater nos 3
SERVER_ONLY_PRESENTATION_FIELDS = ['notificationGoalClubName', 'notificationVictoryNickname']  // só Edge Functions
```
`driftFree` continua exigindo os 3 campos de identidade batendo entre Flutter/Worker/Edge Functions — E, novo, que a copy de notificação do Goiás seja exatamente `'Goiás'`/`'Verdão'` (nunca comparada contra Flutter/Worker, que nunca precisam desse campo — Flutter nunca consome essa copy, o Worker não manda notificação nenhuma). Testado explicitamente que `flutterNotificationGoalClubName`/`workerNotificationGoalClubName` nem aparecem no resultado do drift check — nunca uma duplicação forçada sem necessidade real.

## 58. Escopo — confirmado, nada novo tocado

Passaporte, `GOI-`/`order_number`, PK/UNIQUE/DEFAULT Goiás, RLS, `LEGACY_RPC_PUBLIC_EXECUTE_DEBT` — todos continuam exatamente como estavam na 1ª rodada da M3.3 (§29, §33, §34-35, §36). Nenhum 2º clube real em nenhum registry.

---

# Compatibility gate final (2026-09-02) — antes de deploy/commit

## 59. Copy antiga real, via `git show` — nunca inferência

```bash
git show 7316afc:supabase/functions/notifications-dispatch/index.ts
```
Trecho real retornado (`buildMessage`, o HEAD imediatamente anterior a qualquer edição da M3.3):
```ts
case 'goal': {
  return {
    type: 'goal',
    title: 'GOOOOOOL DO GOIÁS! ⚽💚',
    body: `${p.homeTeamName} ${p.homeScore} x ${p.awayScore} ${p.awayTeamName}`,
  };
}
case 'full_time': {
  const home = p.homeScore ?? 0;
  const away = p.awayScore ?? 0;
  const goiasScore = p.goiasSide === 'home' ? home : away;
  const opponentScore = p.goiasSide === 'home' ? away : home;
  const title = goiasScore > opponentScore ? 'VITÓRIA DO VERDÃO! 💚' : 'Fim de jogo';
  const suffix = goiasScore > opponentScore ? ' Fim de jogo!' : '.';
  return {
    type: 'full_time',
    title,
    body: `${p.homeTeamName} ${home} x ${away} ${p.awayTeamName}${suffix}`,
  };
}
```
**Confirmado, os 2 emojis (`⚽💚`/`💚`) já existiam byte-a-byte antes da M3.3** — a M3.3 nunca introduziu emoji nenhum. Cobertura completa dos 5 casos pedidos, todos lidos do MESMO `git show` (nunca por inferência):

| Caso | title (original) | body (original) |
|---|---|---|
| goal | `'GOOOOOOL DO GOIÁS! ⚽💚'` | `` `${home} ${homeScore} x ${awayScore} ${away}` `` |
| victory (full_time) | `'VITÓRIA DO VERDÃO! 💚'` | `` `${home} ${homeScore} x ${awayScore} ${away} Fim de jogo!` `` (sufixo `' Fim de jogo!'`) |
| draw (full_time) | `'Fim de jogo'` | `` `${home} ${homeScore} x ${awayScore} ${away}.` `` (sufixo `'.'`) |
| defeat (full_time) | `'Fim de jogo'` (mesmo ramo do draw — `goiasScore > opponentScore` é a ÚNICA condição, nunca distingue empate de derrota) | mesmo sufixo `'.'` |
| match_access_open sócio | `'Check-in aberto'` | `` `O check-in pra ${opponent} já está disponível.` `` |
| match_access_open não-sócio | `'Ingressos disponíveis'` | `` `Os ingressos pra ${opponent} já estão à venda.` `` |

**1 divergência real encontrada e corrigida** (não era o achado principal do usuário, mas apareceu na comparação linha a linha): o `opponent` de `match_access_open` no original é um ternário de **3 vias** —
```ts
const opponent = p.homeTeamName === 'Goiás' ? p.awayTeamName : p.homeTeamName === undefined ? '' : p.homeTeamName;
```
— a 1ª rodada da M3.3 tinha simplificado pra 2 vias (`p.homeTeamName === clubConfig.shortName ? p.awayTeamName : p.homeTeamName`), o que muda o resultado APENAS no caso teórico de `homeTeamName === undefined` (nunca acontece na prática — sempre vem populado por quem grava o evento): original produz `''` (string vazia, gerando um espaço duplo real no body, uma peculiaridade pré-existente do código publicado), a versão simplificada produzia `undefined` (que o `?? 'o próximo jogo'` downstream trataria diferente). **Restaurado o ternário de 3 vias exato** em `notification_message_builder.ts` — byte-idêntico ao original, peculiaridade incluída, nunca "corrigido"/"melhorado" por conta própria.

## 60. Teste golden de compatibilidade — adicionado

`notification_message_builder.test.ts` ganhou uma seção dedicada "golden compatibility contra o código real pré-M3.3" (8 testes novos) — cada um comparando `title`/`body`/`type` contra os literais exatos extraídos do `git show` acima (goal, vitória, empate, derrota, checkin, tickets, mandante/visitante, e o caso `homeTeamName undefined`) — nunca contra uma reconstrução aproximada.

## 61. Contagem de testes — corrigida

§53 dizia "27 testes novos" pra storage/cleanup — soma errada, os arquivos listados somam `5+9+6+4=24` (conferido também pelo total real `flutter test`: 841→865 = exatamente +24). Corrigido no relatório (§53) — nenhum teste alterado só pra fazer a contagem bater, a correção foi só na prosa do relatório.

## 62. Edge Functions — compile sanity, limitação documentada

`deno` não está instalado neste ambiente — **não fingido** `deno check`. Verificado: não há nenhum comando já configurado no projeto (`package.json`, Supabase CLI local) que faça bundle/typecheck das 3 Edge Functions sem publicar — `npx supabase functions deploy --dry-run` não existe como flag da CLI atual, e não há script `deno.json`/task equivalente no repo. Registrado explicitamente, sem instalar ferramenta global nova só pra isso:
```
EDGE_DENO_STATIC_CHECK_UNAVAILABLE — os 3 entrypoints Deno
(notifications-poll-live-match, notifications-sync-and-check-access,
notifications-dispatch) não têm validação estática disponível neste
ambiente antes do deploy real. Os módulos PUROS que eles importam
(_shared/club_server_config.ts, _shared/notification_message_builder.ts)
JÁ estão cobertos por vitest (§55, §60) — é só a integração Deno-specific
(Deno.serve/Deno.env/imports via esm.sh) que depende da validação do
runtime real no deploy/Supabase.
```

## 63. Mecanismo de deploy do Worker — dúvida real, reportada antes de executar

`package.json` tem `"deploy": "wrangler deploy"` — um comando manual, já configurado, existente no projeto (não inventado agora). Mas a memória deste projeto (`reference_goias_app_cloudflare_worker`, pesquisa de uma sessão anterior) registra o mecanismo de deploy como **"git-push deploy"** — sugerindo que o Cloudflare Pages/Workers está conectado diretamente ao repositório (integração nativa da Cloudflare, sem GitHub Actions — confirmado que não existe workflow de deploy em `.github/workflows/`, só `sync_x_posts.yml`, não relacionado). Isso deixa uma ambiguidade real: se a integração Git nativa da Cloudflare estiver ativa, rodar `wrangler deploy` manualmente PODE ser redundante (a integração já deployaria no próximo push) ou, pior, poderia divergir do que a integração esperaria deployar depois. Não tenho como confirmar de dentro do repositório qual dos dois é o mecanismo real hoje (a configuração da integração Git vive no dashboard da Cloudflare, fora deste código). Por instrução explícita do usuário ("reporte antes de executar se houver dúvida... não alterar pipeline"), não vou rodar `wrangler deploy`/`npm run deploy` sem confirmação — perguntando antes de prosseguir pro deploy do Worker.

## Reexecução completa — pós compatibility gate

```
flutter analyze → 0 issues
flutter test → 865 passed, 1 skip, 0 failed (841 + 24 novos de local
  storage/cleanup — contagem corrigida, ver §61; 0 teste novo Flutter
  nesta rodada de gate, só os 8 golden ficam no lado TS)

tooling/multiclub/test_*.mjs → 663 passando, 0 falhando (inalterado
  nesta rodada de gate)

npm run test:worker (vitest) → 99 passando, 0 falhando (91 da rodada de
  hardening + 8 golden compatibility novos em
  notification_message_builder.test.ts, §60)
npx tsc --noEmit → 0 erros

npx supabase migration list → 46 locais, 46 local=remote, 0 mismatch
  (inalterado — 0 SQL tocado em toda a M3.3)
```

`SECOND_CLUB_BLOCKED=true` reconfirmado. **0 commit, 0 db push, 0 deploy (Worker/Edge Functions) ainda nesta etapa — deploy só depois da decisão do §63.**

---

## `SECOND_CLUB_BLOCKED = true`

Confirmado — nenhuma PK/UNIQUE/DEFAULT tocada, nenhum clube real cadastrado em nenhum dos 3 registries (Flutter `clubRegistry`, Worker `SERVER_CLUB_CODES`, Edge Functions `SERVER_CLUB_REGISTRY`), todos com exatamente 1 entrada.

---

**PARADO PARA REVISÃO (rodada de hardening concluída). Nada commitado, nada aplicado no banco, nada deployado (Worker/Edge Functions).**

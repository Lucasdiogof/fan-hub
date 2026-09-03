# M4.2A — ClubCapabilities reais

Data: 2026-09-03
Escopo desta rodada: audit, implementação Flutter local, testes, tooling, relatório.
Fora de escopo (não feito): 0 db push, 0 Edge deploy, 0 git push, 0 flavor real, 0 Bragantino, 0 tenancy de Passaporte, 0 correção do `GOI-` no SQL, 0 redesign de RLS.

## 1) Capabilities existentes

`ClubCapabilities` (`lib/core/club/club_capabilities.dart`) tinha 6 campos e ganhou +2 nesta rodada:

- `hasMembership`, `hasStore`, `hasTickets`, `hasCrowdLineup`, `hasPassport` — já existiam.
- `hasNews` (NOVO), `hasSocial` (NOVO) — News/Social nunca tinham capability própria; o gate do Worker (feito na M4.1) nunca era alcançado do lado do Flutter (ver item 10).
- `enabledArenaGames: Set<String>` — já existia; não há `hasArena` separado, a visibilidade do hub é derivada (`enabledArenaGames.isNotEmpty`).

Goiás (`goias_club_config.dart`) tem as 8 capabilities `true` (Arena com todos os jogos habilitados). O clube sintético de teste (`syntheticClubBConfig`, nunca registrado em produção) tem as 7 booleanas `false` e `enabledArenaGames: {'quiz'}` — só 1 jogo, provando granularidade por-jogo, não tudo-ou-nada.

## 2) Entry points auditados

Mapeados (com busca no código + leitura direta) todos os pontos de entrada de 9 features em: Home, bottom nav, rail, Perfil, rotas/deep links, repositórios/serviços. Resultado consolidado nos itens 4-10.

## 3) Capabilities adicionadas

`hasNews` e `hasSocial`. Squad e Notifications **não** ganharam capability própria — decisão deliberada, registrada em comentário na própria classe: ambos já são `club_id`-scoped no backend desde M3.1/M3.2, sempre existem como infraestrutura básica de qualquer clube, e nunca teriam um estado "desligado" com sentido de produto hoje.

## 4) Home / menu / Profile

- **Bottom nav** (`goias_bottom_navigation_bar.dart`): novo helper `_navSlot()` — abas desligadas viram `SizedBox.shrink()` dentro do mesmo `Expanded`, preservando a geometria fixa (4 `Expanded` + gap do crest central). Zero risco de "pulo" de layout; Goiás renderiza pixel-idêntico a antes (confirmado pelos 912 testes pré-existentes passando sem alteração).
- **Rail** (`main_navigation_rail.dart`): `for` loop com `if (isTabEnabled(...))`.
- **`isTabEnabled()`** novo em `main_navigation_items.dart`: jogos/home sempre `true`; sócio→`hasMembership`; loja→`hasStore`; mídia→`hasNews || hasSocial`.
- **HomeShellPage**: `IndexedStack` das 3 abas gateáveis (sócio/loja/mídia) passa a computar `FeatureUnavailablePage` no lugar da página real quando desligado — necessário porque essas 3 abas não são rotas reais do GoRouter (todas compartilham `/`), então o gate de rota sozinho não protege.
- **Profile**: linha de endereços de entrega só aparece com `hasStore`; seção "Minha Jornada" monta lista condicional (Arena se `enabledArenaGames.isNotEmpty`, Passaporte se `hasPassport`) e desaparece inteira se vazia; seção "Compras e Serviços" idem (Ingressos por `hasTickets`; Pedidos+Loja por `hasStore`).

## 5) Rotas / deep links

Novo `lib/core/club/capability_route_gate.dart`: função pura `capabilityGateRedirect(location, capabilities)`, sem depender de `BuildContext`/GoRouter, plugada no `redirect` existente de `app_router.dart` (depois de auth/splash/release-gate, antes do `return null` final). Cobre 8 prefixos: 6 rotas de jogo da Arena (por código individual), `/arena/passport`, `/arena` (fallback do hub), `/store`, `/membership`, `/tickets`, `/crowd-lineup`, `/news`. Ordem importa: checagem por-jogo antes do fallback geral `/arena`; `/arena/passport` antes do `/arena` geral (colisão de prefixo). Quando bloqueado, redireciona para `/feature-unavailable` (nova rota, `FeatureUnavailablePage`, tela genérica "Indisponível" — distinta de `ComingSoonPage`, que implica "em breve"). 36 testes unitários dedicados (`capability_route_gate_test.dart`) cobrem Goiás nunca bloqueado, clubB bloqueado exatamente nos 7 grupos + granularidade por-jogo, Squad/Notifications nunca gateados, sem loop de auto-redirect, e 2 casos fabricados (hub vazio bloqueia tudo; jogos-sem-passaporte distingue corretamente `/arena` de `/arena/passport`).

## 6) Passaporte

`hasPassport=false` para o clube sintético. Confirmado que nenhum caminho normal (Home, Perfil, Arena hub, rota direta, deep link) abre a feature para ele. As 12 RPCs de Passaporte **não** foram tenantizadas nesta rodada (`PASSPORT_TENANCY_DEFERRED=true` mantido) — a proteção aqui é só de UI/roteamento, não de backend; se algum código futuro chamar essas RPCs diretamente sem passar pelo gate, o vazamento de dados do Passaporte do Goiás continua tecnicamente possível. Isso é um blocker de produto pré-existente (M4-round-1), não resolvido nem fingido resolvido aqui.

## 7) Store (Loja)

`hasStore=false` para o clube sintético; `StoreEntryCard` na Home só aparece com `hasStore`; rota `/store` gateada; Perfil (Pedidos, Loja, Endereços de entrega) idem. `generate_store_order_number()` (prefixo `GOI-` no SQL) e `store_entry_card.dart` (asset `AppAssets.storeBanner` hardcoded, `Image.asset` direto) **permanecem intocados** — exclusão padrão desde M4.1, reconfirmada aqui. `STORE_SAFE_FOR_CLUB_B=false` continua valendo; a defesa real é "a feature nunca é alcançável para o clube sintético", não "o backend está seguro".

## 8) Membership (Sócio)

`hasMembership=false` para o clube sintético. Aba "Sócio" da bottom nav/rail some via `isTabEnabled`; `HomeShellPage` substitui a página real por `FeatureUnavailablePage` no slot da aba; rota `/membership` gateada. `MembershipPlansCatalog.plans` continua sendo uma lista `static const` hardcoded com preços/nomes reais — não foi tocada; a defesa aqui também é só "inalcançável", não "backend tenant-aware".

## 9) Arena

`enabledArenaGames` filtra o grid de jogos (`ArenaCatalog.games.where(...)`) — cada jogo (quiz/lineup/career-path/guess-player/tactical-identity/player-identity) só aparece se o código estiver no set. `CrowdLineupHero` (Torcida) só aparece com `hasCrowdLineup`; card do Passaporte só com `hasPassport`; cards de Identidade Tática/Identidade do Jogador só se o respectivo código estiver em `enabledArenaGames`. Clube sintético mantém só `{'quiz'}` habilitado, provando que a granularidade é por-jogo e não um único toggle "Arena sim/não".

**2 achados novos, além do que o exemplo do pedido citava:** `TicketFixture` (dados reais de setor/portão/preço do Estádio Goiás, hardcoded, zero scoping) e `SupabaseCrowdLineupRepository._parseCrowd` (resolve votos via `goiasSquad`, lista real hardcoded, incondicional). Nenhum dos dois tinha proteção alguma antes. Por isso `hasTickets=false` e `hasCrowdLineup=false` também foram setados para o clube sintético — não estavam no exemplo do pedido, mas são a mesma classe de bug (conteúdo real do Goiás sem tenancy) e ficariam abertos se eu só tivesse seguido a lista literal.

Classificação: ambos ficam registrados como **`FEATURE_SPECIFIC_BLOCKER`** (blocker de feature isolada, não um blocker geral do produto como os de RLS/Passaporte/Store) — mitigados nesta rodada só por `syntheticClubB.hasTickets=false`/`syntheticClubB.hasCrowdLineup=false` (defesa de UI, feature inalcançável), sem generalizar `TicketFixture`/`goiasSquad` para um repositório real multi-tenant agora. Isso fica para uma etapa própria futura.

## 10) News / Social

O Worker já tinha o gate `?club=` desde a M4.1 (`club_server_config.ts`, `resolveRequestedClubCode`), mas era código morto do ponto de vista do Flutter: `NewsRemoteDataSource`/`SocialRemoteDataSource` nunca mandavam o parâmetro. Corrigido: ambos os data sources agora recebem `ClubConfig` via construtor e mandam `'club': _clubConfig.identity.code` em toda chamada (lista + artigo, para News; feed, para Social). `SocialFeedPage._MediaFilterBar` agora filtra as opções da barra (Notícias/Instagram/YouTube/X) por `hasNews`/`hasSocial`, e o filtro inicial (`_initialFilter()`) escolhe a primeira aba disponível em vez de assumir Notícias.

## 11) Comportamento Goiás

Nenhuma capability desligada para Goiás — todas as 8 continuam `true`. `flutter test` confirma 952 passados / 1 skip / 0 falhas, mesmo total de antes desta rodada (os únicos testes novos são os das próprias features de gate, que testam o clube sintético ou lógica pura) — sem regressão perceptível.

## 12) Comportamento synthetic clubB

7/7 capabilities booleanas `false`; `enabledArenaGames={'quiz'}`; nenhuma delas aparece em Home/menu/Perfil; nenhuma rota direta ou deep link abre a feature real; nenhum repositório cai silenciosamente para dado do Goiás. Nunca registrado em `clubRegistry` — só existe em `test/core/club/synthetic_club_config.dart`.

## 13) Product naming

Re-auditado `ClubProductNaming`: nenhum dos pontos de wiring desta rodada (nav, rotas, Perfil, Arena, News/Social) criou um lugar natural e seguro para consumir nomes de produto sem entrar em redesign de i18n (os textos hoje vêm majoritariamente de `.arb`/l10n, não de string direta). `PRODUCT_NAMING_WIRING_DEFERRED=true` mantido — nenhuma mudança de naming feita.

## 14) Inventário de nomes `Goias*`

Levantamento (via busca no código, ~35 padrões agrupados cobrindo centenas de ocorrências) classificado em 3 categorias, zero renomeações feitas:

- **GENERIC_RUNTIME_NAME** (nome enganoso, comportamento já correto): `GoiasBottomNavigationBar`, `GoiasLoadingBadge`/`GoiasLoadingIndicator` (ambos já leem `ClubConfig` de verdade); `CareerEntry.isGoias`/`ClubHistoryEntry.isGoias` (flags genéricas "é o clube ativo", só com nome específico); testes de infraestrutura multi-tenant que usam `'goias'`/`'club-b'` como únicas fixtures disponíveis.
- **GOIAS_REAL_CONTENT** (dado real, precisaria de tenancy de verdade, não rename): `goiasClubConfig`, `club_registry`/`resolve_active_club` (fallback hardcoded `'goias'`), `goiasSquad`, `goiasPlayers` (215 entradas), `guessPlayerCatalog`, `ArenaColors.goias*` (cores do uniforme hardcoded fora de `ClubConfig.branding`), `PassportMatch.goiasIsHome/goiasScore`, assets reais (crests, vídeos, produtos de loja, músicas de torcida), chave de migração legada `_isGoiasLegacyEligible`.
- **EDITORIAL_GOIAS_CONTENT** (correto ficar como está): dezenas de strings `.arb` (pt/en/es) — "SIGA O GOIÁS", "Parceiros do Goiás", etc.

Nenhuma renomeação feita — fica como etapa futura própria, exatamente como combinado.

## 15) Tooling

`tooling/multiclub/audit_m4_2_club_capabilities.mjs` (NOVO): audita lendo os `.dart` reais — `capabilityConsumers` (10 arquivos esperados), `capabilityUngatedEntryPoints` (Squad/Notifications, lista fechada com motivo), `gatedPrefixes` (8/8), `routerWired`, 7 `*BlockedForSyntheticClub`, `syntheticEnabledArenaGames`, `arenaCapabilityEnforced`, `newsCapabilityEnforced`/`socialCapabilityEnforced`, `socialFeedPageFiltersOptionsByCapability`, `syntheticClubFeatureLeaks`, `requiredTestsExist`, `m4CapabilitiesReady`. `tooling/multiclub/test_m4_2_club_capabilities.mjs` (NOVO, 15 testes) espelha cada seção + 1 teste de reprodutibilidade + 1 fabricado.

Também corrigida a asserção legitimamente superada de `test_second_club_product_readiness.mjs` (`clubCapabilitiesWired`: era `false` na M4-round-1, agora `true` de verdade) — padrão de nota de supersessão já usado antes neste projeto, comentário explicando a mudança, sem reescrever histórico.

**Investigação adicional feita nesta rodada** (não pedida explicitamente, mas necessária pra confiar no relatório): `goiasFallbacksRemaining > 0` em `audit_second_club_product_readiness.mjs`/seção 7 continua passando — confirmado via grep direto em `lib/` que as únicas 3 ocorrências do padrão `AppAssets.(goiasCrest|loginBackground|stadium|matchHero|tacticsBoardIllustration|storeBanner)` são: 8 linhas em `goias_club_config.dart` (a própria definição, mapeando `AppAssets` pra dentro do `ClubConfig` — não é bypass), 1 em `mock_data.dart` (fixture mock, fora do fluxo de produção) e 1 em `store_entry_card.dart` (exclusão padrão já documentada desde M4.1). Nenhuma regressão nova — a asserção `>0` continua correta pelo motivo certo.

## 16) Testes / Gates

- `flutter analyze`: 0 issues.
- `flutter test`: 952 passed, 1 skip, 0 failed.
- JS tooling (`tooling/multiclub/test_*.mjs`, loop completo): 871 passaram, 0 arquivos com falha.
- Worker/Edge: não rodado — nenhum código de Worker/Edge foi alterado nesta rodada (só Flutter + tooling JS local).
- DB: `npx supabase migration list` — 59 local / 59 remoto, 0 pendente. Inalterado.

Testes novos desta rodada: `test/core/club/capability_route_gate_test.dart` (36 testes) e `test/features/home/presentation/widgets/capability_nav_gating_test.dart` (4 testes, com `_FakeAssetBundle` pra contornar assets de teste do clube sintético que nunca foram pensados pra `Image.asset`).

## 17) M4_CAPABILITIES_READY

**`true`** — todas as sub-checagens da tooling (`audit_m4_2_club_capabilities.mjs`) passam: consumidores reais, prefixos de rota cobertos, router de fato ligado, clube sintético sem vazamento em nenhuma das 7 capabilities, Arena/News/Social com enforcement real, testes obrigatórios existindo.

## 18) SECOND_CLUB_TECHNICALLY_SAFE

**Ainda `false`**, sem mudança em relação à M4-round-1 — e isso é esperado, não uma falha desta rodada. `ClubCapabilities` agora impede a UI de sequer oferecer o caminho pra essas features, mas os blockers técnicos de backend continuam de pé e não foram tocados por escopo explícito:

- Passaporte sem tenancy nas 12 RPCs.
- Store com `GOI-` hardcoded no SQL.
- RLS sem isolamento por `club_id` (só por usuário).
- Pipeline de flavor real ainda não implementado.

Notificações **não** entram mais nessa lista — corrigido nesta rodada em relação a uma menção desatualizada que constava aqui antes. Estado real, já aplicado desde a M4.1c: `NOTIFICATION_TOKEN_DELIVERY_CLUB_SCOPED=true`, `NOTIFICATION_MULTICLUB_MODEL_READY=true`, `NOTIFICATION_SCHEMA_APPLIED_LIVE=true`, `NOTIFICATION_EDGE_DEPLOYED_LIVE=true`, `DB=59/59`.

Os 2 achados novos do item 9 (`TicketFixture`, `SupabaseCrowdLineupRepository`→`goiasSquad`) são `FEATURE_SPECIFIC_BLOCKER`, não blockers gerais do produto — mitigados por `hasTickets=false`/`hasCrowdLineup=false` no clube sintético, não generalizados.

M4.2A reduz a superfície de UI, não resolve os blockers técnicos acima.

## 19) DB

59/59, 0 pendente — confirmado ao final desta rodada, sem nenhuma migration criada ou aplicada.

## 20) Confirmação de escopo

**0 db push. 0 Edge deploy. 0 git push.** Nenhum flavor real criado. Bragantino não cadastrado. Passaporte não tenantizado. SQL `GOI-` não corrigido. RLS não redesenhado. Nenhuma renomeação de arquivo/classe feita.

PARE.

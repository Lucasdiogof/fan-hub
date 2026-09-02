# M1 — `ClubContext` + auditoria completa dos acoplamentos ao Goiás (design + fundação mínima, NÃO aplicado)

Data: 2026-09-02
Status: **PARADO PARA REVISÃO. 0 migrations, 0 commit, 0 `git push`, 0 `db push`.**

Nesta rodada nenhum 2º clube foi nomeado, cadastrado ou pressuposto — todos os exemplos usam `<club_code>`/clubA-clubB. `clubRegistry` tem exatamente 1 entrada (`goias`).

---

## 0. Achado prévio importante

Já existe, de uma sessão anterior (01/09/2026, **antes** da série F começar), um conjunto de 5 documentos de design não-implementados: `docs/multiclub/05_goias_hardcodes.md` (catálogo de hardcodes), `08_multiclub_data_contract.md` (modelo de dados), `09_supabase_migration_plan.md` (plano de migration Supabase), `10_club_config.md` (proposta de `ClubConfig`), `11-14_flavors_*`/`juventude_onboarding_plan.md` (flavors — **não usados nesta M1**, e o nome "Juventude" neles é só um exemplo genérico do documento antigo, não uma decisão de produto). Reusei a análise deles como ponto de partida (revalidando cada afirmação contra o código real de hoje, nunca copiando às cegas — 3 das entradas do catálogo `05` já mudaram desde então porque a série F tocou `career_players.dart`/`goias_players.dart`/`lineup_matches`).

**Tensão arquitetural real encontrada, sinalizada explicitamente na seção 24.**

---

## 1. Bootstrap atual

`lib/main.dart` (único arquivo, sem `bootstrap.dart` separado):
```
WidgetsFlutterBinding.ensureInitialized()
→ initializeBrazilTimeZone()
→ Firebase.initializeApp() (best-effort, try/catch, nunca fatal)
→ Supabase.initialize(url, publishableKey, httpClient)
→ setupDependencies() (GetIt)
→ PackageInfo.fromPlatform()
→ SentryFlutter.init(..., appRunner: () => runApp(GoiasApp()))
```
`GoRouter` é construído depois, dentro do `State` (`late final GoRouter _router = createAppRouter(...)`), puxando `SplashGate` do GetIt — que já precisa estar populado.

## 2. GetIt/DI atual

`lib/core/di/injection_container.dart` — **uma função flat só**, `setupDependencies()`, sem módulos por feature. Tudo `registerLazySingleton`/`registerFactory`; nenhum `registerSingleton` eager existia antes desta etapa. `SupabaseClient` NÃO é registrado no GetIt (chamado direto via `Supabase.instance.client` em toda closure).

## 3. Mecanismo atual de env/dart-define

**Não existe `env.json`/arquivo de instruções neste projeto** (diferente de outros projetos do usuário) — confirmado, documentado em `docs/multiclub/01_current_architecture.md`. Padrão real: `String.fromEnvironment(...)` com `defaultValue` hardcoded, 5 ocorrências (`supabase_config.dart` ×3, `sentry_config.dart` ×2) + 1 sem default explícito (`api_client.dart`). **Nenhum flavor existe** — `applicationId`/bundle id/app label únicos, hardcoded em 3 lugares (`AndroidManifest.xml`, `Info.plist`, `pubspec.yaml`).

## 4-5. Proposta de `ClubContext`/registry — implementada

`lib/core/club/` (10 arquivos, nomenclatura `ClubConfig` — mantida do design pré-existente em `10_club_config.md` em vez de `ClubContext`, já que esse documento já era uma proposta madura e testada conceitualmente; `ClubContext` como nome ficaria livre pra uma futura camada de INJEÇÃO/acesso, se um dia justificar):

```
club_identity.dart        -- ClubIdentity (code, slug, displayName, shortName, fanDemonym, canonicalClubId)
club_branding.dart        -- ClubBranding (embrulha AppColors.light/.dark, não substitui)
club_assets.dart          -- ClubAssets (embrulha AppAssets.*, não move arquivo)
club_integrations.dart    -- ClubIntegrations + ClubPickupAddress (OneFootball id/slug, orderPrefix, contato)
club_capabilities.dart    -- ClubCapabilities (flags REAIS, justificadas por runtime encontrado)
club_product_naming.dart  -- ClubProductNaming (arenaName/passportName/storeName/membershipProgramName)
club_config.dart           -- ClubConfig (agrega os 5 acima — nunca um mega-object solto)
goias_club_config.dart     -- const goiasClubConfig = ClubConfig(...) — os MESMOS valores de hoje
club_registry.dart          -- const clubRegistry = {'goias': goiasClubConfig} — só 1 entrada
resolve_active_club.dart    -- resolveActiveClub() — resolver + fail-fast
```

**Nenhum consumidor real migrado** — `AppColors`/`AppAssets`/`Team.isGoias`/`getGoiasSnapshot()`/`ArenaCatalog.games` continuam exatamente como estavam. `ClubConfig` existe, mas hoje só é lido por 1 lugar: o próprio `setupDependencies()` (registro no GetIt).

## 6. Política missing/invalid `APP_CLUB`

Implementada em `resolve_active_club.dart`, exatamente como pedido:
- `APP_CLUB` ausente (vazio) → Goiás, silenciosamente (comportamento de hoje, todo build real).
- `APP_CLUB` presente mas não cadastrado em `clubRegistry` → **fail-fast**, `StateError` com mensagem acionável (cita o valor recebido + clubes disponíveis). Testado com 8 variações plausíveis de digitação/caixa/espaço — nenhuma vaza pro Goiás.

## 7-8. Hardcodes totais / HIGH+CRITICAL

`tooling/multiclub/audit_multiclub_hardcodes.mjs` — **20 hardcodes catalogados, 100% verificados contra o código real hoje** (0 stale — nenhuma entrada citava um padrão que já não existe mais):
```
CRITICAL: 3   HIGH: 4   MEDIUM: 10   LOW: 3
```
**CRITICAL** (colisão de dado, não cosmético): `user_game_item_progress` PK sem club scope, `arena_selected_content` PK ainda mais frágil (nem inclui `item_id`), `supporter_memberships` sem `club_id` (vazaria status de sócio entre clubes). **HIGH**: `Team.isGoias` (fallback por substring, 3 reimplementações independentes e divergentes entre si), `teamToGuess: 'Goiás'` literal no jogo de escalação, rota do Worker `/api/football/team/goias` com nome de clube no contrato de URL, `GOIAS_TEAM_ID=1863` hardcoded na function de detecção de gol.

## 9. Ocorrências do UUID canônico do Goiás

**Zero em `lib/`** antes desta etapa (confirmado por auditoria) — o único lugar onde ele existia era `supabase/migrations/*` (5 arquivos, seeds da fundação canônica) e `tooling/multiclub/*` (registry + scripts). Agora existe **exatamente 1** ocorrência nova, deliberada: `lib/core/club/goias_club_config.dart` — o próprio local centralizado que a M1 existe pra criar. Sanity check automatizado confirma isso permanece verdade a cada rodada da auditoria.

## 10. Branding audit

`AppColors` (`ThemeExtension`) — maioria semântica (`primary`/`secondary`/`background`/`error`/`success`), mas `darkGreen`/`deepGreen`/`ctaGreen`/`gold` têm nome de matiz literal, não papel — candidatos a rename numa etapa própria (não feito aqui, só documentado). 4 hex duplicados fora do Dart (`pubspec.yaml` — ícone adaptativo/splash/web) — não templatizável em runtime, é config de build nativo. `ClubBranding` criado como INVÓLUCRO (mesmos valores, zero mudança visual).

## 11. Assets audit

Sob `lib/assets/` (não `assets/` — declarado assim em `pubspec.yaml`): `branding/` (CLUB_BRAND, 9 arquivos), `club/titles/` (HISTORICAL_CONTENT, ~44 arquivos, 8 competições), `squad/` (FEATURE_CONTENT, 31 fotos), `games/` (FEATURE_CONTENT, 45 arquivos), `store/products/` (FEATURE_CONTENT, ~245 arquivos), `sponsors/` (FEATURE_CONTENT, 26 arquivos), `content/`+`legal/` (FEATURE_CONTENT), `audio/club/` (CLUB_BRAND-adjacente, hinos/músicas), `videos/goias_splash.mp4` (CLUB_BRAND). **Nenhuma pasta `GENERIC_UI` existe** — 100% dos ícones vêm do pacote Material/Cupertino. `ClubAssets` criado como invólucro dos mesmos paths de `AppAssets`.

## 12. Integrations audit

Worker (`src/`) parcialmente env-driven (`GOIAS_ONEFOOTBALL_SLUG` via `wrangler.toml`, correto), mas toda função chamadora tem nome/rota hardcoded (`handleGoiasTeam`, `/api/football/team/goias`, `isGoias` como campo literal no contrato de API). Scraping de notícias amarrado ao site oficial (`goiasec.com.br`) — generalizar exige parser HTML novo por clube, não é config. Redes sociais: handles/KV-keys hardcoded (`TVGoias`, `goiasoficial`, `instagram:goias:latest`).

## 13. Repositories audit

**Zero ocorrência de `.eq('club_id', ...)`/`clubId`/`'goias'` como filtro em `lib/`** — a fundação canônica correta simplesmente não tem consumidor Dart ainda. O acoplamento real é: 3 heurísticas `isGoias` independentes e não-idênticas entre si (`Team.isGoias` usa `'goi'` sem acento, `crowd_lineup_page._isGoiasHome` reimplementa o mesmo check, `passport_match_ticket_v2._isGoias` usa `'goiás'` COM acento — 3 implementações, 3 comportamentos sutilmente diferentes) + `goiasId=1863` hardcoded numa entidade de domínio + `getGoiasSnapshot()` como nome de método central, chamado de 4+ lugares.

## 14. Fallback audit

| Fallback | Classificação | Vazaria pra outro clube hoje? |
|---|---|---|
| `career_players.dart` | GOIAS_SPECIFIC | Sim — dataset inteiro é Goiás, `is_goias` é bool por linha, não filtro |
| `lineup_matches.dart` | GOIAS_SPECIFIC | Sim — `teamToGuess: 'Goiás'` literal |
| `goiasSquad`/`guess_player_catalog.dart` | GOIAS_SPECIFIC | Sim |
| `goias_players.dart` | GOIAS_SPECIFIC | Sim (215 nomes históricos do Goiás) |
| `quiz_questions.dart` | GOIAS_SPECIFIC | Sim |
| Store (`MockStoreRepository`) | GOIAS_SPECIFIC | Sim — cupons `VERDAO10`/`SOCIO15`, banner `goias_store.png` |
| Ticket fixture (sector/preço) | GOIAS_SPECIFIC | Parcial — a PARTIDA vem de dado real, sector/preço são mock genérico |
| `AppColors`/`AppAssets` | GLOBAL (mecanismo) mas GOIAS_SPECIFIC (valor) | Visual — não "vaza dado", mas mostraria marca errada |

**Nenhum fallback foi movido nesta rodada** — M2 é o momento de decidir isolamento real.

## 15. Coverage `lineup_matches` vs `matches` — já respondido nas Etapas E/F7, não repetido aqui.

## 16. Progress/ranking — collision audit (o achado mais crítico da M1)

`tooling/multiclub/audit_multiclub_data_scope.mjs` — **27 tabelas classificadas** (era 26 antes desta rodada de correção — `quiz_questions`, a tabela de CONTEÚDO, estava faltando; só `quiz_question_progress`, a de PROGRESSO, tinha entrado no universo). 100% verificadas contra o schema real, 0 stale.

A fundação canônica (`people`/`clubs`/`player_club_spells`/`player_positions`/`player_club_stats`/`matches`/`match_source_refs`/`player_match_appearances`) está **100% resolvida nos 2 eixos** (row scope E key scope) — confirmado, testado.

Achado extra: `match_source_refs.source_club_id` é só informativo — a unicidade real vem de `unique(source_namespace, source_ref)`, uma convenção de nome de namespace, não uma constraint de banco sobre `club_id`. Não é bug hoje, é um ponto fraco documentado pra quando um 2º clube existir de verdade.

## 16-bis. Endurecimento pós-revisão — ROW_SCOPE × KEY_SCOPE, nunca confundidos (correção obrigatória)

**Correção conceitual central**: a rodada anterior deste relatório concluiu, forte demais, que a série F havia decidido que tabelas editoriais "nunca ganham `club_id`, ficam implícitas por build pra sempre". Isso está ERRADO. A série F decidiu 3 coisas sobre **IDENTIDADE**, nunca sobre **TENANCY**:
- `person_id` = identidade canônica da PESSOA;
- o `id` de cada feature (`career_players.id='tadeu'`, `lineup_matches.id='2021_csa_brB_g4'`) = chave editorial/gameplay, nunca substituída;
- conteúdo editorial não é consumido ao vivo da camada canônica (Opção B/C, F2/F7).

**`club_id` como dimensão de tenancy é ORTOGONAL a essas 3 decisões.** Adicionar `club_id` a `career_players` não transforma `career_players` em domínio canônico, não faz o Career Path consumir `player_club_stats` ao vivo, e não substitui `id` nem `person_id` — só responde "esta LINHA pertence a qual produto/clube". As 3 identidades (feature id, `person_id`, `club_id`) continuam nunca se substituindo.

**Por isso o Supabase compartilhado (decisão já tomada, seção 18) exige um invariante obrigatório**: toda tabela compartilhada cuja linha pertença a um clube específico precisa de forma inequívoca de determinar esse clube — senão, `APP_CLUB=<clubB>` consultando `career_players` retornaria também linhas do Goiás, sem filtro possível. Isso é vazamento cross-club real, não hipotético.

### Matriz completa — 6 tabelas de conteúdo club-specific + a distinção ROW_SCOPE × KEY_SCOPE

| tabela | PK atual | tem `club_id`? | FK real de banco apontando pra ela | RPC dependente | fallback atual | ROW_SCOPE | KEY_SCOPE | classificação |
|---|---|---|---|---|---|---|---|---|
| `career_players` | `id text` (ex. `'tadeu'`) | não | **0** (nenhuma) | `arena_record_score` (case `career_path`) | `career_players.dart` (build-local) | resolvido adicionando `club_id` | **COLISÃO** — PK só `id`, `'tadeu'` não poderia existir em 2 clubes sem PK composta/surrogate | `TENANT_SCOPE_REQUIRED` |
| `guess_players` | `id text` | não | **0** | `arena_record_score` (case `guess_player`) | `guess_player_catalog.dart` | idem | **COLISÃO**, mesmo padrão | `TENANT_SCOPE_REQUIRED` |
| `squad_members` | `id text` | não | **0** | **nenhuma** (confirmado — não alimenta jogo/progresso nenhum) | nenhum fallback Dart próprio | idem | **COLISÃO**, mas SEM cadeia de RPC pra reconciliar — a mais simples das 6 | `TENANT_SCOPE_REQUIRED` |
| `lineup_matches` | `id text` (ex. `'2021_csa_brB_g4'`) | não | **0** | `arena_record_score` (case `lineup`) | `lineup_matches.dart` | idem | **COLISÃO**, mesmo padrão — **permanece explicitamente aqui, corrigindo a contradição da rodada anterior** | `TENANT_SCOPE_REQUIRED` |
| `passport_matches` | `id text` (ex. `'pe_...'`) | não | **2** (`passport_attendances.match_id`, `passport_trajectory.match_id`) | RPCs de passaporte (não detalhadas nesta rodada) | nenhum fallback Dart (Supabase-only) | idem | **COLISÃO** — mas com FK real + schema ASSIMÉTRICO (`goias_is_home`/`goias_score`/`opponent`, nunca `home_club_id`/`away_club_id`) — coexistência de 2 clubes exigiria redesenho, não só uma coluna | **`NEEDS_DECISION`** (única do grupo) |
| `quiz_questions` | `id text` | não | **0** | `arena_record_score` (case `quiz`) | `quiz_questions.dart` | idem | **COLISÃO**, mesmo padrão — estava AUSENTE da 1ª rodada da auditoria, corrigido agora | `TENANT_SCOPE_REQUIRED` |

**Achado central da matriz**: nenhuma das 6 tem FK real de banco apontando pra ela (exceto `passport_matches`, com 2) — a dependência das tabelas de progresso é só CONVENÇÃO/RPC (`arena_record_score` faz `exists(select 1 from <tabela> where id = p_item_id)` sem nenhuma constraint de banco). Isso significa: **adicionar `club_id` a essas 6 tabelas resolve ROW_SCOPE (dá pra filtrar), mas NUNCA resolve KEY_SCOPE sozinho** — a PK continua sendo só `id`. Pra `'tadeu'` existir em 2 clubes sem colidir, seria necessário OU uma PK composta `unique(club_id, id)` (com uma PK surrogate nova, ex. `row_id uuid`) OU outro desenho — nunca `namespace:id` tipo `'goias:tadeu'` (proibido explicitamente — quebraria progress/ranking/RPC/usuários existentes). **Nenhuma dessas mudanças foi implementada nesta rodada — só desenhada e diferenciada.**

### Cadeia progresso ↔ ranking (exemplo `lineup`, mesma lógica pras outras 3 com jogo)

```
lineup_matches (conteúdo)
  ↕ (convenção de id, SEM FK real)
lineup_match_progress (user_id, match_id)  +  arena_selected_content (user_id, game_id='lineup')
  ↕
user_game_item_progress (user_id, game_id='lineup', item_id)  +  score_events (game_id='lineup', item_id)
  ↕
arena_record_score (RPC) — valida item_id contra lineup_matches, SEM filtro de club_id hoje
```
Pra a cadeia inteira ficar consistente, **todo elo precisaria compartilhar o MESMO `club_id`** — adicionar `club_id` só em `lineup_matches` sem propagar pra `lineup_match_progress`/`user_game_item_progress`/`score_events`/à própria RPC deixaria o meio da cadeia sem filtro, reabrindo o vazamento. `squad_members` é a única tabela de conteúdo SEM essa cadeia (nenhum jogo/progresso a referencia).

### 16-ter. ACHADO NOVO (rodada de fechamento) — `UNIQUE(person_id)` é um SEGUNDO eixo de KEY_SCOPE, além da PK legada

KEY_SCOPE não é só a PK. A auditoria foi endurecida pra considerar **PK + UNIQUE + FK-target + suposições de RPC** — não só a chave primária — e cada tabela agora carrega suas constraints estruturadas reais (`primaryKey`/`uniqueConstraints`/`foreignKeys` + os booleanos `rowScopeProblem`/`keyScopeProblem` + a lista `keyScopeSources` no JSON da auditoria).

Isso isolou um segundo problema de KEY_SCOPE que a rodada anterior não tinha separado: **`career_players`, `guess_players` e `squad_members` ganharam, na série F, uma constraint `UNIQUE(person_id)`** (constraints `career_players_person_id_key` / `guess_players_person_id_key` / `squad_members_person_id_key`, confirmadas — não supostas — em `supabase/migrations/20260902140000_add_person_id_to_career_players.sql`, `…160000_add_person_id_to_guess_players.sql`, `…180000_add_person_id_to_squad_members.sql`, cada uma com FK `person_id → people(id)`). As tabelas base (`supabase/career_players.sql` etc.) não têm essa coluna — ela é acrescentada por essas 3 migrations da série F.

Cenário legítimo futuro que essa constraint proíbe hoje:

```
clubA  →  linha com person_id = UUID do jogador X
clubB  →  linha com person_id = MESMO UUID do jogador X   ← BLOQUEADO hoje por UNIQUE(person_id)
```

O mesmo jogador (uma única identidade canônica em `people`) pode legitimamente aparecer no produto de 2 clubes diferentes (jogou pelos dois). Com `UNIQUE(person_id)` cru, isso é impossível — um problema de KEY_SCOPE tão real quanto o da PK-`id`, só que num eixo diferente. As 3 tabelas passam a ter, portanto, **2 fontes de KEY_SCOPE cada** (a PK-`id` legada + o `UNIQUE(person_id)`), ambas registradas no campo `keyScopeSources` do JSON.

**Candidato futuro (M2, NÃO alterado nesta rodada)**: quando essas tabelas virarem multi-tenant, o `UNIQUE(person_id)` deve virar **`UNIQUE(club_id, person_id)` quando `person_id IS NOT NULL`** — nunca `UNIQUE(person_id)` cru. Isso preserva a proteção 1:1 (uma pessoa só aparece uma vez DENTRO de um mesmo clube) sem impedir a mesma pessoa em clubes diferentes. **Nenhuma constraint foi alterada — M2 decide a migration.**

**Contraste importante**: `lineup_matches` NÃO entra nesse eixo — o `person_id` dele vive DENTRO do jsonb de slot (decisão F7), nunca como coluna/constraint de banco, então não há `UNIQUE(person_id)` pra colidir; `passport_matches`/`quiz_questions` também não têm `person_id`. O achado é específico das 3 tabelas de conteúdo "de pessoa".

**Distinção de UNIQUE legítima (não é problema)**: `store_orders.order_number` (`UNIQUE`, alimentado pela sequência global `store_order_number_seq`) e `user_notification_tokens.fcm_token` (`UNIQUE`) são unicidades **globais corretas** — prefixo+sequência e token de device são globais por natureza. A auditoria as marca `global: true` e NÃO as conta como `keyScopeProblem` (candidatas a `KEEP_GLOBAL` na M2). Ou seja: nem toda `UNIQUE` precisa ganhar `club_id` — a auditoria distingue.

### Confirmação de tipo — `club_id UUID`, nunca `text`

Confirmado no schema real (`supabase/migrations/20260902020000_create_clubs.sql`): `clubs.id uuid primary key`, `slug text not null unique` — **são colunas diferentes**. O plano antigo (`09_supabase_migration_plan.md`, agora marcado `HISTORICAL/NEEDS_RECONCILIATION`) propunha `clubs.id text primary key` (slug) — não é mais o schema real. **Toda recomendação de `club_id` desta M1 usa `uuid references public.clubs(id)`, nunca `text references clubs(slug)`** — testado explicitamente (`tooling/multiclub/test_multiclub_foundation.mjs`, grep no próprio script de auditoria confirmando 0 ocorrência de `club_id text references`).

## 17. Auth/user-data implications

`profiles`/`user_addresses` **não têm arquivo `.sql` no repo** (criadas direto no dashboard — achado extra, confirmado via `supabase/account_deletion_cascade_check.sql`, que documenta essa lacuna). Ambas são `USER_GLOBAL_DATA` corretamente — 1 conta pode, tecnicamente, torcer por clubes diferentes sem duplicar perfil. `supporter_memberships` é o ponto real de ruptura (seção 16). `user_notification_tokens`/`preferences` são globais por device — sem problema hoje, mas `preferences` (`matches_enabled`/`tickets_enabled`) precisaria de dimensão de clube se uma conta seguir 2 clubes um dia.

## 18. Recomendação Supabase compartilhado vs separado

**Já era uma decisão explícita anterior** (`09_supabase_migration_plan.md`, linha 3: *"preservando free tier via multi-tenant (club_id), conforme preferência explícita"*) — **compartilhado, 1 projeto só, multi-tenant via `club_id`**. Revalidei o raciocínio contra o estado atual: continua fazendo sentido — a fundação canônica (`people`/`clubs`/etc.) já foi construída exatamente nesse modelo (Etapas B-F7), e criar um Supabase por clube duplicaria `people` (que existe justamente pra NUNCA duplicar identidade entre clubes). **Recomendação mantida: A opção "compartilhado" já vencida, não é uma pergunta em aberto.**

## 19. Cloudflare/API audit

Ver seção 12. Resumo dos achados novos: `COMPETITION_NAME` hardcoded em 4 arquivos (label de exibição, não filtro), `TEAM_NAME_OVERRIDES` é um mapa global sem dimensão de clube (funcionaria mal se 2 clubes disputassem competições diferentes com nomes de adversário conflitantes).

## 20. Notifications audit

**Sem tópicos FCM** (confirmado, zero `subscribeToTopic` no repo) — entrega é 100% por token direto, o que é estruturalmente MAIS fácil de estender com dimensão de clube que um sistema de tópicos seria. Achados: `GOIAS_TEAM_ID=1863` hardcoded na function de poll (decide qual lado marcou gol), copy de mensagem hardcoded (`'GOOOOL DO GOIÁS! ⚽💚'`), canal Android `channel_id: 'goias_matches'`. Nenhuma tabela de notificação tem `club_id`.

## 21. Store/Membership/Tickets audit

| | Real ou mock | Achado |
|---|---|---|
| Store (catálogo) | Mock | Cupons/banner hardcoded, sem `club_id` estrutural (mas também sem catálogo compartilhado pra colidir) |
| Store (pedidos) | Real | `order_prefix` "GOI-" hardcoded na function SQL |
| Membership (assinatura) | Real | Tabela sem `club_id` — CRITICAL, ver seção 16 |
| Membership (planos) | Mock (Dart) | `MembershipPlansCatalog` — nomes/preços 100% Goiás |
| Tickets | Misto | Sector/preço mock, check-in/pedidos reais — `match_id` texto livre em todas as 3 tabelas |

## 22. Arena games/capabilities audit

7 pastas em `lib/features/arena/games/`: **6 são 100% club-specific** (`career_path`, `guess_player`, `lineup`, `player_identity`, `quiz`, `tactical_identity`), **1 é mecânica club-agnostic** (`penalty` — Flame engine, só 1 constante de cor de camisa, hoje **oculto no produto**, não relacionado a clube). `ArenaCatalog.games` é lista Dart fixa, não configurável — `player_identity`/`tactical_identity` nem estão nessa lista, são cards hardcoded à parte em `arena_page.dart`. `ClubCapabilities.enabledArenaGames` modela exatamente esse conceito (não consumido ainda).

## 23. Routes audit

**100% club-agnostic, confirmado** — 81 rotas totais, 0 contém slug/nome de clube. `/clube/*` é a palavra genérica "clube" em português, não o nome do Goiás. Nenhum trabalho necessário aqui, nunca.

## 24. Pergunta arquitetural obrigatória — Supabase compartilhado (já respondida, seção 18) + **tensão real encontrada**

**CORRIGIDO nesta rodada** (a formulação anterior estava forte demais, ver seção 16-bis pra análise completa): `08_multiclub_data_contract.md`/`09_supabase_migration_plan.md` (01/09, antes da série F) planejavam adicionar `club_id` diretamente em `career_players`/`guess_players`/`squad_members`/`lineup_matches`/`passport_matches`. A conclusão anterior deste relatório dizia que a série F havia PROIBIDO isso — **errado**. A série F decidiu sobre IDENTIDADE (`person_id` != feature id != domínio canônico, conteúdo editorial nunca é substituído por consumo ao vivo) — nunca sobre TENANCY. As duas coisas são eixos diferentes, e não há incompatibilidade real nenhuma entre elas.

**Formulação correta**: `club_id` NÃO transforma conteúdo editorial em canônico. `club_id` PODE e provavelmente DEVE existir nas tabelas editoriais que são compartilhadas no mesmo Supabase, exclusivamente pra isolamento multi-tenant. A decisão B da F2 continua 100% preservada — `career_players` continua `EDITORIAL_SNAPSHOT`. Adicionar tenant scope não significa "Career Path passa a consumir `player_club_stats` ao vivo" — são mudanças completamente independentes. O mesmo vale pra F7: `lineup_matches` continua editorial/gameplay-driven, nunca ganha `person_id` dentro de cada slot do jsonb só por causa do multi-club — mas a LINHA da partida pode precisar de `club_id` pra dizer a qual produto/clube ela pertence. Isso não contradiz F7.

## 25. Arquivos/classes propostos — implementados

Ver seção 4-5.

## 26. Mudanças Dart feitas nesta rodada

- `lib/core/club/` — 10 arquivos novos (modelo completo).
- `lib/core/di/injection_container.dart` — 1 registro novo (`sl.registerSingleton<ClubConfig>(resolveActiveClub())`, primeira linha da função) + 2 imports.
- `test/core/club/resolve_active_club_test.dart` — 11 testes novos.
- **Nenhum outro arquivo Dart tocado.** Zero consumidor migrado.

## 27. Migrations propostas

**ZERO geradas/aplicadas.** Proposta conceitual pra M2 (não gerada, tipo CORRIGIDO nesta rodada): `alter table <tabela> add column club_id uuid references public.clubs(id)` — nunca `text references clubs(slug)` (ver seção 16-bis, confirmado contra o schema real). Aplicável em princípio às 27 tabelas auditadas que não são `GLOBAL` — **incluindo as 6 tabelas de CONTEÚDO editorial** (career_players/guess_players/squad_members/lineup_matches/passport_matches/quiz_questions), não só infraestrutura — mas cada uma precisa de uma 2ª decisão de design (PK composta vs surrogate) antes de virar migration real, porque `club_id` sozinho resolve ROW_SCOPE mas não KEY_SCOPE (ver matriz, seção 16-bis). `passport_matches` além disso precisa de uma decisão de PRODUTO (schema assimétrico), não só técnica.

## 28. Compatibility gate Goiás

Confirmado, testado: com `APP_CLUB` ausente **ou** `APP_CLUB=goias`, `resolveActiveClub()` retorna literalmente o mesmo objeto (`same(goiasClubConfig)`, teste explícito) que carrega os MESMOS valores de sempre (mesmo UUID, mesmo `oneFootballTeamId=1863`, mesmas cores via `AppColors.light`/`.dark`, mesmos assets via `AppAssets.*`). `flutter test` completo (769 testes, incluindo o widget-smoke-test `App renders without crashing`) confirma zero regressão.

## 29. Testes anti-vazamento

`resolve_active_club_test.dart` — teste crítico explícito rodando 8 variações de código inválido (`goia`, `goiass`, `GOIAS`, `' goias'`, `'goias '`, `other-club`, `unknown-club`, `'0'`) confirmando que **nenhuma** resolve pro Goiás nem lança silenciosamente — todas fazem `throwsStateError`. Mensagem de erro testada como acionável (cita o valor recebido + clubes disponíveis). **Endurecimento (rodada de fechamento)**: os códigos inválidos e as chaves negativas do teste de `clubRegistry` deixaram de citar qualquer clube real (antes usavam `juventude`/`bragantino` como exemplos) — agora usam placeholders neutros (`club-b`/`other-club`/`placeholder_club`), pra o teste ficar coerente com o invariante "nenhum 2º clube foi nomeado/cadastrado/pressuposto na M1".

## 30. Tooling

`audit_multiclub_hardcodes.mjs` (20 hardcodes, verificados contra código real, com 4 sanity checks estruturais automatizados) + `audit_multiclub_data_scope.mjs` (**27 tabelas**, verificadas contra schema real, agora com constraints estruturadas por tabela — PK/UNIQUE/FK + `rowScopeProblem`/`keyScopeProblem`) + `test_multiclub_foundation.mjs` (**25 testes** — os 21 anteriores + 4 do endurecimento desta rodada: invariante da soma-das-classificações=27, o achado `UNIQUE(person_id)` como 2º eixo de KEY_SCOPE, o contraste com `lineup_matches` e a confirmação de que UNIQUE global legítima não é falso-positivo).

## 31. JS total

**519 passaram, 0 falharam** (494 pré-M1 + 25 em `test_multiclub_foundation.mjs` = 15 da 1ª rodada + 6 da correção pós-revisão + 4 do endurecimento de fechamento desta rodada).

## 32. `flutter analyze`

**0 issues.**

## 33. `flutter test`

**769 passed, 1 skip** (era 758/1, +11 novos — todos em `resolve_active_club_test.dart`).

## 34. `git diff --stat` / `git status`

```
 docs/multiclub/09_supabase_migration_plan.md                    | 10 +++++
 lib/core/di/injection_container.dart                            |  8 +++-
 lib/features/store/presentation/widgets/store_entry_card.dart   |  2 +-  (pré-existente, não tocado)
```
```
 M docs/multiclub/09_supabase_migration_plan.md   (nota de supersessão adicionada, seção 24 do pedido de correção)
 M lib/core/di/injection_container.dart
 M lib/features/store/presentation/widgets/store_entry_card.dart   (pré-existente)
?? _competitions_pkg/                                              (pré-existente)
?? data_export/goias/player_reconciliation/multiclub_data_scope_audit.json
?? data_export/goias/player_reconciliation/multiclub_data_scope_audit_stats.json
?? data_export/goias/player_reconciliation/multiclub_hardcode_audit.json
?? data_export/goias/player_reconciliation/multiclub_hardcode_audit_stats.json
?? docs/multiclub/19_etapa_e_v4_applied_report.md                  (pré-existente)
?? docs/multiclub/28_etapa_m1_report.md
?? lib/core/club/
?? migration_dump.txt                                              (pré-existente)
?? test/core/club/
?? tooling/multiclub/audit_multiclub_data_scope.mjs
?? tooling/multiclub/audit_multiclub_hardcodes.mjs
?? tooling/multiclub/test_multiclub_foundation.mjs
```

## 35. Sequência recomendada M2/M3/M4 (M2 redefinida nesta rodada)

### M2 — Tenant Scope & Legacy Key Compatibility

**Objetivo**: projetar (e só depois migrar) o isolamento por clube no Supabase compartilhado **sem quebrar IDs legacy** — abrangendo conteúdo club-specific (as 6 tabelas da matriz, seção 16-bis) **e** progresso/ranking/membership/notifications/tickets/votes/sessions juntos, como uma única cadeia (não 2 problemas separados como a versão anterior deste relatório sugeria).

**1ª subetapa obrigatória de M2**: AUDITAR constraints/RPC/RLS de cada tabela em detalhe (a matriz da seção 16-bis é o ponto de partida, não o resultado final) **antes** de gerar qualquer migration. Em particular, decidir por tabela: PK composta `unique(club_id, id)` vs. PK surrogate nova (`row_id uuid` + `unique(club_id, legacy_id)`) — nunca namespacing de id (`'goias:tadeu'`, proibido — quebraria progress/ranking/RPC/usuários existentes). `passport_matches` precisa de uma decisão de produto separada (schema assimétrico) antes de entrar nessa migration.

**Preserva obrigatoriamente**: `supporter_memberships` CRITICAL (seção 16-bis) fica dentro do escopo de M2. `lineup_matches` fica dentro do escopo de M2 (nunca excluída por causa de F7 — F7 é sobre identidade de jogador no slot, não sobre tenancy da linha).

- **M3 — conectar a fiação**: migrar os 3 `isGoias` duplicados pra `isOurClub(team, config)`, `Team.goiasId`→`ClubConfig.integrations.oneFootballTeamId`, `club_badge.dart`, `getGoiasSnapshot()`→`getClubSnapshot(...)`, `ArenaCatalog.games` lendo `ClubCapabilities.enabledArenaGames`. Zero clube novo, zero mudança visual — só elimina hardcode, prova que `ClubConfig` funciona com consumidores reais. (Inalterada nesta rodada de correção.)
- **M4 — só depois de M2+M3 provados**: pipeline de flavor real (Android/iOS/web, `docs/multiclub/11-13`) + generalização do Worker (rotas/Edge Functions por `club_id`) — e só então avaliar onboarding de um clube real (decisão de produto separada, não parte desta fundação).

### Release gate futuro (registrado, não implementado)

Quando existir o 1º segundo flavor real, cada pipeline de release deverá passar `APP_CLUB=<clube esperado>` explicitamente — nunca depender do default Goiás. O default (seção 6) é compatibilidade temporária enquanto só existe 1 clube, nunca o mecanismo final de flavor.

## 36. Confirmação — F1-F7 permanecem semanticamente intactas

Nenhum arquivo das Etapas F1-F7 foi tocado nesta rodada de correção (mesma confirmação da rodada anterior, revalidada). A correção desta rodada é só de FRAMEWORK CONCEITUAL — nunca reabriu nenhuma decisão de identidade da série F. `career_players` continua `EDITORIAL_SNAPSHOT` (F2, Option B). `lineup_matches` continua editorial/gameplay-driven, `person_id` continua nunca entrando no jsonb de slot (F7, Option C). O que mudou é só o entendimento de que `club_id` (tenant scope) é um eixo diferente de `person_id` (identidade canônica) — nenhuma decisão F1-F7 foi revertida, só uma conclusão MINHA (não da série F) foi corrigida.

## 37. Docs antigos — status atualizado

`09_supabase_migration_plan.md` — nota adicionada no topo: **`HISTORICAL / NEEDS_RECONCILIATION`**, apontando os 2 pontos concretos superados (tipo de `clubs.id`, rotulagem 🟢 "simples" das tabelas de conteúdo). `08_multiclub_data_contract.md`/`10_club_config.md` **não foram tocados** nesta rodada — `08` continua conceitualmente válido no nível GLOBAL/CLUB-SCOPED/RELACIONAMENTO (só o detalhe de tipo em `09` estava errado), `10` já é literalmente a base do que foi implementado em `lib/core/club/`, sem necessidade de nota.

---

## Limites respeitados

- 0 migrations, 0 `db push`, 0 commit, 0 `git push`.
- Nenhum flavor nativo criado, nenhum ícone/splash/bundle id tocado.
- `clubRegistry` com exatamente 1 entrada (`goias`) — nenhum 2º clube nomeado, cadastrado ou pressuposto.
- Nenhum consumidor real migrado pra `ClubConfig` (só o registro no GetIt, inalterado desde a 1ª rodada).
- F1-F7 semanticamente intactas — confirmado seção 36.
- M2/M3/flavors não iniciados.

---

**PARADO PARA REVISÃO. Nada aplicado além da fundação Dart descrita — ainda NÃO commitado, aguardando autorização.**

# M4 — Second Club Product Readiness (round 1: AUDIT + GAP ANALYSIS + DESIGN)

Data: 2026-09-03
Status: **AUDITADO. 0 clubB cadastrado. 0 mudança grande aplicada.**

Autorizada logo após a M2.2B-B e o fix pré-M4 da Arena fecharem e sincronizarem (`HEAD==origin/main==7147d13`, `KEY_SCOPE_FINAL=true`, `M4_BLOCKED_BY_ARENA_RPC_FIX=false`).

---

## 1. Preflight

`HEAD == origin/main == 7147d13` confirmado. `git status` limpo (só exclusões-padrão + leftovers legítimos de rodadas anteriores). `npx supabase migration list`: **57 local = 57 remote, 0 pending**.

## 2. Definição histórica da M4 — reconciliada, não redefinida silenciosamente

`docs/multiclub/28_etapa_m1_report.md §35`: *"M4 — só depois de M2+M3 provados: pipeline de flavor real (Android/iOS/web) + generalização do Worker (rotas/Edge Functions por club_id) — e só então avaliar onboarding de um clube real (decisão de produto separada)."* `docs/multiclub/34_etapa_m2_2b_report.md §46`: *"M4 — flavors / Worker / 2º clube real."*

**M4_ALREADY_PLANNED**: pipeline de flavor Android/iOS/Web (`docs/multiclub/10-13`, propostas de 2026-09-01, nada implementado); `ClubIntegrations.orderPrefix` → SQL (doc 34 §28); "2º clube real" como decisão de produto separada.

**Divergência real com a documentação antiga**: a "generalização do Worker/Edge por `club_id`" já ADIANTOU muito além do previsto em M1 — foi majoritariamente feita na M3.3 (rotas `/team/:clubCode`, registries Worker+Edge). Mas os docs antigos **nunca mencionaram** um threat model formal, uma decisão de AUTH_SCOPE, uma classificação RLS user-vs-club, ou uma `ClubCapabilities` matrix — essas são exigências **novas** desta rodada, não uma continuação do que M1 já havia especificado. Classificação: **NEWLY_DISCOVERED_PRE_M4_GAP**, a maior parte do conteúdo desta auditoria.

**DEFERRED_BY_DESIGN** (permanece assim, reconfirmado): Passaporte (`PASSPORT_TENANCY_DEFERRED=true`), 2º clube real em si.

## 3. Matriz de readiness

| Dimensão | Status | Evidência-chave |
|---|---|---|
| DATABASE_ROW_SCOPE | **READY** | 24-26 tabelas com `club_id`, 0 null/wrong/orphan (M2.2A-M2.2B-B) |
| DATABASE_KEY_SCOPE | **READY** | `KEY_SCOPE_FINAL=true`, 18/18 chaves legacy removidas (M2.2B-B) |
| AUTH_SCOPE | **BLOCKED** (hardening, não vazamento entre usuários) | 0 validação server-side liga request→clube permitido; ver §4 |
| RLS | **BLOCKED** p/ isolamento de clube — **READY** p/ isolamento de usuário | 52/52 policies em tabelas tenant-scoped usam só `auth.uid()=user_id`, 0 referenciam `club_id` |
| RPC | **READY_WITH_SYNTHETIC_TEST** (9 `_for_club`) / **BLOCKED** (Passaporte) | Ver §7 |
| EDGE_FUNCTIONS | **BLOCKED** | `notifications-dispatch` não filtra destinatários por clube — ver §20 |
| WORKER | **READY_WITH_SYNTHETIC_TEST** (futebol) / **BLOCKED** (news/social) | Ver §19/§21 |
| FLUTTER_CONFIG | **BLOCKED** | `ClubConfig.branding/capabilities/productNames` têm 0 consumidores reais; múltiplos bypass hardcodes — ver §10 |
| FLUTTER_REPOSITORIES | **READY** | 74 call sites, 100% cobertura nas tabelas com `club_id`, 0 gaps reais — ver §8/§9 |
| LOCAL_STORAGE | **READY_WITH_SYNTHETIC_TEST** (3 stores do app) / **BLOCKED** (sessão Supabase) | Ver §27 |
| DEEP_LINKS | **OUT_OF_SCOPE** | Nenhuma infra de deep link nativo existe ainda (nem Android nem iOS) |
| NOTIFICATIONS | **BLOCKED** | Mesmo achado do EDGE_FUNCTIONS |
| STORE | **BLOCKED** | Catálogo estático Dart, `'GOI-'` hardcoded em 2 lugares, contato/endereço bypassam `ClubConfig` |
| MEMBERSHIP | **BLOCKED** (só pelo contato hardcoded) | RPC/tabela tenant-ready; `MembershipContactConfig` duplica valor já existente em `ClubConfig.integrations` |
| TICKETS | **READY** | Chaves finais (M2.2B-B), RPC check-in tenant-aware, RLS user-isolada |
| ARENA | **READY** | RPC corrigida (rodada anterior), `key_scope_collision` guard mantido |
| CURRENT_SQUAD | **READY_WITH_SYNTHETIC_TEST** | `squad_members` tenant-scoped; `club_history_entry.isGoias` é bug menor, não bloqueia leitura/escrita |
| CONTENT (quiz/career/guess/lineup) | **READY** | `ClubScopedFallback` nunca resolve a um clube default; `ClubDataUnavailableException` confirmado como o comportamento real quando Supabase está vazio e não há fallback — nunca cai pro conteúdo do Goiás |
| ASSETS | **BLOCKED (crítico)** | Praticamente todo asset visual usa `AppAssets.<literal>`, não `ClubConfig.assets` — ver §30 |
| BRANDING | **BLOCKED** | `ClubBranding`/`AppColors` — 0 consumidores via `ClubConfig` |
| PRODUCT_NAMING | **BLOCKED** | `ClubProductNaming` — 0 consumidores; nomes ainda hardcoded no l10n |
| EXTERNAL_INTEGRATIONS | **BLOCKED** | Ver §18 |
| PASSAPORTE | **DEFERRED / BLOCKED se ativado** | 0 tenancy, RPCs com EXECUTE `PUBLIC`/`anon`/`service_role`=true — ver §25 |
| RELEASE_GATE | **READY** | `UNIQUE(club_id,platform)`, Flutter já lê `.eq('club_id', ...)` |
| OBSERVABILITY | **NÃO VERIFICADO NESTA RODADA** | Sentry é usado no projeto, mas nenhum agent/consulta confirmou (ou não) tagging por clube nos eventos — gap de evidência, não veredito |
| WEB/PWA | **BLOCKED** | `web/manifest.json`/`index.html` ainda são o placeholder padrão do Flutter, sem `APP_CLUB` no build web |
| ANDROID | **BLOCKED** | 0 `productFlavors`, `applicationId`/label únicos e hardcoded |
| IOS | **BLOCKED** | 0 configuration extra, bundle id/display name únicos e hardcoded, 0 `.entitlements` |
| SUPABASE_ARCHITECTURE | **READY (decisão confirmada, não invalidada)** | Nenhuma evidência de suposição de banco separado por clube; toda tabela/RPC audita por `club_id` dentro do mesmo projeto |

## 4. AUTH_SCOPE — o que `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` significa hoje

1. **Um usuário autenticado consegue enviar arbitrariamente outro `club_id` numa request?** Sim. Nem RLS (só valida `auth.uid()=user_id`) nem as RPCs `_for_club` (só validam que o `club_id` existe em `clubs`) impedem isso.
2. **As RPCs `_for_club` confiam em `p_club_id` vindo do cliente?** Sim, confirmado nas 9 (inventário §7).
3. **Existe validação server-side ligando request/app → clube permitido?** Não — nenhum JWT claim, nenhuma coluna `profiles.club_id`, nenhuma policy RLS referencia `club_id`.
4. **Isso é requisito para segundo clube ou só hardening futuro?** Depende do modelo de produto (§5). No **Modelo C** (o que o código já constrói), isso é o comportamento ESPERADO — um usuário pode legitimamente usar qualquer app/clube com a mesma conta, e cada request carrega o `club_id` que o app ativo decide. Não é um requisito para um clubB **controlado/sintético**; é hardening de defesa em profundidade antes de um clubB **público**, para impedir alguém com um token válido de ler/gravar via requests manuais (Postman/curl) fora do clube que o app pretendia.
5. **Ameaça real**: baixa-moderada. RLS ainda impede Alice de ver dados de Bob sob QUALQUER `club_id`. O que falta é impedir Alice de ler/gravar seus PRÓPRIOS dados sob um `club_id` que o app dela não pretendia usar — mais uma questão de integridade de produto (misturar ranking do clube A com o B) que uma exposição de dados de terceiros.
6. **O isolamento precisa ser per-user/per-session/per-JWT/per-app/per-request?** **Per-app/per-request** — é isso que `APP_CLUB → ClubConfig → request club_id` já constrói. Não há (nem deveria haver, dado o modelo) um vínculo permanente usuário→clube.

## 5. Threat model — Modelo C confirmado pelo código

Nenhuma coluna `profiles.club_id`, nenhum JWT claim de clube, sessão Supabase Auth compartilhada por projeto (não por clube) — o modelo já sendo construído é o **Modelo C: "instalação/app define o clube, conta é global"** (`APP_CLUB` dart-define → `ClubConfig` → toda request carrega `club_id` explícito). Não inventei `active_club` em JWT/RLS — é uma leitura direta da arquitetura existente, não uma proposta nova.

## 6. RLS — USER_ISOLATION confirmado, CLUB_ISOLATION não existe

Consulta direta a `pg_policies`: **52 policies em 23 tabelas tenant-scoped, 0 referenciam `club_id`** — todas usam `auth.uid() = user_id` (ou `qual=true` para conteúdo público de leitura, ou `qual=false` para tabelas só-service_role). Isso **protege Alice de Bob**, mas não impede Alice+clubA de coexistir com Alice+clubB na mesma policy — não é automaticamente uma vulnerabilidade (depende do Modelo C acima, onde isso é esperado), mas é uma classificação real: `USER_ISOLATION=true`, `CLUB_ISOLATION=false` ao nível de banco. O isolamento de clube hoje é **inteiramente responsabilidade da aplicação** (confirmada 100% correta pela auditoria de repositórios, §9), não do banco.

## 7. Inventário completo de RPCs (36 funções em `public`)

| Categoria | RPCs | Achado |
|---|---|---|
| `_for_club` (9) | `arena_my_rank_for_club`, `arena_ranking_for_club`, `arena_record_score_for_club`, `arena_user_detail_for_club`, `create_store_order_for_club`, `crowd_lineup_for_club`, `get_my_membership_for_club`, `subscribe_to_plan_for_club`, `upsert_membership_checkin_ticket_for_club` | Todas `authenticated=true`, `anon=service_role=public=false`. Todas confiam em `p_club_id` do cliente (`CLIENT_SUPPLIED_CLUB_TRUST`, consistente com o Modelo C). Todos os filtros de tabela conferidos — `CORRECT`, incluindo `arena_record_score_for_club` já corrigida na rodada anterior. |
| Legacy retiradas (8) | `arena_my_rank`, `arena_ranking`, `arena_record_score`, `arena_user_detail`, `create_store_order`, `crowd_lineup`, `get_my_membership`, `subscribe_to_plan` | Todas `anon=authenticated=service_role=public=false` — confirmado ainda revogadas (M2.2B-B). |
| **Passaporte (12)** | `passport_attendance_breakdown`, `passport_attended_matches`, `passport_matches_for_year`, `passport_memorable_match_id`, `passport_my_attendances_for_year`, `passport_my_rank`, `passport_ranking`, `passport_save_attendances`, `passport_seasons`, `passport_set_memorable_match`, `passport_stadium_summary`, `passport_summary` | **Achado não documentado antes**: todas com `anon=authenticated=service_role=public=true` — EXECUTE aberto pra literalmente qualquer role, incluindo `anon` não autenticado. Nenhuma recebe `p_club_id`. `MISSING_CLUB_FILTER` (estrutural — a tabela não tem a coluna) + ACL incomum (mais aberta que qualquer outra RPC do projeto). |
| Globais intencionais (7) | `cpf_is_taken`, `delivery_address_*` (2), `generate_store_order_number`, `handle_new_user`, `list_unconfirmed_signups_for_cleanup`, `rls_auto_enable` | `GLOBAL_INTENTIONAL` — nenhuma toca dado tenant-scoped. |

## 8-9. Cobertura de leitura/escrita direta (Flutter → PostgREST)

74 call sites inventariados (53 `.from()` + 21 `.rpc()`) em todo `lib/`. **Direct read/write tenant coverage nas tabelas que JÁ têm `club_id`: 100% (39/39 leituras, 20/20 escritas)**. **0 gaps reais de código** — nenhum caso de tabela com `club_id` sendo lida/escrita sem o filtro. `arena_record_score_for_club` (já corrigida) confirmada correta de novo por esta varredura independente.

**Achado novo — gap de schema, não de código**: `club_transparency_topics`, `club_transparency_documents`, `club_board_sections`, `club_board_members`, `membership_faq_categories`, `membership_faq_items` — conteúdo editorial "do clube" sem coluna `club_id` no banco, nunca tocado por nenhuma migration `add_multiclub_*`. Decisão de produto pendente: precisam de tenancy real (como `career_players`) ou são boilerplate compartilhado de propósito?

## 10. `ClubConfig` — cobertura real vs. decorativa

`ClubConfig` tem 5 sub-objetos (`identity`, `branding`, `assets`, `capabilities`, `integrations`) + `productNames`. Consumo real auditado por grep:

- `.identity` — **amplamente consumido** (22 arquivos) — a única parte realmente funcional hoje.
- `.assets` — **1 único consumidor** (`club_badge.dart`).
- `.integrations` — **1 único consumidor** (`calendar_day_cell.dart`, via `oneFootballTeamId`).
- `.branding`, `.capabilities`, `.productNames` — **0 consumidores em `lib/`**.

**Hardcodes fora do `ClubConfig` que deveriam estar dentro** (achados novos, nenhum rastreado por tooling anterior):

| # | Achado | Classificação |
|---|---|---|
| 1 | `MembershipContactConfig` duplica o mesmo WhatsApp já em `ClubConfig.integrations` | `MUST_CONFIG_BEFORE_CLUB_B` |
| 2 | `PickupInformation` hardcoda o endereço da loja Goiás como default do construtor, idêntico ao `ClubIntegrations.pickupAddress` que já existe e nunca é lido | `MUST_CONFIG_BEFORE_CLUB_B` |
| 3 | `SocialLinksData` (+ duplicata em `social_empty_state.dart`) — URLs sociais Goiás, sem NENHUM campo em `ClubIntegrations` pra isso | `MUST_CONFIG_BEFORE_CLUB_B` (gap real de contrato, não só de fiação) |
| 4 | `MaterialApp(title: 'Goiás EC')` | `MUST_CONFIG_BEFORE_CLUB_B` |
| 5 | `passport_match_ticket_v2.dart:215` — 3ª reimplementação independente de "é o clube ativo" via string match (`'goiás'`), nunca migrada pro `Team.matchesClub` canônico (as outras 2 ocorrências históricas já foram corrigidas) | `MUST_CONFIG_BEFORE_CLUB_B` — bug real, não hipotético |
| 6-9 | Ícone/splash/label Android/iOS/manifest — configs globais únicas, sem mecanismo de flavor | `MUST_CONFIG_BEFORE_CLUB_B` (ver §14-16) |
| 12-15 | Enum `QuizDifficulty`/`PassportLevel` com nomes de marca; ~45 chaves l10n com "Goiás"/"Esmeraldino" hardcoded, incluindo as poucas que mapeiam 1:1 pra `ClubProductNaming` já existente | `DEFERRED` (cosmético, não quebra funcionalmente) / `MUST_CONFIG_BEFORE_CLUB_B` (só as chaves ligadas a `ClubProductNaming`) |

## 11-12. Hardcode sweep + fallback audit

Nenhum fallback silencioso pra Goiás foi encontrado em: `resolveActiveClub` (falha loud confirmada, ver §13), `ClubScopedFallback` (nunca resolve default, `forClub` devolve `null`), Worker (`UnknownClubError`→404), Edge (`club_id` desconhecido → sessão pulada). **O fallback problemático real está nos ASSETS** (§30) — não é um "fallback" no sentido de código condicional, é a AUSÊNCIA de qualquer condicional: os paths são literais fixos, então tecnicamente "sempre resolvem pro Goiás" porque nunca há uma decisão a se tomar.

## 13. Recomendação `APP_CLUB` default

Manter o comportamento atual (`APP_CLUB` ausente → Goiás) **apenas como compatibilidade do flavor Goiás existente** — nunca generalizar essa regra pra exigir que TODO build futuro declare `APP_CLUB` explicitamente (quebraria scripts/CI atuais sem necessidade). Um flavor `clubB` real, uma vez implementado, sempre passaria seu próprio `--dart-define=APP_CLUB=club-b` explicitamente — o caminho vazio nunca seria exercitado por ele. O comportamento de falha loud pra valor explícito desconhecido já está correto, não precisa mudar.

## 14-16. Flavor gaps (design, nada implementado)

**Android** (`docs/multiclub/11_flavors_android.md`, ainda válido): 0 `productFlavors`, `applicationId` único hardcoded, `android:label` literal no manifest (não `@string`), `google-services.json` único, sem assinatura de release configurada (gap pré-existente).
**iOS** (`docs/multiclub/12_flavors_ios.md`, ainda válido): 1 scheme só, `CFBundleDisplayName`/`CFBundleName` literais, `GoogleService-Info.plist` único, 0 arquivo `.entitlements` (push capability não versionada).
**Web** (`docs/multiclub/13_flavors_web.md`, ainda válido — achado extra confirmado de novo por agent 1): `manifest.json`/`index.html` ainda são o placeholder padrão do `flutter create`, nunca customizados nem pro próprio Goiás.

Classificação unificada: **REQUIRED_FOR_SECOND_CLUB** os 3 (nenhum é nice-to-have — sem eles, um clubB "app" seria literalmente o mesmo pacote/bundle instalado, reescrevendo o Goiás no aparelho).

## 17. Supabase architecture

Confirmado: projeto único, auth único, schema único, separação por `club_id`. Nenhuma evidência de suposição de banco separado — toda tabela/RPC tenant-scoped já assume esse modelo. **Nenhuma mudança recomendada.**

## 18. DB `clubs` registry — mínimo hoje

Schema real: `id uuid`, `slug text`, `name text`, `short_name text`, `created_at`, `updated_at`. **Nenhuma coluna de branding/integração** — o registro no banco é só o ANCORA de identidade (FK de `club_id` em todo lugar), não um registry completo. Branding/integrations vivem só em `ClubConfig` (Flutter), `SERVER_CLUB_CODES` (Worker) e `SERVER_CLUB_REGISTRY` (Edge) — **4 registries fisicamente separados, não 1**. Source-of-truth strategy recomendada: `clubs` (DB) continua sendo a âncora de identidade (é a única coisa que uma FK pode referenciar); os outros 3 continuam operacionais/locais a cada runtime, mas TODOS devem concordar no `code`/`slug` e no `id` — o que já é verificado pelo drift check existente (ver §19).

## 19. Registry drift

Tooling já existe (`audit_multiclub_runtime_hardcodes.mjs`, criado na M3.3): confere Flutter↔Worker↔Edge (`canonicalClubId`, `oneFootballTeamId`, `code`) — hoje `driftFree=true` (trivial com 1 clube). **Gap real**: esse check NUNCA inclui a tabela `clubs` do banco como 4º ponto — só compara os 3 registries de código entre si. Antes de um clubB real, o check deveria também confirmar que o `id`/`slug` em `clubs` bate com o `canonicalClubId`/`code` usado nos 3 registries de runtime.

## 20-21. Edge Functions + Notifications — achado crítico

5 funções auditadas (não só as 3 conhecidas): `cleanup-unconfirmed-signups`, `delete-account` (globais por design, corretas), `notifications-poll-live-match`, `notifications-sync-and-check-access` (`CLUB_CONFIGURED`, corretas), **`notifications-dispatch` (achado sério)**:

- `fetchRecipientTokens` busca `user_notification_tokens` filtrando só `is_active=true` — **sem NENHUM filtro de clube**. Todo token ativo do sistema inteiro é candidato a receber QUALQUER evento.
- `isActiveMember` (decide texto de ticket-vs-checkin) filtra `supporter_memberships` só por `user_id`+`expires_at` — **sem `club_id`**, mesmo a coluna já existindo.
- **Resposta direta à pergunta do dono**: sim, um evento do Goiás seria despachado pra tokens de usuários de um clubB, e vice-versa, se um 2º clube existisse hoje. O canal Android (`channel_id: '<code>_matches'`) já é corretamente por clube, mas isso só afeta ONDE a notificação aparece no telefone, não IMPEDE que ela chegue.
- Classificação: **`MUST_CONFIG_BEFORE_CLUB_B`** — `user_notification_tokens` continua corretamente GLOBAL (é por aparelho, não por clube — decisão correta), mas o DESPACHO precisa ligar token→preferência tenant-scoped→evento, não pode iterar "todo token ativo."

## 22. Store / Membership / Tickets

**Store**: catálogo de produtos é dataset Dart estático (`mock_store_repository.dart`), não uma tabela Supabase tenant-aware — pra um clubB real, precisa de dataset próprio OU `ClubCapabilities.hasStore=false`. `order_number` global intencional (correto). `'GOI-'` hardcoded em 2 lugares: a função SQL `generate_store_order_number()` E o path de demo "pagamento recusado" em `supabase_store_orders_repository.dart:118` (o `ClubIntegrations.orderPrefix='GOI'` existe e nunca é lido em nenhum dos dois). `PickupInformation`/`MembershipContactConfig` bypassam `ClubConfig` (ver §10).

**Membership**: `supporter_memberships`/`subscribe_to_plan_for_club` tenant-ready (confirmado M2.2B-B). Catálogo de planos hardcoded na RPC (`'nossa-gente'`→`'NOSSA GENTE'` etc.) — aceitável como `GLOBAL_INTENTIONAL` SE todo clube reusar os mesmos nomes de plano, ou precisa virar decisão de produto se cada clube tiver planos próprios.

**Tickets**: chaves finais aplicadas (M2.2B-B), RPC de check-in tenant-aware, RLS user-isolada — **sem blocker**.

## 23. Arena/content sem dados — comportamento confirmado

`ClubScopedFallback<T>` (mecanismo já existente, correto por design): nunca resolve a um clube default — `forClub` devolve `null` pra código não registrado, e é responsabilidade explícita de quem chama decidir o que fazer. Testes existentes (`club_scoped_content_repositories_test.dart`) já provam: clubB + Supabase vazio + sem fallback → `ClubDataUnavailableException`, nunca conteúdo do Goiás. **Comportamento desejado já está implementado, nada a mudar aqui.**

## 24. `ClubCapabilities` — existe, mas não está ligada a nada

`lib/core/club/club_capabilities.dart` — criada desde a M1, com o próprio comentário confirmando: *"Nenhum consumidor real lê isto ainda."* Confirmado ainda verdadeiro: `ArenaCatalog.games` continua fixo, nenhuma tela verifica `hasStore`/`hasTickets`/`hasPassport`/`hasMembership`/`hasCrowdLineup` antes de renderizar. **Campos que faltam no contrato**: notificações, feed social, elenco/squad — hoje só cobre 5 flags + `enabledArenaGames`. Antes de qualquer rollout real de clubB, essa matriz precisa: (a) crescer pros campos faltando, (b) ser efetivamente lida em cada tela/feature correspondente.

## 25. Passaporte — recomendação

Alinhado com a tendência do dono: **Opção B — clubB entra com `capability=false`, escondendo Passaporte completamente**, é a recomendação técnica, DESDE QUE `ClubCapabilities` seja realmente wireada primeiro (§24) — hoje, mesmo escolhendo B, não há mecanismo pra de fato esconder a feature. Reforça o achado do ACL: as 12 RPCs de Passaporte têm EXECUTE `PUBLIC`/`anon`/`service_role`=true, mais aberto que qualquer outra RPC do projeto — vale uma nota separada (não bloqueia clubB por si só, mas é uma dívida de segurança pré-existente, no mesmo espírito do já registrado `LEGACY_RPC_PUBLIC_EXECUTE_DEBT`).

## 26. Release Gate

`app_release_requirements` já com `UNIQUE(club_id, platform)` + FK pra `clubs`. `SupabaseReleaseRequirementRepository` já lê `.eq('club_id', _clubConfig.identity.canonicalClubId)` — um futuro flavor clubB automaticamente leria só seu próprio requirement, nunca o do Goiás. **Sem blocker.**

## 27. Local storage — reaudit completo (não só os 3 stores conhecidos)

Único pacote de persistência local real: `shared_preferences` (nenhum Hive/Sembast/secure storage/sqflite em uso). Os 3 stores já corrigidos na M3.3 (`StoreLocalStorage`, `GuessPlayerStorage`, `LocalBestScoreStore`) reconfirmados `CLUB_SCOPED`. `LocalePreference`/`ThemePreference`/`ClubSongVolumeStore` = `GLOBAL_BY_DESIGN` (preferência de UI, não conteúdo de clube). **Nenhum 4º store órfão encontrado.**

**Achado novo**: a própria sessão de autenticação do `supabase_flutter` (`SharedPreferencesLocalStorage`, chave derivada do HOST da URL do projeto Supabase, não do `ClubConfig`) nunca é envolvida por `ClubScopedStorageKey`. Isso só vira um risco real se Goiás e clubB compartilharem o mesmo `applicationId`/bundle id no mesmo aparelho (ver §28) — hoje é exatamente esse o caso, já que não existem flavors.

## 28. Auth/session — comportamento hoje

Sem flavors reais, um build com `APP_CLUB=club-b` usaria o MESMO `applicationId` (`br.com.goiasec.goias_app`)/bundle id do Goiás — o SO trataria como o MESMO app, sobrescrevendo-o no aparelho, e portanto compartilhando o SharedPreferences (incluindo o token de sessão Supabase, sob a mesma chave, já que ambos apontam pro mesmo projeto Supabase). **Uma vez que os flavors reais existirem (§14-16), esse risco desaparece automaticamente** — cada `applicationId`/bundle id ganha sandbox de storage próprio pelo próprio SO, independente de nomes de chave. `ClubScopedStorageKey` vira defesa em profundidade genuína só depois disso (útil hoje só pro cenário dev "trocar `APP_CLUB` sem reinstalar, mesmo package id").

## 29. Deep links

**Nenhuma infra de deep link nativo existe hoje** — 0 intent-filter `VIEW`/`BROWSABLE` no Android, 0 `CFBundleURLTypes` no iOS, 0 `.entitlements`, 0 `usePathUrlStrategy()` no `go_router`. Não há nada hardcoded pro Goiás pra quebrar, porque o mecanismo simplesmente não existe ainda — `OUT_OF_SCOPE` pra esta rodada, não um blocker de clubB. Único ponto relevante: `SupabaseConfig.redirectUrl` (usado em recuperação de senha/magic link) é uma URL web fixa — precisaria virar por-clube quando a feature de deep link nativo for construída.

## 30. Assets — achado crítico

`ClubConfig.assets`/`ClubAssets` existe (10 campos), mas com o mesmo padrão do resto: **1 único consumidor real** (`club_badge.dart`). **Todo o resto do app lê `AppAssets.<literal>` diretamente** — crest, crest badge, login background, banner de estádio, hero de partida, ilustração tática, ícone/foto do estádio da Arena, banner da loja — todos paths fixos, vários com "goias"/cor verde já no NOME do arquivo.

**Resposta direta à pergunta do dono ("clubB veria o escudo/fundo do Goiás por fallback, ou ficaria faltando/quebrado?")**: **nem uma coisa nem outra — mostraria os assets REAIS do Goiás, sem condicional nenhuma**, porque nada além do `ClubBadge` pergunta ao `ClubConfig` qual asset usar. É o resultado menos seguro dos dois possíveis: não é uma falha visível (que seria fácil de notar e corrigir), é conteúdo do Goiás vazando silenciosamente pra dentro de um build clubB.

## 31. Copy / localização

~45 chaves l10n com "Goiás"/"Esmeraldino"/etc — a maioria é `GOIAS_CONTENT_INTENTIONAL` (marketing/trivia/compartilhamento, correto ser específico do clube real). Um punhado mapeia diretamente pros campos já existentes em `ClubProductNaming` (nome da Arena/Passaporte/Loja/Programa de sócio) — esses sim são `MUST_CONFIG_BEFORE_CLUB_B`, mas não precisam de reescrita ampla: o contrato já existe, só falta ser lido.

## 32. Synthetic Club Test Contract

Já existe e já é usado corretamente: `test/core/club/synthetic_club_config.dart` (`syntheticClubBConfig`, `code='club-b'`, `uuid` sintético, reusa branding/assets/integrations/capabilities do Goiás variando só identidade) — testes (`club_scoped_content_repositories_test.dart`) já provam isolamento de config/repository/storage. **Deliberadamente nunca registrado em `clubRegistry`** (produção) — confirmado por teste explícito que `resolveActiveClub` nunca resolveria pra ele. Mecanismo correto, nenhuma mudança necessária.

## 33-34. Blocker classes

- **`BLOCKER_BEFORE_ANY_SECOND_CLUB`** (quebraria/vazaria mesmo num teste controlado/sintético num ambiente real): assets (§30), `notifications-dispatch` fan-out (§20-21), identidade de app/sessão compartilhada (§28, decorre da ausência de flavors), bypasses de config (`MembershipContactConfig`/`PickupInformation`/`SocialLinksData`/`MaterialApp title`/`passport_match_ticket_v2` — §10), `'GOI-'` hardcoded em 2 lugares (§22), News/Social do Worker 100% Goiás sem dimensão de `clubCode` (§19 do Worker).
- **`BLOCKER_BEFORE_PUBLIC_SECOND_CLUB`**: RLS sem `CLUB_ISOLATION` (§6, hardening), `ClubCapabilities` não wireada (§24), flavors Android/iOS/Web completos (§14-16), decisão de schema pra `club_transparency_*`/`club_board_*`/`membership_faq_*` (§8-9), genericização das chaves l10n ligadas a `ClubProductNaming` (§31).
- **`BLOCKER_BEFORE_ENABLING_FEATURE`**: Passaporte (§25, `BLOCKER_BEFORE_ENABLING_PASSAPORTE`), Store (§22, `BLOCKER_BEFORE_ENABLING_STORE` se o catálogo não virar tenant-aware), `club_board`/`club_transparency` (`BLOCKER_BEFORE_ENABLING_CLUB_INSTITUTIONAL_PAGES`).
- **`DEFERRED_NON_BLOCKER`**: `web/manifest.json` placeholder (bug pré-existente, não-multiclube), nomes de enum (`esmeraldino` etc, só rótulo), tokens de cor semânticos (`darkGreen` etc), `ClubSongVolumeStore` não escopado (risco baixo), variável de ambiente do Worker `GOIAS_ONEFOOTBALL_SLUG` (funciona hoje, cada clube teria seu próprio deploy de Worker de qualquer forma).

## 35-38. Escopo desta rodada

Regra seguida à risca: features Goiás-specific que podem virar `capability=false` não precisam de genericização total. Nenhuma mudança grande foi aplicada — só este relatório + tooling (§39) + esta análise.

## 39. Critério final

```
SECOND_CLUB_TECHNICALLY_SAFE=false
SECOND_CLUB_PRODUCT_READY=false
```

`SECOND_CLUB_TECHNICALLY_SAFE=false` (não `true`) porque existem bugs estruturais reais, não hipotéticos, que ATIVAMENTE vazariam dado/branding do Goiás ou quebrariam isolamento mesmo num teste controlado: assets (§30), despacho de notificação (§20-21), e a cascata de identidade de app/sessão (§28) — nenhum desses é "falta polimento", são comportamentos incorretos que aconteceriam de verdade. `SECOND_CLUB_PRODUCT_READY=false` por consequência direta, mais tudo em `BLOCKER_BEFORE_PUBLIC_SECOND_CLUB`.

## 40. Fases recomendadas de implementação da M4 (não autorizadas nesta rodada)

1. **Fiação de branding/assets/naming**: `ClubConfig.assets`/`.branding`/`.productNames` realmente consumidos; corrigir os ~10 `AppAssets` hardcoded, título do `MaterialApp`, `MembershipContactConfig`/`PickupInformation`/`SocialLinksData` (e adicionar campo de social links ao `ClubIntegrations`), bug do `passport_match_ticket_v2`, `'GOI-'` nos 2 lugares.
2. **`ClubCapabilities` real**: crescer a matriz (notificações, social, squad) e efetivamente ligá-la em cada tela/feature.
3. **Hardening de backend**: `notifications-dispatch` filtrando por clube via preferência/token, Worker News/Social com dimensão de `clubCode` (ou capability-gated), RLS com isolamento de clube (defesa em profundidade), drift check estendido pra incluir a tabela `clubs`.
4. **Pipeline de flavor real**: Android/iOS/Web (docs 10-13), o que resolve automaticamente o compartilhamento de sessão/storage (§28).
5. **Decisões de schema/produto**: `club_transparency_*`/`club_board_*`/`membership_faq_*` (tenant real ou boilerplate compartilhado), Passaporte (capability=false, recomendado, após fase 2).
6. **Só então**: onboarding de um clube real — decisão de produto separada, fora do escopo técnico.

## 41. Tooling

Ver `tooling/multiclub/audit_second_club_product_readiness.mjs` + `test_second_club_product_readiness.mjs`.

---

## Estados

`SECOND_CLUB_TECHNICALLY_SAFE=false` · `SECOND_CLUB_PRODUCT_READY=false` · `KEY_SCOPE_FINAL=true` (inalterado) · `ROW_SCOPE_READY=true` (inalterado) · `AUTH_SCOPE_ACTIVE_CLUB_ENFORCEMENT_BLOCKED=true` (inalterado, agora com causa raiz documentada) · `RLS_CLUB_ISOLATION=false` (novo, `RLS_USER_ISOLATION=true`) · `ASSETS_CLUB_PARAMETERIZED=false` (novo, achado crítico) · `NOTIFICATIONS_DISPATCH_CLUB_SCOPED=false` (novo, achado crítico) · `CLUB_CAPABILITIES_WIRED=false` (novo) · `PASSPORT_TENANCY_DEFERRED=true` (inalterado) · `FLAVOR_PIPELINE_IMPLEMENTED=false` (inalterado desde 2026-09-01).

---

**PARE.** Não cadastrar segundo clube. Não iniciar implementação ampla da M4. Auditoria completa, matriz de blockers registrada, aguardando revisão + priorização das 6 fases antes de qualquer trabalho de implementação.

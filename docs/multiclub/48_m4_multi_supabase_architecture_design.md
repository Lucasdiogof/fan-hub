# M4 — Arquitetura "um Supabase por clube": auditoria + design

Data: 2026-09-04
Status: **AUDIT + DESIGN. 0 db push, 0 db reset, 0 migration repair, 0 Edge deploy, 0 cópia de auth.users/dados/secrets, 0 git push, 0 alteração de produção.** Supabase Goiás (`yonozsdgyrhgqrvydbnr`) intocado — 60/60 migrations, dados reais preservados. Supabase Bragantino (`yrgyzkaaudyzmsqwzecj`) auditado só via metadados do projeto do Goiás (nunca conectado/tocado).

## 1) Inventário completo das migrations

60 arquivos em `supabase/migrations/`, todos lidos por completo. Classificação linha a linha na tabela abaixo (categoria primária; secundária entre parênteses quando relevante).

| # | Migration | Classificação |
|---|---|---|
| 1 | `20260830220000_baseline_marker.sql` | LEGACY_TRANSITION |
| 2 | `20260830220001_arena_record_score_item_validation.sql` | SUPERSEDED (→ `arena_record_score_for_club` final em #57) |
| 3 | `20260830220002_subscribe_to_plan_rpc.sql` | SUPERSEDED (→ `subscribe_to_plan_for_club` final em #60) |
| 4 | `20260831000000_tickets_refund_status.sql` | SCHEMA_GENERIC |
| 5 | `20260831010000_passport_attendance_breakdown.sql` | SUPERSEDED (por #7) |
| 6 | `20260831020000_career_players_revalidated_v2.sql` | GOIAS_DATA |
| 7 | `20260831030000_passport_trajectory_view_other_users.sql` | RPC_GENERIC (Passaporte não é tenant-scoped ainda — `NEEDS_PRODUCT_DECISION`) |
| 8 | `20260831040000_passport_venue_audit.sql` | GOIAS_DATA |
| 9 | `20260831050000_passport_venue_haile_pinheiro_name.sql` | GOIAS_DATA |
| 10 | `20260901000000_create_people.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 11 | `20260901010000_seed_goias_people.sql` | GOIAS_SEED |
| 12 | `20260901020000_create_person_aliases.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 13 | `20260901030000_seed_goias_person_aliases.sql` | GOIAS_SEED |
| 14 | `20260902000000_add_evair_welliton_people.sql` | GOIAS_SEED |
| 15 | `20260902010000_add_evair_welliton_aliases.sql` | GOIAS_SEED |
| 16 | `20260902020000_create_clubs.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 17 | `20260902030000_seed_clubs.sql` | GOIAS_SEED / **UNSAFE_FOR_NEW_CLUB** se reusado verbatim |
| 18 | `20260902040000_create_player_club_spells.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 19 | `20260902050000_seed_goias_player_club_spells.sql` | GOIAS_SEED |
| 20 | `20260902060000_create_player_positions.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 21 | `20260902070000_seed_goias_player_positions.sql` | GOIAS_SEED |
| 22 | `20260902080000_create_player_club_stats.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 23 | `20260902090000_seed_goias_player_club_stats.sql` | GOIAS_SEED |
| 24 | `20260902100000_create_matches.sql` | **CANONICAL_FOR_NEW_CLUB** (referência de design: multi-clube desde o dia 1) |
| 25 | `20260902110000_seed_goias_matches.sql` | GOIAS_SEED |
| 26 | `20260902120000_create_player_match_appearances.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 27 | `20260902130000_seed_goias_player_match_appearances.sql` | GOIAS_SEED |
| 28 | `20260902140000_add_person_id_to_career_players.sql` | SCHEMA_GENERIC |
| 29 | `20260902150000_backfill_career_players_person_id.sql` | GOIAS_DATA / UNSAFE_FOR_NEW_CLUB (assert de contagem exata, aborta em banco vazio — seguro, nunca corrompe) |
| 30 | `20260902160000_add_person_id_to_guess_players.sql` | SCHEMA_GENERIC |
| 31 | `20260902170000_backfill_guess_players_person_id.sql` | GOIAS_DATA / UNSAFE_FOR_NEW_CLUB (idem) |
| 32 | `20260902180000_add_person_id_to_squad_members.sql` | SCHEMA_GENERIC |
| 33 | `20260902190000_backfill_squad_members_person_id.sql` | GOIAS_DATA / UNSAFE_FOR_NEW_CLUB (idem) |
| 34 | `20260902200000_fix_current_squad_ongoing_spells.sql` | GOIAS_DATA / UNSAFE_FOR_NEW_CLUB (idem) |
| 35 | `20260902210000_add_current_squad_missing_club_total_stats.sql` | GOIAS_DATA / UNSAFE_FOR_NEW_CLUB (idem) |
| 36 | `20260902220000_add_multiclub_content_tenant_scope.sql` | MULTITENANT_TRANSITION (GOIAS_DEFAULT) |
| 37 | `20260902230000_add_multiclub_arena_quiz_progress_tenant_scope.sql` | MULTITENANT_TRANSITION (GOIAS_DEFAULT) |
| 38 | `20260902240000_add_multiclub_career_lineup_progress_tenant_scope.sql` | MULTITENANT_TRANSITION (GOIAS_DEFAULT) |
| 39 | `20260902250000_add_multiclub_tickets_store_tenant_scope.sql` | MULTITENANT_TRANSITION (GOIAS_DEFAULT) |
| 40 | `20260902260000_add_multiclub_membership_tenant_scope.sql` | MULTITENANT_TRANSITION (GOIAS_DEFAULT) |
| 41 | `20260902270000_add_multiclub_notifications_tenant_scope.sql` | MULTITENANT_TRANSITION (GOIAS_DEFAULT) |
| 42 | `20260903000000_add_arena_tenant_aware_rpcs.sql` | RPC_GENERIC / SECURITY_GENERIC |
| 43 | `20260903010000_add_membership_tenant_aware_rpcs.sql` | RPC_GENERIC (corpo superado por #60) |
| 44 | `20260903020000_add_crowd_lineup_tenant_aware_rpc.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 45 | `20260903030000_add_store_tenant_aware_rpc.sql` | RPC_GENERIC (comentário flagga `GOI-`/`order_number` como debt não resolvido) |
| 46 | `20260903040000_harden_tenant_rpc_execute_grants.sql` | SECURITY_GENERIC |
| 47 | `20260903050000_prepare_tenant_aware_content_keys.sql` | SCHEMA_GENERIC (MULTITENANT_TRANSITION) |
| 48 | `20260903060000_prepare_tenant_aware_progress_keys.sql` | SCHEMA_GENERIC (MULTITENANT_TRANSITION) |
| 49 | `20260903070000_prepare_tenant_aware_engagement_keys.sql` | SCHEMA_GENERIC (MULTITENANT_TRANSITION) |
| 50 | `20260903080000_prepare_tenant_aware_notification_keys.sql` | SCHEMA_GENERIC (MULTITENANT_TRANSITION) |
| 51 | `20260903090000_update_arena_score_tenant_conflict.sql` | SUPERSEDED (por #57) |
| 52 | `20260903100000_add_membership_checkin_ticket_rpc.sql` | **CANONICAL_FOR_NEW_CLUB** |
| 53 | `20260903110000_add_app_release_requirements.sql` | **CANONICAL_FOR_NEW_CLUB** (estrutura) / GOIAS_SEED (a 1 linha inserida) |
| 54 | `20260903120000_finalize_tenant_aware_keys.sql` | MULTITENANT_TRANSITION |
| 55 | `20260903130000_drop_transitional_club_defaults.sql` | MULTITENANT_TRANSITION |
| 56 | `20260903140000_retire_legacy_rpc_execute_grants.sql` | SECURITY_GENERIC |
| 57 | `20260903150000_fix_arena_score_cross_club_reads.sql` | **CANONICAL_FOR_NEW_CLUB** (corpo final de `arena_record_score_for_club`, corrige leak real) |
| 58 | `20260903160000_add_club_id_to_notification_tokens.sql` | MULTITENANT_TRANSITION (GOIAS_DEFAULT) |
| 59 | `20260903170000_drop_default_notification_tokens_club_id.sql` | MULTITENANT_TRANSITION |
| 60 | `20260903180000_fix_ambiguous_id_membership_rpcs.sql` | **CANONICAL_FOR_NEW_CLUB** (corpo final de `get_my_membership_for_club`/`subscribe_to_plan_for_club`) |

Nenhum `REQUIRES_REDESIGN` de tabela/feature encontrado, além do débito já documentado no próprio código (`order_number`/`GOI-`, #39/#45/#49 — vira `ClubConfig` numa etapa própria, não migration).

## 2) Quais são Goiás-only

**GOIAS_DATA/GOIAS_SEED** (nunca replicar): #6, #8, #9, #11, #13, #14, #15, #17, #19, #21, #23, #25, #27, #29, #31, #33, #34, #35, #53(a linha). Cobrem: 94+2 pessoas reais, aliases/provenance, 30 jogadores de carreira (Adivinhe o Clube), 173 guess players (parcial), 31 squad members, 31 partidas + 1697 registros de Passaporte + 160 venues, todo o `career_players_revalidated_v2` (JSON gigante). **Nenhuma migration semeia** `quiz_questions`/produtos de loja/planos de membership — esses vivem fora de `supabase/migrations/` (scripts soltos pré-2026-08-30, ex. `supabase/quiz_questions.sql`, ou hardcoded dentro do corpo das RPCs de assinatura — `subscribe_to_plan_for_club` tem os 6 planos do Sócio Esmeralda literais no corpo da função, não numa tabela).

## 3) Quais representam schema/security/RPC canônicos

**CANONICAL_FOR_NEW_CLUB** (16 itens — a "foto final" que um clube novo precisa, sem nenhuma mecânica de migração/backfill): `people`, `person_aliases`(+sources), `clubs`, `player_club_spells`(+sources), `player_positions`(+sources), `player_club_stats`(+sources), `matches`(+match_source_refs), `player_match_appearances`(+sources), `crowd_lineup_for_club`, `upsert_membership_checkin_ticket_for_club`, `app_release_requirements` (estrutura), e os 3 corpos finais de RPC que só ficaram corretos depois de correções (`arena_record_score_for_club` #57, `get_my_membership_for_club`/`subscribe_to_plan_for_club` #60) — **usar sempre a versão final, nunca a original + replay das correções**.

**SECURITY_GENERIC** (2): `harden_tenant_rpc_execute_grants`, `retire_legacy_rpc_execute_grants` — o RESULTADO (RPCs `_for_club` com `authenticated`-only, RPCs legadas sem EXECUTE nenhum) é o que importa; um projeto novo nasce direto no estado final, sem precisar "endurecer depois".

**Achado crítico que muda o desenho**: `public.profiles`/`public.user_addresses` **não existem em nenhuma migration** — foram criadas direto no dashboard do Goiás. Confirmado ao vivo: 9 colunas (`id, full_name, avatar_url, phone, created_at, updated_at, cpf, birth_date, marketing_opt_in`), FK `profiles.id → auth.users.id` (`ON DELETE CASCADE`), `UNIQUE(cpf) WHERE cpf IS NOT NULL`, 3 policies RLS (`select/insert/update own`, todas `auth.uid() = id`), e a trigger `on_auth_user_created AFTER INSERT ON auth.users EXECUTE FUNCTION handle_new_user()` (corpo: `insert into profiles(id, full_name) values (new.id, new.raw_user_meta_data->>'full_name')` — genérico, sem nada do Goiás). **Isso significa que "rodar as migrations" NUNCA reproduziria um projeto novo funcional** — falta a parte mais básica do fluxo de cadastro. Confirmado também: 57 tabelas / 90 policies RLS / 36 functions / 4 triggers ao vivo hoje (os 4 triggers são todos de `delivery_addresses`, nada em `auth.users` além do já citado).

## 4) Dependências entre migrations

- Cadeia de identidade: `people`(#10)→`person_aliases`(#12)→seeds(#11,13,14,15) — sem dependência de `clubs`.
- Cadeia de clube: `clubs`(#16)→seed Goiás(#17)→`player_club_spells`(#18, FK clubs)→demais tabelas de conteúdo (todas FK `clubs`).
- Cadeia de tenancy: `add_multiclub_*_tenant_scope`(#36-41, DEFAULT Goiás)→`prepare_tenant_aware_*_keys`(#47-50, índices bridge)→`finalize_tenant_aware_keys`(#54, promove PK/UNIQUE + dropa legado)→`drop_transitional_club_defaults`(#55). Essa cadeia INTEIRA existe só porque o Goiás tinha dado/app já publicado precisando de transição sem downtime — um clube novo, vazio, não precisa de NENHUM desses 10 arquivos: nasce direto com `club_id NOT NULL` (sem DEFAULT) e PK composta desde a criação da tabela.
- RPCs: cada `_for_club` tem no mínimo 1 versão "final" (#42/44/45/52/57/60) — usar só essas, nunca a cadeia de correções.

## 5) Estratégia recomendada de baseline para novos clubes

Comparação das 4 opções pedidas:

**A) Baseline canônico + reparar histórico via `migration repair`**
- Risco: alto. `migration repair --status applied` marca uma migration como aplicada SEM rodar — mas 10 dos 60 arquivos (GOIAS_SEED com backfill hardcoded) só fazem sentido/não quebram porque JÁ existem linhas específicas do Goiás; "pular" 40 arquivos e aplicar 20 misturados no meio de uma cadeia de 60 é operação cirúrgica repetida a cada novo clube, propensa a erro humano, e `profiles`/trigger continuam faltando de qualquer jeito (não estão em migration nenhuma pra reparar).
- Manutenção: piora a cada clube novo (a lista de "pular"/"aplicar" tem que ser recalculada).
- Descartada.

**B) Workdirs/configs Supabase separados por clube**
- O Supabase CLI já suporta isso SEM duplicar pastas: `--project-ref <ref>` funciona como override por comando (`migration list --project-ref`, `db push --project-ref`, `db dump --project-ref` — confirmado no `--help`), sem precisar de `supabase link` persistente nem `supabase/` duplicado. Testei: `supabase/config.toml` tem 1 `project_id` fixo, mas todo comando aceita o override.
- Sozinha, não resolve o problema central (ainda sobra "quais dos 60 arquivos aplicar pro clube novo").
- Vira um COMPLEMENTO da opção C (como você aplica, não o que você aplica).

**C) Cadeia nova de migrations canônicas compartilhadas, histórico Goiás como legacy/archive** — **RECOMENDADA**
- Gerar 1 baseline novo via `supabase db dump --schema-only --project-ref yonozsdgyrhgqrvydbnr -f supabase/migrations/<timestamp>_baseline_canonical.sql` (schema-only NUNCA inclui dados — confirmado no `--help`, `--data-only` é uma flag separada) — captura tabelas/RLS/RPCs/índices/constraints no ESTADO FINAL de verdade, sem nenhuma mecânica de transição.
- Curar esse dump à mão (1 revisão manual, não automática) removendo qualquer resíduo: nenhum dos achados acima sugere que exista um literal Goiás DENTRO de RLS/CHECK/índice (os únicos literais Goiás são em `DEFAULT`, já removidos pela cadeia #54-55/58-59, e em `seed_clubs.sql`, que não é schema) — mas revisar é obrigatório antes de aplicar de verdade.
- Extrair `profiles`/`user_addresses`/`handle_new_user` via `pg_dump`/introspecção (item 3 acima) e incluir no MESMO baseline — sem isso o Bragantino não tem cadastro/login funcional.
- Mover os 60 arquivos atuais pra `supabase/_migrations_archive_goias/` (nome deliberadamente FORA de `supabase/migrations/`, que é a única pasta que o CLI escaneia) — preserva histórico/git blame, mas nenhum comando `db push`/`migration list` volta a considerá-los, pra NENHUM projeto, Goiás incluso. **Risco a mitigar**: pro Goiás, isso é seguro (as 60 já estão `local=remote` na tabela de tracking remota — mover o arquivo local não "desaplica" nada), mas `supabase migration list --linked` do Goiás passa a mostrar essas 60 como "só remoto" (sem par local) — comportamento esperado, não erro, mas documentar isso claramente pra não confundir uma sessão futura achando que é drift.
- Daqui pra frente, TODA migration nova nasce em `supabase/migrations/` já genérica (nunca assume 1 clube, nunca tem DEFAULT de club_id, nunca faz backfill hardcoded) e é aplicada nos 2+ projetos via `--project-ref`.
- Manutenção: baixa e constante — 1 baseline por vez que um clube novo nasce (raro), depois só a cadeia normal e compartilhada.

**D) Outra abordagem**
- Considerada e descartada: usar `supabase db diff` contra um projeto Postgres local (`supabase start`) pra gerar a baseline — mais robusto tecnicamente, mas este projeto explicitamente NÃO usa Docker/local (`config.toml` comentário: "Nao usamos supabase start"), então introduziria uma dependência nova só pra esta etapa. `db dump --schema-only` direto do remoto já é suficiente e mantém a convenção do projeto.

## 6) Estratégia de migration history (resumo operacional)

1. `supabase/migrations/` = só migrations GENÉRICAS, compartilhadas por todos os clubes, presente e futuro.
2. `supabase/_migrations_archive_goias/` = as 60 atuais, congeladas, nunca mais aplicadas em lugar nenhum (nem em re-provisionamento futuro do próprio Goiás — se o Goiás precisasse ser recriado do zero um dia, usaria o MESMO baseline canônico + seed de dados reais exportado separadamente, nunca replay das 60).
3. `tooling/multiclub/supabase_projects_registry.json` (novo, espelha `clubs_registry.json`): `{ "goias": "yonozsdgyrhgqrvydbnr", "bragantino": "yrgyzkaaudyzmsqwzecj" }` — fonte única de verdade de "quais projetos existem", usada pela tooling do item 12.
4. Migration club-específica (rara — ex. um seed que só faz sentido pra 1 clube) continua fisicamente em `supabase/migrations/` (mesma pasta, sem pasta separada por clube — a pasta não é o mecanismo de isolamento, o `--project-ref` de aplicação é) mas só é APLICADA (`db push --project-ref`) no projeto certo — documentada explicitamente no nome/cabeçalho do arquivo, nunca implícita.

## 7) UUID canônico do Bragantino — método (não aplicado)

Auditado `tooling/multiclub/club_registry.mjs`: o UUID do Goiás **não é `gen_random_uuid()` nem derivado do slug** — é `uuidV5(CLUBS_UUID_NAMESPACE, canonicalClubKey)`, com `CLUBS_UUID_NAMESPACE = '8c1f4e6a-2d9b-4a3c-9e7f-1b6d8a4c2f9e'` (fixo) e `canonicalClubKey = "goias-app:multiclub:club:<sequência>"` (sequencial, nunca reaproveitado — Goiás é `:1`). `uuidV5` é RFC4122 padrão (SHA-1, bits de versão/variante corretos — conferido no código). O registry (`tooling/multiclub/clubs_registry.json`) já está com `nextSequence: 2`, pronto pro próximo.

Rodei o MESMO algoritmo (leitura, sem gravar nada no registry) pra pré-visualizar o valor real:
```
canonicalClubKey: goias-app:multiclub:club:2
clubId (preview): 51683d2a-ea1d-57c6-8014-996146f242e7
```
Esse É o UUID que `generate_clubs_seed.mjs`/`registerNewClub` produziriam de verdade se rodados — não inventei nem estimei, é o output determinístico real do helper existente. **Nada foi gravado** — nem `clubs_registry.json` nem nenhuma migration. Nota: o prefixo `"goias-app:"` no `canonicalClubKey` é só uma string de namespacing histórica (pré-rebrand Fan Hub) — trocar isso agora produziria um UUID DIFERENTE do que o Goiás já usa, quebrando a determinística; recomendo manter como está (é só uma string interna, nunca exposta a usuário) em vez de "corrigir" o nome.

## 8) Estado final esperado de `public.clubs`

`club_id` **não é removido** — continua contrato de domínio/segurança em profundidade/código compartilhado, exatamente como pedido. Cada Supabase de clube tem sua PRÓPRIA `public.clubs` com, tipicamente, 1 linha:
- `goias-app` (existente): `id=4c16340d-300c-5ab2-903f-17519db9b146, slug=goias, name=Goiás Esporte Clube`.
- `bragantino-app` (futuro, não inserido agora): `id=51683d2a-ea1d-57c6-8014-996146f242e7` (preview acima), `slug=bragantino`, `name=Red Bull Bragantino`.

Toda RPC/tabela que hoje faz `references public.clubs(id)`/valida `exists(select 1 from clubs where id=p_club_id)` continua funcionando idêntico — só que agora "o clube" dentro de cada projeto é sempre o único que existe lá.

## 9) Análise Auth/CPF

Confirmado ao vivo: `UNIQUE(cpf) WHERE cpf IS NOT NULL` é uma constraint **global dentro do projeto**, sem `club_id` — porque cada Supabase agora É o isolamento físico, essa mesma constraint, replicada verbatim pro projeto do Bragantino, automaticamente vira "CPF único DENTRO do Bragantino" sem precisar de nenhuma mudança de schema. Mesmo raciocínio pra email (Supabase Auth já garante unicidade de email por PROJETO, não globalmente entre projetos) e telefone (sem constraint hoje, nem precisaria). `cpf_is_taken(p_cpf)` (RPC, `SECURITY DEFINER`, `anon+authenticated`) também não tem dimensão de clube — replicada verbatim, funciona certo por isolamento físico. **Não é necessário adicionar `club_id` a `profiles`/CPF pra resolver cross-club** — exatamente a conclusão que você esperava, confirmada, não assumida.

Achado à parte: `lib/features/auth/data/auth_repository_impl.dart` usa `SupabaseConfig.redirectUrl` (default hardcoded pro Worker do Goiás) pro redirect de recuperação de senha — precisa ser resolvido junto com o item 10 (senão o link de "esqueci minha senha" de um usuário Bragantino levaria pro domínio do Goiás).

## 10) Configuração Flutter — Supabase por flavor

**Gap real confirmado, hoje**: `lib/core/config/supabase_config.dart` — `url`/`publishableKey`/`redirectUrl` são `String.fromEnvironment(..., defaultValue: <literal do Goiás>)`. `lib/main.dart:44-52` chama `Supabase.initialize(url: SupabaseConfig.url, ...)` sem NENHUMA ramificação por `APP_CLUB`. `tool/flavor_build_commands.json` hoje passa `APP_CLUB`/`API_BASE_URL` pros 2 flavors mas **nunca** `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` — ou seja, **o flavor `bragantino`, hoje, se buildado, conectaria silenciosamente no Supabase do Goiás.** Isso bate exatamente com o que você queria confirmar via auditoria, e o resultado é: SIM, é um problema real, não hipotético.

**Design recomendado** (reaproveita a MESMA infraestrutura fail-loud que já existe pra `APP_CLUB`, não cria um mecanismo paralelo): mover `supabaseUrl`/`supabasePublishableKey` (nunca `service_role`/senha — anon/publishable é config pública de cliente, mas ainda assim organizada por clube) pra dentro de `ClubIntegrations` (ou um novo sub-objeto `ClubBackendConfig`), populados por clube em `goias_club_config.dart`/`bragantino_club_config.dart`. `main()` passa a resolver `ClubConfig` via `resolveActiveClub()` (que JÁ é fail-loud — `APP_CLUB` ausente/desconhecido já lança) **antes** de chamar `Supabase.initialize`, usando `clubConfig.integrations.supabaseUrl`/`.supabasePublishableKey` em vez de `SupabaseConfig.url`/`.publishableKey`. Resultado: **impossível** buildar um flavor sem escolher explicitamente qual Supabase ele fala — mismatch/config ausente já herda o `StateError` fail-loud existente, nunca um fallback silencioso pro Goiás. `SupabaseConfig`'s defaults hardcoded do Goiás deixam de ser usados por qualquer flavor real (só sobreviveriam, se sobreviverem, como fallback do build NÃO-flavored/dev, mesmo período de graça que `APP_CLUB` ausente já tem hoje).

Não implementado nesta rodada — é design. Quando essa etapa for autorizada, `bragantinoClubConfig.integrations` precisa da URL/anon key REAIS do projeto `yrgyzkaaudyzmsqwzecj` (fornecidas por você, nunca inventadas) + o `redirectUrl` do Bragantino (depende do Worker dele estar de pé, ver rodada anterior).

## 11) Edge Functions por clube

| Function | Classificação | Nota |
|---|---|---|
| `cleanup-unconfirmed-signups` | SHARED_CODE_DEPLOY_PER_CLUB | só usa `SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` auto-injetados por projeto — deploy novo funciona sem mudança de código |
| `delete-account` | SHARED_CODE_DEPLOY_PER_CLUB | idem, identifica usuário só via JWT |
| `notifications-dispatch` | REQUIRES_SECRET_PER_PROJECT | precisa de `FCM_SERVICE_ACCOUNT_JSON` PRÓPRIO do Bragantino — nunca copiar o do Goiás (item 13, fase própria) |
| `notifications-poll-live-match` | GOIAS_ONLY / REQUIRES_REDESIGN | `WORKER_BASE_URL` hardcoded pro Worker do Goiás no código-fonte (não é env var) — precisa virar config por projeto antes do Bragantino poder usar |
| `notifications-sync-and-check-access` | GOIAS_ONLY / REQUIRES_REDESIGN | mesmo hardcode de `WORKER_BASE_URL` |

Cron: `supabase/notifications_cron.sql` já é um TEMPLATE reusável (placeholders `<SEU_PROJECT_REF>`/`<SUA_SERVICE_ROLE_KEY>`) — pronto pra reaplicar por projeto. `supabase/cleanup_unconfirmed_signups_cron.sql` hardcoda a URL do projeto Goiás diretamente — precisa de cópia própria por projeto (mecânico, sem redesign). Nenhuma função lê config de outro projeto Supabase; o único acoplamento cross-projeto hoje é a URL do Worker, duplicada como literal em vez de vir de config. Todas as features cujo `ClubCapabilities` já está `false` pro Bragantino (Store/Membership/Tickets/CrowdLineup/Passaporte) não precisam de suas Edge Functions correspondentes funcionando ainda — não ativar nada só porque existe no Goiás.

## 12) Estratégia operacional de migrations futuras (desenho, não implementado)

Comandos-tipo (usando `--project-ref`, sem tocar `config.toml`):
```bash
npx supabase migration list --project-ref yonozsdgyrhgqrvydbnr      # goias-app
npx supabase migration list --project-ref yrgyzkaaudyzmsqwzecj      # bragantino-app
npx supabase db push --dry-run --project-ref <ref>                  # valida antes
npx supabase db push --project-ref <ref>                            # aplica, 1 projeto por vez, nunca em lote automático
```
Ordem: sempre aplicar num projeto por vez, validar (`migration list` + smoke test) antes do próximo — nunca um script que aplica em todos simultaneamente sem checkpoint. "Qual clube está pending" = rodar `migration list --project-ref` pra cada entrada de `supabase_projects_registry.json` e comparar `local` vs `remote`. Rollout parcial = aplicar num projeto, deixar o outro pending deliberadamente (ex.: uma feature que só o Goiás tem dado pronto ainda) — documentado no cabeçalho da migration, não escondido. Migration específica de 1 clube (se algum dia existir) = mesmo arquivo, mesma pasta, aplicada só via `--project-ref` daquele projeto — nunca pasta separada por clube (isso reintroduziria o problema do item 5).

Tooling proposta (nomes, não construídos):
- `tooling/multiclub/check_migrations_all_clubs.mjs` — roda `migration list --project-ref` pra cada projeto do registry, reporta pending/drift por projeto.
- `tooling/multiclub/apply_migration_to_club.mjs <club> [--dry-run]` — wrapper fino sobre `db push --project-ref`, só resolve o ref a partir do `club` (nunca esconde o comando real, só evita erro de digitar o ref errado).

## 13) Arquivos/tooling que precisarão ser criados (quando autorizado)

- `supabase/migrations/<novo-timestamp>_baseline_canonical.sql` (schema+security+RPC final, sem dado).
- Migration separada de `profiles`/`user_addresses`/`handle_new_user` (extraída ao vivo, hoje só no dashboard).
- `supabase/_migrations_archive_goias/` (as 60 atuais movidas, `git mv`, preservando histórico).
- `tooling/multiclub/supabase_projects_registry.json`.
- `tooling/multiclub/check_migrations_all_clubs.mjs` + teste.
- `ClubIntegrations`/`ClubBackendConfig` com `supabaseUrl`/`supabasePublishableKey` por clube + `main.dart` resolvendo `ClubConfig` antes de `Supabase.initialize`.
- Cópia de `supabase/cleanup_unconfirmed_signups_cron.sql` + `supabase/notifications_cron.sql` por projeto (quando o Bragantino ativar notificações).

## 14) Ordem exata para inicializar `yrgyzkaaudyzmsqwzecj` (quando autorizado, etapa própria)

1. Gerar + revisar manualmente o baseline canônico (item 5/13) contra o Goiás.
2. `supabase db push --dry-run --project-ref yrgyzkaaudyzmsqwzecj` com SÓ o baseline — validar que aplicaria limpo num projeto vazio.
3. Aplicar o baseline (`db push`, sem `--dry-run`) — autorização própria.
4. Inserir a 1 linha de `public.clubs` do Bragantino com o UUID determinístico (item 7/8) — autorização própria, registrar em `clubs_registry.json` via `generate_clubs_seed.mjs` de verdade (não o preview).
5. Validar RLS/RPCs ao vivo (mesmo checklist que M2.2A/M3.2 já usaram pro Goiás).
6. Só então: `bragantinoClubConfig.integrations.supabaseUrl/supabasePublishableKey` no Flutter (item 10) + gates + commit + push — etapa própria, autorização própria.
7. Edge Functions (item 11) — REQUIRES_SECRET_PER_PROJECT/REQUIRES_REDESIGN resolvidos numa fase própria, depois.

## 15) Riscos

- **Mover as 60 migrations pra fora de `supabase/migrations/` muda o que `migration list --linked` mostra pro Goiás** (remoto-só, sem par local) — não é drift real, mas precisa de uma nota clara na próxima sessão pra não ser confundido com um problema.
- **`profiles`/`handle_new_user` só existem no dashboard** — se o dashboard do Goiás mudar essa definição no futuro sem atualizar a migration extraída, o baseline do Bragantino (e de qualquer clube futuro) fica desatualizado silenciosamente. Recomendo, quando esta etapa for implementada, também versionar essa definição em `supabase/migrations/` pro PRÓPRIO Goiás (aditivo, `CREATE OR REPLACE`, sem risco) — fecha esse gap de vez, não só pro Bragantino.
- **2 Edge Functions de notificação hardcodam a URL do Worker do Goiás no código-fonte** — bloqueia notificações do Bragantino até uma redesign própria (não é migration, é código TypeScript).
- **`order_number`/`GOI-`** continua como débito não resolvido (já sinalizado desde M4.1) — não afeta o Bragantino enquanto `hasStore=false`.
- **UUID preview do item 7 não foi persistido** — se qualquer outra sessão rodar `generate_clubs_seed.mjs`/`registerNewClub` de verdade antes desta etapa continuar, o valor pode ser consumido por outra coisa (sequência avança) — vale checar `clubs_registry.json` de novo no início da próxima rodada antes de assumir que `51683d2a-...` ainda é o próximo.

---

**0 db push. 0 db reset. 0 migration repair. 0 Edge deploy. 0 cópia de auth.users/dados/secrets. 0 git push. 0 alteração de produção.** Supabase Goiás intocado, Supabase Bragantino nunca conectado.

PARE.

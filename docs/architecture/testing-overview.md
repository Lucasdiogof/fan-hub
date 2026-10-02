# Visão geral de testes

> Análise estática. **Nenhuma suíte foi executada e nenhum percentual de cobertura foi medido** (não há relatório `lcov` no repositório). "Com teste" abaixo significa: existe um `*_test.dart` com o mesmo caminho **ou** algum arquivo em `test/` importa diretamente o arquivo de produção. Cobertura apenas transitiva não conta; portanto os números subestimam a cobertura real e não devem ser lidos como percentual de linhas.

## 1. Onde estão os testes

| Área | Local | Arquivos | Como roda |
|---|---|---:|---|
| Flutter unit/widget | `test/**/*_test.dart` | 169 (~1.336 casos, estimativa por grep) | `flutter test` |
| Flutter integration | `integration_test/` | **não existe** | — |
| Worker (vitest, pool Cloudflare) | `src/**/*.test.ts` | 26 | `npm run test:worker` |
| Helpers das Edge Functions (vitest) | `supabase/functions/_shared/*.test.ts` | 6 | `npm run test:worker` |
| Node: dados, migrations e guardas | `tooling/**/test_*.mjs` | 38 | **manual** (`node tooling/multiclub/test_X.mjs`); sem script npm |
| Outros Node (`*.test.mjs`, `*_test.mjs`) | `tooling/bragantino_*`, `tooling/passport_security/` | 5 | manual (os de IDOR exigem banco real) |
| SQL/RLS | `supabase/passport_harden_per_user_rpcs_test.sql` | 1 | colar manualmente no SQL Editor de cada projeto |
| Python | `scripts/social/test_sync_x_posts.py` | 1 | não está em nenhum workflow (**NÃO VERIFICADO** se roda) |
| Edge Functions (`index.ts`) | `supabase/functions/*/index.ts` | **0** | só os `_shared` puros são testados |

## 2. CI

O único workflow é `.github/workflows/sync_x_posts.yml` (coleta de posts do X). **Não há CI** que rode `flutter analyze`, `flutter test`, vitest ou os testes `.mjs`. O README menciona deploy do Worker "a cada git push", mas isso acontece fora de `.github/` (**NÃO VERIFICADO** onde). `analysis_options.yaml` usa `flutter_lints` com *strict-casts*, *strict-inference* e *strict-raw-types*.

## 3. Estilo e suporte

- **Só fakes manuscritos**, sem `mocktail`/`mockito`. Fakes por feature em `test/features/{auth,match,membership,profile,store,ticket}/fakes/` (11 arquivos). Único utilitário compartilhado: `test/support/fake_asset_bundle.dart`. `fake_async` para temporizadores.
- **Sem golden tests.**
- 42 arquivos usam `testWidgets` (arena 7, club 4, home 4, match 3, news 3, passport 3, profile 3, store 2, squad 2, …).
- `test/widget_test.dart` sobe o `GoiasApp` real como *smoke test*.

## 4. Cobertura por área (import direto ou nome)

Total: **698** arquivos de produção em `lib/` (excluindo gerados e `app_localizations*`), dos quais **326** com teste direto e **372** sem.

| Área | Produção | Com teste | Observação |
|---|---:|---:|---|
| `features/arena` | 137 | 63 | cubits dos jogos e ranking testados; sem teste: `arena_progress_repository`, componentes Flame, `ranking_page` |
| `features/auth` | 24 | 7 | `AuthCubit` testado contra fake; **sem teste:** `auth_repository_impl`, `auth_remote_data_source`, páginas de login/cadastro/reset/OTP |
| `features/club` | 50 | 33 | sem teste: repositórios de diretoria e transparência |
| `features/match` | 70 | 31 | sem teste: `football_remote_data_source`, `football_repository_impl` |
| `features/membership` | 68 | 22 | cubits e repositório Supabase testados; sem teste: ViaCEP/IBGE, regulamento |
| `features/notifications` | 7 | 4 | **sem teste:** `push_notification_service` |
| `features/passport` | 43 | 14 | sem teste: `supabase_passport_repository` |
| `features/profile` | 23 | 11 | sem teste: `supabase_profile_repository` |
| `features/store` | 49 | 26 | **sem teste:** `checkout_page`, `checkout_payment_review`, páginas de pedidos |
| `features/ticket` | 37 | 20 | **sem teste:** `check_in_confirmation_page`, `my_orders_page` |
| `core/router` | 5 | **0** | `app_router`, `splash_gate` e demais sem nenhum import em `test/` |
| `core/club` | 19 | 17 | `capability_route_gate`, `resolve_active_club` e `club_registry` têm teste |
| `core/release` | 6 | 4 | gate e comparador testados; repositório Supabase não |
| `core/l10n` | 4 | 0 | — |
| `core/theme` | 9 | 2 | — |
| `shared` | 46 | 11 | — |
| `social` | 11 | 4 | fonte remota e repositório sem teste |
| demais features | — | — | `crowd_lineup` 11/21, `home` 9/16, `news` 12/18, `partners` 5/6, `squad` 8/11, `release_gate` 1/1, `splash` 1/5 |

## 5. Áreas críticas sem teste direto

Ordenadas por risco aparente (todas confirmadas por ausência de import em `test/`):

1. **Roteamento e gates:** `lib/core/router/app_router.dart`, `splash_gate.dart` — a ordem do `redirect` (splash → release → auth → capability) não tem teste direto.
2. **Autenticação:** `auth_repository_impl.dart` e `auth_remote_data_source.dart` (o cubit só é testado contra `fake_auth_repository`), além das páginas de login/cadastro/reset/OTP.
3. **Push:** `push_notification_service.dart` e **todas** as Edge Functions (`index.ts`); só os helpers `_shared` são testados.
4. **Checkout e pedidos da loja** e **check-in/pedidos de ingressos** (UI).
5. **Release gate:** `supabase_release_requirement_repository.dart`.
6. **Persistência da Arena:** `arena_progress_repository.dart`.
7. **Repositórios Supabase** de passaporte, perfil, diretoria, transparência, endereços, `football_repository_impl` e `social_feed_repository_impl`.
8. **Banco/RLS:** apenas 1 teste SQL e 1 teste IDOR autenticado, ambos manuais; as 18 migrations são checadas por guardas estáticas (`tooling/multiclub/test_*.mjs`, que **leem** o SQL, não o executam). Não há teste automatizado de RLS em CI.

No lado do Worker, arquivos sem teste por import incluem `src/news/scraper.ts`, `src/football/teamSeason.ts` e utilitários de `src/football/_lib/` (a heurística por nome pode subestimar a cobertura de `normalize/*`; **NÃO VERIFICADO** linha a linha).

## 6. O que está bem coberto

Sessão e rede (`account_session_cache_guard`, `session_aware_http_client`, `local_game_cache`), seleção de clube (`resolve_active_club`, `club_registry`, `capability_route_gate`), a lógica pura dos jogos (`quiz_logic`, `penalty_logic`) e os *datasets* do Bragantino (`bragantino_*seed_test.dart`).

## 7. Como rodar (verificado em `package.json`/README)

```bash
flutter test                  # testes Dart
npm run test:worker           # Worker + helpers das Edge Functions (vitest)
node tooling/multiclub/test_<nome>.mjs   # guardas de dados/migrations, manual
```

> Atenção: scripts `tooling/multiclub/audit_*.mjs` (diferentes dos `test_*.mjs`) **gravam** em `data_export/`; veja o aviso em [multi-club.md](multi-club.md).

## 8. Quick wins de teste (não implementados)

- Um workflow de CI com `flutter analyze`, `flutter test` e `npm run test:worker`.
- Teste do `redirect` do `app_router` (ordem de gates) com `GoRouter` e fakes de `AuthCubit`/`ReleaseGate`/`SplashGate`.
- Teste de `auth_repository_impl` com um cliente Supabase falso.
- Rodar `tooling/passport_security/run_authenticated_idor_test.mjs` como etapa manual obrigatória ao criar um projeto de clube novo.

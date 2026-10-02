# Débito técnico

> Classificação por **impacto técnico comprovável** no código lido (commit `e90de17`), não por preferência estética. Cada item aponta a evidência e diz o que **não** foi verificado. Nada aqui foi corrigido em produção: é um inventário para priorizar (a única correção já escrita é a migration de hardening do passaporte, **preparada e não aplicada** — ver A1). Detalhes de segurança estão em [security-overview.md](security-overview.md) e de multi-clube em [multi-club.md](multi-club.md); este documento os consolida e acrescenta acoplamento, código morto e dívida de processo.

**Critérios:** *crítico* = dano comprovado e sem mitigação visível; *alto* = falha confirmada no repositório com efeito relevante ou risco de erro operacional caro; *médio* = problema real e delimitado, ou risco que depende de estado não visto; *baixo* = higiene, custo de manutenção ou risco remoto.

## 1. Resumo

| Nível | Qtd. | Itens |
|---|---:|---|
| Crítico | 0 | Nenhum comprovado. S-01 é o mais próximo (ver A1) e depende do banco vivo |
| Alto | 6 | A1–A6 |
| Médio | 11 | M1–M11 |
| Baixo | 10 | B1–B10 |

## 2. Alto

| ID | Item | Evidência | Impacto |
|---|---|---|---|
| **A1** | **IDOR anônimo nas RPCs `passport_*` reintroduzido pelo baseline** — **correção preparada, NÃO aplicada, NÃO verificada em produção; permanece ALTO** | `supabase/migrations/20260904000000_canonical_baseline.sql` ~2263–2639: `SECURITY DEFINER`, filtro por `coalesce(p_user_id, auth.uid())`, `EXECUTE` para `anon`; `passport_ranking` expõe `user_id`. O fix original está em scripts soltos (`supabase/passport_harden_per_user_rpcs.sql`, `passport_revoke_anon_execute.sql`), fora da cadeia. **Foi criada `supabase/migrations/20261002040000_harden_passport_per_user_rpcs.sql`**: as 5 RPCs por usuário passam a usar `auth.uid()` e recusam `p_user_id` alheio; `EXECUTE` é revogado de `public` e `anon` em todas as `passport_*`, mantendo `authenticated` e `service_role`; há *checks* transacionais na própria migration. **Ainda não foi executada contra um PostgreSQL real nem aplicada aos bancos dos clubes** | Quem tem a chave *publishable* lê a presença em jogos de qualquer usuário num projeto não endurecido. **Não verificado:** o estado dos bancos vivos (se o hardening já foi aplicado à mão) e o comportamento real da migration. Só reclassificar como resolvido após aplicação **e** teste autenticado de IDOR em cada projeto |
| **A2** | **Migrations só-Goiás na cadeia comum** | 11 arquivos `20260930010000`…`20261002030000` (um deles *untracked*) que alteram linhas por id de jogador (por exemplo `where id = 'ernando'`) e não consultam `public.clubs` nem `club_id`; `db-push.mjs <clube>` aplica toda a cadeia | Um `db-push` para Bragantino/Vila Nova pode **abortar** (id inexistente) e bloquear a evolução de schema desses clubes, ou virar *no-op* silencioso. **Não verificado:** quais já foram aplicadas em cada projeto |
| **A3** | **`--flavor` e `APP_CLUB` não são cruzados** | `resolve_active_club.dart:26` (vazio → Goiás); o script citado no comentário, `check_app_club_enforced.mjs`, **não existe** | `flutter run/build --flavor vilanova` sem `--dart-define=APP_CLUB=vilanova` produz um app com identidade do Vila Nova e **Supabase/Worker do Goiás**. Erro caro e silencioso |
| **A4** | **Vazamento de dados do Goiás para outros clubes (Career Path e ingresso)** | `career_autocomplete.dart:180-198` injeta `goiasPlayers` (218 nomes) para todos os clubes; `ticket_pdf.dart:37-38` usa QR `GOIAS-EC-…` e `:76-77` verde fixo | Usuários do Bragantino/Vila Nova veem/aceitam dados do Goiás num jogo habilitado e recebem ingresso com prefixo do Goiás |
| **A5** | **Sem CI de qualidade** | único workflow é `sync_x_posts.yml`; 372 de 698 arquivos de produção sem teste direto; `core/router` com 0/5 | Regressões em roteamento/auth/checkout só aparecem em uso. Cada deploy é manual (Edge Functions por colagem no dashboard) |
| **A6** | **Preço/status de pedido e ingresso decididos pelo cliente** (S-04) | `create_store_order_for_club` grava o que recebe; policies de `UPDATE` livre em `tickets`/`ticket_orders` | Hoje limitado (sem cobrança real); vira **alto de fato** quando houver pagamento ou acesso ao estádio |

## 3. Médio

| ID | Item | Evidência |
|---|---|---|
| M1 | Grants `anon` em `cpf_is_taken` e `REVOKE FROM PUBLIC` insuficiente no baseline (S-02, S-03) | baseline linhas ~1994–2006 e demais RPCs `_for_club` |
| M2 | Check-in de sócio e pontuação da Arena confiam em parâmetros do cliente (S-05) | `upsert_membership_checkin_ticket_for_club` é `INVOKER` sem validar sócio/janela/local |
| M3 | Workflow com `contents: write` e secrets do X instalando `Scweet` sem pin (SC-01) | `.github/workflows/sync_x_posts.yml` |
| M4 | **Ciclo de dependência de 12 arquivos** `injection_container` ↔ módulo Store ↔ `account_session_cache_guard` | uma **entidade de domínio** (`store/domain/entities/shipping.dart`) importa `injection_container.dart`; cubits e páginas da loja usam `sl<T>()` |
| M5 | **Service locator usado fora da composição** | `sl<T>()` direto em páginas e no router (`app_router.dart:194`, `splash_video_page.dart`, `home_page.dart`); `injection_container.dart` tem 132 dependentes diretos em produção |
| M6 | **`core` depende de `features`** (248 imports) | 114 em `core/router` e 85 em `core/di` (composition roots, esperados); **44 em `core/club`** (o `ClubConfig` é tipado por entidades e catálogos das features), 3 em `core/session` (→ `auth_cubit`, `cart_cubit`), 2 em `core/mock` |
| M7 | **Rotas dependem de `state.extra!`** (24 usos) | `app_router.dart` (ex.: `:301`, `:324`, `:346`, `:435`); recarregar a página no web ou abrir URL direta quebra essas telas |
| M8 | **Registro de clubes em 3 cópias** (Dart, Worker, Edge) | `club_server_config.ts` ×2 + `*_club_config.dart`; auditoria de *drift* está desatualizada |
| M9 | **Documentação operacional desatualizada** | `supabase/MIGRATIONS.md` cita `20260830220000_baseline_marker.sql` (só em `archive/`) e trata só o Goiás como PROD; `arena_record_score` legada recriada pela migration `20260909…` e ausente do baseline |
| M10 | **Comércio "Mock" em release sem guarda** | `injection_container.dart:111,291` registram `MockTicketRepository`/`MockStoreRepository` em todos os builds; "Mock" ≠ dado em memória (persiste no Supabase). Risco de expectativa/naming |
| M11 | **Sem modo offline e *polling* de 45 s** | sem banco local nem fila; ao vivo é `Timer.periodic`; sem Realtime |

## 4. Baixo

| ID | Item | Evidência |
|---|---|---|
| B1 | **Código não utilizado (confirmado)** | `arena_game_card.dart`, `auth_scaffold.dart`, `club_timeline_page.dart`, `circle_reveal_clipper.dart`, `reveal_glow_painter.dart`, `competition_badge.dart`, `section_header.dart`, `core/mock/mock_data.dart`, classe `ArenaHighlightPositionPill`, asset `jersey_cutout_transparent.webp`, dependência `cupertino_icons` (ver §5) |
| B2 | **Bundle pesado e com duplicatas** | `lib/assets` = 823 arquivos / 278 MB; 36 arquivos são cópias byte a byte (`uniform_*` da loja, `sula-2010/01.png == 04.png`) |
| B3 | Nome `goias_app` / `GoiasApp` num app multi-clube | `pubspec.yaml`, `main.dart`, release `goias_app@…` no Sentry |
| B4 | Strings de erro em português fixo fora do ARB | `failures.dart`, repositórios, `ArenaCatalog` |
| B5 | Sentry único e sem tag de clube; `tracesSampleRate=1.0`; sem `beforeSend` (C-02) | `sentry_config.dart`, `main.dart` |
| B6 | Firebase: projeto único e mesma chave de cliente nos 3 flavors | `google-services.json`/plists; recomendar restrição por pacote/bundle |
| B7 | Worker: `image-proxy` sem normalizar chave de cache; web sem CSP; chaves de sync com `!==` (W-01, W-03, W-05) | `src/media/imageProxy.ts`, `src/index.ts` |
| B8 | Comentários obsoletos | `club_assets.dart:102,112` afirmam que `AuthScaffold` é usado, mas não há instanciação; `resolve_active_club.dart:5-6` cita script inexistente |
| B9 | Auditorias de `tooling/multiclub` desatualizadas e que **gravam** em `data_export/` | `audit_*.mjs`; sujam o working tree ao rodar |
| B10 | Scripts one-off sem referência (**possivelmente** não usados) | `scripts/{fix_store_names.py, gen_career_players_sql.mjs, gen_guess_players_sql.mjs, gen_membership_content_sql.mjs, import_store_batch.py, import_store_products.py, remove_bg.py}`, `rb_bragantino_partners/`, `_competitions_pkg/`, `design_refs/` |

## 5. Código morto e legado

Classificação segundo a regra pedida. "Confirmado" = busca por import, símbolo e caminho em todo o repositório sem nenhuma referência de código além da própria declaração (re-verificado por amostragem nesta análise).

### CONFIRMADO COMO NÃO UTILIZADO

| Item | Observação |
|---|---|
| `lib/features/arena/presentation/widgets/arena_game_card.dart` | 0 imports. Contém o vazamento visual `goiasOutfield`, hoje inalcançável |
| `lib/features/auth/presentation/widgets/auth_scaffold.dart` | só citado em **comentários** |
| `lib/features/club/presentation/pages/club_timeline_page.dart` | sem import nem rota; `club_timeline_data.dart` segue em uso |
| `lib/features/splash/presentation/widgets/circle_reveal_clipper.dart`, `reveal_glow_painter.dart` | 0 usos |
| `lib/shared/widgets/competition_badge.dart`, `section_header.dart` | 0 usos (`arena_section_header.dart` é outro arquivo) |
| `lib/core/mock/mock_data.dart` (`MockData`) | só um filtro em `audit_m4_critical_club_leakage.mjs` o menciona |
| `ArenaHighlightPositionPill` (`arena_highlight_card.dart:161`) | classe declarada, nunca instanciada |
| Asset `lib/assets/store/promo/jersey_cutout_transparent.webp` | empacotado, sem referência |
| Dependência `cupertino_icons` | 0 imports e 0 usos de `CupertinoIcons` |

### POSSIVELMENTE NÃO UTILIZADO

- **Jogo Penalty:** oculto no `ArenaCatalog` (`arena_catalog.dart:8-16`), mas com rotas `/arena/penalty` registradas (`app_router.dart:258,432`) e `penalty_logic_test.dart`; inalcançável pela UI. Alcançável por URL no web.
- Os 7 scripts one-off acima e as pastas `rb_bragantino_partners/`, `_competitions_pkg/`, `design_refs/`.
- `supabase/*.sql` soltos (114): histórico/seeds; `supabase/squad_members_add_lifecycle_columns.sql` duplica uma migration.
- `supabase/functions/notifications-test-trigger`: ferramenta manual de operador.
- Endpoints *legacy* do Worker (`src/football/team.ts:20`, `teamSeason.ts:25`) mantidos para app já publicado; uso por clientes antigos **NÃO VERIFICADO**.

**Não é morto (apesar de parecer):** `MockTicketRepository`/`MockStoreRepository` (registrados no DI), `data_export/` (usado por testes de `tooling`), `assets_gen/` (usado por `flutter_launcher_icons`), `archive/` (legado intencional).

**Marcadores:** não há `FIXME`, `HACK`, `XXX`, `WORKAROUND` nem `@deprecated`. O único `TODO` real é `lib/core/club/bragantino_club_config.dart:49`; há blocos de `PLACEHOLDER`/`DATA_GAP`/`ASSET_GAP` do Bragantino e do Vila Nova nos respectivos `*_club_config.dart`.

## 6. Acoplamento e blast radius

Calculado sobre as arestas `imports` do grafo, **somente entre arquivos de produção de `lib/`** (698 arquivos Dart); imports vindos de `test/` foram excluídos de propósito para não inflar o acoplamento.

### 6.1 Arquivos mais dependidos

| Arquivo | Dependentes diretos | Transitivos | Linhas |
|---|---:|---:|---:|
| `core/theme/app_colors.dart` | 223 | 387 | 164 |
| `core/theme/app_spacing.dart` | 201 | 273 | 23 |
| `core/l10n/l10n_extensions.dart` | 190 | 275 | 6 |
| `core/club/club_config.dart` | 146 | 296 | 71 |
| `core/di/injection_container.dart` | 132 | 201 | 308 |
| `shared/state/load_status.dart` | 108 | 275 | 1 |
| `core/error/result.dart` | 90 | 277 | 17 |
| `shared/widgets/content_container.dart` | 70 | 92 | 67 |
| `shared/widgets/goias_loading_indicator.dart` | 38 | 60 | 92 |
| `features/match/domain/entities/match.dart` | 37 | 243 | 69 |

Mudar a assinatura de `club_config.dart`, `result.dart` ou `load_status.dart` toca centenas de arquivos. Conferido: as configs específicas de cada clube quase não têm dependentes em produção (`goias_club_config.dart` 2, `bragantino_` 1, `vilanova_` 1 — o `club_registry` e o código morto `mock_data.dart`); o fan-in alto que aparece quando se contam testes (66 e 35) vem dos próprios testes, não de acoplamento de produção ao Goiás.

### 6.2 Maiores arquivos (linhas)

`guess_player_catalog.dart` (2.259, catálogo de dados), `checkout_page.dart` (1.367), `product_detail_page.dart` (1.142), `passport_trajectory_page.dart` (1.133), `lineup_matches.dart` (950), `career_players.dart` (886), `career_path_page.dart` (866), `app_router.dart` (852). São candidatos a *God widgets/objects*: o roteador concentra 87 rotas, o DI concentra o grafo inteiro e as páginas de loja/passaporte acumulam estado e layout.

### 6.3 Camadas e ciclos

- **Domínio limpo:** 0 imports de `domain` para `presentation` ou `data` dentro da mesma feature.
- **Um** import de `presentation` de uma feature para o `data` de outra (`squad_member_detail_page` → `profile/data/social_links_data`).
- `shared` → features: 6 imports (por exemplo `club_badge` → `match/.../team.dart`, `session_expiry_listener` → `auth_cubit`).
- **Um único ciclo** (12 arquivos) — ver M4.

## 7. Quick wins (baixo risco, bom retorno)

1. Aplicar e testar a migration `20261002040000_harden_passport_per_user_rpcs.sql` (já escrita, **não aplicada**), respeitando o risco A2 (A1).
2. Filtrar `goiasPlayers` por clube e parametrizar prefixo do QR e cor do PDF (A4).
3. Falhar o build quando `--flavor` ≠ `APP_CLUB`, ou criar de fato `check_app_club_enforced.mjs` (A3).
4. Adicionar CI com `flutter analyze`, `flutter test` e `npm run test:worker` (A5).
5. Atualizar `supabase/MIGRATIONS.md` (baseline canônico, 3 projetos, `db-push.mjs`) (M9).
6. Remover o código confirmado como morto e a dependência `cupertino_icons` (B1) e deduplicar os 36 assets (B2).
7. Pinar `Scweet` e as actions por SHA e reduzir permissões do workflow (M3).

## 8. Mudanças de alto risco (cuidado antes de tocar)

| Área | Por quê |
|---|---|
| `core/club/club_config.dart` e `result.dart` | 146 e 90 dependentes diretos; blast radius de 296 e 277 arquivos |
| `core/di/injection_container.dart` | 132 dependentes; participa do único ciclo; ordem de registro importa (`ClubConfig` primeiro) |
| `core/router/app_router.dart` | 0 testes; `redirect` com 6 estágios; muitas rotas dependem de `state.extra!` |
| Cadeia `supabase/migrations` | compartilhada pelos 3 projetos; migrations só-Goiás misturadas; efeito depende do banco vivo de cada clube |
| RPCs `SECURITY DEFINER` (passaporte, arena, loja, sócio) | mexer em grants/assinaturas quebra o app publicado; assinaturas precisam ser preservadas |
| Registro de clubes (3 cópias) | divergir entre Dart, Worker e Edge quebra push/dados de um clube sem erro óbvio |
| Edge Functions | deploy manual e sem testes diretos em `index.ts` |

## 9. Próximos passos sugeridos (ordem técnica; nenhum foi implementado)

**Fechar A1 (S-01).** A migration de hardening existe (`20261002040000_harden_passport_per_user_rpcs.sql`). **Vila Nova: concluído em 2026-10-02** — aplicada e registrada pelo `db-push` filtrado, grants e corpos conferidos no banco, teste de IDOR passou inteiro (ver S-01 em [security-overview.md](security-overview.md)). **Goiás: concluído em 2026-10-02** — histórico reconciliado por repair (10 Goiás-only + `0915`), `040000` aplicada e registrada pelo push normal, teste de IDOR passou. **Bragantino:** efeito já presente no banco, mas a `040000` não está registrada e o teste não rodou; A1 continua aberto para ele até o passo 5:

1. Resolver primeiro o risco A2 da cadeia compartilhada de migrations, ou encontrar uma forma segura de aplicar **somente** esta migration.
2. Aplicar `20261002040000_harden_passport_per_user_rpcs.sql` individualmente em cada projeto/clube.
3. Rodar `tooling/passport_security/run_authenticated_idor_test.mjs` em cada projeto.
4. Verificar os grants reais de `anon`, `authenticated` e `service_role` (nas `passport_*` e também, para S-02/S-03, em `arena_*` e `cpf_is_taken`, que esta migration **não** altera).
5. Só depois reclassificar S-01/A1 como resolvido.

**Demais prioridades:**

6. Tornar o build à prova de divergência de flavor (A3) e corrigir os vazamentos de A4.
7. Criar o CI mínimo (A5) e cobrir `app_router` (redirect), `auth_repository_impl` e `push_notification_service`.
8. Tratar M4–M6: tirar `sl<T>()` de entidades de domínio e quebrar o ciclo da loja; avaliar inverter a dependência `core/club` → features (por exemplo, configs referenciando *providers* de conteúdo).
9. Só então: higiene (B1–B10), peso de assets e atualização de documentação.

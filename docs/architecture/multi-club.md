# Multi-clube

> Como Goiás EC, RB Bragantino e Vila Nova FC compartilham código e configuração, e onde a configuração de um clube **vaza** para outro. Análise estática no commit `e90de17`; nada foi executado em runtime. Os documentos de etapa em `docs/multiclub/` descrevem o histórico do rollout — leia-os como histórico: alguns falam em 2 clubes e em "Bragantino sem Worker", e o código atual tem 3 clubes com o Bragantino quase todo ligado.

## 1. Mecanismo

### 1.1 Como o clube é escolhido

1. **Build:** `--dart-define=APP_CLUB=<code>`, lido em `lib/core/club/resolve_active_club.dart`. Vazio → Goiás (silencioso); valor desconhecido → `StateError` (*fail-fast*).
2. **Registro:** `lib/core/club/club_registry.dart` contém `goias`, `bragantino` e `vilanova`.
3. **Config:** `ClubConfig` (`club_config.dart`) agrega `identity`, `branding`, `assets`, `integrations` (Worker, Supabase, redes), `capabilities`, `productNames`, `passportContent`, `membershipProgram`, `institutionalContent` e `ticketsContent`. Uma classe de config por clube: `goias_/bragantino_/vilanova_club_config.dart`.
4. **Supabase:** `SupabaseConfig.configure(club)` lê URL/chave do `ClubConfig` e **lança erro se faltar** — nunca cai no Goiás.
5. **Isolamento no Flutter:** `club_scoped_fallback.dart` (devolve `null` se o clube não tem fallback), `club_scoped_storage_key.dart` (chaves `<code>:<chave>`), `capability_route_gate.dart` (rota bloqueada por capability).

### 1.2 Seleção por plataforma

| Camada | Mecanismo |
|---|---|
| Dart | `--dart-define=APP_CLUB=<code>` (comandos canônicos em `tool/flavor_build_commands.json`) |
| Android | `productFlavors` na dimensão `club`; `applicationId = br.com.fanhub.<clube>`; `google-services.json` por flavor (`android/app/build.gradle.kts`) |
| iOS | 3 *schemes* + `xcconfig` por flavor; *Run Script* copia o `GoogleService-Info.plist` de `ios/Runner/Firebase/${APP_CLUB}/` e falha se `APP_CLUB` vier vazio |
| Web | `node tool/build_web_flavor.mjs <code>` (usa `tool/web_flavors/<code>.json`, restaura `web/` no fim) |
| Worker | um deploy por clube, mesmo `src/`; `CLUB_CODE` em `wrangler*.toml` funciona como allowlist |
| Supabase | **um projeto por clube**, cadeia única `supabase/migrations`, aplicada por `db-push.mjs <clube>` |
| Edge Functions | código compartilhado, com o registro dos 3 clubes |
| Firebase | **projeto único** para os 3 clubes (um app registrado por pacote/bundle) |

### 1.3 Comparativo por dimensão

| Dimensão | Goiás | Bragantino | Vila Nova |
|---|---|---|---|
| Nome do app | Goiás EC | Red Bull Bragantino | Vila Nova FC |
| Produtos | Arena Esmeraldina · Passaporte Esmeraldino · Goiás Store · Sócio Esmeralda | Arena · Passaporte · RedBull Shop · Massa Bruta | Arena do Tigre · Passaporte Colorado · Nação Colorada · Sócio Tigrão |
| Cor primária (claro) | `#004C1B` | `#D2003C` | `#C33D41` |
| Splash em vídeo | sim | não | não |
| Competição principal | Série B | Brasileirão (Série A) | Série B |
| Notícias (fonte) | HTML do site do clube | API JSON do site do clube | HTML do site do clube |
| Cron do Instagram | 3×/dia | 2×/dia | nenhum (GitHub Actions) |
| Prefixo de pedido | `GOI` | `BRA` | `VIL` |
| Loja / Ingressos / Escalação da torcida | sim / sim / sim | sim / **não** / **não** | **não** / sim / **não** |
| Conteúdo de sócio | planos próprios + regulamento | planos externos | Sócio Tigrão (checkout externo) |

Valores específicos (cores, ids de time, hosts, URLs) estão em `lib/core/club/*_club_config.dart`, `wrangler*.toml` e `tool/web_flavors/*.json`. Identificadores de projeto e UUIDs de clube ficam em `tooling/multiclub/supabase_projects_registry.json` e `clubs_registry.json`.

### 1.4 Internacionalização

`lib/l10n/app_{pt,en,es}.arb` usa ICU `select` por `clubCode` (17 *selects* em `pt`). Verificado: nenhuma string com Goiás/Esmeraldino/Verdão fora de um ramo `goias{}`. Não há ARB por clube.

## 2. Vazamentos de configuração (um clube recebendo dado/comportamento do Goiás)

Cada item abaixo foi **conferido no código** nesta análise.

| # | Local | O que acontece | Classe |
|---|---|---|---|
| 1 | `features/arena/games/career_path/pages/career_path_page.dart:136-140` + `career_autocomplete.dart:133,180-198` | O autocomplete do *Career Path* sempre inclui a lista fixa `goiasPlayers` (218 nomes), sem filtrar pelo clube ativo. O jogo está habilitado para Bragantino e Vila Nova, então o torcedor desses clubes vê/aceita nomes de jogadores do Goiás | **Vazamento confirmado** (comportamento) |
| 2 | `features/ticket/presentation/ticket_pdf.dart:37-38` | O QR do ingresso usa o prefixo fixo `GOIAS-EC-` (`DEMO-GOIAS-EC-` em modo demo, que é o modo de todos os clubes hoje). O Vila Nova tem ingressos habilitados | **Vazamento confirmado** (dado) |
| 3 | `ticket_pdf.dart:76-77` | PDF do ingresso com verde fixo `#004C1B` (Goiás) mesmo para o Vila Nova | **Vazamento confirmado** (visual) |
| 4 | `features/arena/presentation/widgets/arena_game_card.dart:42,111,118` + `arena/shared/arena_colors.dart:10` | Gradiente do card da Arena usa `ArenaColors.goiasOutfield` (verde do Goiás). *Nota:* esse arquivo (`arena_game_card.dart`) é **código não utilizado** (ver [technical-debt.md](technical-debt.md)), então o vazamento visual **não é alcançável hoje** | Vazamento no código, sem efeito em runtime |
| 5 | `player_identity_share_card.dart`, `tactical_share_card.dart` | `ArenaColors.goiasKeeper` (amarelo de goleiro) | Tolerável (cor de uniforme, só o nome é "goias") |

### Riscos que não são vazamento em runtime

- **Migrations só-Goiás na cadeia comum.** As 11 migrations `20260930010000` … `20261002030000` (correções de dados do Goiás, mais a `…030000` ainda *untracked*) estão na mesma cadeia que `db-push.mjs <clube>` aplica a todos. Nenhuma filtra por `club_id`/`public.clubs`. Um próximo `db-push` para Bragantino ou Vila Nova tentaria rodá-las: algumas **abortariam** (por exemplo, "career_players: id não encontrado") e outras virariam *no-op* silencioso. Quais migrations cada projeto já aplicou depende do banco vivo (**NÃO VERIFICADO**), e não encontrei decisão documentada de pulá-las para os outros clubes.
- **`--flavor` e `APP_CLUB` não são cruzados.** Nada no Gradle ou no Dart exige que coincidam: `flutter run --flavor vilanova` **sem** `--dart-define=APP_CLUB=vilanova` gera o app com `applicationId` do Vila Nova e configuração do Goiás (Supabase e Worker do Goiás). O comentário em `resolve_active_club.dart:5-6` cita `tooling/multiclub/check_app_club_enforced.mjs`, que **não existe**; a "garantia" atual é só uma verificação sobre `tool/flavor_build_commands.json`.
- **Allowlist do proxy de imagens** (`src/media/imageProxy.ts:12` e `lib/shared/utils/image_proxy.dart:15-18`) só conhece o host de imagens do Goiás. Se os hosts de fotos do Bragantino/Vila Nova não enviarem CORS, ficam sem foto no Flutter Web — **NÃO VERIFICADO**.
- **Sentry único** para os 3 clubes e sem tag de clube; eventos só se distinguem por release/bundle.
- **KV social compartilhado** pelos 3 Workers (isolamento por prefixo de chave, por convenção).
- **Registro de clubes em três lugares** (Dart, Worker, Edge Functions), com risco de *drift*.

## 3. Auditorias existentes estão desatualizadas

`tooling/multiclub/audit_*.mjs` descrevem exceções pretendidas, mas hoje:

| Auditoria | Resultado observado | Leitura |
|---|---|---|
| `audit_multiclub_hardcodes.mjs` | aponta `vilanova_club_config.dart` como inesperado | allowlist (linha ~266) só lista goias/bragantino |
| `audit_multiclub_runtime_hardcodes.mjs` | `driftFree: false` (1 registro de servidor vs 3 reais) | assume um Worker só |
| `audit_m4_critical_club_leakage.mjs` | `m4CriticalLeakageReady: false` | resíduos de um *snapshot* antigo (falsos positivos) |
| `audit_m4_3_flavor_registry_drift.mjs` | `appClubEnforcedEverywhere: true` | só confere o JSON de comandos |

**Nenhuma** detecta os vazamentos 1–3 acima nem as migrations só-Goiás.

> **Cuidado operacional:** os `audit_*.mjs` **gravam** em arquivos versionados de `data_export/goias/player_reconciliation/`. Rodá-los suja o working tree (ocorreu durante esta análise e foi revertido). Prefira rodá-los em um *worktree* ou revise o `git status` depois.

## 4. Capabilities e o que é exclusivo do Goiás

A matriz por clube está em [feature-map.md](feature-map.md) §1. Exclusivos do Goiás hoje: escalação da torcida (com elenco fixo em `goias_squad.dart`), vídeo de splash, fallback offline dos minijogos (Bragantino e Vila Nova dependem do Supabase do clube e lançam `ClubDataUnavailableException` se estiver vazio), canções (Vila Nova não tem) e a combinação loja + ingressos.

## 5. Recomendações (não implementadas)

Em ordem de custo/benefício:

1. Corrigir os vazamentos 1–3 (filtrar `goiasPlayers` por clube; prefixo do QR e cor do PDF a partir de `ClubConfig`).
2. Tornar a escolha de clube **à prova de erro de build**: falhar quando `--flavor` e `APP_CLUB` divergirem (ou criar de fato o `check_app_club_enforced.mjs`).
3. Decidir e documentar o destino das migrations só-Goiás para os outros clubes (mover para `supabase/*.sql` soltos ou condicionar por `public.clubs`).
4. Atualizar as auditorias para 3 clubes e incluir os padrões acima.
5. Avaliar tag de clube no Sentry e um único registro de clubes gerado (em vez de três cópias).

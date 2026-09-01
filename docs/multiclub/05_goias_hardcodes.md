# 05 — Hardcodes de Marca e Regras Específicas do Goiás

> Todo lugar onde o código pressupõe "este app é exclusivamente do Goiás". Gerado em 2026-09-01.

## 1. Strings de marca — l10n vs. hardcoded em Dart

**l10n é a portadora principal.** `lib/l10n/app_pt.arb`/`app_en.arb`/`app_es.arb` carregam a maioria esmagadora do texto de marca ("Goiás", "Verdão", "Esmeraldino(a)", "Arena Esmeraldina", "Passaporte Esmeraldino", "Sócio Esmeralda", "Goiás Store", "Serrinha" etc.) — **~150+ strings distintas** por locale. Isso é esperado/correto — é exatamente a camada que uma config white-label deve manter localizada por clube.

**Hardcoded FORA do l10n (o problema real) — por arquivo:**

| Arquivo:linha | Trecho | Classificação |
|---|---|---|
| `lib/main.dart:71-78` | `class GoiasApp` / `_GoiasAppState` | BRANDING (nome de classe) |
| `lib/main.dart:121` | `title: 'Goiás EC'` (título do MaterialApp, fora do l10n) | BRANDING |
| `lib/shared/widgets/goias_loading_indicator.dart:10,30` | `class GoiasLoadingBadge`/`GoiasLoadingIndicator` | BRANDING (usado em ~30 arquivos como spinner padrão) |
| `lib/features/home/presentation/widgets/goias_bottom_navigation_bar.dart:24-25` | `class GoiasBottomNavigationBar` | BRANDING |
| `lib/features/home/presentation/widgets/home_brand_header.dart:28` | `'GOIÁS ESPORTE CLUBE'` | BRANDING |
| `lib/features/club/presentation/widgets/club_header.dart:21` | `'GOIÁS ESPORTE CLUBE'` | BRANDING |
| `.../tactical_share_card.dart:46,144` | `'GOIÁS ESPORTE CLUBE'`, `'GOIÁS • ${top.coach.period}'` | BRANDING (texto embutido no card de compartilhamento) |
| `.../player_identity_share_card.dart:42` | `'GOIÁS ESPORTE CLUBE'` | BRANDING |
| `.../tactical_coach_detail_sheet.dart:21` | `'Goiás • ${coach.period}'` | BRANDING |
| `.../player_identity_reference_sheet.dart:22` | `'Goiás • ${reference.period}'` | BRANDING |
| `.../tactical_identity_result_page.dart:76,409,465` | `'Goiás ${...}'` (×3) | BRANDING |
| `.../player_identity_result_page.dart:64,457` | `'Goiás ${...}'` (×2) | BRANDING |
| `.../passport_match_list_page.dart:189`, `.../passport_match_ticket_v2.dart:224` | `text: 'Goiás'` | BRANDING |
| `.../passport_match_row_v1.dart:34`, `passport_match_ticket_v2.dart:46`, `passport_trajectory_page.dart:1032`, `passport_memorable_match_picker.dart:137` | `'Goiás x ${match.opponent}'` (fallback) | BRANDING |
| `.../product_detail_page.dart:270-271` | `' — Goiás Store\n...'` (texto de compartilhamento) | BRANDING |
| `lib/features/store/domain/entities/shipping.dart:45-50` | `PickupInformation({storeName='Goiás Store', street='Av. 85, 3277', city='Goiânia', state='GO', zipCode='74823-310'})` | BRANDING + CONFIGURAÇÃO (endereço real como default de construtor) |
| `.../social_empty_state.dart:18`, `.../social_links_data.dart:36` | `'https://youtube.com/@TVGoias'` | BRANDING/CONFIGURAÇÃO |
| `.../ticket_pdf.dart:242` | `'GOIAS-EC-${ticket.id}'` (payload do QR) | BRANDING/CONFIGURAÇÃO |
| `.../mock_ticket_fixture.dart:21,34,47` | `venueLabel: 'Goiás E.C.'` (×3) | BRANDING (dado mock) |
| `.../membership_contact_config.dart:6-7` | `'(62) 99472-2541'`, `'https://wa.me/5562994722541'` | CONFIGURAÇÃO (telefone real hardcoded, não env-driven) |
| `lib/features/arena/games/quiz/quiz_models.dart:5,10` | `enum QuizDifficulty { torcedor, esmeraldino, fanatico }` | BRANDING (valor de enum embutido no domínio) |
| `lib/features/passport/domain/passport_level.dart:12,16` | `lendaEsmeraldina` (enum + lógica de negócio) | BRANDING |
| `lib/features/club/data/club_songs_data.dart` | Letras completas de ~15 hinos/cânticos | DADO |
| `lib/features/club/data/club_history_data.dart`, `club_timeline_data.dart` | Narrativa de fundação, "Estádio Hailé Pinheiro", "Serrinha" | DADO |
| `lib/features/profile/data/legal_documents_data.dart` | ~10 menções a "Goiás Esporte Clube" no texto de Termos/Privacidade | DADO |
| `lib/features/arena/games/quiz/quiz_questions.dart` | ~80 strings de trivia mencionando "Goiás" | DADO (conteúdo em massa) |
| `.../career_players.dart`, `goias_players.dart` | `class GoiasPlayer`, `goiasPlayers` (~215 nomes), `team: 'Goiás'` | DADO + BRANDING |
| `.../lineup_matches.dart` | ~30 `home:`/`away: 'Goiás'`, `teamToGuess: 'Goiás'` | DADO |
| `.../guess_player_catalog.dart` | ~30 `academyClub: 'Goiás'` | DADO |
| `.../membership_plans_catalog.dart:17,33,49,56,77,92,98,119,125` | "desconto na Goiás Store", "Sócio Esmeralda" etc. | DADO/BRANDING |
| `.../partners_data.dart` | Lista de patrocinadores específica do Goiás | DADO |
| `lib/core/mock/mock_data.dart:15-16,92,114,136,147` | `Team.goiasId`, `name: 'Goiás'`, `stadium: 'Serrinha'` (×4) | DADO/CONFIGURAÇÃO |
| `lib/shared/domain/brazilian_states.dart:20` | `BrazilianState(code: 'GO', name: 'Goiás')` | **NÃO é branding** — é o estado brasileiro Goiás (geografia), sem relação com o clube. Falso positivo, ignorar. |

## 2. Cores — `lib/core/theme/app_colors.dart`

Duas paletas (`AppColors.light`, `AppColors.dark`), 16 tokens cada, via `ThemeExtension`.

**Valores exatos (tema claro)**: `background #F6F8F7`, `surface #FFFFFF`, `surfaceRaised #FFFFFF`, `primary #004C1B`, `onPrimary #FFFFFF`, `secondary #E6F0E9`, `darkGreen #003712`, `deepGreen #00280D`, `ctaGreen #169447`, `gold #A9822E`, `textPrimary #121815`, `textSecondary #5E6963`, `textHint #98A19C`, `border #E0E6E3`, `error #A9822E` (deliberadamente dourado, nunca vermelho — regra do projeto), `success #278A52`.

**Tema escuro**: `background #09110C`, `surface #111A14`, `surfaceRaised #17231C`, `primary #1F8A4D`, `onPrimary #FFFFFF`, `secondary #17271C`, `darkGreen #003712`, `deepGreen #00280D`, `ctaGreen #2FA968`, `gold #B8904A`, `textPrimary #F4F7F5`, `textSecondary #AAB5AF`, `textHint #707B75`, `border #26342B`, `error #B8904A`, `success #2D8B57`.

**Avaliação de nomenclatura**: majoritariamente genérica/semântica (`primary`, `secondary`, `background`, `error`, `success`) — bom pra white-labeling. Mas `darkGreen`, `deepGreen` e `ctaGreen` têm nome de matiz literal em vez de papel (deveriam ser algo como `heroAccent`/`ctaAccent`), o que hardcoda a suposição de que a cor do clube é verde. `gold` também é nome de cor-literal representando o que semanticamente é "o token de erro/destaque". **Classificação: CONFIGURAÇÃO** — este arquivo é o melhor candidato pra virar `ClubConfig.colors`; só os 3 tokens de matiz precisam ser renomeados pra papel antes da extração.

Além disso, `pubspec.yaml:186,191-192` hardcoda `#004C1B` mais três vezes (`flutter_launcher_icons.adaptive_icon_background`, `web.background_color`, `web.theme_color`) e `pubspec.yaml:195,197` hardcoda `#F6F8F7` duas vezes (`flutter_native_splash.color`) — duplicando os valores de `AppColors` fora do sistema de cores Dart inteiramente. **CONFIGURAÇÃO** — um pipeline de build white-label precisaria templatizar isso também.

## 3. Assets/logos — `lib/core/theme/app_assets.dart` + `pubspec.yaml`

Todo asset em `AppAssets` (55 linhas) é específico do clube por design — não há path genérico/placeholder: `goiasCrest` → `lib/assets/branding/logo.svg`; `goiasCrestBadge` → `goias_crest.png` (**usado numa regra de negócio hardcoded**, ver §5); `goiasCrest3d`, `loginBackground`, `stadium`, `matchHero`, `tacticsBoardIllustration`, `arenaStadiumIcon`/`Photo` — todas as ilustrações têm o tingimento verde/duotônico **assado na própria imagem**, não aplicado em runtime. `storeBanner` → `store_banner_green.png` (o próprio nome do arquivo carrega a cor do clube).

**Classificação: ASSET.** Todo `AppAssets` precisaria virar bundle de asset por clube; os próprios nomes das constantes (`goias*`) também são identificadores acoplados à marca.

O bloco de assets do `pubspec.yaml` declara ~120 pastas individuais de fotos de produto com nomes gravados com `goias`/`esmeraldino` (ex.: `bag_lateral_goias`, `camisa_reserva_goias_alviverde`), mais pastas de títulos do clube (`campeonato-goiano`, `libertadores-2006`, `copa-do-brasil-1990`, `sula-2010`, `brasileirao-2005`) que codificam o histórico de troféus deste clube específico na própria estrutura de pastas. **ASSET + DADO** — uma versão white-label precisa disso templatizado/gerado por clube em vez de declarado à mão.

## 4. IDs hardcoded — integração externa

**O achado mais importante desta categoria:**

```dart
// lib/features/match/domain/entities/team.dart:37
static const int goiasId = 1863;
```

O ID numérico do time no OneFootball, hardcoded direto como constante Dart numa entidade de domínio — não vem de config/resposta de repositório. Linha 39:
```dart
bool get isGoias => id == goiasId || name.toLowerCase().contains('goi');
```
**Classificação: CONFIGURAÇÃO** (deveria vir de `ClubConfig`, espelhando como o Worker já externaliza o mesmo id via `GOIAS_ONEFOOTBALL_SLUG`). Consumido em `mock_data.dart:15` e `calendar_day_cell.dart:80`.

**O Worker, por contraste, faz isso certo — vale reaproveitar o padrão**: `src/football/_lib/config.ts:1-45` lê `GOIAS_ONEFOOTBALL_SLUG`/`ONEFOOTBALL_COMPETITION_SLUG` do `Env`, nunca hardcoda o id/slug na lógica. Valores reais vivem em `wrangler.toml:29,35` — config, não código.

**Hardcoding remanescente no Worker (mais fraco, mas real)**:
- `src/index.ts:29,33` — rotas hardcoded como `/api/football/team/goias` (nome do clube embutido no contrato de URL, não só num valor de config)
- `src/football/team.ts:22,24` / `teamSeason.ts:23` / `standings.ts` — nomes de função `handleGoiasTeam`, `handleGoiasTeamSeason`, `requireGoiasOneFootballSlug`
- `src/football/team.ts:15`, `standings.ts:9` — `const COMPETITION_NAME = 'Brasileirão Série B';` literal, não env-driven
- `src/social/providers/youtube_provider.ts:3,67` — `TV_GOIAS_HANDLE = '@TVGoias'`
- `src/social/providers/x_provider.ts:29`, `instagram_sync.ts:155` — fallback `'Goiás Esporte Clube'`
- `src/news/article.ts:26`, `list.ts:19` — User-Agent `'GoiasAppBot/1.0'`
- `src/social/data/x_posts.json` — dado estático de fallback (esperado, é seed)

## 5. Regras de negócio / condicionais que assumem Goiás especificamente

| Arquivo:linha | Trecho | Classificação |
|---|---|---|
| `lib/shared/widgets/club_badge.dart:54-61` | `if (team.isGoias) { ...Image.asset(AppAssets.goiasCrestBadge...) }` | REGRA DE NEGÓCIO — o widget de crest de uso global especial-casa "é o Goiás" pra forçar asset local em vez do logo de rede. **Este é o ponto de dependência crucial**: qualquer outro clube precisa do seu próprio ramo equivalente. |
| `.../crowd_lineup_page.dart:71-72` | `bool get _isGoiasHome => widget.match.homeTeam.name.toLowerCase().contains('goi');` | REGRA DE NEGÓCIO — detecção por string duplicada (não reaproveita `Team.isGoias`) |
| `.../passport_match_ticket_v2.dart:215` | `bool _isGoias(String team) => team.toLowerCase().contains('goiás');` | REGRA DE NEGÓCIO — uma TERCEIRA reimplementação independente do mesmo check, desta vez casando com `'goiás'` (com acento) em vez de `'goi'` |
| `lib/features/match/domain/entities/team.dart:39` | `bool get isGoias => id == goiasId \|\| name.toLowerCase().contains('goi');` | REGRA DE NEGÓCIO — versão canônica, mas ainda com fallback de string hardcoded numa entidade de domínio |
| `.../standing.dart:23`, `standing_dto.dart:20,36,49` | `final bool isGoias;` propagado DTO → entidade | REGRA DE NEGÓCIO — "o clube que nos importa" é campo de primeira classe no modelo de classificação em vez de lookup de config |
| `lib/features/squad/domain/club_history_entry.dart:8,18,33` | `isGoias = false`, `json['is_goias']` | REGRA DE NEGÓCIO (mesmo padrão, + coluna Supabase literalmente chamada `is_goias`) |
| `.../career_models.dart:16,24,27`, `career_player_repository.dart:84` | campo `isGoias` + `json['is_goias']` | REGRA DE NEGÓCIO (mesmo padrão de coluna Supabase) |
| `.../football_repository.dart:39`, `football_repository_impl.dart:68,70`, `football_remote_data_source.dart:68` | `getGoiasSnapshot()` — o método central do repositório principal de partidas se chama literalmente assim | REGRA DE NEGÓCIO / naming lock-in — chamado de `home_cubit.dart:32`, `games_cubit.dart:89`, `membership_cubit.dart:34`, `live_match_poller.dart:80`, `mock_ticket_repository.dart:37,403` |
| `.../next_match_hero.dart:103` | `if (match.homeTeam.isGoias) ...` | REGRA DE NEGÓCIO (consumidor do campo acima, decide arte de camisa mandante/visitante) |
| `.../standings_row.dart:19,24,37,63` | `final bool isGoias;` controla cor/peso de fonte de destaque na tabela | REGRA DE NEGÓCIO |
| `.../career_table.dart:210`, `squad_member_detail_page.dart:365` | `entry.isGoias` controla destaque de linha | REGRA DE NEGÓCIO |

## 6. Enums/constantes que assumem clube único

| Arquivo:linha | Trecho | Classificação |
|---|---|---|
| `lib/features/arena/games/quiz/quiz_models.dart:5` | `enum QuizDifficulty { torcedor, esmeraldino, fanatico }` | CONFIGURAÇÃO — a dificuldade intermediária tem literalmente o nome do gentílico da torcida |
| `lib/features/passport/domain/passport_level.dart:9-16` | `enum PassportLevel { ..., lendaEsmeraldina }` com lógica de progressão atrelada | CONFIGURAÇÃO |
| `lib/features/match/domain/entities/team.dart:37` | `static const int goiasId = 1863;` | CONFIGURAÇÃO (instância principal desta categoria, ver §4) |
| `pubspec.yaml:62-69,182-198` | Pastas de asset de título (`campeonato-goiano`, `libertadores-2006`, `sula-2010`, `copa-do-brasil-1990`, `brasileirao-2005`), cores de ícone/splash | CONFIGURAÇÃO/ASSET — o histórico de troféus deste clube está enumerado como nome de pasta em vez de data-driven |
| `lib/features/store/domain/entities/shipping.dart:43-51` | `PickupInformation` com endereço real da Goiás Store como default | CONFIGURAÇÃO |
| `.../membership_contact_config.dart:6-7` | Número de WhatsApp real como constante estática | CONFIGURAÇÃO |

---

## Resumo pro desenho do `ClubConfig`

**Camadas mais limpas** (fáceis de extrair): `lib/core/theme/app_colors.dart` (só precisa renomear 3 tokens) e o `src/football/_lib/config.ts` do Worker (já é env-driven — replicar esse padrão pro resto do app).

**Bloqueios mais difíceis**:
1. O conceito `isGoias`/`goiasId` duplicado em `Team`, `Standing`, `ClubHistoryEntry`, `CareerEntry` + duas reimplementações ad-hoc por string-match (`crowd_lineup_page.dart`, `passport_match_ticket_v2.dart`) — todas precisam colapsar num único check dirigido por `ClubConfig`.
2. `AppAssets`/`club_badge.dart`'s branch hardcoded "sempre renderiza o PNG local do Goiás".
3. O método de repositório literalmente chamado `getGoiasSnapshot()`.
4. O volume de *conteúdo* específico do clube (perguntas de quiz, elencos de jogadores, letras de hino, histórico de títulos, catálogo de loja) que hoje está compilado em fonte Dart em vez de tratado como dado seed por clube.

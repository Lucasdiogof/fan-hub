# 10 — `ClubConfig` / White Label

> Proposta de design — nada implementado. Objetivo: eliminar os hardcodes catalogados em `05_goias_hardcodes.md` sem mudar UM PIXEL do comportamento visual atual do Goiás. Gerado em 2026-09-01.

## Formato

```dart
class ClubConfig {
  const ClubConfig({
    required this.clubId,          // 'goias' — bate com clubs.id no Supabase
    required this.slug,
    required this.name,            // 'Goiás Esporte Clube'
    required this.shortName,       // 'Goiás'
    required this.fanDemonym,      // 'Esmeraldino' — resolve QuizDifficulty.esmeraldino, PassportLevel.lendaEsmeraldina
    required this.colors,          // ClubColors — mesmo shape de AppColors hoje
    required this.assets,          // ClubAssets — mesmo shape de AppAssets hoje
    required this.arenaName,       // 'Arena Esmeraldina'
    required this.passportName,    // 'Passaporte Esmeraldino'
    required this.storeName,       // 'Goiás Store'
    required this.membershipProgramName, // 'Sócio Esmeralda'
    required this.orderPrefix,     // 'GOI' — substitui generate_store_order_number()
    required this.oneFootballTeamId,      // substitui Team.goiasId=1863
    required this.oneFootballSlug,        // 'goias-1863'
    required this.pickupInformation,      // substitui PickupInformation defaults hardcoded
    required this.contactWhatsapp,        // substitui membership_contact_config.dart
    required this.features,        // ClubFeatureFlags — ver 13_feature_flags mais abaixo
  });

  final String clubId;
  final String slug;
  final String name;
  final String shortName;
  final String fanDemonym;
  final ClubColors colors;
  final ClubAssets assets;
  final String arenaName;
  final String passportName;
  final String storeName;
  final String membershipProgramName;
  final String orderPrefix;
  final int oneFootballTeamId;
  final String oneFootballSlug;
  final PickupInformation pickupInformation;
  final String contactWhatsapp;
  final ClubFeatureFlags features;
}
```

`ClubColors`/`ClubAssets` são literalmente `AppColors`/`AppAssets` de hoje, promovidos de `static const` pra campos de instância (ver §2/§3 abaixo) — sem mudar nenhum VALOR pro Goiás, só o mecanismo de acesso.

## Como fica disponível no app

```dart
sl.registerLazySingleton<ClubConfig>(() => currentClubConfig); // escolhido no bootstrap, ver §5
```
Consumido via `context.club` (extension igual `context.colors` hoje) ou `sl<ClubConfig>()` em repositórios/RPCs.

## 1. Substituindo `isGoias`/`goiasId` (o bloqueio mais espalhado, achado em `05`)

Hoje: `Team.goiasId = 1863` hardcoded + 3 reimplementações independentes de "é esse time?" (`Team.isGoias`, `crowd_lineup_page.dart`, `passport_match_ticket_v2.dart`).

Proposta: uma função só, `bool isOurClub(Team team, ClubConfig config) => team.id == config.oneFootballTeamId;` — string-match como fallback (`.contains('goi')`) deixa de existir, porque o id numérico do OneFootball já é config, não precisa de fallback textual. `Team`/`Standing`/`ClubHistoryEntry`/`CareerEntry` deixam de ter campo `isGoias` embutido — quem precisa da comparação chama `isOurClub(...)` no ponto de uso, passando o `ClubConfig` injetado. Isso também mata a coluna `is_goias` do Supabase (`squad_members.club_history`/`career_players.club_career`) — ela vira `club_id == our_club_id` comparado no cliente, sem precisar de uma coluna booleana redundante gravada no banco.

`getGoiasSnapshot()` vira `getClubSnapshot(config.oneFootballTeamId)` — renomeação simples, sem mudança de comportamento.

## 2. `AppColors` → `ClubColors` (mudança mínima, já é `ThemeExtension`)

Passo 1 (sem risco, pode ser feito JÁ, antes de qualquer flavor existir): renomear os 3 tokens de matiz literal pra papel — `darkGreen`→`heroAccentDark`, `deepGreen`→`heroAccentDeep`, `ctaGreen`→`ctaAccent` (ou nomes equivalentes) em `app_colors.dart`. Zero mudança visual, só nomenclatura — desacopla a estrutura do fato de "ser verde".

Passo 2 (junto com o primeiro flavor real): `AppColors.light`/`.dark` deixam de ser `static const` do app inteiro e passam a vir de `ClubConfig.colors.light`/`.dark`, resolvido uma vez no bootstrap. `AppTheme._themeFor` já é a única consumidora estrutural — muda só ali.

Os 4 hex duplicados fora do Dart (`pubspec.yaml` — ícone adaptativo, splash, tema web) continuam por-build (não dá pra templatizar isso em runtime, é config de build nativo) — ver `11_flavors_android.md`/`13_flavors_web.md`.

## 3. `AppAssets` → `ClubAssets`

Mesma lógica: os nomes de constante viram campos de instância (`config.assets.crest`, `config.assets.crestBadge` etc.), os PATHS continuam apontando pra `lib/assets/branding/...` — só que agora esse diretório vira `lib/assets/branding/<clubId>/...` (ou um mecanismo de asset bundle por flavor, ver `11_flavors_android.md`). Pro Goiás, os paths atuais continuam funcionando sem mudança se o diretório for renomeado numa migration única e testada.

`club_badge.dart`'s `if (team.isGoias) { ...Image.asset(AppAssets.goiasCrestBadge...) }` vira `if (isOurClub(team, config)) { ...Image.asset(config.assets.crestBadge...) }` — mesmo comportamento, sem hardcode.

## 4. Enums que carregam nome de marca

`QuizDifficulty.esmeraldino` e `PassportLevel.lendaEsmeraldina` **não precisam virar dinâmicos** — são valores de enum internos (nunca mostrados como string bruta ao usuário, sempre passam por l10n pro texto exibido). O que muda é só o TEXTO exibido pra esse nível, que já vem do l10n (`l10n.tacticalIdentityXxx` etc.) — a chave l10n em si pode ganhar um placeholder de gentílico (`{demonym}`) resolvido com `config.fanDemonym`, ou (mais simples) cada clube tem seu próprio conjunto de strings l10n completo (sem placeholder), já que o app inteiro troca de l10n por flavor de qualquer forma.

## 5. Onde o `ClubConfig` é escolhido

`main.dart` recebe uma constante de compilação (`--dart-define=CLUB_ID=goias`, análogo ao padrão já usado pra `SUPABASE_URL`) e escolhe entre `goiasClubConfig`/`juventudeClubConfig` (arquivos `lib/club_configs/goias.dart`, etc. — cada um só um `const ClubConfig(...)` populado). Alternativa mais forte pra crescer além de 3-4 clubes: buscar a config da tabela `clubs` no boot (1 request extra, cacheável) em vez de compilar — mas isso é otimização prematura pra 2 clubes; recomendo compilar por enquanto e revisitar se/quando o número de clubes crescer.

## O que NÃO muda com isso

- Nenhum valor de cor, asset, texto ou comportamento do Goiás muda — é puramente uma indireção.
- `AppSpacing`/`AppRadius` continuam `static const` global — não são específicos de clube, não precisam de `ClubConfig`.
- Conteúdo (jogadores, partidas, quiz) não é resolvido por `ClubConfig` — isso é resolvido por `club_id` nas queries Supabase (ver `09`), o `ClubConfig` só carrega branding + IDs de integração, nunca dado de conteúdo.

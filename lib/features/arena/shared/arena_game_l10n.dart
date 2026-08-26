import 'package:goias_app/l10n/app_localizations.dart';

/// Título e chamada de cada minigame resolvidos por `id` — o catálogo
/// (`ArenaCatalog`) segue guardando id/ícone/rota; o texto exibido vem daqui,
/// traduzido. `id` desconhecido cai no próprio id (nunca quebra a UI).
String arenaGameTitle(AppLocalizations l10n, String id) => switch (id) {
  'quiz' => l10n.arenaGameQuizTitle,
  'lineup' => l10n.arenaGameLineupTitle,
  'career_path' => l10n.arenaGameCareerTitle,
  'guess_player' => l10n.arenaGuessPlayerTitle,
  _ => id,
};

String arenaGameTagline(AppLocalizations l10n, String id) => switch (id) {
  'quiz' => l10n.arenaGameQuizTagline,
  'lineup' => l10n.arenaGameLineupTagline,
  'career_path' => l10n.arenaGameCareerTagline,
  'guess_player' => l10n.arenaGuessPlayerTagline,
  _ => '',
};

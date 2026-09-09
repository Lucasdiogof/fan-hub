import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Título e chamada de cada minigame resolvidos por `id` — o catálogo
/// (`ArenaCatalog`) segue guardando id/ícone/rota; o texto exibido vem daqui,
/// traduzido. `id` desconhecido cai no próprio id (nunca quebra a UI).
///
/// `quiz` é o único que precisa do clube ativo: o título em PT preserva o
/// apelido "Verdão" especificamente pro Goiás (nunca derivável de nenhum
/// campo genérico — nem `fanDemonym`, que pro Goiás já é "Esmeraldino", um
/// apelido DIFERENTE usado em outro lugar do mesmo jogo); qualquer outro
/// clube usa o nome dele (`{club}`, resolvido por `ClubConfig.identity.
/// shortName`), nunca "Verdão"/"Goiás" herdado. EN/ES já usavam só o nome
/// puro do clube (sem apelido), então esses dois nunca mudam de texto.
String arenaGameTitle(AppLocalizations l10n, String id) => switch (id) {
  'quiz' => l10n.arenaGameQuizTitle(
    sl<ClubConfig>().identity.code,
    sl<ClubConfig>().identity.shortName,
  ),
  'lineup' => l10n.arenaGameLineupTitle,
  'career_path' => l10n.arenaGameCareerTitle,
  'guess_player' => l10n.arenaGuessPlayerTitle,
  _ => id,
};

String arenaGameTagline(AppLocalizations l10n, String id) => switch (id) {
  'quiz' => l10n.arenaGameQuizTagline(sl<ClubConfig>().identity.shortName),
  'lineup' => l10n.arenaGameLineupTagline(sl<ClubConfig>().identity.shortName),
  'career_path' => l10n.arenaGameCareerTagline,
  'guess_player' => l10n.arenaGuessPlayerTagline,
  _ => '',
};

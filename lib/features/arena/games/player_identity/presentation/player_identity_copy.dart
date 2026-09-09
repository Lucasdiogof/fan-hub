import 'package:flutter/widgets.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';

/// Textos de identidade do "Que craque é você?" resolvidos por clube — mesmo
/// mecanismo de `tactical_identity_copy.dart`.
///
/// BUG ENCONTRADO NA QA DE 2026-09-08: título, subtítulo do card, descrição
/// da intro e título de "referências" tinham "esmeraldino"/"Verdão"/"Goiás"
/// cravados nas 3 línguas — o torcedor do Bragantino veria "Que craque
/// esmeraldino é você?" e "ídolo do Verdão" dentro do PRÓPRIO jogo do
/// Bragantino. `tactical_identity` já tinha essa correção (2026-09-08,
/// `tactical_identity_copy.dart`); esta ficou pra trás porque as duas
/// features foram tratadas em blocos separados. Corrigido com o MESMO
/// padrão: nome do clube entra por `ClubConfig.identity.shortName`, frase
/// reescrita em cada idioma pra aceitar qualquer clube (PT/ES com artigo
/// masculino, EN sem artigo) — nunca concatenação crua.
extension PlayerIdentityCopy on BuildContext {
  String get playerIdentityGameTitle =>
      l10n.playerIdentityGameTitle(sl<ClubConfig>().identity.shortName);

  String get playerIntroTitle =>
      l10n.playerIntroTitle(sl<ClubConfig>().identity.shortName);

  String get playerIntroDescription =>
      l10n.playerIntroDescription(sl<ClubConfig>().identity.shortName);

  String get playerIdentityCardSubtitleNew =>
      l10n.playerIdentityCardSubtitleNew(sl<ClubConfig>().identity.shortName);

  String get playerResultReferencesTitle => l10n
      .playerResultReferencesTitle(sl<ClubConfig>().identity.shortName)
      .toUpperCase();
}

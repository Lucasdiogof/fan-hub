import 'package:flutter/widgets.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/passport/domain/club_passport_content.dart';

/// Atalho para a cópia do Passaporte do clube ativo, no idioma da tela.
///
/// A tela pergunta `context.passportCopy.title` e pronto — nunca
/// `if (clube == 'goias')`, nunca `"Lenda ${identity.fanDemonym}"`. Trocar
/// de clube ou de idioma troca a cópia inteira, já escrita.
extension PassportCopyContext on BuildContext {
  PassportCopy get passportCopy => sl<ClubConfig>().passportContent
      .forLanguageCode(Localizations.localeOf(this).languageCode);
}

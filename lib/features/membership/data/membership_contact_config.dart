import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';

/// Contato oficial do programa de sócio do clube ativo — lê de
/// `ClubConfig.integrations`, nunca duplica o valor aqui.
class MembershipContactConfig {
  const MembershipContactConfig._();

  static String get whatsappNumber =>
      sl<ClubConfig>().integrations.contactWhatsappNumber ??
      (throw StateError(
        'club "${sl<ClubConfig>().identity.code}" has no contactWhatsappNumber configured',
      ));

  static String get whatsappUrl =>
      sl<ClubConfig>().integrations.contactWhatsappUrl ??
      (throw StateError(
        'club "${sl<ClubConfig>().identity.code}" has no contactWhatsappUrl configured',
      ));

  static String whatsappUrlWithMessage(String message) =>
      '$whatsappUrl?text=${Uri.encodeComponent(message)}';
}

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';

/// Contato oficial do programa de sócio do clube ativo — lê de
/// `ClubConfig.integrations`, nunca duplica o valor aqui.
class MembershipContactConfig {
  const MembershipContactConfig._();

  /// Se o clube ativo tem WhatsApp de atendimento configurado. Os botões de
  /// "Falar com atendimento" só aparecem quando isto é `true` — nunca um
  /// botão que lança erro ao ser tocado (o caso do Bragantino hoje).
  static bool get hasWhatsapp =>
      sl<ClubConfig>().integrations.contactWhatsappUrl != null;

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

/// Contato oficial do Sócio Esmeralda — fonte única, não espalhar o número
/// em vários widgets.
class MembershipContactConfig {
  const MembershipContactConfig._();

  static const whatsappNumber = '(62) 99472-2541';
  static const whatsappUrl = 'https://wa.me/5562994722541';

  static String whatsappUrlWithMessage(String message) =>
      '$whatsappUrl?text=${Uri.encodeComponent(message)}';
}

import 'package:goias_app/l10n/app_localizations.dart';

/// Validações do checkout da loja — mesma estrutura de `AuthValidators`
/// (uma função por campo, `null` quando válido), mas seguindo o padrão de
/// `MembershipRegistrationState` pra i18n: cada função recebe `l10n` e monta
/// a mensagem a partir dele, nunca guarda texto pronto. As checagens
/// puramente estruturais (`isValidCpf`, `isValidEmailShape`, `isValidPhone`)
/// não precisam de `l10n` — são reaproveitadas tanto aqui quanto por
/// `CheckoutState`/`ProductDetailState` pra decidir validade sem depender de
/// tradução.
class StoreValidators {
  const StoreValidators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static bool isValidFullName(String value) =>
      value.trim().length >= 3 && value.trim().contains(' ');

  static bool isValidEmailShape(String value) => _email.hasMatch(value.trim());

  static bool isValidPhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '').length >= 10;

  static String? fullName(AppLocalizations l10n, String value) {
    if (value.trim().length < 3) return l10n.storeValFullNameRequired;
    if (!value.trim().contains(' ')) return l10n.storeValFullNameIncomplete;
    return null;
  }

  static String? email(AppLocalizations l10n, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return l10n.storeValEmailRequired;
    if (!isValidEmailShape(normalized)) return l10n.storeValEmailInvalid;
    return null;
  }

  static String? phone(AppLocalizations l10n, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return l10n.storeValPhoneInvalid;
    return null;
  }

  static String? cpf(AppLocalizations l10n, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return l10n.storeValCpfRequired;
    if (!isValidCpf(digits)) return l10n.storeValCpfInvalid;
    return null;
  }

  static String? zipCode(AppLocalizations l10n, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return l10n.storeValZipInvalid;
    return null;
  }

  /// Algoritmo padrão de validação de CPF (módulo 11, dois dígitos
  /// verificadores) — rejeita também sequências repetidas (`00000000000`
  /// etc.), que passariam no cálculo mas nunca são CPFs reais.
  static bool isValidCpf(String digits) {
    if (digits.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    final numbers = digits.split('').map(int.parse).toList();

    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += numbers[i] * (10 - i);
    }
    var firstCheck = (sum * 10) % 11;
    if (firstCheck == 10) firstCheck = 0;
    if (firstCheck != numbers[9]) return false;

    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += numbers[i] * (11 - i);
    }
    var secondCheck = (sum * 10) % 11;
    if (secondCheck == 10) secondCheck = 0;
    return secondCheck == numbers[10];
  }
}

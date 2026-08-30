import 'package:goias_app/features/membership/domain/membership_registration_validators.dart'
    as membership;
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/masks.dart';

/// Única fonte de validação de identidade/contato do app — antes existiam
/// `AuthValidators` e `StoreValidators` com regras de e-mail/nome/telefone
/// parcialmente duplicadas e parcialmente divergentes. As checagens
/// estruturais mais completas (CPF com dígitos verificadores, nome com
/// classe de caracteres correta, celular BR com DDD+9, data de nascimento
/// real) já existiam em `membership_registration_validators.dart` — este
/// arquivo as reaproveita em vez de reimplementar, e só acrescenta a
/// tradução (`l10n`) por cima, seguindo a mesma convenção de
/// `(AppLocalizations l10n, String value) → String?` que as duas classes
/// antigas já usavam.
class AppValidators {
  const AppValidators._();

  static const int minPasswordLength = 8;

  static bool isValidCpf(String digits) => membership.isValidCpf(digits);

  static bool isValidEmailShape(String value) =>
      membership.isValidEmailShape(value);

  /// Nome completo: mesma classe de caracteres de `membership` (aceita
  /// acentos/hífen/apóstrofo, rejeita só números) + exige nome e sobrenome,
  /// regra que já existia em `StoreValidators` e faz sentido em qualquer
  /// formulário de identidade do app.
  static bool isValidFullName(String value) =>
      membership.isValidFullName(value) && value.trim().contains(' ');

  /// Telefone genérico (aceita fixo ou celular) — usado onde o campo não é
  /// exclusivamente "Celular"/WhatsApp.
  static bool isValidPhone(String value) =>
      onlyDigits(value).length >= 10;

  /// Celular brasileiro (DDD + 9 dígitos, começando em 9) — usado nos campos
  /// rotulados "Celular"/"WhatsApp".
  static bool isValidMobilePhone(String value) =>
      membership.isValidMobilePhone(value);

  static bool isValidZipCode(String value) => membership.isValidCep(value);

  /// Documento do titular do ingresso: aceita CPF válido OU um passaporte de
  /// forma plausível (o titular pode ser estrangeiro) — mesma checagem de
  /// passaporte que o cadastro de Sócio já usa.
  static bool isValidDocument(String value) =>
      isValidCpf(onlyDigits(value)) || membership.isValidPassportShape(value);

  static DateTime? parseBirthDate(String value) =>
      membership.parseDdMmYyyy(value);

  static bool isAdult(DateTime birthDate) => membership.isAtLeast18(birthDate);

  static String? fullName(AppLocalizations l10n, String value) {
    if (value.trim().length < 3) return l10n.storeValFullNameRequired;
    if (!isValidFullName(value)) return l10n.storeValFullNameIncomplete;
    return null;
  }

  static String? email(AppLocalizations l10n, String value) {
    if (value.trim().isEmpty) return l10n.validatorEmailRequired;
    if (!isValidEmailShape(value)) return l10n.validatorEmailInvalid;
    return null;
  }

  static String? phone(AppLocalizations l10n, String value) {
    if (onlyDigits(value).isEmpty) return l10n.validatorPhoneRequired;
    if (!isValidPhone(value)) return l10n.storeValPhoneInvalid;
    return null;
  }

  static String? mobilePhone(AppLocalizations l10n, String value) {
    if (onlyDigits(value).isEmpty) return l10n.validatorPhoneRequired;
    if (!isValidMobilePhone(value)) return l10n.storeValPhoneInvalid;
    return null;
  }

  static String? cpf(AppLocalizations l10n, String value) {
    final digits = onlyDigits(value);
    if (digits.isEmpty) return l10n.storeValCpfRequired;
    if (!isValidCpf(digits)) return l10n.storeValCpfInvalid;
    return null;
  }

  static String? zipCode(AppLocalizations l10n, String value) {
    if (onlyDigits(value).isEmpty) return l10n.validatorZipRequired;
    if (!isValidZipCode(value)) return l10n.storeValZipInvalid;
    return null;
  }

  static String? birthDate(AppLocalizations l10n, String value) {
    final digits = onlyDigits(value);
    if (digits.isEmpty) return l10n.membershipValBirthRequired;
    if (digits.length < 8) return l10n.membershipValBirthInvalid;
    final parsed = parseBirthDate(value);
    if (parsed == null || parsed.isAfter(DateTime.now())) {
      return l10n.membershipValBirthInvalid;
    }
    return null;
  }

  static String? password(AppLocalizations l10n, String value) {
    if (value.isEmpty) return l10n.validatorPasswordRequired;
    return null;
  }

  static String? newPassword(AppLocalizations l10n, String value) {
    if (value.isEmpty) return l10n.validatorPasswordCreate;
    if (value.length < minPasswordLength) {
      return l10n.validatorPasswordMinLength(minPasswordLength);
    }
    return null;
  }

  static String? confirmPassword(
    AppLocalizations l10n,
    String value,
    String original,
  ) {
    if (value.isEmpty) return l10n.validatorConfirmRequired;
    if (value != original) return l10n.validatorPasswordsDoNotMatch;
    return null;
  }

  static String normalizeEmail(String value) => value.trim().toLowerCase();
}

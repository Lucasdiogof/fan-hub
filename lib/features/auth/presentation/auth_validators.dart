import 'package:goias_app/l10n/app_localizations.dart';

class AuthValidators {
  const AuthValidators._();

  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? fullName(AppLocalizations l10n, String value) {
    if (value.trim().length < 3) return l10n.validatorNameRequired;
    return null;
  }

  static String? email(AppLocalizations l10n, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return l10n.validatorEmailRequired;
    if (!_email.hasMatch(normalized)) return l10n.validatorEmailInvalid;
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

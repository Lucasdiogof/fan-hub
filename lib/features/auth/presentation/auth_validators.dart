class AuthValidators {
  const AuthValidators._();

  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? fullName(String value) {
    if (value.trim().isEmpty) return 'Informe seu nome completo.';
    if (value.trim().length < 3) return 'Informe seu nome completo.';
    return null;
  }

  static String? email(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Informe seu e-mail.';
    if (!_email.hasMatch(normalized)) return 'Informe um e-mail válido.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Informe sua senha.';
    return null;
  }

  static String? newPassword(String value) {
    if (value.isEmpty) return 'Crie uma senha.';
    if (value.length < minPasswordLength) {
      return 'A senha deve ter ao menos $minPasswordLength caracteres.';
    }
    return null;
  }

  static String? confirmPassword(String value, String original) {
    if (value.isEmpty) return 'Confirme sua senha.';
    if (value != original) return 'As senhas não coincidem.';
    return null;
  }

  static String normalizeEmail(String value) => value.trim().toLowerCase();
}

/// Classificação estável de erros de autenticação — nunca uma string final
/// (essa tradução mora na camada de apresentação, ver
/// `lib/features/auth/presentation/auth_error_localization.dart`), pra
/// `AuthFailure` funcionar em PT/EN/ES sem a camada de dados/repositório
/// precisar de `BuildContext`/`AppLocalizations`.
enum AuthErrorCode {
  invalidCredentials,
  currentPasswordIncorrect,
  passwordIncorrect,
  emailAlreadyRegistered,
  weakPassword,
  invalidEmail,
  rateLimited,
  otpInvalidOrExpired,
  sessionExpired,
  signupDisabled,
  emailNotConfirmed,
  serviceUnavailable,
  newPasswordSameAsCurrent,
  cpfAlreadyTaken,
  accountDeletionFailed,

  /// Mensagem vem do próprio backend (Edge Function), já em texto — nunca
  /// um dos casos acima. `AuthFailure.rawMessage` carrega o texto de
  /// verdade; a tradução aqui não se aplica (mesma convenção do resto do
  /// app: conteúdo dinâmico do backend fica em PT).
  functionError,

  /// Espelha `NetworkFailure` pros pontos de exibição do fluxo de auth —
  /// não substitui `NetworkFailure` em si (usado em todo o app).
  network,

  generic,
}

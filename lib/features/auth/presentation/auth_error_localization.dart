import 'package:goias_app/core/error/auth_error_code.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Único ponto que transforma um [Failure] vindo do fluxo de auth numa
/// string pronta pra mostrar — mora na apresentação (não em `data/`)
/// justamente pra poder receber [AppLocalizations]. Cobre [AuthFailure] e
/// [NetworkFailure] (frequentemente retornado no lugar de um `AuthFailure`
/// pela mesma chamada, ver `mapAuthError`); qualquer outro tipo de
/// [Failure] cai no fallback genérico — `ServerFailure`/`UnexpectedFailure`
/// continuam fora deste escopo (usadas em várias outras features com
/// mensagens próprias, não só auth).
String localizeAuthFailure(Failure failure, AppLocalizations l10n) {
  if (failure is AuthFailure) return _localizeCode(failure, l10n);
  if (failure is NetworkFailure) return l10n.authErrorNetwork;
  return l10n.authErrorGeneric;
}

String _localizeCode(AuthFailure failure, AppLocalizations l10n) {
  switch (failure.code) {
    case AuthErrorCode.invalidCredentials:
      return l10n.authErrorInvalidCredentials;
    case AuthErrorCode.currentPasswordIncorrect:
      return l10n.authErrorCurrentPasswordIncorrect;
    case AuthErrorCode.passwordIncorrect:
      return l10n.authErrorPasswordIncorrect;
    case AuthErrorCode.emailAlreadyRegistered:
      return l10n.authErrorEmailAlreadyRegistered;
    case AuthErrorCode.weakPassword:
      return l10n.authErrorWeakPassword;
    case AuthErrorCode.invalidEmail:
      return l10n.authErrorInvalidEmail;
    case AuthErrorCode.rateLimited:
      return l10n.authErrorRateLimited;
    case AuthErrorCode.otpInvalidOrExpired:
      return l10n.authErrorOtpInvalidOrExpired;
    case AuthErrorCode.sessionExpired:
      return l10n.authErrorSessionExpired;
    case AuthErrorCode.signupDisabled:
      return l10n.authErrorSignupDisabled;
    case AuthErrorCode.emailNotConfirmed:
      return l10n.authErrorEmailNotConfirmed;
    case AuthErrorCode.serviceUnavailable:
      return l10n.authErrorServiceUnavailable;
    case AuthErrorCode.newPasswordSameAsCurrent:
      return l10n.authErrorNewPasswordSameAsCurrent;
    case AuthErrorCode.cpfAlreadyTaken:
      return l10n.authErrorCpfAlreadyTaken;
    case AuthErrorCode.accountDeletionFailed:
      return l10n.authErrorAccountDeletionFailed;
    case AuthErrorCode.functionError:
      return failure.rawMessage ?? l10n.authErrorGeneric;
    case AuthErrorCode.network:
      return l10n.authErrorNetwork;
    case AuthErrorCode.generic:
      return l10n.authErrorGeneric;
  }
}

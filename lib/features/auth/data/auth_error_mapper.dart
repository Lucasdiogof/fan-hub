import 'dart:async';

import 'package:goias_app/core/error/auth_error_code.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapAuthError(Object error, StackTrace stackTrace) {
  unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  if (error is AuthRetryableFetchException || _looksLikeNetwork(error)) {
    return const NetworkFailure();
  }

  if (error is AuthException) {
    return AuthFailure(_codeForAuthException(error));
  }

  return const AuthFailure(AuthErrorCode.generic);
}

bool _looksLikeNetwork(Object error) {
  final name = error.runtimeType.toString();
  return name.contains('SocketException') ||
      name.contains('ClientException') ||
      name.contains('TimeoutException');
}

/// PRIMEIRO critério é sempre `code`/`statusCode` (nunca texto em inglês —
/// ver https://supabase.com/docs/guides/auth/debugging/error-codes pra
/// lista completa). O `switch` por mensagem no fim só cobre casos legados
/// (ex.: login com senha errada) onde não confirmei se o GoTrue sempre
/// preenche `code` — nunca é o critério usado pros erros novos de
/// cadastro/OTP.
AuthErrorCode _codeForAuthException(AuthException error) {
  switch (error.code) {
    case 'user_already_exists':
    case 'email_exists':
      return AuthErrorCode.emailAlreadyRegistered;
    case 'weak_password':
      return AuthErrorCode.weakPassword;
    case 'validation_failed':
    case 'bad_json':
      return AuthErrorCode.invalidEmail;
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
    case 'over_sms_send_rate_limit':
      return AuthErrorCode.rateLimited;
    // GoTrue não distingue "código errado" de "código expirado" nessa
    // resposta (os dois vêm como `otp_expired`, por design — não dar pra
    // quem está tentando adivinhar o código nenhuma pista sobre qual dos
    // dois aconteceu) — por isso um código só cobrindo as duas
    // possibilidades, em vez de inventar uma distinção que a API não dá.
    case 'otp_expired':
    case 'otp_disabled':
      return AuthErrorCode.otpInvalidOrExpired;
    case 'session_expired':
    case 'session_not_found':
    case 'session_missing':
      return AuthErrorCode.sessionExpired;
    case 'signup_disabled':
      return AuthErrorCode.signupDisabled;
    case 'email_not_confirmed':
      return AuthErrorCode.emailNotConfirmed;
  }

  if (error.statusCode == '429') {
    return AuthErrorCode.rateLimited;
  }
  if (error.statusCode == '503') {
    return AuthErrorCode.serviceUnavailable;
  }

  final raw = error.message.toLowerCase();
  if (raw.contains('invalid login credentials')) {
    return AuthErrorCode.invalidCredentials;
  }
  if (raw.contains('email not confirmed')) {
    return AuthErrorCode.emailNotConfirmed;
  }
  if (raw.contains('user already registered') ||
      raw.contains('already been registered')) {
    return AuthErrorCode.emailAlreadyRegistered;
  }
  if (raw.contains('password should be at least') ||
      raw.contains('weak password')) {
    return AuthErrorCode.weakPassword;
  }
  if (raw.contains('unable to validate email address') ||
      raw.contains('invalid email')) {
    return AuthErrorCode.invalidEmail;
  }
  if (raw.contains('for security purposes') ||
      raw.contains('rate limit') ||
      raw.contains('too many')) {
    return AuthErrorCode.rateLimited;
  }
  if (raw.contains('new password should be different')) {
    return AuthErrorCode.newPasswordSameAsCurrent;
  }
  if (raw.contains('token has expired or is invalid')) {
    return AuthErrorCode.otpInvalidOrExpired;
  }

  return AuthErrorCode.generic;
}

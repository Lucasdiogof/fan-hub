import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapAuthError(Object error, StackTrace stackTrace) {
  unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  if (error is AuthRetryableFetchException || _looksLikeNetwork(error)) {
    return const NetworkFailure();
  }

  if (error is AuthException) {
    return AuthFailure(_messageForAuthException(error));
  }

  return const AuthFailure('Não foi possível concluir agora. Tente novamente.');
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
String _messageForAuthException(AuthException error) {
  switch (error.code) {
    case 'user_already_exists':
    case 'email_exists':
      return 'Este e-mail já possui uma conta.';
    case 'weak_password':
      return 'A senha não atende aos requisitos mínimos.';
    case 'validation_failed':
    case 'bad_json':
      return 'Informe um e-mail válido.';
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
    case 'over_sms_send_rate_limit':
      return 'Já enviamos um código recentemente. Aguarde um pouco antes de solicitar outro.';
    // GoTrue não distingue "código errado" de "código expirado" nessa
    // resposta (os dois vêm como `otp_expired`, por design — não dar pra
    // quem está tentando adivinhar o código nenhuma pista sobre qual dos
    // dois aconteceu) — por isso uma mensagem só cobrindo as duas
    // possibilidades, em vez de inventar uma distinção que a API não dá.
    case 'otp_expired':
    case 'otp_disabled':
      return 'Este código não é válido ou já expirou. Confira e tente novamente, ou solicite um novo código.';
    case 'session_expired':
    case 'session_not_found':
    case 'session_missing':
      return 'Sua sessão expirou. Faça login novamente.';
    case 'signup_disabled':
      return 'Novos cadastros estão temporariamente indisponíveis.';
    case 'email_not_confirmed':
      return 'Confirme seu e-mail antes de entrar.';
  }

  if (error.statusCode == '429') {
    return 'Já enviamos um código recentemente. Aguarde um pouco antes de solicitar outro.';
  }
  if (error.statusCode == '503') {
    return 'O serviço está temporariamente indisponível. Tente novamente em instantes.';
  }

  final raw = error.message.toLowerCase();
  if (raw.contains('invalid login credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (raw.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar.';
  }
  if (raw.contains('user already registered') ||
      raw.contains('already been registered')) {
    return 'Este e-mail já possui uma conta.';
  }
  if (raw.contains('password should be at least') ||
      raw.contains('weak password')) {
    return 'A senha não atende aos requisitos mínimos.';
  }
  if (raw.contains('unable to validate email address') ||
      raw.contains('invalid email')) {
    return 'Informe um e-mail válido.';
  }
  if (raw.contains('for security purposes') ||
      raw.contains('rate limit') ||
      raw.contains('too many')) {
    return 'Já enviamos um código recentemente. Aguarde um pouco antes de solicitar outro.';
  }
  if (raw.contains('new password should be different')) {
    return 'A nova senha precisa ser diferente da atual.';
  }
  if (raw.contains('token has expired or is invalid')) {
    return 'Este código não é válido ou já expirou. Confira e tente novamente, ou solicite um novo código.';
  }

  return 'Não foi possível concluir agora. Tente novamente.';
}

import 'package:goias_app/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapAuthError(Object error) {
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

String _messageForAuthException(AuthException error) {
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
    return 'Muitas tentativas. Aguarde um instante e tente de novo.';
  }
  if (raw.contains('new password should be different')) {
    return 'A nova senha precisa ser diferente da atual.';
  }

  return 'Não foi possível concluir agora. Tente novamente.';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/features/auth/data/auth_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Failure map(AuthException error) =>
      mapAuthError(error, StackTrace.empty);

  group('code-first mapping (never message.contains in English)', () {
    test('over_email_send_rate_limit never mentions "rate limit" or 429', () {
      final failure = map(
        const AuthException('Email rate limit exceeded', code: 'over_email_send_rate_limit'),
      );
      expect(failure.message, isNot(contains('rate limit')));
      expect(failure.message, isNot(contains('429')));
      expect(failure.message, contains('Já enviamos um código'));
    });

    test('otp_expired covers both wrong and expired code, in Portuguese', () {
      final failure = map(
        const AuthException('Token has expired or is invalid', code: 'otp_expired'),
      );
      expect(failure.message, isNot(contains('Token')));
      expect(failure.message, contains('código'));
    });

    test('user_already_exists', () {
      final failure = map(
        const AuthException('User already registered', code: 'user_already_exists'),
      );
      expect(failure.message, 'Este e-mail já possui uma conta.');
    });

    test('weak_password', () {
      final failure = map(
        const AuthException('Password is too weak', code: 'weak_password'),
      );
      expect(failure.message, 'A senha não atende aos requisitos mínimos.');
    });

    test('statusCode 429 without a matching code still maps to rate limit', () {
      final failure = map(
        const AuthException('Unexpected', statusCode: '429'),
      );
      expect(failure.message, contains('Já enviamos um código'));
    });

    test('statusCode 503 maps to a temporary-unavailability message', () {
      final failure = map(
        const AuthException('Unexpected', statusCode: '503'),
      );
      expect(failure.message, contains('temporariamente indisponível'));
    });
  });

  group('legacy message-based fallback (only when there is no code)', () {
    test('invalid login credentials — existing login flow, never regressed', () {
      final failure = map(
        const AuthException('Invalid login credentials'),
      );
      expect(failure.message, 'E-mail ou senha incorretos.');
    });
  });

  test('never exposes AuthException/statusCode/stacktrace text to the user', () {
    final failure = map(
      const AuthException('Some obscure internal GoTrue message', code: 'otp_expired'),
    );
    expect(failure.message, isNot(contains('AuthException')));
    expect(failure.message, isNot(contains('obscure internal')));
  });
}

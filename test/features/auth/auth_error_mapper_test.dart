import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/auth_error_code.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/features/auth/data/auth_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  AuthErrorCode map(AuthException error) {
    final failure = mapAuthError(error, StackTrace.empty);
    return (failure as AuthFailure).code;
  }

  group('code-first mapping (never message.contains in English)', () {
    test('over_email_send_rate_limit classifies as rateLimited', () {
      final code = map(
        const AuthException(
          'Email rate limit exceeded',
          code: 'over_email_send_rate_limit',
        ),
      );
      expect(code, AuthErrorCode.rateLimited);
    });

    test('otp_expired covers both wrong and expired code', () {
      final code = map(
        const AuthException(
          'Token has expired or is invalid',
          code: 'otp_expired',
        ),
      );
      expect(code, AuthErrorCode.otpInvalidOrExpired);
    });

    test('user_already_exists', () {
      final code = map(
        const AuthException(
          'User already registered',
          code: 'user_already_exists',
        ),
      );
      expect(code, AuthErrorCode.emailAlreadyRegistered);
    });

    test('weak_password', () {
      final code = map(
        const AuthException('Password is too weak', code: 'weak_password'),
      );
      expect(code, AuthErrorCode.weakPassword);
    });

    test('statusCode 429 without a matching code still maps to rate limit', () {
      final code = map(const AuthException('Unexpected', statusCode: '429'));
      expect(code, AuthErrorCode.rateLimited);
    });

    test('statusCode 503 maps to service unavailable', () {
      final code = map(const AuthException('Unexpected', statusCode: '503'));
      expect(code, AuthErrorCode.serviceUnavailable);
    });
  });

  group('legacy message-based fallback (only when there is no code)', () {
    test(
      'invalid login credentials — existing login flow, never regressed',
      () {
        final code = map(const AuthException('Invalid login credentials'));
        expect(code, AuthErrorCode.invalidCredentials);
      },
    );
  });

  test(
    'never exposes AuthException/statusCode/stacktrace text via message',
    () {
      final failure = mapAuthError(
        const AuthException(
          'Some obscure internal GoTrue message',
          code: 'otp_expired',
        ),
        StackTrace.empty,
      );
      // `message` (herdado de Failure) só existe pra Sentry/Equatable agora —
      // a mensagem exibida pro usuário vem do `code` traduzido na
      // apresentação (ver auth_error_localization.dart), nunca daqui.
      expect(failure.message, isNot(contains('AuthException')));
      expect(failure.message, isNot(contains('obscure internal')));
    },
  );
}

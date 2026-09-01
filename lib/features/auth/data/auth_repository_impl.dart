import 'dart:async';

import 'package:goias_app/core/config/supabase_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/data/auth_error_mapper.dart';
import 'package:goias_app/features/auth/data/auth_remote_data_source.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, this._profileRepository);

  final AuthRemoteDataSource _dataSource;

  /// Só usado por [verifyEmailOtp], pra copiar cpf/data de
  /// nascimento/telefone/opt-in do `user_metadata` pendente pra `profiles`
  /// assim que a confirmação estabelece sessão válida.
  final ProfileRepository _profileRepository;

  @override
  bool get isAuthenticated => _dataSource.currentSession != null;

  @override
  AuthUser? get currentUser {
    final user = _dataSource.currentUser;
    return user == null ? null : _mapUser(user);
  }

  /// Único listener do `onAuthStateChange` do app inteiro (o `AuthCubit`
  /// assina isto uma vez só, na criação) — nenhuma outra tela/repositório
  /// deve assinar `_client.auth.onAuthStateChange` diretamente, senão
  /// passamos a ter vários listeners concorrentes reagindo à mesma coisa.
  ///
  /// `.handleError` é essencial aqui: o GoTrue reporta uma falha de rede
  /// durante a renovação automática do token como um ERRO no stream (não
  /// um evento normal) — sem isso, vira uma exceção não tratada toda vez
  /// que o refresh tenta renovar sem internet. Falha de rede nunca deve
  /// virar sign-out (a sessão local continua válida), então só logamos e
  /// ignoramos.
  @override
  Stream<AuthSessionEvent> get sessionEvents => _dataSource.onAuthStateChange
      .map(_withBreadcrumb)
      .handleError((Object error, StackTrace stackTrace) {
        unawaited(
          Sentry.addBreadcrumb(
            Breadcrumb(
              message: 'auth_state_stream_error',
              category: 'auth',
              level: SentryLevel.warning,
              data: {'error': error.runtimeType.toString()},
            ),
          ),
        );
      })
      .map(_mapEvent)
      .where((event) => event != null)
      .cast<AuthSessionEvent>();

  /// Breadcrumbs de observabilidade — nunca token/header, só o evento e (no
  /// caso de sign-out) o motivo. Um refresh bem-sucedido não deve virar uma
  /// issue de erro no Sentry (é o caminho feliz), só um rastro; só a perda
  /// definitiva de sessão vira um evento de verdade.
  AuthState _withBreadcrumb(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.tokenRefreshed:
        unawaited(
          Sentry.addBreadcrumb(
            Breadcrumb(
              message: 'auth_session_refreshed',
              category: 'auth',
              level: SentryLevel.info,
            ),
          ),
        );
      case AuthChangeEvent.signedOut:
        final reason = state.signOutReason;
        if (reason == SignOutReason.sessionExpired ||
            reason == SignOutReason.sessionMissing) {
          unawaited(
            Sentry.captureMessage(
              'auth_session_recovery_failed',
              level: SentryLevel.warning,
              withScope: (scope) =>
                  scope.setTag('reason', reason!.name),
            ),
          );
        }
      default:
        break;
    }
    return state;
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _dataSource.signIn(email: email, password: password);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  }) async {
    try {
      final response = await _dataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
        cpf: cpf,
        birthDate: birthDate,
        phone: phone,
        marketingOptIn: marketingOptIn,
      );
      return Success(response.session == null);
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _dataSource.verifyEmailOtp(
        email: email,
        token: token,
      );
      final metadata = response.user?.userMetadata ?? const {};
      // Nunca deixa uma falha aqui derrubar a confirmação — a sessão já
      // está válida nesse ponto (o usuário É real e confirmado), então o
      // pior cenário é entrar no app com `profiles` ainda incompleto (o
      // Perfil deixa completar depois), nunca ficar preso na tela de OTP.
      try {
        final birthRaw = metadata['birth_date'] as String?;
        await _profileRepository.updateProfile(
          fullName: metadata['full_name'] as String?,
          cpf: metadata['cpf'] as String?,
          birthDate: birthRaw == null ? null : DateTime.tryParse(birthRaw),
          phone: metadata['phone'] as String?,
          marketingOptIn: metadata['marketing_opt_in'] as bool? ?? false,
        );
        unawaited(_dataSource.clearPendingSignupMetadata());
      } catch (error, stackTrace) {
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      }
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<bool>> isCpfTaken(String cpf) async {
    try {
      return Success(await _dataSource.isCpfTaken(cpf));
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _dataSource.sendPasswordReset(
        email,
        redirectTo: SupabaseConfig.redirectUrl,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> resendConfirmationEmail(String email) async {
    try {
      await _dataSource.resendConfirmation(email);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _dataSource.updatePassword(newPassword);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      if (error is AuthException &&
          error.message.toLowerCase().contains('invalid login credentials')) {
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
        return const Error(AuthFailure('Senha atual incorreta.'));
      }
      return Error(mapAuthError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteAccount({required String password}) async {
    try {
      await _dataSource.deleteAccount(password);
      return const Success(null);
    } catch (error, stackTrace) {
      if (error is AuthException &&
          error.message.toLowerCase().contains('invalid login credentials')) {
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
        return const Error(AuthFailure('Senha incorreta.'));
      }
      if (error is FunctionException) {
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
        return Error(AuthFailure(_messageForFunctionsError(error)));
      }
      return Error(mapAuthError(error, stackTrace));
    }
  }

  String _messageForFunctionsError(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    return 'Não foi possível excluir sua conta. Tente novamente em alguns instantes.';
  }

  AuthUser _mapUser(User user) {
    final metadata = user.userMetadata;
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      fullName: metadata?['full_name'] as String?,
      avatarUrl: metadata?['avatar_url'] as String?,
    );
  }

  AuthSessionEvent? _mapEvent(AuthState state) {
    return switch (state.event) {
      AuthChangeEvent.signedIn => AuthSessionEvent.signedIn,
      AuthChangeEvent.userUpdated => AuthSessionEvent.userUpdated,
      // `signOutReason` só vem preenchido pro GoTrue quando ELE MESMO
      // encerrou a sessão (refresh token inválido/revogado ou sessão local
      // incompleta) — um `signOut()` chamado pelo usuário chega aqui com
      // `reason == null` (ver doc de `AuthState.signOutReason`).
      AuthChangeEvent.signedOut => switch (state.signOutReason) {
        SignOutReason.sessionExpired ||
        SignOutReason.sessionMissing => AuthSessionEvent.sessionExpired,
        _ => AuthSessionEvent.signedOut,
      },
      AuthChangeEvent.passwordRecovery => AuthSessionEvent.passwordRecovery,
      AuthChangeEvent.initialSession =>
        state.session != null
            ? AuthSessionEvent.signedIn
            : AuthSessionEvent.signedOut,
      _ => null,
    };
  }
}

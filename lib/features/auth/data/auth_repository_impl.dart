import 'package:goias_app/core/config/supabase_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/data/auth_error_mapper.dart';
import 'package:goias_app/features/auth/data/auth_remote_data_source.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  bool get isAuthenticated => _dataSource.currentSession != null;

  @override
  AuthUser? get currentUser {
    final user = _dataSource.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Stream<AuthSessionEvent> get sessionEvents => _dataSource.onAuthStateChange
      .map(_mapEvent)
      .where((event) => event != null)
      .cast<AuthSessionEvent>();

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _dataSource.signIn(email: email, password: password);
      return const Success(null);
    } catch (error) {
      return Error(mapAuthError(error));
    }
  }

  @override
  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );
      return Success(response.session == null);
    } catch (error) {
      return Error(mapAuthError(error));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Success(null);
    } catch (error) {
      return Error(mapAuthError(error));
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
    } catch (error) {
      return Error(mapAuthError(error));
    }
  }

  @override
  Future<Result<void>> resendConfirmationEmail(String email) async {
    try {
      await _dataSource.resendConfirmation(
        email,
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );
      return const Success(null);
    } catch (error) {
      return Error(mapAuthError(error));
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _dataSource.updatePassword(newPassword);
      return const Success(null);
    } catch (error) {
      return Error(mapAuthError(error));
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
    } catch (error) {
      if (error is AuthException &&
          error.message.toLowerCase().contains('invalid login credentials')) {
        return const Error(AuthFailure('Senha atual incorreta.'));
      }
      return Error(mapAuthError(error));
    }
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
      AuthChangeEvent.signedOut => AuthSessionEvent.signedOut,
      AuthChangeEvent.passwordRecovery => AuthSessionEvent.passwordRecovery,
      AuthChangeEvent.initialSession =>
        state.session != null
            ? AuthSessionEvent.signedIn
            : AuthSessionEvent.signedOut,
      _ => null,
    };
  }
}

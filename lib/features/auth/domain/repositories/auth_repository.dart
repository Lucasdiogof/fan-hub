import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';

enum AuthSessionEvent { signedIn, signedOut, passwordRecovery, userUpdated }

abstract interface class AuthRepository {
  bool get isAuthenticated;

  AuthUser? get currentUser;

  Stream<AuthSessionEvent> get sessionEvents;

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<void>> resendConfirmationEmail(String email);

  Future<Result<void>> updatePassword(String newPassword);

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Reautentica com a senha atual (mesmo motivo de [changePassword]: uma
  /// operação irreversível merece confirmar identidade de novo) e então
  /// chama a Edge Function que exclui a conta no backend. Ao final, encerra
  /// a sessão local — nunca deixa o app "logado" numa conta que não existe
  /// mais no Supabase.
  Future<Result<void>> deleteAccount({required String password});
}

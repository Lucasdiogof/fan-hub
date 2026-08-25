import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    String? emailRedirectTo,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: emailRedirectTo,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email, {String? redirectTo}) {
    return _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> resendConfirmation(String email, {String? emailRedirectTo}) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: emailRedirectTo,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Reautentica com a senha atual antes de trocar — diferente de
  /// [updatePassword] (usado só no fluxo de recuperação por e-mail, onde o
  /// usuário não tem como informar a senha antiga).
  Future<UserResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser!.email!;
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Reautentica igual [changePassword] e então chama a Edge Function
  /// `delete-account` — ela identifica o usuário pelo JWT da sessão atual
  /// (nunca por um id enviado daqui), então precisa rodar DEPOIS do
  /// `signInWithPassword` ter renovado a sessão.
  Future<void> deleteAccount(String password) async {
    final email = _client.auth.currentUser!.email!;
    await _client.auth.signInWithPassword(email: email, password: password);
    await _client.functions.invoke('delete-account');
    // Best-effort: a conta já foi excluída no servidor nesse ponto, então
    // o próprio signOut pode falhar (sessão de um usuário que não existe
    // mais) — isso nunca deve mascarar o sucesso da exclusão.
    try {
      await _client.auth.signOut();
    } catch (_) {
      // ignore
    }
  }
}

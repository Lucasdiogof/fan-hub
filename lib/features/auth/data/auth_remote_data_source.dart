import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({required String email, required String password}) {
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
    return _client.auth.resend(type: OtpType.signup, email: email, emailRedirectTo: emailRedirectTo);
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}

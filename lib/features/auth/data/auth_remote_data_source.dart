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

  /// [cpf]/[birthDate]/[phone]/[marketingOptIn] vão só pro `user_metadata`
  /// — nenhuma sessão existe ainda pra gravar em `profiles` diretamente (a
  /// trigger `handle_new_user` só copia `full_name` na criação; o resto é
  /// copiado por [verifyEmailOtp] depois da confirmação, e então limpo
  /// daqui via [clearPendingSignupMetadata]).
  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'cpf': cpf,
        'birth_date': _dateOnly(birthDate),
        'phone': phone,
        'marketing_opt_in': marketingOptIn,
      },
    );
  }

  /// `type: OtpType.signup` — o código de 6 dígitos do template "Confirm
  /// signup" (`{{ .Token }}`), nunca um link. Sucesso já estabelece sessão
  /// válida sozinho (comportamento do próprio GoTrue).
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  /// Remove do `user_metadata` os campos sensíveis que só existiam ali
  /// temporariamente pra sobreviver à janela sem sessão — chamado só
  /// depois que [verifyEmailOtp] já copiou tudo pra `profiles`. Melhor
  /// esforço: se falhar, os dados já estão salvos em `profiles` mesmo
  /// assim, então nunca deve bloquear nem re-lançar.
  Future<void> clearPendingSignupMetadata() async {
    await _client.auth.updateUser(
      UserAttributes(
        data: {'cpf': null, 'birth_date': null, 'phone': null},
      ),
    );
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email, {String? redirectTo}) {
    return _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> resendConfirmation(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email);
  }

  Future<bool> isCpfTaken(String cpf) async {
    final result = await _client.rpc<bool>(
      'cpf_is_taken',
      params: {'p_cpf': cpf},
    );
    return result;
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

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';

enum AuthSessionEvent {
  signedIn,
  signedOut,

  /// Sign-out involuntário — refresh token inválido/revogado ou sessão
  /// local incompleta (ver `SignOutReason.sessionExpired`/`sessionMissing`
  /// do GoTrue), nunca um `signOut()` que o próprio usuário pediu. Existe
  /// separado de [signedOut] só pra UI decidir se mostra o aviso "sua
  /// sessão expirou" (nunca faz sentido mostrar isso depois de um logout
  /// deliberado).
  sessionExpired,
  passwordRecovery,
  userUpdated,
}

abstract interface class AuthRepository {
  bool get isAuthenticated;

  AuthUser? get currentUser;

  Stream<AuthSessionEvent> get sessionEvents;

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  /// `true` no resultado significa "precisa confirmar o e-mail antes de
  /// entrar" (é o que acontece sempre, com "Confirm email" ligado no
  /// Supabase) — [cpf]/[birthDate]/[phone]/[marketingOptIn] vão só no
  /// `user_metadata` do signup (nenhuma sessão existe ainda pra gravar em
  /// `profiles` diretamente); [verifyEmailOtp] é quem copia isso pra
  /// `profiles` depois que o código é confirmado.
  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  });

  /// Confirma o cadastro com o código de 6 dígitos enviado por e-mail
  /// (`{{ .Token }}` do template "Confirm signup"). Sucesso já estabelece
  /// sessão válida (o SDK faz isso sozinho) e finaliza o `profiles`
  /// pendente com os dados que foram pro metadata em [signUp].
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Checagem de UX no Passo 1 — nunca a autoridade final (essa é o unique
  /// index no Postgres, ver `supabase/profiles_signup_fields.sql`). Só
  /// evita o usuário preencher os 3 passos pra descobrir o conflito no fim.
  Future<Result<bool>> isCpfTaken(String cpf);

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

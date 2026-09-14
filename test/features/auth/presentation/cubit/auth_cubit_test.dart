import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/auth_error_code.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';

const _user = AuthUser(id: 'u1', email: 'torcedor@example.com');

class _FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  final _events = StreamController<AuthSessionEvent>.broadcast();

  bool signOutCalled = false;
  Result<void> signInResult = const Success(null);
  Result<bool> isCpfTakenResult = const Success(false);
  Result<void> deleteAccountResult = const Success(null);
  Result<void> changePasswordResult = const Success(null);
  String? lastDeleteAccountPassword;

  void emitEvent(AuthSessionEvent event) => _events.add(event);

  @override
  bool get isAuthenticated => user != null;

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthSessionEvent> get sessionEvents => _events.stream;

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async => signInResult;

  @override
  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  }) async => const Success(true);

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async => const Success(null);

  @override
  Future<Result<bool>> isCpfTaken(String cpf) async => isCpfTakenResult;

  @override
  Future<Result<void>> signOut() async {
    signOutCalled = true;
    user = null;
    return const Success(null);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async =>
      const Success(null);

  @override
  Future<Result<void>> resendConfirmationEmail(String email) async =>
      const Success(null);

  @override
  Future<Result<void>> updatePassword(String newPassword) async =>
      const Success(null);

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => changePasswordResult;

  @override
  Future<Result<void>> deleteAccount({required String password}) async {
    lastDeleteAccountPassword = password;
    return deleteAccountResult;
  }
}

void main() {
  late _FakeAuthRepository repository;

  setUp(() {
    repository = _FakeAuthRepository();
  });

  test('sem sessão salva, começa como AuthUnauthenticated', () {
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);
    expect(cubit.state, const AuthUnauthenticated());
  });

  test('com sessão salva, começa direto como AuthAuthenticated', () {
    repository.user = _user;
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);
    expect(cubit.state, const AuthAuthenticated(_user));
  });

  test('evento signedIn emite AuthAuthenticated com o usuário atual', () async {
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    repository.user = _user;
    repository.emitEvent(AuthSessionEvent.signedIn);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const AuthAuthenticated(_user));
  });

  test('evento signedOut emite AuthUnauthenticated', () async {
    repository.user = _user;
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    repository.emitEvent(AuthSessionEvent.signedOut);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const AuthUnauthenticated());
  });

  test(
    'evento sessionExpired emite AuthSessionExpired, nunca AuthUnauthenticated',
    () async {
      repository.user = _user;
      final cubit = AuthCubit(repository);
      addTearDown(cubit.close);

      repository.emitEvent(AuthSessionEvent.sessionExpired);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const AuthSessionExpired());
    },
  );

  test('evento passwordRecovery emite AuthPasswordRecovery', () async {
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    repository.emitEvent(AuthSessionEvent.passwordRecovery);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const AuthPasswordRecovery());
  });

  test('evento userUpdated com usuário nulo não emite nada novo', () async {
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    repository.emitEvent(AuthSessionEvent.userUpdated);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const AuthUnauthenticated());
  });

  test(
    'signIn repassa direto pro repositório e devolve o Result dele',
    () async {
      final cubit = AuthCubit(repository);
      addTearDown(cubit.close);
      repository.signInResult = const Error(
        AuthFailure(AuthErrorCode.invalidCredentials),
      );

      final result = await cubit.signIn(
        email: 'torcedor@example.com',
        password: 'errada',
      );

      expect(result, isA<Error<void>>());
    },
  );

  test('signOut chama o repositório', () async {
    repository.user = _user;
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    await cubit.signOut();

    expect(repository.signOutCalled, isTrue);
  });

  test('deleteAccount repassa a senha pro repositório', () async {
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    await cubit.deleteAccount(password: 'minhaSenha123');

    expect(repository.lastDeleteAccountPassword, 'minhaSenha123');
  });

  test('isCpfTaken repassa o resultado do repositório', () async {
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);
    repository.isCpfTakenResult = const Success(true);

    final result = await cubit.isCpfTaken('12345678900');

    expect(result, isA<Success<bool>>());
    expect((result as Success<bool>).data, isTrue);
  });
}

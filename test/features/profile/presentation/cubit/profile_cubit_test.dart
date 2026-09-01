import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Mesmo padrão de `_FakeAuthRepository` em `session_expiry_listener_test.dart`.
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSessionEvent>.broadcast();
  AuthUser? _user;

  void emitSignedIn(String userId) {
    _user = AuthUser(id: userId, email: '$userId@goias.com');
    _controller.add(AuthSessionEvent.signedIn);
  }

  void emitSignedOut() {
    _user = null;
    _controller.add(AuthSessionEvent.signedOut);
  }

  void emitSessionExpired() {
    _user = null;
    _controller.add(AuthSessionEvent.sessionExpired);
  }

  Future<void> dispose() => _controller.close();

  @override
  bool get isAuthenticated => _user != null;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthSessionEvent> get sessionEvents => _controller.stream;

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async => const Success(null);

  @override
  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  }) async => const Success(false);

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async => const Success(null);

  @override
  Future<Result<bool>> isCpfTaken(String cpf) async => const Success(false);

  @override
  Future<Result<void>> signOut() async {
    emitSignedOut();
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
  }) async => const Success(null);

  @override
  Future<Result<void>> deleteAccount({required String password}) async =>
      const Success(null);
}

/// Devolve um `Profile` diferente por usuário — pra provar que o CPF/nome
/// de uma conta nunca aparece pra outra (ver testes de troca de conta).
class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this._authRepo);

  final _FakeAuthRepository _authRepo;

  @override
  Future<Result<Profile>> getProfile() async {
    final user = _authRepo.currentUser;
    if (user == null) {
      return const Error(UnexpectedFailure('sem usuário'));
    }

    return Success(
      Profile(id: user.id, email: user.email, fullName: 'Nome ${user.id}', cpf: 'cpf-${user.id}'),
    );
  }

  @override
  Future<Result<Profile>> updateProfile({
    String? fullName,
    String? cpf,
    DateTime? birthDate,
    String? phone,
    bool? marketingOptIn,
  }) async {
    final user = _authRepo.currentUser!;
    return Success(
      Profile(id: user.id, email: user.email, fullName: fullName, cpf: cpf),
    );
  }

  @override
  Future<Result<UserAddress?>> getAddress() async => const Success(null);

  @override
  Future<Result<void>> saveAddress(UserAddress address) async =>
      const Success(null);

  @override
  Future<Result<Profile>> uploadAvatar(
    Uint8List bytes,
    String fileExtension,
  ) async {
    final user = _authRepo.currentUser!;
    return Success(Profile(id: user.id, email: user.email));
  }
}

void main() {
  late _FakeAuthRepository authRepo;
  late AuthCubit authCubit;
  late _FakeProfileRepository profileRepo;

  setUp(() {
    authRepo = _FakeAuthRepository();
    authCubit = AuthCubit(authRepo);
    profileRepo = _FakeProfileRepository(authRepo);
  });

  tearDown(() async {
    await authCubit.close();
    await authRepo.dispose();
  });

  test('já autenticado na criação: carrega o perfil imediatamente', () async {
    authRepo.emitSignedIn('conta-a');
    final cubit = ProfileCubit(profileRepo, authCubit);
    await pumpEventQueue();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.profile?.id, 'conta-a');
    await cubit.close();
  });

  test('logout limpa o perfil da conta anterior', () async {
    authRepo.emitSignedIn('conta-a');
    final cubit = ProfileCubit(profileRepo, authCubit);
    await pumpEventQueue();
    expect(cubit.state.profile?.id, 'conta-a');

    authRepo.emitSignedOut();
    await pumpEventQueue();

    expect(cubit.state.profile, isNull);
    await cubit.close();
  });

  test('sessão expirada limpa o perfil igual o logout manual', () async {
    authRepo.emitSignedIn('conta-a');
    final cubit = ProfileCubit(profileRepo, authCubit);
    await pumpEventQueue();

    authRepo.emitSessionExpired();
    await pumpEventQueue();

    expect(cubit.state.profile, isNull);
    await cubit.close();
  });

  test(
    'A → B → A na mesma sessão: nunca reaproveita CPF/nome da conta anterior',
    () async {
      authRepo.emitSignedIn('conta-a');
      final cubit = ProfileCubit(profileRepo, authCubit);
      await pumpEventQueue();
      expect(cubit.state.profile?.cpf, 'cpf-conta-a');

      authRepo.emitSignedOut();
      await pumpEventQueue();
      expect(cubit.state.profile, isNull);

      authRepo.emitSignedIn('conta-b');
      await pumpEventQueue();
      expect(cubit.state.profile?.id, 'conta-b');
      expect(cubit.state.profile?.cpf, 'cpf-conta-b');
      // Nenhum instante lógico devolve o CPF da conta A pra conta B.
      expect(cubit.state.profile?.cpf, isNot('cpf-conta-a'));

      authRepo.emitSignedOut();
      await pumpEventQueue();
      expect(cubit.state.profile, isNull);

      authRepo.emitSignedIn('conta-a');
      await pumpEventQueue();
      expect(cubit.state.profile?.cpf, 'cpf-conta-a');

      await cubit.close();
    },
  );
}

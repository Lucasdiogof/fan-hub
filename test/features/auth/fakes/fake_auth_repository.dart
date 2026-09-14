import 'dart:async';

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';

const authUserFixture = AuthUser(id: 'u1', email: 'torcedor@example.com');

class FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  final _events = StreamController<AuthSessionEvent>.broadcast();

  Result<void> signInResult = const Success(null);
  Result<bool> signUpResult = const Success(true);
  Result<bool> isCpfTakenResult = const Success(false);
  Result<void> deleteAccountResult = const Success(null);
  Result<void> changePasswordResult = const Success(null);
  bool signOutCalled = false;
  Map<String, dynamic>? lastSignUpArgs;
  String? lastIsCpfTakenArg;
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
  }) async {
    lastSignUpArgs = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'cpf': cpf,
      'birthDate': birthDate,
      'phone': phone,
      'marketingOptIn': marketingOptIn,
    };
    return signUpResult;
  }

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async => const Success(null);

  @override
  Future<Result<bool>> isCpfTaken(String cpf) async {
    lastIsCpfTakenArg = cpf;
    return isCpfTakenResult;
  }

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

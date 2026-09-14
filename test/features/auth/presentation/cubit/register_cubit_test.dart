import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/auth_error_code.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_state.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  final _events = StreamController<AuthSessionEvent>.broadcast();

  Result<bool> isCpfTakenResult = const Success(false);
  Result<bool> signUpResult = const Success(true);
  Map<String, dynamic>? lastSignUpArgs;
  String? lastIsCpfTakenArg;

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
  Future<Result<void>> signOut() async => const Success(null);

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

void main() {
  late _FakeAuthRepository repository;
  late AuthCubit authCubit;
  late RegisterCubit cubit;

  setUp(() {
    repository = _FakeAuthRepository();
    authCubit = AuthCubit(repository);
    cubit = RegisterCubit(authCubit);
  });

  tearDown(() async {
    await cubit.close();
    await authCubit.close();
  });

  test('estado inicial começa no passo pessoal, sem dado nenhum', () {
    expect(cubit.state.step, RegisterStep.personal);
    expect(cubit.state.fullName, isEmpty);
    expect(cubit.state.formError, isNull);
  });

  test('updateFullName atualiza o nome e limpa erro anterior', () {
    cubit.emit(
      cubit.state.copyWith(
        formError: const AuthFailure(AuthErrorCode.rateLimited),
      ),
    );
    cubit.updateFullName('Lucas Silva');
    expect(cubit.state.fullName, 'Lucas Silva');
    expect(cubit.state.formError, isNull);
  });

  test('updateMarketingOptIn/updateAcceptedTerms não mexem no formError', () {
    cubit.emit(
      cubit.state.copyWith(
        formError: const AuthFailure(AuthErrorCode.rateLimited),
      ),
    );
    cubit.updateMarketingOptIn(true);
    expect(cubit.state.marketingOptIn, isTrue);
    expect(cubit.state.formError, isNotNull);
    cubit.updateAcceptedTerms(true);
    expect(cubit.state.acceptedTerms, isTrue);
    expect(cubit.state.formError, isNotNull);
  });

  group('continueFromPersonal', () {
    test('CPF livre avança pro passo de contato e retorna true', () async {
      cubit.updateCpf('123.456.789-00');
      repository.isCpfTakenResult = const Success(false);

      final advanced = await cubit.continueFromPersonal();

      expect(advanced, isTrue);
      expect(cubit.state.step, RegisterStep.contact);
      expect(cubit.state.checkingCpf, isFalse);
      expect(cubit.state.formError, isNull);
      expect(repository.lastIsCpfTakenArg, '12345678900');
    });

    test(
      'CPF já cadastrado não avança e expõe AuthFailure.cpfAlreadyTaken',
      () async {
        cubit.updateCpf('123.456.789-00');
        repository.isCpfTakenResult = const Success(true);

        final advanced = await cubit.continueFromPersonal();

        expect(advanced, isFalse);
        expect(cubit.state.step, RegisterStep.personal);
        expect(
          cubit.state.formError,
          const AuthFailure(AuthErrorCode.cpfAlreadyTaken),
        );
      },
    );

    test(
      'falha de rede na checagem não avança e propaga a falha original',
      () async {
        const failure = NetworkFailure();
        repository.isCpfTakenResult = const Error(failure);

        final advanced = await cubit.continueFromPersonal();

        expect(advanced, isFalse);
        expect(cubit.state.step, RegisterStep.personal);
        expect(cubit.state.formError, failure);
        expect(cubit.state.checkingCpf, isFalse);
      },
    );
  });

  test('continueFromContact avança pro passo de segurança e limpa erro', () {
    cubit.emit(
      cubit.state.copyWith(
        formError: const AuthFailure(AuthErrorCode.rateLimited),
      ),
    );
    cubit.continueFromContact();
    expect(cubit.state.step, RegisterStep.security);
    expect(cubit.state.formError, isNull);
  });

  group('back', () {
    test('do passo pessoal retorna false — não existe passo anterior', () {
      expect(cubit.back(), isFalse);
      expect(cubit.state.step, RegisterStep.personal);
    });

    test('do passo de contato volta pro pessoal e retorna true', () {
      cubit.continueFromContact();
      cubit.emit(cubit.state.copyWith(step: RegisterStep.contact));
      final went = cubit.back();
      expect(went, isTrue);
      expect(cubit.state.step, RegisterStep.personal);
    });

    test('do passo de segurança volta pro contato e retorna true', () {
      cubit.emit(cubit.state.copyWith(step: RegisterStep.security));
      final went = cubit.back();
      expect(went, isTrue);
      expect(cubit.state.step, RegisterStep.contact);
    });
  });

  group('submit', () {
    void fillValidForm() {
      cubit
        ..updateFullName('Lucas Silva')
        ..updateCpf('123.456.789-00')
        ..updateBirthDate('01/01/2000')
        ..updateEmail('lucas@example.com')
        ..updatePhone('(62) 99999-8888')
        ..updateMarketingOptIn(true)
        ..updatePassword('senha123')
        ..updateConfirmPassword('senha123')
        ..updateAcceptedTerms(true);
    }

    test(
      'sucesso envia dados normalizados (só dígitos em CPF/telefone) pro AuthCubit',
      () async {
        fillValidForm();
        repository.signUpResult = const Success(true);

        final result = await cubit.submit();

        expect(result, isA<Success<bool>>());
        expect(cubit.state.submitting, isFalse);
        expect(cubit.state.formError, isNull);
        expect(repository.lastSignUpArgs, isNotNull);
        expect(repository.lastSignUpArgs!['cpf'], '12345678900');
        expect(repository.lastSignUpArgs!['phone'], '62999998888');
        expect(repository.lastSignUpArgs!['fullName'], 'Lucas Silva');
        expect(repository.lastSignUpArgs!['marketingOptIn'], isTrue);
        expect(repository.lastSignUpArgs!['birthDate'], DateTime(2000, 1, 1));
      },
    );

    test('falha do backend mantém submitting=false e expõe a falha', () async {
      fillValidForm();
      const failure = AuthFailure(AuthErrorCode.emailAlreadyRegistered);
      repository.signUpResult = const Error(failure);

      final result = await cubit.submit();

      expect(result, isA<Error<bool>>());
      expect(cubit.state.submitting, isFalse);
      expect(cubit.state.formError, failure);
    });
  });
}

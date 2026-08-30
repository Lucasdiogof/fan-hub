import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';

/// Mesmo padrão de `_FakeAuthRepository` em `session_expiry_listener_test.dart`.
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSessionEvent>.broadcast();
  final AuthUser _user = const AuthUser(id: 'u1', email: 'torcedor@goias.com');

  Future<void> dispose() => _controller.close();

  @override
  bool get isAuthenticated => true;

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
  }) async => const Success(false);

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

const _plan = MembershipPlan(
  id: 'nossa-gente',
  name: 'NOSSA GENTE',
  tagline: 'Torça em qualquer lugar.',
  includesStadiumAccess: false,
  benefits: ['benefício 1'],
  prices: [
    MembershipPlanPrice(label: '', monthlyPrice: 9.99, annualPrice: 119.88),
  ],
);

class _FakeMembershipRepository implements MembershipRepository {
  int submitRegistrationCallCount = 0;
  Failure? submitFailure;

  @override
  Future<Result<List<MembershipPlan>>> getPlans() async =>
      const Success([_plan]);

  @override
  Future<Result<Membership?>> getMyMembership() async => const Success(null);

  @override
  Future<Result<List<CheckIn>>> getMyCheckIns() async => const Success([]);

  @override
  Future<Result<CheckIn>> checkIn(String matchId) async =>
      throw UnimplementedError();

  @override
  Future<Result<Membership>> submitRegistration({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  }) async {
    submitRegistrationCallCount++;
    // Delay real (não só microtask) — é essa janela assíncrona que um
    // duplo toque/chamada concorrente exploraria sem a guarda no Cubit.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final failure = submitFailure;
    if (failure != null) return Error(failure);
    return Success(
      Membership(
        id: 'membership-$submitRegistrationCallCount',
        userId: 'u1',
        plan: plan,
        planPrice: price,
        status: MembershipStatus.active,
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        regulationVersion: regulationVersion,
        regulationAcceptedAt: regulationAcceptedAt,
      ),
    );
  }
}

void main() {
  late _FakeAuthRepository authRepo;
  late AuthCubit authCubit;
  late _FakeMembershipRepository membershipRepo;
  late MembershipStatusCubit cubit;

  setUp(() {
    authRepo = _FakeAuthRepository();
    authCubit = AuthCubit(authRepo);
    membershipRepo = _FakeMembershipRepository();
    cubit = MembershipStatusCubit(membershipRepo, authCubit);
  });

  tearDown(() async {
    await cubit.close();
    await authCubit.close();
    await authRepo.dispose();
  });

  Future<Result<Membership>> subscribe() => cubit.subscribeToPlan(
    plan: _plan,
    price: _plan.defaultPrice,
    data: const MembershipRegistrationData(),
    regulationVersion: 'v1',
    regulationAcceptedAt: DateTime.now(),
  );

  test(
    'duas chamadas concorrentes de subscribeToPlan só criam uma assinatura',
    () async {
      final first = subscribe();
      final second = subscribe(); // "segundo toque" durante o 1º.
      final results = await Future.wait([first, second]);

      expect(membershipRepo.submitRegistrationCallCount, 1);
      // A que "perdeu" a corrida recebe um Error de operação em andamento,
      // nunca chega a repetir o insert.
      expect(results.whereType<Success<Membership>>(), hasLength(1));
      expect(results.whereType<Error<Membership>>(), hasLength(1));
    },
  );

  test('subscribeToPlan atualiza o estado global em caso de sucesso', () async {
    final result = await subscribe();

    expect(result, isA<Success<Membership>>());
    expect(cubit.state.isMember, isTrue);
    expect(cubit.state.subscribing, isFalse);
  });

  test('subscribeToPlan libera a guarda depois de um erro do servidor', () async {
    membershipRepo.submitFailure = const ServerFailure('já é sócio');
    final result = await subscribe();

    expect(result, isA<Error<Membership>>());
    expect(cubit.state.subscribing, isFalse);
    // Depois do erro, uma nova tentativa consegue chamar o repositório de
    // novo — a guarda não fica presa em `true` por engano.
    membershipRepo.submitFailure = null;
    final retryResult = await subscribe();
    expect(retryResult, isA<Success<Membership>>());
    expect(membershipRepo.submitRegistrationCallCount, 2);
  });
}

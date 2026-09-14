import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/features/ticket/domain/entities/match_ticket_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

import '../../fakes/fake_ticket_repository.dart';

TicketEvent _buildEvent() {
  final match = Match(
    id: '1',
    competition: 'Campeonato Goiano',
    round: 'Rodada 1',
    homeTeam: goiasTeam,
    awayTeam: opponentTeam,
    stadium: 'Serrinha',
    kickoff: DateTime.now().add(const Duration(days: 5)),
    status: MatchStatus.scheduled,
  );
  final info = MatchTicketInfo(
    matchId: '1',
    saleOpensAt: DateTime.now().subtract(const Duration(days: 1)),
    checkInOpensAt: DateTime.now().subtract(const Duration(hours: 1)),
    canCancelCheckIn: true,
    sectors: const [],
  );
  return TicketEvent(
    match: match,
    info: info,
    saleStatus: TicketSaleStatus.open,
    checkInStatus: CheckInStatus.available,
  );
}

class _FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  final _events = StreamController<AuthSessionEvent>.broadcast();

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
  }) async => const Success(true);

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async => const Success(null);

  @override
  Future<Result<bool>> isCpfTaken(String cpf) async => const Success(false);

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

class _UnusedMembershipRepository implements MembershipRepository {
  @override
  Future<Result<List<MembershipPlan>>> getPlans() => throw UnimplementedError();

  @override
  Future<Result<Membership?>> getMyMembership() => throw UnimplementedError();

  @override
  Future<Result<List<CheckIn>>> getMyCheckIns() => throw UnimplementedError();

  @override
  Future<Result<CheckIn>> checkIn(String matchId) => throw UnimplementedError();

  @override
  Future<Result<Membership>> submitRegistration({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  }) => throw UnimplementedError();
}

void main() {
  late FakeTicketRepository ticketRepository;
  late AuthCubit authCubit;
  late MembershipStatusCubit membershipStatusCubit;

  setUp(() {
    ticketRepository = FakeTicketRepository();
    authCubit = AuthCubit(_FakeAuthRepository());
    membershipStatusCubit = MembershipStatusCubit(
      _UnusedMembershipRepository(),
      authCubit,
    );
  });

  tearDown(() async {
    await membershipStatusCubit.close();
    await authCubit.close();
  });

  test(
    'ao criar, carrega sozinho o evento em destaque e o status de sócio',
    () async {
      final event = _buildEvent();
      ticketRepository.featuredEventResult = Success(event);

      final cubit = TicketsCubit(ticketRepository, membershipStatusCubit);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.event, event);
    },
  );

  test(
    'sem evento em destaque, event fica nulo mas status é success',
    () async {
      ticketRepository.featuredEventResult = const Success(null);

      final cubit = TicketsCubit(ticketRepository, membershipStatusCubit);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.event, isNull);
    },
  );

  test('falha do repositório expõe a mensagem de erro', () async {
    ticketRepository.featuredEventResult = const Error(
      ServerFailure('indisponível'),
    );

    final cubit = TicketsCubit(ticketRepository, membershipStatusCubit);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.error);
    expect(cubit.state.errorMessage, 'indisponível');
  });

  test(
    'isMember reflete o MembershipStatusCubit, nunca uma checagem própria',
    () async {
      membershipStatusCubit.emit(
        const MembershipStatusState(status: LoadStatus.success),
      );
      ticketRepository.featuredEventResult = const Success(null);

      final cubitNaoSocio = TicketsCubit(
        ticketRepository,
        membershipStatusCubit,
      );
      addTearDown(cubitNaoSocio.close);
      await Future<void>.delayed(Duration.zero);
      expect(cubitNaoSocio.state.isMember, isFalse);
    },
  );
}

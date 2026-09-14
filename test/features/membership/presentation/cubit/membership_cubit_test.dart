import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_cubit.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/shared/state/load_status.dart';

import '../../../match/fakes/fake_football_repository.dart';
import '../../../profile/fakes/fake_profile_repository.dart';
import '../../fakes/fake_membership_repository.dart';

const _goias = Team(
  id: 1863,
  name: 'Goiás',
  shortName: 'GO',
  color: Color(0xFF004C1B),
);
const _opponent = Team(
  id: 2,
  name: 'Vila Nova',
  shortName: 'VNO',
  color: Color(0xFF000000),
);

void main() {
  late FakeMembershipRepository membershipRepository;
  late FakeProfileRepository profileRepository;
  late FakeFootballRepository footballRepository;

  setUp(() {
    membershipRepository = FakeMembershipRepository();
    profileRepository = FakeProfileRepository();
    footballRepository = FakeFootballRepository();
    footballRepository.getActiveClubSnapshotCall = () =>
        const Success((nextMatch: null, recentResults: []));
  });

  MembershipCubit build() => MembershipCubit(
    membershipRepository,
    profileRepository,
    footballRepository,
  );

  test('ao criar, já carrega sozinho e combina os 4 resultados', () async {
    membershipRepository.myMembershipResult = Success(buildMembership());
    profileRepository.getProfileResult = const Success(
      Profile(id: 'u1', email: 'torcedor@example.com'),
    );

    final cubit = build();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.isMember, isTrue);
    expect(cubit.state.plans, [membershipPlanFixture]);
    expect(cubit.state.user?.id, 'u1');
  });

  test(
    'sem membership, isMember fica false mas status continua success',
    () async {
      membershipRepository.myMembershipResult = const Success(null);

      final cubit = build();
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.isMember, isFalse);
      expect(cubit.state.membership, isNull);
    },
  );

  test('próximo jogo futuro entra no state, um já encerrado não', () async {
    final futureMatch = Match(
      id: 'f1',
      competition: 'Goianão',
      round: '1',
      homeTeam: _goias,
      awayTeam: _opponent,
      stadium: 'Serrinha',
      kickoff: DateTime.now().add(const Duration(days: 3)),
      status: MatchStatus.scheduled,
    );
    footballRepository.getActiveClubSnapshotCall = () =>
        Success((nextMatch: futureMatch, recentResults: const []));

    final cubit = build();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.nextMatch, futureMatch);
  });

  test('jogo sem kickoff confirmado conta como "ainda por vir"', () async {
    const matchSemHorario = Match(
      id: 'f2',
      competition: 'Goianão',
      round: '1',
      homeTeam: _goias,
      awayTeam: _opponent,
      stadium: 'Serrinha',
      status: MatchStatus.scheduled,
    );
    footballRepository.getActiveClubSnapshotCall = () =>
        const Success((nextMatch: matchSemHorario, recentResults: []));

    final cubit = build();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.nextMatch, matchSemHorario);
  });

  test(
    'falha ao buscar membership emite error e marca isNetworkError certo',
    () async {
      membershipRepository.myMembershipResult = const Error(NetworkFailure());

      final cubit = build();
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.isNetworkError, isTrue);
    },
  );

  test('falha não-rede não marca isNetworkError', () async {
    membershipRepository.myMembershipResult = const Error(
      ServerFailure('erro qualquer'),
    );

    final cubit = build();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.error);
    expect(cubit.state.isNetworkError, isFalse);
    expect(cubit.state.errorMessage, 'erro qualquer');
  });

  test('falha ao buscar planos também emite error', () async {
    membershipRepository.plansResult = const Error(ServerFailure('erro'));

    final cubit = build();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.error);
  });

  test('falha ao buscar o perfil também emite error', () async {
    profileRepository.getProfileResult = const Error(ServerFailure('erro'));

    final cubit = build();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.error);
  });
}

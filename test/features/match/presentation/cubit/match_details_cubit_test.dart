import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

import '../../fakes/fake_football_repository.dart';

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

Match _buildMatch(MatchStatus status) => Match(
  id: 'f1',
  competition: 'Campeonato Goiano',
  round: 'Rodada 1',
  homeTeam: _goias,
  awayTeam: _opponent,
  stadium: 'Serrinha',
  status: status,
);

({
  Match match,
  List<MatchEvent> events,
  MatchLineups? lineups,
  List<MatchStat> stats,
})
_detailsFor(MatchStatus status) => (
  match: _buildMatch(status),
  events: const [],
  lineups: null,
  stats: const [],
);

void main() {
  late FakeFootballRepository repository;
  late MatchDetailsCubit cubit;

  setUp(() {
    repository = FakeFootballRepository();
    cubit = MatchDetailsCubit(repository, 'f1');
  });

  tearDown(() => cubit.close());

  test('load busca os detalhes e emite success', () async {
    repository.getMatchDetailsCall = () =>
        Success(_detailsFor(MatchStatus.finished));

    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.match?.status, MatchStatus.finished);
    expect(repository.lastFixtureId, 'f1');
  });

  test('falha em load (não silenciosa) emite error com a mensagem', () async {
    repository.getMatchDetailsCall = () =>
        const Error(ServerFailure('indisponível'));

    await cubit.load();

    expect(cubit.state.status, LoadStatus.error);
    expect(cubit.state.errorMessage, 'indisponível');
  });

  test('partida agendada não inicia polling', () {
    fakeAsync((async) {
      repository.getMatchDetailsCall = () =>
          Success(_detailsFor(MatchStatus.scheduled));
      unawaited(cubit.load());
      async.elapse(const Duration(seconds: 1));

      async.elapse(const Duration(seconds: 90));

      expect(repository.getMatchDetailsCallCount, 1);
    });
  });

  test(
    'partida ao vivo faz polling a cada 45s até deixar de estar ao vivo',
    () {
      fakeAsync((async) {
        repository.getMatchDetailsCall = () =>
            Success(_detailsFor(MatchStatus.live));
        unawaited(cubit.load());
        async.elapse(Duration.zero);
        expect(repository.getMatchDetailsCallCount, 1);

        async.elapse(const Duration(seconds: 45));
        expect(repository.getMatchDetailsCallCount, 2);

        repository.getMatchDetailsCall = () =>
            Success(_detailsFor(MatchStatus.finished));
        async.elapse(const Duration(seconds: 45));
        expect(repository.getMatchDetailsCallCount, 3);
        expect(cubit.state.match?.status, MatchStatus.finished);

        async.elapse(const Duration(seconds: 45));
        expect(repository.getMatchDetailsCallCount, 3);
      });
    },
  );

  test('poll silencioso, em falha, mantém o último dado bom na tela', () {
    fakeAsync((async) {
      repository.getMatchDetailsCall = () =>
          Success(_detailsFor(MatchStatus.live));
      unawaited(cubit.load());
      async.elapse(Duration.zero);
      expect(cubit.state.status, LoadStatus.success);

      repository.getMatchDetailsCall = () =>
          const Error(ServerFailure('timeout'));
      async.elapse(const Duration(seconds: 45));

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.match?.status, MatchStatus.live);
    });
  });

  test('pausePolling para o timer; resumePolling busca na hora e retoma', () {
    fakeAsync((async) {
      repository.getMatchDetailsCall = () =>
          Success(_detailsFor(MatchStatus.live));
      unawaited(cubit.load());
      async.elapse(Duration.zero);
      expect(repository.getMatchDetailsCallCount, 1);

      cubit.pausePolling();
      async.elapse(const Duration(seconds: 90));
      expect(repository.getMatchDetailsCallCount, 1);

      cubit.resumePolling();
      async.elapse(Duration.zero);
      expect(repository.getMatchDetailsCallCount, 2);

      async.elapse(const Duration(seconds: 45));
      expect(repository.getMatchDetailsCallCount, 3);
    });
  });
}

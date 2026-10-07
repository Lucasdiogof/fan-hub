import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/data/football_active_idol_stats_repository.dart';
import 'package:goias_app/features/club/data/goias_idols_data.dart';
import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/domain/idol_stats_calculator.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/competition_season.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';

import '../idol_stats_fixtures.dart';

typedef _Details = ({
  Match match,
  List<MatchEvent> events,
  MatchLineups? lineups,
  List<MatchStat> stats,
});

/// Repositório de partidas falso: devolve [records] como temporada + detalhes
/// e CONTA cada chamada (para provar que não há N+1 nem refetch).
class _FakeFootball implements FootballRepository {
  _FakeFootball(this.records);

  final List<IdolMatchRecord> records;
  Result<List<Match>>? seasonOverride;
  Object? seasonThrows;
  final failingDetails = <String>{};

  int seasonCalls = 0;
  final detailCalls = <String>[];

  @override
  Future<Result<List<Match>>> getSeasonFixtures() async {
    seasonCalls += 1;
    if (seasonThrows != null) throw seasonThrows!;
    return seasonOverride ?? Success([for (final r in records) r.match]);
  }

  @override
  Future<Result<_Details>> getMatchDetails(String fixtureId) async {
    detailCalls.add(fixtureId);
    if (failingDetails.contains(fixtureId)) {
      return const Error(NetworkFailure());
    }
    final r = records.firstWhere((r) => r.match.id == fixtureId);
    return Success((
      match: r.match,
      events: r.events,
      lineups: r.lineups,
      stats: const <MatchStat>[],
    ));
  }

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() =>
      throw UnimplementedError();

  @override
  Future<Result<({CompetitionRef competition, CompetitionSeason season})>>
  getCompetitionSeason({String? competitionId}) => throw UnimplementedError();

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() => throw UnimplementedError();

  @override
  Future<
    Result<
      ({
        List<Match> matches,
        String? roundLabel,
        bool hasPrevious,
        bool hasNext,
      })
    >
  >
  getCurrentRound({int offset = 0}) => throw UnimplementedError();

  @override
  Future<
    Result<
      ({
        CompetitionRef competition,
        List<Standing> table,
        List<StandingGroup> groups,
      })
    >
  >
  getStandings({String? competitionId}) => throw UnimplementedError();
}

ClubIdol _otherActiveIdol() => ClubIdol(
  name: 'Fulano Ativo',
  tier: 1,
  evidenceExplicitIdol: false,
  description: 'Outro ídolo ativo, só para provar que não há N+1.',
  tracking: ActiveIdolTracking(
    providerPlayerId: 55555,
    eventNames: const {'Fulano'},
    baseline: tadeuTracking.baseline,
  ),
);

ClubIdol _historical() =>
    GoiasIdolsData.idols.firstWhere((i) => i.name == 'Harlei');

void main() {
  late List<IdolMatchRecord> season;

  setUp(() {
    season = [
      // Já dentro do baseline (nunca deve ser buscada).
      record(
        id: baselineMatchId,
        kickoff: DateTime.utc(2026, 10, 2),
        starters: [tadeuStarter],
        home: false,
      ),
      // Anterior ao baseline (nunca deve ser buscada).
      record(
        id: 'onef-velha',
        kickoff: DateTime.utc(2026, 9, 26, 21, 30),
        starters: [tadeuStarter],
      ),
      // Posterior, finalizada, ele jogou.
      record(id: 'onef-1', kickoff: after1, starters: [tadeuStarter]),
      // Posterior, finalizada, ele NÃO jogou.
      record(id: 'onef-2', kickoff: after2, starters: [starter('Outro', 1)]),
      // Futura (nunca deve ser buscada).
      record(
        id: 'onef-3',
        kickoff: after3,
        status: MatchStatus.scheduled,
        starters: [tadeuStarter],
      ),
    ];
  });

  FootballActiveIdolStatsRepository repoOf(_FakeFootball f) =>
      FootballActiveIdolStatsRepository(f, clubTeamId);

  test('calcula baseline + partidas posteriores: 406 -> 407', () async {
    final fake = _FakeFootball(season);
    final stats = (await repoOf(fake).loadStats([tadeu]))['Tadeu']!;
    expect(stats.appearances, 407);
    expect(stats.goals, 13);
    expect(stats.isComplete, isTrue);
    expect(stats.asOfDate, '2026-10-12'); // última partida verificada
  });

  test(
    'só busca detalhe de partida FINALIZADA e POSTERIOR ao baseline',
    () async {
      final fake = _FakeFootball(season);
      await repoOf(fake).loadStats([tadeu]);
      expect(fake.seasonCalls, 1);
      expect(fake.detailCalls..sort(), ['onef-1', 'onef-2']);
    },
  );

  test('sem N+1: vários ídolos ativos compartilham a mesma consulta', () async {
    final fake = _FakeFootball(season);
    final result = await repoOf(fake).loadStats([tadeu, _otherActiveIdol()]);
    expect(result.keys, containsAll(['Tadeu', 'Fulano Ativo']));
    expect(result['Tadeu']!.appearances, 407);
    expect(result['Fulano Ativo']!.appearances, 406);
    expect(fake.seasonCalls, 1);
    expect(fake.detailCalls.length, 2, reason: 'não multiplica por ídolo');
  });

  test('ídolo histórico não é consultado nem entra no resultado', () async {
    final fake = _FakeFootball(season);
    final result = await repoOf(fake).loadStats([_historical()]);
    expect(result, isEmpty);
    expect(fake.seasonCalls, 0);
    expect(fake.detailCalls, isEmpty);
  });

  test(
    'partida finalizada fica em cache: a 2ª carga não busca de novo',
    () async {
      final fake = _FakeFootball(season);
      final repo = repoOf(fake);
      await repo.loadStats([tadeu]);
      expect(fake.detailCalls.length, 2);
      final again = (await repo.loadStats([tadeu]))['Tadeu']!;
      expect(fake.detailCalls.length, 2, reason: 'detalhes vieram do cache');
      expect(fake.seasonCalls, 2);
      expect(again.appearances, 407, reason: 'recarregar nunca vira 408');
    },
  );

  test(
    '9) falha ao carregar a temporada => continua mostrando o baseline',
    () async {
      final fake = _FakeFootball(season)
        ..seasonOverride = const Error(NetworkFailure());
      final stats = (await repoOf(fake).loadStats([tadeu]))['Tadeu']!;
      expect(stats.appearances, 406);
      expect(stats.goals, 13);
      expect(stats.asOfDate, '2026-10-01');
      expect(stats.isComplete, isFalse);
    },
  );

  test(
    '9b) exceção inesperada também cai no baseline, nunca em zero',
    () async {
      final fake = _FakeFootball(season)..seasonThrows = StateError('boom');
      final stats = (await repoOf(fake).loadStats([tadeu]))['Tadeu']!;
      expect(stats.appearances, 406);
      expect(stats.goals, 13);
    },
  );

  group(
    'fail-closed: resultado parcial nunca vira total aparentemente atual',
    () {
      IdolMatchRecord late() => record(
        id: 'onef-4',
        kickoff: DateTime.utc(2026, 10, 26, 21, 30),
        starters: [tadeuStarter],
      );

      test(
        '1) uma partida verificada + outra falhando => baseline (não 407)',
        () async {
          final fake = _FakeFootball(season)..failingDetails.add('onef-2');
          final stats = (await repoOf(fake).loadStats([tadeu]))['Tadeu']!;
          expect(
            stats.appearances,
            406,
            reason: 'onef-1 verificada, mas onef-2 falhou',
          );
          expect(stats.goals, 13);
          expect(stats.asOfDate, '2026-10-01');
        },
      );

      test('2) retry com as duas funcionando => total sobe para 407', () async {
        final fake = _FakeFootball(season)..failingDetails.add('onef-2');
        final repo = repoOf(fake);
        expect((await repo.loadStats([tadeu]))['Tadeu']!.appearances, 406);
        fake.failingDetails.clear();
        final stats = (await repo.loadStats([tadeu]))['Tadeu']!;
        expect(stats.appearances, 407);
        expect(stats.isComplete, isTrue);
      });

      test(
        '3) completo anterior + nova partida falhando => mantém o último completo',
        () async {
          final fake = _FakeFootball(season);
          final repo = repoOf(fake);
          expect((await repo.loadStats([tadeu]))['Tadeu']!.appearances, 407);
          fake.records.add(late());
          fake.failingDetails.add('onef-4');
          final stats = (await repo.loadStats([tadeu]))['Tadeu']!;
          expect(
            stats.appearances,
            407,
            reason: 'continua o último completo, nunca 408 parcial',
          );
          expect(stats.isComplete, isTrue);
          expect(repo.lastCompleteFor(tadeu)!.appearances, 407);
        },
      );

      test(
        '4) assim que a nova partida pode ser validada => atualiza',
        () async {
          final fake = _FakeFootball(season);
          final repo = repoOf(fake);
          await repo.loadStats([tadeu]);
          fake.records.add(late());
          fake.failingDetails.add('onef-4');
          await repo.loadStats([tadeu]);
          fake.failingDetails.clear();
          final stats = (await repo.loadStats([tadeu]))['Tadeu']!;
          expect(stats.appearances, 408);
          expect(repo.lastCompleteFor(tadeu)!.appearances, 408);
        },
      );

      test(
        '5) nenhuma partida finalizada posterior => baseline normal',
        () async {
          final fake = _FakeFootball([season[0], season[1], season[4]]);
          final stats = (await repoOf(fake).loadStats([tadeu]))['Tadeu']!;
          expect(stats.appearances, 406);
          expect(stats.goals, 13);
          expect(
            stats.isComplete,
            isTrue,
            reason: 'conjunto vazio verificado por completo',
          );
          expect(fake.detailCalls, isEmpty);
        },
      );

      test(
        'todas as partidas falhando sem snapshot prévio => baseline, sem cache',
        () async {
          final fake = _FakeFootball(season)
            ..failingDetails.addAll(['onef-1', 'onef-2']);
          final repo = repoOf(fake);
          final stats = (await repo.loadStats([tadeu]))['Tadeu']!;
          expect(stats.appearances, 406);
          expect(
            repo.lastCompleteFor(tadeu),
            isNull,
            reason: 'incompleto nunca vira completo em cache',
          );
        },
      );

      test(
        'falha da temporada depois de um completo => mantém o completo',
        () async {
          final fake = _FakeFootball(season);
          final repo = repoOf(fake);
          await repo.loadStats([tadeu]);
          fake.seasonOverride = const Error(NetworkFailure());
          expect((await repo.loadStats([tadeu]))['Tadeu']!.appearances, 407);
        },
      );
    },
  );

  test(
    'partida sem escalação publicada não vai para o cache (tenta de novo)',
    () async {
      final noLineups = [
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [tadeuStarter],
          withLineups: false,
        ),
      ];
      final fake = _FakeFootball(noLineups);
      final repo = repoOf(fake);
      await repo.loadStats([tadeu]);
      await repo.loadStats([tadeu]);
      expect(fake.detailCalls, ['onef-1', 'onef-1']);
    },
  );

  test('o mesmo cálculo é determinístico entre repositórios', () async {
    final a = (await repoOf(_FakeFootball(season)).loadStats([tadeu]))['Tadeu'];
    final b = (await repoOf(_FakeFootball(season)).loadStats([tadeu]))['Tadeu'];
    expect(a, b);
  });
}

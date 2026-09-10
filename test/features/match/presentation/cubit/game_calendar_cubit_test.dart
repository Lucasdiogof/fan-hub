import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/calendar_competition_filter.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/competition_season.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/game_calendar_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

// Fixture de teste, explicitamente Goiás (TEST_FIXTURE_ALLOWED) — mesmo id
// de `goiasClubConfig.integrations.oneFootballTeamId`, duplicado aqui só
// porque acesso a campo de objeto const de outro arquivo não é uma
// constant expression válida neste contexto.
const _goiasTeamId = 1863;
const _goias = Team(
  id: _goiasTeamId,
  name: 'Goiás',
  shortName: 'GOI',
  color: Color(0xFF004C1B),
);
const _opponent = Team(
  id: 2,
  name: 'Vila Nova',
  shortName: 'VNO',
  color: Color(0xFF1F6F4A),
);

Match _match({
  required String id,
  required DateTime kickoff,
  required String competition,
  bool goiasHome = true,
}) {
  return Match(
    id: id,
    competition: competition,
    round: 'Rodada 1',
    homeTeam: goiasHome ? _goias : _opponent,
    awayTeam: goiasHome ? _opponent : _goias,
    stadium: 'Serrinha',
    kickoff: kickoff,
    status: MatchStatus.scheduled,
  );
}

class _FakeFootballRepository implements FootballRepository {
  List<Match> seasonFixtures = const [];
  Failure? failure;

  @override
  Future<Result<List<Match>>> getSeasonFixtures() async {
    final currentFailure = failure;
    if (currentFailure != null) return Error(currentFailure);
    return Success(seasonFixtures);
  }

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
  getStandings({String? competitionId}) async => throw UnimplementedError();

  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async =>
      throw UnimplementedError();

  @override
  Future<Result<({CompetitionRef competition, CompetitionSeason season})>>
  getCompetitionSeason({String? competitionId}) async =>
      throw UnimplementedError();

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
  getCurrentRound({int offset = 0}) async => throw UnimplementedError();

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() async => throw UnimplementedError();

  @override
  Future<
    Result<
      ({
        Match match,
        List<MatchEvent> events,
        MatchLineups? lineups,
        List<MatchStat> stats,
      })
    >
  >
  getMatchDetails(String fixtureId) async => throw UnimplementedError();
}

void main() {
  setUpAll(initializeBrazilTimeZone);

  late _FakeFootballRepository repository;
  late GameCalendarCubit cubit;

  setUp(() {
    repository = _FakeFootballRepository();
    cubit = GameCalendarCubit(repository);
  });

  test('estado inicial começa no mês atual', () {
    final now = DateTime.now();
    expect(cubit.state.selectedMonth, DateTime(now.year, now.month));
  });

  test('load com sucesso preenche allMatches', () async {
    final matches = [
      _match(id: 'a', kickoff: DateTime(2026, 8, 15), competition: 'Goiano'),
    ];
    repository.seasonFixtures = matches;

    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.allMatches, matches);
  });

  test('load sem nenhuma partida vira estado vazio', () async {
    repository.seasonFixtures = const [];

    await cubit.load();

    expect(cubit.state.status, LoadStatus.empty);
  });

  test('load com falha vira estado de erro', () async {
    repository.failure = const ServerFailure('sem conexão');

    await cubit.load();

    expect(cubit.state.status, LoadStatus.error);
    expect(cubit.state.errorMessage, 'sem conexão');
  });

  test('nextMonth/previousMonth navegam sem refazer request', () async {
    repository.seasonFixtures = const [];
    await cubit.load();
    final loadedAt = cubit.state.allMatches;
    cubit.jumpToMonth(DateTime(2026, 6));

    cubit.nextMonth();
    expect(cubit.state.selectedMonth, DateTime(2026, 7));

    cubit.previousMonth();
    cubit.previousMonth();
    expect(cubit.state.selectedMonth, DateTime(2026, 5));

    // Mesma lista de partidas o tempo todo — nenhuma chamada nova disparada.
    expect(cubit.state.allMatches, same(loadedAt));
  });

  test('virada de ano: dezembro -> janeiro do ano seguinte', () {
    cubit.jumpToMonth(DateTime(2026, 12));

    cubit.nextMonth();

    expect(cubit.state.selectedMonth, DateTime(2027, 1));
  });

  test('virada de ano pra trás: janeiro -> dezembro do ano anterior', () {
    cubit.jumpToMonth(DateTime(2026, 1));

    cubit.previousMonth();

    expect(cubit.state.selectedMonth, DateTime(2025, 12));
  });

  test(
    'matchesByDayInSelectedMonth agrupa só as partidas do mês selecionado',
    () async {
      // UTC de propósito (não `DateTime(...)` local): `matchesByDayInSelectedMonth`
      // agrupa por dia em horário de Brasília (`toBrazilTime`, nunca o fuso
      // da máquina rodando o teste) — meio-dia em Brasília nunca vira outro
      // dia na conversão, então o teste fica determinístico em qualquer
      // fuso.
      repository.seasonFixtures = [
        _match(
          id: 'in-month',
          kickoff: DateTime.utc(2026, 8, 20, 15),
          competition: 'Goiano',
        ),
        _match(
          id: 'other-month',
          kickoff: DateTime.utc(2026, 9, 1, 15),
          competition: 'Goiano',
        ),
      ];
      await cubit.load();
      cubit.jumpToMonth(DateTime(2026, 8));

      final byDay = cubit.state.matchesByDayInSelectedMonth;

      expect(byDay.keys, [20]);
      expect(byDay[20]!.single.id, 'in-month');
    },
  );

  test('jogo mandante (Goiás em casa) é reconhecido via Match.isHomeTeam', () {
    final home = _match(
      id: 'h',
      kickoff: DateTime(2026, 8, 1),
      competition: 'Goiano',
    );
    final away = _match(
      id: 'a',
      kickoff: DateTime(2026, 8, 2),
      competition: 'Goiano',
      goiasHome: false,
    );

    expect(home.isHomeTeam(_goiasTeamId), isTrue);
    expect(away.isHomeTeam(_goiasTeamId), isFalse);
  });

  test('filtro de competição some com jogos de outras categorias', () async {
    repository.seasonFixtures = [
      _match(id: 'g', kickoff: DateTime(2026, 8, 5), competition: 'Goiano'),
      _match(
        id: 'b',
        kickoff: DateTime(2026, 8, 6),
        competition: 'Brasileirão Série B Superbet',
      ),
    ];
    await cubit.load();

    cubit.setCompetitionFilter(CalendarCompetitionFilter.goiano);

    expect(cubit.state.filteredMatches, hasLength(1));
    expect(cubit.state.filteredMatches.single.id, 'g');
  });
}

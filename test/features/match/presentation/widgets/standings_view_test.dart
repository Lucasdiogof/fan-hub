import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/data/selected_competition_storage.dart';
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
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_view.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _primary = CompetitionRef(
  id: 'primary',
  name: 'Brasileirão Série B',
  format: CompetitionFormat.leagueTable,
  isClubParticipating: true,
);
const _secondary = CompetitionRef(
  id: 'sudamericana',
  name: 'CONMEBOL Sudamericana',
  format: CompetitionFormat.groupStage,
);

class _FakeRepository implements FootballRepository {
  @override
  Future<Result<List<CompetitionRef>>> getCompetitions() async =>
      const Success([_primary, _secondary]);

  @override
  Future<Result<({CompetitionRef competition, CompetitionSeason season})>>
  getCompetitionSeason({String? competitionId}) => throw UnimplementedError();

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
  getStandings({String? competitionId}) async => const Success((
    competition: _primary,
    table: [
      Standing(
        position: 1,
        team: Team(
          id: 1,
          name: 'Goiás',
          shortName: 'GOI',
          color: Color(0xFF000000),
        ),
        isActiveClub: true,
        points: 10,
        played: 5,
        wins: 3,
        draws: 1,
        losses: 1,
        goalDifference: 4,
      ),
    ],
    groups: [],
  ));

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() async =>
      const Success((nextMatch: null, recentResults: []));

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
  getCurrentRound({int offset = 0}) async => const Success((
    matches: [],
    roundLabel: null,
    hasPrevious: false,
    hasNext: false,
  ));

  @override
  Future<Result<List<Match>>> getSeasonFixtures() async => const Success([]);

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
  getMatchDetails(String fixtureId) => throw UnimplementedError();
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpStandings(WidgetTester tester) async {
    final cubit = GamesCubit(
      _FakeRepository(),
      SelectedCompetitionStorage(goiasClubConfig),
    );
    addTearDown(cubit.close);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider.value(
            value: cubit,
            child: const Scaffold(body: StandingsView()),
          ),
        ),
        GoRoute(
          path: '/games/competitions',
          builder: (context, state) =>
              const Scaffold(body: Text('Tela Campeonatos')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
      ),
    );
    // Deixa o cubit resolver rodada/snapshot/competições/classificação.
    await tester.pumpAndSettle();
  }

  testWidgets(
    'não mostra mais o seletor de competições (chips) na Classificação principal',
    (tester) async {
      await pumpStandings(tester);

      expect(find.text('Brasileirão Série B'), findsNothing);
      expect(find.text('CONMEBOL Sudamericana'), findsNothing);
    },
  );

  testWidgets(
    'CTA "Ver outros campeonatos" continua presente e navega pro catálogo',
    (tester) async {
      await pumpStandings(tester);

      final cta = find.text('Ver outros campeonatos');
      expect(cta, findsOneWidget);

      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('Tela Campeonatos'), findsOneWidget);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/home/presentation/widgets/compact_match_header.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/l10n/app_localizations.dart';

const _goias = Team(
  id: 1863,
  name: 'Goiás',
  shortName: 'GO',
  color: Color(0xFF004C1B),
);
const _opponent = Team(
  id: 2,
  name: 'Fortaleza',
  shortName: 'FOR',
  color: Color(0xFF1F6F4A),
);

Match _match({
  required MatchStatus status,
  DateTime? kickoff,
  int? homeScore,
  int? awayScore,
  String? minute,
}) => Match(
  id: 'm-1',
  competition: 'Campeonato Brasileiro Série B',
  round: 'Rodada 20',
  homeTeam: _goias,
  awayTeam: _opponent,
  stadium: 'Serrinha',
  kickoff: kickoff,
  status: status,
  homeScore: homeScore,
  awayScore: awayScore,
  minute: minute,
);

Future<void> _pump(WidgetTester tester, Match match) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.dark(),
    home: Scaffold(body: CompactMatchHeader(match: match)),
  ),
);

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  testWidgets('scheduled match shows date and time, no score', (tester) async {
    await _pump(
      tester,
      _match(status: MatchStatus.scheduled, kickoff: DateTime(2026, 9, 5, 16)),
    );

    expect(find.text('GOIÁS'), findsOneWidget);
    expect(find.text('FORTALEZA'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
    expect(find.textContaining('16:00'), findsOneWidget);
  });

  testWidgets('a match kicking off today shows "HOJE" instead of the date', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pump(
      tester,
      _match(
        status: MatchStatus.scheduled,
        kickoff: DateTime(now.year, now.month, now.day, 20),
      ),
    );

    expect(find.textContaining('HOJE'), findsOneWidget);
  });

  testWidgets('live match shows the score and the live indicator', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        status: MatchStatus.live,
        kickoff: DateTime(2026, 9, 5, 16),
        homeScore: 2,
        awayScore: 1,
        minute: "67'",
      ),
    );

    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.textContaining("67'"), findsOneWidget);
    expect(find.text('X'), findsNothing);
  });

  testWidgets('live match never invents a minute when the source has none', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        status: MatchStatus.live,
        kickoff: DateTime(2026, 9, 5, 16),
        homeScore: 0,
        awayScore: 0,
      ),
    );

    expect(find.textContaining("'"), findsNothing);
  });

  testWidgets('halftime shows the score without a live pulse/minute', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        status: MatchStatus.halftime,
        kickoff: DateTime(2026, 9, 5, 16),
        homeScore: 1,
        awayScore: 0,
      ),
    );

    expect(find.text('1 - 0'), findsOneWidget);
  });

  testWidgets('finished match keeps showing the final score', (tester) async {
    await _pump(
      tester,
      _match(
        status: MatchStatus.finished,
        kickoff: DateTime(2026, 9, 5, 16),
        homeScore: 2,
        awayScore: 1,
      ),
    );

    expect(find.text('2 - 1'), findsOneWidget);
    expect(find.text('FIM DE JOGO'), findsOneWidget);
  });

  testWidgets('the whole header is tappable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CompactMatchHeader(
            match: _match(
              status: MatchStatus.scheduled,
              kickoff: DateTime(2026, 9, 5, 16),
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CompactMatchHeader));
    expect(tapped, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_section.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/widgets/victory_glow_border.dart';
import 'package:material_ui/material_ui.dart';

Team _team(int id) =>
    Team(id: id, name: 'T$id', shortName: 'T$id', color: Colors.grey);
const _rival = 999;

Match _m(
  ClubConfig club, {
  required bool home,
  int? clubScore,
  int? rivalScore,
  MatchStatus status = MatchStatus.finished,
}) {
  final c = _team(club.integrations.oneFootballTeamId);
  final r = _team(_rival);
  return Match(
    id: 'm',
    competition: 'Série B',
    round: '1',
    homeTeam: home ? c : r,
    awayTeam: home ? r : c,
    stadium: 'E',
    status: status,
    homeScore: home ? clubScore : rivalScore,
    awayScore: home ? rivalScore : clubScore,
  );
}

Future<void> _pump(
  WidgetTester tester,
  ClubConfig club,
  Match match, {
  bool dark = true,
}) async {
  await sl.reset();
  sl.registerSingleton<ClubConfig>(club);
  final colors = dark ? club.branding.dark : club.branding.light;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: dark ? AppTheme.dark(colors) : AppTheme.light(colors),
      home: Scaffold(body: NextMatchSection(match: match)),
    ),
  );
}

void main() {
  final clubs = {
    'goias': goiasClubConfig,
    'vila': vilaNovaClubConfig,
    'bragantino': bragantinoClubConfig,
  };

  for (final e in clubs.entries) {
    final club = e.value;
    group(e.key, () {
      test('isClubWinning: mandante/visitante, vencendo/venceu', () {
        for (final home in [true, false]) {
          for (final s in [
            MatchStatus.live,
            MatchStatus.halftime,
            MatchStatus.finished,
          ]) {
            expect(
              _m(
                club,
                home: home,
                clubScore: 2,
                rivalScore: 1,
                status: s,
              ).isClubWinning(club),
              isTrue,
            );
          }
          expect(
            _m(
              club,
              home: home,
              clubScore: 1,
              rivalScore: 1,
            ).isClubWinning(club),
            isFalse,
          );
          expect(
            _m(
              club,
              home: home,
              clubScore: 0,
              rivalScore: 3,
            ).isClubWinning(club),
            isFalse,
          );
          expect(
            _m(club, home: home).isClubWinning(club),
            isFalse,
            reason: 'sem placar',
          );
        }
        expect(
          _m(
            club,
            home: true,
            clubScore: 2,
            rivalScore: 0,
            status: MatchStatus.scheduled,
          ).isClubWinning(club),
          isFalse,
        );
      });

      for (final dark in [true, false]) {
        final theme = dark ? 'escuro' : 'claro';
        testWidgets('vitória em casa/fora: glow na cor do clube ($theme)', (
          tester,
        ) async {
          for (final home in [true, false]) {
            await _pump(
              tester,
              club,
              _m(club, home: home, clubScore: 2, rivalScore: 0),
              dark: dark,
            );
            expect(find.byType(VictoryGlowBorder), findsOneWidget);
            final glow = tester.widget<VictoryGlowBorder>(
              find.byType(VictoryGlowBorder),
            );
            expect(glow.active, isTrue);
            expect(
              glow.color,
              (dark ? club.branding.dark : club.branding.light).cta,
            );
            expect(find.byKey(const ValueKey('victory-glow')), findsOneWidget);
            expect(find.text(home ? '2 x 0' : '0 x 2'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }

      testWidgets('empate e derrota: sem glow', (tester) async {
        for (final m in [
          _m(club, home: true, clubScore: 1, rivalScore: 1),
          _m(club, home: false, clubScore: 0, rivalScore: 2),
        ]) {
          await _pump(tester, club, m);
          expect(find.byKey(const ValueKey('victory-glow')), findsNothing);
        }
      });

      testWidgets('sem placar nem escudo: não quebra, sem glow', (
        tester,
      ) async {
        await _pump(
          tester,
          club,
          _m(club, home: true, status: MatchStatus.live),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('victory-glow')), findsNothing);
      });
    });
  }
}

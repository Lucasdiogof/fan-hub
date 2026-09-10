import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/domain/entities/knockout_round.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/knockout_bracket_view.dart';
import 'package:goias_app/l10n/app_localizations.dart';

const _home = Team(
  id: 1,
  name: 'Grêmio',
  shortName: 'GRE',
  color: Color(0xFF000000),
);
const _away = Team(
  id: 2,
  name: 'Internacional',
  shortName: 'INT',
  color: Color(0xFF000000),
);

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  testWidgets(
    'confronto de ida e volta mostra o placar de CADA perna, nunca só a soma (2026-09-11)',
    (tester) async {
      const round = KnockoutRound(
        id: 'round-0',
        name: 'Semifinais',
        order: 0,
        status: StageStatus.completed,
        isCurrent: true,
        ties: [
          KnockoutTie(
            homeTeam: _home,
            awayTeam: _away,
            legs: [
              KnockoutLeg(
                legType: KnockoutLegType.first,
                status: MatchStatus.finished,
                homeScore: 3,
                awayScore: 2,
              ),
              KnockoutLeg(
                legType: KnockoutLegType.second,
                status: MatchStatus.finished,
                homeScore: 1,
                awayScore: 1,
              ),
            ],
            aggregateHome: 4,
            aggregateAway: 3,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(const KnockoutBracketView(rounds: [round])),
      );

      // As 4 pernas individuais aparecem — 3, 2, 1, 1 — nunca só 4 e 3.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
      // O agregado ainda existe, mas como resumo na linha de status.
      expect(find.textContaining('4-3'), findsOneWidget);
    },
  );

  testWidgets('confronto de jogo único mostra só uma coluna de placar', (
    tester,
  ) async {
    const round = KnockoutRound(
      id: 'round-0',
      name: 'Final',
      order: 0,
      status: StageStatus.completed,
      isCurrent: true,
      ties: [
        KnockoutTie(
          homeTeam: _home,
          awayTeam: _away,
          legs: [
            KnockoutLeg(
              legType: KnockoutLegType.single,
              status: MatchStatus.finished,
              homeScore: 2,
              awayScore: 1,
            ),
          ],
          aggregateHome: 2,
          aggregateAway: 1,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(const KnockoutBracketView(rounds: [round])));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining('Ida'), findsNothing);
    expect(find.textContaining('Volta'), findsNothing);
  });
}

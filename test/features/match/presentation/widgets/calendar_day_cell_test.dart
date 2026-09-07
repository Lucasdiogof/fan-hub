import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/calendar_day_cell.dart';
import 'package:goias_app/l10n/app_localizations.dart';

// Fixture de teste, explicitamente Goiás (TEST_FIXTURE_ALLOWED) — mesmo id
// de `goiasClubConfig.integrations.oneFootballTeamId`.
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

final _match = Match(
  id: 'match-1',
  competition: 'Goiano',
  round: 'Rodada 1',
  homeTeam: _goias,
  awayTeam: _opponent,
  stadium: 'Serrinha',
  kickoff: DateTime(2026, 8, 15),
  status: MatchStatus.scheduled,
);

// Mesmo tamanho de célula que o `GridView.count` real dá em produção — sem
// isso, o Column por dentro (crest + pill) não tem constraint nenhuma e
// estoura layout no teste (nunca acontece de verdade, porque o grid real
// sempre dá um tamanho definido pra cada célula).
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(child: SizedBox(width: 48, height: 90, child: child)),
  ),
);

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  testWidgets('dia sem partida não é clicável e não mostra escudo', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        CalendarDayCell(
          date: DateTime(2026, 8, 3),
          matches: const [],
          isToday: false,
          onMatchTap: (_) => tapped = true,
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(tapped, isFalse);
  });

  testWidgets(
    'tocar no indicador de partida chama onMatchTap com a partida certa',
    (tester) async {
      Match? tappedMatch;
      await tester.pumpWidget(
        _wrap(
          CalendarDayCell(
            date: DateTime(2026, 8, 15),
            matches: [_match],
            isToday: false,
            onMatchTap: (m) => tappedMatch = m,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tappedMatch?.id, 'match-1');
    },
  );

  testWidgets('dia atual recebe destaque diferente de um dia comum', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CalendarDayCell(
          date: DateTime(2026, 8, 15),
          matches: const [],
          isToday: true,
          onMatchTap: (_) {},
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('15'));
    expect(text.style?.fontWeight, FontWeight.w800);
  });

  // O destaque de "hoje" sumia exatamente no dia de jogo: a célula troca o
  // número pelo escudo e levava junto a decoração, então o dia mais
  // importante do mês era o único sem marcação.
  testWidgets('dia de jogo que é hoje mantém o destaque de hoje', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CalendarDayCell(
          date: DateTime(2026, 8, 15),
          matches: [_match],
          isToday: true,
          onMatchTap: (_) {},
        ),
      ),
    );

    final decorated = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => w.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border != null)
        .toList();
    expect(
      decorated,
      isNotEmpty,
      reason: 'dia de jogo em que hoje bate precisa continuar contornado',
    );
    // E o escudo continua lá — o destaque não substitui a informação.
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('dia de jogo que NÃO é hoje não ganha contorno', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CalendarDayCell(
          date: DateTime(2026, 8, 15),
          matches: [_match],
          isToday: false,
          onMatchTap: (_) {},
        ),
      ),
    );

    final bordered = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => w.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border != null);
    expect(bordered, isEmpty);
  });

  testWidgets('célula vazia (fora do mês) não renderiza nada', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CalendarDayCell(
          date: null,
          matches: const [],
          isToday: false,
          onMatchTap: (_) {},
        ),
      ),
    );

    expect(
      find.byWidgetPredicate((w) => w is SizedBox && w.width == 0),
      findsOneWidget,
    );
    expect(find.byType(Text), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';

Widget _host(
  Widget child, {
  double width = 390,
  ThemeData? theme,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

List<AnimatedDefaultTextStyle> _labels(WidgetTester tester) => tester
    .widgetList<AnimatedDefaultTextStyle>(
      find.descendant(
        of: find.byType(FanHubTabBar),
        matching: find.byType(AnimatedDefaultTextStyle),
      ),
    )
    .toList();

/// Os conjuntos REAIS de rótulos do app, em cada idioma.
Map<String, List<String>> _realSets(AppLocalizations l) => {
  'jogos': [l.matchTabMatches, l.matchTabCalendar, l.matchTabStandings],
  'midia': [
    l.newsTitle,
    l.socialPlatformInstagram,
    l.socialPlatformYoutube,
    l.socialPlatformX,
  ],
  'ranking': [
    l.arenaRankingAllTime,
    l.arenaRankingMonthly,
    l.arenaRankingWeekly,
  ],
  'ingressos': [l.ticketsTabUpcoming, l.ticketsTabHistory],
  'escalacao': [l.crowdTitle, l.crowdTabEscale],
  'passaporte': [l.passportRankingPeriodOverall, '2026', '2025', '2024'],
};

void main() {
  group('uma linha, sem reticências, sem overflow', () {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final width in [280.0, 320.0, 360.0, 390.0, 600.0, 900.0]) {
        testWidgets('${locale.languageCode} em ${width.toInt()}px', (
          tester,
        ) async {
          final l = lookupAppLocalizations(locale);
          for (final entry in _realSets(l).entries) {
            await tester.pumpWidget(
              _host(
                FanHubTabBar(
                  labels: entry.value,
                  selectedIndex: 0,
                  onChanged: (_) {},
                ),
                width: width,
              ),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} @ $width (${locale.languageCode})',
            );
            final labels = _labels(tester);
            expect(labels, hasLength(entry.value.length));
            for (final label in labels) {
              expect(label.maxLines, 1);
              expect(label.softWrap, isFalse);
              expect(label.overflow, TextOverflow.visible);
            }
            // Mesmo tamanho de fonte em todas as abas do conjunto.
            expect(
              labels.map((label) => label.style.fontSize).toSet(),
              hasLength(1),
              reason: entry.key,
            );
          }
        });
      }
    }
  });

  testWidgets('mantém a fonte preferida quando tudo cabe', (tester) async {
    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['PARTIDAS', 'CALENDÁRIO', 'CLASSIFICAÇÃO'],
          selectedIndex: 1,
          onChanged: (_) {},
        ),
        width: 600,
      ),
    );
    expect(_labels(tester).map((l) => l.style.fontSize).toSet(), {
      FanHubTabBar.preferredFontSize,
    });
  });

  testWidgets('desce a fonte do conjunto inteiro, nunca abaixo do mínimo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['PARTIDAS', 'CALENDÁRIO', 'CLASSIFICAÇÃO'],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
        width: 300,
      ),
    );
    final sizes = _labels(tester).map((l) => l.style.fontSize!).toSet();
    expect(sizes, hasLength(1));
    expect(sizes.single, lessThan(FanHubTabBar.preferredFontSize));
    expect(sizes.single, greaterThanOrEqualTo(FanHubTabBar.minFontSize));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rótulo impossível de caber vira faixa rolável, em tamanho '
      'legível e inteiro', (tester) async {
    const long = [
      'HISTÓRICO COMPLETO DA TEMPORADA',
      'PRÓXIMOS JOGOS DO CAMPEONATO',
      'CLASSIFICAÇÃO GERAL',
    ];
    await tester.pumpWidget(
      _host(
        FanHubTabBar(labels: long, selectedIndex: 0, onChanged: (_) {}),
        width: 320,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(_labels(tester).map((l) => l.style.fontSize).toSet(), {
      FanHubTabBar.scrollFontSize,
    });
    for (final text in long) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('fonte do sistema grande não gera overflow', (tester) async {
    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['PARTIDAS', 'CALENDÁRIO', 'CLASSIFICAÇÃO'],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
        width: 320,
        textScale: 1.6,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('toque chama onChanged com o índice certo', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['A', 'B', 'C'],
          selectedIndex: 0,
          onChanged: (i) => tapped = i,
        ),
      ),
    );
    await tester.tap(find.text('C'));
    expect(tapped, 2);
  });

  testWidgets('selecionada em destaque; índice -1 não destaca nenhuma', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['A', 'B'],
          selectedIndex: 1,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final styles = _labels(tester).map((l) => l.style).toList();
    expect(styles[1].fontWeight, FontWeight.w700);
    expect(styles[0].fontWeight, FontWeight.w500);
    expect(styles[1].color, isNot(styles[0].color));

    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['A', 'B'],
          selectedIndex: -1,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final none = _labels(tester).map((l) => l.style.fontWeight).toSet();
    expect(none, {FontWeight.w500});
  });

  testWidgets('tema escuro renderiza sem erro', (tester) async {
    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['PARTIDAS', 'CALENDÁRIO', 'CLASSIFICAÇÃO'],
          selectedIndex: 1,
          onChanged: (_) {},
        ),
        theme: AppTheme.dark(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('altura compacta (barra de 46px)', (tester) async {
    await tester.pumpWidget(
      _host(
        FanHubTabBar(
          labels: const ['A', 'B'],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(FanHubTabBar)).height, 46);
  });

  group('FanHubControllerTabBar', () {
    testWidgets('segue o TabController e o move ao tocar', (tester) async {
      late TabController controller;
      await tester.pumpWidget(
        _host(_ControllerHarness(onController: (c) => controller = c)),
      );
      expect(controller.index, 0);
      await tester.tap(find.text('Segunda'));
      await tester.pumpAndSettle();
      expect(controller.index, 1);
      expect(find.text('conteúdo 2'), findsOneWidget);

      // Troca feita pelo controller (swipe) reflete na barra.
      controller.animateTo(0);
      await tester.pumpAndSettle();
      final weights = _labels(tester).map((l) => l.style.fontWeight).toList();
      expect(weights, [FontWeight.w700, FontWeight.w500]);
    });
  });
}

class _ControllerHarness extends StatefulWidget {
  const _ControllerHarness({required this.onController});

  final ValueChanged<TabController> onController;

  @override
  State<_ControllerHarness> createState() => _ControllerHarnessState();
}

class _ControllerHarnessState extends State<_ControllerHarness>
    with SingleTickerProviderStateMixin {
  late final controller = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    widget.onController(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FanHubControllerTabBar(
          controller: controller,
          labels: const ['Primeira', 'Segunda'],
        ),
        SizedBox(
          height: 80,
          child: TabBarView(
            controller: controller,
            children: const [Text('conteúdo 1'), Text('conteúdo 2')],
          ),
        ),
      ],
    );
  }
}

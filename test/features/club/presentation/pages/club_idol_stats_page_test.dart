import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/club/data/goias_idols_data.dart';
import 'package:goias_app/features/club/domain/entities/active_idol_tracking.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/domain/repositories/active_idol_stats_repository.dart';
import 'package:goias_app/features/club/presentation/pages/club_idol_detail_page.dart';
import 'package:goias_app/l10n/app_localizations.dart';

import '../../idol_stats_fixtures.dart';

/// Repositório falso da tela: devolve [stats] (ou lança) e conta chamadas.
class _FakeStatsRepository implements ActiveIdolStatsRepository {
  _FakeStatsRepository({this.stats, this.fails = false});

  final IdolStats? stats;
  final bool fails;
  int calls = 0;

  @override
  IdolStats? lastCompleteFor(ClubIdol idol) => null;

  @override
  Future<Map<String, IdolStats>> loadStats(List<ClubIdol> idols) async {
    calls += 1;
    if (fails) throw StateError('provedor fora do ar');
    return {for (final idol in idols) idol.name: stats!};
  }
}

void main() {
  tearDown(sl.reset);

  Future<void> open(
    WidgetTester tester,
    ClubIdol idol, {
    ActiveIdolStatsRepository? repository,
  }) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ClubIdolDetailPage(idol: idol, statsRepository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Tadeu com partida posterior: o card mostra 407, não 406', (
    tester,
  ) async {
    final repo = _FakeStatsRepository(
      stats: const IdolStats(
        appearances: 407,
        goals: 13,
        asOfDate: '2026-10-06',
        countedMatches: 1,
      ),
    );
    await open(tester, tadeu, repository: repo);
    expect(repo.calls, 1);
    expect(find.text('407'), findsOneWidget);
    expect(find.text('406'), findsNothing);
    expect(find.text('Números até 06/10/2026'), findsOneWidget);
  });

  testWidgets('falha ao carregar: continua mostrando o baseline (406), '
      'nunca zero e nunca some', (tester) async {
    final repo = _FakeStatsRepository(fails: true);
    await open(tester, tadeu, repository: repo);
    expect(repo.calls, 1);
    expect(find.text('406'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('Números até 01/10/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem repositório (ex.: offline total): baseline auditado', (
    tester,
  ) async {
    await open(tester, tadeu);
    expect(find.text('406'), findsOneWidget);
    expect(find.text('Números até 01/10/2026'), findsOneWidget);
  });

  testWidgets('10) ídolo histórico mostra exatamente o número estático e nem '
      'chama o repositório', (tester) async {
    final harlei = GoiasIdolsData.idols.firstWhere((i) => i.name == 'Harlei');
    final repo = _FakeStatsRepository(
      stats: const IdolStats(
        appearances: 9999,
        goals: 9999,
        asOfDate: '2099-01-01',
      ),
    );
    await open(tester, harlei, repository: repo);
    expect(repo.calls, 0);
    expect(find.text('831'), findsOneWidget);
    expect(find.text('9999'), findsNothing);
  });

  test('só o Tadeu está marcado como ativo no catálogo do Goiás', () {
    final active = [
      for (final i in GoiasIdolsData.idols)
        if (i.tracking != null) i.name,
    ];
    expect(active, ['Tadeu']);
    // E o baseline dele NÃO fica mais nos campos estáticos de jogos/gols.
    expect(tadeu.matches, isNull);
    expect(tadeu.goals, isNull);
    expect(tadeu.statsAsOf, isNull);
  });
}

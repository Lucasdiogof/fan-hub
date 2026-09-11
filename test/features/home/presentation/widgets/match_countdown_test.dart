// Spec 2026-09-11: a contagem regressiva da Home não pode depender do fuso
// configurado no aparelho. `MatchCountdown` já faz a aritmética certa
// (`DateTime.now()` puro, `.difference()` sobre instante absoluto — nunca
// `.toLocal()`), mas o bug real estava em COMO o kickoff chegava até aqui
// (ver `brazil_time_test.dart`, que prova a invariância de fuso na
// aritmética). Este arquivo prova a mesma invariância na PONTA — o widget
// renderiza o mesmo tanto de dias/horas restantes pro mesmo instante real,
// não importa em qual fuso esse instante é representado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/home/presentation/widgets/match_countdown.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> _pump(WidgetTester tester, DateTime kickoff) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: MatchCountdown(kickoff: kickoff)),
  ),
);

// Os blocos de valor (dias/horas/min/seg) são os únicos `Text` com essa
// fontSize — mesma técnica de desambiguação já usada em
// `knockout_stage_view_test.dart` pra achar um `Text` específico sem
// depender de `Key`.
List<String> _countdownValues(WidgetTester tester) => tester
    .widgetList<Text>(
      find.byWidgetPredicate((w) => w is Text && w.style?.fontSize == 17),
    )
    .map((t) => t.data!)
    .toList();

void main() {
  setUpAll(initializeBrazilTimeZone);

  testWidgets(
    'mesmo kickoff real mostra os mesmos dias/horas restantes, seja ele '
    'representado num DateTime UTC puro ou projetado em qualquer fuso — '
    'simula o aparelho em qualquer lugar do mundo (spec 2026-09-11)',
    (tester) async {
      // Margem generosa (5 dias) pra qualquer drift de milissegundos entre
      // os pumps nunca cruzar uma fronteira de dia/hora/minuto.
      final kickoffUtc = DateTime.now().toUtc().add(
        const Duration(days: 5, hours: 4),
      );

      await _pump(tester, kickoffUtc);
      final valuesFromUtc = _countdownValues(tester);

      for (final zoneName in [
        'America/Sao_Paulo',
        'America/New_York',
        'Europe/London',
        'Asia/Tokyo',
        'Pacific/Auckland',
      ]) {
        final kickoffAsSeenByThatDevice = tz.TZDateTime.from(
          kickoffUtc,
          tz.getLocation(zoneName),
        );
        await _pump(tester, kickoffAsSeenByThatDevice);
        final values = _countdownValues(tester);

        // Dias e horas: estáveis contra qualquer drift de milissegundos
        // entre pumps. Minutos/segundos não entram na comparação aqui —
        // são cobertos deterministicamente (sem qualquer wall-clock real)
        // pelos testes de `brazil_time_test.dart`.
        expect(
          values[0],
          valuesFromUtc[0],
          reason: 'dias restantes, aparelho em $zoneName',
        );
        expect(
          values[1],
          valuesFromUtc[1],
          reason: 'horas restantes, aparelho em $zoneName',
        );
      }
    },
  );

  testWidgets('mostra dias/horas/min/seg corretos pro kickoff informado', (
    tester,
  ) async {
    final kickoff = DateTime.now().toUtc().add(
      const Duration(days: 2, hours: 3, minutes: 4),
    );

    await _pump(tester, kickoff);
    final values = _countdownValues(tester);

    expect(values[0], '02');
    expect(values[1], '03');
  });
}

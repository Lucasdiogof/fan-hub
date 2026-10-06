import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_name_label.dart';
import 'package:goias_app/shared/utils/display_name_fit.dart';

Widget _host(Widget child, {double width = 200}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  group('personNameCandidates', () {
    test('do maior pro menor, sem terminar em partícula', () {
      expect(personNameCandidates('deusimar ribeiro de franca'), [
        'deusimar ribeiro de franca',
        'deusimar ribeiro',
        'deusimar',
      ]);
      expect(personNameCandidates('Lucas Diogo França'), [
        'Lucas Diogo França',
        'Lucas Diogo',
        'Lucas',
      ]);
    });

    test('nome de uma palavra só e vazio não quebram', () {
      expect(personNameCandidates('Jaumzin'), ['Jaumzin']);
      expect(personNameCandidates('  '), ['']);
    });
  });

  group('playerNameCandidates', () {
    test('apelido provável é o último nome', () {
      expect(playerNameCandidates('Wellington Saci'), [
        'Wellington Saci',
        'Saci',
        'Wellington',
      ]);
      expect(playerNameCandidates('Felipe Machado'), [
        'Felipe Machado',
        'Machado',
        'Felipe',
      ]);
    });

    test('sufixo de geração não vira apelido sozinho', () {
      expect(playerNameCandidates('Otacílio Neto'), [
        'Otacílio Neto',
        'Otacílio',
      ]);
      expect(playerNameCandidates('Hernane Júnior'), [
        'Hernane Júnior',
        'Hernane',
      ]);
    });

    test('último nome que é prenome comum: vira primeiro nome + inicial', () {
      expect(playerNameCandidates('Carlos Alberto'), [
        'Carlos Alberto',
        'Carlos A.',
        'Carlos',
      ]);
    });

    test('partícula nunca abre o apelido', () {
      expect(playerNameCandidates('Pedro da Silva'), [
        'Pedro da Silva',
        'Silva',
        'Pedro',
      ]);
    });

    test('nome de uma palavra só fica como está', () {
      expect(playerNameCandidates('Harlei'), ['Harlei']);
    });
  });

  group('LineupNameLabel — nunca corta o nome', () {
    List<String> shown(WidgetTester tester) => [
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(LineupNameLabel),
          matching: find.byType(Text),
        ),
      ))
        if ((t.data ?? '').trim().isNotEmpty) t.data!,
    ];

    testWidgets('cabe: nome completo em duas linhas', (tester) async {
      await tester.pumpWidget(
        _host(const LineupNameLabel(text: 'Rafael Moura', maxWidth: 110)),
      );
      expect(shown(tester), ['RAFAEL', 'MOURA']);
    });

    testWidgets('não cabe: troca pelo apelido em vez de reticências', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const LineupNameLabel(text: 'Wellington Saci', maxWidth: 56)),
      );
      expect(shown(tester), ['SACI']);
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
      }
    });

    testWidgets('nenhuma linha usa reticências em larguras variadas', (
      tester,
    ) async {
      const names = [
        'Otacílio Neto',
        'Carlos Alberto',
        'Felipe Machado',
        'Wellington Saci',
        'Douglas Coutinho',
        'Harlei',
      ];
      for (final width in [48.0, 56.0, 64.0, 72.0, 90.0]) {
        for (final maxLines in [1, 2]) {
          await tester.pumpWidget(
            _host(
              Column(
                children: [
                  for (final n in names)
                    LineupNameLabel(
                      text: n,
                      maxWidth: width,
                      maxLines: maxLines,
                    ),
                ],
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: '$width/$maxLines');
          for (final t in tester.widgetList<Text>(find.byType(Text))) {
            expect(t.overflow, isNot(TextOverflow.ellipsis));
          }
        }
      }
    });

    testWidgets('altura reservada igual com 1 ou 2 palavras', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              LineupNameLabel(text: 'Harlei', maxWidth: 72),
              LineupNameLabel(text: 'Rafael Moura', maxWidth: 72),
            ],
          ),
        ),
      );
      final a = tester.getSize(find.byType(LineupNameLabel).at(0)).height;
      final b = tester.getSize(find.byType(LineupNameLabel).at(1)).height;
      expect(a, b);
    });

    testWidgets('slot vazio (sigla) não vira apelido nem quebra', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LineupNameLabel(text: 'ZAG', maxWidth: 56, allowSplit: false),
        ),
      );
      expect(shown(tester), ['ZAG']);
    });
  });

  group('FittedNameText', () {
    testWidgets('mostra o maior nome que cabe, sem reticências', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 14, fontFamily: 'Roboto');
      Future<String> pick(double width) async {
        await tester.pumpWidget(
          _host(
            const FittedNameText('deusimar ribeiro de franca', style: style),
            width: width,
          ),
        );
        final t = tester.widget<Text>(find.byType(Text));
        expect(t.overflow, TextOverflow.ellipsis);
        return t.data!;
      }

      expect(await pick(2000), 'deusimar ribeiro de franca');
      final medium = await pick(150);
      expect(medium, anyOf('deusimar ribeiro', 'deusimar'));
      expect(await pick(20), 'deusimar');
    });
  });
}

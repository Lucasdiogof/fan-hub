import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/presentation/tactical_identity_copy.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Resolve TODO o texto do questionário (10 enunciados + 40 alternativas)
/// pelo mesmo caminho que a tela usa, num clube e num idioma.
Future<({List<String> stems, List<String> options})> _copy(
  WidgetTester tester,
  ClubConfig club,
  Locale locale,
) async {
  await sl.reset();
  sl.registerSingleton<ClubConfig>(club);

  final stems = <String>[];
  final options = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          for (final q in tacticalIdentityQuestions) {
            stems.add(context.tacticalQuestionText(q));
            for (final o in q.options) {
              options.add(context.tacticalOptionText(o));
            }
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return (stems: stems, options: options);
}

void main() {
  tearDown(() => sl.reset());

  const pt = Locale('pt');
  const en = Locale('en');
  const es = Locale('es');

  group('todo texto existe nos 3 idiomas, nos 2 clubes', () {
    for (final (clube, config) in [
      ('Goiás', goiasClubConfig),
      ('Bragantino', bragantinoClubConfig),
    ]) {
      for (final (idioma, locale) in [('pt', pt), ('en', en), ('es', es)]) {
        testWidgets('$clube / $idioma resolve 10 enunciados e 40 opções', (
          tester,
        ) async {
          final copy = await _copy(tester, config, locale);
          expect(copy.stems, hasLength(10));
          expect(copy.options, hasLength(40));
          for (final t in [...copy.stems, ...copy.options]) {
            expect(t.trim(), isNotEmpty);
            // Placeholder não substituído vazaria como chaves literais.
            expect(t, isNot(contains('{club}')));
          }
          // Nenhum texto repetido: duas alternativas iguais na mesma tela
          // seriam um erro de mapeamento id → chave l10n.
          expect(copy.options.toSet(), hasLength(40));
        });
      }
    }
  });

  group('o nome do clube entra certo', () {
    testWidgets('Goiás em PT mantém as frases originais', (tester) async {
      final copy = await _copy(tester, goiasClubConfig, pt);
      expect(copy.stems[0], contains('O que seu Goiás faz?'));
      expect(copy.stems[2], startsWith('O Goiás vence por 1 a 0'));
      expect(copy.stems[6], startsWith('Intervalo. O Goiás perde por 1 a 0'));
      expect(copy.stems[8], contains('o Goiás precisa de um gol'));
    });

    testWidgets('Bragantino em PT recebe o próprio nome', (tester) async {
      final copy = await _copy(tester, bragantinoClubConfig, pt);
      expect(copy.stems[0], contains('O que seu Bragantino faz?'));
      expect(copy.stems[2], startsWith('O Bragantino vence por 1 a 0'));
      expect(copy.stems[8], contains('o Bragantino precisa de um gol'));
    });

    testWidgets('EN e ES também trocam o nome', (tester) async {
      final enBraga = await _copy(tester, bragantinoClubConfig, en);
      expect(enBraga.stems[0], contains('What does your Bragantino do?'));
      expect(enBraga.stems[8], contains('Bragantino need a goal'));

      final esBraga = await _copy(tester, bragantinoClubConfig, es);
      expect(esBraga.stems[0], contains('¿Qué hace tu Bragantino?'));
      expect(esBraga.stems[8], contains('el Bragantino necesita un gol'));

      final enGoias = await _copy(tester, goiasClubConfig, en);
      expect(enGoias.stems[0], contains('What does your Goiás do?'));
    });
  });

  group('zero copy do Goiás no flavor Bragantino', () {
    for (final (idioma, locale) in [('pt', pt), ('en', en), ('es', es)]) {
      testWidgets('$idioma: nada de Goiás/Esmeraldino/Verdão', (tester) async {
        final copy = await _copy(tester, bragantinoClubConfig, locale);
        for (final texto in [...copy.stems, ...copy.options]) {
          for (final termo in ['goiás', 'goias', 'esmeraldin', 'verdão']) {
            expect(
              texto.toLowerCase(),
              isNot(contains(termo)),
              reason: '"$termo" apareceu no questionário do Bragantino',
            );
          }
        }
      });
    }
  });

  group('os idiomas são realmente diferentes', () {
    testWidgets('PT, EN e ES não devolvem o mesmo texto', (tester) async {
      // Uma chave esquecida no ARB de outro idioma cairia no template
      // do idioma base e passaria despercebida sem esta checagem.
      final a = await _copy(tester, goiasClubConfig, pt);
      final b = await _copy(tester, goiasClubConfig, en);
      final c = await _copy(tester, goiasClubConfig, es);
      for (var i = 0; i < a.options.length; i++) {
        expect(a.options[i], isNot(b.options[i]), reason: 'opção $i PT=EN');
        expect(b.options[i], isNot(c.options[i]), reason: 'opção $i EN=ES');
      }
    });
  });

  group('a estrutura do questionário não mudou', () {
    test('10 perguntas, 4 alternativas cada, ids únicos', () {
      expect(tacticalIdentityQuestions, hasLength(10));
      final ids = <String>{};
      for (final q in tacticalIdentityQuestions) {
        expect(q.options, hasLength(4));
        expect(ids.add(q.id), isTrue);
        for (final o in q.options) {
          expect(ids.add(o.id), isTrue);
        }
      }
    });
  });
}

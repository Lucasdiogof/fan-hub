import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/passport/domain/club_passport_content.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';
import 'package:goias_app/features/passport/presentation/passport_copy_extension.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Tudo que um torcedor do clube pode ler na tela do Passaporte, num idioma.
List<String> _allCopy(PassportCopy c) => [
  c.title,
  c.cardDescription,
  c.emptyBody,
  c.shareText,
  c.levels.starter,
  c.levels.present,
  c.levels.bleacher,
  c.levels.roots,
  c.levels.legend,
  c.matchesLived(0),
  c.matchesLived(1),
  c.matchesLived(7),
];

List<String> _everything(ClubPassportContent content) =>
    [content.pt, content.en, content.es].expand(_allCopy).toList();

/// Renderiza a cópia resolvida pelo clube ATIVO — mesmo caminho que a tela
/// usa (`context.passportCopy`), não a leitura direta da constante.
Future<PassportCopy> _copyOnScreen(
  WidgetTester tester,
  ClubConfig club,
  Locale locale,
) async {
  await sl.reset();
  sl.registerSingleton<ClubConfig>(club);

  late PassportCopy captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = context.passportCopy;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  tearDown(() => sl.reset());

  group('Goiás — nada do que existe hoje pode mudar', () {
    final copy = GoiasContentUnderTest.pt;

    test('o título continua Passaporte Esmeraldino nos 3 idiomas', () {
      final content = goiasClubConfig.passportContent;
      expect(content.pt.title, 'Passaporte Esmeraldino');
      expect(content.en.title, 'Passaporte Esmeraldino');
      expect(content.es.title, 'Passaporte Esmeraldino');
    });

    test('os nomes dos níveis continuam exatamente os atuais', () {
      expect(copy.levels.starter, 'Primeiros Passos');
      expect(copy.levels.present, 'Torcedor Presente');
      expect(copy.levels.bleacher, 'Esmeraldino de Arquibancada');
      expect(copy.levels.roots, 'Verdão Raiz');
      expect(copy.levels.legend, 'Lenda Esmeraldina');
    });

    test('a contagem de jogos preserva o caso especial de zero, só em PT', () {
      final content = goiasClubConfig.passportContent;
      expect(
        content.pt.matchesLived(0),
        'Nenhum jogo vivido ainda com o Verdão',
      );
      expect(
        content.pt.matchesLived(1),
        '1 jogo cantando e vibrando com o Verdão',
      );
      expect(
        content.pt.matchesLived(43),
        '43 jogos cantando e vibrando com o Verdão',
      );
      // Inglês e espanhol nunca tiveram forma própria pra zero — usam o
      // plural, como sempre usaram. Não "consertar" isso sem pedido.
      expect(
        content.en.matchesLived(0),
        '0 matches singing and roaring with Verdão',
      );
      expect(
        content.es.matchesLived(0),
        '0 partidos cantando y vibrando con el Verdão',
      );
    });

    test('o compartilhamento continua o mesmo', () {
      expect(copy.shareText, 'Essa é a minha trajetória com o Goiás! 💚');
    });
  });

  group('Bragantino — identidade própria', () {
    test('o título é Passaporte Massa Bruta nos 3 idiomas', () {
      final content = bragantinoClubConfig.passportContent;
      expect(content.pt.title, 'Passaporte Massa Bruta');
      expect(content.en.title, 'Passaporte Massa Bruta');
      expect(content.es.title, 'Passaporte Massa Bruta');
    });

    test('os níveis com identidade são os definidos pelo clube', () {
      final pt = bragantinoClubConfig.passportContent.pt;
      expect(pt.levels.bleacher, 'Bragantino de Arquibancada');
      expect(pt.levels.roots, 'Braga Raiz');
      expect(pt.levels.legend, 'Lenda da Massa Bruta');
    });

    test('o compartilhamento é o do Bragantino', () {
      expect(
        bragantinoClubConfig.passportContent.pt.shareText,
        'Essa é a minha trajetória com o Massa Bruta! 🔴⚪',
      );
    });

    test('Massa Bruta e Braga não são traduzidos em EN/ES', () {
      final content = bragantinoClubConfig.passportContent;
      for (final copy in [content.en, content.es]) {
        expect(copy.title, contains('Massa Bruta'));
        expect(copy.shareText, contains('Massa Bruta'));
        expect(copy.levels.legend, contains('Massa Bruta'));
        expect(copy.levels.roots, contains('Braga'));
      }
    });
  });

  group('nenhum clube vaza no outro', () {
    test('nada do Goiás aparece na cópia do Bragantino', () {
      final proibidos = [
        'Esmeraldino',
        'Esmeraldina',
        'Esmeralda',
        'Verdão',
        'Goiás',
      ];
      for (final texto in _everything(bragantinoClubConfig.passportContent)) {
        for (final termo in proibidos) {
          expect(
            texto.toLowerCase(),
            isNot(contains(termo.toLowerCase())),
            reason: '"$termo" apareceu no Passaporte do Bragantino: "$texto"',
          );
        }
      }
    });

    test('nada do Bragantino aparece na cópia do Goiás', () {
      final proibidos = ['Massa Bruta', 'Braga', 'Bragantino'];
      for (final texto in _everything(goiasClubConfig.passportContent)) {
        for (final termo in proibidos) {
          expect(
            texto.toLowerCase(),
            isNot(contains(termo.toLowerCase())),
            reason: '"$termo" apareceu no Passaporte do Goiás: "$texto"',
          );
        }
      }
    });

    test('os dois clubes não compartilham nenhuma frase com identidade', () {
      final goias = _everything(goiasClubConfig.passportContent).toSet();
      final braga = _everything(bragantinoClubConfig.passportContent).toSet();
      final iguais = goias.intersection(braga);
      // O que pode coincidir é só copy NEUTRA (as duas primeiras faixas, que
      // não carregam nome de clube). Qualquer outra coincidência significa
      // que um clube herdou texto do outro.
      const neutrasEsperadas = {
        'Primeiros Passos',
        'Torcedor Presente',
        'First Steps',
        'Regular Supporter',
        'Primeros Pasos',
        'Hincha Presente',
      };
      expect(iguais, neutrasEsperadas);
    });
  });

  group('os níveis são conteúdo editorial, não concatenação de gentílico', () {
    test('nenhum nível é o gentílico colado numa fórmula', () {
      for (final club in [goiasClubConfig, bragantinoClubConfig]) {
        final demonym = club.identity.fanDemonym;
        final pt = club.passportContent.pt.levels;
        // Estas são exatamente as frases que sairiam de
        // `"Lenda $demonym"` / `"$demonym Raiz"`. Se alguma bater, alguém
        // trocou a cópia editorial por interpolação.
        expect(pt.legend, isNot('Lenda $demonym'));
        expect(pt.roots, isNot('$demonym Raiz'));
      }
    });

    test('a concordância do Goiás não sobrevive a uma fórmula', () {
      // "Lenda Esmeraldina" concorda em gênero com "Lenda"; o gentílico é
      // "Esmeraldino". Nenhuma interpolação produz o texto correto — é por
      // isso que a cópia é escrita por extenso.
      expect(goiasClubConfig.identity.fanDemonym, 'Esmeraldino');
      expect(
        goiasClubConfig.passportContent.pt.levels.legend,
        'Lenda Esmeraldina',
      );
    });

    test('o Bragantino precisa da preposição que uma fórmula não daria', () {
      expect(
        bragantinoClubConfig.passportContent.pt.levels.legend,
        'Lenda da Massa Bruta',
      );
    });

    test('forLevel cobre as 5 faixas sem repetir rótulo', () {
      for (final club in [goiasClubConfig, bragantinoClubConfig]) {
        final levels = club.passportContent.pt.levels;
        final rotulos = PassportLevel.values.map(levels.forLevel).toList();
        expect(rotulos, hasLength(PassportLevel.values.length));
        expect(rotulos.toSet(), hasLength(PassportLevel.values.length));
      }
    });
  });

  group('a tela resolve pelo clube ativo e pelo idioma', () {
    testWidgets('Goiás em pt/en/es', (tester) async {
      expect(
        (await _copyOnScreen(
          tester,
          goiasClubConfig,
          const Locale('pt'),
        )).cardDescription,
        'Marque os jogos que você viveu com o Verdão.',
      );
      expect(
        (await _copyOnScreen(
          tester,
          goiasClubConfig,
          const Locale('en'),
        )).cardDescription,
        'Mark the matches you lived with Goiás.',
      );
      expect(
        (await _copyOnScreen(
          tester,
          goiasClubConfig,
          const Locale('es'),
        )).cardDescription,
        'Marca los partidos que viviste con el Goiás.',
      );
    });

    testWidgets('Bragantino em pt/en/es', (tester) async {
      expect(
        (await _copyOnScreen(
          tester,
          bragantinoClubConfig,
          const Locale('pt'),
        )).title,
        'Passaporte Massa Bruta',
      );
      expect(
        (await _copyOnScreen(
          tester,
          bragantinoClubConfig,
          const Locale('en'),
        )).shareText,
        'This is my journey with Massa Bruta! 🔴⚪',
      );
      expect(
        (await _copyOnScreen(
          tester,
          bragantinoClubConfig,
          const Locale('es'),
        )).shareText,
        '¡Esta es mi trayectoria con el Massa Bruta! 🔴⚪',
      );
    });

    testWidgets('o compartilhamento segue o clube ativo, não o build', (
      tester,
    ) async {
      final goias = await _copyOnScreen(
        tester,
        goiasClubConfig,
        const Locale('pt'),
      );
      final braga = await _copyOnScreen(
        tester,
        bragantinoClubConfig,
        const Locale('pt'),
      );
      expect(goias.shareText, isNot(braga.shareText));
      expect(braga.shareText, contains('Massa Bruta'));
      expect(goias.shareText, contains('Goiás'));
    });

    testWidgets('idioma não suportado cai no português, não em outro clube', (
      tester,
    ) async {
      final copy = await _copyOnScreen(
        tester,
        bragantinoClubConfig,
        const Locale('pt'),
      );
      expect(
        bragantinoClubConfig.passportContent.forLanguageCode('fr').title,
        copy.title,
      );
    });
  });
}

/// Referência direta à cópia do Goiás, só pra encurtar as asserções acima.
class GoiasContentUnderTest {
  const GoiasContentUnderTest._();
  static PassportCopy get pt => goiasClubConfig.passportContent.pt;
}

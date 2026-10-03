import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Travas de identidade dos ídolos históricos (auditoria de 2026-10-01):
/// nomes parecidos nunca são fundidos e identidade sem prova nunca vira
/// certeza.
void main() {
  final braga = bragantinoClubConfig.institutionalContent.idols;
  final vila = vilaNovaClubConfig.institutionalContent.idols;
  final goias = goiasClubConfig.institutionalContent.idols;
  ClubIdol byName(List<ClubIdol> idols, String name) =>
      idols.firstWhere((i) => i.name == name);

  group('Bragantino', () {
    test('Nivaldo de 1965 é distinto do goleiro Nivaldo Penafiel', () {
      final nivaldo = byName(braga, 'Nivaldo "Queixo-de-mula"');
      expect(nivaldo.position, isNot('Goleiro'));
      expect(nivaldo.period, startsWith('1965'));
      expect(braga.where((i) => i.name.contains('Penafiel')), isEmpty);
    });

    test('o Marcelo da geração 1989–1992 é o Marcelo Martelotte, nunca o '
        'técnico Marcelo Veiga', () {
      final marcelo = byName(braga, 'Marcelo Martelotte');
      expect(marcelo.position, 'Goleiro');
      expect(braga.where((i) => i.name == 'Marcelo'), isEmpty);
      expect(braga.where((i) => i.name.contains('Veiga')), isEmpty);
    });

    test('Carlos Alberto Seixas não é tratado como passagem confirmada', () {
      expect(braga.where((i) => i.name.contains('Seixas')), isEmpty);
    });

    test('Alberto Félix sem a frase "maior craque" como fato', () {
      final alberto = byName(braga, 'Alberto Félix');
      expect(
        alberto.description.toLowerCase(),
        isNot(contains('maior craque')),
      );
    });
  });

  group('Goiás', () {
    test(
      'Josué não volta a ser "revelado pelo Goiás" (formador: Porto de Caruaru)',
      () {
        final josue = byName(goias, 'Josué');
        expect(josue.description, isNot(contains('revelado pelo Goiás')));
        expect(josue.description, contains('Porto'));
      },
    );

    test(
      'Cacau: atacante revelado pelo Goiás, 105 jogos e 18 gols (matéria oficial)',
      () {
        final cacau = byName(goias, 'Cacau');
        expect(cacau.position, 'Atacante');
        expect(cacau.description, contains('revelado pelo Goiás'));
        expect(cacau.matches, 105);
        expect(cacau.goals, 18);
      },
    );

    test(
      'Marquinhos é o lateral-esquerdo Marcos José Franklin Macena de Melo, 1997-2002',
      () {
        final marquinhos = byName(goias, 'Marquinhos');
        expect(marquinhos.fullName, 'Marcos José Franklin Macena de Melo');
        expect(marquinhos.position, 'Lateral-esquerdo');
        expect(marquinhos.period, '1997-2002');
        // Sem total de jogos/gols: nenhuma fonte do clube que feche.
        expect(marquinhos.matches, isNull);
        expect(marquinhos.goals, isNull);
      },
    );

    test('Araújo: maior artilheiro, 145 gols e 391 jogos (fonte oficial)', () {
      final araujo = byName(goias, 'Araújo');
      expect(
        araujo.description,
        contains('Maior artilheiro da história do Goiás'),
      );
      expect(araujo.goals, 145);
      expect(araujo.matches, 391);
    });

    test(
      'Dill: 135 gols (press kits 2026), sem total de jogos e sem "revelado"',
      () {
        final dill = byName(goias, 'Dill');
        expect(dill.goals, 135);
        expect(dill.matches, isNull);
        expect(dill.description.toLowerCase(), isNot(contains('revelado')));
        expect(dill.description, contains('Chegou ao Goiás em 1994'));
      },
    );

    test(
      'Ernando: 405 jogos (press kit oficial), gols sem fonte específica',
      () {
        final ernando = byName(goias, 'Ernando');
        expect(ernando.matches, 405);
        expect(ernando.goals, isNull);
      },
    );

    test('nenhum ídolo repete nome', () {
      final names = goias.map((i) => i.name).toList();
      expect(names.toSet(), hasLength(names.length));
    });
  });

  group('Vila Nova', () {
    test('Gibrair é da geração do fim dos anos 1950/anos 1960', () {
      final gibrair = byName(vila, 'Gibrair Caetano');
      expect(gibrair.period, startsWith('195'));
      expect(gibrair.period, isNot(contains('197')));
      expect(gibrair.period, isNot(contains('198')));
    });

    test(
      'Luciano só entra como Luciano Goiano (fonte própria: O Popular '
      'o chama de ídolo), nunca como "Luciano" solto nem Luciano Mineiro',
      () {
        final lucianos = vila.where((i) => i.name.contains('Luciano'));
        expect(lucianos.map((i) => i.name), ['Luciano Goiano']);
        expect(lucianos.single.description, contains('25 gols'));
      },
    );

    test('Moisés: os dois goleadores da Série C 2015 são Frontini (9) e '
        'Moisés (8), nunca um trio com Robston', () {
      final moises = byName(vila, 'Moisés');
      expect(moises.description, contains('8 gols'));
      expect(moises.description, contains('Frontini'));
      expect(moises.description, isNot(contains('Robston')));
    });
  });
}

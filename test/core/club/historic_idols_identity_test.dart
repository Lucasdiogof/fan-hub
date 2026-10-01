import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/vilanova_club_config.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Travas de identidade dos ídolos históricos (auditoria de 2026-10-01):
/// nomes parecidos nunca são fundidos e identidade sem prova nunca vira
/// certeza.
void main() {
  final braga = bragantinoClubConfig.institutionalContent.idols;
  final vila = vilaNovaClubConfig.institutionalContent.idols;
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

  group('Vila Nova', () {
    test('Gibrair é da geração do fim dos anos 1950/anos 1960', () {
      final gibrair = byName(vila, 'Gibrair Caetano');
      expect(gibrair.period, startsWith('195'));
      expect(gibrair.period, isNot(contains('197')));
      expect(gibrair.period, isNot(contains('198')));
    });

    test('Luciano não vira Luciano Goiano sem evidência', () {
      expect(vila.where((i) => i.name.contains('Luciano')), isEmpty);
    });

    test('Moisés: os dois goleadores da Série C 2015 são Frontini (9) e '
        'Moisés (8), nunca um trio com Robston', () {
      final moises = byName(vila, 'Moisés');
      expect(moises.description, contains('8 gols'));
      expect(moises.description, contains('Frontini'));
      expect(moises.description, isNot(contains('Robston')));
    });
  });
}

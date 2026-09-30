import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/passport/presentation/passport_display_format.dart';

void main() {
  group('shortCompetitionLabel', () {
    test('encurta Campeonato Brasileiro Série B para Série B', () {
      expect(
        shortCompetitionLabel('Campeonato Brasileiro Série B'),
        'Série B',
      );
    });

    test('encurta Campeonato Brasileiro Série A para Série A', () {
      expect(
        shortCompetitionLabel('Campeonato Brasileiro Série A'),
        'Série A',
      );
    });

    test('mantém competições sem prefixo Campeonato Brasileiro intactas', () {
      expect(shortCompetitionLabel('Campeonato Goiano'), 'Campeonato Goiano');
      expect(shortCompetitionLabel('Copa do Brasil'), 'Copa do Brasil');
      expect(shortCompetitionLabel('Copa Verde'), 'Copa Verde');
    });

    test(
      'mantém Campeonato Brasileiro sem letra de série intacto (ex.: base)',
      () {
        expect(
          shortCompetitionLabel('Campeonato Brasileiro Sub-20'),
          'Campeonato Brasileiro Sub-20',
        );
      },
    );
  });
}

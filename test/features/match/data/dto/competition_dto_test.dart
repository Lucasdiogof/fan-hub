import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/competition_dto.dart';

void main() {
  group('CompetitionDto', () {
    test('parses a real season number', () {
      final dto = CompetitionDto.fromJson({
        'name': 'Brasileirão Série B',
        'season': 2026,
      });
      expect(dto.name, 'Brasileirão Série B');
      expect(dto.season, 2026);
    });

    test(
      'season null does not throw — every football endpoint sends this since the OneFootball switch',
      () {
        final dto = CompetitionDto.fromJson({
          'name': 'Brasileirão Série B',
          'season': null,
        });
        expect(dto.season, isNull);
      },
    );

    test('toEntity carries a null season through unchanged', () {
      final entity = CompetitionDto.fromJson({
        'name': 'x',
        'season': null,
      }).toEntity();
      expect(entity.season, isNull);
    });
  });
}

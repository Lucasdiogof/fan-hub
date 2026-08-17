import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';

void main() {
  group('StandingDto', () {
    final json = {
      'position': 2,
      'team': {'id': 1, 'name': 'Goiás', 'logo': 'https://example.com/goias.png'},
      'points': 40,
      'played': 21,
      'wins': 11,
      'draws': 7,
      'losses': 3,
      'goalsFor': 30,
      'goalsAgainst': 18,
      'form': 'WWDLW',
    };

    test('parses from json correctly', () {
      final dto = StandingDto.fromJson(json);
      expect(dto.position, 2);
      expect(dto.team.id, 1);
      expect(dto.points, 40);
      expect(dto.form, 'WWDLW');
    });

    test('maps to domain entity with correct goal difference', () {
      final entity = StandingDto.fromJson(json).toEntity();
      expect(entity.position, 2);
      expect(entity.team.name, 'Goiás');
      expect(entity.goalDifference, 12);
    });

    test('form defaults to null when absent', () {
      final dto = StandingDto.fromJson({...json}..remove('form'));
      expect(dto.form, isNull);
    });
  });
}

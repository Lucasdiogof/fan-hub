import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';

void main() {
  group('StandingDto', () {
    final json = {
      'position': 2,
      'team': {'id': 1, 'name': 'Goiás', 'logo': 'https://example.com/goias.png'},
      'isGoias': true,
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
      expect(dto.isGoias, isTrue);
      expect(dto.points, 40);
      expect(dto.form, 'WWDLW');
    });

    test('maps to domain entity with correct goal difference and isGoias', () {
      final entity = StandingDto.fromJson(json).toEntity();
      expect(entity.position, 2);
      expect(entity.team.name, 'Goiás');
      expect(entity.isGoias, isTrue);
      expect(entity.goalDifference, 12);
    });

    test('form defaults to null when absent', () {
      final dto = StandingDto.fromJson({...json}..remove('form'));
      expect(dto.form, isNull);
    });

    test('isGoias defaults to false when absent — decided server-side, never guessed by name', () {
      final dto = StandingDto.fromJson({...json}..remove('isGoias'));
      expect(dto.isGoias, isFalse);
    });
  });
}

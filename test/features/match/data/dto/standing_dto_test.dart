import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/standing_dto.dart';

void main() {
  group('StandingDto', () {
    final json = {
      'position': 2,
      'team': {
        'id': 1,
        'name': 'Goiás',
        'logo': 'https://example.com/goias.png',
      },
      'points': 40,
      'played': 21,
      'wins': 11,
      'draws': 7,
      'losses': 3,
      'goalDifference': 12,
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

    // M3.3: "é o clube ativo?" não é mais decidido no servidor (era
    // `isGoias`, removido de StandingDto/Standing) — agora é sempre
    // `standing.team.matchesClub(clubConfig)`, calculado só no Flutter. A
    // prova de que o campo genuinamente não existe mais é o próprio tipo:
    // `StandingDto.fromJson`/`Standing` não aceitam mais `isGoias` como
    // parâmetro nomeado — `flutter analyze` já falha se alguém reintroduzir
    // isso sem atualizar todos os call sites (ver também
    // `test_multiclub_runtime_hardcodes.mjs`, checagem estática dedicada).
    test(
      'an extra unknown "isGoias" key in the source json is simply ignored, never resurrected as a field',
      () {
        final dto = StandingDto.fromJson({...json, 'isGoias': true});
        expect(dto.position, 2); // parseia normalmente, sem quebrar
      },
    );
  });
}

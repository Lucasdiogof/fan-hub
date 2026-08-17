import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

void main() {
  setUpAll(initializeBrazilTimeZone);

  group('MatchDto', () {
    final json = {
      'fixtureId': 12345,
      'round': '23ª Rodada',
      'homeTeam': {'id': 1, 'name': 'Goiás', 'logo': 'https://example.com/goias.png'},
      'awayTeam': {'id': 2, 'name': 'Coritiba', 'logo': 'https://example.com/coritiba.png'},
      'kickoff': '2026-08-21T21:30:00-03:00',
      'status': 'NS',
      'venue': {'name': 'Serrinha', 'city': 'Goiânia'},
      'homeScore': null,
      'awayScore': null,
    };

    test('parses from json correctly', () {
      final dto = MatchDto.fromJson(json);
      expect(dto.fixtureId, 12345);
      expect(dto.round, '23ª Rodada');
      expect(dto.homeTeam.name, 'Goiás');
      expect(dto.awayTeam.name, 'Coritiba');
      expect(dto.venueName, 'Serrinha');
      expect(dto.venueCity, 'Goiânia');
      expect(dto.statusCode, 'NS');
    });

    test('maps to domain entity with correct status and Brazil wall-clock time', () {
      final entity = MatchDto.fromJson(json).toEntity(competitionName: 'Brasileirão Série B');
      expect(entity.id, '12345');
      expect(entity.status, MatchStatus.scheduled);
      expect(entity.homeTeam.id, 1);
      expect(entity.awayTeam.id, 2);
      // O offset -03:00 no JSON já é o horário de Brasília — a entidade deve
      // preservar exatamente esses valores de parede, não reconverter pelo
      // fuso do dispositivo rodando o teste.
      expect(entity.kickoff.hour, 21);
      expect(entity.kickoff.minute, 30);
      expect(entity.kickoff.day, 21);
      expect(entity.kickoff.month, 8);
    });

    test('defaults missing venue/round/status gracefully', () {
      final dto = MatchDto.fromJson({
        'fixtureId': 1,
        'homeTeam': {'id': 1, 'name': 'Goiás'},
        'awayTeam': {'id': 2, 'name': 'Coritiba'},
        'kickoff': '2026-08-21T21:30:00-03:00',
      });
      expect(dto.round, '');
      expect(dto.statusCode, 'TBD');
      expect(dto.venueName, isNull);
      expect(dto.venueCity, isNull);
    });
  });
}

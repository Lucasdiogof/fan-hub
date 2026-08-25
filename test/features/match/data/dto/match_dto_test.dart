import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

void main() {
  group('MatchDto', () {
    final json = {
      'id': 'cbapi-12345',
      'round': '23a rodada',
      'homeTeam': {
        'id': 1,
        'name': 'Goiás',
        'logo': 'https://example.com/goias.png',
      },
      'awayTeam': {
        'id': 2,
        'name': 'Coritiba',
        'logo': 'https://example.com/coritiba.png',
      },
      'kickoff': '2026-08-21T21:30:00',
      'status': 'scheduled',
      'venue': 'Serrinha',
      'homeScore': null,
      'awayScore': null,
    };

    test('parses from json correctly', () {
      final dto = MatchDto.fromJson(json);
      expect(dto.id, 'cbapi-12345');
      expect(dto.round, '23a rodada');
      expect(dto.homeTeam.name, 'Goiás');
      expect(dto.awayTeam.name, 'Coritiba');
      expect(dto.venue, 'Serrinha');
      expect(dto.statusName, 'scheduled');
    });

    test('maps to domain entity preserving the raw wall-clock kickoff', () {
      final entity = MatchDto.fromJson(
        json,
      ).toEntity(competitionName: 'Brasileirão Série B');
      expect(entity.id, 'cbapi-12345');
      expect(entity.status, MatchStatus.scheduled);
      expect(entity.homeTeam.id, 1);
      expect(entity.awayTeam.id, 2);
      // O kickoff da fonte já é hora local do Brasil sem offset — a entidade
      // deve preservar exatamente esses valores de parede, sem reconverter
      // pelo fuso do dispositivo rodando o teste.
      expect(entity.kickoff!.hour, 21);
      expect(entity.kickoff!.minute, 30);
      expect(entity.kickoff!.day, 21);
      expect(entity.kickoff!.month, 8);
    });

    test(
      'kickoff missing from the source maps to a null kickoff, not a crash',
      () {
        final dto = MatchDto.fromJson({...json, 'kickoff': null});
        expect(dto.kickoffRaw, isNull);
        final entity = dto.toEntity(competitionName: 'Brasileirão Série B');
        expect(entity.kickoff, isNull);
      },
    );

    test('defaults missing venue/round/status gracefully', () {
      final dto = MatchDto.fromJson({
        'id': 'cbapi-1',
        'homeTeam': {'id': 1, 'name': 'Goiás'},
        'awayTeam': {'id': 2, 'name': 'Coritiba'},
        'kickoff': '2026-08-21T21:30:00',
      });
      expect(dto.round, '');
      expect(dto.statusName, 'unknown');
      expect(dto.venue, isNull);
    });

    test('unrecognized status name falls back to MatchStatus.unknown', () {
      final dto = MatchDto.fromJson({...json, 'status': 'something-new'});
      final entity = dto.toEntity(competitionName: 'Brasileirão Série B');
      expect(entity.status, MatchStatus.unknown);
    });
  });
}

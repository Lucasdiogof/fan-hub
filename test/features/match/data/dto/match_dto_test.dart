import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/match_dto.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

void main() {
  setUpAll(initializeBrazilTimeZone);

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

    test(
      'kickoff SEM timezone (convenção histórica do Worker) -> interpretado '
      'como America/Sao_Paulo, nunca como hora local do aparelho rodando o '
      'app (correção 2026-09-12)',
      () {
        final entity = MatchDto.fromJson(
          json,
        ).toEntity(competitionName: 'Brasileirão Série B');
        expect(entity.id, 'cbapi-12345');
        expect(entity.status, MatchStatus.scheduled);
        expect(entity.homeTeam.id, 1);
        expect(entity.awayTeam.id, 2);
        // O instante guardado é sempre UTC — só ao converter pra Brasília
        // (nunca `.toLocal()`) é que volta a bater com a hora de parede
        // original da fonte.
        expect(entity.kickoff!.isUtc, isTrue);
        final brazil = toBrazilTime(entity.kickoff!);
        expect(brazil.hour, 21);
        expect(brazil.minute, 30);
        expect(brazil.day, 21);
        expect(brazil.month, 8);
        // 21:30 em Brasília (UTC-3, sem horário de verão desde 2019) é
        // 00:30 UTC do dia seguinte — é ISSO que tem que estar no epoch
        // real, não 21:30 UTC.
        expect(entity.kickoff!.hour, 0);
        expect(entity.kickoff!.day, 22);
      },
    );

    test(
      'kickoff COM timezone explícito (ex.: pernas de mata-mata, sempre UTC '
      'real com "Z") -> respeitado como está, nunca desloca de novo por '
      '-03:00',
      () {
        final dto = MatchDto.fromJson({
          ...json,
          'kickoff': '2026-08-21T21:30:00Z',
        });
        final entity = dto.toEntity(competitionName: 'Brasileirão Série B');
        expect(entity.kickoff!.isUtc, isTrue);
        expect(entity.kickoff!.hour, 21);
        expect(entity.kickoff!.minute, 30);
        // Em Brasília isso é 18:30, não 21:30 — só bate com o valor cru
        // quando convertido de volta pro fuso do dispositivo (irrelevante
        // aqui), nunca igual à hora de parede do Brasil.
        expect(toBrazilTime(entity.kickoff!).hour, 18);
      },
    );

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

    test(
      'minute defaults to null when absent, carries through as-is when present',
      () {
        expect(MatchDto.fromJson(json).minute, isNull);
        final live = MatchDto.fromJson({...json, 'minute': "37'"});
        expect(live.minute, "37'");
        expect(
          live.toEntity(competitionName: 'Brasileirão Série B').minute,
          "37'",
        );
      },
    );
  });
}

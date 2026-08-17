import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/mappers/api_football_match_status_mapper.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

void main() {
  group('ApiFootballMatchStatusMapper', () {
    test('maps not-started codes to scheduled', () {
      expect(ApiFootballMatchStatusMapper.map('NS'), MatchStatus.scheduled);
      expect(ApiFootballMatchStatusMapper.map('TBD'), MatchStatus.scheduled);
    });

    test('maps in-play codes to live', () {
      expect(ApiFootballMatchStatusMapper.map('1H'), MatchStatus.live);
      expect(ApiFootballMatchStatusMapper.map('2H'), MatchStatus.live);
      expect(ApiFootballMatchStatusMapper.map('ET'), MatchStatus.live);
    });

    test('maps HT to halftime', () {
      expect(ApiFootballMatchStatusMapper.map('HT'), MatchStatus.halftime);
    });

    test('maps finished codes to finished', () {
      expect(ApiFootballMatchStatusMapper.map('FT'), MatchStatus.finished);
      expect(ApiFootballMatchStatusMapper.map('AET'), MatchStatus.finished);
      expect(ApiFootballMatchStatusMapper.map('PEN'), MatchStatus.finished);
    });

    test('maps PST to postponed and CANC to cancelled', () {
      expect(ApiFootballMatchStatusMapper.map('PST'), MatchStatus.postponed);
      expect(ApiFootballMatchStatusMapper.map('CANC'), MatchStatus.cancelled);
    });

    test('maps SUSP/ABD to suspended', () {
      expect(ApiFootballMatchStatusMapper.map('SUSP'), MatchStatus.suspended);
      expect(ApiFootballMatchStatusMapper.map('ABD'), MatchStatus.suspended);
    });

    test('falls back to unknown for unrecognized codes', () {
      expect(ApiFootballMatchStatusMapper.map('WEIRD_CODE'), MatchStatus.unknown);
    });
  });
}

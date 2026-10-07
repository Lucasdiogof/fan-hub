import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/match_event_dto.dart';

void main() {
  test('substituição com playerInId/playerOutId chega ao Flutter', () {
    final e = MatchEventDto.fromJson({
      'minute': "70'",
      'side': 'home',
      'type': 'substitution',
      'player': 'Tadeu',
      'detail': 'Outro',
      'playerInId': 48597,
      'playerOutId': 111,
    }).toEntity();
    expect(e.playerInId, 48597);
    expect(e.playerOutId, 111);
  });

  test('payload antigo (sem IDs) continua válido: IDs nulos', () {
    final e = MatchEventDto.fromJson({
      'minute': "70'",
      'side': 'home',
      'type': 'substitution',
      'player': 'Tadeu',
      'detail': 'Outro',
    }).toEntity();
    expect(e.playerInId, isNull);
    expect(e.playerOutId, isNull);
    expect(e.player, 'Tadeu');
  });
}

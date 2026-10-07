import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/data/dto/lineup_dto.dart';

void main() {
  group('LineupPlayerDto — ID do jogador no provedor', () {
    test('usa o playerId do Worker quando ele vem', () {
      final dto = LineupPlayerDto.fromJson({
        'name': 'Kadu Sousa',
        'jerseyNumber': 40,
        'photo': '',
        'playerId': 123456,
      });
      expect(dto.toEntity().providerPlayerId, 123456);
    });

    test(
      'payload NOVO com playerId não depende da foto (vazia ou de outro host)',
      () {
        for (final photo in ['', 'https://outro.com/qualquer.png', 'lixo']) {
          final dto = LineupPlayerDto.fromJson({
            'name': 'Tadeu',
            'jerseyNumber': 23,
            'photo': photo,
            'playerId': 48597,
          });
          expect(dto.toEntity().providerPlayerId, 48597, reason: photo);
        }
      },
    );

    test(
      'LEGACY FALLBACK — Worker antigo (sem playerId): recupera o ID da URL da foto',
      () {
        final dto = LineupPlayerDto.fromJson({
          'name': 'Tadeu',
          'jerseyNumber': 23,
          'photo': 'https://images.onefootball.com/players/180/48597.jpg',
        });
        expect(dto.toEntity().providerPlayerId, 48597);
      },
    );

    test('sem playerId e sem foto reconhecível: null (nunca chuta)', () {
      for (final photo in [
        '',
        'https://outro-host.com/players/180/48597.jpg',
        'https://images.onefootball.com/teams/180/48597.png',
        'https://images.onefootball.com/players/180/abc.jpg',
      ]) {
        final dto = LineupPlayerDto.fromJson({
          'name': 'X',
          'jerseyNumber': 1,
          'photo': photo,
        });
        expect(dto.toEntity().providerPlayerId, isNull, reason: photo);
      }
    });

    test('o playerId explícito vence o da foto', () {
      final dto = LineupPlayerDto.fromJson({
        'name': 'X',
        'jerseyNumber': 1,
        'photo': 'https://images.onefootball.com/players/180/111.jpg',
        'playerId': 222,
      });
      expect(dto.toEntity().providerPlayerId, 222);
    });
  });
}

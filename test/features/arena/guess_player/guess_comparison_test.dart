import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_comparison.dart';
import 'package:goias_app/shared/domain/player_position.dart';

void main() {
  group('comparePosition', () {
    test('mesma posição -> match', () {
      expect(
        comparePosition(PlayerPosition.ata, PlayerPosition.ata),
        MatchResult.match,
      );
    });

    test('posição diferente -> mismatch', () {
      expect(
        comparePosition(PlayerPosition.ata, PlayerPosition.zag),
        MatchResult.mismatch,
      );
    });

    test('dado ausente -> unknown', () {
      expect(comparePosition(null, PlayerPosition.ata), MatchResult.unknown);
      expect(comparePosition(PlayerPosition.ata, null), MatchResult.unknown);
      expect(comparePosition(null, null), MatchResult.unknown);
    });
  });

  group('compareShirtNumber', () {
    test('mesmo número -> match', () {
      expect(compareShirtNumber(23, 23), DirectionalResult.match);
    });

    test('palpite menor que o secreto -> higher (secreto é maior)', () {
      expect(compareShirtNumber(23, 10), DirectionalResult.higher);
    });

    test('palpite maior que o secreto -> lower (secreto é menor)', () {
      expect(compareShirtNumber(23, 40), DirectionalResult.lower);
    });

    test('dado ausente -> unknown', () {
      expect(compareShirtNumber(null, 10), DirectionalResult.unknown);
      expect(compareShirtNumber(23, null), DirectionalResult.unknown);
    });
  });

  group('compareAcademy', () {
    test('mesmo clube -> match', () {
      expect(compareAcademy('Goiás', 'Goiás'), MatchResult.match);
    });

    test('clube diferente -> mismatch', () {
      expect(compareAcademy('Goiás', 'Cruzeiro'), MatchResult.mismatch);
    });

    test('dado ausente -> unknown', () {
      expect(compareAcademy(null, 'Cruzeiro'), MatchResult.unknown);
      expect(compareAcademy('Goiás', null), MatchResult.unknown);
    });

    test('dois "Desconhecido" nunca contam como acerto', () {
      expect(compareAcademy(null, null), MatchResult.unknown);
    });

    test('string vazia ou só espaços vale como ausente', () {
      expect(compareAcademy('', 'Goiás'), MatchResult.unknown);
      expect(compareAcademy('Goiás', '   '), MatchResult.unknown);
    });
  });

  group('compareDebutYear', () {
    test('mesmo ano -> match', () {
      expect(compareDebutYear(2019, 2019), DirectionalResult.match);
    });

    test(
      'palpite estreou antes do secreto -> higher (secreto estreou depois)',
      () {
        expect(compareDebutYear(2019, 2014), DirectionalResult.higher);
      },
    );

    test(
      'palpite estreou depois do secreto -> lower (secreto estreou antes)',
      () {
        expect(compareDebutYear(2019, 2022), DirectionalResult.lower);
      },
    );

    test('dado ausente -> unknown', () {
      expect(compareDebutYear(null, 2019), DirectionalResult.unknown);
      expect(compareDebutYear(2019, null), DirectionalResult.unknown);
    });
  });
}

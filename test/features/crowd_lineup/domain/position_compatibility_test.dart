import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/crowd_lineup/domain/position_compatibility.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';
import 'package:goias_app/shared/domain/player_position.dart';

SquadPlayer _player(List<PlayerPosition> positions) => SquadPlayer(
  id: 'p',
  personId: 'p-person-id',
  name: 'Player',
  shirtNumber: 10,
  allowedPositions: positions,
);

void main() {
  const service = PositionCompatibilityService();

  group('exact matches', () {
    test('primary position filling its own slot is exactPrimary', () {
      final player = _player([PlayerPosition.ata]);
      expect(
        service.fitFor(player, PlayerPosition.ata),
        PositionFit.exactPrimary,
      );
      expect(service.scoreFor(player, PlayerPosition.ata), 100);
    });

    test('a listed secondary position is exactSecondary, not natural', () {
      final player = _player([PlayerPosition.ld, PlayerPosition.ald]);
      expect(
        service.fitFor(player, PlayerPosition.ald),
        PositionFit.exactSecondary,
      );
      expect(service.scoreFor(player, PlayerPosition.ald), 90);
    });

    test('an explicit secondary position outranks a natural adaptation', () {
      // Cadu tem ambos: PD é secundária explícita (índice > 0) e também
      // seria uma adaptação natural pra MD via allowedPositions — a
      // secundária explícita tem que vencer.
      final player = _player([PlayerPosition.ata, PlayerPosition.pd]);
      final fit = service.fitFor(player, PlayerPosition.pd);
      expect(fit, PositionFit.exactSecondary);
      expect(service.scoreFor(player, PlayerPosition.pd), 90);
    });
  });

  group('natural adaptations from the spec', () {
    test('ATA filling SA is natural', () {
      final player = _player([PlayerPosition.ata]);
      expect(service.fitFor(player, PlayerPosition.sa), PositionFit.natural);
    });

    test('PD filling MD is natural, scored 80', () {
      final player = _player([PlayerPosition.pd]);
      expect(service.fitFor(player, PlayerPosition.md), PositionFit.natural);
      expect(service.scoreFor(player, PlayerPosition.md), 80);
    });

    test('MD filling PD is natural but scored lower than the reverse (70)', () {
      final player = _player([PlayerPosition.md]);
      expect(service.fitFor(player, PlayerPosition.pd), PositionFit.natural);
      expect(service.scoreFor(player, PlayerPosition.pd), 70);
    });

    test('PE filling ME is natural', () {
      final player = _player([PlayerPosition.pe]);
      expect(service.fitFor(player, PlayerPosition.me), PositionFit.natural);
    });

    test('MC filling VOL is natural', () {
      final player = _player([PlayerPosition.mc]);
      expect(service.fitFor(player, PlayerPosition.vol), PositionFit.natural);
    });

    test('VOL filling MC is natural', () {
      final player = _player([PlayerPosition.vol]);
      expect(service.fitFor(player, PlayerPosition.mc), PositionFit.natural);
    });

    test('LD filling ALD is natural', () {
      final player = _player([PlayerPosition.ld]);
      expect(service.fitFor(player, PlayerPosition.ald), PositionFit.natural);
    });

    test('LE filling ALE is natural', () {
      final player = _player([PlayerPosition.le]);
      expect(service.fitFor(player, PlayerPosition.ale), PositionFit.natural);
    });

    test('the pair is asymmetric: LD-as-ALD outscores ALD-as-LD', () {
      final ld = _player([PlayerPosition.ld]);
      final ald = _player([PlayerPosition.ald]);
      final ldAsAld = service.scoreFor(ld, PlayerPosition.ald)!;
      final aldAsLd = service.scoreFor(ald, PlayerPosition.ld)!;
      expect(ldAsAld, greaterThan(aldAsLd));
    });
  });

  group('incompatibilities from the spec', () {
    test('a goalkeeper can never fill ATA', () {
      final player = _player([PlayerPosition.gol]);
      expect(
        service.fitFor(player, PlayerPosition.ata),
        PositionFit.incompatible,
      );
      expect(service.scoreFor(player, PlayerPosition.ata), isNull);
    });

    test('a centre-back does not automatically fill PD', () {
      final player = _player([PlayerPosition.zag]);
      expect(
        service.fitFor(player, PlayerPosition.pd),
        PositionFit.incompatible,
      );
    });

    test('a forward does not automatically fill VOL', () {
      final player = _player([PlayerPosition.ata]);
      expect(
        service.fitFor(player, PlayerPosition.vol),
        PositionFit.incompatible,
      );
    });

    test('an explicit secondary position overrides the incompatibility', () {
      // Se VOL estiver mesmo cadastrado como secundária do atacante, deixa
      // de ser um "auto-infer" e vira um encaixe exato legítimo.
      final player = _player([PlayerPosition.ata, PlayerPosition.vol]);
      expect(
        service.fitFor(player, PlayerPosition.vol),
        PositionFit.exactSecondary,
      );
    });
  });
}

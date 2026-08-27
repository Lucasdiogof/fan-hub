import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_logic.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_models.dart';

void main() {
  const goalLeft = 100.0;
  const goalWidth = 200.0;

  group('resolvePenalty', () {
    test('gol quando o goleiro escolhe a zona errada', () {
      final result = resolvePenalty(
        targetX: 270,
        goalLeft: goalLeft,
        goalWidth: goalWidth,
        keeperZone: ShotZone.left,
      );
      expect(result, PenaltyResult.goal);
    });

    test('defesa quando o goleiro acerta a zona', () {
      final result = resolvePenalty(
        targetX: 270,
        goalLeft: goalLeft,
        goalWidth: goalWidth,
        keeperZone: ShotZone.right,
      );
      expect(result, PenaltyResult.save);
    });

    test('fora quando passa dos postes', () {
      final result = resolvePenalty(
        targetX: 340,
        goalLeft: goalLeft,
        goalWidth: goalWidth,
        keeperZone: ShotZone.center,
      );
      expect(result, PenaltyResult.out);
    });

    test('trave quando bate bem perto do poste', () {
      final result = resolvePenalty(
        targetX: 296,
        goalLeft: goalLeft,
        goalWidth: goalWidth,
        keeperZone: ShotZone.left,
      );
      expect(result, PenaltyResult.post);
    });
  });

  group('ballZoneForTarget', () {
    test('divide o gol em três zonas', () {
      expect(ballZoneForTarget(120, goalLeft, goalWidth), ShotZone.left);
      expect(ballZoneForTarget(200, goalLeft, goalWidth), ShotZone.center);
      expect(ballZoneForTarget(280, goalLeft, goalWidth), ShotZone.right);
    });
  });

  group('penaltyScore', () {
    test('vale 200 pontos por gol', () {
      expect(penaltyScore(0), 0);
      expect(penaltyScore(4), 800);
      expect(penaltyScore(5), 1000);
    });
  });
}

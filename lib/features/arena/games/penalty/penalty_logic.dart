import 'package:goias_app/features/arena/games/penalty/penalty_models.dart';

const penaltyTotalAttempts = 5;
const penaltyPointsPerGoal = 200;

int penaltyScore(int goals) => goals * penaltyPointsPerGoal;

ShotZone ballZoneForTarget(double targetX, double goalLeft, double goalWidth) {
  final rel = ((targetX - goalLeft) / goalWidth).clamp(0.0, 1.0);
  if (rel < 0.34) return ShotZone.left;
  if (rel < 0.66) return ShotZone.center;
  return ShotZone.right;
}

PenaltyResult resolvePenalty({
  required double targetX,
  required double goalLeft,
  required double goalWidth,
  required ShotZone keeperZone,
}) {
  final goalRight = goalLeft + goalWidth;
  final postTol = goalWidth * 0.045;
  if (targetX < goalLeft - postTol || targetX > goalRight + postTol) {
    return PenaltyResult.out;
  }
  if ((targetX - goalLeft).abs() < postTol || (targetX - goalRight).abs() < postTol) {
    return PenaltyResult.post;
  }
  final ballZone = ballZoneForTarget(targetX, goalLeft, goalWidth);
  return ballZone == keeperZone ? PenaltyResult.save : PenaltyResult.goal;
}

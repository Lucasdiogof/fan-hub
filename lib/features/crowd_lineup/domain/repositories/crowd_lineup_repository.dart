import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';

abstract interface class CrowdLineupRepository {
  Future<Result<LineupVote?>> getMyVote(String matchId);

  Future<Result<void>> submitVote(String matchId, LineupVote vote);

  Future<Result<CrowdLineup>> getCrowdLineup(String matchId);
}

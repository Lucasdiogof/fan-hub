import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

abstract class MatchRepository {
  Future<Result<Match?>> getNextMatch();

  Future<Result<List<Match>>> getUpcomingMatches();

  Future<Result<Match>> getMatchById(String id);
}

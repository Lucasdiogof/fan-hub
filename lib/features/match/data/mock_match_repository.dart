import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/repositories/match_repository.dart';

class MockMatchRepository implements MatchRepository {
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Result<Match?>> getNextMatch() async {
    await Future<void>.delayed(_latency);
    final upcoming = MockData.matches.where((m) => m.status == MatchStatus.scheduled).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    return Success(upcoming.isEmpty ? null : upcoming.first);
  }

  @override
  Future<Result<List<Match>>> getUpcomingMatches() async {
    await Future<void>.delayed(_latency);
    final upcoming = MockData.matches.where((m) => m.status == MatchStatus.scheduled).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    return Success(upcoming);
  }

  @override
  Future<Result<Match>> getMatchById(String id) async {
    await Future<void>.delayed(_latency);
    for (final match in MockData.matches) {
      if (match.id == id) return Success(match);
    }
    return const Error(UnexpectedFailure('Jogo não encontrado.'));
  }
}

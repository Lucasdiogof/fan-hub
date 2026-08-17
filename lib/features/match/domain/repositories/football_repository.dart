import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';

/// Dados esportivos reais (API-Football via nosso backend) — Brasileirão
/// Série B / Goiás. Ingresso e Sócio continuam mockados em outras features;
/// esse repositório não sabe nada sobre venda de ingresso ou check-in.
abstract interface class FootballRepository {
  Future<Result<List<Match>>> getMatches();

  Future<Result<List<Match>>> getUpcomingMatches();

  Future<Result<List<Match>>> getResults();

  Future<Result<List<Standing>>> getStandings();

  Future<Result<Match>> getMatchDetails(int fixtureId);
}

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';

abstract interface class PassportRepository {
  Future<Result<List<PassportSeason>>> getSeasons();
  Future<Result<List<PassportMatch>>> getMatchesForYear(int year);
  Future<Result<PassportSummary>> getSummary();

  Future<Result<PassportAttendanceBreakdown>> getAttendanceBreakdown();

  Future<Result<PassportStadiumSummary>> getStadiumSummary();

  /// Todas as partidas marcadas como "Eu fui", de qualquer temporada — fonte
  /// do seletor de jogo memorável e da resolução do jogo já escolhido.
  Future<Result<List<PassportMatch>>> getAttendedMatches();

  /// `null` = usuário ainda não escolheu nenhum jogo memorável.
  Future<Result<String?>> getMemorableMatchId();

  /// O servidor rejeita se [matchId] não for uma partida marcada como
  /// "Eu fui" pelo usuário atual (ver `passport_set_memorable_match`).
  Future<Result<void>> setMemorableMatch(String matchId);

  /// Envia só o delta (nunca as 1.697 partidas) — uma chamada transacional
  /// pra N marcações/desmarcações. O servidor é quem decide se cada uma foi
  /// aplicada (ver `PassportAttendanceChangeResult`).
  Future<Result<List<PassportAttendanceChangeResult>>> saveAttendances(
    List<PassportAttendanceChange> changes,
  );

  Future<Result<List<PassportRankingEntry>>> getRanking({
    int? year,
    int limit = 50,
  });

  Future<Result<({int rank, int matchCount})?>> getMyRank({int? year});
}

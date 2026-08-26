import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';

abstract class ArenaRankingRepository {
  /// Chamada uma vez por conclusão de conteúdo pontuável (resposta certa do
  /// quiz, rodada terminada do Adivinhe o Jogador/Quem Vestiu o Manto,
  /// escalação concluída ou desistida). A regra de quanto isso vale mora no
  /// servidor (`arena_record_score`) — aqui só se manda o que aconteceu.
  Future<Result<ScoreResult>> recordScore({
    required String gameId,
    required String itemId,
    required String eventType,
    int? attemptNumber,
    String? difficulty,
    int? wrongCount,
    int? foundCount,
    int? totalCount,
    bool wasRevealed = false,
    bool wasAbandoned = false,
  });

  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  });

  /// `null` quando o usuário ainda não pontuou nada nesse período.
  Future<Result<({int rank, int totalScore})?>> getMyRank(RankingPeriod period);

  /// [context] é a linha já conhecida (nome/avatar/pontuação/posição) de
  /// quem foi tocado no ranking — a RPC só devolve a distribuição por jogo,
  /// não repete os dados que a lista já tinha.
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context);
}

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';

/// Dados esportivos reais (fontes gratuitas via nosso backend) — Brasileirão
/// Série B / Goiás. Ingresso e Sócio continuam mockados em outras features;
/// esse repositório não sabe nada sobre venda de ingresso ou check-in.
///
/// Não existe "calendário completo" nas fontes gratuitas disponíveis — só
/// classificação completa, a rodada atual (todos os times) e um snapshot
/// do Goiás (próximo jogo + últimos resultados). Por isso não há
/// `getUpcomingMatches()`/`getResults()` genéricos: a UI trabalha com o que
/// realmente existe.
abstract interface class FootballRepository {
  Future<Result<List<Standing>>> getStandings();

  /// Todos os jogos de uma rodada do campeonato (não só do Goiás).
  /// [offset] é relativo à rodada atual (0) — negativo pra rodadas
  /// anteriores, positivo pras seguintes (deve ser raro/inexistente, já
  /// que o campeonato só define os confrontos rodada a rodada).
  Future<
    Result<
      ({
        List<Match> matches,
        String? roundLabel,
        bool hasPrevious,
        bool hasNext,
      })
    >
  >
  getCurrentRound({int offset = 0});

  /// Próximo jogo do Goiás (se houver dado confiável) + últimos resultados.
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getGoiasSnapshot();

  Future<
    Result<({Match match, List<MatchEvent> events, MatchLineups? lineups})>
  >
  getMatchDetails(String fixtureId);
}

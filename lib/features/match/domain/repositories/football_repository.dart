import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';

/// Dados esportivos reais (fontes gratuitas via nosso backend) — Brasileirão
/// Série B / Goiás. Ingresso e Sócio continuam mockados em outras features;
/// esse repositório não sabe nada sobre venda de ingresso ou check-in.
///
/// Não existe "calendário completo do campeonato" nas fontes gratuitas
/// disponíveis — só classificação completa e a rodada atual (todos os
/// times). Por isso não há `getUpcomingMatches()`/`getResults()` genéricos
/// pra qualquer time. `getSeasonFixtures()` é a exceção: dá pra montar a
/// temporada inteira APENAS do Goiás (todas as competições que ele disputa
/// juntas), porque a fonte pagina por time, não por campeonato.
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

  /// Todos os jogos do Goiás na temporada atual, de qualquer competição
  /// (Goianão, Brasileirão Série B, Copa do Brasil...), ordenados por
  /// kickoff — fonte do Calendário de Jogos. Nunca traz estádio (custaria
  /// uma chamada extra por partida pra ~50 partidas de uma vez); quem
  /// precisar do estádio de uma partida específica usa `getMatchDetails`.
  Future<Result<List<Match>>> getSeasonFixtures();

  Future<
    Result<
      ({
        Match match,
        List<MatchEvent> events,
        MatchLineups? lineups,
        List<MatchStat> stats,
      })
    >
  >
  getMatchDetails(String fixtureId);
}

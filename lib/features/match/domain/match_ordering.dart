import 'package:goias_app/features/match/domain/entities/match.dart';

const _openStatuses = {MatchStatus.scheduled, MatchStatus.live, MatchStatus.halftime};

/// Regras de seleção/ordenação de partidas — isoladas da UI e do repositório
/// pra serem testáveis sem mock de rede. Não há mais "calendário completo"
/// pra agrupar por mês: as fontes gratuitas só dão rodada atual e um
/// snapshot do Goiás (próximo jogo + últimos resultados).
class MatchOrdering {
  const MatchOrdering._();

  /// Nunca confia cegamente no status vindo do provedor pra decidir se uma
  /// partida ainda é "próxima" — sempre passa por aqui antes de exibir.
  static bool isOpen(Match match) => _openStatuses.contains(match.status);

  /// Ordem cronológica ascendente — nunca confia na ordem que o provedor
  /// devolveu. Partidas sem horário confirmado (`kickoff == null`) vão pro
  /// final, não pro início.
  static List<Match> chronological(List<Match> matches) {
    final sorted = [...matches]..sort((a, b) {
      final kickoffA = a.kickoff;
      final kickoffB = b.kickoff;
      if (kickoffA == null && kickoffB == null) return 0;
      if (kickoffA == null) return 1;
      if (kickoffB == null) return -1;
      return kickoffA.compareTo(kickoffB);
    });
    return sorted;
  }
}

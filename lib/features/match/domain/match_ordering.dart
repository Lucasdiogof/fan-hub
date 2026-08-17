import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/date_labels.dart';

const _openStatuses = {MatchStatus.scheduled, MatchStatus.live, MatchStatus.halftime};

/// Regras de seleção/ordenação de partidas — isoladas da UI e do repositório
/// pra serem testáveis sem mock de rede.
class MatchOrdering {
  const MatchOrdering._();

  /// Primeira partida futura (ou em andamento) válida — nunca `matches.first`
  /// sem checar status/data.
  static Match? nextMatch(List<Match> matches) {
    final valid = upcoming(matches);
    return valid.isEmpty ? null : valid.first;
  }

  /// Partidas ainda não encerradas, da mais próxima para a mais distante.
  static List<Match> upcoming(List<Match> matches) {
    final valid = matches.where((m) => _openStatuses.contains(m.status)).toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    return valid;
  }

  /// Partidas encerradas, da mais recente para a mais antiga.
  static List<Match> results(List<Match> matches) {
    final valid = matches.where((m) => m.status == MatchStatus.finished).toList()
      ..sort((a, b) => b.kickoff.compareTo(a.kickoff));
    return valid;
  }

  /// Agrupa por mês (derivado de `kickoff`, nunca hardcoded), preservando a
  /// ordem de entrada — passe uma lista já ordenada.
  static Map<String, List<Match>> groupByMonth(List<Match> matches) {
    final groups = <String, List<Match>>{};
    for (final match in matches) {
      final key = monthLabel(match.kickoff);
      groups.putIfAbsent(key, () => []).add(match);
    }
    return groups;
  }
}

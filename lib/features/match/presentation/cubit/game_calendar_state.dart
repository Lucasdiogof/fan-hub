import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/calendar_competition_filter.dart';
import 'package:goias_app/features/match/domain/calendar_month_grid.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

class GameCalendarState extends Equatable {
  GameCalendarState({
    this.status = LoadStatus.initial,
    this.allMatches = const [],
    DateTime? selectedMonth,
    this.competitionFilter = CalendarCompetitionFilter.all,
    this.errorMessage,
  }) : selectedMonth = selectedMonth ?? startOfMonth(DateTime.now());

  final LoadStatus status;
  final List<Match> allMatches;
  final DateTime selectedMonth;
  final CalendarCompetitionFilter competitionFilter;
  final String? errorMessage;

  List<Match> get filteredMatches => allMatches
      .where(
        (match) =>
            matchesCompetitionFilter(competitionFilter, match.competition),
      )
      .toList(growable: false);

  /// Só partidas do mês selecionado, agrupadas por dia — partidas sem
  /// `kickoff` confirmado nunca aparecem aqui (não há onde posicioná-las na
  /// grade).
  Map<int, List<Match>> get matchesByDayInSelectedMonth {
    final map = <int, List<Match>>{};
    for (final match in filteredMatches) {
      final kickoffRaw = match.kickoff;
      if (kickoffRaw == null) continue;
      // `toBrazilTime`, nunca `.toLocal()`: o calendário é o calendário do
      // Brasil (spec 2026-09-12) — um jogo às 22h de Brasília nunca pode
      // cair no dia seguinte só porque o aparelho está em outro fuso.
      final kickoff = toBrazilTime(kickoffRaw);
      if (kickoff.year != selectedMonth.year ||
          kickoff.month != selectedMonth.month) {
        continue;
      }
      map.putIfAbsent(kickoff.day, () => []).add(match);
    }
    return map;
  }

  GameCalendarState copyWith({
    LoadStatus? status,
    List<Match>? allMatches,
    DateTime? selectedMonth,
    CalendarCompetitionFilter? competitionFilter,
    String? errorMessage,
  }) {
    return GameCalendarState(
      status: status ?? this.status,
      allMatches: allMatches ?? this.allMatches,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      competitionFilter: competitionFilter ?? this.competitionFilter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allMatches,
    selectedMonth,
    competitionFilter,
    errorMessage,
  ];
}

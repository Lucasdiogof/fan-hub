import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/calendar_competition_filter.dart';
import 'package:goias_app/features/match/domain/calendar_month_grid.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/game_calendar_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Busca a temporada UMA vez (`load`) e resolve navegação de mês/filtro só
/// em memória — nunca refaz request ao trocar de mês ou de filtro (ver
/// `GameCalendarState.matchesByDayInSelectedMonth`/`filteredMatches`).
class GameCalendarCubit extends Cubit<GameCalendarState> {
  GameCalendarCubit(this._repository) : super(GameCalendarState());

  final FootballRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getSeasonFixtures();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            allMatches: data,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: failure.message,
          ),
        );
    }
  }

  void previousMonth() =>
      emit(state.copyWith(selectedMonth: addMonths(state.selectedMonth, -1)));

  void nextMonth() =>
      emit(state.copyWith(selectedMonth: addMonths(state.selectedMonth, 1)));

  /// Pula direto pra um mês — usado pelo seletor de temporada (quando
  /// houver mais de uma) e por testes que precisam de um mês conhecido,
  /// já que o inicial é sempre relativo a `DateTime.now()`.
  void jumpToMonth(DateTime month) =>
      emit(state.copyWith(selectedMonth: startOfMonth(month)));

  void setCompetitionFilter(CalendarCompetitionFilter filter) =>
      emit(state.copyWith(competitionFilter: filter));
}

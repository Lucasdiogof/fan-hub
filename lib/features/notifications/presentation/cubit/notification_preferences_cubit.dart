import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:goias_app/features/notifications/presentation/cubit/notification_preferences_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit(this._repository)
    : super(const NotificationPreferencesState());

  final NotificationRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getPreferences();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: LoadStatus.success, preferences: data));
      case Error():
        emit(state.copyWith(status: LoadStatus.error));
    }
  }

  Future<void> setMatchesEnabled(bool value) async {
    final previous = state.preferences;
    emit(
      state.copyWith(
        preferences: previous.copyWith(matchesEnabled: value),
        saving: true,
      ),
    );
    final result = await _repository.updatePreferences(matchesEnabled: value);
    if (result is Error) emit(state.copyWith(preferences: previous));
    emit(state.copyWith(saving: false));
  }

  Future<void> setTicketsEnabled(bool value) async {
    final previous = state.preferences;
    emit(
      state.copyWith(
        preferences: previous.copyWith(ticketsEnabled: value),
        saving: true,
      ),
    );
    final result = await _repository.updatePreferences(ticketsEnabled: value);
    if (result is Error) emit(state.copyWith(preferences: previous));
    emit(state.copyWith(saving: false));
  }
}

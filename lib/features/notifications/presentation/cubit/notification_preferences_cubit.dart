import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/notifications/domain/entities/notification_preferences.dart';
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

  Future<void> _update(
    NotificationPreferences Function(NotificationPreferences previous) apply,
    Future<Result<void>> Function() persist,
  ) async {
    final previous = state.preferences;
    emit(state.copyWith(preferences: apply(previous), saving: true));
    final result = await persist();
    if (result is Error) emit(state.copyWith(preferences: previous));
    emit(state.copyWith(saving: false));
  }

  Future<void> setLiveMatchesEnabled(bool value) => _update(
    (p) => p.copyWith(liveMatchesEnabled: value),
    () => _repository.updatePreferences(liveMatchesEnabled: value),
  );

  Future<void> setKickoffEnabled(bool value) => _update(
    (p) => p.copyWith(kickoffEnabled: value),
    () => _repository.updatePreferences(kickoffEnabled: value),
  );

  Future<void> setGoalForEnabled(bool value) => _update(
    (p) => p.copyWith(goalForEnabled: value),
    () => _repository.updatePreferences(goalForEnabled: value),
  );

  Future<void> setGoalAgainstEnabled(bool value) => _update(
    (p) => p.copyWith(goalAgainstEnabled: value),
    () => _repository.updatePreferences(goalAgainstEnabled: value),
  );

  Future<void> setHalfTimeEnabled(bool value) => _update(
    (p) => p.copyWith(halfTimeEnabled: value),
    () => _repository.updatePreferences(halfTimeEnabled: value),
  );

  Future<void> setSecondHalfStartedEnabled(bool value) => _update(
    (p) => p.copyWith(secondHalfStartedEnabled: value),
    () => _repository.updatePreferences(secondHalfStartedEnabled: value),
  );

  Future<void> setFullTimeEnabled(bool value) => _update(
    (p) => p.copyWith(fullTimeEnabled: value),
    () => _repository.updatePreferences(fullTimeEnabled: value),
  );

  Future<void> setTicketsEnabled(bool value) => _update(
    (p) => p.copyWith(ticketsEnabled: value),
    () => _repository.updatePreferences(ticketsEnabled: value),
  );
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:goias_app/shared/state/load_status.dart';

class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.status = LoadStatus.initial,
    this.preferences = const NotificationPreferences(),
    this.saving = false,
  });

  final LoadStatus status;
  final NotificationPreferences preferences;
  final bool saving;

  NotificationPreferencesState copyWith({
    LoadStatus? status,
    NotificationPreferences? preferences,
    bool? saving,
  }) {
    return NotificationPreferencesState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [status, preferences, saving];
}

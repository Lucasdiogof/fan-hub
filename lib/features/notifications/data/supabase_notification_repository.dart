import 'dart:async';

import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:goias_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _genericErrorMessage =
    'Não foi possível concluir agora. Tente novamente.';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Result<void>> registerToken({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _client.from('user_notification_tokens').upsert({
        'user_id': _uid,
        'fcm_token': fcmToken,
        'platform': platform,
        'is_active': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'fcm_token');
      return const Success(null);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<void>> deactivateToken(String fcmToken) async {
    try {
      await _client
          .from('user_notification_tokens')
          .update({'is_active': false})
          .eq('fcm_token', fcmToken)
          .eq('user_id', _uid);
      return const Success(null);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<NotificationPreferences>> getPreferences() async {
    try {
      final row = await _client
          .from('user_notification_preferences')
          .select('matches_enabled, tickets_enabled')
          .eq('user_id', _uid)
          .maybeSingle();
      if (row == null) return const Success(NotificationPreferences());
      return Success(
        NotificationPreferences(
          matchesEnabled: row['matches_enabled'] as bool,
          ticketsEnabled: row['tickets_enabled'] as bool,
        ),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }

  @override
  Future<Result<void>> updatePreferences({
    bool? matchesEnabled,
    bool? ticketsEnabled,
  }) async {
    try {
      await _client.from('user_notification_preferences').upsert({
        'user_id': _uid,
        'matches_enabled': ?matchesEnabled,
        'tickets_enabled': ?ticketsEnabled,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      return const Success(null);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }
}

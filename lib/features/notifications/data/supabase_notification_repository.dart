import 'dart:async';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:goias_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _genericErrorMessage =
    'Não foi possível concluir agora. Tente novamente.';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  // `user_notification_tokens` fica GLOBAL de propósito — o token FCM é do
  // aparelho, não do clube (§25 do pedido da M3.2). Nunca adicionar club_id
  // aqui.
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
          .eq('club_id', _clubId)
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
      // M3.4: onConflict tenant-aware usando a bridge unp_user_club_uidx
      // (user_id, club_id) — a PK legada (user_id) continua intacta pro app
      // publicado. Uma 2ª linha de preferências por clube só passa a existir
      // de fato quando a M2.2B-B trocar a PK; até lá o único clube é Goiás.
      await _client.from('user_notification_preferences').upsert({
        'user_id': _uid,
        'club_id': _clubId,
        'matches_enabled': ?matchesEnabled,
        'tickets_enabled': ?ticketsEnabled,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,club_id');
      return const Success(null);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(ServerFailure(_genericErrorMessage));
    }
  }
}

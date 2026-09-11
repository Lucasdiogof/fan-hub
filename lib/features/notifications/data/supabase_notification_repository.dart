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

  // `user_notification_tokens` continua GLOBAL no sentido de "aparelho, não
  // conta" (mesma linha física pode trocar de `user_id` se outra conta
  // logar no mesmo app instalado — é assim desde sempre, upsert por
  // `fcm_token`). Mas desde a M4.1c cada linha SABE a qual clube pertence:
  // um token FCM é escopado pela instalação do app que o gerou (Firebase
  // App ID = package/bundle id), nunca compartilhado entre 2 apps
  // diferentes — `club_id` grava isso explicitamente, nunca inferido.
  // fcm_token continua a ÚNICA chave de unicidade (nunca (club_id,
  // fcm_token) — o mesmo token físico nunca duplica, com ou sem clube).
  @override
  Future<Result<void>> registerToken({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _client.from('user_notification_tokens').upsert({
        'user_id': _uid,
        'fcm_token': fcmToken,
        'club_id': _clubId,
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
          .select(
            'live_matches_enabled, kickoff_enabled, goal_for_enabled, '
            'goal_against_enabled, half_time_enabled, '
            'second_half_started_enabled, full_time_enabled, tickets_enabled',
          )
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .maybeSingle();
      if (row == null) return const Success(NotificationPreferences());
      return Success(
        NotificationPreferences(
          liveMatchesEnabled: row['live_matches_enabled'] as bool,
          kickoffEnabled: row['kickoff_enabled'] as bool,
          goalForEnabled: row['goal_for_enabled'] as bool,
          goalAgainstEnabled: row['goal_against_enabled'] as bool,
          halfTimeEnabled: row['half_time_enabled'] as bool,
          secondHalfStartedEnabled: row['second_half_started_enabled'] as bool,
          fullTimeEnabled: row['full_time_enabled'] as bool,
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
    bool? liveMatchesEnabled,
    bool? kickoffEnabled,
    bool? goalForEnabled,
    bool? goalAgainstEnabled,
    bool? halfTimeEnabled,
    bool? secondHalfStartedEnabled,
    bool? fullTimeEnabled,
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
        'live_matches_enabled': ?liveMatchesEnabled,
        'kickoff_enabled': ?kickoffEnabled,
        'goal_for_enabled': ?goalForEnabled,
        'goal_against_enabled': ?goalAgainstEnabled,
        'half_time_enabled': ?halfTimeEnabled,
        'second_half_started_enabled': ?secondHalfStartedEnabled,
        'full_time_enabled': ?fullTimeEnabled,
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

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/notifications/domain/entities/notification_preferences.dart';

abstract class NotificationRepository {
  /// Upsert por `fcm_token` — se o mesmo aparelho logar com outra conta, o
  /// token muda de dono automaticamente, nunca duplica.
  Future<Result<void>> registerToken({
    required String fcmToken,
    required String platform,
  });

  /// Chamado no logout — marca o token como inativo (não apaga: se a mesma
  /// conta logar de novo no mesmo aparelho, um novo `registerToken`
  /// reativa). Nunca lança se o token já não existir mais.
  Future<Result<void>> deactivateToken(String fcmToken);

  Future<Result<NotificationPreferences>> getPreferences();

  Future<Result<void>> updatePreferences({
    bool? liveMatchesEnabled,
    bool? kickoffEnabled,
    bool? goalForEnabled,
    bool? goalAgainstEnabled,
    bool? halfTimeEnabled,
    bool? secondHalfStartedEnabled,
    bool? fullTimeEnabled,
    bool? ticketsEnabled,
  });
}

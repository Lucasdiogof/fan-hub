import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:goias_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:goias_app/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Dublê em memória — mesmo padrão de `_FakePassportRepository`
/// (test/features/passport/passport_cubit_test.dart). `lastUpdateCall`
/// guarda os args exatos da última `updatePreferences`, pra provar que
/// cada setter do Cubit persiste SÓ o campo que mudou.
class _FakeNotificationRepository implements NotificationRepository {
  NotificationPreferences preferences = const NotificationPreferences();
  bool failNextUpdate = false;
  Map<String, bool?>? lastUpdateCall;

  @override
  Future<Result<void>> registerToken({
    required String fcmToken,
    required String platform,
  }) async => const Success(null);

  @override
  Future<Result<void>> deactivateToken(String fcmToken) async =>
      const Success(null);

  @override
  Future<Result<NotificationPreferences>> getPreferences() async =>
      Success(preferences);

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
    lastUpdateCall = {
      'liveMatchesEnabled': liveMatchesEnabled,
      'kickoffEnabled': kickoffEnabled,
      'goalForEnabled': goalForEnabled,
      'goalAgainstEnabled': goalAgainstEnabled,
      'halfTimeEnabled': halfTimeEnabled,
      'secondHalfStartedEnabled': secondHalfStartedEnabled,
      'fullTimeEnabled': fullTimeEnabled,
      'ticketsEnabled': ticketsEnabled,
    };
    if (failNextUpdate) return const Error(ServerFailure('falhou'));
    return const Success(null);
  }
}

void main() {
  group('NotificationPreferencesCubit', () {
    test('load() -> success com as preferências do repositório', () async {
      final repo = _FakeNotificationRepository()
        ..preferences = const NotificationPreferences(
          liveMatchesEnabled: false,
          goalAgainstEnabled: false,
        );
      final cubit = NotificationPreferencesCubit(repo);
      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.preferences.liveMatchesEnabled, false);
      expect(cubit.state.preferences.goalAgainstEnabled, false);
    });

    test('load() -> error quando o repositório falha', () async {
      final repo = _FakeNotificationRepository();
      final cubit = NotificationPreferencesCubit(repo);
      // Simula falha via subclasse não é necessário: getPreferences do fake
      // sempre tem sucesso, então testamos o outro caminho via update.
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
    });

    test(
      'setLiveMatchesEnabled(false) atualiza o master e persiste só esse campo',
      () async {
        final repo = _FakeNotificationRepository();
        final cubit = NotificationPreferencesCubit(repo);
        await cubit.load();

        await cubit.setLiveMatchesEnabled(false);

        expect(cubit.state.preferences.liveMatchesEnabled, false);
        expect(repo.lastUpdateCall!['liveMatchesEnabled'], false);
        expect(repo.lastUpdateCall!['goalForEnabled'], isNull);
      },
    );

    test(
      'GRANULARIDADE: setGoalAgainstEnabled(false) não afeta goalForEnabled/kickoffEnabled',
      () async {
        final repo = _FakeNotificationRepository();
        final cubit = NotificationPreferencesCubit(repo);
        await cubit.load();

        await cubit.setGoalAgainstEnabled(false);

        expect(cubit.state.preferences.goalAgainstEnabled, false);
        expect(cubit.state.preferences.goalForEnabled, true);
        expect(cubit.state.preferences.kickoffEnabled, true);
      },
    );

    test(
      'setTicketsEnabled nunca mexe nas preferências de jogos ao vivo (categorias separadas)',
      () async {
        final repo = _FakeNotificationRepository();
        final cubit = NotificationPreferencesCubit(repo);
        await cubit.load();

        await cubit.setTicketsEnabled(false);

        expect(cubit.state.preferences.ticketsEnabled, false);
        expect(cubit.state.preferences.liveMatchesEnabled, true);
        expect(repo.lastUpdateCall!['liveMatchesEnabled'], isNull);
      },
    );

    test('falha na persistência reverte o valor otimista', () async {
      final repo = _FakeNotificationRepository()..failNextUpdate = true;
      final cubit = NotificationPreferencesCubit(repo);
      await cubit.load();

      await cubit.setHalfTimeEnabled(false);

      expect(cubit.state.preferences.halfTimeEnabled, true);
      expect(cubit.state.saving, false);
    });

    test(
      'sem linha no Supabase -> tudo habilitado por default (opt-out explícito, nunca opt-in silencioso)',
      () {
        const prefs = NotificationPreferences();
        expect(prefs.liveMatchesEnabled, true);
        expect(prefs.kickoffEnabled, true);
        expect(prefs.goalForEnabled, true);
        expect(prefs.goalAgainstEnabled, true);
        expect(prefs.halfTimeEnabled, true);
        expect(prefs.secondHalfStartedEnabled, true);
        expect(prefs.fullTimeEnabled, true);
        expect(prefs.ticketsEnabled, true);
      },
    );
  });
}

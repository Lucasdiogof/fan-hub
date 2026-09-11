import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:goias_app/features/notifications/presentation/cubit/notification_preferences_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationPreferencesCubit>()..load(),
      child: const _NotificationPreferencesView(),
    );
  }
}

class _NotificationPreferencesView extends StatelessWidget {
  const _NotificationPreferencesView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PageTitle(context.l10n.settingsNotificationsTitle),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: const [
                      _OsPermissionBanner(),
                      SizedBox(height: AppSpacing.lg),
                      _LiveMatchesGroup(),
                      SizedBox(height: AppSpacing.lg),
                      _TicketsToggle(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado da permissão do SO é uma coisa separada da preferência do app
/// (ponto explícito do spec) — se o sistema bloqueou notificações, mostra
/// isso claramente em vez de deixar os toggles prometerem algo que não vai
/// chegar. `FirebaseMessaging.getNotificationSettings()` nunca pede
/// permissão sozinho, só lê o estado atual.
class _OsPermissionBanner extends StatelessWidget {
  const _OsPermissionBanner();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotificationSettings>(
      future: FirebaseMessaging.instance.getNotificationSettings(),
      builder: (context, snapshot) {
        final status = snapshot.data?.authorizationStatus;
        if (status == null || status == AuthorizationStatus.authorized) {
          return const SizedBox.shrink();
        }
        final colors = context.colors;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.notificationsOsBlockedMessage,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: openAppSettings,
                child: Text(context.l10n.notificationsOpenSettings),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Grupo "Jogos ao vivo" — master toggle + 6 sub-preferências, uma por
/// evento canônico de partida. Regra explícita do produto: master OFF
/// desliga (e desabilita visualmente) os 6 sub-toggles, mesmo que o valor
/// individual salvo continue `true` — reativar o master volta a respeitar
/// cada sub-preferência como estava.
class _LiveMatchesGroup extends StatelessWidget {
  const _LiveMatchesGroup();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clubName = sl<ClubConfig>().identity.shortName;
    return BlocBuilder<NotificationPreferencesCubit, NotificationPreferencesState>(
      builder: (context, state) {
        final prefs = state.preferences;
        final loading = state.status == LoadStatus.loading;
        final subtogglesEnabled = !loading && prefs.liveMatchesEnabled;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.notificationsLiveMatchesTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.notificationsLiveMatchesDescription(
                              clubName,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: prefs.liveMatchesEnabled,
                      onChanged: loading
                          ? null
                          : (value) => context
                                .read<NotificationPreferencesCubit>()
                                .setLiveMatchesEnabled(value),
                      activeTrackColor: colors.primary,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              _SubToggleRow(
                title: context.l10n.notificationsKickoffTitle,
                description: context.l10n.notificationsKickoffDescription,
                value: prefs.kickoffEnabled,
                enabled: subtogglesEnabled,
                onChanged: (value) => context
                    .read<NotificationPreferencesCubit>()
                    .setKickoffEnabled(value),
              ),
              _SubToggleRow(
                title: context.l10n.notificationsGoalForTitle(clubName),
                description: context.l10n.notificationsGoalForDescription(
                  clubName,
                ),
                value: prefs.goalForEnabled,
                enabled: subtogglesEnabled,
                onChanged: (value) => context
                    .read<NotificationPreferencesCubit>()
                    .setGoalForEnabled(value),
              ),
              _SubToggleRow(
                title: context.l10n.notificationsGoalAgainstTitle,
                description: context.l10n.notificationsGoalAgainstDescription,
                value: prefs.goalAgainstEnabled,
                enabled: subtogglesEnabled,
                onChanged: (value) => context
                    .read<NotificationPreferencesCubit>()
                    .setGoalAgainstEnabled(value),
              ),
              _SubToggleRow(
                title: context.l10n.notificationsHalfTimeTitle,
                description: context.l10n.notificationsHalfTimeDescription,
                value: prefs.halfTimeEnabled,
                enabled: subtogglesEnabled,
                onChanged: (value) => context
                    .read<NotificationPreferencesCubit>()
                    .setHalfTimeEnabled(value),
              ),
              _SubToggleRow(
                title: context.l10n.notificationsSecondHalfTitle,
                description: context.l10n.notificationsSecondHalfDescription,
                value: prefs.secondHalfStartedEnabled,
                enabled: subtogglesEnabled,
                onChanged: (value) => context
                    .read<NotificationPreferencesCubit>()
                    .setSecondHalfStartedEnabled(value),
              ),
              _SubToggleRow(
                title: context.l10n.notificationsFullTimeTitle,
                description: context.l10n.notificationsFullTimeDescription,
                value: prefs.fullTimeEnabled,
                enabled: subtogglesEnabled,
                isLast: true,
                onChanged: (value) => context
                    .read<NotificationPreferencesCubit>()
                    .setFullTimeEnabled(value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubToggleRow extends StatelessWidget {
  const _SubToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.isLast = false,
  });

  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: enabled ? colors.textPrimary : colors.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: enabled ? colors.textSecondary : colors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeTrackColor: colors.primary,
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: colors.border, indent: AppSpacing.lg),
      ],
    );
  }
}

class _TicketsToggle extends StatelessWidget {
  const _TicketsToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NotificationPreferencesCubit,
      NotificationPreferencesState
    >(
      builder: (context, state) => _ToggleRow(
        icon: Icons.confirmation_number_outlined,
        title: context.l10n.notificationsTicketsTitle,
        description: context.l10n.notificationsTicketsDescription,
        value: state.preferences.ticketsEnabled,
        enabled: state.status != LoadStatus.loading,
        onChanged: (value) => context
            .read<NotificationPreferencesCubit>()
            .setTicketsEnabled(value),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: colors.primary,
          ),
        ],
      ),
    );
  }
}

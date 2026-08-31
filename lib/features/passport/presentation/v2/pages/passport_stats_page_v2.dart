import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_stats_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_stats_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Números da trajetória do usuário — aberta ao tocar no card "Meu
/// Passaporte" (`PassportCoverV2`). Carrega sob demanda (nunca junto do
/// resto do Passaporte, que já tem carga própria) e cobre todas as
/// temporadas de uma vez, não só o ano selecionado na tela principal.
class PassportStatsPageV2 extends StatelessWidget {
  const PassportStatsPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PassportStatsCubit>()..load(),
      child: const _PassportStatsViewV2(),
    );
  }
}

class _PassportStatsViewV2 extends StatelessWidget {
  const _PassportStatsViewV2();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        context.l10n.passportStatsTitle,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<PassportStatsCubit, PassportStatsState>(
                    builder: (context, state) {
                      return switch (state.status) {
                        LoadStatus.initial ||
                        LoadStatus.loading => const Center(
                          child: GoiasLoadingIndicator(),
                        ),
                        LoadStatus.error => Center(
                          child: StateMessage(
                            icon: Icons.wifi_off_rounded,
                            title: context.l10n.passportLoadErrorTitle,
                            message: state.errorMessage,
                            actionLabel: context.l10n.commonRetry,
                            onAction: () =>
                                context.read<PassportStatsCubit>().load(),
                          ),
                        ),
                        LoadStatus.empty => Center(
                          child: StateMessage(
                            icon: Icons.confirmation_number_outlined,
                            title: context.l10n.passportStatsEmptyTitle,
                            message: context.l10n.passportStatsEmptyMessage,
                          ),
                        ),
                        LoadStatus.success =>
                          state.breakdown.totalMatches == 0
                              ? Center(
                                  child: StateMessage(
                                    icon: Icons.confirmation_number_outlined,
                                    title: context.l10n.passportStatsEmptyTitle,
                                    message:
                                        context.l10n.passportStatsEmptyMessage,
                                  ),
                                )
                              : _StatsBody(breakdown: state.breakdown),
                      };
                    },
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

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.breakdown});

  final PassportAttendanceBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final goalDiff = breakdown.goalsFor - breakdown.goalsAgainst;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          l10n.passportStatsSubtitle,
          style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsWins,
                value: breakdown.wins,
                color: colors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsDraws,
                value: breakdown.draws,
                color: colors.textHint,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsLosses,
                value: breakdown.losses,
                color: colors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsHomeGames,
                value: breakdown.homeGames,
                color: colors.primary,
                icon: Icons.home_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: l10n.passportStatsAwayGames,
                value: breakdown.awayGames,
                color: colors.primary,
                icon: Icons.flight_takeoff_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _GoalStat(
                  label: l10n.passportStatsGoalsFor,
                  value: breakdown.goalsFor,
                  color: colors.success,
                ),
              ),
              Container(width: 1, height: 36, color: colors.border),
              Expanded(
                child: _GoalStat(
                  label: l10n.passportStatsGoalsAgainst,
                  value: breakdown.goalsAgainst,
                  color: colors.gold,
                ),
              ),
              Container(width: 1, height: 36, color: colors.border),
              Expanded(
                child: _GoalStat(
                  label: l10n.passportStatsGoalDifference,
                  value: goalDiff,
                  color: goalDiff >= 0 ? colors.success : colors.gold,
                  showSign: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
          ],
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({
    required this.label,
    required this.value,
    required this.color,
    this.showSign = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = showSign && value > 0 ? '+$value' : '$value';
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, color: colors.textSecondary),
        ),
      ],
    );
  }
}

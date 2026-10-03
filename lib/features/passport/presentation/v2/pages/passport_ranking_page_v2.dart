import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/ranking/presentation/widgets/ranking_avatar.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_ranking_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_ranking_state.dart';
import 'package:goias_app/features/passport/presentation/pages/passport_trajectory_page.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Mesma tela/Cubit/regra de pontuação da V1 — só a apresentação visual
/// segue a linguagem V2.
class PassportRankingPageV2 extends StatelessWidget {
  const PassportRankingPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PassportRankingCubit>()..load(),
      child: const _PassportRankingViewV2(),
    );
  }
}

class _PassportRankingViewV2 extends StatelessWidget {
  const _PassportRankingViewV2();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = context.l10n.passportRankingTitle;
    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<PassportRankingCubit, PassportRankingState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<PassportRankingCubit>().refresh(),
            color: colors.primary,
            child: DetailPageHeader(
              title: title,
              heroTitle: Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PeriodSelectorV2(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    switch (state.status) {
                      LoadStatus.initial || LoadStatus.loading => const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: GoiasLoadingIndicator()),
                      ),
                      LoadStatus.error => Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: StateMessage(
                            icon: Icons.wifi_off_rounded,
                            title: context.l10n.passportLoadErrorTitle,
                            message: state.errorMessage,
                            actionLabel: context.l10n.commonRetry,
                            onAction: () =>
                                context.read<PassportRankingCubit>().refresh(),
                          ),
                        ),
                      ),
                      LoadStatus.empty => Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: StateMessage(
                            icon: Icons.leaderboard_outlined,
                            title: context.l10n.passportRankingEmptyTitle,
                            message: context.l10n.passportRankingEmptyMessage,
                          ),
                        ),
                      ),
                      LoadStatus.success => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final entry in state.entries)
                            _RankingRowV2(entry: entry),
                        ],
                      ),
                    },
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeriodSelectorV2 extends StatelessWidget {
  const _PeriodSelectorV2({required this.state});

  final PassportRankingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear; y >= currentYear - 4; y--) y];
    final options = <(int?, String)>[
      (null, l10n.passportRankingPeriodOverall),
      for (final y in years) (y, '$y'),
    ];
    return FanHubTabBar(
      labels: [for (final (_, label) in options) label],
      selectedIndex: options.indexWhere((option) => option.$1 == state.year),
      onChanged: (index) =>
          context.read<PassportRankingCubit>().selectYear(options[index].$1),
    );
  }
}

class _RankingRowV2 extends StatelessWidget {
  const _RankingRowV2({required this.entry});

  final PassportRankingEntry entry;

  /// Tocar em si mesmo abre a própria trajetória no modo normal (edita jogo
  /// memorável, nome/foto do `ProfileCubit`) — nunca no modo só-leitura de
  /// outro torcedor, mesmo sendo tecnicamente a mesma pessoa.
  void _openTrajectory(BuildContext context) {
    context.push(
      '/arena/passport/trajectory',
      extra: entry.isMe
          ? null
          : PassportTrajectoryArgs(
              userId: entry.userId,
              name: entry.name,
              avatarUrl: entry.avatarUrl,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Material(
      color: entry.isMe ? colors.secondary : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openTrajectory(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: entry.isMe
                  ? colors.primary.withValues(alpha: 0.35)
                  : colors.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${entry.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              RankingAvatar(name: entry.name, avatarUrl: entry.avatarUrl),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: entry.isMe
                              ? colors.primary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (entry.isMember) ...[
                      const SizedBox(width: 6),
                      RankingMemberBadge(label: l10n.arenaRankingMemberBadge),
                    ],
                  ],
                ),
              ),
              Text(
                l10n.passportRankingMatchCount(entry.matchCount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

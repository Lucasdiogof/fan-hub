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
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Ranking do Passaporte — totalmente separado do ranking da Arena, própria
/// tela, próprio Cubit, própria pontuação (1 partida marcada = 1 ponto).
class PassportRankingPageV1 extends StatelessWidget {
  const PassportRankingPageV1({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PassportRankingCubit>()..load(),
      child: const _PassportRankingView(),
    );
  }
}

class _PassportRankingView extends StatelessWidget {
  const _PassportRankingView();

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
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      PageTitle(context.l10n.passportRankingTitle),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      BlocBuilder<PassportRankingCubit, PassportRankingState>(
                        builder: (context, state) {
                          return RefreshIndicator(
                            onRefresh: () =>
                                context.read<PassportRankingCubit>().refresh(),
                            color: colors.primary,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.md,
                                AppSpacing.lg,
                                AppSpacing.xxxl,
                              ),
                              children: [
                                _PeriodSelector(state: state),
                                const SizedBox(height: AppSpacing.lg),
                                switch (state.status) {
                                  LoadStatus.initial ||
                                  LoadStatus.loading => const Padding(
                                    padding: EdgeInsets.only(top: 60),
                                    child: Center(
                                      child: GoiasLoadingIndicator(),
                                    ),
                                  ),
                                  LoadStatus.error => Padding(
                                    padding: const EdgeInsets.only(top: 60),
                                    child: Center(
                                      child: StateMessage(
                                        icon: Icons.wifi_off_rounded,
                                        title:
                                            context.l10n.passportLoadErrorTitle,
                                        message: state.errorMessage,
                                        actionLabel: context.l10n.commonRetry,
                                        onAction: () => context
                                            .read<PassportRankingCubit>()
                                            .refresh(),
                                      ),
                                    ),
                                  ),
                                  LoadStatus.empty => Padding(
                                    padding: const EdgeInsets.only(top: 60),
                                    child: Center(
                                      child: StateMessage(
                                        icon: Icons.leaderboard_outlined,
                                        title: context
                                            .l10n
                                            .passportRankingEmptyTitle,
                                        message: context
                                            .l10n
                                            .passportRankingEmptyMessage,
                                      ),
                                    ),
                                  ),
                                  LoadStatus.success => Column(
                                    children: [
                                      for (final entry in state.entries)
                                        _RankingRow(entry: entry),
                                    ],
                                  ),
                                },
                              ],
                            ),
                          );
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

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.state});

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
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (year, label) = options[index];
          final selected = state.year == year;
          final colors = context.colors;
          return Semantics(
            button: true,
            selected: selected,
            label: label,
            child: InkWell(
              onTap: () =>
                  context.read<PassportRankingCubit>().selectYear(year),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? colors.onPrimary : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final PassportRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: entry.isMe ? colors.secondary : colors.surface,
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
                      color: entry.isMe ? colors.primary : colors.textPrimary,
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
    );
  }
}

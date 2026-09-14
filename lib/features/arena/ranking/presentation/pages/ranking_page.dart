import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/ranking/presentation/cubit/ranking_cubit.dart';
import 'package:goias_app/features/arena/ranking/presentation/cubit/ranking_state.dart';
import 'package:goias_app/features/arena/ranking/presentation/widgets/ranking_avatar.dart';
import 'package:goias_app/features/arena/ranking/presentation/widgets/ranking_user_detail_sheet.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// [cubit], quando fornecido, já veio construído e carregado por quem
/// navegou pra cá (ver `GlobalLoading.run` em `arena_page.dart`) — a tela
/// só reaproveita via `BlocProvider.value`. Fica `null` (e a tela cria/
/// carrega o próprio Cubit) só em navegação direta por URL.
class RankingPage extends StatelessWidget {
  const RankingPage({this.cubit, super.key});

  final RankingCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(value: preloaded, child: const _RankingView());
    }
    return BlocProvider(
      create: (_) => RankingCubit(
        sl<ArenaRankingRepository>(),
        sl<MembershipStatusCubit>(),
      )..load(),
      child: const _RankingView(),
    );
  }
}

class _RankingView extends StatelessWidget {
  const _RankingView();

  void _showDetail(
    BuildContext context,
    RankingEntry entry,
    RankingPeriod period, {
    int? pointsToNext,
    int? nextRank,
  }) {
    AppModalSheet.show<void>(
      context,
      builder: (_) => RankingUserDetailSheet(
        entry: entry,
        period: period,
        pointsToNext: pointsToNext,
        nextRank: nextRank,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = context.l10n.arenaRankingTitle;
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        title: title,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
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
              BlocBuilder<RankingCubit, RankingState>(
                buildWhen: (previous, current) =>
                    previous.period != current.period,
                builder: (context, state) => _PeriodSegmented(
                  period: state.period,
                  onChanged: (period) =>
                      context.read<RankingCubit>().selectPeriod(period),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<RankingCubit, RankingState>(
                builder: (context, state) {
                  if (state.status == LoadStatus.loading ||
                      state.status == LoadStatus.initial) {
                    return const SizedBox(
                      height: 320,
                      child: Center(child: GoiasLoadingIndicator()),
                    );
                  }
                  if (state.status == LoadStatus.error) {
                    return _ErrorRanking(
                      onRetry: () => context.read<RankingCubit>().load(),
                    );
                  }
                  if (state.entries.isEmpty) {
                    return const _EmptyRanking();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < state.entries.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        _RankRow(
                          entry: state.entries[i],
                          onTap: () => _showDetail(
                            context,
                            state.entries[i],
                            state.period,
                            pointsToNext: i == 0
                                ? null
                                : state.entries[i - 1].totalScore -
                                      state.entries[i].totalScore,
                            nextRank: i == 0 ? null : state.entries[i - 1].rank,
                          ),
                        ),
                      ],
                      if (state.showPinnedPosition) const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<RankingCubit, RankingState>(
        buildWhen: (previous, current) =>
            previous.showPinnedPosition != current.showPinnedPosition ||
            previous.myRank != current.myRank,
        builder: (context, state) {
          if (!state.showPinnedPosition) return const SizedBox.shrink();
          final myRank = state.myRank!;
          return SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ContentWidth.wide.maxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: _PinnedPositionCard(
                    rank: myRank.rank,
                    score: myRank.totalScore,
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

class _PeriodSegmented extends StatelessWidget {
  const _PeriodSegmented({required this.period, required this.onChanged});

  final RankingPeriod period;
  final ValueChanged<RankingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final options = [
      (RankingPeriod.allTime, context.l10n.arenaRankingAllTime),
      (RankingPeriod.monthly, context.l10n.arenaRankingMonthly),
      (RankingPeriod.weekly, context.l10n.arenaRankingWeekly),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _SegmentButton(
                label: option.$2,
                selected: option.$1 == period,
                onTap: () => onChanged(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? colors.onPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.onTap});

  final RankingEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final medal = switch (entry.rank) {
      1 => colors.gold,
      2 => const Color(0xFFB8BCC0),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };
    return Material(
      color: entry.isMe ? colors.secondary : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: entry.isMe ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medal ?? colors.background,
                  border: medal == null
                      ? Border.all(color: colors.border)
                      : null,
                ),
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: medal != null ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              RankingAvatar(
                name: rankingDisplayName(context, entry),
                avatarUrl: entry.avatarUrl,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        rankingDisplayName(context, entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: entry.isMe
                              ? colors.primary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (entry.isMe) ...[
                      const SizedBox(width: 6),
                      const _YouTag(),
                    ],
                    if (entry.isMember) ...[
                      const SizedBox(width: 6),
                      RankingMemberBadge(
                        label: context.l10n.arenaRankingMemberBadge,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${entry.totalScore}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                context.l10n.arenaRankingPoints,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouTag extends StatelessWidget {
  const _YouTag();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.arenaRankingYouTag,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}

class _PinnedPositionCard extends StatelessWidget {
  const _PinnedPositionCard({required this.rank, required this.score});

  final int rank;
  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.arenaRankingYourPosition,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colors.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            context.l10n.arenaRankingPoints,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRanking extends StatelessWidget {
  const _ErrorRanking({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.arenaRankingEmpty,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.arenaRankingEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

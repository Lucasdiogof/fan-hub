import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/ranking/presentation/widgets/ranking_avatar.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

String gameLabel(BuildContext context, String gameId) => switch (gameId) {
  ArenaGameIds.quiz => context.l10n.arenaGameQuizTitle,
  ArenaGameIds.lineup => context.l10n.arenaGameLineupTitle,
  ArenaGameIds.careerPath => context.l10n.arenaGameCareerTitle,
  ArenaGameIds.guessPlayer => context.l10n.arenaGuessPlayerTitle,
  _ => gameId,
};

class RankingUserDetailSheet extends StatefulWidget {
  const RankingUserDetailSheet({required this.entry, super.key});

  final RankingEntry entry;

  @override
  State<RankingUserDetailSheet> createState() => _RankingUserDetailSheetState();
}

class _RankingUserDetailSheetState extends State<RankingUserDetailSheet> {
  late final Future<Result<RankingUserDetail>> _future =
      sl<ArenaRankingRepository>().getUserDetail(widget.entry);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entry = widget.entry;
    final medal = switch (entry.rank) {
      1 => colors.gold,
      2 => const Color(0xFFB8BCC0),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    RankingAvatar(
                      name: entry.name,
                      avatarUrl: entry.avatarUrl,
                      size: 64,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (entry.isMember) ...[
                          const SizedBox(width: 6),
                          RankingMemberBadge(
                            label: context.l10n.arenaRankingMemberBadge,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: medal != null
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.totalScore} ${context.l10n.arenaRankingPoints}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FutureBuilder<Result<RankingUserDetail>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(child: GoiasLoadingIndicator()),
                    );
                  }
                  final result = snapshot.data;
                  if (result is! Success<RankingUserDetail>) {
                    return const SizedBox.shrink();
                  }
                  return _DetailBody(detail: result.data);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final RankingUserDetail detail;

  int _scoreFor(String gameId) {
    for (final row in detail.breakdown) {
      if (row.gameId == gameId) return row.score;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const games = [
      ArenaGameIds.quiz,
      ArenaGameIds.lineup,
      ArenaGameIds.careerPath,
      ArenaGameIds.guessPlayer,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final gameId in games) ...[
          _StatRow(label: gameLabel(context, gameId), value: _scoreFor(gameId)),
          const SizedBox(height: AppSpacing.xs),
        ],
        const Divider(height: AppSpacing.lg),
        _StatRow(
          label: context.l10n.arenaRankingDetailTotal,
          value: detail.entry.totalScore,
          emphasized: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SecondaryStat(
          label: context.l10n.arenaRankingDetailFirstTry,
          value: detail.firstTryTotal,
        ),
        _SecondaryStat(
          label: context.l10n.arenaRankingDetailReview,
          value: detail.reviewTotal,
        ),
        _SecondaryStat(
          label: context.l10n.arenaRankingDetailAbandoned,
          value: detail.abandonedOrRevealedTotal,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 14.5 : 13.5,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              color: emphasized ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: emphasized ? 16 : 14,
            fontWeight: FontWeight.w900,
            color: emphasized ? colors.primary : colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SecondaryStat extends StatelessWidget {
  const _SecondaryStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

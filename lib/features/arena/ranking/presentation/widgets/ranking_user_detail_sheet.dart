import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/ranking/presentation/widgets/ranking_avatar.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// Ordem canônica dos jogos na sheet (mesma do hub da Arena).
const _games = [
  ArenaGameIds.quiz,
  ArenaGameIds.guessPlayer,
  ArenaGameIds.lineup,
  ArenaGameIds.careerPath,
];

String gameLabel(BuildContext context, String gameId) => switch (gameId) {
  ArenaGameIds.quiz => context.l10n.arenaGameQuizTitle,
  ArenaGameIds.lineup => context.l10n.arenaGameLineupTitle,
  ArenaGameIds.careerPath => context.l10n.arenaGameCareerTitle,
  ArenaGameIds.guessPlayer => context.l10n.arenaGuessPlayerTitle,
  _ => gameId,
};

IconData gameIcon(String gameId) => switch (gameId) {
  ArenaGameIds.quiz => Icons.psychology_rounded,
  ArenaGameIds.lineup => Icons.groups_rounded,
  ArenaGameIds.careerPath => Icons.timeline_rounded,
  ArenaGameIds.guessPlayer => Icons.checkroom_rounded,
  _ => Icons.sports_soccer_rounded,
};

Color? medalColor(BuildContext context, int rank) => switch (rank) {
  1 => context.colors.gold,
  2 => const Color(0xFFB8BCC0),
  3 => const Color(0xFFCD7F32),
  _ => null,
};

class RankingUserDetailSheet extends StatefulWidget {
  const RankingUserDetailSheet({
    required this.entry,
    required this.period,
    this.pointsToNext,
    this.nextRank,
    super.key,
  });

  final RankingEntry entry;
  final RankingPeriod period;

  /// Diferença de pontos pro colocado logo acima (e a posição dele) — vem da
  /// lista já carregada na tela, `null` pro 1º lugar ou quando indisponível.
  final int? pointsToNext;
  final int? nextRank;

  @override
  State<RankingUserDetailSheet> createState() => _RankingUserDetailSheetState();
}

class _RankingUserDetailSheetState extends State<RankingUserDetailSheet> {
  late final Future<Result<RankingUserDetail>> _future =
      sl<ArenaRankingRepository>().getUserDetail(widget.entry);

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeader(
                entry: widget.entry,
                period: widget.period,
                pointsToNext: widget.pointsToNext,
                nextRank: widget.nextRank,
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
                  return _DetailBody(
                    detail: result.data,
                    isMe: widget.entry.isMe,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.entry,
    required this.period,
    required this.pointsToNext,
    required this.nextRank,
  });

  final RankingEntry entry;
  final RankingPeriod period;
  final int? pointsToNext;
  final int? nextRank;

  String _periodLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (period) {
      case RankingPeriod.allTime:
        return l10n.arenaRankingPeriodOverall;
      case RankingPeriod.weekly:
        return l10n.arenaRankingPeriodWeek;
      case RankingPeriod.monthly:
        final locale = Localizations.localeOf(context).toLanguageTag();
        final label = DateFormat.yMMMM(locale).format(DateTime.now());
        return label.isEmpty
            ? label
            : label[0].toUpperCase() + label.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final medal = medalColor(context, entry.rank);
    final gap = pointsToNext;
    return Column(
      children: [
        RankingAvatar(
          name: rankingDisplayName(context, entry),
          avatarUrl: entry.avatarUrl,
          size: 72,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                rankingDisplayName(context, entry),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (entry.isMember) ...[
              const SizedBox(width: 6),
              RankingMemberBadge(label: context.l10n.arenaRankingMemberBadge),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medal ?? colors.secondary,
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
            const SizedBox(width: 8),
            Text(
              context.l10n.arenaRankingPlace(entry.rank),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${entry.totalScore}',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              TextSpan(
                text: ' ${context.l10n.arenaRankingPointsFull}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PeriodChip(label: _periodLabel(context)),
        if (gap != null && gap > 0 && nextRank != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.arenaRankingGapToNext(gap, nextRank!),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textHint,
            ),
          ),
        ],
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.isMe});

  final RankingUserDetail detail;
  final bool isMe;

  GameScoreBreakdown? _rowFor(String gameId) {
    for (final row in detail.breakdown) {
      if (row.gameId == gameId) return row;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total = detail.breakdown.fold(0, (sum, b) => sum + b.score);
    if (total <= 0) {
      return _EmptyPerformance(isMe: isMe);
    }

    final scored = [
      for (final gameId in _games)
        if ((_rowFor(gameId)?.score ?? 0) > 0) gameId,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: context.l10n.arenaRankingByGame),
        const SizedBox(height: AppSpacing.md),
        for (final gameId in _games) ...[
          _GamePointsRow(
            gameId: gameId,
            score: _rowFor(gameId)?.score ?? 0,
            total: total,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        _SectionTitle(
          title: isMe
              ? context.l10n.arenaRankingHowScoredSelf
              : context.l10n.arenaRankingHowScoredOther(
                  rankingDisplayName(context, detail.entry).split(' ').first,
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final gameId in scored) ...[
          _GameBreakdownCard(row: _rowFor(gameId)!),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: colors.textPrimary,
      ),
    );
  }
}

/// Linha compacta de "Pontuação por jogo": ícone, nome, pontos + % e barra de
/// contribuição. Jogos sem pontos aparecem apagados, sem barra.
class _GamePointsRow extends StatelessWidget {
  const _GamePointsRow({
    required this.gameId,
    required this.score,
    required this.total,
  });

  final String gameId;
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isZero = score <= 0;
    final percent = isZero ? 0 : (score / total * 100).round();
    final fraction = isZero ? 0.0 : (score / total).clamp(0.0, 1.0);
    final accent = isZero ? colors.textHint : colors.primary;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isZero
                ? colors.secondary.withValues(alpha: 0.5)
                : colors.secondary,
          ),
          child: Icon(gameIcon(gameId), size: 18, color: accent),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      gameLabel(context, gameId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isZero ? colors.textHint : colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.arenaRankingGamePointsShare(score, percent),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isZero ? colors.textHint : colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: colors.secondary,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card de detalhamento de um jogo: cabeçalho (ícone + nome + pontos) e só as
/// métricas que aquele jogo tem (contadores zerados ficam de fora).
class _GameBreakdownCard extends StatelessWidget {
  const _GameBreakdownCard({required this.row});

  final GameScoreBreakdown row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = <(IconData, String, int)>[
      if (row.firstTryCount > 0)
        (
          Icons.check_circle_rounded,
          context.l10n.arenaRankingDetailFirstTry,
          row.firstTryCount,
        ),
      if (row.reviewCount > 0)
        (
          Icons.refresh_rounded,
          context.l10n.arenaRankingDetailReview,
          row.reviewCount,
        ),
      if (row.abandonedOrRevealedCount > 0)
        (
          Icons.visibility_rounded,
          context.l10n.arenaRankingDetailAbandoned,
          row.abandonedOrRevealedCount,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(gameIcon(row.gameId), size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  gameLabel(context, row.gameId),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${row.score} ${context.l10n.arenaRankingPoints}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          if (metrics.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          for (final metric in metrics)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(metric.$1, size: 15, color: colors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metric.$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${metric.$3}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPerformance extends StatelessWidget {
  const _EmptyPerformance({required this.isMe});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Icon(Icons.sports_soccer_rounded, size: 40, color: colors.textHint),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.arenaRankingNoPointsTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isMe
              ? context.l10n.arenaRankingNoPointsSelf
              : context.l10n.arenaRankingNoPointsOther,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

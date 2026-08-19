import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

class MatchListItem extends StatelessWidget {
  const MatchListItem({required this.match, this.onTap, super.key});

  final Match match;
  final VoidCallback? onTap;

  bool get _isFinished =>
      match.status == MatchStatus.finished && match.homeScore != null && match.awayScore != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${shortDateLabel(match.kickoff)} • ${weekdayShortLabel(match.kickoff)}',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      ClubBadge(team: match.homeTeam, size: 30),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          match.homeTeam.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: _isFinished
                      ? Text(
                          '${match.homeScore} x ${match.awayScore}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: colors.textPrimary),
                        )
                      : Text(
                          timeLabel(match.kickoff),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: colors.textPrimary),
                        ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          match.awayTeam.name,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ClubBadge(team: match.awayTeam, size: 30),
                    ],
                  ),
                ),
              ],
            ),
            if (match.stadium.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: colors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    match.stadium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: colors.textHint),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

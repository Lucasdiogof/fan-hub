import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

class UpcomingMatchCard extends StatelessWidget {
  const UpcomingMatchCard({
    required this.match,
    this.ticketsAvailable = false,
    this.onTap,
    super.key,
  });

  final Match match;

  /// Mock local — ingresso/check-in não vem da API-Football, só dados esportivos.
  final bool ticketsAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: Container(
        width: 156,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              shortDateLabel(match.kickoff),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            const SizedBox(height: 1),
            Text(
              timeLabel(match.kickoff),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.textHint),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubBadge(team: match.homeTeam, size: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'x',
                    style: TextStyle(color: colors.textHint, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                ClubBadge(team: match.awayTeam, size: 28),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              match.stadium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ticketsAvailable ? colors.success : colors.textHint,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ticketsAvailable ? 'VENDA ABERTA' : 'EM BREVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: ticketsAvailable ? colors.success : colors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

class LastMatchCard extends StatelessWidget {
  const LastMatchCard({required this.match, super.key});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ÚLTIMO RESULTADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClubBadge(team: match.homeTeam, size: 42),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      match.homeTeam.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30, color: colors.textPrimary, height: 1),
                    children: [
                      TextSpan(text: '${match.homeScore}'),
                      TextSpan(
                        text: '  x  ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textHint),
                      ),
                      TextSpan(text: '${match.awayScore}'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClubBadge(team: match.awayTeam, size: 42),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      match.awayTeam.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(height: 1, color: colors.border),
          const SizedBox(height: AppSpacing.md),
          Text(
            match.competition,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '${shortDateLabel(match.kickoff)} • ${weekdayLabel(match.kickoff)}',
            style: TextStyle(fontSize: 11, color: colors.textHint),
          ),
        ],
      ),
    );
  }
}

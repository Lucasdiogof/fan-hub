import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

class StandingsRow extends StatelessWidget {
  const StandingsRow({
    required this.standing,
    required this.isActiveClub,
    super.key,
  });

  final Standing standing;

  /// Vem de comparação por `team.id`, decidida por quem monta a lista —
  /// esse widget não sabe (nem precisa saber) qual é o id do Goiás.
  final bool isActiveClub;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isActiveClub ? colors.primary : colors.textPrimary;
    final numberStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: foreground,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isActiveClub ? colors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${standing.position}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ClubBadge(team: standing.team, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              shortTeamName(standing.team.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActiveClub ? FontWeight.w800 : FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${standing.points}',
              textAlign: TextAlign.center,
              style: numberStyle,
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${standing.played}',
              textAlign: TextAlign.center,
              style: numberStyle,
            ),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${standing.wins}',
              textAlign: TextAlign.center,
              style: numberStyle,
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              standing.goalDifference > 0
                  ? '+${standing.goalDifference}'
                  : '${standing.goalDifference}',
              textAlign: TextAlign.center,
              style: numberStyle,
            ),
          ),
        ],
      ),
    );
  }
}

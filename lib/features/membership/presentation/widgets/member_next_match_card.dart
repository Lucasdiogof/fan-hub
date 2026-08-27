import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Não implementa check-in real — só leva pra uma tela preparada, sem
/// fingir integração com o sistema oficial do Sócio Esmeralda.
class MemberNextMatchCard extends StatelessWidget {
  const MemberNextMatchCard({
    required this.match,
    required this.onCheckIn,
    super.key,
  });

  final Match match;
  final VoidCallback onCheckIn;

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
        children: [
          Text(
            context.l10n.homeNextMatch,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.textHint,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ClubBadge(team: match.homeTeam, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'x',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textHint,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClubBadge(team: match.awayTeam, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '${shortTeamName(match.homeTeam.name)} x ${shortTeamName(match.awayTeam.name)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            match.kickoff != null
                ? '${shortDateLabel(match.kickoff!, Localizations.localeOf(context).toString())} • ${timeLabel(match.kickoff!)}${match.stadium.isNotEmpty ? ' • ${match.stadium}' : ''}'
                : '${context.l10n.matchDateToBeConfirmed}${match.stadium.isNotEmpty ? ' • ${match.stadium}' : ''}',
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.membershipMatchAccessNotice,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCheckIn,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.3,
                ),
              ),
              child: Text(context.l10n.membershipCheckInAction),
            ),
          ),
        ],
      ),
    );
  }
}

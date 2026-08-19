import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/widgets/match_countdown.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/stadium_backdrop.dart';

class NextMatchHero extends StatelessWidget {
  const NextMatchHero({
    required this.match,
    this.onTickets,
    this.onViewDetails,
    this.onMatchStarted,
    super.key,
  });

  final Match match;
  final VoidCallback? onTickets;
  final VoidCallback? onViewDetails;
  final VoidCallback? onMatchStarted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          const Positioned.fill(child: StadiumBackdrop(imageAsset: AppAssets.matchHero)),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PRÓXIMO JOGO',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  match.competition.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${shortDateLabel(match.kickoff)} | ${timeLabel(match.kickoff)} | ${match.stadium.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _TeamColumn(team: match.homeTeam)),
                    const _VersusBadge(),
                    Expanded(child: _TeamColumn(team: match.awayTeam)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                MatchCountdown(kickoff: match.kickoff, onFinished: onMatchStarted),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        child: const Text('DETALHES DO JOGO'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onTickets,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.ctaGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: colors.ctaGreen.withValues(alpha: 0.5),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        child: const Text('INGRESSOS'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClubBadge(team: team, size: 60, onDark: true),
        const SizedBox(height: AppSpacing.md),
        Text(
          team.name.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _VersusBadge extends StatelessWidget {
  const _VersusBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          'X',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

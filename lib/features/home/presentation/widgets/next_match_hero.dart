import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/stadium_backdrop.dart';

class NextMatchHero extends StatelessWidget {
  const NextMatchHero({
    required this.match,
    this.onBuyTicket,
    this.onViewDetails,
    super.key,
  });

  final Match match;
  final VoidCallback? onBuyTicket;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          const Positioned.fill(child: StadiumBackdrop()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
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
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _TeamColumn(team: match.homeTeam)),
                    const _VersusBadge(),
                    Expanded(child: _TeamColumn(team: match.awayTeam)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  children: [
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.calendar_today_outlined,
                        label: '${shortDateLabel(match.kickoff)} • ${weekdayShortLabel(match.kickoff)}',
                      ),
                    ),
                    const _MetaDivider(),
                    Expanded(
                      child: _MetaItem(icon: Icons.access_time_rounded, label: timeLabel(match.kickoff)),
                    ),
                    const _MetaDivider(),
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.location_on_outlined,
                        label: match.stadium.toUpperCase(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBuyTicket,
                        icon: const Icon(Icons.confirmation_number_outlined, size: 17),
                        label: const Text('COMPRAR INGRESSO'),
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
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('VER DETALHES'),
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

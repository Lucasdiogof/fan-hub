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

/// Único grande bloco escuro da primeira dobra — o header acima dele é
/// claro de propósito, pra não competir visualmente.
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
          const Positioned.fill(
            child: StadiumBackdrop(imageAsset: AppAssets.matchHero, showFloodlights: false, overlayOpacity: 0.85),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
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
                  _shortCompetitionLabel(match.competition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${shortDateLabel(match.kickoff)} • ${timeLabel(match.kickoff)} • ${match.stadium.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _TeamColumn(team: match.homeTeam)),
                    const _VersusBadge(),
                    Expanded(child: _TeamColumn(team: match.awayTeam)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                MatchCountdown(kickoff: match.kickoff, onFinished: onMatchStarted),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
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
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
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

final _competitionShortNames = {
  RegExp(r'campeonato brasileiro s[ée]rie a', caseSensitive: false): 'Brasileirão Série A',
  RegExp(r'campeonato brasileiro s[ée]rie b', caseSensitive: false): 'Brasileirão Série B',
  RegExp(r'campeonato brasileiro s[ée]rie c', caseSensitive: false): 'Brasileirão Série C',
};

/// A fonte real devolve algo como "Campeonato Brasileiro Série B 2026" —
/// grande demais pro Hero. Isso é só apresentação, não mexe no dado.
String _shortCompetitionLabel(String competition) {
  for (final entry in _competitionShortNames.entries) {
    if (entry.key.hasMatch(competition)) return entry.value;
  }
  return competition;
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClubBadge(team: team, size: 64, onDark: true),
        const SizedBox(height: AppSpacing.sm),
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
      child: Text(
        'X',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

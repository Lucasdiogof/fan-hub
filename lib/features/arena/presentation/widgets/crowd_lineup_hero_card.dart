import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/stadium_backdrop.dart';

/// Elemento principal da Arena quando há um próximo jogo — a Escalação da
/// Torcida deixa de disputar espaço com os outros cards e vira o hero da
/// página. Mesmo fundo institucional do `NextMatchHero` (`StadiumBackdrop`
/// em darkGreen, sem foto/holofote) por consistência, nunca um gradiente
/// novo. A prancheta tática entra bem sutil no canto, só pra dar textura
/// de "campo/escalação" sem competir com o conteúdo.
class CrowdLineupHeroCard extends StatelessWidget {
  const CrowdLineupHeroCard({
    required this.match,
    required this.hasVoted,
    required this.onTap,
    this.participants,
    super.key,
  });

  final Match match;
  final bool hasVoted;
  final VoidCallback onTap;
  final int? participants;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateTimeLabel = match.kickoff != null
        ? '${shortDateLabel(match.kickoff!, locale)} • ${timeLabel(match.kickoff!)} • ${match.stadium.toUpperCase()}'
        : '${l10n.homeDateToBeConfirmed} • ${match.stadium.toUpperCase()}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          const Positioned.fill(child: StadiumBackdrop(showFloodlights: false)),
          Positioned(
            right: -30,
            bottom: 92,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                sl<ClubConfig>().assets.tacticsBoardIllustration,
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.arenaNextMatchBadge,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClubBadge(team: match.homeTeam, size: 28, onDark: true),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${shortTeamName(match.homeTeam.name)} × ${shortTeamName(match.awayTeam.name)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ClubBadge(team: match.awayTeam, size: 28, onDark: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateTimeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.arenaLineupHeroEyebrow,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasVoted
                          ? l10n.crowdCardDescVoted(
                              sl<ClubConfig>().identity.shortName,
                            )
                          : l10n.crowdCardDescNew(
                              sl<ClubConfig>().identity.shortName,
                            ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm + 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          hasVoted
                              ? l10n.arenaHighlightViewLineup
                              : l10n.arenaLineupHeroCta,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: sl<ClubConfig>().branding.light.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado sem próximo jogo confirmado — discreto, nunca no tamanho do hero
/// (a Escalação só domina a tela quando de fato há o que escalar).
class CrowdLineupHeroEmptyCard extends StatelessWidget {
  const CrowdLineupHeroEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            child: Icon(
              Icons.event_available_outlined,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.arenaLineupHeroEmptyTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.arenaLineupHeroEmptyMessage,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: colors.textSecondary,
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

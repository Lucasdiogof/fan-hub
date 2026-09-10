import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/widgets/match_status_label.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

class MatchListItem extends StatelessWidget {
  const MatchListItem({required this.match, this.onTap, super.key});

  final Match match;
  final VoidCallback? onTap;

  /// Mostra o placar sempre que ele existir — mesmo com o jogo ainda em
  /// andamento (placar parcial). Antes só mostrava quando `finished`, então
  /// a lista ficava mostrando o horário durante o jogo todo, só trocando
  /// pro placar quando o jogo já tinha acabado.
  bool get _hasScore => match.homeScore != null && match.awayScore != null;

  bool get _isInProgress =>
      match.status == MatchStatus.live || match.status == MatchStatus.halftime;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // `toBrazilTime`, nunca `.toLocal()` (spec 2026-09-12).
    final kickoff = match.kickoff != null
        ? toBrazilTime(match.kickoff!)
        : null;
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    kickoff != null
                        ? '${shortDateLabel(kickoff, Localizations.localeOf(context).toString())} • ${weekdayShortLabel(kickoff, Localizations.localeOf(context).toString())}'
                        : context.l10n.matchDateToBeConfirmed,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (_isInProgress) _LiveBadge(status: match.status),
              ],
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
                          shortTeamName(match.homeTeam.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: _hasScore
                      ? Text(
                          '${match.homeScore} x ${match.awayScore}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                        )
                      : Text(
                          kickoff != null ? timeLabel(kickoff) : '--:--',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          shortTeamName(match.awayTeam.name),
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
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
                  Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: colors.textHint,
                  ),
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

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            matchStatusLabel(context.l10n, status).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

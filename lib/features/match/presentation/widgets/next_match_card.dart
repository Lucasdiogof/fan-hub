import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/match_status_label.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/live_pulse_dot.dart';

/// Versão funcional do "próximo jogo" para a aba Jogos — informação e
/// escaneabilidade em primeiro lugar, sem a fotografia/emoção do Hero da
/// Home (ver `NextMatchHero`). Mesmo componente conceitual, propósito
/// diferente: aqui o usuário está procurando dado, não se emocionando.
class NextMatchCard extends StatelessWidget {
  const NextMatchCard({
    required this.match,
    this.onBuyTicket,
    this.onViewDetails,
    super.key,
  });

  final Match match;
  final VoidCallback? onBuyTicket;
  final VoidCallback? onViewDetails;

  bool get _isLive =>
      match.status == MatchStatus.live || match.status == MatchStatus.halftime;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLive = _isLive;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isLive ? colors.primary.withValues(alpha: 0.4) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (isLive) ...[
                LivePulseDot(color: colors.primary),
                const SizedBox(width: 6),
              ],
              Text(
                isLive
                    ? [
                        matchStatusLabel(
                          context.l10n,
                          match.status,
                        ).toUpperCase(),
                        if (match.minute != null) match.minute!,
                      ].join(' · ')
                    : context.l10n.homeNextMatch,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              if (match.round.isNotEmpty)
                Text(
                  match.round.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: _TeamColumn(team: match.homeTeam)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child:
                    isLive && match.homeScore != null && match.awayScore != null
                    ? Text(
                        '${match.homeScore} x ${match.awayScore}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      )
                    : Text(
                        'X',
                        style: TextStyle(
                          color: colors.textHint,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
              Expanded(child: _TeamColumn(team: match.awayTeam)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(height: 1, color: colors.border),
          const SizedBox(height: AppSpacing.lg),
          if (!isLive)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (match.kickoff != null) ...[
                  _InfoItem(
                    icon: Icons.calendar_today_outlined,
                    label:
                        '${shortDateLabel(match.kickoff!, Localizations.localeOf(context).toString())} • ${weekdayShortLabel(match.kickoff!, Localizations.localeOf(context).toString())}',
                  ),
                  _Dot(color: colors.textHint),
                  _InfoItem(
                    icon: Icons.access_time_rounded,
                    label: timeLabel(match.kickoff!),
                  ),
                ] else
                  _InfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: context.l10n.matchDateToBeConfirmed,
                  ),
                if (match.stadium.isNotEmpty) ...[
                  _Dot(color: colors.textHint),
                  _InfoItem(
                    icon: Icons.location_on_outlined,
                    label: match.stadium,
                  ),
                ],
              ],
            )
          else if (match.stadium.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: match.stadium,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          if (isLive)
            ElevatedButton(
              onPressed: onViewDetails,
              style: matchCtaFilledStyle(context).merge(
                ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              child: Text(context.l10n.matchFollowLive),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBuyTicket,
                    style: matchCtaFilledStyle(context).merge(
                      ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(context.l10n.matchBuyTicket, maxLines: 1),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: matchCtaOutlineStyle(context).merge(
                      OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(context.l10n.matchDetailsShort, maxLines: 1),
                    ),
                  ),
                ),
              ],
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
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClubBadge(team: team, size: 52),
        const SizedBox(height: AppSpacing.sm),
        Text(
          shortTeamName(team.name).toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

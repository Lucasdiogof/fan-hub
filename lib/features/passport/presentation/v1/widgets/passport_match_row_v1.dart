import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_outcome_pill.dart';
import 'package:goias_app/shared/utils/date_labels.dart';

/// Uma partida na lista — nunca mostra `null`/texto quebrado quando falta
/// horário ou estádio: só oculta a linha. Partida agendada nunca tem
/// controle de marcação (regra vem do servidor via `canMarkAttendance`,
/// aqui só reflete visualmente).
class PassportMatchRowV1 extends StatelessWidget {
  const PassportMatchRowV1({
    required this.match,
    required this.attended,
    required this.onToggle,
    super.key,
  });

  final PassportMatch match;
  final bool attended;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final canMark = match.canMarkAttendance;
    final home = match.homeTeam;
    final away = match.awayTeam;
    final matchupLabel = (home != null && away != null)
        ? '$home x $away'
        : '${sl<ClubConfig>().identity.shortName} x ${match.opponent}';
    final hasScore = match.homeScore != null && match.awayScore != null;

    return Semantics(
      button: canMark,
      checked: canMark ? attended : null,
      label: matchupLabel,
      child: InkWell(
        onTap: canMark ? onToggle : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelectionControl(
                enabled: canMark,
                checked: attended,
                onTap: canMark ? onToggle : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          match.matchDate == null
                              ? l10n.matchDateToBeConfirmed
                              : fullDateLabel(match.matchDate!),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textHint,
                          ),
                        ),
                        if (match.matchTime != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            match.matchTime!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textHint,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (match.status == PassportMatchStatus.scheduled)
                          _StatusTag(label: l10n.passportStatusScheduled)
                        else if (match.status == PassportMatchStatus.postponed)
                          _StatusTag(label: l10n.passportStatusPostponed)
                        else if (match.status == PassportMatchStatus.cancelled)
                          _StatusTag(label: l10n.passportStatusCancelled),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            matchupLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (hasScore) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${match.homeScore}-${match.awayScore}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                        if (match.outcome != null) ...[
                          const SizedBox(width: 6),
                          PassportOutcomePill(outcome: match.outcome),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        match.competition,
                        if (match.round != null) match.round!,
                        if (match.venueName != null) match.venueName!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionControl extends StatelessWidget {
  const _SelectionControl({
    required this.enabled,
    required this.checked,
    required this.onTap,
  });

  final bool enabled;
  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: !enabled
                ? colors.secondary.withValues(alpha: 0.4)
                : (checked ? colors.primary : colors.surface),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: !enabled
                  ? colors.border
                  : (checked ? colors.primary : colors.border),
              width: 1.5,
            ),
          ),
          child: checked && enabled
              ? Icon(Icons.check_rounded, size: 15, color: colors.onPrimary)
              : null,
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

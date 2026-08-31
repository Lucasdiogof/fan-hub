import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/shared/utils/date_labels.dart';

/// Resumo do usuário — nunca mostra contador de estádios (os dados
/// históricos não têm `venue_id` preenchido ainda; mostrar "0 estádios"
/// seria informação errada, não só incompleta).
class PassportSummaryCardV1 extends StatelessWidget {
  const PassportSummaryCardV1({required this.summary, super.key});

  final PassportSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasDates =
        summary.firstMarkedMatchDate != null &&
        summary.lastMarkedMatchDate != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(
                    value: '${summary.totalMatches}',
                    label: l10n.passportSummaryTotalMatches,
                  ),
                ),
                VerticalDivider(width: 1, color: colors.border),
                Expanded(
                  child: _Stat(
                    value: '${summary.yearsWithAttendance}',
                    label: l10n.passportSummaryYearsCount,
                  ),
                ),
              ],
            ),
          ),
          if (hasDates) ...[
            Divider(height: 1, color: colors.border),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Stat(
                      value: fullDateLabel(summary.firstMarkedMatchDate!),
                      label: l10n.passportSummaryFirstMatch,
                      big: false,
                    ),
                  ),
                  VerticalDivider(width: 1, color: colors.border),
                  Expanded(
                    child: _Stat(
                      value: fullDateLabel(summary.lastMarkedMatchDate!),
                      label: l10n.passportSummaryLastMatch,
                      big: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.big = true});

  final String value;
  final String label;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: big ? 22 : 14,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/shared/utils/date_labels.dart';

/// Três indicadores editoriais lado a lado — nunca um grid 2x2 em card.
/// Fica direto sobre o fundo (sem borda/sombra própria): a hierarquia vem
/// da tipografia, não de mais uma caixa.
class PassportIndicatorsV2 extends StatelessWidget {
  const PassportIndicatorsV2({required this.summary, super.key});

  final PassportSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final firstDate = summary.firstMarkedMatchDate;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Indicator(
              value: '${summary.totalMatches}',
              label: l10n.passportIndicatorMatches,
            ),
          ),
          VerticalDivider(width: 1, color: colors.border),
          Expanded(
            child: _Indicator(
              value: '${summary.yearsWithAttendance}',
              label: l10n.passportIndicatorYears,
            ),
          ),
          VerticalDivider(width: 1, color: colors.border),
          Expanded(
            child: _Indicator(
              value: firstDate != null ? fullDateLabel(firstDate) : '—',
              label: l10n.passportIndicatorFirstMatch,
              small: firstDate != null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.value,
    required this.label,
    this.small = false,
  });

  final String value;
  final String label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small ? 15 : 21,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

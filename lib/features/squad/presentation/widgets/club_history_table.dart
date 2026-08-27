import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/squad/domain/club_history_entry.dart';

const _yearsWidth = 92.0;
const _numberWidth = 50.0;

class ClubHistoryTable extends StatelessWidget {
  const ClubHistoryTable({required this.history, super.key});

  final List<ClubHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderRow(),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < history.length; i++)
            _EntryRow(entry: history[i], showDivider: i < history.length - 1),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: context.colors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _yearsWidth,
            child: Text(l10n.squadHistoryYears, style: style),
          ),
          Expanded(child: Text(l10n.squadHistoryClubs, style: style)),
          SizedBox(
            width: _numberWidth,
            child: Text(
              l10n.squadHistoryMatches,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(
              l10n.squadHistoryGoals,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.showDivider});

  final ClubHistoryEntry entry;
  final bool showDivider;

  String _n(int? value) => value?.toString() ?? '—';

  /// "abr/2012–jan/2013" -> "2012–2013"; "jan/2020–atual" -> "2020–atual".
  /// Períodos já em anos ("2021") ou com "atual" sozinho ficam intactos.
  static final _monthPrefix = RegExp('[a-zçã]{3}/', caseSensitive: false);

  String _yearsOnly(String period) => period.replaceAll(_monthPrefix, '');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highlight = entry.isGoias;
    final textColor = highlight ? colors.primary : colors.textPrimary;
    final l10n = context.l10n;
    final teamName = entry.loan
        ? '${entry.team} ${l10n.squadLoanTag}'
        : entry.team;
    final uncertain = entry.dataQuality != 'verified';

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _yearsWidth,
            child: Text(
              _yearsOnly(entry.period),
              style: TextStyle(
                fontSize: 13.5,
                color: highlight ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    teamName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                      height: 1.15,
                    ),
                  ),
                ),
                if (uncertain) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: entry.notes ?? l10n.squadDataUnconfirmed,
                    child: Icon(
                      entry.dataQuality == 'review'
                          ? Icons.error_outline_rounded
                          : Icons.help_outline_rounded,
                      size: 14,
                      color: colors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(
              _n(entry.appearances),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.5, color: textColor),
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(
              _n(entry.goals),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.5, color: textColor),
            ),
          ),
        ],
      ),
    );

    if (highlight) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        ),
        child: row,
      );
    }

    return Column(
      children: [
        row,
        if (showDivider) Divider(height: 1, color: colors.border),
      ],
    );
  }
}

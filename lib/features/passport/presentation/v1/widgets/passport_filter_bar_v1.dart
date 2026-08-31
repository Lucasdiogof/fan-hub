import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';

/// Dois eixos de filtro independentes e combináveis: status/lado (chips
/// principais) e competição (linha secundária, só aparece quando a
/// temporada atual tem mais de uma competição).
class PassportFilterBarV1 extends StatelessWidget {
  const PassportFilterBarV1({
    required this.state,
    required this.onFilterSelected,
    required this.onCompetitionSelected,
    super.key,
  });

  final PassportState state;
  final ValueChanged<PassportFilter> onFilterSelected;
  final ValueChanged<String?> onCompetitionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = <(PassportFilter, String)>[
      (PassportFilter.all, l10n.passportFilterAll),
      (PassportFilter.attended, l10n.passportFilterAttended),
      (PassportFilter.notAttended, l10n.passportFilterNotAttended),
      (PassportFilter.home, l10n.passportFilterHome),
      (PassportFilter.away, l10n.passportFilterAway),
    ];
    final competitions = state.availableCompetitions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final (value, label) = options[index];
              return _FilterChip(
                label: label,
                selected: state.filter == value,
                onTap: () => onFilterSelected(value),
              );
            },
          ),
        ),
        if (competitions.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: competitions.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _FilterChip(
                    label: l10n.passportFilterAllCompetitions,
                    selected: state.competitionFilter == null,
                    onTap: () => onCompetitionSelected(null),
                    small: true,
                  );
                }
                final code = competitions[index - 1];
                final displayName = state.matches
                    .firstWhere((m) => m.competitionCode == code)
                    .competition;
                return _FilterChip(
                  label: displayName,
                  selected: state.competitionFilter == code,
                  onTap: () => onCompetitionSelected(code),
                  small: true,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.small = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 10 : 12,
            vertical: 6,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: selected ? colors.onPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

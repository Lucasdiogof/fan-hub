import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';

/// Seletor horizontal de ano — só a contagem por temporada (nunca as
/// partidas) já vem carregada de `passport_seasons`, então trocar de ano
/// aqui é sempre leve.
class PassportYearSelectorV1 extends StatelessWidget {
  const PassportYearSelectorV1({
    required this.seasons,
    required this.selectedYear,
    required this.markedByYear,
    required this.onSelected,
    super.key,
  });

  final List<PassportSeason> seasons;
  final int? selectedYear;

  /// Contagem marcada pro ano atualmente selecionado (os outros anos ainda
  /// não carregaram partidas, então só mostram o total da temporada).
  final int Function(int year) markedByYear;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final season = seasons[index];
          final selected = season.season == selectedYear;
          return _YearChip(
            season: season,
            selected: selected,
            markedCount: selected ? markedByYear(season.season) : null,
            onTap: () => onSelected(season.season),
          );
        },
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({
    required this.season,
    required this.selected,
    required this.markedCount,
    required this.onTap,
  });

  final PassportSeason season;
  final bool selected;
  final int? markedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '${season.season}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          width: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${season.season}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? colors.onPrimary : colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                markedCount != null
                    ? '$markedCount/${season.finishedCount}'
                    : '${season.finishedCount}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? colors.onPrimary.withValues(alpha: 0.85)
                      : colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

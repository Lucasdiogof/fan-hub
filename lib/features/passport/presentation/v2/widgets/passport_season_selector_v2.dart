import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';

/// Seletor de temporada compacto — nunca uma fileira de botões grandes (são
/// 27 temporadas, não caberia). `‹ ›` andam um ano por vez; tocar no ano ou
/// em "Trocar temporada" abre a lista completa. `markedCountsByYear` só tem
/// os anos que o usuário já visitou nesta sessão (`passport_seasons` não
/// devolve contagem marcada por ano) — anos fora do cache mostram só o
/// total, nunca um "0" inventado.
class PassportSeasonSelectorV2 extends StatelessWidget {
  const PassportSeasonSelectorV2({
    required this.seasons,
    required this.selectedYear,
    required this.markedCountsByYear,
    required this.onSelected,
    super.key,
  });

  final List<PassportSeason> seasons;
  final int? selectedYear;
  final Map<int, int> markedCountsByYear;
  final ValueChanged<int> onSelected;

  void _openSheet(BuildContext context) {
    AppModalSheet.show<void>(
      context,
      builder: (sheetContext) => _SeasonSheet(
        seasons: seasons,
        selectedYear: selectedYear,
        markedCountsByYear: markedCountsByYear,
        onSelected: (year) {
          Navigator.of(sheetContext).pop();
          onSelected(year);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final index = seasons.indexWhere((s) => s.season == selectedYear);
    final current = index >= 0 ? seasons[index] : null;
    // Lista vem `order by season desc` — ano anterior é o PRÓXIMO índice.
    final hasPrevious = index >= 0 && index < seasons.length - 1;
    final hasNext = index > 0;

    return Row(
      children: [
        _StepButton(
          icon: Icons.chevron_left_rounded,
          enabled: hasPrevious,
          onTap: () => onSelected(seasons[index + 1].season),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _openSheet(context),
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                current != null ? '${current.season}' : '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.chevron_right_rounded,
          enabled: hasNext,
          onTap: () => onSelected(seasons[index - 1].season),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => _openSheet(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.passportChangeSeasonCta,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: enabled ? colors.textPrimary : colors.textHint,
        ),
      ),
    );
  }
}

class _SeasonSheet extends StatelessWidget {
  const _SeasonSheet({
    required this.seasons,
    required this.selectedYear,
    required this.markedCountsByYear,
    required this.onSelected,
  });

  final List<PassportSeason> seasons;
  final int? selectedYear;
  final Map<int, int> markedCountsByYear;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.passportChangeSeasonCta,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                itemCount: seasons.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
                itemBuilder: (context, index) {
                  final season = seasons[index];
                  final selected = season.season == selectedYear;
                  final marked = markedCountsByYear[season.season];
                  final hasAttendance = (marked ?? 0) > 0;
                  return InkWell(
                    onTap: () => onSelected(season.season),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          if (hasAttendance)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.stars_rounded,
                                size: 15,
                                color: colors.gold,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              '${season.season}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: selected
                                    ? colors.primary
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            marked != null
                                ? l10n.passportSeasonProgressLine(
                                    marked,
                                    season.finishedCount,
                                  )
                                : l10n.passportSeasonTotalOnly(
                                    season.finishedCount,
                                  ),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: colors.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';

String _filterLabel(BuildContext context, PassportFilter filter) {
  final l10n = context.l10n;
  return switch (filter) {
    PassportFilter.all => l10n.passportFilterAll,
    PassportFilter.attended => l10n.passportFilterAttended,
    PassportFilter.notAttended => l10n.passportFilterNotAttended,
    PassportFilter.home => l10n.passportFilterHome,
    PassportFilter.away => l10n.passportFilterAway,
    PassportFilter.neutral => l10n.passportFilterNeutral,
  };
}

/// Controle segmentado "Todos | Eu fui" + botão "Filtros" com badge quando
/// há filtro avançado ativo (qualquer coisa além de `all`/`attended`, ou
/// competição selecionada). O resumo ativo some pra nunca duplicar o que já
/// aparece no segmentado (`all`/`attended` puros não geram resumo).
class PassportFilterControlV2 extends StatelessWidget {
  const PassportFilterControlV2({
    required this.state,
    required this.onFilterChanged,
    required this.onCompetitionChanged,
    super.key,
  });

  final PassportState state;
  final ValueChanged<PassportFilter> onFilterChanged;
  final ValueChanged<String?> onCompetitionChanged;

  bool get _hasAdvancedFilter =>
      state.filter != PassportFilter.all &&
          state.filter != PassportFilter.attended ||
      state.competitionFilter != null;

  void _openSheet(BuildContext context) {
    AppModalSheet.show<void>(
      context,
      builder: (sheetContext) => _FilterSheet(
        state: state,
        onFilterChanged: (f) {
          Navigator.of(sheetContext).pop();
          onFilterChanged(f);
        },
        onCompetitionChanged: (c) {
          Navigator.of(sheetContext).pop();
          onCompetitionChanged(c);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Segmented(
                selectedAll: state.filter == PassportFilter.all,
                onSelectAll: () => onFilterChanged(PassportFilter.all),
                onSelectAttended: () =>
                    onFilterChanged(PassportFilter.attended),
                selectedAttended: state.filter == PassportFilter.attended,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            InkWell(
              onTap: () => _openSheet(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.passportFiltersCta,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (_hasAdvancedFilter) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_hasAdvancedFilter) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Flexible(
                child: Text(
                  l10n.passportFiltersActiveSummary(
                    [
                      if (state.filter != PassportFilter.all)
                        _filterLabel(context, state.filter),
                      if (state.competitionFilter != null)
                        state.matches
                            .firstWhere(
                              (m) => m.competitionCode == state.competitionFilter,
                            )
                            .competition,
                    ].join(' · '),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  onFilterChanged(PassportFilter.all);
                  onCompetitionChanged(null);
                },
                child: Text(
                  l10n.passportFiltersClear,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.selectedAll,
    required this.selectedAttended,
    required this.onSelectAll,
    required this.onSelectAttended,
  });

  final bool selectedAll;
  final bool selectedAttended;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectAttended;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: l10n.passportFilterAll,
              selected: selectedAll,
              onTap: onSelectAll,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: l10n.passportFilterImWasThere,
              selected: selectedAttended,
              onTap: onSelectAttended,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.state,
    required this.onFilterChanged,
    required this.onCompetitionChanged,
  });

  final PassportState state;
  final ValueChanged<PassportFilter> onFilterChanged;
  final ValueChanged<String?> onCompetitionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final competitions = state.availableCompetitions;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.passportFiltersCta,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final f in PassportFilter.values)
              _OptionTile(
                label: _filterLabel(context, f),
                selected: state.filter == f,
                onTap: () => onFilterChanged(f),
              ),
            if (competitions.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(color: colors.border),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.passportFilterAllCompetitions,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: colors.textHint,
                ),
              ),
              _OptionTile(
                label: l10n.passportFilterAllCompetitions,
                selected: state.competitionFilter == null,
                onTap: () => onCompetitionChanged(null),
              ),
              for (final code in competitions)
                _OptionTile(
                  label: state.matches
                      .firstWhere((m) => m.competitionCode == code)
                      .competition,
                  selected: state.competitionFilter == code,
                  onTap: () => onCompetitionChanged(code),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 19,
              color: selected ? colors.primary : colors.textHint,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? colors.primary : colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

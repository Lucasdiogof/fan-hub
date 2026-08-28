import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_filters.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

Map<String, String> _audienceLabels(AppLocalizations l10n) => {
  'masculine': l10n.storeAudienceMasculine,
  'feminine': l10n.storeAudienceFeminine,
  'kids': l10n.storeAudienceKids,
  'unisex': l10n.storeAudienceUnisex,
};

Map<String, String> _typeLabels(AppLocalizations l10n) => {
  'matchJersey': l10n.storeTypeMatchJersey,
  'goalkeeper': l10n.storeTypeGoalkeeper,
  'training': l10n.storeTypeTraining,
  'casual': l10n.storeTypeCasual,
  'accessory': l10n.storeTypeAccessory,
  'souvenir': l10n.storeTypeSouvenir,
};

/// Tamanhos são códigos universais (P/M/G...), não palavras — não entram
/// no pipeline de tradução.
const _sizeOptions = ['PP', 'P', 'M', 'G', 'GG', 'XG', 'ÚNICO'];

Future<void> showStoreFiltersSheet(
  BuildContext context, {
  required StoreListingFilters current,
  required ValueChanged<StoreListingFilters> onApply,
  required VoidCallback onClear,
}) {
  return AppModalSheet.show<void>(
    context,
    dialogMaxWidth: 480,
    builder: (_) => _StoreFiltersContent(
      current: current,
      onApply: onApply,
      onClear: onClear,
    ),
  );
}

Future<void> showStoreSortSheet(
  BuildContext context, {
  required StoreSortOrder current,
  required ValueChanged<StoreSortOrder> onChanged,
}) {
  return AppModalSheet.show<void>(
    context,
    dialogMaxWidth: 420,
    builder: (sheetContext) =>
        _StoreSortContent(current: current, onChanged: onChanged),
  );
}

class _StoreSortContent extends StatelessWidget {
  const _StoreSortContent({required this.current, required this.onChanged});

  final StoreSortOrder current;
  final ValueChanged<StoreSortOrder> onChanged;

  Map<StoreSortOrder, String> _labels(AppLocalizations l10n) => {
    StoreSortOrder.relevance: l10n.storeSortRelevance,
    StoreSortOrder.newest: l10n.storeSortNewest,
    StoreSortOrder.priceLowToHigh: l10n.storeSortPriceLowToHigh,
    StoreSortOrder.priceHighToLow: l10n.storeSortPriceHighToLow,
    StoreSortOrder.biggestDiscount: l10n.storeSortBiggestDiscount,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
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
            Semantics(
              header: true,
              child: Text(
                l10n.storeSortSheetTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textHint,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RadioGroup<StoreSortOrder>(
              groupValue: current,
              onChanged: (value) {
                if (value != null) onChanged(value);
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in _labels(l10n).entries)
                    RadioListTile<StoreSortOrder>(
                      value: entry.key,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: colors.primary,
                      title: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreFiltersContent extends StatefulWidget {
  const _StoreFiltersContent({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  final StoreListingFilters current;
  final ValueChanged<StoreListingFilters> onApply;
  final VoidCallback onClear;

  @override
  State<_StoreFiltersContent> createState() => _StoreFiltersContentState();
}

class _StoreFiltersContentState extends State<_StoreFiltersContent> {
  late Set<String> _audiences = {...widget.current.audiences};
  late Set<String> _types = {...widget.current.types};
  late Set<String> _editions = {...widget.current.uniformEditions};
  late Set<String> _sizes = {...widget.current.sizes};
  late bool _onlyAvailable = widget.current.onlyAvailable;
  late bool _onlyOnSale = widget.current.onlyOnSale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.storeFiltersSheetTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _audiences = {};
                        _types = {};
                        _editions = {};
                        _sizes = {};
                        _onlyAvailable = false;
                        _onlyOnSale = false;
                      });
                      widget.onClear();
                    },
                    child: Text(l10n.storeClearFilters),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterGroup(
                label: l10n.storeFilterAudienceLabel,
                options: _audienceLabels(l10n),
                selected: _audiences,
                onToggle: (key) => setState(() => _toggle(_audiences, key)),
              ),
              _FilterGroup(
                label: l10n.storeFilterTypeLabel,
                options: _typeLabels(l10n),
                selected: _types,
                onToggle: (key) => setState(() => _toggle(_types, key)),
              ),
              _FilterGroup(
                label: l10n.storeFilterUniformLabel,
                options: {
                  '01': l10n.storeUniform01,
                  '02': l10n.storeUniform02,
                  '03': l10n.storeUniform03,
                },
                selected: _editions,
                onToggle: (key) => setState(() => _toggle(_editions, key)),
              ),
              _FilterGroup(
                label: l10n.storeFilterSizeLabel,
                options: {for (final s in _sizeOptions) s: s},
                selected: _sizes,
                onToggle: (key) => setState(() => _toggle(_sizes, key)),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                value: _onlyAvailable,
                onChanged: (value) => setState(() => _onlyAvailable = value),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: colors.primary,
                title: Text(
                  l10n.storeFilterOnlyAvailable,
                  style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                ),
              ),
              SwitchListTile(
                value: _onlyOnSale,
                onChanged: (value) => setState(() => _onlyOnSale = value),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: colors.primary,
                title: Text(
                  l10n.storeFilterOnlyOnSale,
                  style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: l10n.storeApplyFilters,
                onPressed: () {
                  widget.onApply(
                    StoreListingFilters(
                      audiences: _audiences,
                      types: _types,
                      uniformEditions: _editions,
                      sizes: _sizes,
                      onlyAvailable: _onlyAvailable,
                      onlyOnSale: _onlyOnSale,
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(Set<String> set, String key) {
    if (!set.remove(key)) set.add(key);
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final Map<String, String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.textHint,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in options.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: selected.contains(entry.key),
                  onSelected: (_) => onToggle(entry.key),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected.contains(entry.key)
                        ? colors.onPrimary
                        : colors.textSecondary,
                  ),
                  selectedColor: colors.primary,
                  backgroundColor: colors.secondary,
                  side: BorderSide.none,
                  showCheckmark: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Um item selecionável do [SegmentedChipRow].
class SegmentedChipItem {
  const SegmentedChipItem({required this.id, required this.label});

  final String id;
  final String label;
}

/// Seletor compacto tipo segmented/chips, reutilizado tanto pelo
/// `CompetitionStageSelector` (`[Fase de Grupos][Eliminatórias]`) quanto
/// pelo seletor de rodada dentro do mata-mata (`[Oitavas][Quartas]...`) —
/// spec 2026-09-12, item 12: mesmo visual, estado ativo na cor do flavor,
/// inativos discretos, com scroll horizontal só no seletor (nunca na
/// tela). Some sozinho quando há 1 item só ou nenhum.
class SegmentedChipRow extends StatelessWidget {
  const SegmentedChipRow({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    super.key,
  });

  final List<SegmentedChipItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (items.length <= 1) return const SizedBox.shrink();
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final item in items) ...[
            _SegmentedChip(
              label: item.label,
              selected: item.id == selectedId,
              onTap: () => onSelected(item.id),
              colors: colors,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SegmentedChip extends StatelessWidget {
  const _SegmentedChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

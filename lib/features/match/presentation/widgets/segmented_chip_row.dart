import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';

/// Um item selecionável do [SegmentedChipRow].
class SegmentedChipItem {
  const SegmentedChipItem({required this.id, required this.label});

  final String id;
  final String label;
}

/// Seletor de fase/rodada (`[Fase de Grupos][Eliminatórias]`,
/// `[Oitavas][Quartas]...`) — usa o mesmo [FanHubTabBar] do resto do app
/// (vira faixa rolável só quando os rótulos não cabem). Some sozinho quando
/// há 1 item só ou nenhum.
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
    return FanHubTabBar(
      labels: [for (final item in items) item.label],
      selectedIndex: items.indexWhere((item) => item.id == selectedId),
      onChanged: (index) => onSelected(items[index].id),
      padding: padding,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_items.dart';

/// Equivalente da `MainBottomNavigation` pra telas expandidas/largas —
/// mesmas 5 abas, mesmos ícones/rótulos (ver `main_navigation_items.dart`),
/// só a apresentação muda (rail lateral fixo em vez de barra inferior).
/// Nunca aparece sozinha: `HomeShellPage` escolhe UMA das duas conforme
/// `context.isAtLeastExpanded`, nunca as duas ao mesmo tempo.
class MainNavigationRail extends StatelessWidget {
  const MainNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = mainNavItems(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: 96,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < items.length; i++)
                _RailItem(
                  data: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final MainNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: selected ? colors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? data.selectedIcon : data.icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

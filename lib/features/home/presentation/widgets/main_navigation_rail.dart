import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_items.dart';

/// Equivalente da `GoiasBottomNavigationBar` pra telas expandidas/largas —
/// mesmas 5 abas, mesmos ícones/rótulos (ver `main_navigation_items.dart`),
/// só a apresentação muda (rail lateral fixo em vez de barra inferior).
/// Nunca aparece junto com a bottom nav: `HomeShellPage` escolhe UMA das
/// duas conforme `context.isAtLeastExpanded`. Também é reaproveitada por
/// `DesktopShellFrame` pra manter o mesmo rail nas rotas internas.
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
    final capabilities = sl<ClubConfig>().capabilities;
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
              // M4.2A — aba sem capability nunca aparece no rail (o rail,
              // ao contrário da bottom nav, não tem geometria fixa a
              // preservar, então pode simplesmente omitir o item).
              for (var i = 0; i < items.length; i++)
                if (isTabEnabled(i, capabilities))
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

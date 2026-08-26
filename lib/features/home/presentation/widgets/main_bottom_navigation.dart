import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Bottom nav própria — sem o indicator-pill padrão do `NavigationBar` do
/// Material. Item ativo só muda de cor (ícone + rótulo); nenhum outro
/// tratamento além disso.
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({required this.selectedIndex, required this.onSelected, super.key});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItemData(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded),
    _NavItemData(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
    ),
    _NavItemData(icon: Icons.badge_outlined, selectedIcon: Icons.badge_rounded),
    _NavItemData(
      icon: Icons.ondemand_video_outlined,
      selectedIcon: Icons.ondemand_video_rounded,
    ),
    _NavItemData(
      icon: Icons.sports_esports_outlined,
      selectedIcon: Icons.sports_esports_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final labels = [
      l10n.navHome,
      l10n.navMatches,
      l10n.navMembership,
      l10n.navMedia,
      l10n.navArena,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: _items[i],
                    label: labels[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.selectedIcon});

  final IconData icon;
  final IconData selectedIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? data.selectedIcon : data.icon, size: 22, color: color),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

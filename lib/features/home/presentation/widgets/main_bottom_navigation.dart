import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Bottom nav própria — sem o indicator-pill padrão do `NavigationBar` do
/// Material. Item ativo só muda de cor (ícone + rótulo); nenhum outro
/// tratamento além disso.
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({required this.selectedIndex, required this.onSelected, super.key});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItemData(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Início'),
    _NavItemData(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Jogos',
    ),
    _NavItemData(
      icon: Icons.confirmation_number_outlined,
      selectedIcon: Icons.confirmation_number_rounded,
      label: 'Ingressos',
    ),
    _NavItemData(icon: Icons.badge_outlined, selectedIcon: Icons.badge_rounded, label: 'Sócio'),
    _NavItemData(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
  const _NavItemData({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.data, required this.selected, required this.onTap});

  final _NavItemData data;
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
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

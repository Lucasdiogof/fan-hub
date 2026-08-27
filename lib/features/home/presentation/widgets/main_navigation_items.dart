import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';

/// Ícone (normal/selecionado) + rótulo de cada aba do shell principal —
/// fonte única usada tanto pelo `MainBottomNavigation` (mobile/tablet)
/// quanto pelo `MainNavigationRail` (desktop), pra nunca ter as duas
/// listas divergindo.
class MainNavItemData {
  const MainNavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

List<MainNavItemData> mainNavItems(BuildContext context) {
  final l10n = context.l10n;
  return [
    MainNavItemData(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: l10n.navHome,
    ),
    MainNavItemData(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: l10n.navMatches,
    ),
    MainNavItemData(
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge_rounded,
      label: l10n.navMembership,
    ),
    MainNavItemData(
      icon: Icons.ondemand_video_outlined,
      selectedIcon: Icons.ondemand_video_rounded,
      label: l10n.navMedia,
    ),
    MainNavItemData(
      icon: Icons.sports_esports_outlined,
      selectedIcon: Icons.sports_esports_rounded,
      label: l10n.navArena,
    ),
  ];
}

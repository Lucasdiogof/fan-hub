import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';

/// Índices das 5 abas do shell principal — Home ocupa o centro (2), não a
/// primeira posição. Único lugar que define essa ordem; todo código que
/// precisa saber "essa é a aba X" (recarregar ao voltar pra ela, navegar
/// programaticamente pra ela, destacar no rail) usa essas constantes em vez
/// de um número mágico.
const jogosTabIndex = 0;
const socioTabIndex = 1;
const homeTabIndex = 2;
const lojaTabIndex = 3;
const midiaTabIndex = 4;

/// Ícone (normal/selecionado) + rótulo de cada aba do shell principal —
/// fonte única usada tanto pelo `GoiasBottomNavigationBar` (mobile/tablet)
/// quanto pelo `MainNavigationRail` (desktop), pra nunca ter as duas
/// listas divergindo. A entrada de Home mantém ícone/rótulo genéricos pro
/// rail (que não tem o tratamento especial de escudo) — só a bottom nav
/// ignora `icon`/`label` no índice [homeTabIndex] e desenha o escudo.
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

List<MainNavItemData> mainNavItems(
  BuildContext context,
  ClubCapabilities capabilities,
) {
  final l10n = context.l10n;
  final items = List<MainNavItemData>.filled(
    5,
    const MainNavItemData(
      icon: Icons.circle,
      selectedIcon: Icons.circle,
      label: '',
    ),
  );
  items[jogosTabIndex] = MainNavItemData(
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    label: l10n.navMatches,
  );
  // Sócio some enquanto `hasMembership` for false (envio às lojas) — o
  // slot nunca fica vazio, vira O Clube nesse meio-tempo (ver
  // `isTabEnabled`/`home_shell_page.dart`).
  items[socioTabIndex] = capabilities.hasMembership
      ? MainNavItemData(
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge_rounded,
          label: l10n.navMembership,
        )
      : const MainNavItemData(
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield_rounded,
          label: 'Clube',
        );
  items[homeTabIndex] = MainNavItemData(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: l10n.navHome,
  );
  // Loja some enquanto `hasStore` for false — vira Arena no mesmo espírito
  // do Sócio/Clube acima.
  items[lojaTabIndex] = capabilities.hasStore
      ? MainNavItemData(
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag_rounded,
          label: l10n.navStore,
        )
      : const MainNavItemData(
          icon: Icons.sports_esports_outlined,
          selectedIcon: Icons.sports_esports_rounded,
          label: 'Arena',
        );
  items[midiaTabIndex] = MainNavItemData(
    icon: Icons.ondemand_video_outlined,
    selectedIcon: Icons.ondemand_video_rounded,
    label: l10n.navMedia,
  );
  return items;
}

/// M4.2A — se a aba [index] deve aparecer/ser navegável pro clube ativo.
/// Home nunca é gateada (é o núcleo do produto, sem capability dedicada) —
/// Jogos/Mídia sim. Sócio/Loja SEMPRE aparecem: quando a capability real
/// está desligada (envio às lojas), o slot mostra O Clube/Arena em vez de
/// sumir (ver `mainNavItems`/`home_shell_page.dart`) — nunca um buraco na
/// barra. Mídia (Notícias + Instagram/YouTube/X) fica visível se QUALQUER
/// uma das duas capabilities dela estiver ligada — a granularidade de qual
/// filtro aparece DENTRO da aba é decidida por `SocialFeedPage`, não aqui.
bool isTabEnabled(int index, ClubCapabilities capabilities) {
  return switch (index) {
    jogosTabIndex => capabilities.hasMatches,
    midiaTabIndex => capabilities.hasNews || capabilities.hasSocial,
    _ => true,
  };
}

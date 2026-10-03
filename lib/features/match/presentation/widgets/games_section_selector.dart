import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/match/presentation/widgets/games_section.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';

/// Abas Partidas / Calendário / Classificação — visual único do app
/// ([FanHubTabBar]); a seleção continua vindo de [GamesSection].
class GamesSectionSelector extends StatelessWidget {
  const GamesSectionSelector({
    required this.section,
    required this.onChanged,
    super.key,
  });

  final GamesSection section;
  final ValueChanged<GamesSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FanHubTabBar(
      labels: [
        l10n.matchTabMatches,
        l10n.matchTabCalendar,
        l10n.matchTabStandings,
      ],
      selectedIndex: GamesSection.values.indexOf(section),
      onChanged: (index) => onChanged(GamesSection.values[index]),
    );
  }
}

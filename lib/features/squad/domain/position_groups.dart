import 'package:goias_app/l10n/app_localizations.dart';

const positionGroupOrder = [
  'Goleiros',
  'Zagueiros',
  'Laterais-direitos',
  'Laterais-esquerdos',
  'Volantes',
  'Meios-campistas',
  'Atacantes',
];

String positionGroupLabel(String group, AppLocalizations l10n) {
  return switch (group) {
    'Goleiros' => l10n.squadGroupGoalkeepers,
    'Zagueiros' => l10n.squadGroupDefenders,
    'Laterais-direitos' => l10n.squadGroupRightBacks,
    'Laterais-esquerdos' => l10n.squadGroupLeftBacks,
    'Volantes' => l10n.squadGroupDefensiveMids,
    'Meios-campistas' => l10n.squadGroupMidfielders,
    'Atacantes' => l10n.squadGroupForwards,
    _ => group,
  };
}

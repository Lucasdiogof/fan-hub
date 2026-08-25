/// Um grupo de títulos da mesma competição — nunca mistura vice-campeonatos
/// aqui (esses vivem em [ClubHistoricalCampaign]).
class ClubTitleGroup {
  const ClubTitleGroup({required this.competitionName, required this.years});

  final String competitionName;
  final List<int> years;

  int get count => years.length;
}

/// Campanha histórica relevante que NÃO foi título — 3º lugar, vice, uma
/// participação inédita. Mostrada separada dos troféus de verdade.
class ClubHistoricalCampaign {
  const ClubHistoricalCampaign({required this.year, required this.title});

  final int year;
  final String title;
}

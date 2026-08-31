/// Um grupo de títulos da mesma competição — nunca mistura vice-campeonatos
/// aqui (esses vivem em [ClubHistoricalCampaign]).
class ClubTitleGroup {
  const ClubTitleGroup({
    required this.competitionName,
    required this.years,
    this.images = const [],
  });

  final String competitionName;
  final List<int> years;

  /// Caminhos das fotos do carrossel de "momentos históricos" — vazio até
  /// termos fotos de verdade. Nunca preenchido com placeholder: lista
  /// vazia = carrossel não aparece.
  final List<String> images;

  int get count => years.length;
}

/// Campanha histórica relevante que NÃO foi título — 3º lugar, vice, uma
/// participação inédita. Mostrada separada dos troféus de verdade.
class ClubHistoricalCampaign {
  const ClubHistoricalCampaign({
    required this.year,
    required this.title,
    this.images = const [],
  });

  final int year;
  final String title;
  final List<String> images;
}

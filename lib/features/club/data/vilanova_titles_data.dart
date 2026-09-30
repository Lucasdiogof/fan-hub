import 'package:goias_app/features/club/domain/entities/club_title_group.dart';

/// Fonte: `docs/vila_nova_data/data/honors.json`, que segue o acervo oficial
/// (vilanovafc.com.br/titulos). Só grupos `READY`. `images` vazio em todos:
/// ainda não há foto real de nenhuma conquista (ASSET_GAP), e a UI já
/// trata título sem imagem.
///
/// Fora de propósito (DATA_GAP, não omissão silenciosa):
///   * Torneio Início Goiano e Torneio Goiânia-Anápolis — o acervo lista,
///     mas falta classificar como oficial x amistoso (REVIEW no pacote);
///   * Quadrangular Internacional Joaquim Coelho (1970) — torneio amistoso,
///     aparece só na linha do tempo.
///
/// Goiano: o site oficial lista 16 títulos (a Wikipedia cita 17). Seguimos o
/// oficial; a divergência está registrada no pacote.
///
/// Segunda Divisão Goiana 2015 conferida na FGF ("Vila Nova é campeão da
/// Divisão de Acesso/2015"): o clube caiu no Goiano de 2014.
class VilaNovaTitlesData {
  const VilaNovaTitlesData._();

  static const List<ClubTitleGroup> groups = [
    ClubTitleGroup(
      competitionName: 'Campeonato Brasileiro Série C',
      years: [1996, 2015, 2020],
    ),
    ClubTitleGroup(
      competitionName: 'Campeonato Goiano',
      years: [
        1961,
        1962,
        1963,
        1969,
        1973,
        1977,
        1978,
        1979,
        1980,
        1982,
        1984,
        1993,
        1995,
        2001,
        2005,
        2025,
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Segunda Divisão Goiana',
      years: [2000, 2015],
    ),
    ClubTitleGroup(competitionName: 'Copa Goiás', years: [1969, 1971, 1976]),
    ClubTitleGroup(
      competitionName: 'Copa Leonino Caiado',
      years: [1977, 1979, 1981],
    ),
    ClubTitleGroup(
      competitionName: 'Taça Cidade de Goiânia',
      years: [1961, 1962, 1972],
    ),
    ClubTitleGroup(competitionName: 'Taça Goiás', years: [1966]),
  ];

  /// Vice-campeonatos — nunca contam como título. Os vices da Copa
  /// Centro-Oeste (1999–2001) ficam de fora até sair do REVIEW no pacote.
  static const List<ClubHistoricalCampaign> historicalCampaigns = [
    ClubHistoricalCampaign(year: 2021, title: 'Vice-campeão da Copa Verde'),
    ClubHistoricalCampaign(year: 2022, title: 'Vice-campeão da Copa Verde'),
    ClubHistoricalCampaign(year: 2024, title: 'Vice-campeão da Copa Verde'),
  ];
}

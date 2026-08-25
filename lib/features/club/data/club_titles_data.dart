import 'package:goias_app/features/club/domain/entities/club_title_group.dart';

/// Fonte: https://www.goiasec.com.br/titulos — 34 títulos principais no
/// total. Vice-campeonatos e campanhas de destaque NUNCA entram aqui,
/// só em [historicalCampaigns].
class ClubTitlesData {
  const ClubTitlesData._();

  static const List<ClubTitleGroup> groups = [
    ClubTitleGroup(
      competitionName: 'Campeonato Goiano',
      years: [
        1966,
        1971,
        1972,
        1975,
        1976,
        1981,
        1983,
        1986,
        1987,
        1989,
        1990,
        1991,
        1994,
        1996,
        1997,
        1998,
        1999,
        2000,
        2002,
        2003,
        2006,
        2009,
        2012,
        2013,
        2015,
        2016,
        2017,
        2018,
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Copa Centro-Oeste',
      years: [2000, 2001, 2002],
    ),
    ClubTitleGroup(
      competitionName: 'Campeonato Brasileiro Série B',
      years: [1999, 2012],
    ),
    ClubTitleGroup(competitionName: 'Copa Verde', years: [2023]),
  ];

  static int get totalTitles =>
      groups.fold(0, (sum, group) => sum + group.count);

  static const List<ClubHistoricalCampaign> historicalCampaigns = [
    ClubHistoricalCampaign(year: 1990, title: 'Vice-campeão da Copa do Brasil'),
    ClubHistoricalCampaign(
      year: 2005,
      title: '3º colocado no Campeonato Brasileiro',
    ),
    ClubHistoricalCampaign(year: 2006, title: 'Participação na Libertadores'),
    ClubHistoricalCampaign(
      year: 2010,
      title: 'Vice-campeão da Copa Sul-Americana',
    ),
  ];
}

import 'package:goias_app/features/club/domain/entities/club_title_group.dart';

/// Fonte: https://www.goiasec.com.br/titulos, com o Campeonato Goiano 2026
/// acrescentado manualmente. Vice-campeonatos e campanhas de destaque NUNCA
/// entram aqui, só em [historicalCampaigns].
///
/// Fotos do carrossel de "momentos históricos": uma pasta por competição/
/// campanha em `lib/assets/club/titles/<slug>/`, arquivos numerados
/// sequencialmente (`01`, `02`...) já que não há legenda por foto (a tela
/// só mostra a foto no card e o nome da competição/campanha na
/// visualização em tela cheia). Pasta nova precisa entrar em
/// `pubspec.yaml > flutter > assets` antes de referenciar aqui.
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
        2026,
      ],
      images: [
        'lib/assets/club/titles/campeonato-goiano/01.webp',
        'lib/assets/club/titles/campeonato-goiano/02.webp',
        'lib/assets/club/titles/campeonato-goiano/03.webp',
        'lib/assets/club/titles/campeonato-goiano/04.webp',
        'lib/assets/club/titles/campeonato-goiano/05.webp',
        'lib/assets/club/titles/campeonato-goiano/06.jpg',
        'lib/assets/club/titles/campeonato-goiano/07.png',
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Copa Centro-Oeste',
      years: [2000, 2001, 2002],
      images: [
        'lib/assets/club/titles/copa-centro-oeste/01.jpg',
        'lib/assets/club/titles/copa-centro-oeste/02.jpg',
        'lib/assets/club/titles/copa-centro-oeste/03.jpg',
        'lib/assets/club/titles/copa-centro-oeste/04.jpg',
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Campeonato Brasileiro Série B',
      years: [1999, 2012],
      images: [
        'lib/assets/club/titles/serie-b/01.jpg',
        'lib/assets/club/titles/serie-b/02.webp',
        'lib/assets/club/titles/serie-b/03.jpg',
        'lib/assets/club/titles/serie-b/04.jpg',
        'lib/assets/club/titles/serie-b/05.webp',
        'lib/assets/club/titles/serie-b/06.png',
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Copa Verde',
      years: [2023],
      images: [
        'lib/assets/club/titles/copa-verde/01.png',
        'lib/assets/club/titles/copa-verde/02.jpeg',
        'lib/assets/club/titles/copa-verde/03.jpg',
        'lib/assets/club/titles/copa-verde/04.jpg',
        'lib/assets/club/titles/copa-verde/05.jpg',
      ],
    ),
  ];

  static int get totalTitles =>
      groups.fold(0, (sum, group) => sum + group.count);

  static const List<ClubHistoricalCampaign> historicalCampaigns = [
    ClubHistoricalCampaign(
      year: 1990,
      title: 'Vice-campeão da Copa do Brasil',
      images: [
        'lib/assets/club/titles/copa-do-brasil-1990/01.jpg',
        'lib/assets/club/titles/copa-do-brasil-1990/02.jpeg',
        'lib/assets/club/titles/copa-do-brasil-1990/03.jpg',
        'lib/assets/club/titles/copa-do-brasil-1990/04.jpg',
      ],
    ),
    ClubHistoricalCampaign(
      year: 2005,
      title: '3º colocado no Campeonato Brasileiro',
      images: [
        'lib/assets/club/titles/brasileirao-2005/01.png',
        'lib/assets/club/titles/brasileirao-2005/02.jpg',
        'lib/assets/club/titles/brasileirao-2005/03.png',
        'lib/assets/club/titles/brasileirao-2005/04.jpg',
      ],
    ),
    ClubHistoricalCampaign(
      year: 2006,
      title: 'Participação na Libertadores',
      images: [
        'lib/assets/club/titles/libertadores-2006/01.jpg',
        'lib/assets/club/titles/libertadores-2006/02.jpg',
        'lib/assets/club/titles/libertadores-2006/03.webp',
        'lib/assets/club/titles/libertadores-2006/04.jpg',
      ],
    ),
    ClubHistoricalCampaign(
      year: 2010,
      title: 'Vice-campeão da Copa Sul-Americana',
      images: [
        'lib/assets/club/titles/sula-2010/01.png',
        'lib/assets/club/titles/sula-2010/02.png',
        'lib/assets/club/titles/sula-2010/03.png',
        'lib/assets/club/titles/sula-2010/04.png',
        'lib/assets/club/titles/sula-2010/05.png',
        'lib/assets/club/titles/sula-2010/06.png',
        'lib/assets/club/titles/sula-2010/07.png',
        'lib/assets/club/titles/sula-2010/08.png',
        'lib/assets/club/titles/sula-2010/09.png',
        'lib/assets/club/titles/sula-2010/10.png',
      ],
    ),
  ];
}

import 'package:goias_app/features/club/domain/entities/club_title_group.dart';

/// Fonte: https://www.goiasec.com.br/titulos, com o Campeonato Goiano 2026
/// acrescentado manualmente. Vice-campeonatos e campanhas de destaque NUNCA
/// entram aqui, só em [historicalCampaigns].
///
/// Fotos do carrossel de "momentos históricos": arquivos soltos direto em
/// `lib/assets/` (a pasta já é registrada inteira no `pubspec.yaml`, sem
/// precisar de entrada nova por subpasta), agrupados por prefixo do nome —
/// `goianao*` (Campeonato Goiano), `copa co*` (Copa Centro-Oeste),
/// `serie b*` (Série B), `copa verde*` (Copa Verde), `cdb*` (Copa do
/// Brasil 1990), `libertadores*` (Libertadores 2006), `sula*`/`sula_2010_*`
/// (Sul-Americana 2010). Sem legenda por foto de propósito — a tela só
/// mostra a foto no card e o título da competição/campanha (já existente
/// aqui) na visualização em tela cheia.
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
        'lib/assets/goianao.jpg',
        'lib/assets/goianao2.webp',
        'lib/assets/goianao3.webp',
        'lib/assets/goianao4.webp',
        'lib/assets/goianao5.webp',
        'lib/assets/goianao6.webp',
        'lib/assets/goianao7.png',
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Copa Centro-Oeste',
      years: [2000, 2001, 2002],
      images: [
        'lib/assets/copa co.jpg',
        'lib/assets/copa co 2.jpg',
        'lib/assets/copa co 3.jpg',
        'lib/assets/copa co 4.jpg',
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Campeonato Brasileiro Série B',
      years: [1999, 2012],
      images: [
        'lib/assets/serie b.jpg',
        'lib/assets/serie b 2.webp',
        'lib/assets/serie b 3.jpg',
        'lib/assets/serie b 4.jpg',
        'lib/assets/serie b 5.webp',
        'lib/assets/serie b 6.png',
      ],
    ),
    ClubTitleGroup(
      competitionName: 'Copa Verde',
      years: [2023],
      images: [
        'lib/assets/copa verde.png',
        'lib/assets/copa verde 2.jpeg',
        'lib/assets/copa verde 3.jpg',
        'lib/assets/copa verde 4.jpg',
        'lib/assets/copa verde 5.jpg',
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
        'lib/assets/cdb.jpg',
        'lib/assets/cdb.jpeg',
        'lib/assets/cdb 2.jpg',
        'lib/assets/cdb 4.jpg',
      ],
    ),
    ClubHistoricalCampaign(
      year: 2005,
      title: '3º colocado no Campeonato Brasileiro',
    ),
    ClubHistoricalCampaign(
      year: 2006,
      title: 'Participação na Libertadores',
      images: [
        'lib/assets/libertadores.jpg',
        'lib/assets/libertadores 2.jpg',
        'lib/assets/libertadores 3.webp',
        'lib/assets/libertadores 4.jpg',
      ],
    ),
    ClubHistoricalCampaign(
      year: 2010,
      title: 'Vice-campeão da Copa Sul-Americana',
      images: [
        'lib/assets/sula.png',
        'lib/assets/sula 2.png',
        'lib/assets/sula 3.png',
        'lib/assets/sula 4.png',
        'lib/assets/sula 5.png',
        'lib/assets/sula 6.png',
        'lib/assets/sula_2010_lance_marcante_01.png',
        'lib/assets/sula_2010_lance_marcante_02.png',
        'lib/assets/sula_2010_palmeiras_semifinal_comemoracao.png',
        'lib/assets/sula_2010_penarol_comemoracao_montevideu.png',
      ],
    ),
  ];
}

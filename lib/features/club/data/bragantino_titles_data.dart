import 'package:goias_app/features/club/domain/entities/club_title_group.dart';

/// Fonte: https://en.wikipedia.org/wiki/Red_Bull_Bragantino (seção
/// "Honours"), pesquisado em 2026-09-05. `images` vazio em TODOS os
/// grupos de propósito — ainda não temos foto real de nenhuma conquista
/// do Bragantino (ASSET_GAP), e o modelo/UI (`ClubTitleGroup`/
/// `ClubTitlesPage`) já suporta título sem imagem: só o carrossel some,
/// a conquista continua contando normalmente.
///
/// "Torneio Início" (1991, achado numa única fonte, sem confirmação
/// cruzada) foi deixado de fora por enquanto — DATA_GAP, não uma omissão
/// silenciosa: é um torneio menor demais pra entrar sem segunda fonte.
class BragantinoTitlesData {
  const BragantinoTitlesData._();

  static const List<ClubTitleGroup> groups = [
    ClubTitleGroup(
      competitionName: 'Campeonato Brasileiro Série B',
      years: [1989, 2019],
    ),
    ClubTitleGroup(
      competitionName: 'Campeonato Brasileiro Série C',
      years: [2007],
    ),
    ClubTitleGroup(competitionName: 'Campeonato Paulista', years: [1990]),
    ClubTitleGroup(
      competitionName: 'Campeonato Paulista Série A2',
      years: [1965, 1988],
    ),
    ClubTitleGroup(
      competitionName: 'Campeonato Paulista Segunda Divisão',
      years: [1979],
    ),
    ClubTitleGroup(
      competitionName: 'Campeonato Paulista do Interior',
      years: [2020],
    ),
  ];

  /// Vice-campeonatos e campanhas de destaque — nunca contam como título
  /// (ver [groups] acima e o comentário de classe de [ClubTitleGroup]).
  static const List<ClubHistoricalCampaign> historicalCampaigns = [
    ClubHistoricalCampaign(
      year: 1991,
      title: 'Vice-campeão do Campeonato Brasileiro',
    ),
    ClubHistoricalCampaign(
      year: 2021,
      title: 'Vice-campeão da Copa Sul-Americana',
    ),
    ClubHistoricalCampaign(
      year: 2022,
      title: 'Estreia na fase de grupos da Copa Libertadores',
    ),
  ];
}

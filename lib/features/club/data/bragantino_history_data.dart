import 'package:goias_app/features/club/domain/entities/club_history_section.dart';

/// Fontes: https://www.redbullbragantino.com/br-pt/historia (site oficial),
/// cruzado com https://en.wikipedia.org/wiki/Red_Bull_Bragantino pra datas
/// exatas — pesquisado e redigido com palavras próprias em 2026-09-05.
/// Cobre até a estreia na fase de grupos da Libertadores (2022); marcos
/// mais recentes (2023 em diante) ainda não levantados — DATA_GAP, não
/// inventar.
class BragantinoHistoryData {
  const BragantinoHistoryData._();

  static const List<ClubHistorySection> sections = [
    ClubHistorySection(
      period: 'FUNDAÇÃO — 1928',
      title: 'Fundação',
      paragraphs: [
        'O Clube Atlético Bragantino foi fundado em 8 de janeiro de 1928, '
            'em Bragança Paulista, por um grupo de dissidentes do Bragança '
            'Futebol Clube.',
        'Ismael de Aguiar Leme foi o primeiro presidente do clube, num '
            'período em que a presidência trocava quase todo ano.',
      ],
    ),
    ClubHistorySection(
      period: 'MASSA BRUTA — 1931',
      title: 'O apelido "Massa Bruta"',
      paragraphs: [
        'Em 1931, o clube conquistou a Taça Raul Leme com uma campanha de '
            'destaque, e a imprensa regional passou a chamá-lo de "Massa '
            'Bruta" — apelido usado pela torcida e pelo próprio clube até '
            'hoje.',
      ],
    ),
    ClubHistorySection(
      period: 'ERA NABI ABI CHEDID — 1958–1965',
      title: 'Acesso à elite paulista',
      paragraphs: [
        'Em 1958, Nabi Abi Chedid assumiu a presidência do clube — seu '
            'nome batiza o estádio do Bragantino até hoje.',
        'Em 1965, sob seu comando, o time conquistou a 1ª Divisão do '
            'Campeonato Paulista e subiu à elite do futebol do estado.',
      ],
    ),
    ClubHistorySection(
      period: 'PRIMEIROS TÍTULOS NACIONAIS — 1989–2007',
      title: 'Bragantino nacional',
      paragraphs: [
        'Em 1989, o clube conquistou seu primeiro título da Série B do '
            'Campeonato Brasileiro.',
        'Em 1990 veio o título do Campeonato Paulista, e em 1991 o '
            'vice-campeonato do Campeonato Brasileiro (Série A).',
        'Em 2007, o clube foi campeão da Série C do Campeonato Brasileiro.',
      ],
    ),
    ClubHistorySection(
      period: 'ERA RED BULL — 2019',
      title: 'A parceria com a Red Bull',
      paragraphs: [
        'Em março de 2019, o Clube Atlético Bragantino anunciou uma '
            'parceria com a Red Bull, buscando o acesso à Série A e a '
            'modernização do Estádio Nabi Abi Chedid — o clube passou a se '
            'chamar Red Bull Bragantino.',
        'Ainda em 2019, o time conquistou o título da Série B com duas '
            'rodadas de antecedência, garantindo o acesso à elite do '
            'futebol brasileiro.',
      ],
    ),
    ClubHistorySection(
      period: 'PROTAGONISMO INTERNACIONAL — 2021–2022',
      title: 'Estreias continentais',
      paragraphs: [
        'Em 2021, o Red Bull Bragantino disputou sua primeira final '
            'continental, a Copa Sul-Americana, sendo vice-campeão para o '
            'Athletico-PR.',
        'Em 2022, o clube fez sua primeira participação na fase de grupos '
            'da Copa Libertadores da América.',
      ],
    ),
  ];
}

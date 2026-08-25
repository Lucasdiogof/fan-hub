import 'package:goias_app/features/club/domain/entities/club_history_section.dart';

/// Fonte: https://www.goiasec.com.br/historia — conteúdo validado, dividido
/// em capítulos pra leitura confortável no celular. Nunca acrescentar fato
/// que não veio dessa fonte.
class ClubHistoryData {
  const ClubHistoryData._();

  static const List<ClubHistorySection> sections = [
    ClubHistorySection(
      period: 'FUNDAÇÃO — 1943',
      title: 'Fundação',
      paragraphs: [
        'O Goiás Esporte Clube foi fundado em 6 de abril de 1943.',
        'A reunião ocorreu inicialmente na casa dos irmãos Lino e Carlos '
            'Barsi e acabou seguindo na calçada da Rua 23, no centro de '
            'Goiânia, sob um poste de iluminação.',
        'Esse momento marcou o nascimento do clube.',
      ],
    ),
    ClubHistorySection(
      period: 'PRIMEIROS ANOS',
      title: 'Primeiros anos',
      paragraphs: [
        'A primeira partida do Goiás foi contra o Atlético Goianiense.',
        'Sem recursos financeiros, o clube utilizou camisas listradas '
            'horizontalmente em verde e branco, doadas pelo América Mineiro.',
        'Como havia apenas nove camisas, o uniforme precisou ser completado '
            'com camisas brancas.',
      ],
    ),
    ClubHistorySection(
      period: 'SERRINHA — 1960',
      title: 'Serrinha',
      paragraphs: [
        'Em 1960, o clube negociou a compra de uma área na região conhecida '
            'como Fazenda Macambira.',
        'Essa região viria a se tornar a sede da Serrinha, onde hoje fica o '
            'Estádio Hailé Pinheiro.',
      ],
    ),
    ClubHistorySection(
      period: 'PRIMEIRO CAMPEONATO GOIANO — 1966',
      title: 'Primeiro Campeonato Goiano',
      paragraphs: [
        'Em 1966, o Goiás conquistou seu primeiro Campeonato Goiano.',
      ],
    ),
    ClubHistorySection(
      period: 'DÉCADA DE 1970',
      title: 'Década de 1970',
      paragraphs: [
        'Primeiro bicampeonato estadual: 1971 e 1972.',
        'Em 1973, o Goiás se tornou o primeiro clube do estado a disputar o '
            'Campeonato Brasileiro.',
        'A estreia foi contra o Olaria: Goiás 0 x 0 Olaria.',
        'A primeira vitória veio contra o Flamengo: Goiás 1 x 0 Flamengo, '
            'gol de Lincoln.',
      ],
    ),
    ClubHistorySection(
      period: 'DÉCADA DE 1990',
      title: 'Década de 1990',
      paragraphs: [
        'Período de grande crescimento esportivo e institucional.',
        '1990 — Vice-campeão da Copa do Brasil.',
        '1995 — Inauguração do Estádio Hailé Pinheiro.',
        '1997 — Entrada no Clube dos 13.',
        '1999 — Campeão Brasileiro da Série B.',
      ],
    ),
    ClubHistorySection(
      period: 'ANOS 2000',
      title: 'Anos 2000',
      paragraphs: [
        '2000, 2001 e 2002 — Copa Centro-Oeste.',
        'Em 2005 — 3º colocado no Campeonato Brasileiro e classificação '
            'inédita para a Libertadores.',
        'Em 2006 — Primeira participação na Copa Libertadores.',
        '2010 — Final da Copa Sul-Americana, vice-campeão após decisão '
            'contra o Independiente.',
        '2012 — Segundo título do Campeonato Brasileiro Série B.',
        '2023 — Campeão da Copa Verde.',
      ],
    ),
  ];
}

import 'package:goias_app/features/club/domain/entities/club_history_section.dart';

/// Fonte: `docs/vila_nova_data/data/history.json` (pacote de pesquisa, texto
/// original redigido a partir do site oficial — vilanovafc.com.br/historico e
/// /titulos — e da Assembleia Legislativa de Goiás). Só seções `READY`.
/// GERADO por `tooling/vilanova_content/generate_institutional_dart.mjs`:
/// corrigir no pacote e regenerar, nunca editar à mão.
class VilaNovaHistoryData {
  const VilaNovaHistoryData._();

  static const List<ClubHistorySection> sections = [
    ClubHistorySection(
      period: '1938–1943',
      title: 'Origens no bairro Vila Nova',
      paragraphs: [
        'A Associação Mariana, criada em 1938 sob liderança do padre José Balestiere, reuniu moradores do bairro Vila Nova em uma Goiânia ainda jovem. O futebol surgiu nesse ambiente comunitário e deu origem ao clube.',
        'O Vila Nova Futebol Clube foi formalizado em 1943 e passou a disputar competições vinculadas ao futebol goiano naquele mesmo ano.',
      ],
    ),
    ClubHistorySection(
      period: '1946–1955',
      title: 'Mudanças de nome e retorno à identidade original',
      paragraphs: [
        'Em 1946, o time passou a se chamar Operário. Ao longo do período também usou os nomes Araguaia e Fênix Futebol Clube.',
        'O nome Vila Nova foi retomado em 1955 e acompanha o clube desde então.',
      ],
    ),
    ClubHistorySection(
      period: '1958–1963',
      title: 'A consolidação esportiva',
      paragraphs: [
        'Em 1958, o Vila terminou o Campeonato Goiano na terceira colocação. A ascensão se confirmou em 1961, temporada em que conquistou seus primeiros troféus de maior destaque e o primeiro Campeonato Goiano.',
        'O clube repetiu o título estadual em 1962 e 1963, abrindo a primeira grande sequência vencedora de sua história.',
      ],
    ),
    ClubHistorySection(
      period: '1969–1984',
      title: 'A era de domínio estadual',
      paragraphs: [
        'Entre o fim dos anos 1960 e a primeira metade dos anos 1980, o Vila acumulou títulos estaduais e consolidou uma das fases mais vitoriosas de sua história.',
        'O clube foi campeão goiano em 1969, 1973, 1977, 1978, 1979, 1980, 1982 e 1984, além de taças regionais como a Copa Goiás (1969, 1971 e 1976) e a Copa Leonino Caiado (1977, 1979 e 1981).',
      ],
    ),
    ClubHistorySection(
      period: '1993–2005',
      title: 'Retomada e primeiro título nacional',
      paragraphs: [
        'O Vila voltou a vencer o Campeonato Goiano em 1993 e 1995. Em 1996, conquistou de forma invicta a terceira divisão nacional, um dos marcos centrais de sua história.',
        'Na virada do século, venceu a Segunda Divisão Goiana de 2000, o Goiano de 2001 e voltou a ser campeão estadual em 2005.',
      ],
    ),
    ClubHistorySection(
      period: '2015–2020',
      title: 'Novos títulos nacionais',
      paragraphs: [
        'O clube voltou a conquistar a terceira divisão nacional em 2015 e novamente em 2020, elevando para três o total de títulos do Campeonato Brasileiro da Série C.',
        'No mesmo ano de 2015, o Vila também venceu a Segunda Divisão Goiana.',
      ],
    ),
    ClubHistorySection(
      period: '2021–2026',
      title: 'Finais regionais, estrutura e título estadual',
      paragraphs: [
        'O Vila foi vice-campeão da Copa Verde em 2021, 2022 e 2024. Em 2024, o futebol profissional passou a treinar integralmente no CT Vila do Tigre.',
        'Em 2025, o clube conquistou seu 16º Campeonato Goiano. Em 2026, segue utilizando o OBA como casa principal e mantém estrutura profissional no CT.',
      ],
    ),
  ];
}

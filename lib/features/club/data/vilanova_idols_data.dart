import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Fonte: `docs/vila_nova_data/data/idols.json` (pacote v1.2). No app só o
/// tier 1 é publicado (`ClubIdol.isPublishable`). Mapeamento:
///   * tier 1 = `READY` no pacote, com fonte que chama o jogador de ídolo
///     (ge, Sou Tigrão, votação da torcida) OU marcos concretos e
///     específicos pelo clube (mesmo critério do Bragantino pra
///     `evidenceExplicitIdol: false`);
///   * tier 2 = `READY` mas retido: Túlio (números em conflito — pacote diz
///     104 jogos/92 gols pelo Zerozero, Wikipedia/oGol somam 58/51) e
///     Willian Formiga (atleta em atividade no elenco atual);
///   * tier 3 = `REVIEW` no pacote (período/estatística não fechados).
///
/// Números de jogos/gols só aparecem quando a fonte cobre a passagem
/// inteira; quando a base é parcial (Guilherme), o texto não cita número.
/// FOTOS: nenhuma ainda (ASSET_GAP, ver `docs/vila_nova_data/assets_todo.md`).
///
/// Lote 2026-09-30 (pendências da rodada de auditoria de elenco):
/// adicionados Gibrair Caetano, Fernandinho, Roberto Oliveira, Zé Luís,
/// Zé Henrique, Timoura, Paulinho Benga, Sabino, Moisés e Michel Alves —
/// todos com identidade e período confirmados por pesquisa dedicada.
/// Correção de Alan Mineiro (artilheiro 2020) MANTIDA sem alteração: a
/// reauditoria (ogol.com.br, quebra temporada a temporada) fechou
/// exatamente em 45 gols/156 jogos, confirmando o valor já publicado —
/// a fonte alternativa (49/175) não bateu com o detalhamento por
/// temporada e foi descartada.
/// "Luciano" NÃO foi adicionado: candidato mais provável é Luciano
/// Santos Gonçalves ("Luciano Goiano", anos 1990), mas a fonte histórica
/// cita só "Luciano" sem desambiguação suficiente — pendência aberta,
/// não transformar em certeza sem evidência adicional.
class VilaNovaIdolsData {
  const VilaNovaIdolsData._();

  static const List<ClubIdol> idols = [
    ClubIdol(
      name: 'Guilherme',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Atacante',
      period: '1968–1977',
      description:
          'Chegou ao Vila em 1968 e se tornou uma das maiores referências da '
          'história colorada, com mais de dez títulos pelo clube. Em 2013, a '
          'torcida o escolheu como o maior jogador de todos os tempos do Vila.',
    ),
    ClubIdol(
      name: 'Tim',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Meia',
      period: '1992–2005',
      description:
          'Meia formado no clube, campeão goiano em 1995 e 2005 e campeão '
          'invicto da Série C de 1996. Mais de 150 jogos e 23 gols pelo Tigre, '
          'em três passagens.',
    ),
    ClubIdol(
      name: 'Roni',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Atacante',
      period: '1994–1996; 2010–2011',
      description:
          'Revelado pelo Vila, foi campeão goiano em 1995 antes de uma carreira '
          'nacional e internacional. Voltou em 2010 e somou 86 jogos e 41 gols '
          'pelo clube.',
    ),
    ClubIdol(
      name: 'Wando',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Atacante',
      period: '2000–2014',
      description:
          'Revelado no início dos anos 2000, virou ídolo da torcida e esteve '
          'nos títulos goianos de 2001 e 2005, em várias passagens pelo clube.',
    ),
    ClubIdol(
      name: 'Pedro Júnior',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Atacante',
      period: '2005–2021',
      description:
          'Atacante revelado pelo Vila, campeão goiano em 2005, com cinco '
          'passagens pelo clube e 33 gols em 85 jogos.',
    ),
    ClubIdol(
      name: 'Róbston',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Volante',
      period: '2013–2016',
      description:
          'Capitão do time campeão da Série C de 2015 e presente nos acessos à '
          'Série B de 2013 e 2015.',
    ),
    ClubIdol(
      name: 'Carlos Frontini',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Atacante',
      period: '2013–2021',
      description:
          'Atacante argentino, herói dos acessos à Série B de 2013 e 2015, com '
          '28 gols em 79 jogos pelo Vila.',
    ),
    ClubIdol(
      name: 'Alan Mineiro',
      tier: 1,
      evidenceExplicitIdol: true,
      position: 'Meia',
      period: '2017–2021',
      description:
          'Principal referência técnica do Vila a partir de 2017 e campeão da '
          'Série C de 2020, com 45 gols em 156 jogos.',
    ),
    ClubIdol(
      name: 'Rafael Donato',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Zagueiro',
      period: '2020–2023',
      description:
          'Capitão por quatro temporadas e campeão da Série C de 2020. Fez 182 '
          'jogos e 18 gols pelo clube.',
    ),
    ClubIdol(
      name: 'Túlio Maravilha',
      tier: 2,
      evidenceExplicitIdol: true,
      position: 'Atacante',
      description:
          'Em 2008 marcou 24 gols na Série B e 14 no Goiano pelo Vila. Retido: '
          'totais pelo clube em conflito entre as fontes.',
    ),
    ClubIdol(
      name: 'Willian Formiga',
      tier: 2,
      evidenceExplicitIdol: false,
      position: 'Lateral-esquerdo',
      description:
          'Campeão da Série C de 2020. Retido: segue em atividade no elenco.',
    ),
    ClubIdol(
      name: 'Gibrair Caetano',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Meio-campista',
      period: '1958–1963',
      description:
          'Conhecido como "Pérola Negra", artilheiro do Campeonato '
          'Goiano de 1961 e integrante da geração do primeiro título '
          'estadual do Vila Nova.',
    ),
    ClubIdol(
      name: 'Fernandinho',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Ponta-direita',
      period: '1972–1973; 1976–1979',
      description:
          'Hugo Fernando Bonfim Queiroz. Campeão goiano pelo Vila em '
          '1973, 1977, 1978 e 1979; também teve passagem pelo Santos.',
    ),
    ClubIdol(
      name: 'Roberto Oliveira',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Volante',
      period: '1977–1985',
      description:
          'Oswaldo Roberto Oliveira, volante que também atuou na defesa. '
          'Campeão goiano pelo Vila em 1977, 1978, 1979, 1980, 1982 e '
          '1984; depois virou treinador.',
    ),
    ClubIdol(
      name: 'Zé Luís',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Lateral-direito',
      period: '1969–início dos anos 1980',
      description:
          'José Luis dos Santos. Ligado ao clube desde as categorias de '
          'base em 1969, também atuou como zagueiro; integrante das '
          'gerações campeãs goianas de 1977, 1978, 1979, 1980 e 1982.',
    ),
    ClubIdol(
      name: 'Zé Henrique',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Ponta-direita',
      period: 'fim dos anos 1970–1984, com retorno posterior',
      description:
          'Artilheiro do Campeonato Goiano em 1980 e 1984 (há '
          'divergência entre fontes sobre o número exato de gols em uma '
          'dessas artilharias). Nome completo não confirmado.',
    ),
    ClubIdol(
      name: 'Timoura',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Zagueiro',
      period: '1977–1982',
      description:
          'Integrante da geração tetracampeã goiana (1977, 1978, 1979 '
          'e 1980). Nome completo não confirmado.',
    ),
    ClubIdol(
      name: 'Paulinho Benga',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Ponta-esquerda',
      period: '1978–1983',
      description:
          'Paulo César de Souza. Integrante do tetracampeonato goiano e '
          'campeão em 1982; depois seguiu ligado ao clube em funções '
          'técnicas e de categorias de base.',
    ),
    ClubIdol(
      name: 'Sabino',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Meia',
      period: '1996–1998',
      description:
          'Bartolomeu Moreira Neves. Campeão brasileiro da Série C de '
          '1996, destaque ofensivo daquela campanha, com retorno '
          'posterior ao clube.',
    ),
    ClubIdol(
      name: 'Moisés',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Atacante',
      period: '2015–',
      description:
          'Moisés Oliveira Brito. Um dos artilheiros do título da Série '
          'C de 2015 (8 gols, atrás apenas de Frontini, autor de '
          '9), com bom desempenho de gols também na Série B.',
    ),
    ClubIdol(
      name: 'Michel Alves',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Goleiro',
      period: '2004–2005; 2011',
      description:
          'Michel Aluízio da Cruz Alves. Goleiro do time campeão goiano '
          'de 2005, ao lado de Tim e Pedro Júnior.',
    ),
    ClubIdol(
      name: 'Bé',
      tier: 3,
      evidenceExplicitIdol: true,
      position: 'Atacante',
      description:
          'Artilheiro dos Goianos de 1993 e 1994 — período em revisão.',
    ),
    ClubIdol(
      name: 'Max',
      tier: 3,
      evidenceExplicitIdol: true,
      position: 'Goleiro',
      description: 'Goleiro do fim dos anos 2000 — passagens em revisão.',
    ),
  ];
}

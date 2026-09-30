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

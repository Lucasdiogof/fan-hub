import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Fonte: pacote de pesquisa consolidado fornecido pelo usuário em
/// 2026-09-05 (bragantino_idols_seed_v1.json). Tier 1 = nomes fortes; Tier
/// 2 = pool editorial (`CANDIDATE_PRIOR_RESEARCH`); Tier 3 = candidatos
/// ainda em revisão (`REVIEW`, menor confiança). NUNCA promover 2/3 pro
/// mesmo peso do Tier 1 sem checagem adicional.
///
/// Lincom: RESOLVIDO em 2026-09-07 (pacote `docs/bragantino_data`) — fonte
/// contemporânea de dezembro/2016 registra explicitamente 160 jogos / 72
/// gols (passagens pelo Bragantino, todas as competições oficiais). Fontes
/// retrospectivas posteriores citam 73 gols — mantido como nota de
/// auditoria, nunca como contador principal.
///
/// Atualização 2026-09-07 (mesmo pacote): Biro-Biro, Ivair, Claudinho, Léo
/// Ortiz, Artur, Ytalo e Aderlan promovidos de tier 2 pra tier 1 — a nova
/// pesquisa trouxe conquistas/marcos concretos e específicos pra cada um
/// (não mais só "revisão pendente"), o suficiente pra publicar mesmo sem
/// citação explícita de "ídolo" (`evidenceExplicitIdol: false`, mesmo
/// padrão de Gil Baiano/Marcelo). Léo Jaime, Mazinho e Luís Müller
/// PRESERVADOS sem alteração — a ausência deles na pesquisa nova não é
/// evidência de erro na pesquisa anterior (decisão explícita do usuário:
/// união, nunca substituição).
///
/// Nenhuma característica comportamental/técnica (estilo, dimensões,
/// pesos) foi anexada — isso é DATA_GAP separado, necessário só quando o
/// jogo de identidade de jogador do Bragantino for implementado de
/// verdade (ver docs da rodada M4.4).
class BragantinoIdolsData {
  const BragantinoIdolsData._();

  static const _generation199091 =
      'Destaque da geração histórica do clube de 1990-91.';
  static const _tier2Historico =
      'Nome histórico levantado como candidato a destaque — revisão '
      'editorial pendente.';
  static const _tier2Longevidade =
      'Nome associado à longevidade no clube — revisão editorial '
      'pendente.';
  static const _tier3 = 'Candidato de pool estendido, ainda em revisão.';

  static const List<ClubIdol> idols = [
    ClubIdol(
      name: 'Mauro Silva',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Ídolo do clube, eleito Bola de Ouro da Placar em 1991.',
    ),
    ClubIdol(
      name: 'Lincom',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Ídolo histórico do clube, com 160 jogos e 72 gols em suas '
          'passagens pelo Bragantino (fonte contemporânea de dezembro de '
          '2016; fontes retrospectivas posteriores citam 73 gols).',
      position: 'Atacante',
      period: '2011-2016',
    ),
    ClubIdol(
      name: 'Léo Jaime',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Chamado de ídolo do clube em levantamentos históricos.',
    ),
    ClubIdol(
      name: 'Cleiton',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Descrito pela loja oficial do clube como um dos grandes '
          'ídolos; atingiu 300 jogos pelo Bragantino em 2025.',
    ),
    ClubIdol(
      name: 'Gil Baiano',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Destaque da geração histórica de 1990-91, com premiações '
          'Bola de Prata/Ouro citadas como referência.',
    ),
    ClubIdol(
      name: 'Marcelo',
      tier: 1,
      evidenceExplicitIdol: false,
      description: _generation199091,
    ),
    ClubIdol(
      name: 'Mazinho',
      tier: 1,
      evidenceExplicitIdol: false,
      description: _generation199091,
    ),
    ClubIdol(
      name: 'Luís Müller',
      tier: 1,
      evidenceExplicitIdol: false,
      description: _generation199091,
    ),
    ClubIdol(
      name: 'Biro-Biro',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Integrante das equipes campeãs de 1989 e 1990 e vice-campeã '
          'em 1991 — geração histórica do clube.',
      period: '1989-1991',
    ),
    ClubIdol(
      name: 'Ivair',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Meio-campista da geração histórica de 1989-1991, presente nos '
          'títulos de Série B 1989 e Paulista 1990.',
      period: '1989-1991',
    ),
    ClubIdol(
      name: 'Tiba',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Historico,
    ),
    ClubIdol(
      name: 'Júnior',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Historico,
    ),
    ClubIdol(
      name: 'Nei',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Historico,
    ),
    ClubIdol(
      name: 'Ytalo',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Parte das campanhas de acesso via Série B 2019 e da final da '
          'Sul-Americana 2021.',
      period: '2019-2022',
    ),
    ClubIdol(
      name: 'Claudinho',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Campeão da Série B em 2019 e artilheiro do Campeonato '
          'Brasileiro de 2020 pelo clube, com 18 gols.',
      period: '2019-2021',
    ),
    ClubIdol(
      name: 'Artur',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Um dos protagonistas da campanha de vice-campeão da '
          'Sul-Americana 2021, integrante da seleção da competição.',
      period: '2020-2023',
    ),
    ClubIdol(
      name: 'Léo Ortiz',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Capitão e referência defensiva na campanha de vice-campeão '
          'da Sul-Americana 2021, integrante da seleção da competição.',
      period: '2019-2024',
    ),
    ClubIdol(
      name: 'Aderlan',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Presença recorrente nas campanhas do clube ao longo da era '
          'Red Bull.',
      period: '2019-2020s',
    ),
    ClubIdol(
      name: 'Jadsom',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Longevidade,
    ),
    ClubIdol(
      name: 'Lucas Evangelista',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Longevidade,
    ),
    ClubIdol(
      name: 'Adãozinho',
      tier: 3,
      evidenceExplicitIdol: false,
      description: _tier3,
    ),
    ClubIdol(
      name: 'Somália',
      tier: 3,
      evidenceExplicitIdol: false,
      description: _tier3,
    ),
    ClubIdol(
      name: 'Davi',
      tier: 3,
      evidenceExplicitIdol: false,
      description: _tier3,
    ),
    ClubIdol(
      name: 'Guilherme Mattis',
      tier: 3,
      evidenceExplicitIdol: false,
      description: _tier3,
    ),
    ClubIdol(
      name: 'Júlio César',
      tier: 3,
      evidenceExplicitIdol: false,
      description: _tier3,
    ),
    ClubIdol(
      name: 'Matheus Peixoto',
      tier: 3,
      evidenceExplicitIdol: false,
      description: _tier3,
    ),
  ];
}

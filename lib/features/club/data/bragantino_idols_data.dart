import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Fonte: pacote de pesquisa consolidado fornecido pelo usuário em
/// 2026-09-05 (bragantino_idols_seed_v1.json). Tier 1 = nomes fortes; Tier
/// 2 = pool editorial (`CANDIDATE_PRIOR_RESEARCH`); Tier 3 = candidatos
/// ainda em revisão (`REVIEW`, menor confiança). NUNCA promover 2/3 pro
/// mesmo peso do Tier 1 sem checagem adicional.
///
/// Lincom: condição de ídolo mantida, mas total de jogos/gols NÃO entra
/// aqui — um checkpoint posterior marcou os números (73 gols / 133+
/// jogos) como conflito estatístico aberto, sem revalidação.
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
  static const _tier2RedBullEra =
      'Nome da era Red Bull levantado como candidato a destaque — revisão '
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
      description: 'Ídolo histórico do clube.',
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
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Historico,
    ),
    ClubIdol(
      name: 'Ivair',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Historico,
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
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2RedBullEra,
    ),
    ClubIdol(
      name: 'Claudinho',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2RedBullEra,
    ),
    ClubIdol(
      name: 'Artur',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2RedBullEra,
    ),
    ClubIdol(
      name: 'Léo Ortiz',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2RedBullEra,
    ),
    ClubIdol(
      name: 'Aderlan',
      tier: 2,
      evidenceExplicitIdol: false,
      description: _tier2Longevidade,
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

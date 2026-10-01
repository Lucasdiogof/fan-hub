import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Fonte: pacote de pesquisa consolidado fornecido pelo usuário em
/// 2026-09-05 (bragantino_idols_seed_v1.json). Tier 1 = nomes fortes; Tier
/// 2 = pool editorial (`CANDIDATE_PRIOR_RESEARCH`); Tier 3 = candidatos
/// ainda em revisão (`REVIEW`, menor confiança). NUNCA promover 2/3 pro
/// mesmo peso do Tier 1 sem checagem adicional.
///
/// Lincom: ATUALIZADO em 2026-09-30 — reauditoria (3ª/4ª fonte) encontrou
/// confirmação direta pela conta oficial do clube (@RedBullBraga, X/Twitter:
/// "autor de 73 gols com o manto do Massa Bruta") somada a 3 veículos
/// esportivos distintos, todos convergindo em 73 gols (2011-2016), sem
/// nenhuma fonte atual sustentando 72. O "72" (fonte contemporânea de
/// dezembro/2016) foi substituído; 73 passa a ser o contador principal.
///
/// Atualização 2026-09-07 (mesmo pacote): Biro-Biro, Ivair, Claudinho, Léo
/// Ortiz, Artur, Ytalo e Aderlan promovidos de tier 2 pra tier 1 — a nova
/// pesquisa trouxe conquistas/marcos concretos e específicos pra cada um
/// (não mais só "revisão pendente"), o suficiente pra publicar mesmo sem
/// citação explícita de "ídolo" (`evidenceExplicitIdol: false`, mesmo
/// padrão de Gil Baiano). Léo Jaime, Mazinho e Luís Müller
/// PRESERVADOS sem alteração — a ausência deles na pesquisa nova não é
/// evidência de erro na pesquisa anterior (decisão explícita do usuário:
/// união, nunca substituição).
///
/// Nenhuma característica comportamental/técnica (estilo, dimensões,
/// pesos) foi anexada — isso é DATA_GAP separado, necessário só quando o
/// jogo de identidade de jogador do Bragantino for implementado de
/// verdade (ver docs da rodada M4.4).
///
/// FOTOS (2026-09-09): 14/15 tier-1 ganharam `photoAsset` — Cleiton
/// reaproveita a URL do CDN oficial (elenco atual); Ytalo/Claudinho/
/// Artur/Léo Ortiz/Aderlan reaproveitam o asset local já usado em "Quem
/// Vestiu o Manto" (`_bragantinoGuessPlayerPhotos`); Mauro Silva/Lincom/
/// Léo Jaime/Gil Baiano/Mazinho/Luís Müller/Biro-Biro/Ivair usam fotos
/// novas em `lib/assets/branding/bragantino/idols/`.
///
/// `Marcelo` REMOVIDO em 2026-09-09 (ver histórico), RESTAURADO em
/// 2026-09-30: pesquisa dedicada (pesquisa externa + checagem cruzada) identificou
/// o jogador da geração 1989-91 como MARCELO MARTELOTTE, goleiro —
/// pessoa DISTINTA do técnico Marcelo Veiga (2018,
/// `bragantino_tactical_coach_references.dart`). Reentrada como "Marcelo
/// Martelotte", sem foto ainda (ASSET_GAP — nunca reaproveitar
/// `marcelo_veiga.jpg`, que é de outra pessoa).
///
/// Lote 2026-09-30 (pendências da rodada de auditoria de elenco):
/// adicionados Alberto Félix, Wilsinho Acedo, Hélio Burini, Nardinho,
/// Nivaldo "Queixo-de-mula" (1965, DISTINTO de Nivaldo Penafiel — goleiro
/// de 1990, já presente em `career_players` com id `nivaldo_penafiel`,
/// sem relação) e Marcelo Martelotte, todos com fonte e período
/// confirmados. "Carlos Alberto Seixas" foi PESQUISADO e EXCLUÍDO
/// deliberadamente: fontes mais detalhadas de carreira não confirmam
/// passagem consistente pelo Bragantino (risco de confusão com outro
/// "Carlos Alberto Seixas/Cacá") — não promover sem evidência nova.
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
      photoAsset: 'lib/assets/branding/bragantino/idols/mauro_silva.jpg',
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
      photoAsset: 'lib/assets/branding/bragantino/idols/lincom.png',
    ),
    ClubIdol(
      name: 'Léo Jaime',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Chamado de ídolo do clube em levantamentos históricos.',
      photoAsset: 'lib/assets/branding/bragantino/idols/leo_jaime.png',
    ),
    ClubIdol(
      name: 'Cleiton',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Descrito pela loja oficial do clube como um dos grandes '
          'ídolos; atingiu 300 jogos pelo Bragantino em 2025.',
      // Segue no elenco atual — mesma URL do CDN oficial já usada em
      // `_bragantinoGuessPlayerPhotos['cleiton']`/`squad_members`, nunca
      // uma foto nova/duplicada pra mesma pessoa.
      photoAsset:
          'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/gliozjfvi1mbxq88fibm/goleiro-cleiton',
    ),
    ClubIdol(
      name: 'Gil Baiano',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Destaque da geração histórica de 1990-91; venceu a Bola de '
          'Prata em 1990 e 1991 e foi convocado à Seleção Brasileira em '
          '1990 (6 amistosos).',
      // Correção 2026-09-30: lista oficial de vencedores da Bola de Prata
      // (imortaisdofutebol.com) confirma Gil Baiano em 1990 e 1991; ele
      // NUNCA venceu a Bola de Ouro (1990 foi de César Sampaio, 1991 foi
      // do próprio Mauro Silva, também ídolo deste dataset).
      photoAsset: 'lib/assets/branding/bragantino/idols/gil_baiano.png',
    ),
    ClubIdol(
      name: 'Mazinho',
      tier: 1,
      evidenceExplicitIdol: false,
      description: _generation199091,
      photoAsset: 'lib/assets/branding/bragantino/idols/mazinho.jpg',
    ),
    ClubIdol(
      name: 'Luís Müller',
      tier: 1,
      evidenceExplicitIdol: false,
      description: _generation199091,
      photoAsset: 'lib/assets/branding/bragantino/idols/luis_muller.png',
    ),
    ClubIdol(
      name: 'Biro-Biro',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Integrante das equipes campeãs de 1989 e 1990 e vice-campeã '
          'em 1991 — geração histórica do clube.',
      // Correção 2026-09-30: vínculo completo com o clube é 1985-1992
      // (pt.wikipedia.org/wiki/Biro-Biro_Ribeiro + ogol.com.br, batendo
      // com o valor já usado em career_players); 1989-1991 cobria só o
      // núcleo do período de título, não a passagem inteira.
      period: '1985-1992',
      photoAsset: 'lib/assets/branding/bragantino/idols/biro_biro.jpg',
    ),
    ClubIdol(
      name: 'Ivair',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Meio-campista da geração histórica de 1989-1991, presente nos '
          'títulos de Série B 1989 e Paulista 1990.',
      period: '1989-1991',
      photoAsset: 'lib/assets/branding/bragantino/idols/ivair.png',
    ),
    ClubIdol(
      name: 'Marcelo Martelotte',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Goleiro',
      description:
          'Goleiro da geração histórica, campeão brasileiro da Série B '
          'de 1989 e campeão paulista de 1990.',
      period: '1989-1992',
    ),
    ClubIdol(
      name: 'Alberto Félix',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Meia',
      description:
          'Alberto Carlos Félix da Silva. Meia de criação, integrante da '
          'geração vice-campeã brasileira de 1991; convocado à Seleção '
          'Brasileira em 1993.',
      period: '1991-1995',
    ),
    ClubIdol(
      name: 'Wilsinho Acedo',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Ponta-esquerda',
      description:
          'Wilson Aparecido Acedo. Integrante do time campeão da divisão '
          'de acesso de 1965; destaque na elite paulista em 1966.',
      period: '1959-1966',
    ),
    ClubIdol(
      name: 'Hélio Burini',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Meia',
      description:
          'Marcou o gol do 1x0 contra o Barretos no primeiro jogo da '
          'final de 1965, decisiva para o acesso à elite paulista.',
      period: '1964-1969',
    ),
    ClubIdol(
      name: 'Nardinho',
      tier: 2,
      evidenceExplicitIdol: false,
      position: 'Atacante',
      description:
          'Integrante da equipe campeã do acesso em 1965. Fontes '
          'históricas registram participação na partida de volta da '
          'decisão contra o Barretos, mas há divergência entre elas '
          'sobre os detalhes — nome completo não confirmado.',
      period: '1965-1966',
    ),
    ClubIdol(
      name: 'Nivaldo "Queixo-de-mula"',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Centroavante',
      description:
          'Integrante do elenco campeão do acesso em 1965, com gol '
          'registrado na decisão contra o Barretos. Pessoa DISTINTA de '
          'Nivaldo Penafiel (goleiro da geração de 1990); nome completo '
          'não confirmado.',
      period: '1965-1966',
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
      // Já fora do elenco atual — reaproveita a foto histórica já usada
      // em "Quem Vestiu o Manto" (`_bragantinoGuessPlayerPhotos['ytalo']`),
      // nunca uma foto nova/duplicada.
      photoAsset: 'lib/assets/games/guess_player/bragantino/ytalo.png',
    ),
    ClubIdol(
      name: 'Claudinho',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Campeão da Série B em 2019 e artilheiro do Campeonato '
          'Brasileiro de 2020 pelo clube, com 18 gols.',
      period: '2019-2021',
      photoAsset: 'lib/assets/games/guess_player/bragantino/claudinho.png',
    ),
    ClubIdol(
      name: 'Artur',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Um dos protagonistas da campanha de vice-campeão da '
          'Sul-Americana 2021, integrante da seleção da competição.',
      period: '2020-2023',
      photoAsset: 'lib/assets/games/guess_player/bragantino/artur.png',
    ),
    ClubIdol(
      name: 'Léo Ortiz',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Capitão e referência defensiva na campanha de vice-campeão '
          'da Sul-Americana 2021, integrante da seleção da competição.',
      period: '2019-2024',
      photoAsset: 'lib/assets/games/guess_player/bragantino/leo_ortiz.png',
    ),
    ClubIdol(
      name: 'Aderlan',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Presença recorrente nas campanhas do clube ao longo da era '
          'Red Bull.',
      period: '2019-2020s',
      photoAsset: 'lib/assets/games/guess_player/bragantino/aderlan.png',
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

import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

/// Referências do Vila Nova pro jogo "Que craque é você?".
///
/// v1 (2026-09-29) — 10 jogadores, convertidos editorialmente do pacote de
/// pesquisa `docs/vila_nova_data/arena/player_identity.json` (que usa 8
/// dimensões em português, formato incompatível com o motor). Os valores
/// aqui NÃO são conversão automática/linear daquele schema: cada nota nas
/// seis dimensões reais (`creativity, definition, leadership, intensity,
/// technique, tactics`) foi lida a partir dos `trait_evidence` originais
/// (fatos + fonte `ge`) do pacote, e depois ajustada dentro da faixa que a
/// evidência sustenta pra evitar dois perfis colidirem no mesmo canto do
/// espaço (mesmo processo de calibração do Bragantino, sobre estes 10).
/// Nenhum dado foi inventado; onde o pacote já registrava "sem evidência
/// específica", a nota aqui também ficou conservadora/intermediária.
///
/// Calibração: `dart run tool/vilanova_player_identity_calibration.dart`
/// (mesmo motor/perguntas do app, enumeração amostrada das combinações) —
/// todos os 10 ficam entre 8% e 14% como referência #1, gap médio
/// Top1→Top2 de 2,66 pontos.
const vilanovaPlayerIdentityReferences = <PlayerIdentityReference>[
  // Meia armador, ídolo desde 2017: principal articulador ofensivo do
  // período e artilheiro incomum pra função (45 gols em 156 jogos).
  PlayerIdentityReference(
    id: 'vn_player_profile_alan_mineiro',
    name: 'Alan Mineiro',
    period: '2017–2021',
    creativity: 62,
    definition: 63,
    leadership: 62,
    intensity: 34,
    technique: 73,
    tactics: 47,
    confidence: 'high',
  ),

  // Zagueiro e capitão por quatro temporadas, pilar defensivo do título da
  // Série C de 2020, líder do grupo e presença ofensiva incomum de bola
  // aérea — o mais disponível do elenco em quase todas as temporadas.
  PlayerIdentityReference(
    id: 'vn_player_profile_rafael_donato',
    name: 'Rafael Donato',
    period: '2020–2023',
    creativity: 34,
    definition: 55,
    leadership: 86,
    intensity: 83,
    technique: 53,
    tactics: 66,
    confidence: 'high',
  ),

  // Atacante versátil, eleito um dos melhores do Goiano de 2024 (20 gols e
  // 10 assistências), com evolução física/técnica/tática citada por ele
  // mesmo.
  PlayerIdentityReference(
    id: 'vn_player_profile_alesson',
    name: 'Alesson',
    period: '2024',
    creativity: 67,
    definition: 72,
    leadership: 38,
    intensity: 67,
    technique: 59,
    tactics: 60,
    confidence: 'high',
  ),

  // Volante veterano de proteção — 84 jogos aos 39 anos, renovado por três
  // temporadas seguidas puramente pela solidez defensiva/tática, sem
  // pretensão ofensiva alguma.
  PlayerIdentityReference(
    id: 'vn_player_profile_ralf',
    name: 'Ralf',
    period: '2021–2023',
    creativity: 13,
    definition: 13,
    leadership: 66,
    intensity: 35,
    technique: 40,
    tactics: 87,
    confidence: 'high',
  ),

  // Atacante de área pura: o próprio técnico elogiou explicitamente seu
  // posicionamento, com gols decisivos nos acréscimos entrando do banco —
  // finalizador puro, quase nada fora da área.
  PlayerIdentityReference(
    id: 'vn_player_profile_henrique_almeida',
    name: 'Henrique Almeida',
    period: '2024',
    creativity: 18,
    definition: 92,
    leadership: 29,
    intensity: 42,
    technique: 45,
    tactics: 66,
    confidence: 'high',
  ),

  // Lateral-esquerdo de muita ida e volta, autoavaliado como "muito
  // potencial defensivo" — o maior volume de corrida do grupo, sem apelo
  // criativo ou de finalização.
  PlayerIdentityReference(
    id: 'vn_player_profile_willian_formiga',
    name: 'Willian Formiga',
    period: '2021',
    creativity: 27,
    definition: 17,
    leadership: 40,
    intensity: 83,
    technique: 58,
    tactics: 47,
    confidence: 'medium',
  ),

  // Meio-campista completo: líder de participações em gols do elenco em
  // 2026 (8 gols e 8 assistências em 34 jogos) e também forte na
  // recuperação de bola — o perfil mais criativo E mais intenso ao mesmo
  // tempo, sem ser o de mais liderança ou leitura tática do grupo.
  PlayerIdentityReference(
    id: 'vn_player_profile_joao_vieira',
    name: 'João Vieira',
    period: '2026',
    creativity: 86,
    definition: 40,
    leadership: 41,
    intensity: 84,
    technique: 47,
    tactics: 61,
    confidence: 'high',
  ),

  // Meia experiente contratado em 2026 pra somar passe, assistências e
  // liderança dentro e fora de campo, vindo de temporada regular pelo
  // Avaí — pouco gol e pouco ritmo físico, mas o maior mix de
  // criação+liderança+leitura do elenco.
  PlayerIdentityReference(
    id: 'vn_player_profile_marquinhos_gabriel',
    name: 'Marquinhos Gabriel',
    period: '2026',
    creativity: 60,
    definition: 29,
    leadership: 81,
    intensity: 23,
    technique: 59,
    tactics: 69,
    confidence: 'medium',
  ),

  // Atacante convertido de ponta pra centroavante em 2026, virou referência
  // móvel e decisiva (pivô, giro e finalização) em meio a desfalques.
  PlayerIdentityReference(
    id: 'vn_player_profile_andre_luis',
    name: 'André Luís',
    period: '2026',
    creativity: 36,
    definition: 60,
    leadership: 50,
    intensity: 50,
    technique: 66,
    tactics: 68,
    confidence: 'high',
  ),

  // Ponta vertical e líder de assistências da Série B de 2026, com produção
  // dupla de gols e passes decisivos — instintivo e direto, quase sem
  // preocupação de leitura/organização.
  PlayerIdentityReference(
    id: 'vn_player_profile_janderson',
    name: 'Janderson',
    period: '2026',
    creativity: 48,
    definition: 72,
    leadership: 44,
    intensity: 76,
    technique: 64,
    tactics: 28,
    confidence: 'high',
  ),
];

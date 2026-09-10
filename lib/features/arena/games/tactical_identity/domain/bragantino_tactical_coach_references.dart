import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Referências do Red Bull Bragantino para o jogo "Identidade Futebolística".
///
/// REVISÃO 2026-09-10
/// - dataset ampliado de 6 para 12 técnicos, igualando a quantidade do Goiás;
/// - `x` negativo = POSSE e positivo = VERTICAL;
/// - `y` negativo = DOGMÁTICO e positivo = PRAGMÁTICO;
/// - pressing/blockHeight/risk/structuralFluidity são dimensões editoriais
///   ocultas usadas apenas na afinidade completa;
/// - os valores representam a PASSAGEM pelo Bragantino, nunca a carreira
///   inteira do treinador;
/// - nenhuma coordenada foi gerada automaticamente a partir de estatística;
///   a pesquisa qualitativa define os perfis e a calibração apenas verifica
///   se o motor não produz referências dominantes ou inúteis.
///
/// Gate final: enumeração EXAUSTIVA das 4^10 = 1.048.576 combinações do
/// questionário usando a mesma métrica do app. Todos os 12 técnicos aparecem
/// no Top 3; nenhum supera 20% como referência #1 (máximo ~19,84%); gap médio
/// Top1→Top2 ~4,39 pontos; empate visual dos três primeiros ~1,07%.
///
/// Fontes qualitativas principais da expansão: ge e registros históricos de
/// passagem pelo clube. Felipe Conceição foi descrito com intensidade,
/// agressividade, posse objetiva e pressão alta; Fernando Seabra com 4-3-3,
/// pressão alta e mistura de posse/transição; Mancini com pragmatismo e
/// verticalidade; Benazzi/Mazola representam fases mais reativas/diretas;
/// Alberto Félix amplia o polo adaptativo/flexível do conjunto histórico.
const bragantinoTacticalCoachReferences = <TacticalCoachReference>[
  TacticalCoachReference(
    id: 'vanderlei_luxemburgo_1989',
    coach: 'Vanderlei Luxemburgo',
    period: '1989–1990',
    x: 20,
    y: 78,
    confidence: 'high',
    pressing: 48,
    blockHeight: 42,
    risk: 68,
    structuralFluidity: 72,
  ),
  TacticalCoachReference(
    id: 'carlos_alberto_parreira_1991',
    coach: 'Carlos Alberto Parreira',
    period: '1991',
    x: -30,
    y: 25,
    confidence: 'high',
    pressing: 38,
    blockHeight: 45,
    risk: 32,
    structuralFluidity: 46,
  ),
  TacticalCoachReference(
    id: 'marcelo_veiga_2018',
    coach: 'Marcelo Veiga',
    period: '2018',
    x: 70,
    y: 55,
    confidence: 'medium',
    pressing: 34,
    blockHeight: 26,
    risk: 45,
    structuralFluidity: 38,
  ),
  TacticalCoachReference(
    id: 'antonio_carlos_zago_2019',
    coach: 'Antônio Carlos Zago',
    period: '2019',
    x: -55,
    y: -40,
    confidence: 'high',
    pressing: 76,
    blockHeight: 68,
    risk: 66,
    structuralFluidity: 58,
  ),
  TacticalCoachReference(
    id: 'mauricio_barbieri_2020',
    coach: 'Maurício Barbieri',
    period: '2020–2022',
    x: -25,
    y: -62,
    confidence: 'high',
    pressing: 78,
    blockHeight: 70,
    risk: 44,
    structuralFluidity: 40,
  ),
  TacticalCoachReference(
    id: 'pedro_caixinha_2023',
    coach: 'Pedro Caixinha',
    period: '2023–2024',
    x: 35,
    y: -70,
    confidence: 'high',
    pressing: 88,
    blockHeight: 84,
    risk: 74,
    structuralFluidity: 66,
  ),

  // Início de 2020: time agressivo sem a bola, intenso e com pressão alta,
  // mas ainda com preferência por circulação/posse objetiva.
  TacticalCoachReference(
    id: 'felipe_conceicao_2020',
    coach: 'Felipe Conceição',
    period: '2020',
    x: -46,
    y: -54,
    confidence: 'high',
    pressing: 88,
    blockHeight: 70,
    risk: 78,
    structuralFluidity: 49,
  ),

  // 2024–2025: 4-3-3, pressão alta e jogo híbrido — constrói quando pode,
  // mas acelera bastante quando encontra espaço.
  TacticalCoachReference(
    id: 'fernando_seabra_2024',
    coach: 'Fernando Seabra',
    period: '2024–2025',
    x: -9,
    y: -16,
    confidence: 'high',
    pressing: 92,
    blockHeight: 78,
    risk: 66,
    structuralFluidity: 76,
  ),

  // 2026: abordagem mais vertical/adaptativa, intensidade alta sem a rigidez
  // extrema dos modelos de Caixinha/Barbieri.
  TacticalCoachReference(
    id: 'vagner_mancini_2026',
    coach: 'Vagner Mancini',
    period: '2026',
    x: 45,
    y: 19,
    confidence: 'medium',
    pressing: 87,
    blockHeight: 76,
    risk: 68,
    structuralFluidity: 63,
  ),

  // 2012: perfil direto e reativo, com bloco mais baixo e muita adaptação à
  // circunstância da partida.
  TacticalCoachReference(
    id: 'vagner_benazzi_2012',
    coach: 'Vagner Benazzi',
    period: '2012',
    x: 52,
    y: 62,
    confidence: 'medium',
    pressing: 28,
    blockHeight: 28,
    risk: 42,
    structuralFluidity: 75,
  ),

  // 2013: jogo direto, forte leitura do adversário e preferência por
  // transição em vez de controlar longos trechos pela posse.
  TacticalCoachReference(
    id: 'mazola_junior_2013',
    coach: 'Mazola Júnior',
    period: '2013',
    x: 56,
    y: 83,
    confidence: 'medium',
    pressing: 45,
    blockHeight: 38,
    risk: 36,
    structuralFluidity: 71,
  ),

  // 2017: referência central/pragmática e altamente flexível — útil para
  // separar resultados que não pertencem aos extremos posse/vertical.
  TacticalCoachReference(
    id: 'alberto_felix_2017',
    coach: 'Alberto Félix',
    period: '2017',
    x: -15,
    y: 62,
    confidence: 'medium',
    pressing: 48,
    blockHeight: 49,
    risk: 47,
    structuralFluidity: 80,
  ),
];

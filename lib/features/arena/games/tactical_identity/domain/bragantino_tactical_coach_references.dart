import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Os 6 técnicos do Bragantino no jogo "Identidade Futebolística".
///
/// COMO ESTES NÚMEROS FORAM DEFINIDOS — leia antes de mexer.
///
/// Não são conversão do pacote de origem. `docs/bragantino_data/new_data/
/// perfil_tecnico_bragantino_v1.json` traz 8 traços achatados (`posse`,
/// `verticalidade`, `pressao_alta`, `bloco_baixo`, `flexibilidade`,
/// `gestao`, `juventude`, `ousadia`) numa escala 1–10, que não é a
/// geometria deste motor. Mapear aquilo por fórmula pros dois eixos mais as
/// quatro auxiliares daria números sem lastro. Os campos `evidence` e
/// `identity` foram lidos como evidência; a posição de cada técnico foi
/// decidida editorialmente aqui.
///
/// GEOMETRIA (ver `tactical_identity_engine.dart`):
///   x  negativo = POSSE, positivo = VERTICAL  (`posse% = (100 - x) / 2`)
///   y  negativo = DOGMÁTICO, positivo = PRAGMÁTICO
/// As quatro auxiliares (0–100) nunca aparecem em tela — só entram na
/// afinidade, e existem justamente pra separar técnicos que caem perto no
/// mapa 2D e são bem diferentes na prática.
///
/// Distâncias com a MÉTRICA PONDERADA do motor
/// (`0,225·dx² + 0,225·dy² + 0,1375·Σauxiliares²`, em z-space): mínima
/// 0,556, mediana 1,476, máxima 2,396. O dataset do Goiás, medido do mesmo
/// jeito, tem mínima 0,470 — este conjunto está mais espalhado, sem nenhum
/// valor mexido pra forçar isso.
///
/// O par mais próximo é Zago × Caixinha (0,556) e a proximidade é
/// LEGÍTIMA: são as duas leituras mais radicais do modelo de pressão do
/// clube. Ficam separados mesmo assim por pressão, altura de bloco e risco.
const bragantinoTacticalCoachReferences = <TacticalCoachReference>[
  // "Variava a estratégia conforme o adversário", com um plano específico
  // pra controlar o São Paulo em 1989: pragmatismo no talo (y +78) e a
  // maior fluidez estrutural do conjunto (72) — a forma muda por jogo.
  // Bloco mais recuado porque a evidência é sobre CONTROLAR, não sufocar.
  TacticalCoachReference(
    id: 'vanderlei_luxemburgo_1989',
    coach: 'Vanderlei Luxemburgo',
    period: '1989–1990',
    x: 20,
    y: 78,
    confidence: 'high',
    pressing: 48,
    blockHeight: 42,
    risk: 62,
    structuralFluidity: 72,
  ),

  // "Organização, equilíbrio, controle": posse moderada (x -30), risco
  // baixo (32) e a segunda menor fluidez (34) — estrutura fixa é o ponto.
  // Pragmático, mas bem menos que Luxemburgo: aqui o equilíbrio é o
  // princípio, não a adaptação ao adversário.
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
    structuralFluidity: 34,
  ),

  // Adversários descreviam o time de 2018 como "mais defensivo e perigoso
  // em contra-ataques": é a definição de vertical (x +70, o maior) com
  // bloco baixo (26, o menor) e pressão baixa (34). Espera e sai rápido.
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

  // "Posse alta, saída rápida, pressão pós-perda, liberdade ofensiva": a
  // posição mais de posse do conjunto (x -55). Dogmático, mas o menos
  // dogmático dos três da era do modelo — "liberdade ofensiva" implica
  // menos amarração, daí risco 66 e fluidez 58.
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

  // "Continuidade do modelo" e "organização posicional" — dogmatismo alto
  // (y -62) com a fluidez mais baixa dos três da era (40): posição definida
  // é o método. Risco 52, o menor do trio, porque a evidência fala em
  // organização, não em ousadia.
  TacticalCoachReference(
    id: 'mauricio_barbieri_2020',
    coach: 'Maurício Barbieri',
    period: '2020–2022',
    x: -25,
    y: -62,
    confidence: 'high',
    pressing: 78,
    blockHeight: 70,
    risk: 52,
    structuralFluidity: 40,
  ),

  // "Construção no campo rival", "linha alta", "forte pressão",
  // "mobilidade": leva ao extremo as três auxiliares que definem a era —
  // pressão 88, bloco 84 e risco 74, os maiores do conjunto — e é o mais
  // dogmático (y -70). "Mobilidade" sustenta fluidez 66.
  TacticalCoachReference(
    id: 'pedro_caixinha_2023',
    coach: 'Pedro Caixinha',
    period: '2023–2024',
    x: -40,
    y: -70,
    confidence: 'high',
    pressing: 88,
    blockHeight: 84,
    risk: 74,
    structuralFluidity: 66,
  ),
];

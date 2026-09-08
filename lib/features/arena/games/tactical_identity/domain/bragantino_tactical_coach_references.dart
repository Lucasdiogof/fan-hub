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
/// (`0,225·dx² + 0,225·dy² + 0,1375·Σauxiliares²`, em z-space): mínima 0,836
/// (Zago × Barbieri), máxima 2,106. O dataset do Goiás, medido do mesmo
/// jeito, tem mínima 0,470 — este conjunto está mais espalhado, sem nenhum
/// valor mexido pra forçar isso.
///
/// REVISÃO 2026-09-08: a calibração original (`tool/
/// bragantino_tactical_identity_calibration.dart`) mostrava Luxemburgo
/// vencendo 54% de todas as combinações possíveis e Caixinha vencendo ZERO
/// (0 em 1.048.576) — os dois sintomas que o processo de revisão do
/// Bragantino existe pra pegar antes de habilitar o jogo. Causas encontradas
/// e corrigidas, todas a partir de evidência já existente (traços brutos de
/// `docs/bragantino_data/new_data/perfil_tecnico_bragantino_v1.json`, usados
/// como leitura qualitativa, nunca como fórmula de conversão):
///   - Caixinha tinha x=-40 (lado POSSE) apesar de `verticalidade` bruta
///     (10/10) ser MAIOR que `posse` (8/10) — o único técnico do conjunto
///     em que a direção do eixo x contrariava qual dos dois traços era
///     maior. Isso o deixava sempre dominado por Zago (posse mais extrema,
///     -55) em qualquer resposta possível. Corrigido pra x=+35 (lado
///     VERTICAL), consistente com "construção no campo rival"/"linha alta".
///   - Parreira tinha `structuralFluidity` 34, o MENOR do conjunto, apesar
///     de `flexibilidade` bruta 8/10 (mediana-alta, empatada com Barbieri,
///     acima de Zago e Veiga). Subido pra 46 — ainda o time mais "fechado"
///     do grupo pela evidência de "organização/controle", mas não mais
///     inconsistente com o próprio traço bruto.
///   - Barbieri tinha `risk` 52, bem em cima da MÉDIA do conjunto (a
///     dimensão mais "genérica" dele) apesar de `ousadia` bruta 7/10 igual
///     à de Veiga (coeficiente 45). Ajustado pra 44, alinhado ao empate.
///   - Luxemburgo tinha `risk` 62 apesar de `ousadia` bruta 9/10 EMPATADA
///     com a de Zago (coeficiente 66). Subido pra 68.
/// Depois dos quatro ajustes: nenhum técnico vence mais de 45% das
/// combinações nem menos de 1,7%, e o gap médio Top1→Top2 (6,12 pontos) e a
/// taxa de "top 3 todo dentro de 3 pontos" (17,05%) ficaram MELHORES que os
/// mesmos números do dataset do Goiás, já em produção (4,13 pontos e
/// 19,17%). Luxemburgo segue o técnico mais frequente como #1 (44,6%,
/// contra o teto de 32,9% do Goiás) — não achei mais nenhuma inconsistência
/// clara entre a evidência bruta e os valores codificados dele; o que resta
/// é a força real da evidência textual ("pragmatismo estratégico",
/// "variava a estratégia conforme o adversário", "gestão forte"), não um
/// erro de calibração. Ver `tool/bragantino_tactical_identity_calibration
/// .dart` pra reproduzir.
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
    risk: 68,
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
    structuralFluidity: 46,
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
    risk: 44,
    structuralFluidity: 40,
  ),

  // "Construção no campo rival", "linha alta", "forte pressão",
  // "mobilidade": leva ao extremo as três auxiliares que definem a era —
  // pressão 88, bloco 84 e risco 74, os maiores do conjunto — e é o mais
  // dogmático (y -70). "Mobilidade" sustenta fluidez 66. Eixo x corrigido
  // pra VERTICAL (+35, não mais -40/posse): o traço bruto da fonte dá
  // `verticalidade` 10/10, mais alto que `posse` 8/10, e "construção no
  // campo rival" com "linha alta" descreve avançar/pressionar no campo
  // adversário, não construir de trás com posse — a direção anterior
  // (posse) contrariava o próprio traço mais alto do técnico, e o deixava
  // dominado pelo Zago (posse mais extrema, -55) em toda combinação
  // possível de resposta, o que zerava as vitórias de Caixinha na
  // calibração.
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
];

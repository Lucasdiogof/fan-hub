import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// As 12 referências históricas de passagens de técnicos pelo Goiás usadas
/// pelo jogo "Identidade Futebolística".
///
/// IMPORTANTE (repetido do pedido original, pra quem for mexer aqui
/// depois): `x`/`y` são dados EDITORIAIS do jogo, não estatísticas oficiais.
/// Classificam uma PASSAGEM ESPECÍFICA do treinador pelo Goiás, nunca a
/// carreira dele inteira. NUNCA alterar essas coordenadas durante uma
/// implementação — qualquer recalibração é decisão explícita, feita aqui e
/// em nenhum outro lugar (a UI nunca deve depender do valor exato, só
/// consumir esta lista).
///
/// `pressing`/`blockHeight`/`risk`/`structuralFluidity` (0–100) foram
/// adicionados na recalibração v2 (2026-09-01) — critério editorial baseado
/// no estilo geral conhecido de cada treinador, adaptado ao que se sabe da
/// passagem específica pelo Goiás sempre que possível; `confidence` reflete
/// quando a evidência disponível é mais fraca (a maioria dos casos aqui,
/// dado que são detalhes táticos de passagens antigas por um clube — nunca
/// tratar como fato apurado, é a mesma natureza editorial do resto do
/// dataset).
///
/// Os valores das 4 dimensões ocultas passaram por DUAS correções na v2:
///
/// 1. RECENTRAMENTO — a primeira versão editorial usava uma escala cuja
///    média (~44–50) não batia com a média empírica do que o questionário
///    de 10 perguntas realmente consegue produzir pro usuário (~54–57,
///    medido via `tool/tactical_identity_calibration.dart`). Isso distorcia
///    a afinidade mesmo com z-score, do mesmo jeito que aconteceu no
///    dataset de jogadores (ver `player_identity_references.dart`).
/// 2. DESCORRELAÇÃO — a primeira tentativa de recentramento só deslocou os
///    4 valores originais uniformemente, mas os 4 originais já
///    variavam JUNTOS por técnico (quem tinha pressing alto também tinha
///    bloco/risco/fluidez altos) — na prática um único fator "intensidade"
///    repetido 4x, que dominava a afinidade por pura compounding de 4
///    dimensões correlacionadas (medido: 1 técnico passou a aparecer em
///    ~40% dos resultados como #1, pior que antes da recalibração). Os
///    valores abaixo foram redesenhados pra variar cada dimensão de forma
///    mais independente por técnico — ex.: Enderson/Barbieri (posse
///    paciente) ficam com pressing/risco baixos mas fluidez estrutural
///    alta; Zanardi (construção pelo chão) fica com risco baixo e fluidez
///    alta, não "média em tudo" — refletindo que essas características
///    táticas reais não andam sempre juntas.
///
/// `x`/`y` NÃO foram alterados — continuam exatamente os valores editoriais
/// originais, porque alimentam o mapa e o texto visíveis ao usuário (não é
/// só matemática interna).
const tacticalCoachReferences = <TacticalCoachReference>[
  TacticalCoachReference(
    id: 'cuca_2003',
    coach: 'Cuca',
    period: '2003',
    x: 45,
    y: 80,
    confidence: 'high',
    pressing: 62,
    blockHeight: 58,
    risk: 61,
    structuralFluidity: 53,
  ),
  TacticalCoachReference(
    id: 'helio_2008_2010',
    coach: 'Hélio dos Anjos',
    period: '2008–2010',
    x: 30,
    y: -30,
    confidence: 'high',
    pressing: 40,
    blockHeight: 32,
    risk: 36,
    structuralFluidity: 33,
  ),
  TacticalCoachReference(
    id: 'geninho_2005_2006',
    coach: 'Geninho',
    period: '2005–2006',
    x: 60,
    y: -15,
    confidence: 'medium',
    pressing: 48,
    blockHeight: 50,
    risk: 48,
    structuralFluidity: 35,
  ),
  TacticalCoachReference(
    id: 'caio_junior_2008',
    coach: 'Caio Júnior',
    period: '2008',
    x: 5,
    y: 20,
    confidence: 'medium',
    pressing: 64,
    blockHeight: 68,
    risk: 78,
    structuralFluidity: 63,
  ),
  TacticalCoachReference(
    id: 'enderson_2011_2013',
    coach: 'Enderson Moreira',
    period: '2011–2013',
    x: -30,
    y: 70,
    confidence: 'high',
    pressing: 42,
    blockHeight: 40,
    risk: 44,
    structuralFluidity: 73,
  ),
  TacticalCoachReference(
    id: 'ney_franco_2018',
    coach: 'Ney Franco',
    period: '2018',
    x: 10,
    y: 55,
    confidence: 'medium',
    pressing: 52,
    blockHeight: 54,
    risk: 60,
    structuralFluidity: 57,
  ),
  TacticalCoachReference(
    id: 'barbieri_2019',
    coach: 'Maurício Barbieri',
    period: '2019',
    x: -65,
    y: -30,
    confidence: 'high',
    pressing: 44,
    blockHeight: 60,
    risk: 46,
    structuralFluidity: 71,
  ),
  TacticalCoachReference(
    id: 'claudinei_2019',
    coach: 'Claudinei Oliveira',
    period: '2019',
    x: 60,
    y: 50,
    confidence: 'high',
    pressing: 56,
    blockHeight: 50,
    risk: 66,
    structuralFluidity: 45,
  ),
  TacticalCoachReference(
    id: 'jair_2022',
    coach: 'Jair Ventura',
    period: '2022',
    x: 65,
    y: 85,
    confidence: 'high',
    pressing: 82,
    blockHeight: 74,
    risk: 86,
    structuralFluidity: 67,
  ),
  TacticalCoachReference(
    id: 'armando_2023',
    coach: 'Armando Evangelista',
    period: '2023',
    x: 10,
    y: 90,
    confidence: 'low',
    pressing: 50,
    blockHeight: 50,
    risk: 54,
    structuralFluidity: 53,
  ),
  TacticalCoachReference(
    id: 'zanardi_2024',
    coach: 'Márcio Zanardi',
    period: '2024',
    x: -15,
    y: 45,
    confidence: 'medium',
    pressing: 50,
    blockHeight: 52,
    risk: 44,
    structuralFluidity: 69,
  ),
  TacticalCoachReference(
    id: 'mancini_2024',
    coach: 'Vagner Mancini',
    period: '2024',
    x: -35,
    y: 50,
    confidence: 'high',
    pressing: 54,
    blockHeight: 62,
    risk: 50,
    structuralFluidity: 51,
  ),
];

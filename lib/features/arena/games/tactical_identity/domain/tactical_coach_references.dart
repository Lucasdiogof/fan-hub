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
const tacticalCoachReferences = <TacticalCoachReference>[
  TacticalCoachReference(
    id: 'cuca_2003',
    coach: 'Cuca',
    period: '2003',
    x: 45,
    y: 80,
    confidence: 'high',
  ),
  TacticalCoachReference(
    id: 'helio_2008_2010',
    coach: 'Hélio dos Anjos',
    period: '2008–2010',
    x: 30,
    y: -30,
    confidence: 'high',
  ),
  TacticalCoachReference(
    id: 'geninho_2005_2006',
    coach: 'Geninho',
    period: '2005–2006',
    x: 60,
    y: -15,
    confidence: 'medium',
  ),
  TacticalCoachReference(
    id: 'caio_junior_2008',
    coach: 'Caio Júnior',
    period: '2008',
    x: 5,
    y: 20,
    confidence: 'medium',
  ),
  TacticalCoachReference(
    id: 'enderson_2011_2013',
    coach: 'Enderson Moreira',
    period: '2011–2013',
    x: -30,
    y: 70,
    confidence: 'high',
  ),
  TacticalCoachReference(
    id: 'ney_franco_2018',
    coach: 'Ney Franco',
    period: '2018',
    x: 10,
    y: 55,
    confidence: 'medium',
  ),
  TacticalCoachReference(
    id: 'barbieri_2019',
    coach: 'Maurício Barbieri',
    period: '2019',
    x: -65,
    y: -30,
    confidence: 'high',
  ),
  TacticalCoachReference(
    id: 'claudinei_2019',
    coach: 'Claudinei Oliveira',
    period: '2019',
    x: 60,
    y: 50,
    confidence: 'high',
  ),
  TacticalCoachReference(
    id: 'jair_2022',
    coach: 'Jair Ventura',
    period: '2022',
    x: 65,
    y: 85,
    confidence: 'high',
  ),
  TacticalCoachReference(
    id: 'armando_2023',
    coach: 'Armando Evangelista',
    period: '2023',
    x: 10,
    y: 90,
    confidence: 'high',
  ),
  TacticalCoachReference(
    id: 'zanardi_2024',
    coach: 'Márcio Zanardi',
    period: '2024',
    x: -15,
    y: 45,
    confidence: 'medium',
  ),
  TacticalCoachReference(
    id: 'mancini_2024',
    coach: 'Vagner Mancini',
    period: '2024',
    x: -35,
    y: 50,
    confidence: 'high',
  ),
];

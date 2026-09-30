import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Referências do Vila Nova pro jogo "Identidade Futebolística".
///
/// v1 (2026-09-29) — 6 técnicos, convertidos editorialmente do pacote de
/// pesquisa `docs/vila_nova_data/arena/tactical_identity.json` (8 dimensões
/// em português, formato incompatível com o motor). `x`/`y` e as 4
/// dimensões ocultas (`pressing/blockHeight/risk/structuralFluidity`) foram
/// lidos a partir dos `trait_evidence` originais (declarações dos próprios
/// técnicos à imprensa, fonte `ge`), nunca gerados automaticamente da nota
/// 0–10 do pacote — e depois ajustados dentro da faixa que a evidência
/// sustenta pra nenhum técnico dominar/ficar inalcançável (mesmo processo
/// de calibração do Bragantino, sobre estes 6).
///
/// Gate: `dart run tool/vilanova_tactical_identity_calibration.dart`
/// (enumeração completa das 4^10 combinações) — os 6 técnicos ficam entre
/// 16,5% e 16,8% como referência #1 (nenhum nunca aparece, nenhum domina),
/// gap médio Top1→Top2 de 1,89 pontos.
const vilanovaTacticalCoachReferences = <TacticalCoachReference>[
  // 2015 / 2020: pragmático, mata-mata, sabia alternar domínio com bloco
  // mais baixo e contra-ataque — campeão da Série C nas duas passagens.
  TacticalCoachReference(
    id: 'vn_coach_profile_marcio_fernandes',
    coach: 'Márcio Fernandes',
    period: '2015 / 2020',
    x: 40,
    y: 60,
    confidence: 'high',
    pressing: 55,
    blockHeight: 45,
    risk: 26,
    structuralFluidity: 53,
  ),

  // 2022: ideia vertical (citava Atlético-MG e Abel Ferreira), identidade
  // ofensiva agressiva com organização defensiva iniciada no ataque.
  TacticalCoachReference(
    id: 'vn_coach_profile_higo_magalhaes',
    coach: 'Higo Magalhães',
    period: '2022',
    x: 53,
    y: -21,
    confidence: 'high',
    pressing: 80,
    blockHeight: 68,
    risk: 58,
    structuralFluidity: 62,
  ),

  // 2022: simplicidade e objetividade declaradas, pedia o menor número de
  // erros possível — perfil pragmático de controle de risco.
  TacticalCoachReference(
    id: 'vn_coach_profile_allan_aal',
    coach: 'Allan Aal',
    period: '2022',
    x: -31,
    y: 46,
    confidence: 'medium',
    pressing: 34,
    blockHeight: 43,
    risk: 16,
    structuralFluidity: 54,
  ),

  // 2024: intensidade e transição rápida como eixo central, time
  // competitivo que "corre, marca e joga".
  TacticalCoachReference(
    id: 'vn_coach_profile_luizinho_lopes',
    coach: 'Luizinho Lopes',
    period: '2024',
    x: 62,
    y: 24,
    confidence: 'high',
    pressing: 85,
    blockHeight: 65,
    risk: 60,
    structuralFluidity: 58,
  ),

  // 2024–2025: organização defensiva e solidez como princípio central,
  // campeão goiano de 2025 negando rótulo de retranqueiro ("aqui se chama
  // organizado").
  TacticalCoachReference(
    id: 'vn_coach_profile_rafael_lacerda',
    coach: 'Rafael Lacerda',
    period: '2024–2025',
    x: -20,
    y: 74,
    confidence: 'high',
    pressing: 69,
    blockHeight: 50,
    risk: 15,
    structuralFluidity: 60,
  ),

  // 2025: intensidade máxima em todos os momentos, ataque com quatro
  // jogadores na área e cinturão defensivo para proteger a transição.
  TacticalCoachReference(
    id: 'vn_coach_profile_paulo_turra',
    coach: 'Paulo Turra',
    period: '2025',
    x: 50,
    y: -50,
    confidence: 'high',
    pressing: 92,
    blockHeight: 83,
    risk: 51,
    structuralFluidity: 44,
  ),
];

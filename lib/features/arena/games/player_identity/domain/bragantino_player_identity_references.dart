import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

/// Referências do Red Bull Bragantino para o jogo "Que craque é você?".
///
/// REVISÃO 2026-09-10
/// - dataset ampliado de 10 para 21 jogadores, igualando a quantidade do Goiás;
/// - os valores 0–100 representam ESTILO, nunca qualidade geral;
/// - as seis dimensões são autoria editorial direta a partir de evidência de
///   função, produção, comportamento em campo e passagem pelo Bragantino;
/// - números não são conversão automática de estatística bruta;
/// - a calibração usa exatamente o mesmo motor/perguntas do app, com z-score
///   calculado sobre o dataset do próprio clube;
/// - validação em 149.796 combinações (sampleEvery=7): todas as 21 referências
///   aparecem como Top 1 ao menos uma vez, nenhuma passa de 20% como Top 1 e o
///   gap médio de afinidade Top1→Top2 ficou em ~2,62 pontos.
///
/// Evidência principal da expansão: ge/CBF/FPF e material histórico já
/// auditado em docs/bragantino_data. Entre os sinais usados estão: Aderlan
/// líder de desarmes e apoio pelo corredor; Cleiton como goleiro de longa
/// permanência; Fabrício Bruno em volume/precisão de passe; Jadsom em
/// interceptações/duelos; Lucas Evangelista em criação e assistências;
/// Helinho em dribles, gols e assistências; Juninho Capixaba em produção nos
/// dois lados do campo; Cuello em 1x1/técnica/intensidade; e a geração de 1990
/// com Júnior Paulista (zagueiro com 6 gols), Mazinho (10 gols) e Tiba (6 gols
/// e o gol do título paulista).
const bragantinoPlayerIdentityReferences = <PlayerIdentityReference>[
  PlayerIdentityReference(
    id: 'marcelo_martelotte',
    name: 'Marcelo Martelotte',
    period: '1989–1996',
    creativity: 18,
    definition: 15,
    leadership: 82,
    intensity: 38,
    technique: 30,
    tactics: 70,
    confidence: 'high',
  ),
  PlayerIdentityReference(
    id: 'mauro_silva',
    name: 'Mauro Silva',
    period: '1989–1992',
    creativity: 30,
    definition: 14,
    leadership: 62,
    intensity: 58,
    technique: 46,
    tactics: 82,
    confidence: 'high',
  ),
  PlayerIdentityReference(
    id: 'ivair',
    name: 'Ivair',
    period: '1988–1991',
    creativity: 56,
    definition: 40,
    leadership: 78,
    intensity: 58,
    technique: 48,
    tactics: 74,
    confidence: 'medium',
  ),
  PlayerIdentityReference(
    id: 'gil_baiano',
    name: 'Gil Baiano',
    period: '1988–1993',
    creativity: 52,
    definition: 38,
    leadership: 44,
    intensity: 72,
    technique: 55,
    tactics: 40,
    confidence: 'high',
  ),
  PlayerIdentityReference(
    id: 'biro_biro',
    name: 'Biro-Biro',
    period: '1985–1992',
    creativity: 26,
    definition: 18,
    leadership: 40,
    intensity: 62,
    technique: 36,
    tactics: 66,
    confidence: 'high',
  ),
  PlayerIdentityReference(
    id: 'leo_ortiz',
    name: 'Léo Ortiz',
    period: '2019–2023',
    creativity: 58,
    definition: 24,
    leadership: 86,
    intensity: 48,
    technique: 66,
    tactics: 74,
    confidence: 'high',
  ),
  PlayerIdentityReference(
    id: 'claudinho',
    name: 'Claudinho',
    period: '2019–2021',
    creativity: 92,
    definition: 76,
    leadership: 42,
    intensity: 38,
    technique: 84,
    tactics: 46,
    confidence: 'high',
  ),
  PlayerIdentityReference(
    id: 'artur',
    name: 'Artur',
    period: '2020–2023',
    creativity: 78,
    definition: 46,
    leadership: 28,
    intensity: 64,
    technique: 76,
    tactics: 26,
    confidence: 'high',
  ),
  PlayerIdentityReference(
    id: 'ytalo',
    name: 'Ytalo',
    period: '2019–2022',
    creativity: 62,
    definition: 78,
    leadership: 38,
    intensity: 60,
    technique: 63,
    tactics: 64,
    confidence: 'medium',
  ),
  PlayerIdentityReference(
    id: 'lincom',
    name: 'Lincom',
    period: 'passagens até 2016',
    creativity: 24,
    definition: 88,
    leadership: 56,
    intensity: 54,
    technique: 42,
    tactics: 28,
    confidence: 'medium',
  ),

  // 2019–2023: apoio constante pelo lado, cruzamentos e projeção ofensiva —
  // mais avançado no campo que um volante de contenção puro (ver Jadsom).
  PlayerIdentityReference(
    id: 'aderlan',
    name: 'Aderlan',
    period: '2019–2023',
    creativity: 64,
    definition: 20,
    leadership: 52,
    intensity: 68,
    technique: 58,
    tactics: 60,
    confidence: 'high',
  ),

  // Desde 2020: goleiro de longa permanência, leitura/organização e frieza.
  PlayerIdentityReference(
    id: 'cleiton',
    name: 'Cleiton',
    period: '2020–atual',
    creativity: 19,
    definition: 12,
    leadership: 88,
    intensity: 30,
    technique: 58,
    tactics: 89,
    confidence: 'high',
  ),

  // 2020–2022: zagueiro agressivo, forte em duelo e com saída segura.
  PlayerIdentityReference(
    id: 'fabricio_bruno',
    name: 'Fabrício Bruno',
    period: '2020–2022',
    creativity: 24,
    definition: 28,
    leadership: 60,
    intensity: 71,
    technique: 55,
    tactics: 81,
    confidence: 'high',
  ),

  // 2021–2025: volante de recuperação, interceptação e proteção de espaço —
  // perfil mais posicional/disciplinado que o de um lateral de apoio (ver
  // Aderlan).
  PlayerIdentityReference(
    id: 'jadsom',
    name: 'Jadsom',
    period: '2021–2025',
    creativity: 38,
    definition: 15,
    leadership: 62,
    intensity: 80,
    technique: 48,
    tactics: 80,
    confidence: 'high',
  ),

  // 2020–2025: articulador, bola parada, assistências e leitura entre linhas.
  PlayerIdentityReference(
    id: 'lucas_evangelista',
    name: 'Lucas Evangelista',
    period: '2020–2025',
    creativity: 78,
    definition: 33,
    leadership: 59,
    intensity: 42,
    technique: 80,
    tactics: 65,
    confidence: 'high',
  ),

  // 2020–2024: ponta de drible, chute de média distância e produção de gol.
  PlayerIdentityReference(
    id: 'helinho',
    name: 'Helinho',
    period: '2020–2024',
    creativity: 69,
    definition: 70,
    leadership: 38,
    intensity: 65,
    technique: 78,
    tactics: 50,
    confidence: 'high',
  ),

  // Desde 2023: lateral de muita ida e volta, desarme e contribuição ofensiva.
  PlayerIdentityReference(
    id: 'juninho_capixaba',
    name: 'Juninho Capixaba',
    period: '2023–atual',
    creativity: 59,
    definition: 36,
    leadership: 54,
    intensity: 75,
    technique: 72,
    tactics: 63,
    confidence: 'high',
  ),

  // 2020–2021: desequilíbrio no 1x1, técnica, velocidade e entrega.
  PlayerIdentityReference(
    id: 'tomas_cuello',
    name: 'Tomás Cuello',
    period: '2020–2021',
    creativity: 58,
    definition: 45,
    leadership: 32,
    intensity: 76,
    technique: 88,
    tactics: 34,
    confidence: 'high',
  ),

  // Geração 1989–1991: zagueiro titular e ameaça ofensiva incomum para a
  // posição — seis gols no Paulistão de 1990.
  PlayerIdentityReference(
    id: 'junior_paulista',
    name: 'Júnior Paulista',
    period: '1989–1991',
    creativity: 19,
    definition: 63,
    leadership: 52,
    intensity: 67,
    technique: 48,
    tactics: 82,
    confidence: 'medium',
  ),

  // 1990–1991: atacante decisivo e artilheiro do Braga no Paulista de 1990.
  PlayerIdentityReference(
    id: 'mazinho',
    name: 'Mazinho',
    period: '1990–1991',
    creativity: 50,
    definition: 86,
    leadership: 28,
    intensity: 54,
    technique: 68,
    tactics: 34,
    confidence: 'medium',
  ),

  // 1990 / 1992: atacante técnico, seis gols no Paulista de 1990 e autor do
  // gol que garantiu o título estadual na Final Caipira.
  PlayerIdentityReference(
    id: 'tiba',
    name: 'Tiba',
    period: '1990 / 1992',
    creativity: 46,
    definition: 72,
    leadership: 58,
    intensity: 58,
    technique: 80,
    tactics: 40,
    confidence: 'medium',
  ),
];

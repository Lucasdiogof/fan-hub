import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

/// As 10 referências do Bragantino no jogo "Que craque é você?".
///
/// COMO ESTES NÚMEROS FORAM DEFINIDOS — leia antes de mexer.
///
/// Não são conversão do pacote de origem. `docs/bragantino_data/new_data/
/// perfil_jogador_bragantino_v1.json` traz um modelo de 8 traços achatados
/// (`visao_criacao`, `um_contra_um`, `presenca_area`, ...) numa escala 1–10
/// que NÃO é o schema deste motor. Converter aquilo por fórmula produziria
/// números com aparência de precisão e nenhuma base — a regra do projeto é
/// explícita: autoria editorial direta nas 6 dimensões reais, a partir da
/// evidência. Os campos `evidence`/`identity` daquele JSON foram usados como
/// MATÉRIA-PRIMA de leitura, nunca como entrada de cálculo.
///
/// ESCALA: mesma convenção do dataset do Goiás (`player_identity_references
/// .dart`) — 0–100 representando ESTILO, nunca qualidade geral, e o conjunto
/// centrado perto de 50 de propósito. Isso não é estética: o motor compara
/// por z-score contra as estatísticas do PRÓPRIO dataset, e uma cartela
/// centrada bem acima do que o questionário consegue produzir enviesa a
/// comparação a favor de quem responder mais "baixo/moderado". Médias
/// obtidas aqui (pós-revisão de Ivair e Ytalo, ver nota abaixo): criatividade
/// 49,6 / definição 43,7 / liderança 55,6 / intensidade 55,2 / técnica 54,6 /
/// tática 57,0.
///
/// `definition` ficou em 43,7, abaixo da faixa do Goiás (50,7), e isso é
/// deliberado: 6 dos 10 perfis são funções sem gol (goleiro, dois volantes,
/// dois laterais, um zagueiro) e a evidência de Mauro Silva diz
/// literalmente "zero gols no Paulistão 1990". Subir esses valores pra
/// fechar uma média seria inventar. O risco documentado pelo motor é o
/// dataset ficar centrado ALTO demais, não baixo.
///
/// PERÍODOS: vêm da pesquisa de carreira já verificada no repositório
/// (`tooling/bragantino_arena/generate_career_players_sql.mjs`), não do
/// pacote. Lincom e Ytalo não estão lá — por isso `confidence: 'medium'`.
///
/// Distâncias RMS em z-space (a MESMA métrica do motor): mínima 0,649
/// (Mauro Silva × Biro-Biro), máxima 2,406. Para comparação, o dataset do
/// Goiás tem mínima 0,290 (Harlei × Tadeu) — este conjunto está menos
/// aglomerado que o de lá, sem nenhum valor mexido artificialmente pra isso.
///
/// REVISÃO 2026-09-08 (Ivair e Ytalo): a calibração original (`tool/
/// bragantino_player_identity_calibration.dart`) mostrava Ivair vencendo
/// 48% de todas as combinações possíveis de resposta — sintoma de perfil
/// perto demais da média em quase toda dimensão (distância ao centroide a
/// menor do conjunto, 0,530, bem abaixo da segunda menor). A causa: só
/// `definition` e `leadership` tinham evidência textual direta; as outras
/// quatro dimensões ficaram em valores genéricos, sem base. A correção NÃO
/// inventou fatos novos — usou como leitura qualitativa os 8 traços brutos
/// já existentes em `docs/bragantino_data/new_data/
/// perfil_jogador_bragantino_v1.json` (explicitamente vetados como fórmula
/// de conversão, mas válidos como material de leitura): `leitura_tatica` de
/// Ivair é 9/10, quase igual ao 10/10 de Mauro Silva, e `presenca_area`/
/// `um_contra_um` bem acima dos de Mauro — evidência de um volante mais
/// completo e vertical, não um clone reduzido. Corrigir só o Ivair revelou
/// o mesmo padrão escondido em Ytalo (dominância subiu pra 30% assim que
/// Ivair parou de mascará-lo): `leitura_tatica` 8/10 e `competitividade`
/// 9/10 também estavam subaproveitados. Depois de ajustar os dois, nenhum
/// jogador passa de 20% de vitórias como #1 e todos vencem pelo menos uma
/// vez — ver o próprio arquivo de calibração para reproduzir.
const bragantinoPlayerIdentityReferences = <PlayerIdentityReference>[
  // Goleiro da geração de 1990, decisivo na final. "Frieza" e "proteção do
  // resultado" puxam tática e liderança pra cima e criatividade/definição
  // pro fundo da escala; intensidade fica média porque a evidência descreve
  // serenidade, não fúria.
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

  // "Leitura tática" é o traço que define o perfil — daí a maior tática do
  // conjunto (82). Definição em 14 é a evidência falando: zero gols no
  // Paulistão de 1990. Liderança alta mas não máxima: a fonte diz
  // "liderança silenciosa", não capitão vocal.
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

  // O outro volante de 1990, separado de Mauro Silva pela evidência —
  // incluindo os 8 traços brutos da fonte original (`visao_criacao`,
  // `um_contra_um`, `presenca_area`, `leitura_tatica`, ...), usados aqui só
  // como leitura qualitativa (nunca como fórmula de conversão). Essa leitura
  // mostra Ivair com `leitura_tatica` 9/10 — quase igual ao 10/10 de Mauro
  // Silva, não a "média genérica" que uma leitura só do texto sugeriria — e
  // `presenca_area`/`um_contra_um` bem acima dos de Mauro, o que casa com a
  // evidência direta de "chegada" e quatro gols no Paulistão (definição 40
  // contra 14) e "comando do setor", liderança vocal (78 contra 62). O
  // resultado é um volante mais completo e mais vertical que Mauro Silva —
  // não uma versão reduzida dele.
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

  // Lateral-direito "agressivo", de "apoio constante" e "energia": maior
  // intensidade do conjunto (72), tática baixa porque o perfil descrito é
  // de projeção, não de contenção. Três gols na competição sustentam
  // definição acima dos outros defensores.
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

  // O oposto exato do lateral do outro lado, e por evidência, não por
  // simetria forçada: "sustentação", "regularidade" e "disciplina" contra
  // "agressivo" e "chegada ofensiva". Tática 66 contra 40, criatividade 26
  // contra 52. "Combatividade" mantém a intensidade alta nos dois.
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

  // "Zagueiro construtor": criatividade 58 é altíssima pra posição e vem da
  // evidência direta ("peça da criação desde a defesa", lançamentos).
  // Capitão com "personalidade" dá a maior liderança do conjunto (86).
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

  // A evidência mais forte do conjunto inteiro: 108 passes para finalização
  // no Brasileirão 2020 (criatividade 92, a maior) somados a 18 gols na
  // mesma competição — um criador que também finaliza, o que justifica
  // definição 76 num meia.
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

  // Ponta de "drible", "velocidade" e "1x1": técnica e criatividade altas,
  // mas tática 26 (a menor) porque o perfil descrito é de duelo individual
  // e amplitude, não de função coletiva. Separa-se de Claudinho justamente
  // por definição (46 contra 76) e tática.
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

  // Artilheiro da Série B 2019, mas a evidência insiste em "movimentação",
  // "associação" e "ocupação de espaços" — por isso criatividade 62, bem
  // acima de um centroavante de área puro. Os traços brutos da fonte
  // original (mesma leitura qualitativa aplicada a Ivair) mostram
  // `leitura_tatica` 8/10 e `competitividade` 9/10 — tática e intensidade
  // estavam abaixo do que essa leitura sustenta; sobem para refletir isso,
  // sem tocar nos dois valores já evidenciados diretamente pelo texto
  // (definição, pelos gols; criatividade, pela "criação de espaços").
  PlayerIdentityReference(
    id: 'ytalo',
    name: 'Ytalo',
    period: '2019',
    creativity: 62,
    definition: 78,
    leadership: 38,
    intensity: 60,
    technique: 63,
    tactics: 64,
    confidence: 'medium',
  ),

  // "Referência de área" e "presença física" com 72 gols em 160 jogos:
  // maior definição do conjunto (88) e criatividade baixa (24). É o
  // contraponto do Ytalo — mesmo posto, perfis opostos, e a distância entre
  // os dois confirma isso.
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
];

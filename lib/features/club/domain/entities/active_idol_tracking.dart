import 'package:equatable/equatable.dart';

/// Baseline HISTÓRICO e AUDITADO dos números de um ídolo que ainda joga —
/// nunca "o número de hoje". Significa: "até a partida [throughMatchId]
/// (inclusive) o jogador tinha [appearances] jogos e [goals] gols pelo clube".
/// Tudo o que acontece DEPOIS dessa partida entra por cálculo sobre as
/// partidas reais (ver `computeIdolStats`), nunca por edição manual deste
/// número.
class IdolStatsBaseline extends Equatable {
  const IdolStatsBaseline({
    required this.appearances,
    required this.throughMatchId,
    required this.throughKickoff,
    required this.throughDate,
    this.goals,
  });

  /// Jogos pelo clube contabilizados até [throughMatchId], inclusive.
  final int appearances;

  /// Gols pelo clube até [throughMatchId], inclusive. `null` quando o
  /// baseline não tem gols auditados (nada é somado nesse caso).
  final int? goals;

  /// ID da PARTIDA (mesmo formato de `Match.id`, ex.: `onef-2669540`) que
  /// fecha o baseline. Ela já está dentro dos números acima e por isso NUNCA
  /// entra de novo no cálculo — protege contra dupla contagem mesmo que o
  /// provedor reordene ou reagende jogos.
  final String throughMatchId;

  /// Horário de início dessa partida, no MESMO formato bruto que o Worker
  /// manda em `Match.kickoff` (hora de parede de Brasília, sem fuso — ver
  /// `parseKickoffInstant`). Só contam partidas que começam DEPOIS dele.
  final String throughKickoff;

  /// Data de referência (ISO `yyyy-MM-dd`, Brasília) mostrada como "Números
  /// até dd/mm/aaaa" enquanto nenhuma partida posterior foi processada.
  final String throughDate;

  @override
  List<Object?> get props => [
    appearances,
    goals,
    throughMatchId,
    throughKickoff,
    throughDate,
  ];
}

/// Marca explícita de que um ídolo AINDA ESTÁ NO ELENCO e, portanto, seus
/// números evoluem: [baseline] + o que as partidas posteriores mostram. Só
/// quem recebe este objeto em `ClubIdol.tracking` ganha cálculo dinâmico —
/// "ativo" nunca é deduzido pelo período do ídolo.
class ActiveIdolTracking extends Equatable {
  const ActiveIdolTracking({
    required this.baseline,
    required this.providerPlayerId,
    required this.eventNames,
  });

  final IdolStatsBaseline baseline;

  /// ID do jogador no provedor das partidas (OneFootball — o número no fim
  /// de `/jogador/<slug>-<id>`). É o vínculo CANÔNICO com as escalações.
  final int providerPlayerId;

  /// Como o provedor escreve o nome dele em GOLS e SUBSTITUIÇÕES — esses
  /// eventos vêm só com o nome, sem ID. É usado apenas ali, apenas no lado
  /// do clube e nunca quando a escalação da mesma partida mostra um jogador
  /// de mesmo nome com OUTRO ID.
  final Set<String> eventNames;

  @override
  List<Object?> get props => [baseline, providerPlayerId, eventNames];
}

/// Números prontos pra exibir de um ídolo ativo.
class IdolStats extends Equatable {
  const IdolStats({
    required this.appearances,
    required this.goals,
    required this.asOfDate,
    this.isComplete = true,
    this.countedMatches = 0,
  });

  /// Só o baseline auditado, sem nenhuma partida posterior — é o que a tela
  /// mostra enquanto carrega e quando o carregamento falha.
  factory IdolStats.fromBaseline(IdolStatsBaseline baseline) => IdolStats(
    appearances: baseline.appearances,
    goals: baseline.goals,
    asOfDate: baseline.throughDate,
    isComplete: false,
  );

  final int appearances;
  final int? goals;

  /// Data (ISO `yyyy-MM-dd`, Brasília) até a qual os números valem: a da
  /// última partida posterior processada, ou a do baseline.
  final String asOfDate;

  /// `false` quando alguma partida posterior não pôde ser verificada (rede,
  /// provedor) — os números são, no mínimo, o baseline auditado.
  final bool isComplete;

  /// Quantas partidas posteriores ao baseline o jogador de fato disputou.
  final int countedMatches;

  @override
  List<Object?> get props => [
    appearances,
    goals,
    asOfDate,
    isComplete,
    countedMatches,
  ];
}

import 'package:equatable/equatable.dart';

enum CareerRoundStatus { playing, won, lost, revealed }

extension CareerRoundStatusName on CareerRoundStatus {
  bool get isDone => this != CareerRoundStatus.playing;
}

class CareerEntry extends Equatable {
  const CareerEntry({
    required this.period,
    required this.team,
    this.appearances,
    this.goals,
    this.loan = false,
    this.isGoias = false,
  });

  final String period;
  final String team;
  final int? appearances;
  final int? goals;
  final bool loan;
  final bool isGoias;

  @override
  List<Object?> get props => [period, team, appearances, goals, loan, isGoias];
}

/// Total combinado de um clube quando o jogador teve mais de uma passagem
/// por ele e a fonte só fecha o número somado, nunca por passagem
/// individual — nesse caso as `CareerEntry` daquele clube em [spells]
/// ficam com `appearances`/`goals` nulos (nunca um número adivinhado), e
/// este total mora aqui, separado, pra UI nunca fingir que pertence a uma
/// única passagem.
class CareerAggregateStat extends Equatable {
  const CareerAggregateStat({
    required this.club,
    required this.spells,
    this.appearances,
    this.goals,
    this.note,
  });

  final String club;

  /// Os `period` das passagens que este total cobre — só pra referência
  /// visual, não usado pra casar com `CareerEntry` (isso é feito pela
  /// ordem/clube na lista, nunca por comparação de texto).
  final List<String> spells;
  final int? appearances;
  final int? goals;
  final String? note;

  @override
  List<Object?> get props => [club, spells, appearances, goals, note];
}

class CareerPlayer extends Equatable {
  const CareerPlayer({
    required this.id,
    required this.answer,
    required this.acceptedAnswers,
    required this.clubCareer,
    this.nationalTeams = const [],
    this.aggregateStats = const [],
    this.position,
    this.imageAsset,
    this.personId,
  });

  final String id;
  final String answer;
  final List<String> acceptedAnswers;
  final List<CareerEntry> clubCareer;
  final List<CareerEntry> nationalTeams;
  final List<CareerAggregateStat> aggregateStats;
  final String? position;
  final String? imageAsset;

  /// Identidade canônica (people.id, Etapa F1) — null quando a
  /// reconciliação ainda não fechou uma pessoa aprovada com segurança
  /// suficiente pra este jogador (ver career_players_person_mapping.json).
  /// [id] continua sendo a chave do JOGO (progresso/ranking, nunca muda);
  /// [personId] é a identidade da PESSOA real, quando conhecida — os dois
  /// nunca devem ser confundidos.
  final String? personId;

  @override
  List<Object?> get props => [
    id,
    answer,
    acceptedAnswers,
    clubCareer,
    nationalTeams,
    aggregateStats,
    position,
    imageAsset,
    personId,
  ];
}

class CareerRoundState extends Equatable {
  const CareerRoundState({
    required this.playerId,
    required this.startedAt,
    this.wrongGuesses = const [],
    this.status = CareerRoundStatus.playing,
    this.completedAt,
  });

  final String playerId;
  final DateTime startedAt;
  final List<String> wrongGuesses;
  final CareerRoundStatus status;
  final DateTime? completedAt;

  int get attemptsUsed => wrongGuesses.length;
  int get attemptsToWin => wrongGuesses.length + 1;
  bool get isDone => status.isDone;

  CareerRoundState copyWith({
    List<String>? wrongGuesses,
    CareerRoundStatus? status,
    DateTime? completedAt,
  }) {
    return CareerRoundState(
      playerId: playerId,
      startedAt: startedAt,
      wrongGuesses: wrongGuesses ?? this.wrongGuesses,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'startedAt': startedAt.toIso8601String(),
    'wrongGuesses': wrongGuesses,
    'status': status.name,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory CareerRoundState.fromJson(Map<String, dynamic> json) {
    return CareerRoundState(
      playerId: json['playerId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      wrongGuesses: (json['wrongGuesses'] as List<dynamic>).cast<String>(),
      status: CareerRoundStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => CareerRoundStatus.playing,
      ),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    playerId,
    startedAt,
    wrongGuesses,
    status,
    completedAt,
  ];
}

import 'package:equatable/equatable.dart';

/// O quanto confiamos na escalação/formação registrada pra essa partida —
/// fontes antigas (anos 90/2000) às vezes só têm a formação "oficial" da
/// época, sem confirmação de titular por titular.
enum FormationConfidence { confirmed, probable, estimated }

/// Estado de uma letra depois de avaliada contra a resposta — nomes de
/// Wordle, não cores: quem decide a cor é a UI, isso aqui é só o resultado
/// da comparação.
enum LetterStatus { correct, present, absent }

/// Uma partida histórica do Goiás usada como puzzle — dados fixos, nunca
/// mudam durante uma rodada (quem muda é [LineupGameState], separado).
class LineupMatch extends Equatable {
  const LineupMatch({
    required this.id,
    required this.competition,
    required this.season,
    required this.phase,
    required this.date,
    this.venue,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.teamToGuess,
    required this.formation,
    required this.formationConfidence,
    required this.players,
  });

  final String id;
  final String competition;
  final String season;
  final String phase;
  final DateTime date;
  final String? venue;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;

  /// Qual dos dois times ([homeTeam] ou [awayTeam]) é a escalação a
  /// descobrir — quase sempre "Goiás", mas mantido explícito em vez de
  /// assumido, já que Goiás pode ter jogado em casa ou fora.
  final String teamToGuess;

  final String formation;
  final FormationConfidence formationConfidence;
  final List<LineupPlayer> players;

  @override
  List<Object?> get props => [
    id,
    competition,
    season,
    phase,
    date,
    venue,
    homeTeam,
    awayTeam,
    homeScore,
    awayScore,
    teamToGuess,
    formation,
    formationConfidence,
    players,
  ];
}

/// Um dos 11 titulares a descobrir.
class LineupPlayer extends Equatable {
  const LineupPlayer({
    required this.id,
    required this.position,
    required this.x,
    required this.y,
    required this.shirtNumber,
    required this.fullName,
    required this.displayName,
    required this.puzzleAnswer,
    required this.answerParts,
    required this.normalizedAnswer,
    this.aliases = const [],
    this.sourceUrl,
  });

  final String id;

  /// Sigla curta da posição (ex.: "ST", "CB", "GK") — usada só como legenda,
  /// nunca pra decidir onde a camisa aparece no campo (isso é [x]/[y]).
  final String position;

  /// Coordenadas relativas do campo, 0.0–1.0 em ambos os eixos. Vêm prontas
  /// do dataset (com [FormationLayoutService] como gerador de posições
  /// padrão quando um dataset novo ainda não tiver x/y curados à mão).
  final double x;
  final double y;

  /// `null` quando a fonte não confirmou o número daquela partida — a UI
  /// mostra a camisa sem número nesse caso, nunca um "?" (ver
  /// `LineupShirtButton`/`LineupGuessPage`).
  final int? shirtNumber;
  final String fullName;
  final String displayName;

  /// A resposta OFICIAL do puzzle — nunca derivada automaticamente de
  /// [fullName]. É o texto configurado no dataset, na grafia normal
  /// (acentos, maiúsculas de nome próprio).
  final String puzzleAnswer;

  /// Comprimento de cada "palavra" de [puzzleAnswer], na ordem em que
  /// aparecem — ex.: "CARLOS ALBERTO" → [6, 7]. Define a estrutura visual
  /// da grade (grupos separados, mas uma única sequência de letras pra
  /// digitação/validação).
  final List<int> answerParts;

  /// [puzzleAnswer] já normalizado (sem acento, maiúsculo, sem espaço/
  /// hífen/apóstrofo) — é contra isso que o [WordEvaluationService] compara,
  /// nunca contra [puzzleAnswer] cru.
  final String normalizedAnswer;

  /// Nomes alternativos/apelidos — não usados pra validar a grade (o
  /// tamanho fixo da grade é sempre o de [puzzleAnswer]), só pra busca ou
  /// estatísticas futuras.
  final List<String> aliases;

  final String? sourceUrl;

  @override
  List<Object?> get props => [
    id,
    position,
    x,
    y,
    shirtNumber,
    fullName,
    displayName,
    puzzleAnswer,
    answerParts,
    normalizedAnswer,
    aliases,
    sourceUrl,
  ];
}

/// Progresso de UM jogador dentro de uma rodada — as 11 instâncias são
/// totalmente independentes entre si (tentativas, teclado, solved/failed).
class LineupPlayerState extends Equatable {
  const LineupPlayerState({
    this.guesses = const [],
    this.keyboardState = const {},
    this.solved = false,
    this.failed = false,
  });

  /// Cada tentativa já avaliada, na ordem em que foi enviada.
  final List<LineupGuess> guesses;

  /// Letra normalizada → melhor estado já visto pra ela (nunca regride:
  /// correct > present > absent).
  final Map<String, LetterStatus> keyboardState;

  final bool solved;
  final bool failed;

  int get attemptsUsed => guesses.length;
  bool get isDone => solved || failed;

  LineupPlayerState copyWith({
    List<LineupGuess>? guesses,
    Map<String, LetterStatus>? keyboardState,
    bool? solved,
    bool? failed,
  }) {
    return LineupPlayerState(
      guesses: guesses ?? this.guesses,
      keyboardState: keyboardState ?? this.keyboardState,
      solved: solved ?? this.solved,
      failed: failed ?? this.failed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guesses': guesses.map((g) => g.toJson()).toList(),
      'keyboardState': keyboardState.map(
        (letter, status) => MapEntry(letter, status.name),
      ),
      'solved': solved,
      'failed': failed,
    };
  }

  factory LineupPlayerState.fromJson(Map<String, dynamic> json) {
    return LineupPlayerState(
      guesses: (json['guesses'] as List)
          .map((g) => LineupGuess.fromJson(g as Map<String, dynamic>))
          .toList(),
      keyboardState: (json['keyboardState'] as Map<String, dynamic>).map(
        (letter, status) =>
            MapEntry(letter, LetterStatus.values.byName(status as String)),
      ),
      solved: json['solved'] as bool,
      failed: json['failed'] as bool,
    );
  }

  @override
  List<Object?> get props => [guesses, keyboardState, solved, failed];
}

/// Uma tentativa já enviada e avaliada — guarda a palavra normalizada
/// digitada e o resultado letra a letra, pra não precisar reavaliar toda
/// vez que a UI é reconstruída.
class LineupGuess extends Equatable {
  const LineupGuess({required this.letters, required this.statuses});

  final String letters;
  final List<LetterStatus> statuses;

  Map<String, dynamic> toJson() => {
    'letters': letters,
    'statuses': statuses.map((s) => s.name).toList(),
  };

  factory LineupGuess.fromJson(Map<String, dynamic> json) {
    return LineupGuess(
      letters: json['letters'] as String,
      statuses: (json['statuses'] as List)
          .map((s) => LetterStatus.values.byName(s as String))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [letters, statuses];
}

/// Estado completo e persistível de uma rodada (uma partida jogada).
class LineupGameState extends Equatable {
  const LineupGameState({
    required this.matchId,
    required this.startedAt,
    this.completedAt,
    this.surrendered = false,
    this.playerStates = const {},
  });

  final String matchId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool surrendered;

  /// playerId → progresso daquele jogador.
  final Map<String, LineupPlayerState> playerStates;

  bool get isFinished => completedAt != null;

  LineupGameState copyWith({
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? surrendered,
    Map<String, LineupPlayerState>? playerStates,
  }) {
    return LineupGameState(
      matchId: matchId,
      startedAt: startedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      surrendered: surrendered ?? this.surrendered,
      playerStates: playerStates ?? this.playerStates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'surrendered': surrendered,
      'playerStates': playerStates.map(
        (id, state) => MapEntry(id, state.toJson()),
      ),
    };
  }

  factory LineupGameState.fromJson(Map<String, dynamic> json) {
    return LineupGameState(
      matchId: json['matchId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      surrendered: json['surrendered'] as bool,
      playerStates: (json['playerStates'] as Map<String, dynamic>).map(
        (id, state) => MapEntry(
          id,
          LineupPlayerState.fromJson(state as Map<String, dynamic>),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
    matchId,
    startedAt,
    completedAt,
    surrendered,
    playerStates,
  ];
}

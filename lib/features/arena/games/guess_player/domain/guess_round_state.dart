const maxGuessAttempts = 7;

/// Nível de blur (sigma) por tentativa já usada — índice 0 = antes de
/// qualquer palpite (mais embaçado, mas ainda dá pra reconhecer algum
/// padrão), índice 6 = na última tentativa disponível (a mais nítida, mas
/// nunca a ponto de entregar o rosto de graça). Ao acertar, o sigma vira 0
/// independente do índice.
const blurLevelsByAttempt = [22.0, 18.0, 15.0, 12.0, 9.0, 6.5, 4.5];

class GuessPlayerRoundState {
  const GuessPlayerRoundState({
    required this.secretPlayerId,
    this.guessedPlayerIds = const [],
    this.won = false,
    this.lost = false,
  });

  final String secretPlayerId;
  final List<String> guessedPlayerIds;
  final bool won;
  final bool lost;

  bool get isOver => won || lost;
  int get attemptsUsed => guessedPlayerIds.length;
  int get attemptsRemaining => maxGuessAttempts - attemptsUsed;

  double get blurSigma {
    if (won) return 0;
    final index = attemptsUsed.clamp(0, blurLevelsByAttempt.length - 1);
    return blurLevelsByAttempt[index];
  }

  GuessPlayerRoundState copyWith({
    List<String>? guessedPlayerIds,
    bool? won,
    bool? lost,
  }) {
    return GuessPlayerRoundState(
      secretPlayerId: secretPlayerId,
      guessedPlayerIds: guessedPlayerIds ?? this.guessedPlayerIds,
      won: won ?? this.won,
      lost: lost ?? this.lost,
    );
  }

  Map<String, dynamic> toJson() => {
    'secretPlayerId': secretPlayerId,
    'guessedPlayerIds': guessedPlayerIds,
    'won': won,
    'lost': lost,
  };

  factory GuessPlayerRoundState.fromJson(Map<String, dynamic> json) {
    return GuessPlayerRoundState(
      secretPlayerId: json['secretPlayerId'] as String,
      guessedPlayerIds: (json['guessedPlayerIds'] as List<dynamic>)
          .cast<String>(),
      won: json['won'] as bool,
      lost: json['lost'] as bool,
    );
  }
}

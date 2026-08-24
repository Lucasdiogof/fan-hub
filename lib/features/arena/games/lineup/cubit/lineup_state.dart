import 'package:equatable/equatable.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/shared/state/load_status.dart';

class LineupState extends Equatable {
  const LineupState({
    this.status = LoadStatus.initial,
    this.matches = const [],
    this.match,
    this.game,
    this.selectedPlayerId,
    this.currentGuessLetters = const [],
    this.justCompleted = false,
  });

  final LoadStatus status;

  /// Banco inteiro de partidas, na ordem em que devem ser navegadas — fixo,
  /// nunca muda durante a sessão (quem muda é [match], apontando pra uma
  /// posição diferente dessa mesma lista).
  final List<LineupMatch> matches;

  final LineupMatch? match;
  final LineupGameState? game;

  /// Id do jogador com a tela de adivinhação aberta — `null` quando está no
  /// campo. É a partir disso que a tela de adivinhação sabe qual jogador
  /// mostrar, sem precisar receber isso por parâmetro (fica só reagindo ao
  /// Cubit).
  final String? selectedPlayerId;

  /// Letras já digitadas na tentativa em andamento do jogador selecionado
  /// — só existe em memória, nunca persistido (uma tentativa incompleta se
  /// perde ao sair, como em qualquer Wordle; só tentativas ENVIADAS
  /// persistem).
  final List<String> currentGuessLetters;

  /// Sinal de "acabou de completar AGORA" — `true` só no instante em que
  /// [LineupCubit.submitGuess]/`giveUp` faz a partida atual virar
  /// completa, nunca como efeito colateral de navegar pra uma partida já
  /// concluída antes. A UI consome isso uma vez (mostra o diálogo de
  /// resultado) e chama `acknowledgeResultShown()`, que zera de volta —
  /// sem esse sinal dedicado, reabrir uma partida já concluída faria o
  /// diálogo pipocar de novo sozinho.
  final bool justCompleted;

  LineupPlayer? get selectedPlayer {
    if (match == null || selectedPlayerId == null) return null;
    for (final player in match!.players) {
      if (player.id == selectedPlayerId) return player;
    }
    return null;
  }

  LineupPlayerState get selectedPlayerState {
    final id = selectedPlayerId;
    if (id == null || game == null) return const LineupPlayerState();
    return game!.playerStates[id] ?? const LineupPlayerState();
  }

  int get solvedCount =>
      game?.playerStates.values.where((p) => p.solved).length ?? 0;

  int get failedCount =>
      game?.playerStates.values.where((p) => p.failed).length ?? 0;

  int get totalPlayers => match?.players.length ?? 0;

  int get totalAttempts =>
      game?.playerStates.values.fold<int>(
        0,
        (sum, p) => sum + p.attemptsUsed,
      ) ??
      0;

  bool get isComplete {
    final currentGame = game;
    final currentMatch = match;
    if (currentGame == null || currentMatch == null) return false;
    if (currentMatch.players.isEmpty) return false;
    return currentMatch.players.every((player) {
      final playerState = currentGame.playerStates[player.id];
      return playerState != null && playerState.isDone;
    });
  }

  Duration? get elapsed {
    final currentGame = game;
    if (currentGame == null) return null;
    final end = currentGame.completedAt ?? DateTime.now();
    return end.difference(currentGame.startedAt);
  }

  /// Posição (0-based) da partida atual dentro de [matches] — `null`
  /// enquanto nada foi carregado ainda.
  int? get currentIndex {
    final id = match?.id;
    if (id == null) return null;
    final index = matches.indexWhere((candidate) => candidate.id == id);
    return index == -1 ? null : index;
  }

  int get totalMatches => matches.length;

  bool get hasPrevious => (currentIndex ?? 0) > 0;

  bool get hasNext {
    final index = currentIndex;
    return index != null && index < matches.length - 1;
  }

  LineupState copyWith({
    LoadStatus? status,
    List<LineupMatch>? matches,
    LineupMatch? match,
    LineupGameState? game,
    String? selectedPlayerId,
    bool clearSelectedPlayer = false,
    List<String>? currentGuessLetters,
    bool? justCompleted,
  }) {
    return LineupState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      match: match ?? this.match,
      game: game ?? this.game,
      selectedPlayerId: clearSelectedPlayer
          ? null
          : (selectedPlayerId ?? this.selectedPlayerId),
      currentGuessLetters: currentGuessLetters ?? this.currentGuessLetters,
      justCompleted: justCompleted ?? this.justCompleted,
    );
  }

  @override
  List<Object?> get props => [
    status,
    matches,
    match,
    game,
    selectedPlayerId,
    currentGuessLetters,
    justCompleted,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_comparison.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class GuessPlayerState extends Equatable {
  const GuessPlayerState({
    this.status = LoadStatus.initial,
    this.secretPlayer,
    this.round,
    this.comparisons = const [],
  });

  final LoadStatus status;
  final GuessPlayer? secretPlayer;
  final GuessPlayerRoundState? round;
  final List<GuessComparisonResult> comparisons;

  GuessPlayerState copyWith({
    LoadStatus? status,
    GuessPlayer? secretPlayer,
    GuessPlayerRoundState? round,
    List<GuessComparisonResult>? comparisons,
  }) {
    return GuessPlayerState(
      status: status ?? this.status,
      secretPlayer: secretPlayer ?? this.secretPlayer,
      round: round ?? this.round,
      comparisons: comparisons ?? this.comparisons,
    );
  }

  @override
  List<Object?> get props => [status, secretPlayer, round, comparisons];
}

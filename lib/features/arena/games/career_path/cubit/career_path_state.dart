import 'package:equatable/equatable.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/shared/state/load_status.dart';

class CareerPathState extends Equatable {
  const CareerPathState({
    this.status = LoadStatus.initial,
    this.players = const [],
    this.player,
    this.round,
    this.justFinished = false,
  });

  final LoadStatus status;
  final List<CareerPlayer> players;
  final CareerPlayer? player;
  final CareerRoundState? round;
  final bool justFinished;

  int? get currentIndex {
    final id = player?.id;
    if (id == null) return null;
    final index = players.indexWhere((candidate) => candidate.id == id);
    return index == -1 ? null : index;
  }

  int get total => players.length;
  bool get hasPrevious => (currentIndex ?? 0) > 0;
  bool get hasNext {
    final index = currentIndex;
    return index != null && index < players.length - 1;
  }

  CareerRoundStatus get roundStatus => round?.status ?? CareerRoundStatus.playing;
  int get attemptsUsed => round?.attemptsUsed ?? 0;
  bool get isDone => round?.isDone ?? false;

  CareerPathState copyWith({
    LoadStatus? status,
    List<CareerPlayer>? players,
    CareerPlayer? player,
    CareerRoundState? round,
    bool? justFinished,
  }) {
    return CareerPathState(
      status: status ?? this.status,
      players: players ?? this.players,
      player: player ?? this.player,
      round: round ?? this.round,
      justFinished: justFinished ?? this.justFinished,
    );
  }

  @override
  List<Object?> get props => [status, players, player, round, justFinished];
}

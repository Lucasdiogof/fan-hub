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
    this.roundNumber = 0,
  });

  final LoadStatus status;
  final List<CareerPlayer> players;
  final CareerPlayer? player;
  final CareerRoundState? round;
  final bool justFinished;

  /// Contador da rodada dentro da sessão (1-based) — não é mais a posição
  /// do jogador no array, já que a ordem de exibição agora é sorteada a
  /// cada "Próximo jogador", não sequencial.
  final int roundNumber;

  int get total => players.length;

  CareerRoundStatus get roundStatus =>
      round?.status ?? CareerRoundStatus.playing;
  int get attemptsUsed => round?.attemptsUsed ?? 0;
  bool get isDone => round?.isDone ?? false;

  CareerPathState copyWith({
    LoadStatus? status,
    List<CareerPlayer>? players,
    CareerPlayer? player,
    CareerRoundState? round,
    bool? justFinished,
    int? roundNumber,
  }) {
    return CareerPathState(
      status: status ?? this.status,
      players: players ?? this.players,
      player: player ?? this.player,
      round: round ?? this.round,
      justFinished: justFinished ?? this.justFinished,
      roundNumber: roundNumber ?? this.roundNumber,
    );
  }

  @override
  List<Object?> get props => [
    status,
    players,
    player,
    round,
    justFinished,
    roundNumber,
  ];
}

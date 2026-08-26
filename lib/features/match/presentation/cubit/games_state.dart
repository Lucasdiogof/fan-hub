import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/shared/state/load_status.dart';

class GamesState extends Equatable {
  const GamesState({
    this.currentRoundStatus = LoadStatus.initial,
    this.snapshotStatus = LoadStatus.initial,
    this.standingsStatus = LoadStatus.initial,
    this.currentRoundMatches = const [],
    this.roundOffset = 0,
    this.roundLabel,
    this.hasPreviousRound = false,
    this.hasNextRound = false,
    this.nextMatch,
    this.standings = const [],
    this.currentRoundErrorMessage,
    this.snapshotErrorMessage,
    this.standingsErrorMessage,
  });

  final LoadStatus currentRoundStatus;
  final LoadStatus snapshotStatus;
  final LoadStatus standingsStatus;
  final List<Match> currentRoundMatches;

  /// Relativo à rodada atual (0). Negativo = navegou pra rodadas
  /// anteriores. Zerado a cada `loadCurrentRound()`/pull-to-refresh.
  final int roundOffset;
  final String? roundLabel;
  final bool hasPreviousRound;
  final bool hasNextRound;
  final Match? nextMatch;
  final List<Standing> standings;
  final String? currentRoundErrorMessage;
  final String? snapshotErrorMessage;
  final String? standingsErrorMessage;

  GamesState copyWith({
    LoadStatus? currentRoundStatus,
    LoadStatus? snapshotStatus,
    LoadStatus? standingsStatus,
    List<Match>? currentRoundMatches,
    int? roundOffset,
    String? roundLabel,
    bool clearRoundLabel = false,
    bool? hasPreviousRound,
    bool? hasNextRound,
    Match? nextMatch,
    bool clearNextMatch = false,
    List<Standing>? standings,
    String? currentRoundErrorMessage,
    String? snapshotErrorMessage,
    String? standingsErrorMessage,
  }) {
    return GamesState(
      currentRoundStatus: currentRoundStatus ?? this.currentRoundStatus,
      snapshotStatus: snapshotStatus ?? this.snapshotStatus,
      standingsStatus: standingsStatus ?? this.standingsStatus,
      currentRoundMatches: currentRoundMatches ?? this.currentRoundMatches,
      roundOffset: roundOffset ?? this.roundOffset,
      roundLabel: clearRoundLabel ? null : (roundLabel ?? this.roundLabel),
      hasPreviousRound: hasPreviousRound ?? this.hasPreviousRound,
      hasNextRound: hasNextRound ?? this.hasNextRound,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
      standings: standings ?? this.standings,
      currentRoundErrorMessage:
          currentRoundErrorMessage ?? this.currentRoundErrorMessage,
      snapshotErrorMessage: snapshotErrorMessage ?? this.snapshotErrorMessage,
      standingsErrorMessage:
          standingsErrorMessage ?? this.standingsErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    currentRoundStatus,
    snapshotStatus,
    standingsStatus,
    currentRoundMatches,
    roundOffset,
    roundLabel,
    hasPreviousRound,
    hasNextRound,
    nextMatch,
    standings,
    currentRoundErrorMessage,
    snapshotErrorMessage,
    standingsErrorMessage,
  ];
}

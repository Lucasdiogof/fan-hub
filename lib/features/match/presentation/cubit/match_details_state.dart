import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MatchDetailsState extends Equatable {
  const MatchDetailsState({
    this.status = LoadStatus.initial,
    this.match,
    this.events = const [],
    this.lineups,
    this.stats = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final Match? match;
  final List<MatchEvent> events;
  final MatchLineups? lineups;
  final List<MatchStat> stats;
  final String? errorMessage;

  MatchDetailsState copyWith({
    LoadStatus? status,
    Match? match,
    List<MatchEvent>? events,
    MatchLineups? lineups,
    List<MatchStat>? stats,
    String? errorMessage,
  }) {
    return MatchDetailsState(
      status: status ?? this.status,
      match: match ?? this.match,
      events: events ?? this.events,
      lineups: lineups ?? this.lineups,
      stats: stats ?? this.stats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    match,
    events,
    lineups,
    stats,
    errorMessage,
  ];
}

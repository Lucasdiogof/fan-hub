import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/shared/state/load_status.dart';

class CompetitionDetailsState extends Equatable {
  const CompetitionDetailsState({
    this.status = LoadStatus.initial,
    this.competition,
    this.standings = const [],
    this.standingGroups = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final CompetitionRef? competition;
  final List<Standing> standings;
  final List<StandingGroup> standingGroups;
  final String? errorMessage;

  CompetitionDetailsState copyWith({
    LoadStatus? status,
    CompetitionRef? competition,
    List<Standing>? standings,
    List<StandingGroup>? standingGroups,
    String? errorMessage,
  }) {
    return CompetitionDetailsState(
      status: status ?? this.status,
      competition: competition ?? this.competition,
      standings: standings ?? this.standings,
      standingGroups: standingGroups ?? this.standingGroups,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    competition,
    standings,
    standingGroups,
    errorMessage,
  ];
}

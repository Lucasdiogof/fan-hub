import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MatchDetailsState extends Equatable {
  const MatchDetailsState({this.status = LoadStatus.initial, this.match, this.errorMessage});

  final LoadStatus status;
  final Match? match;
  final String? errorMessage;

  MatchDetailsState copyWith({LoadStatus? status, Match? match, String? errorMessage}) {
    return MatchDetailsState(
      status: status ?? this.status,
      match: match ?? this.match,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, match, errorMessage];
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/shared/state/load_status.dart';

class PassportRankingState extends Equatable {
  const PassportRankingState({
    this.status = LoadStatus.initial,
    this.entries = const [],
    this.errorMessage,
    this.year,
    this.myRank,
    this.myMatchCount,
  });

  final LoadStatus status;
  final List<PassportRankingEntry> entries;
  final String? errorMessage;

  /// null = geral (todas as temporadas).
  final int? year;
  final int? myRank;
  final int? myMatchCount;

  PassportRankingState copyWith({
    LoadStatus? status,
    List<PassportRankingEntry>? entries,
    String? Function()? errorMessage,
    int? Function()? year,
    int? Function()? myRank,
    int? Function()? myMatchCount,
  }) {
    return PassportRankingState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      year: year != null ? year() : this.year,
      myRank: myRank != null ? myRank() : this.myRank,
      myMatchCount: myMatchCount != null ? myMatchCount() : this.myMatchCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    errorMessage,
    year,
    myRank,
    myMatchCount,
  ];
}

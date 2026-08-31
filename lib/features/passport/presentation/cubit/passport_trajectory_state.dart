import 'package:equatable/equatable.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/shared/state/load_status.dart';

class PassportTrajectoryState extends Equatable {
  const PassportTrajectoryState({
    this.status = LoadStatus.initial,
    this.summary = PassportSummary.empty,
    this.breakdown = PassportAttendanceBreakdown.empty,
    this.stadiumSummary = PassportStadiumSummary.empty,
    this.attendedMatches = const [],
    this.memorableMatch,
    this.savingMemorableMatch = false,
  });

  final LoadStatus status;
  final PassportSummary summary;
  final PassportAttendanceBreakdown breakdown;
  final PassportStadiumSummary stadiumSummary;
  final List<PassportMatch> attendedMatches;
  final PassportMatch? memorableMatch;
  final bool savingMemorableMatch;

  int get totalMatches => summary.totalMatches;
  int get seasonsCount => summary.yearsWithAttendance;
  int get goalDifference => breakdown.goalsFor - breakdown.goalsAgainst;

  PassportTrajectoryState copyWith({
    LoadStatus? status,
    PassportSummary? summary,
    PassportAttendanceBreakdown? breakdown,
    PassportStadiumSummary? stadiumSummary,
    List<PassportMatch>? attendedMatches,
    PassportMatch? memorableMatch,
    bool clearMemorableMatch = false,
    bool? savingMemorableMatch,
  }) {
    return PassportTrajectoryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      breakdown: breakdown ?? this.breakdown,
      stadiumSummary: stadiumSummary ?? this.stadiumSummary,
      attendedMatches: attendedMatches ?? this.attendedMatches,
      memorableMatch: clearMemorableMatch
          ? null
          : (memorableMatch ?? this.memorableMatch),
      savingMemorableMatch: savingMemorableMatch ?? this.savingMemorableMatch,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    breakdown,
    stadiumSummary,
    attendedMatches,
    memorableMatch,
    savingMemorableMatch,
  ];
}

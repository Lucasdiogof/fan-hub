import 'package:equatable/equatable.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/shared/state/load_status.dart';

class PassportStatsState extends Equatable {
  const PassportStatsState({
    this.status = LoadStatus.initial,
    this.breakdown = PassportAttendanceBreakdown.empty,
    this.errorMessage,
  });

  final LoadStatus status;
  final PassportAttendanceBreakdown breakdown;
  final String? errorMessage;

  PassportStatsState copyWith({
    LoadStatus? status,
    PassportAttendanceBreakdown? breakdown,
    String? errorMessage,
  }) {
    return PassportStatsState(
      status: status ?? this.status,
      breakdown: breakdown ?? this.breakdown,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, breakdown, errorMessage];
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ClubBoardState extends Equatable {
  const ClubBoardState({
    this.status = LoadStatus.initial,
    this.sections = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<ClubBoardSection> sections;
  final String? errorMessage;

  ClubBoardState copyWith({
    LoadStatus? status,
    List<ClubBoardSection>? sections,
    String? Function()? errorMessage,
  }) {
    return ClubBoardState(
      status: status ?? this.status,
      sections: sections ?? this.sections,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sections, errorMessage];
}

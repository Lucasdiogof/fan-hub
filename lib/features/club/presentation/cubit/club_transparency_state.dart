import 'package:equatable/equatable.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ClubTransparencyState extends Equatable {
  const ClubTransparencyState({
    this.status = LoadStatus.initial,
    this.topics = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<ClubTransparencyTopic> topics;
  final String? errorMessage;

  ClubTransparencyState copyWith({
    LoadStatus? status,
    List<ClubTransparencyTopic>? topics,
    String? Function()? errorMessage,
  }) {
    return ClubTransparencyState(
      status: status ?? this.status,
      topics: topics ?? this.topics,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, topics, errorMessage];
}

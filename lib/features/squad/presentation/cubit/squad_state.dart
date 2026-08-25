import 'package:equatable/equatable.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/shared/state/load_status.dart';

class SquadState extends Equatable {
  const SquadState({
    this.status = LoadStatus.initial,
    this.members = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<SquadMember> members;
  final String? errorMessage;

  SquadState copyWith({
    LoadStatus? status,
    List<SquadMember>? members,
    String? Function()? errorMessage,
  }) {
    return SquadState(
      status: status ?? this.status,
      members: members ?? this.members,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, members, errorMessage];
}

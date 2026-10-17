import 'package:equatable/equatable.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/shared/state/load_status.dart';

class SquadState extends Equatable {
  const SquadState({
    this.status = LoadStatus.initial,
    this.members = const [],
    this.errorMessage,
    this.isOffline = false,
    this.cachedAt,
  });

  final LoadStatus status;
  final List<SquadMember> members;
  final String? errorMessage;

  /// A falha foi falta de rede/timeout (não erro do servidor).
  final bool isOffline;

  /// Não nulo quando o conteúdo exibido é a última consulta salva.
  final DateTime? cachedAt;

  SquadState copyWith({
    LoadStatus? status,
    List<SquadMember>? members,
    String? Function()? errorMessage,
    bool? isOffline,
    DateTime? Function()? cachedAt,
  }) {
    return SquadState(
      status: status ?? this.status,
      members: members ?? this.members,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt != null ? cachedAt() : this.cachedAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    members,
    errorMessage,
    isOffline,
    cachedAt,
  ];
}

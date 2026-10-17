import 'package:equatable/equatable.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ClubTransparencyState extends Equatable {
  const ClubTransparencyState({
    this.status = LoadStatus.initial,
    this.topics = const [],
    this.errorMessage,
    this.isOffline = false,
    this.cachedAt,
  });

  final LoadStatus status;
  final List<ClubTransparencyTopic> topics;
  final String? errorMessage;

  /// A falha foi falta de rede/timeout (não erro do servidor).
  final bool isOffline;

  /// Não nulo quando o conteúdo exibido é a última consulta salva.
  final DateTime? cachedAt;

  ClubTransparencyState copyWith({
    LoadStatus? status,
    List<ClubTransparencyTopic>? topics,
    String? Function()? errorMessage,
    bool? isOffline,
    DateTime? Function()? cachedAt,
  }) {
    return ClubTransparencyState(
      status: status ?? this.status,
      topics: topics ?? this.topics,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt != null ? cachedAt() : this.cachedAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    topics,
    errorMessage,
    isOffline,
    cachedAt,
  ];
}

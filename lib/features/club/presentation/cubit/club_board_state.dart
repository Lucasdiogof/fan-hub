import 'package:equatable/equatable.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ClubBoardState extends Equatable {
  const ClubBoardState({
    this.status = LoadStatus.initial,
    this.sections = const [],
    this.errorMessage,
    this.isOffline = false,
    this.cachedAt,
  });

  final LoadStatus status;
  final List<ClubBoardSection> sections;
  final String? errorMessage;

  /// A falha foi falta de rede/timeout (não erro do servidor).
  final bool isOffline;

  /// Não nulo quando o conteúdo exibido é a última consulta salva.
  final DateTime? cachedAt;

  ClubBoardState copyWith({
    LoadStatus? status,
    List<ClubBoardSection>? sections,
    String? Function()? errorMessage,
    bool? isOffline,
    DateTime? Function()? cachedAt,
  }) {
    return ClubBoardState(
      status: status ?? this.status,
      sections: sections ?? this.sections,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt != null ? cachedAt() : this.cachedAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sections,
    errorMessage,
    isOffline,
    cachedAt,
  ];
}

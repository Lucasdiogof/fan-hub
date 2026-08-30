import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/state/load_status.dart';

class HomeState extends Equatable {
  const HomeState({
    this.status = LoadStatus.loading,
    this.nextMatch,
    this.errorMessage,
    this.hasVotedForNextMatch = false,
  });

  final LoadStatus status;
  final Match? nextMatch;

  /// Só preenchido quando [status] é [LoadStatus.error] — falha de
  /// rede/servidor ao buscar o próximo jogo, nunca confundida com "não
  /// existe próximo jogo agendado" (que é `status: success, nextMatch:
  /// null`, sem mensagem nenhuma).
  final String? errorMessage;

  /// Se o usuário já enviou uma escalação da torcida pro `nextMatch` atual
  /// (não um booleano global — ver `CrowdLineupRepository.getMyVote`,
  /// consultado por `matchId`). Resolvido junto com o resto do load da Home
  /// pra o card "Escalação da Torcida" já nascer no estado certo, sem
  /// piscar de um estado pro outro depois de montada.
  final bool hasVotedForNextMatch;

  HomeState copyWith({
    LoadStatus? status,
    Match? nextMatch,
    bool clearNextMatch = false,
    String? Function()? errorMessage,
    bool? hasVotedForNextMatch,
  }) {
    return HomeState(
      status: status ?? this.status,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      hasVotedForNextMatch: hasVotedForNextMatch ?? this.hasVotedForNextMatch,
    );
  }

  @override
  List<Object?> get props => [
    status,
    nextMatch,
    errorMessage,
    hasVotedForNextMatch,
  ];
}

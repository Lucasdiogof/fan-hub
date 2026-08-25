import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.nextMatch,
    this.isMember = false,
    this.hasVotedForNextMatch = false,
  });

  final bool loading;
  final Match? nextMatch;
  final bool isMember;

  /// Se o usuário já enviou uma escalação da torcida pro `nextMatch` atual
  /// (não um booleano global — ver `CrowdLineupRepository.getMyVote`,
  /// consultado por `matchId`). Resolvido junto com o resto do load da Home
  /// pra o card "Escalação da Torcida" já nascer no estado certo, sem
  /// piscar de um estado pro outro depois de montada.
  final bool hasVotedForNextMatch;

  HomeState copyWith({
    bool? loading,
    Match? nextMatch,
    bool clearNextMatch = false,
    bool? isMember,
    bool? hasVotedForNextMatch,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
      isMember: isMember ?? this.isMember,
      hasVotedForNextMatch: hasVotedForNextMatch ?? this.hasVotedForNextMatch,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    nextMatch,
    isMember,
    hasVotedForNextMatch,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/shared/state/load_status.dart';

class HomeState extends Equatable {
  const HomeState({
    this.status = LoadStatus.loading,
    this.nextMatch,
    this.matchForLineupVoting,
    this.errorMessage,
    this.hasVotedForNextMatch = false,
  });

  final LoadStatus status;

  /// Partida mostrada no card da Home — pode ser o próximo jogo agendado,
  /// um jogo ao vivo/intervalo, OU o último resultado (dentro da folga de
  /// [HomeCubit._finishedGracePeriod], pedido explícito do usuário: "acho
  /// justo manter um pouco o jogo que terminou"). NUNCA use este campo pra
  /// decidir se dá pra escalar a Torcida — ver [matchForLineupVoting].
  final Match? nextMatch;

  /// Partida-alvo da "Escalação da Torcida" — o MESMO jogo que [nextMatch]
  /// mostra no card da Home, mas só quando ele ainda está aberto
  /// (agendado/ao vivo/intervalo). `null` sempre que [nextMatch] for um
  /// resultado já encerrado (dentro da folga de
  /// [HomeCubit._finishedGracePeriod]) — comportamento pedido
  /// explicitamente: enquanto a Home ainda mostra o placar do jogo que
  /// acabou, a Arena esconde o hero de Escalação (não adianta pro próximo
  /// jogo); assim que a própria Home troca pro próximo jogo, a Arena
  /// libera junto, pro mesmo jogo. Campo separado de [nextMatch] só pra a
  /// UI nunca ter que reimplementar essa regra (`MatchOrdering.isOpen`) em
  /// mais de um lugar.
  final Match? matchForLineupVoting;

  /// Só preenchido quando [status] é [LoadStatus.error] — falha de
  /// rede/servidor ao buscar o próximo jogo, nunca confundida com "não
  /// existe próximo jogo agendado" (que é `status: success, nextMatch:
  /// null`, sem mensagem nenhuma).
  final String? errorMessage;

  /// Se o usuário já enviou uma escalação da torcida pro
  /// [matchForLineupVoting] atual (não um booleano global — ver
  /// `CrowdLineupRepository.getMyVote`, consultado por `matchId`).
  /// Resolvido junto com o resto do load da Home pra o card "Escalação da
  /// Torcida" já nascer no estado certo, sem piscar de um estado pro outro
  /// depois de montada.
  final bool hasVotedForNextMatch;

  HomeState copyWith({
    LoadStatus? status,
    Match? nextMatch,
    bool clearNextMatch = false,
    Match? matchForLineupVoting,
    bool clearMatchForLineupVoting = false,
    String? Function()? errorMessage,
    bool? hasVotedForNextMatch,
  }) {
    return HomeState(
      status: status ?? this.status,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
      matchForLineupVoting: clearMatchForLineupVoting
          ? null
          : (matchForLineupVoting ?? this.matchForLineupVoting),
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      hasVotedForNextMatch: hasVotedForNextMatch ?? this.hasVotedForNextMatch,
    );
  }

  @override
  List<Object?> get props => [
    status,
    nextMatch,
    matchForLineupVoting,
    errorMessage,
    hasVotedForNextMatch,
  ];
}

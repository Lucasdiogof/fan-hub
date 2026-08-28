import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._footballRepository,
    this._membershipRepository,
    this._crowdLineupRepository,
  ) : super(const HomeState()) {
    load();
  }

  final FootballRepository _footballRepository;
  final MembershipRepository _membershipRepository;
  final CrowdLineupRepository _crowdLineupRepository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));

    final snapshotFuture = _footballRepository.getGoiasSnapshot();
    final membershipFuture = _membershipRepository.getMyMembership();

    final snapshotResult = await snapshotFuture;
    final membershipResult = await membershipFuture;

    final isMember = switch (membershipResult) {
      Success(:final data) => data?.status == MembershipStatus.active,
      _ => false,
    };

    switch (snapshotResult) {
      case Success(:final data):
        final match = data.nextMatch;
        // Não é só "kickoff ainda não chegou" — o card continua de pé
        // enquanto o jogo está rolando (`live`/`halftime`), só sai quando
        // termina de verdade. Mesma regra que já decide o "próximo jogo" da
        // aba Jogos (`GamesCubit.loadSnapshot`), pra Home e Jogos nunca
        // discordarem sobre se o jogo do Goiás ainda está "aberto".
        final stillOpen = match != null && MatchOrdering.isOpen(match);
        final resolvedMatch = stillOpen ? match : null;
        // Resolvido por matchId (nunca um booleano global) — se o próximo
        // jogo mudar, essa consulta muda junto, e o card "Escalação da
        // Torcida" volta pra "Escalar agora" pro jogo novo.
        final hasVoted = resolvedMatch == null
            ? false
            : await _hasVotedFor(resolvedMatch.id);
        emit(
          state.copyWith(
            loading: false,
            nextMatch: resolvedMatch,
            clearNextMatch: !stillOpen,
            isMember: isMember,
            hasVotedForNextMatch: hasVoted,
          ),
        );
      case Error():
        emit(
          state.copyWith(
            loading: false,
            clearNextMatch: true,
            isMember: isMember,
          ),
        );
    }
  }

  Future<bool> _hasVotedFor(String matchId) async {
    final result = await _crowdLineupRepository.getMyVote(matchId);
    return switch (result) {
      Success(:final data) => data != null,
      Error() => false,
    };
  }
}

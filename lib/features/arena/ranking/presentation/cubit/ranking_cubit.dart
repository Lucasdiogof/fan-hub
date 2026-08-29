import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/ranking/presentation/cubit/ranking_state.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

class RankingCubit extends Cubit<RankingState> {
  RankingCubit(this._ranking, this._membershipStatusCubit)
    : super(const RankingState());

  final ArenaRankingRepository _ranking;
  final MembershipStatusCubit _membershipStatusCubit;

  Future<void> load() => _loadPeriod(state.period);

  Future<void> selectPeriod(RankingPeriod period) async {
    if (period == state.period) return;
    await _loadPeriod(period);
  }

  /// A situação de sócio do próprio usuário vem de `MembershipStatusCubit`
  /// (fonte única do app inteiro) e é aplicada só na SUA linha — a RPC do
  /// ranking sempre devolve `is_member = false` pra todo mundo, porque ela
  /// não sabe nada sobre a assinatura de sócio de NINGUÉM (nem a do próprio
  /// usuário nem a de outros) — só o app sabe, via essa mesma fonte única.
  Future<void> _loadPeriod(RankingPeriod period) async {
    emit(state.copyWith(status: LoadStatus.loading, period: period));
    final rankingFuture = _ranking.getRanking(period);
    final myRankFuture = _ranking.getMyRank(period);

    final rankingResult = await rankingFuture;
    if (rankingResult is Error<List<RankingEntry>>) {
      emit(state.copyWith(status: LoadStatus.error));
      return;
    }
    final entries = (rankingResult as Success<List<RankingEntry>>).data;

    final isMember = _membershipStatusCubit.state.isMember;
    final patchedEntries = [
      for (final entry in entries)
        if (entry.isMe) entry.copyWith(isMember: isMember) else entry,
    ];

    final myRankResult = await myRankFuture;
    final myRank = myRankResult is Success<({int rank, int totalScore})?>
        ? myRankResult.data
        : null;

    emit(
      state.copyWith(
        status: patchedEntries.isEmpty ? LoadStatus.empty : LoadStatus.success,
        entries: patchedEntries,
        myRank: myRank,
        clearMyRank: myRank == null,
      ),
    );
  }
}

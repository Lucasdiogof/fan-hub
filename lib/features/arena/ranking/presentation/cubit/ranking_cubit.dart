import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/ranking/presentation/cubit/ranking_state.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';

class RankingCubit extends Cubit<RankingState> {
  RankingCubit(this._ranking, this._membership) : super(const RankingState());

  final ArenaRankingRepository _ranking;
  final MembershipRepository _membership;

  Future<void> load() => _loadPeriod(state.period);

  Future<void> selectPeriod(RankingPeriod period) async {
    if (period == state.period) return;
    await _loadPeriod(period);
  }

  /// A situação de sócio do próprio usuário é resolvida localmente (mesma
  /// fonte que o resto do app usa) e aplicada só na SUA linha — a RPC do
  /// ranking sempre devolve `is_member = false` pra todo mundo, porque a
  /// associação ainda é 100% mock/local, sem tabela no Supabase pra saber
  /// se OUTRO usuário é sócio.
  Future<void> _loadPeriod(RankingPeriod period) async {
    emit(state.copyWith(status: LoadStatus.loading, period: period));
    final rankingFuture = _ranking.getRanking(period);
    final myRankFuture = _ranking.getMyRank(period);
    final membershipFuture = _membership.getMyMembership();

    final rankingResult = await rankingFuture;
    if (rankingResult is Error<List<RankingEntry>>) {
      emit(state.copyWith(status: LoadStatus.error));
      return;
    }
    final entries = (rankingResult as Success<List<RankingEntry>>).data;

    final membershipResult = await membershipFuture;
    final isMember =
        membershipResult is Success<Membership?> &&
        membershipResult.data?.status == MembershipStatus.active;
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

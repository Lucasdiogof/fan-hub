import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._footballRepository, this._membershipRepository) : super(const HomeState()) {
    load();
  }

  final FootballRepository _footballRepository;
  final MembershipRepository _membershipRepository;

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
        final stillUpcoming = match != null && DateTime.now().isBefore(match.kickoff);
        emit(
          state.copyWith(
            loading: false,
            nextMatch: stillUpcoming ? match : null,
            clearNextMatch: !stillUpcoming,
            isMember: isMember,
          ),
        );
      case Error():
        emit(state.copyWith(loading: false, clearNextMatch: true, isMember: isMember));
    }
  }
}

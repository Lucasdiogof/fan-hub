import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_state.dart';
import 'package:goias_app/features/profile/domain/entities/app_user.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Decide, a partir do estado da associação, qual das duas experiências da
/// aba Sócio mostrar — a página não decide isso sozinha.
class MembershipCubit extends Cubit<MembershipState> {
  MembershipCubit(
    this._membershipRepository,
    this._userRepository,
    this._footballRepository,
  ) : super(const MembershipState()) {
    load();
  }

  final MembershipRepository _membershipRepository;
  final UserRepository _userRepository;
  final FootballRepository _footballRepository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final membershipFuture = _membershipRepository.getMyMembership();
    final plansFuture = _membershipRepository.getPlans();
    final userFuture = _userRepository.getCurrentUser();
    final snapshotFuture = _footballRepository.getGoiasSnapshot();

    final membershipResult = await membershipFuture;
    final plansResult = await plansFuture;
    final userResult = await userFuture;
    final snapshotResult = await snapshotFuture;

    if (membershipResult case Error(:final failure)) {
      emit(
        state.copyWith(status: LoadStatus.error, errorMessage: failure.message),
      );
      return;
    }
    if (plansResult case Error(:final failure)) {
      emit(
        state.copyWith(status: LoadStatus.error, errorMessage: failure.message),
      );
      return;
    }
    if (userResult case Error(:final failure)) {
      emit(
        state.copyWith(status: LoadStatus.error, errorMessage: failure.message),
      );
      return;
    }

    final membership = (membershipResult as Success<Membership?>).data;
    final plans = (plansResult as Success<List<MembershipPlan>>).data;
    final user = (userResult as Success<AppUser>).data;
    // Sem horário confirmado (kickoff == null) conta como "ainda por vir".
    final nextMatch = switch (snapshotResult) {
      Success(:final data)
          when data.nextMatch != null &&
              (data.nextMatch!.kickoff == null ||
                  DateTime.now().isBefore(data.nextMatch!.kickoff!)) =>
        data.nextMatch,
      _ => null,
    };

    emit(
      state.copyWith(
        status: LoadStatus.success,
        membership: membership,
        clearMembership: membership == null,
        plans: plans,
        user: user,
        nextMatch: nextMatch,
        clearNextMatch: nextMatch == null,
      ),
    );
  }
}

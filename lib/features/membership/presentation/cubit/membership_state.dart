import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MembershipState extends Equatable {
  const MembershipState({
    this.status = LoadStatus.initial,
    this.membership,
    this.plans = const [],
    this.user,
    this.nextMatch,
    this.errorMessage,
  });

  final LoadStatus status;
  final Membership? membership;
  final List<MembershipPlan> plans;
  final Profile? user;
  final Match? nextMatch;
  final String? errorMessage;

  bool get isMember =>
      membership != null && membership!.status == MembershipStatus.active;

  MembershipState copyWith({
    LoadStatus? status,
    Membership? membership,
    bool clearMembership = false,
    List<MembershipPlan>? plans,
    Profile? user,
    Match? nextMatch,
    bool clearNextMatch = false,
    String? errorMessage,
  }) {
    return MembershipState(
      status: status ?? this.status,
      membership: clearMembership ? null : (membership ?? this.membership),
      plans: plans ?? this.plans,
      user: user ?? this.user,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    membership,
    plans,
    user,
    nextMatch,
    errorMessage,
  ];
}

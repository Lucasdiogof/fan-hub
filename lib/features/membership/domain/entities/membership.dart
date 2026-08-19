import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';

enum MembershipStatus { none, pending, active, suspended, cancelled }

class Membership extends Equatable {
  const Membership({
    required this.id,
    required this.userId,
    required this.plan,
    required this.planPrice,
    required this.status,
    this.memberNumber,
    this.startedAt,
    this.expiresAt,
    this.regulationVersion,
    this.regulationAcceptedAt,
  });

  final String id;
  final String userId;
  final MembershipPlan plan;
  final MembershipPlanPrice planPrice;
  final MembershipStatus status;
  final String? memberNumber;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  /// [RegulationVersion.version] aceita pelo sócio no momento da adesão.
  final String? regulationVersion;
  final DateTime? regulationAcceptedAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    plan,
    planPrice,
    status,
    memberNumber,
    startedAt,
    expiresAt,
    regulationVersion,
    regulationAcceptedAt,
  ];
}

class CheckIn extends Equatable {
  const CheckIn({required this.matchId, required this.checkedInAt});

  final String matchId;
  final DateTime checkedInAt;

  @override
  List<Object?> get props => [matchId, checkedInAt];
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';

enum MembershipStatus { active, inactive }

class Membership extends Equatable {
  const Membership({
    required this.plan,
    required this.status,
    required this.memberNumber,
    required this.holderName,
    required this.nextPaymentDate,
  });

  final MembershipPlan plan;
  final MembershipStatus status;
  final String memberNumber;
  final String holderName;
  final DateTime nextPaymentDate;

  @override
  List<Object?> get props => [plan, status, memberNumber, holderName, nextPaymentDate];
}

class CheckIn extends Equatable {
  const CheckIn({required this.matchId, required this.checkedInAt});

  final String matchId;
  final DateTime checkedInAt;

  @override
  List<Object?> get props => [matchId, checkedInAt];
}

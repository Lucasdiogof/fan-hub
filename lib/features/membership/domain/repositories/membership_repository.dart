import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';

abstract class MembershipRepository {
  Future<Result<List<MembershipPlan>>> getPlans();

  Future<Result<Membership?>> getMyMembership();

  Future<Result<List<CheckIn>>> getMyCheckIns();

  Future<Result<CheckIn>> checkIn(String matchId);
}

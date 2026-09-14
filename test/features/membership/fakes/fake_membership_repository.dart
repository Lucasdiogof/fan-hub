import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';

const membershipPlanFixture = MembershipPlan(
  id: 'plan1',
  name: 'Esmeralda',
  tagline: 'O plano clássico',
  includesStadiumAccess: true,
  benefits: ['Check-in em jogos'],
  prices: [
    MembershipPlanPrice(label: 'Mensal', monthlyPrice: 39.9, annualPrice: 399),
  ],
  allowedSectors: ['Norte'],
);

Membership buildMembership({
  MembershipStatus status = MembershipStatus.active,
}) => Membership(
  id: 'm1',
  userId: 'u1',
  plan: membershipPlanFixture,
  planPrice: membershipPlanFixture.prices.first,
  status: status,
);

class FakeMembershipRepository implements MembershipRepository {
  Result<List<MembershipPlan>> plansResult = const Success([
    membershipPlanFixture,
  ]);
  Result<Membership?> myMembershipResult = const Success(null);
  Result<List<CheckIn>> myCheckInsResult = const Success([]);
  Result<CheckIn>? checkInResult;
  Result<Membership>? submitRegistrationResult;

  @override
  Future<Result<List<MembershipPlan>>> getPlans() async => plansResult;

  @override
  Future<Result<Membership?>> getMyMembership() async => myMembershipResult;

  @override
  Future<Result<List<CheckIn>>> getMyCheckIns() async => myCheckInsResult;

  @override
  Future<Result<CheckIn>> checkIn(String matchId) async => checkInResult!;

  @override
  Future<Result<Membership>> submitRegistration({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  }) async => submitRegistrationResult!;
}

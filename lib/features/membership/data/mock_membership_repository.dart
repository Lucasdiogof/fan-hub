import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';

class MockMembershipRepository implements MembershipRepository {
  static const _latency = Duration(milliseconds: 300);

  final List<CheckIn> _checkIns = [];

  @override
  Future<Result<List<MembershipPlan>>> getPlans() async {
    await Future<void>.delayed(_latency);
    return const Success(MockData.plans);
  }

  @override
  Future<Result<Membership?>> getMyMembership() async {
    await Future<void>.delayed(_latency);
    return Success(MockData.myMembership);
  }

  @override
  Future<Result<List<CheckIn>>> getMyCheckIns() async {
    await Future<void>.delayed(_latency);
    return Success([..._checkIns.reversed]);
  }

  @override
  Future<Result<CheckIn>> checkIn(String matchId) async {
    await Future<void>.delayed(_latency);
    for (final checkIn in _checkIns) {
      if (checkIn.matchId == matchId) return Success(checkIn);
    }
    final checkIn = CheckIn(matchId: matchId, checkedInAt: DateTime.now());
    _checkIns.add(checkIn);
    return Success(checkIn);
  }
}

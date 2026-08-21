import 'dart:math';

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/data/membership_plans_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';

/// Implementação local enquanto não existe integração oficial com
/// socioesmeralda.com.br. `MembershipHomePage` e o fluxo de associação só
/// conhecem `MembershipRepository` — trocar por uma implementação real
/// (`GoiasMembershipRepository`) não deve exigir mudança nas telas.
class MockMembershipRepository implements MembershipRepository {
  static const _latency = Duration(milliseconds: 300);
  final List<CheckIn> _checkIns = [];
  Membership? _membership;

  @override
  Future<Result<List<MembershipPlan>>> getPlans() async {
    await Future<void>.delayed(_latency);
    return const Success(MembershipPlansCatalog.plans);
  }

  @override
  Future<Result<Membership?>> getMyMembership() async {
    await Future<void>.delayed(_latency);
    return Success(_membership);
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

  @override
  Future<Result<Membership>> submitRegistration({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  }) async {
    await Future<void>.delayed(_latency);
    final membership = Membership(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock-user',
      plan: plan,
      planPrice: price,
      status: MembershipStatus.active,
      memberNumber: _generateMemberNumber(),
      startedAt: DateTime.now(),
      regulationVersion: regulationVersion,
      regulationAcceptedAt: regulationAcceptedAt,
    );
    _membership = membership;
    return Success(membership);
  }

  String _generateMemberNumber() => (100000 + Random().nextInt(900000)).toString();

  /// Alternado a partir do Perfil, enquanto não existe integração real com
  /// o Sócio Esmeralda — nunca deve existir caminho de produção que crie
  /// uma associação real sem passar por [submitRegistration].
  void debugSetActive(bool isActive) {
    if (!isActive) {
      _membership = null;
      return;
    }
    final plan = MembershipPlansCatalog.plans.firstWhere((p) => p.id == 'nossa-garra');
    _membership = Membership(
      id: 'mock-debug',
      userId: 'mock-user',
      plan: plan,
      planPrice: plan.defaultPrice,
      status: MembershipStatus.active,
      memberNumber: '084213',
      startedAt: DateTime.now().subtract(const Duration(days: 200)),
      expiresAt: DateTime.now().add(const Duration(days: 165)),
    );
  }
}

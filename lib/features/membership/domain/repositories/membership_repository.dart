import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';

abstract class MembershipRepository {
  Future<Result<List<MembershipPlan>>> getPlans();

  Future<Result<Membership?>> getMyMembership();

  Future<Result<List<CheckIn>>> getMyCheckIns();

  Future<Result<CheckIn>> checkIn(String matchId);

  /// Só existe [MembershipSuccessPage] depois de um resultado de sucesso
  /// daqui — nunca porque o usuário "chegou ao fim do formulário".
  /// Quem decide esse sucesso é `SupabaseMembershipRepository`, gravando a
  /// assinatura em `supporter_memberships`.
  Future<Result<Membership>> submitRegistration({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  });
}

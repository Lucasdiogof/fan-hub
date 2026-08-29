import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/data/membership_error_mapper.dart';
import 'package:goias_app/features/membership/data/membership_plans_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Substitui `MockMembershipRepository` — a assinatura de Sócio Torcedor é
/// persistida em `public.supporter_memberships`, vinculada ao usuário
/// autenticado. Planos continuam vindo do catálogo local
/// (`MembershipPlansCatalog`, ver spec: só a contratação em si precisava
/// virar real, não os planos).
///
/// `is_active` nunca é decidido aqui nem em nenhuma camada do app — vem
/// pronto de `get_my_membership()`, que compara `expires_at` com o `now()`
/// do próprio Postgres. Assim o relógio do aparelho nunca decide se alguém é
/// sócio.
class SupabaseMembershipRepository implements MembershipRepository {
  SupabaseMembershipRepository(this._client);

  final SupabaseClient _client;

  static const _membershipDuration = Duration(days: 30);

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Result<List<MembershipPlan>>> getPlans() async {
    return const Success(MembershipPlansCatalog.plans);
  }

  @override
  Future<Result<Membership?>> getMyMembership() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('get_my_membership');
      final row = rows.isEmpty ? null : rows.first as Map<String, dynamic>;
      if (row == null || row['is_active'] != true) return const Success(null);
      return Success(_mapRow(row));
    } catch (error, stackTrace) {
      return Error(mapMembershipError(error, stackTrace));
    }
  }

  @override
  Future<Result<List<CheckIn>>> getMyCheckIns() async {
    // Nunca usado em produção — o check-in real (`CheckInCubit`) fala com
    // `TicketRepository`, não com este. Mantido só porque a interface já
    // declarava; ver `membership_repository.dart`.
    return const Success([]);
  }

  @override
  Future<Result<CheckIn>> checkIn(String matchId) async {
    return const Error(UnexpectedFailure());
  }

  @override
  Future<Result<Membership>> submitRegistration({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  }) async {
    try {
      final startedAt = DateTime.now().toUtc();
      final expiresAt = startedAt.add(_membershipDuration);
      final row = await _client
          .from('supporter_memberships')
          .insert({
            'user_id': _uid,
            'plan_id': plan.id,
            'plan_name': plan.name,
            'started_at': startedAt.toIso8601String(),
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();
      return Success(
        Membership(
          id: row['id'] as String,
          userId: _uid,
          plan: plan,
          planPrice: price,
          status: MembershipStatus.active,
          startedAt: DateTime.parse(row['started_at'] as String),
          expiresAt: DateTime.parse(row['expires_at'] as String),
          regulationVersion: regulationVersion,
          regulationAcceptedAt: regulationAcceptedAt,
        ),
      );
    } catch (error, stackTrace) {
      return Error(mapMembershipError(error, stackTrace));
    }
  }

  Membership _mapRow(Map<String, dynamic> row) {
    final planId = row['plan_id'] as String;
    final plan = MembershipPlansCatalog.plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => MembershipPlansCatalog.plans.first,
    );
    return Membership(
      id: row['id'] as String,
      userId: _uid,
      plan: plan,
      planPrice: plan.defaultPrice,
      status: MembershipStatus.active,
      startedAt: DateTime.parse(row['started_at'] as String),
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  }
}

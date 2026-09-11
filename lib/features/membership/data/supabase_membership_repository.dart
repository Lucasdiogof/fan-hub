import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/data/membership_error_mapper.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Substitui `MockMembershipRepository` — a assinatura de Sócio Torcedor é
/// persistida em `public.supporter_memberships`, vinculada ao usuário
/// autenticado. Planos continuam vindo do catálogo local de cada clube
/// (`ClubConfig.membershipProgram.plans`, ver spec: só a contratação em si
/// precisava virar real, não os planos).
///
/// `is_active` nunca é decidido aqui nem em nenhuma camada do app — vem
/// pronto de `get_my_membership()`, que compara `expires_at` com o `now()`
/// do próprio Postgres. Assim o relógio do aparelho nunca decide se alguém é
/// sócio. A validade da contratação em si (`started_at`/`expires_at`) também
/// nunca é calculada aqui — vem pronta de `subscribe_to_plan()`, pelo mesmo
/// motivo (ver `submitRegistration`).
class SupabaseMembershipRepository implements MembershipRepository {
  SupabaseMembershipRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  @override
  Future<Result<List<MembershipPlan>>> getPlans() async {
    return Success(_clubConfig.membershipProgram.plans);
  }

  @override
  Future<Result<Membership?>> getMyMembership() async {
    try {
      // Runtime novo (M3.2): variante tenant-aware — filtra
      // `user_id = auth.uid() AND club_id = p_club_id`, nunca o
      // `order by created_at desc limit 1` global da RPC legacy (que
      // continua intacta só pro app antigo — §15-16 do pedido da M3.2).
      final rows = await _client.rpc<List<dynamic>>(
        'get_my_membership_for_club',
        params: {'p_club_id': _clubId},
      );
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
      // started_at/expires_at nunca são calculados aqui — a RPC decide os
      // dois com o horário do próprio Postgres e rejeita se já existe
      // assinatura ativa ou se `plan.id` não corresponde a um plano real
      // (ver supabase/migrations/20260830220002_subscribe_to_plan_rpc.sql).
      // Runtime novo (M3.2): variante tenant-aware — grava `club_id`
      // explícito e permite assinaturas simultâneas ativas em clubes
      // diferentes (mesmo padrão de `user_notification_preferences`), nunca
      // a RPC legacy (fica só pro app antigo).
      final rows = await _client.rpc<List<dynamic>>(
        'subscribe_to_plan_for_club',
        params: {'p_club_id': _clubId, 'p_plan_id': plan.id},
      );
      final row = rows.first as Map<String, dynamic>;
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
    final plans = _clubConfig.membershipProgram.plans;
    final plan = plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => plans.first,
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

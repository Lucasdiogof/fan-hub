import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MembershipStatusState extends Equatable {
  const MembershipStatusState({
    this.status = LoadStatus.initial,
    this.membership,
    this.subscribing = false,
  });

  final LoadStatus status;
  final Membership? membership;

  /// Separado de [status] de propósito — [status] já é mutado por [load]
  /// (chamado no login/logout); reaproveitar o mesmo campo faria uma
  /// chamada de `subscribeToPlan` em andamento colidir com um `load()`
  /// concorrente (ou vice-versa). Guarda contra duplo toque/chamada
  /// concorrente em `subscribeToPlan` (ver spec de hardening: "defesa em
  /// profundidade", a UI já desabilita o botão, isto é o backstop no Cubit).
  final bool subscribing;

  bool get isMember => membership != null;
  DateTime? get expiresAt => membership?.expiresAt;

  /// Só pra exibição ("X dias restantes") — nunca usado pra decidir
  /// `isMember`, que já vem pronto do backend (ver
  /// `SupabaseMembershipRepository`/`get_my_membership()`).
  int? get daysRemaining {
    final expires = expiresAt;
    if (expires == null) return null;
    final remaining = expires.difference(DateTime.now()).inHours / 24;
    return remaining.ceil().clamp(0, 1 << 30);
  }

  MembershipStatusState copyWith({
    LoadStatus? status,
    Membership? membership,
    bool clearMembership = false,
    bool? subscribing,
  }) {
    return MembershipStatusState(
      status: status ?? this.status,
      membership: clearMembership ? null : (membership ?? this.membership),
      subscribing: subscribing ?? this.subscribing,
    );
  }

  @override
  List<Object?> get props => [status, membership, subscribing];
}

/// Fonte única de verdade de "este usuário é Sócio Torcedor?" — singleton
/// (ver `injection_container.dart`), nunca recriado por tela. Antes desta
/// classe existir, `HomeCubit`, `TicketsCubit`, `RankingCubit` e o Perfil
/// consultavam `MembershipRepository.getMyMembership()` cada um por conta
/// própria, com sua própria cópia de `status == MembershipStatus.active` —
/// qualquer novo lugar que precise saber se o usuário é sócio deve ler
/// [state] daqui, nunca chamar o repositório de novo.
///
/// Ouve `AuthCubit` pra nunca vazar sócio de uma conta pra outra: limpa na
/// hora em logout/sessão expirada (sem esperar rede), recarrega no login.
class MembershipStatusCubit extends Cubit<MembershipStatusState> {
  MembershipStatusCubit(this._repository, AuthCubit authCubit)
    : super(const MembershipStatusState()) {
    if (authCubit.state is AuthAuthenticated) load();
    _authSubscription = authCubit.stream.listen(_onAuthChanged);
  }

  final MembershipRepository _repository;
  late final StreamSubscription<AuthState> _authSubscription;

  void _onAuthChanged(AuthState state) {
    switch (state) {
      case AuthAuthenticated():
        load();
      case AuthUnauthenticated():
      case AuthSessionExpired():
        emit(const MembershipStatusState(status: LoadStatus.success));
      case AuthInitial():
      case AuthPasswordRecovery():
        break;
    }
  }

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getMyMembership();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: LoadStatus.success,
            membership: data,
            clearMembership: data == null,
          ),
        );
      case Error():
        // Falha de rede/servidor nunca deixa o app "travado" sem saber o
        // status — cai pro estado mais seguro (não-sócio) em vez de mostrar
        // um loading indefinido; um `load()` seguinte (pull-to-refresh,
        // reabrir a aba) tenta de novo.
        emit(state.copyWith(status: LoadStatus.success, clearMembership: true));
    }
  }

  /// Impede duas assinaturas simultâneas por acidente (ver spec: "usuário
  /// ativo tenta contratar novamente não deve criar assinatura duplicada").
  /// A tela de planos já não deveria oferecer isso enquanto `isMember` for
  /// verdadeiro, mas a checagem mora aqui — não em cada botão que chama
  /// isto — pra nunca depender de a UI lembrar de verificar antes.
  Future<Result<Membership>> subscribeToPlan({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  }) async {
    if (state.subscribing) {
      return const Error(UnexpectedFailure('Operação em andamento.'));
    }
    if (state.isMember) {
      return const Error(ServerFailure('Você já é sócio torcedor.'));
    }
    emit(state.copyWith(subscribing: true));
    final result = await _repository.submitRegistration(
      plan: plan,
      price: price,
      data: data,
      regulationVersion: regulationVersion,
      regulationAcceptedAt: regulationAcceptedAt,
    );
    switch (result) {
      case Success(:final data):
        // Atualiza o estado global na hora, sem esperar um novo round-trip —
        // já temos a assinatura recém-criada em mãos.
        emit(
          state.copyWith(
            status: LoadStatus.success,
            membership: data,
            subscribing: false,
          ),
        );
      case Error():
        emit(state.copyWith(subscribing: false));
    }
    return result;
  }

  @override
  Future<void> close() {
    unawaited(_authSubscription.cancel());
    return super.close();
  }
}

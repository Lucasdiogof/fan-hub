import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Combina o evento em destaque (`TicketRepository`, não sabe nada de
/// sócio) com o status de associação (`MembershipRepository`, feature
/// diferente) — quem decide sócio-vs-não-sócio é este Cubit, nunca a UI.
class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(this._ticketRepository, this._membershipRepository)
    : super(const TicketsState()) {
    load();
  }

  final TicketRepository _ticketRepository;
  final MembershipRepository _membershipRepository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final eventFuture = _ticketRepository.getFeaturedEvent();
    final membershipFuture = _membershipRepository.getMyMembership();
    final eventResult = await eventFuture;
    final membershipResult = await membershipFuture;

    final TicketEvent? event;
    switch (eventResult) {
      case Success(:final data):
        event = data;
      case Error(:final failure):
        emit(state.copyWith(status: LoadStatus.error, errorMessage: failure.message));
        return;
    }

    final isMember = switch (membershipResult) {
      Success(:final data) => data?.status == MembershipStatus.active,
      Error() => false,
    };

    emit(
      state.copyWith(
        status: LoadStatus.success,
        event: event,
        clearEvent: event == null,
        isMember: isMember,
      ),
    );
  }
}

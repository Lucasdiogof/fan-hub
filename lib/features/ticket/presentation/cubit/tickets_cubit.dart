import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Combina o evento em destaque (`TicketRepository`, não sabe nada de
/// sócio) com o status de associação, lido de `MembershipStatusCubit` — a
/// fonte única de "é sócio?" do app inteiro, nunca uma consulta própria a
/// `MembershipRepository` aqui. Quem decide sócio-vs-não-sócio pro CTA de
/// ingresso/check-in é este Cubit, nunca a UI.
class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(this._ticketRepository, this._membershipStatusCubit)
    : super(const TicketsState()) {
    load();
  }

  final TicketRepository _ticketRepository;
  final MembershipStatusCubit _membershipStatusCubit;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));

    final eventResult = await _ticketRepository.getFeaturedEvent();

    final TicketEvent? event;
    switch (eventResult) {
      case Success(:final data):
        event = data;
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: failure.message,
          ),
        );
        return;
    }

    emit(
      state.copyWith(
        status: LoadStatus.success,
        event: event,
        clearEvent: event == null,
        isMember: _membershipStatusCubit.state.isMember,
      ),
    );
  }
}

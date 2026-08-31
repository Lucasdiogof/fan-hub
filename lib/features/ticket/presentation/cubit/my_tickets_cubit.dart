import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MyTicketsCubit extends Cubit<MyTicketsState> {
  MyTicketsCubit(this._repository) : super(const MyTicketsState()) {
    load();
  }

  final TicketRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getMyTickets();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            tickets: data,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> requestRefund(String ticketId) async {
    if (state.refunding) return;
    emit(state.copyWith(refunding: true, refundErrorMessage: () => null));
    final result = await _repository.requestRefund(ticketId);
    switch (result) {
      case Success():
        // Recarrega a lista inteira em vez de só trocar o item local — o
        // ingresso reembolsado precisa sair de "Próximos" e entrar em
        // "Histórico", que são recalculados a partir de `tickets` (ver
        // `MyTicketsState.upcoming`/`history`). `load()` não mexe em
        // `refunding`, então ele só volta a `false` aqui no final.
        await load();
        emit(state.copyWith(refunding: false));
      case Error(:final failure):
        emit(
          state.copyWith(
            refunding: false,
            refundErrorMessage: () => failure.message,
          ),
        );
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_state.dart';

/// Carrinho de compra de uma partida — vive por toda a jornada (seleção de
/// setor/categoria → resumo → titular → finalizar), um Cubit só, não um por
/// tela, já que o estado (quantidades, titular) precisa sobreviver entre
/// elas.
class PurchaseCubit extends Cubit<PurchaseState> {
  PurchaseCubit(this._repository, TicketEvent event)
    : super(PurchaseState(event: event));

  final TicketRepository _repository;

  void setQuantity(String sectorId, String categoryId, int quantity) {
    final next = Map<(String, String), int>.from(state.quantities);
    if (quantity <= 0) {
      next.remove((sectorId, categoryId));
    } else {
      next[(sectorId, categoryId)] = quantity;
    }
    emit(state.copyWith(quantities: next));
  }

  void setHolderIsSelf(
    bool value, {
    String? profileName,
    String? profileDocument,
  }) {
    emit(
      state.copyWith(
        holderIsSelf: value,
        holderName: value ? (profileName ?? '') : '',
        holderDocument: value ? (profileDocument ?? '') : '',
      ),
    );
  }

  void setHolderName(String value) => emit(state.copyWith(holderName: value));

  void setHolderDocument(String value) =>
      emit(state.copyWith(holderDocument: value));

  Future<void> finalizePurchase() async {
    if (!state.canFinalize) return;
    emit(state.copyWith(saving: true, clearError: true));
    final result = await _repository.purchase(
      matchId: state.event.match.id.toString(),
      items: state.items,
      holderName: state.holderName.trim(),
      holderDocument: state.holderDocument.trim(),
    );
    switch (result) {
      case Success(:final data):
        final ticketsResult = await _repository.getMyTickets();
        final purchasedTickets = switch (ticketsResult) {
          Success(data: final allTickets) =>
            allTickets.where((ticket) => ticket.orderId == data.id).toList(),
          Error() => const <Ticket>[],
        };
        emit(
          state.copyWith(
            saving: false,
            order: data,
            purchasedTickets: purchasedTickets,
          ),
        );
      case Error(:final failure):
        emit(state.copyWith(saving: false, errorMessage: failure.message));
    }
  }
}

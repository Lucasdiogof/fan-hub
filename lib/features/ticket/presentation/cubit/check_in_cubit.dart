import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/check_in_state.dart';

/// Estado da tela de confirmação de check-in — seleção de setor, envio e
/// recusa. Não sabe nada de sócio/plano (isso já veio pronto em
/// `TicketEvent`, montado por `TicketsCubit`); só orquestra as ações desta
/// tela sobre `TicketRepository`.
class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit(this._repository, TicketEvent event)
    : super(CheckInState(event: event));

  final TicketRepository _repository;

  void selectSector(String sectorId) =>
      emit(state.copyWith(selectedSectorId: sectorId));

  Future<void> confirm({
    required String holderName,
    required String holderDocument,
  }) async {
    final sectorId = state.selectedSectorId;
    if (sectorId == null) return;
    emit(state.copyWith(saving: true, clearError: true));
    final result = await _repository.checkIn(
      matchId: state.event.match.id.toString(),
      sectorId: sectorId,
      holderName: holderName,
      holderDocument: holderDocument,
    );
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            saving: false,
            justConfirmed: true,
            confirmedTicket: data,
          ),
        );
      case Error(:final failure):
        emit(state.copyWith(saving: false, errorMessage: failure.message));
    }
  }

  Future<void> decline() async {
    emit(state.copyWith(saving: true, clearError: true));
    final result = await _repository.declineCheckIn(
      state.event.match.id.toString(),
    );
    switch (result) {
      case Success():
        emit(state.copyWith(saving: false, justDeclined: true));
      case Error(:final failure):
        emit(state.copyWith(saving: false, errorMessage: failure.message));
    }
  }
}

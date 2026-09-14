import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_state.dart';

/// Carrinho de compra de uma partida — vive por toda a jornada (seleção de
/// setor/categoria → resumo → titulares → finalizar), um Cubit só, não um por
/// tela, já que o estado (quantidades, titulares) precisa sobreviver entre
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

  /// Garante um `TicketHolder` por ingresso físico (`totalQuantity`) —
  /// chamado ao entrar na tela de titulares. Preserva o que já foi
  /// preenchido em slots existentes; novos slots nascem vazios, exceto o
  /// primeiro, que a própria tela pré-marca como "é pra mim" (caso mais
  /// comum: comprar pelo menos 1 ingresso pro próprio usuário).
  void ensureHolderSlots() {
    final target = state.totalQuantity;
    if (state.holders.length == target) return;
    final holders = List<TicketHolder>.generate(
      target,
      (i) => i < state.holders.length
          ? state.holders[i]
          : const TicketHolder(name: '', document: ''),
    );
    emit(state.copyWith(holders: holders));
  }

  void setHolderIsSelf(
    int index, {
    required bool value,
    String? profileName,
    String? profileDocument,
  }) {
    final holders = List<TicketHolder>.of(state.holders);
    holders[index] = holders[index].copyWith(
      name: value ? (profileName ?? '') : '',
      document: value ? (profileDocument ?? '') : '',
      isSelf: value,
    );
    emit(state.copyWith(holders: holders));
  }

  void setHolderName(int index, String value) {
    final holders = List<TicketHolder>.of(state.holders);
    holders[index] = holders[index].copyWith(name: value);
    emit(state.copyWith(holders: holders));
  }

  void setHolderDocument(int index, String value) {
    final holders = List<TicketHolder>.of(state.holders);
    holders[index] = holders[index].copyWith(document: value);
    emit(state.copyWith(holders: holders));
  }

  /// Trocar o tipo limpa o comprovante já enviado — `promotional` nunca
  /// exige comprovante, e um `law` que troca de titular/categoria não deve
  /// herdar o arquivo de uma escolha anterior sem o usuário confirmar de
  /// novo.
  void setHolderHalfPriceType(int index, HalfPriceType type) {
    final holders = List<TicketHolder>.of(state.holders);
    holders[index] = holders[index].copyWith(
      halfPriceType: type,
      clearHalfPriceProofPath: true,
    );
    emit(state.copyWith(holders: holders));
  }

  Future<void> uploadHalfPriceProof(
    int index,
    Uint8List bytes,
    String fileExtension,
  ) async {
    emit(state.copyWith(saving: true, clearError: true));
    final result = await _repository.uploadHalfPriceProof(bytes, fileExtension);
    switch (result) {
      case Success(:final data):
        final holders = List<TicketHolder>.of(state.holders);
        holders[index] = holders[index].copyWith(halfPriceProofPath: data);
        emit(state.copyWith(saving: false, holders: holders));
      case Error(:final failure):
        emit(state.copyWith(saving: false, errorMessage: failure.message));
    }
  }

  Future<void> finalizePurchase() async {
    if (state.saving || !state.canFinalize) return;
    emit(state.copyWith(saving: true, clearError: true));
    final result = await _repository.purchase(
      matchId: state.event.match.id.toString(),
      items: state.items,
      holders: [
        for (final holder in state.holders)
          TicketHolder(
            name: holder.name.trim(),
            document: holder.document.trim(),
            isSelf: holder.isSelf,
            halfPriceType: holder.halfPriceType,
            halfPriceProofPath: holder.halfPriceProofPath,
          ),
      ],
    );
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(saving: false, order: data));
      case Error(:final failure):
        emit(state.copyWith(saving: false, errorMessage: failure.message));
    }
  }
}

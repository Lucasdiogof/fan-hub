import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(this._repository) : super(const TicketsState()) {
    load();
  }

  final TicketRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getFeaturedEvent();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: LoadStatus.success, featuredEvent: data, clearEvent: data == null));
      case Error(:final failure):
        emit(state.copyWith(status: LoadStatus.error, errorMessage: failure.message));
    }
  }
}

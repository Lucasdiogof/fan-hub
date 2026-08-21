import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MyOrdersCubit extends Cubit<MyOrdersState> {
  MyOrdersCubit(this._repository) : super(const MyOrdersState()) {
    load();
  }

  final TicketRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getMyOrders();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: data.isEmpty ? LoadStatus.empty : LoadStatus.success, orders: data));
      case Error(:final failure):
        emit(state.copyWith(status: LoadStatus.error, errorMessage: failure.message));
    }
  }
}

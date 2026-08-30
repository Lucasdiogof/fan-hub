import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/repositories/store_orders_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/store_orders_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class StoreOrdersCubit extends Cubit<StoreOrdersState> {
  StoreOrdersCubit(this._repository) : super(const StoreOrdersState());

  final StoreOrdersRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getOrders();
    switch (result) {
      case Success(:final data):
        final orders = [...data]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(
          state.copyWith(
            status: orders.isEmpty ? LoadStatus.empty : LoadStatus.success,
            orders: orders,
          ),
        );
      case Error():
        emit(state.copyWith(status: LoadStatus.error));
    }
  }
}

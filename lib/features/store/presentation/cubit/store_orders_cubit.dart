import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/store_orders_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class StoreOrdersCubit extends Cubit<StoreOrdersState> {
  StoreOrdersCubit(this._repository) : super(const StoreOrdersState());

  final StoreRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final orders = await _repository.getOrders();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(
      state.copyWith(
        status: orders.isEmpty ? LoadStatus.empty : LoadStatus.success,
        orders: orders,
      ),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/shared/state/load_status.dart';

class StoreOrdersState extends Equatable {
  const StoreOrdersState({
    this.status = LoadStatus.initial,
    this.orders = const [],
  });

  final LoadStatus status;
  final List<StoreOrder> orders;

  StoreOrdersState copyWith({LoadStatus? status, List<StoreOrder>? orders}) =>
      StoreOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
      );

  @override
  List<Object?> get props => [status, orders];
}

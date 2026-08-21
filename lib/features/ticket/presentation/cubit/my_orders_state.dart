import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MyOrdersState extends Equatable {
  const MyOrdersState({this.status = LoadStatus.initial, this.orders = const [], this.errorMessage});

  final LoadStatus status;
  final List<TicketOrder> orders;
  final String? errorMessage;

  MyOrdersState copyWith({LoadStatus? status, List<TicketOrder>? orders, String? errorMessage}) {
    return MyOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, orders, errorMessage];
}

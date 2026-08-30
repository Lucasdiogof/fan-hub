import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/repositories/store_orders_repository.dart';

/// Repositório falso em memória — mesma ideia de `FakeStoreRepository`, só
/// que cobrindo `StoreOrdersRepository` (separado desde que os pedidos
/// passaram a ser persistidos de verdade, ver `SupabaseStoreOrdersRepository`).
class FakeStoreOrdersRepository implements StoreOrdersRepository {
  final List<StoreOrder> orders = [];

  /// Espião — quantas vezes [createOrder] foi de fato chamado, pra testar
  /// que um duplo clique/toque não cria dois pedidos.
  int createOrderCallCount = 0;

  /// Quando setado, [createOrder]/[getOrders] lançam isto em vez de
  /// funcionar normalmente — pra testar o tratamento de erro do checkout.
  Object? failWith;

  @override
  Future<StoreOrder> createOrder({
    required List<OrderItem> items,
    required CustomerIdentification identification,
    required FulfillmentMethod fulfillmentMethod,
    CustomerAddress? address,
    ShippingOption? shippingOption,
    PickupResponsible? pickupResponsible,
    required PaymentSimulationInput payment,
    required double subtotal,
    required double discountAmount,
    String? couponCode,
  }) async {
    createOrderCallCount++;
    final failure = failWith;
    if (failure != null) throw failure;

    final order = StoreOrder(
      id: 'GOI-2026-${100000 + createOrderCallCount}',
      createdAt: DateTime(2026, 1, 1),
      items: items,
      identification: identification,
      fulfillmentMethod: fulfillmentMethod,
      address: address,
      shippingOption: shippingOption,
      pickupInfo: fulfillmentMethod == FulfillmentMethod.pickup
          ? const PickupInformation()
          : null,
      pickupResponsible: pickupResponsible,
      payment: PaymentSimulation(
        method: payment.method,
        status: payment.forceRejected
            ? PaymentStatus.rejected
            : PaymentStatus.approved,
        simulatedAt: DateTime(2026, 1, 1),
      ),
      subtotal: subtotal,
      discountAmount: discountAmount,
      shippingCost: fulfillmentMethod == FulfillmentMethod.pickup
          ? 0
          : (shippingOption?.price ?? 0),
      couponCode: couponCode,
      status: OrderStatus.paid,
    );
    orders.add(order);
    return order;
  }

  @override
  Future<List<StoreOrder>> getOrders() async {
    final failure = failWith;
    if (failure != null) throw failure;
    return orders;
  }

  @override
  Future<StoreOrder?> getOrderById(String id) async =>
      orders.where((o) => o.id == id).firstOrNull;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

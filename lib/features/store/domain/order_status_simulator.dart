import 'package:goias_app/features/store/domain/entities/store_order.dart';

/// Como não existe logística real, a evolução do pedido no tempo é
/// simulada — mas centralizada aqui, nunca espalhada em `if`s de `DateTime`
/// pelos widgets. A tela de lista e a de detalhe só recebem um
/// [OrderStatus] pronto de [resolve]; nenhuma delas sabe que é mock.
///
/// Só avança pedidos que já foram efetivamente pagos ([OrderStatus.paid]
/// em diante) — `cancelled`/`created`/`paymentPending` nunca progridem
/// sozinhos com o tempo. As durações abaixo são propositalmente curtas pra
/// demonstração; trocar por um feed de status real no futuro é só apagar
/// esta classe e devolver `order.status` direto.
class OrderStatusSimulator {
  const OrderStatusSimulator._();

  /// Quanto tempo depois da criação cada etapa (após `paid`) é alcançada.
  static const _delivery = [
    Duration.zero, // paid
    Duration(minutes: 2), // preparing
    Duration(minutes: 5), // shipped
    Duration(minutes: 10), // delivered
  ];

  static const _pickup = [
    Duration.zero, // paid
    Duration(minutes: 2), // preparing
    Duration(minutes: 4), // readyForPickup
    Duration(minutes: 8), // delivered (retirado)
  ];

  static const _deliverySteps = [
    OrderStatus.paid,
    OrderStatus.preparing,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  static const _pickupSteps = [
    OrderStatus.paid,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.delivered,
  ];

  static OrderStatus resolve(StoreOrder order, {DateTime? now}) {
    if (order.status != OrderStatus.paid) return order.status;

    final steps = order.isPickup ? _pickupSteps : _deliverySteps;
    final delays = order.isPickup ? _pickup : _delivery;
    final elapsed = (now ?? DateTime.now()).difference(order.createdAt);

    var resolved = steps.first;
    for (var i = 0; i < steps.length; i++) {
      if (elapsed >= delays[i]) resolved = steps[i];
    }
    return resolved;
  }
}

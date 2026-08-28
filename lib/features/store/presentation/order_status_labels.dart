import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Rótulos/sequência do `OrderStatus` — o mesmo enum serve entrega E
/// retirada (ver docstring em `store_order.dart`); aqui é onde as duas
/// leituras divergem, nunca em dois enums separados.
String orderStatusLabel(
  AppLocalizations l10n,
  OrderStatus status, {
  required bool isPickup,
}) {
  return switch (status) {
    OrderStatus.created => l10n.storeStatusCreated,
    OrderStatus.paymentPending => l10n.storeStatusPaymentPending,
    OrderStatus.paid => l10n.storeStatusPaid,
    OrderStatus.preparing => l10n.storeStatusPreparing,
    OrderStatus.readyForPickup => l10n.storeStatusReadyForPickup,
    OrderStatus.shipped => l10n.storeStatusShipped,
    OrderStatus.delivered =>
      isPickup
          ? l10n.storeStatusDeliveredPickup
          : l10n.storeStatusDeliveredShipping,
    OrderStatus.cancelled => l10n.storeStatusCancelled,
  };
}

/// Sequência "normal" (sem cancelamento) pra montar a timeline — difere só
/// na etapa de saída (retirada vs. envio).
List<OrderStatus> orderStatusTimeline({required bool isPickup}) => [
  OrderStatus.created,
  OrderStatus.paymentPending,
  OrderStatus.paid,
  OrderStatus.preparing,
  isPickup ? OrderStatus.readyForPickup : OrderStatus.shipped,
  OrderStatus.delivered,
];

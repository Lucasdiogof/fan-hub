import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/order_status_simulator.dart';

const _identification = CustomerIdentification(
  fullName: 'Lucas Diogo',
  cpf: '11144477735',
  email: 'lucas@example.com',
  phone: '62999998888',
);

final _payment = PaymentSimulation(
  method: PaymentMethod.pix,
  status: PaymentStatus.approved,
  simulatedAt: DateTime(2026, 1, 1),
);

StoreOrder _order({
  required DateTime createdAt,
  required OrderStatus status,
  bool isPickup = false,
}) => StoreOrder(
  id: 'GOI-2026-000001',
  createdAt: createdAt,
  items: const [],
  identification: _identification,
  fulfillmentMethod: isPickup
      ? FulfillmentMethod.pickup
      : FulfillmentMethod.delivery,
  pickupInfo: isPickup ? const PickupInformation() : null,
  payment: _payment,
  subtotal: 79.90,
  discountAmount: 0,
  shippingCost: 0,
  couponCode: null,
  status: status,
);

void main() {
  final createdAt = DateTime(2026, 1, 1, 12);

  group('terminal/pending statuses never progress with time', () {
    for (final status in [
      OrderStatus.created,
      OrderStatus.paymentPending,
      OrderStatus.cancelled,
    ]) {
      test('$status stays $status no matter how much time passes', () {
        final order = _order(createdAt: createdAt, status: status);
        final resolved = OrderStatusSimulator.resolve(
          order,
          now: createdAt.add(const Duration(days: 30)),
        );
        expect(resolved, status);
      });
    }
  });

  group('delivery timeline', () {
    test('right after paying, the order is still just paid', () {
      final order = _order(createdAt: createdAt, status: OrderStatus.paid);
      final resolved = OrderStatusSimulator.resolve(order, now: createdAt);
      expect(resolved, OrderStatus.paid);
    });

    test('advances to preparing, then shipped, then delivered over time', () {
      final order = _order(createdAt: createdAt, status: OrderStatus.paid);

      expect(
        OrderStatusSimulator.resolve(
          order,
          now: createdAt.add(const Duration(minutes: 3)),
        ),
        OrderStatus.preparing,
      );
      expect(
        OrderStatusSimulator.resolve(
          order,
          now: createdAt.add(const Duration(minutes: 6)),
        ),
        OrderStatus.shipped,
      );
      expect(
        OrderStatusSimulator.resolve(
          order,
          now: createdAt.add(const Duration(minutes: 15)),
        ),
        OrderStatus.delivered,
      );
    });

    test('never reaches readyForPickup — that is pickup-only', () {
      final order = _order(createdAt: createdAt, status: OrderStatus.paid);
      final resolved = OrderStatusSimulator.resolve(
        order,
        now: createdAt.add(const Duration(hours: 1)),
      );
      expect(resolved, isNot(OrderStatus.readyForPickup));
    });
  });

  group('pickup timeline', () {
    test(
      'advances to preparing, then readyForPickup, then delivered (retirado)',
      () {
        final order = _order(
          createdAt: createdAt,
          status: OrderStatus.paid,
          isPickup: true,
        );

        expect(
          OrderStatusSimulator.resolve(
            order,
            now: createdAt.add(const Duration(minutes: 3)),
          ),
          OrderStatus.preparing,
        );
        expect(
          OrderStatusSimulator.resolve(
            order,
            now: createdAt.add(const Duration(minutes: 5)),
          ),
          OrderStatus.readyForPickup,
        );
        expect(
          OrderStatusSimulator.resolve(
            order,
            now: createdAt.add(const Duration(hours: 1)),
          ),
          OrderStatus.delivered,
        );
      },
    );

    test('never reaches shipped — that is delivery-only', () {
      final order = _order(
        createdAt: createdAt,
        status: OrderStatus.paid,
        isPickup: true,
      );
      final resolved = OrderStatusSimulator.resolve(
        order,
        now: createdAt.add(const Duration(hours: 1)),
      );
      expect(resolved, isNot(OrderStatus.shipped));
    });
  });
}

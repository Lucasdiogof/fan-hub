import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/presentation/cubit/store_orders_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

import 'fakes/fake_store_orders_repository.dart';

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

StoreOrder _order(String id, DateTime createdAt) => StoreOrder(
  id: id,
  createdAt: createdAt,
  items: const [],
  identification: _identification,
  fulfillmentMethod: FulfillmentMethod.pickup,
  pickupInfo: const PickupInformation(
    storeName: 'Test Store',
    street: 'Rua Teste, 1',
    neighborhood: 'Bairro Teste',
    city: 'Cidade Teste',
    state: 'TS',
    zipCode: '00000-000',
  ),
  payment: _payment,
  subtotal: 79.90,
  discountAmount: 0,
  shippingCost: 0,
  couponCode: null,
  status: OrderStatus.paid,
);

void main() {
  late FakeStoreOrdersRepository repository;

  setUp(() => repository = FakeStoreOrdersRepository());

  test(
    'starts as initial and loads to empty when there are no orders',
    () async {
      final cubit = StoreOrdersCubit(repository);
      addTearDown(cubit.close);
      expect(cubit.state.status, LoadStatus.initial);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
      expect(cubit.state.orders, isEmpty);
    },
  );

  test('loads existing orders, most recent first', () async {
    repository.orders.addAll([
      _order('GOI-2026-000001', DateTime(2026, 1, 1)),
      _order('GOI-2026-000002', DateTime(2026, 3, 1)),
      _order('GOI-2026-000003', DateTime(2026, 2, 1)),
    ]);

    final cubit = StoreOrdersCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.orders.map((o) => o.id), [
      'GOI-2026-000002',
      'GOI-2026-000003',
      'GOI-2026-000001',
    ]);
  });

  test('a repository failure surfaces as an error status', () async {
    repository.failWith = Exception('network down');
    final cubit = StoreOrdersCubit(repository);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, LoadStatus.error);
  });
}

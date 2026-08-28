import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/data/mock_store_repository.dart';
import 'package:goias_app/features/store/data/store_local_storage.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const identification = CustomerIdentification(
  fullName: 'Lucas Diogo',
  cpf: '11144477735',
  email: 'lucas@example.com',
  phone: '62999998888',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStoreRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockStoreRepository(StoreLocalStorage());
  });

  test('getProducts loads the real catalog asset', () async {
    final products = await repository.getProducts();

    expect(products, isNotEmpty);
    expect(products.first.id, 'uniform_01_female_fan');
  });

  test(
    'getCategories only returns categories that have at least one product',
    () async {
      final categories = await repository.getCategories();

      expect(
        categories.map((c) => c.id),
        containsAll(['uniforms', 'feminine']),
      );
      // "kids" não tem nenhum produto no catálogo mock — não deveria aparecer.
      expect(categories.map((c) => c.id), isNot(contains('kids')));
    },
  );

  test('searchProducts matches by name', () async {
    final results = await repository.searchProducts('camisa');
    expect(results, isNotEmpty);

    final none = await repository.searchProducts('produto-que-nao-existe');
    expect(none, isEmpty);
  });

  group('calculateShipping', () {
    test(
      'matches the specified mock tiers and prices below the free threshold',
      () async {
        final options = await repository.calculateShipping(
          zipCode: '74000-000',
          cartSubtotal: 100,
        );

        expect(
          options.map((o) => (o.speed, o.price)),
          containsAll([
            (ShippingSpeed.economy, 14.90),
            (ShippingSpeed.standard, 22.90),
            (ShippingSpeed.express, 34.90),
          ]),
        );
      },
    );

    test('economy becomes free at or above R\$399.90', () async {
      final below = await repository.calculateShipping(
        zipCode: '74000-000',
        cartSubtotal: 399.89,
      );
      final atThreshold = await repository.calculateShipping(
        zipCode: '74000-000',
        cartSubtotal: 399.90,
      );

      expect(below.first.price, 14.90);
      expect(atThreshold.first.price, 0);
    });
  });

  group('resolveCouponDiscountPercent', () {
    test('VERDAO10 resolves to 10%, case-insensitively', () async {
      expect(await repository.resolveCouponDiscountPercent('verdao10'), 10.0);
    });

    test('SOCIO15 resolves to 15%', () async {
      expect(await repository.resolveCouponDiscountPercent('SOCIO15'), 15.0);
    });

    test('an unknown coupon resolves to null', () async {
      expect(
        await repository.resolveCouponDiscountPercent('INEXISTENTE'),
        isNull,
      );
    });
  });

  group('createOrder', () {
    test('generates a GOI-<year>-###### order code', () async {
      final order = await repository.createOrder(
        items: const [],
        identification: identification,
        fulfillmentMethod: FulfillmentMethod.pickup,
        payment: const PaymentSimulationInput(method: PaymentMethod.pix),
        subtotal: 79.90,
        discountAmount: 0,
      );

      expect(order.id, matches(RegExp(r'^GOI-\d{4}-\d{6}$')));
    });

    test('an approved order is persisted and shows up in getOrders', () async {
      await repository.createOrder(
        items: const [],
        identification: identification,
        fulfillmentMethod: FulfillmentMethod.pickup,
        payment: const PaymentSimulationInput(method: PaymentMethod.pix),
        subtotal: 79.90,
        discountAmount: 0,
      );

      final orders = await repository.getOrders();
      expect(orders, hasLength(1));
    });

    test('a rejected (forceRejected) order is never persisted', () async {
      await repository.createOrder(
        items: const [],
        identification: identification,
        fulfillmentMethod: FulfillmentMethod.pickup,
        payment: const PaymentSimulationInput(
          method: PaymentMethod.pix,
          forceRejected: true,
        ),
        subtotal: 79.90,
        discountAmount: 0,
      );

      final orders = await repository.getOrders();
      expect(orders, isEmpty);
    });

    test('pickup orders never carry a shipping cost', () async {
      final order = await repository.createOrder(
        items: const [],
        identification: identification,
        fulfillmentMethod: FulfillmentMethod.pickup,
        shippingOption: const ShippingOption(
          speed: ShippingSpeed.express,
          label: 'Expressa',
          etaLabel: '2 a 3 dias úteis',
          price: 34.90,
        ),
        payment: const PaymentSimulationInput(method: PaymentMethod.pix),
        subtotal: 79.90,
        discountAmount: 0,
      );

      expect(order.shippingCost, 0);
    });
  });

  group('local persistence', () {
    test('cart is saved and reloaded across repository instances', () async {
      const cart = Cart(
        items: [
          CartItem(
            id: 'i1',
            productId: 'uniform_01_female_fan',
            productName: 'Camisa',
            thumbnail: 'thumb.jpg',
            size: 'M',
            unitPrice: 349.90,
          ),
        ],
      );
      await repository.saveCart(cart);

      final reloaded = MockStoreRepository(StoreLocalStorage());
      final loaded = await reloaded.loadCart();
      expect(loaded.items, hasLength(1));
      expect(loaded.items.single.productId, 'uniform_01_female_fan');
    });

    test('addresses round-trip through persistence', () async {
      const address = CustomerAddress(
        id: 'a1',
        zipCode: '74000-000',
        street: 'Rua Teste',
        number: '10',
        neighborhood: 'Setor Teste',
        city: 'Goiânia',
        state: 'GO',
      );
      await repository.saveAddresses([address]);

      final reloaded = await MockStoreRepository(
        StoreLocalStorage(),
      ).loadAddresses();
      expect(reloaded, hasLength(1));
      expect(reloaded.single.zipCode, '74000-000');
    });

    test(
      'the order payload only ever carries the last 4 card digits — the type has no room for more',
      () async {
        final order = await repository.createOrder(
          items: const [],
          identification: identification,
          fulfillmentMethod: FulfillmentMethod.pickup,
          payment: const PaymentSimulationInput(
            method: PaymentMethod.creditCard,
            cardHolderName: 'LUCAS DIOGO',
            cardLastFourDigits: '4242',
          ),
          subtotal: 79.90,
          discountAmount: 0,
        );

        final cardJson = order.payment.cardSummary!.toJson();
        expect(
          cardJson.keys,
          containsAll(['holderName', 'lastFourDigits', 'installments']),
        );
        expect(
          cardJson.keys,
          isNot(
            anyOf(contains('cvv'), contains('cardNumber'), contains('expiry')),
          ),
        );
        expect((cardJson['lastFourDigits'] as String).length, 4);
      },
    );
  });
}

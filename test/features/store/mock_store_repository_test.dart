import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/data/mock_store_repository.dart';
import 'package:goias_app/features/store/data/store_local_storage.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        containsAll(['uniforms', 'feminine', 'kids', 'accessories']),
      );
      // "souvenirs" existe no menu mas não tem nenhum produto no catálogo
      // mock — categorias sem produto não devem aparecer.
      expect(categories.map((c) => c.id), isNot(contains('souvenirs')));
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

  });
}

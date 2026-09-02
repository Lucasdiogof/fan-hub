import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/data/mock_store_repository.dart';
import 'package:goias_app/features/store/data/store_local_storage.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desembrulha um `Result` esperando sucesso — falha o teste com uma
/// mensagem clara se vier `Error`, em vez de um cast quebrando sem contexto.
T _unwrap<T>(Result<T> result) => switch (result) {
  Success(:final data) => data,
  Error(:final failure) => throw StateError('Esperava Success, veio $failure'),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStoreRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockStoreRepository(StoreLocalStorage(goiasClubConfig));
  });

  test('getProducts loads the real catalog asset', () async {
    final products = _unwrap(await repository.getProducts());

    expect(products, isNotEmpty);
    expect(products.first.id, 'uniform_01_female_fan');
  });

  test(
    'getCategories only returns categories that have at least one product',
    () async {
      final categories = _unwrap(await repository.getCategories());

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
    final results = _unwrap(await repository.searchProducts('camisa'));
    expect(results, isNotEmpty);

    final none = _unwrap(
      await repository.searchProducts('produto-que-nao-existe'),
    );
    expect(none, isEmpty);
  });

  group('calculateShipping', () {
    test(
      'matches the specified mock tiers and prices below the free threshold',
      () async {
        final options = _unwrap(
          await repository.calculateShipping(
            zipCode: '74000-000',
            cartSubtotal: 100,
          ),
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
      final below = _unwrap(
        await repository.calculateShipping(
          zipCode: '74000-000',
          cartSubtotal: 399.89,
        ),
      );
      final atThreshold = _unwrap(
        await repository.calculateShipping(
          zipCode: '74000-000',
          cartSubtotal: 399.90,
        ),
      );

      expect(below.first.price, 14.90);
      expect(atThreshold.first.price, 0);
    });
  });

  group('resolveCouponDiscountPercent', () {
    test('VERDAO10 resolves to 10%, case-insensitively', () async {
      expect(
        _unwrap(await repository.resolveCouponDiscountPercent('verdao10')),
        10.0,
      );
    });

    test('SOCIO15 resolves to 15%', () async {
      expect(
        _unwrap(await repository.resolveCouponDiscountPercent('SOCIO15')),
        15.0,
      );
    });

    test('an unknown coupon resolves to null', () async {
      expect(
        _unwrap(await repository.resolveCouponDiscountPercent('INEXISTENTE')),
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

      final reloaded = MockStoreRepository(StoreLocalStorage(goiasClubConfig));
      final loaded = _unwrap(await reloaded.loadCart());
      expect(loaded.items, hasLength(1));
      expect(loaded.items.single.productId, 'uniform_01_female_fan');
    });

  });
}

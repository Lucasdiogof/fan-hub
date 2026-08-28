import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';

import 'fakes/fake_store_repository.dart';

CartItem _item({
  String id = 'item-1',
  String productId = 'jersey-fem',
  String size = 'M',
  double unitPrice = 349.90,
  int quantity = 1,
  String? personalizedName,
  int? personalizedNumber,
  double personalizationSurcharge = 0,
}) => CartItem(
  id: id,
  productId: productId,
  productName: 'Camisa Goiás Uniforme 01 Feminina',
  thumbnail: 'fem_thumb.jpg',
  size: size,
  unitPrice: unitPrice,
  quantity: quantity,
  personalizedName: personalizedName,
  personalizedNumber: personalizedNumber,
  personalizationSurcharge: personalizationSurcharge,
);

void main() {
  late FakeStoreRepository repository;
  late CartCubit cubit;

  setUp(() {
    repository = FakeStoreRepository();
    cubit = CartCubit(repository);
  });

  tearDown(() => cubit.close());

  test(
    'adding the same product+size+personalization merges quantities instead of duplicating',
    () async {
      await cubit.load();
      await cubit.addItem(_item());
      await cubit.addItem(_item(quantity: 2));

      expect(cubit.state.cart.items, hasLength(1));
      expect(cubit.state.cart.items.single.quantity, 3);
    },
  );

  test('a different size creates a separate line', () async {
    await cubit.load();
    await cubit.addItem(_item());
    await cubit.addItem(_item(id: 'item-2', size: 'G'));

    expect(cubit.state.cart.items, hasLength(2));
  });

  test('updateQuantity to zero removes the item, same as removeItem', () async {
    await cubit.load();
    await cubit.addItem(_item());
    await cubit.updateQuantity('item-1', 0);

    expect(cubit.state.cart.isEmpty, isTrue);
  });

  test('removeItem drops only the targeted line', () async {
    await cubit.load();
    await cubit.addItem(_item());
    await cubit.addItem(_item(id: 'item-2', size: 'G'));
    await cubit.removeItem('item-1');

    expect(cubit.state.cart.items, hasLength(1));
    expect(cubit.state.cart.items.single.id, 'item-2');
  });

  test('every mutation is persisted to the repository immediately', () async {
    await cubit.load();
    await cubit.addItem(_item());

    expect(repository.cart.items, hasLength(1));
  });

  test('personalization surcharge is included in the line total', () async {
    await cubit.load();
    await cubit.addItem(
      _item(
        personalizedName: 'LUCAS',
        personalizationSurcharge: 30,
        quantity: 2,
      ),
    );

    // (349.90 + 30) * 2
    expect(cubit.state.cart.subtotal, closeTo(759.80, 0.001));
  });

  group('coupons', () {
    test('VERDAO10 applies a 10% discount on the subtotal', () async {
      await cubit.load();
      await cubit.addItem(_item(unitPrice: 100, quantity: 1));
      await cubit.applyCoupon('verdao10');

      expect(cubit.state.cart.coupon?.code, 'VERDAO10');
      expect(cubit.state.cart.discountAmount, closeTo(10, 0.001));
      expect(cubit.state.cart.totalAfterDiscount, closeTo(90, 0.001));
    });

    test('SOCIO15 applies a 15% discount', () async {
      await cubit.load();
      await cubit.addItem(_item(unitPrice: 100, quantity: 1));
      await cubit.applyCoupon('SOCIO15');

      expect(cubit.state.cart.discountAmount, closeTo(15, 0.001));
    });

    test(
      'an unknown code is rejected with an error and no coupon is applied',
      () async {
        await cubit.load();
        await cubit.addItem(_item(unitPrice: 100, quantity: 1));
        await cubit.applyCoupon('NAOEXISTE');

        expect(cubit.state.cart.coupon, isNull);
        expect(cubit.state.invalidCoupon, isTrue);
      },
    );

    test('removeCoupon clears the applied coupon', () async {
      await cubit.load();
      await cubit.addItem(_item(unitPrice: 100, quantity: 1));
      await cubit.applyCoupon('VERDAO10');
      await cubit.removeCoupon();

      expect(cubit.state.cart.coupon, isNull);
      expect(cubit.state.cart.totalAfterDiscount, closeTo(100, 0.001));
    });
  });
}

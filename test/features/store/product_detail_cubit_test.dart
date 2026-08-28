import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/presentation/cubit/product_detail_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/product_detail_state.dart';

import 'fakes/fake_store_repository.dart';

void main() {
  late FakeStoreRepository repository;
  late ProductDetailCubit cubit;

  setUp(() {
    repository = FakeStoreRepository();
    cubit = ProductDetailCubit(repository);
  });

  tearDown(() => cubit.close());

  test(
    'a product with more than one size does not preselect any size',
    () async {
      await cubit.load('jersey-fem');

      expect(cubit.state.selectedSize, isNull);
      expect(cubit.state.blockReason, ProductBlockReason.chooseSize);
      expect(cubit.state.canAddToCart, isFalse);
    },
  );

  test('a product with a single size auto-selects it', () async {
    await cubit.load('cap-unico');

    expect(cubit.state.selectedSize, 'ÚNICO');
    expect(cubit.state.canAddToCart, isTrue);
  });

  test('selecting an out-of-stock size blocks adding to cart', () async {
    await cubit.load('jersey-fem');
    cubit.selectSize('G'); // stock: 0

    expect(cubit.state.canAddToCart, isFalse);
    expect(cubit.state.blockReason, ProductBlockReason.outOfStock);
  });

  test('selecting an in-stock size unblocks adding to cart', () async {
    await cubit.load('jersey-fem');
    cubit.selectSize('M');

    expect(cubit.state.canAddToCart, isTrue);
  });

  test('quantity is clamped between 1 and 10', () async {
    await cubit.load('jersey-fem');
    cubit.setQuantity(0);
    expect(cubit.state.quantity, 1);
    cubit.setQuantity(99);
    expect(cubit.state.quantity, 10);
  });

  group('personalization surcharge', () {
    test('is zero with no personalization', () async {
      await cubit.load('jersey-fem');
      expect(cubit.state.personalizationSurcharge, 0);
    });

    test('adds the name cost only when a non-empty name is set', () async {
      await cubit.load('jersey-fem');
      cubit.setPersonalizedName('LUCAS');
      expect(cubit.state.personalizationSurcharge, 30);

      cubit.setPersonalizedName('');
      expect(cubit.state.personalizationSurcharge, 0);
      expect(cubit.state.wantsPersonalization, isFalse);
    });

    test('adds the number cost only when a number is set', () async {
      await cubit.load('jersey-fem');
      cubit.setPersonalizedNumber(10);
      expect(cubit.state.personalizationSurcharge, 40);
    });

    test('name and number surcharges stack', () async {
      await cubit.load('jersey-fem');
      cubit.setPersonalizedName('LUCAS');
      cubit.setPersonalizedNumber(10);
      expect(cubit.state.personalizationSurcharge, 70);
      expect(
        cubit.state.unitPriceWithPersonalization,
        closeTo(349.90 + 70, 0.001),
      );
    });

    test(
      'a product without personalization support always has zero surcharge',
      () async {
        await cubit.load('cap-unico');
        expect(cubit.state.product!.allowsPersonalization, isFalse);
        expect(cubit.state.personalizationSurcharge, 0);
      },
    );
  });
}

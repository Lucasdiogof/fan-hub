import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/store_catalog_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

import '../../fakes/fake_store_repository.dart';

class _FakeStoreRepository implements StoreRepository {
  Result<List<StoreProduct>> productsResult = const Success([]);
  Result<List<StoreCategory>> categoriesResult = const Success([]);

  @override
  Future<Result<List<StoreProduct>>> getProducts() async => productsResult;

  @override
  Future<Result<StoreProduct>> getProductById(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<List<StoreCategory>>> getCategories() async => categoriesResult;

  @override
  Future<Result<List<StoreProduct>>> searchProducts(String query) =>
      throw UnimplementedError();

  @override
  Future<Result<List<ShippingOption>>> calculateShipping({
    required String zipCode,
    required double cartSubtotal,
  }) => throw UnimplementedError();

  @override
  Future<Result<double?>> resolveCouponDiscountPercent(String code) =>
      throw UnimplementedError();

  @override
  Future<Result<Cart>> loadCart() => throw UnimplementedError();

  @override
  Future<Result<void>> saveCart(Cart value) => throw UnimplementedError();
}

void main() {
  late _FakeStoreRepository repository;
  late StoreCatalogCubit cubit;

  setUp(() {
    repository = _FakeStoreRepository();
    cubit = StoreCatalogCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial fica em LoadStatus.initial, sem produtos', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.products, isEmpty);
  });

  group('load', () {
    test('sucesso combina produtos e categorias', () async {
      repository.productsResult = const Success([
        fakeJerseyFeminine,
        fakeJerseyMasculine,
      ]);
      repository.categoriesResult = const Success([
        StoreCategory(id: 'uniforms', name: 'Uniformes', icon: Icons.checkroom),
      ]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.products, [fakeJerseyFeminine, fakeJerseyMasculine]);
      expect(cubit.state.categories.length, 1);
    });

    test('sem produto nenhum emite LoadStatus.empty', () async {
      repository.productsResult = const Success([]);

      await cubit.load();

      expect(cubit.state.status, LoadStatus.empty);
    });

    test(
      'falha ao buscar produtos emite error, mesmo se categorias funcionassem',
      () async {
        repository.productsResult = const Error(ServerFailure('erro'));
        repository.categoriesResult = const Success([]);

        await cubit.load();

        expect(cubit.state.status, LoadStatus.error);
      },
    );

    test('produtos ok mas falha nas categorias também emite error', () async {
      repository.productsResult = const Success([fakeJerseyFeminine]);
      repository.categoriesResult = const Error(ServerFailure('erro'));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
    });
  });
}

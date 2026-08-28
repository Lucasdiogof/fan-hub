import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_filters.dart';

import 'fakes/fake_store_repository.dart';

const _soldOut = StoreProduct(
  id: 'sold-out',
  slug: 'sold-out',
  name: 'Camisa esgotada',
  shortDescription: '',
  description: '',
  brand: 'Diadora',
  reference: 'GOI-SOLD-OUT',
  categoryIds: ['uniforms'],
  collectionIds: [],
  audience: StoreAudience.unisex,
  type: ProductType.matchJersey,
  price: 199.90,
  images: ['sold_out.jpg'],
  thumbnail: 'sold_out_thumb.jpg',
  variations: [ProductVariation(sku: 'SOLD-OUT-M', size: 'M', stock: 0)],
);

void main() {
  late FakeStoreRepository repository;

  setUp(() => repository = FakeStoreRepository());

  test('load() populates allProducts from the repository catalog', () async {
    final cubit = StoreListingCubit(repository);
    await cubit.load();

    expect(cubit.state.allProducts, hasLength(3));
    addTearDown(cubit.close);
  });

  test(
    'a categoryId scopes visibleProducts to that category or collection',
    () async {
      final cubit = StoreListingCubit(repository, categoryId: 'accessories');
      await cubit.load();

      expect(cubit.state.visibleProducts.map((p) => p.id), ['cap-unico']);
      addTearDown(cubit.close);
    },
  );

  test('query filters by name (accent/case-insensitive)', () async {
    final cubit = StoreListingCubit(repository);
    await cubit.load();
    cubit.setQuery('bone');

    expect(cubit.state.visibleProducts.map((p) => p.id), ['cap-unico']);
    addTearDown(cubit.close);
  });

  test('audience filter narrows results', () async {
    final cubit = StoreListingCubit(repository);
    await cubit.load();
    cubit.setFilters(const StoreListingFilters(audiences: {'masculine'}));

    expect(cubit.state.visibleProducts.map((p) => p.id), ['jersey-masc']);
    addTearDown(cubit.close);
  });

  test('onlyOnSale filter keeps only discounted products', () async {
    final cubit = StoreListingCubit(repository);
    await cubit.load();
    cubit.setFilters(const StoreListingFilters(onlyOnSale: true));

    expect(cubit.state.visibleProducts.map((p) => p.id), ['jersey-masc']);
    addTearDown(cubit.close);
  });

  test('onlyAvailable filter drops fully out-of-stock products', () async {
    final soldOutRepo = FakeStoreRepository(
      products: [fakeJerseyFeminine, _soldOut],
    );
    final cubit = StoreListingCubit(soldOutRepo);
    await cubit.load();
    cubit.setFilters(const StoreListingFilters(onlyAvailable: true));

    expect(cubit.state.visibleProducts.map((p) => p.id), ['jersey-fem']);
    addTearDown(cubit.close);
  });

  test('clearFilters resets to the default (empty) filters', () async {
    final cubit = StoreListingCubit(repository);
    await cubit.load();
    cubit.setFilters(const StoreListingFilters(onlyOnSale: true));
    cubit.clearFilters();

    expect(cubit.state.filters.isEmpty, isTrue);
    expect(cubit.state.visibleProducts, hasLength(3));
    addTearDown(cubit.close);
  });

  group('sort', () {
    test('priceLowToHigh orders ascending by price', () async {
      final cubit = StoreListingCubit(repository);
      await cubit.load();
      cubit.setSort(StoreSortOrder.priceLowToHigh);

      expect(cubit.state.visibleProducts.map((p) => p.id), [
        'cap-unico',
        'jersey-masc',
        'jersey-fem',
      ]);
      addTearDown(cubit.close);
    });

    test('priceHighToLow orders descending by price', () async {
      final cubit = StoreListingCubit(repository);
      await cubit.load();
      cubit.setSort(StoreSortOrder.priceHighToLow);

      expect(cubit.state.visibleProducts.map((p) => p.id), [
        'jersey-fem',
        'jersey-masc',
        'cap-unico',
      ]);
      addTearDown(cubit.close);
    });

    test('biggestDiscount puts the on-sale product first', () async {
      final cubit = StoreListingCubit(repository);
      await cubit.load();
      cubit.setSort(StoreSortOrder.biggestDiscount);

      expect(cubit.state.visibleProducts.first.id, 'jersey-masc');
      addTearDown(cubit.close);
    });
  });
}

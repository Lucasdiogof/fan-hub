import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';

const fakeJerseyFeminine = StoreProduct(
  id: 'jersey-fem',
  slug: 'jersey-fem',
  name: 'Camisa Goiás Uniforme 01 Feminina',
  shortDescription: 'Manto titular feminino',
  description: 'Descrição completa do manto titular feminino.',
  brand: 'Diadora',
  reference: 'GOI-01-FEM',
  categoryIds: ['uniforms', 'feminine'],
  collectionIds: ['kit_01'],
  audience: StoreAudience.feminine,
  type: ProductType.matchJersey,
  uniformEdition: '01',
  price: 349.90,
  maxInstallments: 3,
  images: ['fem_1.jpg'],
  thumbnail: 'fem_thumb.jpg',
  variations: [
    ProductVariation(sku: 'FEM-P', size: 'P', stock: 1),
    ProductVariation(sku: 'FEM-M', size: 'M', stock: 2),
    ProductVariation(sku: 'FEM-G', size: 'G', stock: 0),
  ],
  isNew: true,
  personalization: ProductPersonalization(allowsName: true, allowsNumber: true),
);

const fakeJerseyMasculine = StoreProduct(
  id: 'jersey-masc',
  slug: 'jersey-masc',
  name: 'Camisa Goiás Uniforme 02 Masculina',
  shortDescription: 'Manto reserva masculino',
  description: 'Descrição completa do manto reserva masculino.',
  brand: 'Diadora',
  reference: 'GOI-02-MASC',
  categoryIds: ['uniforms', 'masculine'],
  collectionIds: ['kit_02'],
  audience: StoreAudience.masculine,
  type: ProductType.matchJersey,
  uniformEdition: '02',
  price: 299.90,
  originalPrice: 349.90,
  maxInstallments: 6,
  images: ['masc_1.jpg'],
  thumbnail: 'masc_thumb.jpg',
  variations: [
    ProductVariation(sku: 'MASC-M', size: 'M', stock: 5),
    ProductVariation(sku: 'MASC-G', size: 'G', stock: 5),
  ],
  isFeatured: true,
);

const fakeCap = StoreProduct(
  id: 'cap-unico',
  slug: 'cap-unico',
  name: 'Boné Goiás Casual',
  shortDescription: 'Boné oficial',
  description: 'Descrição completa do boné oficial.',
  brand: 'Goiás',
  reference: 'GOI-CAP',
  categoryIds: ['accessories'],
  collectionIds: ['casual'],
  audience: StoreAudience.unisex,
  type: ProductType.accessory,
  price: 79.90,
  images: ['cap_1.jpg'],
  thumbnail: 'cap_thumb.jpg',
  variations: [ProductVariation(sku: 'CAP-U', size: 'ÚNICO', stock: 10)],
);

/// Repositório falso em memória — mesma ideia de `_FakeStorage` em
/// `lineup_cubit_test.dart`, só que cobrindo toda a superfície de
/// `StoreRepository`, pra testar cubits sem depender de SharedPreferences
/// real nem do asset JSON do catálogo.
class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository({List<StoreProduct>? products})
    : products = products ?? [fakeJerseyFeminine, fakeJerseyMasculine, fakeCap];

  final List<StoreProduct> products;
  Cart cart = const Cart();

  static const freeShippingThreshold = 399.90;
  static const coupons = {'VERDAO10': 10.0, 'SOCIO15': 15.0};

  @override
  Future<Result<List<StoreProduct>>> getProducts() async => Success(products);

  @override
  Future<Result<StoreProduct>> getProductById(String id) async =>
      Success(products.firstWhere((p) => p.id == id));

  @override
  Future<Result<List<StoreCategory>>> getCategories() async =>
      const Success([]);

  @override
  Future<Result<List<StoreProduct>>> searchProducts(String query) async =>
      Success(
        products
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );

  @override
  Future<Result<List<ShippingOption>>> calculateShipping({
    required String zipCode,
    required double cartSubtotal,
  }) async {
    final freeEligible = cartSubtotal >= freeShippingThreshold;
    return Success([
      ShippingOption(
        speed: ShippingSpeed.economy,
        label: 'Econômica',
        etaLabel: '7 a 10 dias úteis',
        price: freeEligible ? 0 : 14.90,
      ),
      const ShippingOption(
        speed: ShippingSpeed.standard,
        label: 'Padrão',
        etaLabel: '4 a 7 dias úteis',
        price: 22.90,
      ),
      const ShippingOption(
        speed: ShippingSpeed.express,
        label: 'Expressa',
        etaLabel: '2 a 3 dias úteis',
        price: 34.90,
      ),
    ]);
  }

  @override
  Future<Result<double?>> resolveCouponDiscountPercent(String code) async =>
      Success(coupons[code.trim().toUpperCase()]);

  @override
  Future<Result<Cart>> loadCart() async => Success(cart);

  @override
  Future<Result<void>> saveCart(Cart value) async {
    cart = value;
    return const Success(null);
  }
}

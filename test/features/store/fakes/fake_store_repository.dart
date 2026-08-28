import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
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
  final List<CustomerAddress> addresses = [];
  final Set<String> favoriteIds = {};
  final List<StoreOrder> orders = [];

  /// Espião — quantas vezes [createOrder] foi de fato chamado, pra testar
  /// que um duplo clique/toque não cria dois pedidos.
  int createOrderCallCount = 0;

  static const freeShippingThreshold = 399.90;
  static const coupons = {'VERDAO10': 10.0, 'SOCIO15': 15.0};

  @override
  Future<List<StoreProduct>> getProducts() async => products;

  @override
  Future<StoreProduct> getProductById(String id) async =>
      products.firstWhere((p) => p.id == id);

  @override
  Future<List<StoreCategory>> getCategories() async => const [];

  @override
  Future<List<StoreProduct>> searchProducts(String query) async => products
      .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  Future<List<ShippingOption>> calculateShipping({
    required String zipCode,
    required double cartSubtotal,
  }) async {
    final freeEligible = cartSubtotal >= freeShippingThreshold;
    return [
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
    ];
  }

  @override
  Future<double?> resolveCouponDiscountPercent(String code) async =>
      coupons[code.trim().toUpperCase()];

  @override
  Future<StoreOrder> createOrder({
    required List<OrderItem> items,
    required CustomerIdentification identification,
    required FulfillmentMethod fulfillmentMethod,
    CustomerAddress? address,
    ShippingOption? shippingOption,
    PickupResponsible? pickupResponsible,
    required PaymentSimulationInput payment,
    required double subtotal,
    required double discountAmount,
    String? couponCode,
  }) async {
    createOrderCallCount++;
    final order = StoreOrder(
      id: 'GOI-2026-${100000 + createOrderCallCount}',
      createdAt: DateTime(2026, 1, 1),
      items: items,
      identification: identification,
      fulfillmentMethod: fulfillmentMethod,
      address: address,
      shippingOption: shippingOption,
      pickupInfo: fulfillmentMethod == FulfillmentMethod.pickup
          ? const PickupInformation()
          : null,
      pickupResponsible: pickupResponsible,
      payment: PaymentSimulation(
        method: payment.method,
        status: payment.forceRejected
            ? PaymentStatus.rejected
            : PaymentStatus.approved,
        simulatedAt: DateTime(2026, 1, 1),
      ),
      subtotal: subtotal,
      discountAmount: discountAmount,
      shippingCost: fulfillmentMethod == FulfillmentMethod.pickup
          ? 0
          : (shippingOption?.price ?? 0),
      couponCode: couponCode,
      status: OrderStatus.paid,
    );
    orders.add(order);
    return order;
  }

  @override
  Future<List<StoreOrder>> getOrders() async => orders;

  @override
  Future<StoreOrder?> getOrderById(String id) async =>
      orders.where((o) => o.id == id).firstOrNull;

  @override
  Future<Cart> loadCart() async => cart;

  @override
  Future<void> saveCart(Cart value) async => cart = value;

  @override
  Future<List<CustomerAddress>> loadAddresses() async => addresses;

  @override
  Future<void> saveAddresses(List<CustomerAddress> value) async {
    addresses
      ..clear()
      ..addAll(value);
  }

  @override
  Future<Set<String>> loadFavoriteProductIds() async => favoriteIds;

  @override
  Future<void> saveFavoriteProductIds(Set<String> ids) async {
    favoriteIds
      ..clear()
      ..addAll(ids);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

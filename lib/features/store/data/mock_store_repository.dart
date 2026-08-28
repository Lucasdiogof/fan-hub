import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/features/store/data/store_category_catalog.dart';
import 'package:goias_app/features/store/data/store_local_storage.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';

/// Regras da loja demonstrativa — todas centralizadas aqui, nunca
/// espalhadas por widget. Uma futura `TrayStoreRepository` substitui só
/// esta classe; frete/cupom/pedido passam a vir de verdade da API em vez
/// de simulados, sem a UI mudar nada.
const _freeShippingThreshold = 399.90;
const _coupons = {'VERDAO10': 10.0, 'SOCIO15': 15.0};

class MockStoreRepository implements StoreRepository {
  MockStoreRepository(this._storage);

  final StoreLocalStorage _storage;
  List<StoreProduct>? _catalogCache;
  final _random = Random();

  Future<List<StoreProduct>> _catalog() async {
    final cached = _catalogCache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(
      'lib/assets/content/store_products.json',
    );
    final list = (jsonDecode(raw) as List)
        .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _catalogCache = list;
    return list;
  }

  @override
  Future<List<StoreProduct>> getProducts() => _catalog();

  @override
  Future<StoreProduct> getProductById(String id) async {
    final products = await _catalog();
    return products.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Produto "$id" não encontrado.'),
    );
  }

  @override
  Future<List<StoreCategory>> getCategories() async {
    final products = await _catalog();
    final activeIds = <String>{};
    for (final product in products) {
      activeIds
        ..addAll(product.categoryIds)
        ..addAll(product.collectionIds);
    }
    return StoreCategoryCatalog.all
        .where((c) => activeIds.contains(c.id))
        .toList(growable: false);
  }

  @override
  Future<List<StoreProduct>> searchProducts(String query) async {
    final needle = normalizeName(query);
    if (needle.isEmpty) return [];
    final products = await _catalog();
    return products
        .where((product) {
          final haystack = normalizeName(
            [
              product.name,
              product.brand,
              product.audience.name,
              product.type.name,
              product.uniformEdition ?? '',
              ...product.categoryIds.map(
                (id) => StoreCategoryCatalog.byId(id)?.name ?? '',
              ),
              ...product.collectionIds.map(
                (id) => StoreCategoryCatalog.byId(id)?.name ?? '',
              ),
            ].join(' '),
          );
          return haystack.contains(needle);
        })
        .toList(growable: false);
  }

  @override
  Future<List<ShippingOption>> calculateShipping({
    required String zipCode,
    required double cartSubtotal,
  }) async {
    final freeEligible = cartSubtotal >= _freeShippingThreshold;
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
  Future<double?> resolveCouponDiscountPercent(String code) async {
    return _coupons[code.trim().toUpperCase()];
  }

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
    final id = _generateOrderCode();
    final status = payment.forceRejected
        ? PaymentStatus.rejected
        : PaymentStatus.approved;
    final simulation = PaymentSimulation(
      method: payment.method,
      status: status,
      cardSummary: payment.method == PaymentMethod.creditCard
          ? CardBillingSummary(
              holderName: payment.cardHolderName ?? '',
              lastFourDigits: payment.cardLastFourDigits ?? '',
              installments: payment.installments,
            )
          : null,
      simulatedAt: DateTime.now(),
    );

    final order = StoreOrder(
      id: id,
      createdAt: DateTime.now(),
      items: items,
      identification: identification,
      fulfillmentMethod: fulfillmentMethod,
      address: fulfillmentMethod == FulfillmentMethod.delivery ? address : null,
      shippingOption: fulfillmentMethod == FulfillmentMethod.delivery
          ? shippingOption
          : null,
      pickupInfo: fulfillmentMethod == FulfillmentMethod.pickup
          ? const PickupInformation()
          : null,
      pickupResponsible: fulfillmentMethod == FulfillmentMethod.pickup
          ? pickupResponsible
          : null,
      payment: simulation,
      subtotal: subtotal,
      discountAmount: discountAmount,
      shippingCost: fulfillmentMethod == FulfillmentMethod.pickup
          ? 0
          : (shippingOption?.price ?? 0),
      couponCode: couponCode,
      status: status == PaymentStatus.approved
          ? OrderStatus.paid
          : OrderStatus.paymentPending,
    );

    if (status == PaymentStatus.approved) {
      final orders = await _storage.loadOrders();
      await _storage.saveOrders([order, ...orders]);
    }
    return order;
  }

  String _generateOrderCode() {
    final year = DateTime.now().year;
    final sequence = (100000 + _random.nextInt(899999)).toString();
    return 'GOI-$year-$sequence';
  }

  @override
  Future<List<StoreOrder>> getOrders() => _storage.loadOrders();

  @override
  Future<StoreOrder?> getOrderById(String id) async {
    final orders = await _storage.loadOrders();
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Future<Cart> loadCart() async => await _storage.loadCart() ?? const Cart();

  @override
  Future<void> saveCart(Cart cart) => _storage.saveCart(cart);

  @override
  Future<List<CustomerAddress>> loadAddresses() => _storage.loadAddresses();

  @override
  Future<void> saveAddresses(List<CustomerAddress> addresses) =>
      _storage.saveAddresses(addresses);

  @override
  Future<Set<String>> loadFavoriteProductIds() =>
      _storage.loadFavoriteProductIds();

  @override
  Future<void> saveFavoriteProductIds(Set<String> ids) =>
      _storage.saveFavoriteProductIds(ids);
}

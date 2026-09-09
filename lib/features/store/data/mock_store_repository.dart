import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/data/store_category_catalog.dart';
import 'package:goias_app/features/store/data/store_error_mapper.dart';
import 'package:goias_app/features/store/data/store_local_storage.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';

/// Regras da loja demonstrativa — todas centralizadas aqui, nunca
/// espalhadas por widget. Uma futura `TrayStoreRepository` substitui só
/// esta classe; frete/cupom passam a vir de verdade da API em vez de
/// simulados, sem a UI mudar nada. Pedidos ficam em `StoreOrdersRepository`.
const _freeShippingThreshold = 399.90;
const _coupons = {'VERDAO10': 10.0, 'SOCIO15': 15.0};

class MockStoreRepository implements StoreRepository {
  MockStoreRepository(this._storage, this._clubConfig);

  final StoreLocalStorage _storage;
  final ClubConfig _clubConfig;
  List<StoreProduct>? _catalogCache;

  /// Path é do CLUBE ATIVO (`ClubAssets.storeCatalogAssetPath`) — nunca um
  /// literal fixo aqui. Clube sem catálogo próprio ainda (`null`) tem 0
  /// produtos: nunca lança, e jamais cai pro JSON de outro clube.
  Future<List<StoreProduct>> _catalog() async {
    final cached = _catalogCache;
    if (cached != null) return cached;
    final path = _clubConfig.assets.storeCatalogAssetPath;
    if (path == null) {
      _catalogCache = const [];
      return const [];
    }
    final raw = await rootBundle.loadString(path);
    final list = (jsonDecode(raw) as List)
        .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _catalogCache = list;
    return list;
  }

  @override
  Future<Result<List<StoreProduct>>> getProducts() async {
    try {
      return Success(await _catalog());
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<StoreProduct>> getProductById(String id) async {
    try {
      final products = await _catalog();
      return Success(
        products.firstWhere(
          (p) => p.id == id,
          orElse: () => throw StateError('Produto "$id" não encontrado.'),
        ),
      );
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<List<StoreCategory>>> getCategories() async {
    try {
      final products = await _catalog();
      final activeIds = <String>{};
      for (final product in products) {
        activeIds
          ..addAll(product.categoryIds)
          ..addAll(product.collectionIds);
      }
      return Success(
        StoreCategoryCatalog.all
            .where((c) => activeIds.contains(c.id))
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<List<StoreProduct>>> searchProducts(String query) async {
    try {
      final needle = normalizeName(query);
      if (needle.isEmpty) return const Success([]);
      final products = await _catalog();
      return Success(
        products
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
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<List<ShippingOption>>> calculateShipping({
    required String zipCode,
    required double cartSubtotal,
  }) async {
    try {
      final freeEligible = cartSubtotal >= _freeShippingThreshold;
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
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<double?>> resolveCouponDiscountPercent(String code) async {
    try {
      return Success(_coupons[code.trim().toUpperCase()]);
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<Cart>> loadCart() async {
    try {
      return Success(await _storage.loadCart() ?? const Cart());
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> saveCart(Cart cart) async {
    try {
      await _storage.saveCart(cart);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }
}

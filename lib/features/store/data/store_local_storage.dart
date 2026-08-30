import 'dart:convert';

import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tudo que a Goiás Store guarda no aparelho — carrinho, endereços e
/// favoritos. Pedidos NÃO ficam aqui (ver `StoreOrdersRepository`): são
/// vinculados à conta autenticada, não ao aparelho.
class StoreLocalStorage {
  static const _cartKey = 'store_cart';
  static const _addressesKey = 'store_addresses';
  static const _favoritesKey = 'store_favorite_product_ids';

  Future<Cart?> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey);
    if (raw == null) return null;
    try {
      return Cart.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCart(Cart cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart.toJson()));
  }

  Future<List<CustomerAddress>> loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAddresses(List<CustomerAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _addressesKey,
      jsonEncode(addresses.map((e) => e.toJson()).toList()),
    );
  }

  Future<Set<String>> loadFavoriteProductIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey)?.toSet() ?? {};
  }

  Future<void> saveFavoriteProductIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids.toList());
  }
}

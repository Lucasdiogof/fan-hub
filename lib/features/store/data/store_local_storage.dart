import 'dart:convert';

import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tudo que a Goiás Store guarda no aparelho — o carrinho. Pedidos NÃO
/// ficam aqui (ver `StoreOrdersRepository`) nem endereços de entrega (ver
/// `DeliveryAddressRepository`) — ambos vinculados à conta autenticada,
/// não ao aparelho.
class StoreLocalStorage {
  static const _cartKey = 'store_cart';

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
}

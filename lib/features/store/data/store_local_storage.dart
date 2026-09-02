import 'dart:convert';

import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_scoped_storage_key.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tudo que a loja do clube ativo guarda no aparelho — o carrinho. Pedidos
/// NÃO ficam aqui (ver `StoreOrdersRepository`) nem endereços de entrega
/// (ver `DeliveryAddressRepository`) — ambos vinculados à conta
/// autenticada, não ao aparelho. Chave namespaçada por clube desde a M3.3
/// (`ClubScopedStorageKey`) — com migração transparente da chave legacy
/// (sem namespace) só pro Goiás, nunca pra um clube sintético/novo.
class StoreLocalStorage {
  StoreLocalStorage(this._clubConfig);

  static const _cartKey = 'store_cart';

  final ClubConfig _clubConfig;

  Future<Cart?> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = ClubScopedStorageKey(_clubConfig);
    var raw = prefs.getString(keys.scoped(_cartKey));
    if (raw == null && _clubConfig.identity.code == 'goias') {
      // LEGACY_LOCAL_STATE_IS_GOIAS_ONLY — só o Goiás pode ter escrito essa
      // chave antiga (nenhum outro clube existiu ainda). Migra pra chave
      // namespaçada assim que encontrada, nunca fica lendo a legacy de novo.
      raw = prefs.getString(_cartKey);
      if (raw != null) await prefs.setString(keys.scoped(_cartKey), raw);
    }
    if (raw == null) return null;
    try {
      return Cart.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCart(Cart cart) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = ClubScopedStorageKey(_clubConfig);
    await prefs.setString(keys.scoped(_cartKey), jsonEncode(cart.toJson()));
  }
}

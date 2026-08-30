import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';

/// Fonte única do catálogo/carrinho/endereços da Goiás Store — hoje só
/// [MockStoreRepository] (catálogo local, tudo simulado). Nada na camada de
/// apresentação sabe que é mock; quando a integração com a Tray existir,
/// uma `TrayStoreRepository` implementa esta mesma interface e a UI não
/// muda uma linha. Pedidos NÃO moram aqui — ver `StoreOrdersRepository`.
///
/// Todo método retorna `Result<T>` (mesmo padrão de Membership/Perfil) —
/// nunca lança pra quem chama, sempre passa pelo `store_error_mapper` antes.
abstract interface class StoreRepository {
  Future<Result<List<StoreProduct>>> getProducts();
  Future<Result<StoreProduct>> getProductById(String id);
  Future<Result<List<StoreCategory>>> getCategories();
  Future<Result<List<StoreProduct>>> searchProducts(String query);

  /// Cotação de frete pro CEP informado, já considerando frete grátis
  /// acima do valor mínimo (regra central, nunca no widget).
  Future<Result<List<ShippingOption>>> calculateShipping({
    required String zipCode,
    required double cartSubtotal,
  });

  /// `Success(null)` se o cupom não existir — nunca é um `Error` pra um
  /// caso esperado, só falhas reais (leitura/rede) viram `Error`.
  Future<Result<double?>> resolveCouponDiscountPercent(String code);

  // Persistência local — carrinho e favoritos vivem no dispositivo (ver
  // `StoreLocalStorage`), não no backend/mock de catálogo, mas passam pelo
  // repository pra widgets/cubits nunca falarem com `SharedPreferences`
  // direto. Endereços de entrega NÃO ficam aqui — ver
  // `DeliveryAddressRepository` (por conta, no Supabase).
  Future<Result<Cart>> loadCart();
  Future<Result<void>> saveCart(Cart cart);

  Future<Result<Set<String>>> loadFavoriteProductIds();
  Future<Result<void>> saveFavoriteProductIds(Set<String> ids);
}

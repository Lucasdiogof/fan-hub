import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
// Reexport pra quem só importa o repository não precisar de outro import.
export 'package:goias_app/features/store/domain/entities/payment.dart'
    show PaymentMethod;

/// Fonte única da Goiás Store — hoje só [MockStoreRepository] (catálogo
/// local, tudo simulado). Nada na camada de apresentação sabe que é mock;
/// quando a integração com a Tray existir, uma `TrayStoreRepository`
/// implementa esta mesma interface e a UI não muda uma linha.
abstract interface class StoreRepository {
  Future<List<StoreProduct>> getProducts();
  Future<StoreProduct> getProductById(String id);
  Future<List<StoreCategory>> getCategories();
  Future<List<StoreProduct>> searchProducts(String query);

  /// Cotação de frete pro CEP informado, já considerando frete grátis
  /// acima do valor mínimo (regra central, nunca no widget).
  Future<List<ShippingOption>> calculateShipping({
    required String zipCode,
    required double cartSubtotal,
  });

  /// `null` se o cupom não existir — nunca lança pra um caso esperado.
  Future<double?> resolveCouponDiscountPercent(String code);

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
  });

  Future<List<StoreOrder>> getOrders();
  Future<StoreOrder?> getOrderById(String id);

  // Persistência local — carrinho, endereços e favoritos vivem no
  // dispositivo (ver `StoreLocalStorage`), não no backend/mock de catálogo,
  // mas passam pelo repository pra widgets/cubits nunca falarem com
  // `SharedPreferences` direto.
  Future<Cart> loadCart();
  Future<void> saveCart(Cart cart);

  Future<List<CustomerAddress>> loadAddresses();
  Future<void> saveAddresses(List<CustomerAddress> addresses);

  Future<Set<String>> loadFavoriteProductIds();
  Future<void> saveFavoriteProductIds(Set<String> ids);
}

/// Entrada crua de pagamento — a página de checkout monta isto a partir do
/// formulário (Pix ou cartão) e o repository decide status/aprovação
/// (sempre `approved` no mock, exceto quando o usuário simula recusa).
class PaymentSimulationInput {
  const PaymentSimulationInput({
    required this.method,
    this.cardHolderName,
    this.cardLastFourDigits,
    this.installments = 1,
    this.forceRejected = false,
  });

  final PaymentMethod method;
  final String? cardHolderName;
  final String? cardLastFourDigits;
  final int installments;
  final bool forceRejected;
}

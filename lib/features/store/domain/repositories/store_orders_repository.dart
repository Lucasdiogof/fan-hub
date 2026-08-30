import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
// Reexport pra quem só importa este repository não precisar de outro import.
export 'package:goias_app/features/store/domain/entities/payment.dart'
    show PaymentMethod;

/// Pedidos da Goiás Store — separado de [StoreRepository] de propósito: a
/// compra em si continua simulada (sem gateway/transportadora de verdade),
/// mas o HISTÓRICO de pedidos precisa ser real e vinculado à conta, então
/// tem seu próprio backend (Supabase) enquanto catálogo/carrinho/endereços
/// seguem locais — mesma separação que Ingressos/Sócio Torcedor já têm em
/// relação ao resto do app.
///
/// Todo método retorna `Result<T>` (mesmo padrão de Membership/Perfil) —
/// nunca lança pra quem chama, sempre passa pelo `store_error_mapper` antes.
abstract interface class StoreOrdersRepository {
  Future<Result<StoreOrder>> createOrder({
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

  Future<Result<List<StoreOrder>>> getOrders();
  Future<Result<StoreOrder?>> getOrderById(String id);
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

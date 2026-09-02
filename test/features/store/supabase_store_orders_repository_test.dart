import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/data/supabase_store_orders_repository.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/repositories/store_orders_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Desembrulha um `Result` esperando sucesso — falha o teste com uma
/// mensagem clara se vier `Error`, em vez de um cast quebrando sem contexto.
StoreOrder _unwrap(Result<StoreOrder> result) => switch (result) {
  Success(:final data) => data,
  Error(:final failure) => throw StateError('Esperava Success, veio $failure'),
};

const identification = CustomerIdentification(
  fullName: 'Lucas Diogo',
  cpf: '11144477735',
  email: 'lucas@example.com',
  phone: '62999998888',
);

void main() {
  // Um cliente Supabase "vazio" (nunca conecta de verdade) — só é seguro
  // aqui porque um pagamento recusado nunca chega a chamar a rede (ver
  // `SupabaseStoreOrdersRepository.createOrder`, que retorna cedo nesse
  // caso). Aprovar um pedido de verdade exigiria um Supabase real; a lógica
  // testável sem rede (redação do cartão, frete zerado na retirada) é
  // exatamente a mesma nos dois caminhos.
  late SupabaseStoreOrdersRepository repository;

  setUp(() {
    repository = SupabaseStoreOrdersRepository(
      SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
      goiasClubConfig,
    );
  });

  test(
    'a rejected (forceRejected) order is built but never touches the network',
    () async {
      final order = _unwrap(
        await repository.createOrder(
          items: const [],
          identification: identification,
          fulfillmentMethod: FulfillmentMethod.pickup,
          payment: const PaymentSimulationInput(
            method: PaymentMethod.pix,
            forceRejected: true,
          ),
          subtotal: 79.90,
          discountAmount: 0,
        ),
      );

      expect(order.id, matches(RegExp(r'^GOI-\d{4}-\d+$')));
    },
  );

  test('pickup orders never carry a shipping cost', () async {
    final order = _unwrap(
      await repository.createOrder(
        items: const [],
        identification: identification,
        fulfillmentMethod: FulfillmentMethod.pickup,
        shippingOption: const ShippingOption(
          speed: ShippingSpeed.express,
          label: 'Expressa',
          etaLabel: '2 a 3 dias úteis',
          price: 34.90,
        ),
        payment: const PaymentSimulationInput(
          method: PaymentMethod.pix,
          forceRejected: true,
        ),
        subtotal: 79.90,
        discountAmount: 0,
      ),
    );

    expect(order.shippingCost, 0);
  });

  test(
    'the order payload only ever carries the last 4 card digits — the type has no room for more',
    () async {
      final order = _unwrap(
        await repository.createOrder(
          items: const [],
          identification: identification,
          fulfillmentMethod: FulfillmentMethod.pickup,
          payment: const PaymentSimulationInput(
            method: PaymentMethod.creditCard,
            cardHolderName: 'LUCAS DIOGO',
            cardLastFourDigits: '4242',
            forceRejected: true,
          ),
          subtotal: 79.90,
          discountAmount: 0,
        ),
      );

      final cardJson = order.payment.cardSummary!.toJson();
      expect(
        cardJson.keys,
        containsAll(['holderName', 'lastFourDigits', 'installments']),
      );
      expect(
        cardJson.keys,
        isNot(
          anyOf(contains('cvv'), contains('cardNumber'), contains('expiry')),
        ),
      );
      expect((cardJson['lastFourDigits'] as String).length, 4);
    },
  );
}

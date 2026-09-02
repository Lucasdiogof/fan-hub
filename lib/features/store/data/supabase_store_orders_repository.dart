import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/data/store_error_mapper.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/repositories/store_orders_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Substitui a versão antiga (pedidos salvos em `SharedPreferences`, no
/// aparelho, sem dono) — agora persistidos em `public.store_orders`/
/// `public.store_order_items`, vinculados ao usuário autenticado (ver
/// `supabase/store_orders.sql`). A COMPRA continua simulada (nunca existe
/// gateway/transportadora real), mas o HISTÓRICO é real e sobrevive
/// logout/reinstalação, e nunca vaza entre contas (RLS).
///
/// `id`/`order_number` do pedido é o mesmo campo pra fora daqui — o app
/// inteiro (rotas, telas, testes) só conhece o código amigável tipo
/// `GOI-2026-000184`, nunca o uuid interno da linha.
///
/// A criação usa a função `create_store_order` (ver o SQL) pra inserir o
/// pedido e seus itens em uma única operação atômica — nunca dois inserts
/// separados que pudessem deixar um pedido "órfão" sem itens se o segundo
/// falhasse no meio do caminho.
class SupabaseStoreOrdersRepository implements StoreOrdersRepository {
  SupabaseStoreOrdersRepository(this._client, this._clubConfig);

  final SupabaseClient _client;
  final ClubConfig _clubConfig;

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  @override
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
  }) async {
    try {
      return Success(
        await _createOrder(
          items: items,
          identification: identification,
          fulfillmentMethod: fulfillmentMethod,
          address: address,
          shippingOption: shippingOption,
          pickupResponsible: pickupResponsible,
          payment: payment,
          subtotal: subtotal,
          discountAmount: discountAmount,
          couponCode: couponCode,
        ),
      );
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  Future<StoreOrder> _createOrder({
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
    final paymentStatus = payment.forceRejected
        ? PaymentStatus.rejected
        : PaymentStatus.approved;
    final simulation = PaymentSimulation(
      method: payment.method,
      status: paymentStatus,
      cardSummary: payment.method == PaymentMethod.creditCard
          ? CardBillingSummary(
              holderName: payment.cardHolderName ?? '',
              lastFourDigits: payment.cardLastFourDigits ?? '',
              installments: payment.installments,
            )
          : null,
      simulatedAt: DateTime.now(),
    );
    final resolvedAddress = fulfillmentMethod == FulfillmentMethod.delivery
        ? address
        : null;
    final resolvedShippingOption =
        fulfillmentMethod == FulfillmentMethod.delivery ? shippingOption : null;
    final resolvedPickupResponsible =
        fulfillmentMethod == FulfillmentMethod.pickup
        ? pickupResponsible
        : null;
    final shippingCost = fulfillmentMethod == FulfillmentMethod.pickup
        ? 0.0
        : (shippingOption?.price ?? 0);
    final status = paymentStatus == PaymentStatus.approved
        ? OrderStatus.paid
        : OrderStatus.paymentPending;

    // Pagamento "recusado" só existe pro fluxo de demonstração (nunca
    // exposto como opção real na UI) — nunca vira uma linha persistida,
    // igual o comportamento antigo do mock.
    if (paymentStatus == PaymentStatus.rejected) {
      final now = DateTime.now();
      final pseudoSequence = 100000 + (now.millisecondsSinceEpoch % 900000);
      return StoreOrder(
        id: 'GOI-${now.year}-$pseudoSequence',
        createdAt: now,
        items: items,
        identification: identification,
        fulfillmentMethod: fulfillmentMethod,
        address: resolvedAddress,
        shippingOption: resolvedShippingOption,
        pickupInfo: fulfillmentMethod == FulfillmentMethod.pickup
            ? const PickupInformation()
            : null,
        pickupResponsible: resolvedPickupResponsible,
        payment: simulation,
        subtotal: subtotal,
        discountAmount: discountAmount,
        shippingCost: shippingCost,
        couponCode: couponCode,
        status: status,
      );
    }

    // Runtime novo (M3.2): variante tenant-aware — grava `club_id`
    // explícito no pedido, nunca confia no DEFAULT Goiás da coluna. A RPC
    // legacy `create_store_order` fica intacta só pro app antigo (§21).
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_store_order_for_club',
      params: {
        'p_club_id': _clubId,
        'p_status': status.name,
        'p_fulfillment_method': fulfillmentMethod.name,
        'p_customer': identification.toJson(),
        'p_address': resolvedAddress?.toJson(),
        'p_shipping_option': resolvedShippingOption?.toJson(),
        'p_pickup_responsible': resolvedPickupResponsible?.toJson(),
        'p_payment': simulation.toJson(),
        'p_subtotal': subtotal,
        'p_discount_amount': discountAmount,
        'p_shipping_cost': shippingCost,
        'p_coupon_code': couponCode,
        'p_items': [
          for (final item in items)
            {
              'productId': item.productId,
              'productName': item.productName,
              'thumbnail': item.thumbnail,
              'size': item.size,
              'unitPrice': item.unitPrice,
              'quantity': item.quantity,
              'personalizedName': item.personalizedName,
              'personalizedNumber': item.personalizedNumber,
              'personalizationSurcharge': item.personalizationSurcharge,
            },
        ],
      },
    );

    return StoreOrder(
      id: row['order_number'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      items: items,
      identification: identification,
      fulfillmentMethod: fulfillmentMethod,
      address: resolvedAddress,
      shippingOption: resolvedShippingOption,
      pickupInfo: fulfillmentMethod == FulfillmentMethod.pickup
          ? const PickupInformation()
          : null,
      pickupResponsible: resolvedPickupResponsible,
      payment: simulation,
      subtotal: subtotal,
      discountAmount: discountAmount,
      shippingCost: shippingCost,
      couponCode: couponCode,
      status: status,
    );
  }

  @override
  Future<Result<List<StoreOrder>>> getOrders() async {
    try {
      final rows = await _client
          .from('store_orders')
          .select('*, store_order_items(*)')
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .order('created_at', ascending: false);
      return Success(rows.map(_mapOrder).toList());
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  @override
  Future<Result<StoreOrder?>> getOrderById(String id) async {
    try {
      final row = await _client
          .from('store_orders')
          .select('*, store_order_items(*)')
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .eq('order_number', id)
          .maybeSingle();
      return Success(row == null ? null : _mapOrder(row));
    } catch (error, stackTrace) {
      return Error(mapStoreError(error, stackTrace));
    }
  }

  StoreOrder _mapOrder(Map<String, dynamic> row) {
    final isPickup = row['fulfillment_method'] == 'pickup';
    final itemRows = row['store_order_items'] as List;
    return StoreOrder(
      id: row['order_number'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      items: itemRows.map((e) => _mapItem(e as Map<String, dynamic>)).toList(),
      identification: CustomerIdentification.fromJson(
        row['customer'] as Map<String, dynamic>,
      ),
      fulfillmentMethod: FulfillmentMethod.values.byName(
        row['fulfillment_method'] as String,
      ),
      address: row['address'] != null
          ? CustomerAddress.fromJson(row['address'] as Map<String, dynamic>)
          : null,
      shippingOption: row['shipping_option'] != null
          ? ShippingOption.fromJson(
              row['shipping_option'] as Map<String, dynamic>,
            )
          : null,
      pickupInfo: isPickup ? const PickupInformation() : null,
      pickupResponsible: row['pickup_responsible'] != null
          ? PickupResponsible.fromJson(
              row['pickup_responsible'] as Map<String, dynamic>,
            )
          : null,
      payment: PaymentSimulation.fromJson(
        row['payment'] as Map<String, dynamic>,
      ),
      subtotal: (row['subtotal'] as num).toDouble(),
      discountAmount: (row['discount_amount'] as num).toDouble(),
      shippingCost: (row['shipping_cost'] as num).toDouble(),
      couponCode: row['coupon_code'] as String?,
      status: OrderStatus.values.byName(row['status'] as String),
    );
  }

  OrderItem _mapItem(Map<String, dynamic> row) => OrderItem(
    productId: row['product_id'] as String,
    productName: row['product_name'] as String,
    thumbnail: row['product_image'] as String,
    size: row['size'] as String,
    unitPrice: (row['unit_price'] as num).toDouble(),
    quantity: row['quantity'] as int,
    personalizedName: row['personalized_name'] as String?,
    personalizedNumber: row['personalized_number'] as int?,
    personalizationSurcharge:
        (row['personalization_surcharge'] as num?)?.toDouble() ?? 0,
  );
}

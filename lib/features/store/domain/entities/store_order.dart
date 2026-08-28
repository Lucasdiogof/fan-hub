import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';

/// Estados possíveis de um pedido — os dois fluxos (entrega/retirada)
/// compartilham o mesmo enum; `readyForPickup` só é usado por pedidos de
/// retirada, `shipped` só por pedidos de entrega, e `delivered` é o estado
/// terminal dos dois ("Entregue" numa tela, "Retirado" na outra — ver
/// `OrderStatusLabels` na camada de apresentação, o enum em si é único).
enum OrderStatus {
  created,
  paymentPending,
  paid,
  preparing,
  readyForPickup,
  shipped,
  delivered,
  cancelled,
}

class OrderItem extends Equatable {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.thumbnail,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    this.personalizedName,
    this.personalizedNumber,
    this.personalizationSurcharge = 0,
  });

  final String productId;
  final String productName;
  final String thumbnail;
  final String size;
  final double unitPrice;
  final int quantity;
  final String? personalizedName;
  final int? personalizedNumber;
  final double personalizationSurcharge;

  double get lineTotal => (unitPrice + personalizationSurcharge) * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'thumbnail': thumbnail,
    'size': size,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'personalizedName': personalizedName,
    'personalizedNumber': personalizedNumber,
    'personalizationSurcharge': personalizationSurcharge,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    thumbnail: json['thumbnail'] as String,
    size: json['size'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'] as int,
    personalizedName: json['personalizedName'] as String?,
    personalizedNumber: json['personalizedNumber'] as int?,
    personalizationSurcharge:
        (json['personalizationSurcharge'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [
    productId,
    productName,
    thumbnail,
    size,
    unitPrice,
    quantity,
    personalizedName,
    personalizedNumber,
    personalizationSurcharge,
  ];
}

class StoreOrder extends Equatable {
  const StoreOrder({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.identification,
    required this.fulfillmentMethod,
    this.address,
    this.shippingOption,
    this.pickupInfo,
    this.pickupResponsible,
    required this.payment,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingCost,
    required this.couponCode,
    required this.status,
  });

  /// Código legível tipo `GOI-2026-000184` — nunca reaproveitado.
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final CustomerIdentification identification;

  final FulfillmentMethod fulfillmentMethod;
  final CustomerAddress? address;
  final ShippingOption? shippingOption;
  final PickupInformation? pickupInfo;
  final PickupResponsible? pickupResponsible;

  final PaymentSimulation payment;

  /// Congelados no momento da criação — um pedido nunca recalcula seus
  /// valores a partir do catálogo atual.
  final double subtotal;
  final double discountAmount;
  final double shippingCost;
  final String? couponCode;

  final OrderStatus status;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  double get personalizationTotal =>
      items.fold(0, (sum, i) => sum + i.personalizationSurcharge * i.quantity);
  double get total => subtotal - discountAmount + shippingCost;

  bool get isPickup => fulfillmentMethod == FulfillmentMethod.pickup;

  StoreOrder copyWith({OrderStatus? status}) => StoreOrder(
    id: id,
    createdAt: createdAt,
    items: items,
    identification: identification,
    fulfillmentMethod: fulfillmentMethod,
    address: address,
    shippingOption: shippingOption,
    pickupInfo: pickupInfo,
    pickupResponsible: pickupResponsible,
    payment: payment,
    subtotal: subtotal,
    discountAmount: discountAmount,
    shippingCost: shippingCost,
    couponCode: couponCode,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'identification': identification.toJson(),
    'fulfillmentMethod': fulfillmentMethod.name,
    'address': address?.toJson(),
    'shippingOption': shippingOption?.toJson(),
    'pickupResponsible': pickupResponsible?.toJson(),
    'payment': payment.toJson(),
    'subtotal': subtotal,
    'discountAmount': discountAmount,
    'shippingCost': shippingCost,
    'couponCode': couponCode,
    'status': status.name,
  };

  factory StoreOrder.fromJson(Map<String, dynamic> json) => StoreOrder(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: (json['items'] as List)
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    identification: CustomerIdentification.fromJson(
      json['identification'] as Map<String, dynamic>,
    ),
    fulfillmentMethod: FulfillmentMethod.values.byName(
      json['fulfillmentMethod'] as String,
    ),
    address: json['address'] != null
        ? CustomerAddress.fromJson(json['address'] as Map<String, dynamic>)
        : null,
    shippingOption: json['shippingOption'] != null
        ? ShippingOption.fromJson(
            json['shippingOption'] as Map<String, dynamic>,
          )
        : null,
    pickupInfo: json['fulfillmentMethod'] == 'pickup'
        ? const PickupInformation()
        : null,
    pickupResponsible: json['pickupResponsible'] != null
        ? PickupResponsible.fromJson(
            json['pickupResponsible'] as Map<String, dynamic>,
          )
        : null,
    payment: PaymentSimulation.fromJson(
      json['payment'] as Map<String, dynamic>,
    ),
    subtotal: (json['subtotal'] as num).toDouble(),
    discountAmount: (json['discountAmount'] as num).toDouble(),
    shippingCost: (json['shippingCost'] as num).toDouble(),
    couponCode: json['couponCode'] as String?,
    status: OrderStatus.values.byName(json['status'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    createdAt,
    items,
    identification,
    fulfillmentMethod,
    address,
    shippingOption,
    pickupInfo,
    pickupResponsible,
    payment,
    subtotal,
    discountAmount,
    shippingCost,
    couponCode,
    status,
  ];
}

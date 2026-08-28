import 'package:equatable/equatable.dart';

/// Uma linha do carrinho — congela nome/preço/miniatura do produto no
/// momento da adição, então o carrinho nunca muda sozinho se o catálogo
/// mudar depois (mesma ideia de um pedido: é uma fotografia, não uma
/// referência viva).
class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.thumbnail,
    required this.size,
    required this.unitPrice,
    this.quantity = 1,
    this.personalizedName,
    this.personalizedNumber,
    this.personalizationSurcharge = 0,
  });

  /// Id da linha, não do produto — o mesmo produto pode aparecer em mais de
  /// uma linha (tamanhos/personalizações diferentes).
  final String id;
  final String productId;
  final String productName;
  final String thumbnail;
  final String size;
  final double unitPrice;
  final int quantity;
  final String? personalizedName;
  final int? personalizedNumber;
  final double personalizationSurcharge;

  bool get isPersonalized =>
      personalizedName != null || personalizedNumber != null;

  double get lineTotal => (unitPrice + personalizationSurcharge) * quantity;

  CartItem copyWith({
    int? quantity,
    String? Function()? personalizedName,
    int? Function()? personalizedNumber,
    double? personalizationSurcharge,
  }) => CartItem(
    id: id,
    productId: productId,
    productName: productName,
    thumbnail: thumbnail,
    size: size,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    personalizedName: personalizedName != null
        ? personalizedName()
        : this.personalizedName,
    personalizedNumber: personalizedNumber != null
        ? personalizedNumber()
        : this.personalizedNumber,
    personalizationSurcharge:
        personalizationSurcharge ?? this.personalizationSurcharge,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
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

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
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
    id,
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

/// Cupom aplicado — só percentual e código, calculado por cima do
/// subtotal atual (nunca guarda o valor do desconto em reais, pra nunca
/// dessincronizar se os itens mudarem depois de aplicado).
class AppliedCoupon extends Equatable {
  const AppliedCoupon({required this.code, required this.discountPercent});

  final String code;
  final double discountPercent;

  Map<String, dynamic> toJson() => {
    'code': code,
    'discountPercent': discountPercent,
  };

  factory AppliedCoupon.fromJson(Map<String, dynamic> json) => AppliedCoupon(
    code: json['code'] as String,
    discountPercent: (json['discountPercent'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [code, discountPercent];
}

class Cart extends Equatable {
  const Cart({this.items = const [], this.coupon});

  final List<CartItem> items;
  final AppliedCoupon? coupon;

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  double get discountAmount =>
      coupon == null ? 0 : subtotal * coupon!.discountPercent / 100;
  double get totalAfterDiscount => subtotal - discountAmount;

  Cart copyWith({List<CartItem>? items, AppliedCoupon? Function()? coupon}) =>
      Cart(
        items: items ?? this.items,
        coupon: coupon != null ? coupon() : this.coupon,
      );

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'coupon': coupon?.toJson(),
  };

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    items: (json['items'] as List)
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    coupon: json['coupon'] != null
        ? AppliedCoupon.fromJson(json['coupon'] as Map<String, dynamic>)
        : null,
  );

  @override
  List<Object?> get props => [items, coupon];
}

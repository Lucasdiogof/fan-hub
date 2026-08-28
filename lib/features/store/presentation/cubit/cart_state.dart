import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/shared/state/load_status.dart';

class CartState extends Equatable {
  const CartState({
    this.status = LoadStatus.initial,
    this.cart = const Cart(),
    this.invalidCoupon = false,
    this.applyingCoupon = false,
  });

  final LoadStatus status;
  final Cart cart;

  /// `true` = o último código tentado não existe/expirou — some assim que
  /// um novo código é digitado ou um cupom válido é aplicado. Sem texto
  /// aqui de propósito (ver `StoreValidators`/`store_validators.dart`):
  /// quem traduz é a tela, com `context.l10n`.
  final bool invalidCoupon;
  final bool applyingCoupon;

  CartState copyWith({
    LoadStatus? status,
    Cart? cart,
    bool? invalidCoupon,
    bool? applyingCoupon,
  }) => CartState(
    status: status ?? this.status,
    cart: cart ?? this.cart,
    invalidCoupon: invalidCoupon ?? this.invalidCoupon,
    applyingCoupon: applyingCoupon ?? this.applyingCoupon,
  );

  @override
  List<Object?> get props => [status, cart, invalidCoupon, applyingCoupon];
}

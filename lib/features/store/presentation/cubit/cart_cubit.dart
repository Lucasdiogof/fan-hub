import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Singleton do app inteiro (ver `injection_container.dart`) — o carrinho
/// precisa sobreviver a navegação entre a loja, o detalhe do produto e o
/// checkout, igual ao `HomeShellCubit`. Persiste a cada mutação (nunca em
/// lote), então fechar o app no meio de uma alteração nunca perde nada.
class CartCubit extends Cubit<CartState> {
  CartCubit(this._repository) : super(const CartState());

  final StoreRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.loadCart();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: LoadStatus.success, cart: data));
      case Error():
        emit(state.copyWith(status: LoadStatus.error));
    }
  }

  Future<void> _persist(Cart cart) async {
    emit(state.copyWith(cart: cart));
    await _repository.saveCart(cart);
  }

  /// Junta com uma linha já existente (mesmo produto+tamanho+personalização)
  /// em vez de duplicar — mesma UX de qualquer carrinho de e-commerce.
  Future<void> addItem(CartItem item) async {
    final items = [...state.cart.items];
    final matchIndex = items.indexWhere(
      (i) =>
          i.productId == item.productId &&
          i.size == item.size &&
          i.personalizedName == item.personalizedName &&
          i.personalizedNumber == item.personalizedNumber,
    );
    if (matchIndex >= 0) {
      items[matchIndex] = items[matchIndex].copyWith(
        quantity: items[matchIndex].quantity + item.quantity,
      );
    } else {
      items.add(item);
    }
    await _persist(state.cart.copyWith(items: items));
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) return removeItem(itemId);
    final items = state.cart.items
        .map((i) => i.id == itemId ? i.copyWith(quantity: quantity) : i)
        .toList();
    await _persist(state.cart.copyWith(items: items));
  }

  Future<void> removeItem(String itemId) async {
    final items = state.cart.items.where((i) => i.id != itemId).toList();
    await _persist(state.cart.copyWith(items: items));
  }

  Future<void> clear() async {
    await _persist(const Cart());
  }

  Future<void> applyCoupon(String code) async {
    emit(state.copyWith(applyingCoupon: true, invalidCoupon: false));
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(applyingCoupon: false));
      return;
    }
    final result = await _repository.resolveCouponDiscountPercent(trimmed);
    final percent = switch (result) {
      Success(:final data) => data,
      Error() => null,
    };
    if (percent == null) {
      emit(state.copyWith(applyingCoupon: false, invalidCoupon: true));
      return;
    }
    emit(state.copyWith(applyingCoupon: false));
    await _persist(
      state.cart.copyWith(
        coupon: () => AppliedCoupon(
          code: trimmed.toUpperCase(),
          discountPercent: percent,
        ),
      ),
    );
  }

  Future<void> removeCoupon() async {
    await _persist(state.cart.copyWith(coupon: () => null));
  }
}

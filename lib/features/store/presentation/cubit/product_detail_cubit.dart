import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/product_detail_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(this._repository) : super(const ProductDetailState());

  final StoreRepository _repository;

  Future<void> load(String productId) async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final product = await _repository.getProductById(productId);
      final allProducts = await _repository.getProducts();
      final related = product.relatedProductIds
          .map((id) {
            for (final p in allProducts) {
              if (p.id == id) return p;
            }
            return null;
          })
          .whereType<StoreProduct>()
          .toList(growable: false);
      // Único tamanho → já vem selecionado, nunca obriga escolher o óbvio.
      final onlySize = product.variations.length == 1
          ? product.variations.first.size
          : null;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          product: product,
          relatedProducts: related,
          selectedSize: () => onlySize,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: LoadStatus.error));
    }
  }

  void selectSize(String size) => emit(
    state.copyWith(selectedSize: () => size, showSizeRequired: false),
  );

  /// Chamado quando o usuário toca em comprar/adicionar sem escolher tamanho —
  /// a tela usa isso pra rolar até e destacar a seção Tamanho.
  void requireSize() => emit(state.copyWith(showSizeRequired: true));

  void setQuantity(int quantity) =>
      emit(state.copyWith(quantity: quantity.clamp(1, 10)));

  void setPersonalizedName(String? name) {
    final trimmed = name?.trim();
    emit(
      state.copyWith(
        personalizedName: () =>
            (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      ),
    );
  }

  void setPersonalizedNumber(int? number) =>
      emit(state.copyWith(personalizedNumber: () => number));
}

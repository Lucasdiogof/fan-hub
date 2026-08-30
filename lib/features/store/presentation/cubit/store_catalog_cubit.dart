import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/store_catalog_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Home da loja — carrega o catálogo inteiro uma vez; as seções (lançamentos,
/// mantos, ofertas...) são todas derivadas do mesmo `products` (ver
/// `StoreCatalogState`), nunca buscadas separadamente.
class StoreCatalogCubit extends Cubit<StoreCatalogState> {
  StoreCatalogCubit(this._repository) : super(const StoreCatalogState());

  final StoreRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final productsResult = await _repository.getProducts();
    final categoriesResult = await _repository.getCategories();
    if (productsResult case Success(:final data)) {
      final products = data;
      if (categoriesResult case Success(:final data)) {
        emit(
          state.copyWith(
            status: products.isEmpty ? LoadStatus.empty : LoadStatus.success,
            products: products,
            categories: data,
          ),
        );
        return;
      }
    }
    emit(state.copyWith(status: LoadStatus.error));
  }
}

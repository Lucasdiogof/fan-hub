import 'package:flutter_bloc/flutter_bloc.dart';
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
    try {
      final products = await _repository.getProducts();
      final categories = await _repository.getCategories();
      emit(
        state.copyWith(
          status: products.isEmpty ? LoadStatus.empty : LoadStatus.success,
          products: products,
          categories: categories,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: LoadStatus.error));
    }
  }
}

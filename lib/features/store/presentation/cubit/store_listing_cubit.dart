import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_filters.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Uma listagem (categoria OU busca livre) — o catálogo inteiro carrega uma
/// vez e busca/filtro/ordenação são só um recorte em memória sobre ele
/// (ver `StoreListingState.visibleProducts`), sem round-trip novo a cada
/// tecla/filtro. O debounce da busca fica na tela (texto digitado só chama
/// [setQuery] depois de parar de digitar), não aqui.
class StoreListingCubit extends Cubit<StoreListingState> {
  StoreListingCubit(this._repository, {String? categoryId})
    : super(StoreListingState(categoryId: categoryId));

  final StoreRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final products = await _repository.getProducts();
    emit(state.copyWith(status: LoadStatus.success, allProducts: products));
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setSort(StoreSortOrder sort) => emit(state.copyWith(sort: sort));

  void setFilters(StoreListingFilters filters) =>
      emit(state.copyWith(filters: filters));

  void clearFilters() =>
      emit(state.copyWith(filters: const StoreListingFilters()));
}

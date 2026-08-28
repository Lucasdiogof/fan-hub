import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_filters.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';

class StoreListingState extends Equatable {
  const StoreListingState({
    this.status = LoadStatus.initial,
    this.allProducts = const [],
    this.categoryId,
    this.query = '',
    this.filters = const StoreListingFilters(),
    this.sort = StoreSortOrder.relevance,
  });

  final LoadStatus status;
  final List<StoreProduct> allProducts;

  /// Contexto fixo da tela (veio de um card de categoria) — `null` quando é
  /// uma busca livre ou "todos os produtos".
  final String? categoryId;
  final String query;
  final StoreListingFilters filters;
  final StoreSortOrder sort;

  List<StoreProduct> get visibleProducts {
    final result = allProducts.where((p) {
      if (categoryId != null &&
          !p.categoryIds.contains(categoryId) &&
          !p.collectionIds.contains(categoryId)) {
        return false;
      }
      if (query.isNotEmpty) {
        final needle = normalizeName(query);
        final haystack = normalizeName(
          '${p.name} ${p.brand} ${p.shortDescription}',
        );
        if (!haystack.contains(needle)) return false;
      }
      if (filters.audiences.isNotEmpty &&
          !filters.audiences.contains(p.audience.name)) {
        return false;
      }
      if (filters.types.isNotEmpty && !filters.types.contains(p.type.name)) {
        return false;
      }
      if (filters.uniformEditions.isNotEmpty &&
          !filters.uniformEditions.contains(p.uniformEdition)) {
        return false;
      }
      if (filters.sizes.isNotEmpty &&
          !p.variations.any(
            (v) => filters.sizes.contains(v.size) && v.inStock,
          )) {
        return false;
      }
      if (filters.minPrice != null && p.price < filters.minPrice!) return false;
      if (filters.maxPrice != null && p.price > filters.maxPrice!) return false;
      if (filters.onlyAvailable && !p.isAvailable) return false;
      if (filters.onlyOnSale && !p.isOnSale) return false;
      return true;
    }).toList();

    switch (sort) {
      case StoreSortOrder.relevance:
        break;
      case StoreSortOrder.newest:
        result.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
      case StoreSortOrder.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
      case StoreSortOrder.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
      case StoreSortOrder.biggestDiscount:
        result.sort(
          (a, b) => b.discountPercentage.compareTo(a.discountPercentage),
        );
    }
    return result;
  }

  StoreListingState copyWith({
    LoadStatus? status,
    List<StoreProduct>? allProducts,
    String? categoryId,
    String? query,
    StoreListingFilters? filters,
    StoreSortOrder? sort,
  }) => StoreListingState(
    status: status ?? this.status,
    allProducts: allProducts ?? this.allProducts,
    categoryId: categoryId ?? this.categoryId,
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => [
    status,
    allProducts,
    categoryId,
    query,
    filters,
    sort,
  ];
}

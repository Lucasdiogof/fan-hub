import 'package:equatable/equatable.dart';

enum StoreSortOrder {
  relevance,
  newest,
  priceLowToHigh,
  priceHighToLow,
  biggestDiscount,
}

/// Filtros ajustáveis pelo torcedor — separado de `categoryId` de propósito:
/// a categoria é o CONTEXTO da tela (veio de um card/menu), os filtros são
/// o que o usuário refina depois. "Limpar filtros" só zera isto, nunca a
/// categoria da tela.
class StoreListingFilters extends Equatable {
  const StoreListingFilters({
    this.audiences = const {},
    this.types = const {},
    this.uniformEditions = const {},
    this.sizes = const {},
    this.minPrice,
    this.maxPrice,
    this.onlyAvailable = false,
    this.onlyOnSale = false,
  });

  final Set<String> audiences;
  final Set<String> types;
  final Set<String> uniformEditions;
  final Set<String> sizes;
  final double? minPrice;
  final double? maxPrice;
  final bool onlyAvailable;
  final bool onlyOnSale;

  int get activeCount =>
      audiences.length +
      types.length +
      uniformEditions.length +
      sizes.length +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (onlyAvailable ? 1 : 0) +
      (onlyOnSale ? 1 : 0);

  bool get isEmpty => activeCount == 0;

  StoreListingFilters copyWith({
    Set<String>? audiences,
    Set<String>? types,
    Set<String>? uniformEditions,
    Set<String>? sizes,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    bool? onlyAvailable,
    bool? onlyOnSale,
  }) => StoreListingFilters(
    audiences: audiences ?? this.audiences,
    types: types ?? this.types,
    uniformEditions: uniformEditions ?? this.uniformEditions,
    sizes: sizes ?? this.sizes,
    minPrice: minPrice != null ? minPrice() : this.minPrice,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    onlyOnSale: onlyOnSale ?? this.onlyOnSale,
  );

  @override
  List<Object?> get props => [
    audiences,
    types,
    uniformEditions,
    sizes,
    minPrice,
    maxPrice,
    onlyAvailable,
    onlyOnSale,
  ];
}

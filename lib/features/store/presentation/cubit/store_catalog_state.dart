import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/store_category.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/shared/state/load_status.dart';

class StoreCatalogState extends Equatable {
  const StoreCatalogState({
    this.status = LoadStatus.initial,
    this.products = const [],
    this.categories = const [],
  });

  final LoadStatus status;
  final List<StoreProduct> products;
  final List<StoreCategory> categories;

  List<StoreCategory> get mainCategories =>
      categories.where((c) => !c.isCollection).toList();

  // Seções da Home da loja — sempre derivadas do catálogo carregado, nunca
  // uma lista própria guardada à parte (ver spec: "alimentadas pelos dados
  // mock, sem produtos hardcoded").
  List<StoreProduct> get launches => products.where((p) => p.isNew).toList();
  List<StoreProduct> get officialJerseys =>
      products.where((p) => p.type == ProductType.matchJersey).toList();

  /// Único produto personalizável do catálogo (hoje, o juvenil) — alimenta
  /// o card editorial "Personalize seu manto" da Home da loja.
  StoreProduct? get personalizableProduct {
    for (final product in products) {
      if (product.allowsPersonalization) return product;
    }
    return null;
  }

  StoreCatalogState copyWith({
    LoadStatus? status,
    List<StoreProduct>? products,
    List<StoreCategory>? categories,
  }) => StoreCatalogState(
    status: status ?? this.status,
    products: products ?? this.products,
    categories: categories ?? this.categories,
  );

  @override
  List<Object?> get props => [status, products, categories];
}

import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Por que [ProductDetailState.canAddToCart] está bloqueado — texto
/// nenhum aqui, só o motivo estrutural; quem traduz é a tela
/// (`ProductDetailPage`), com `context.l10n`.
enum ProductBlockReason { none, chooseSize, outOfStock }

class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = LoadStatus.initial,
    this.product,
    this.relatedProducts = const [],
    this.selectedSize,
    this.quantity = 1,
    this.personalizedName,
    this.personalizedNumber,
    this.showSizeRequired = false,
  });

  final LoadStatus status;
  final StoreProduct? product;
  final List<StoreProduct> relatedProducts;
  final String? selectedSize;
  final int quantity;
  final String? personalizedName;
  final int? personalizedNumber;

  /// Ligado quando o usuário tenta comprar/adicionar sem escolher o tamanho
  /// obrigatório — a UI destaca a seção Tamanho em vez de bloquear os botões.
  /// Desliga ao selecionar um tamanho.
  final bool showSizeRequired;

  bool get wantsPersonalization =>
      (personalizedName != null && personalizedName!.isNotEmpty) ||
      personalizedNumber != null;

  double get personalizationSurcharge {
    final p = product;
    if (p?.personalization == null) return 0;
    var total = 0.0;
    if (personalizedName != null && personalizedName!.isNotEmpty) {
      total += p!.personalization!.nameCost;
    }
    if (personalizedNumber != null) total += p!.personalization!.numberCost;
    return total;
  }

  double get unitPriceWithPersonalization =>
      (product?.price ?? 0) + personalizationSurcharge;

  ProductBlockReason get blockReason {
    final p = product;
    if (p == null) return ProductBlockReason.none;
    if (p.requiresSizeSelection && selectedSize == null) {
      return ProductBlockReason.chooseSize;
    }
    if (selectedSize != null) {
      final variation = p.variationForSize(selectedSize!);
      if (variation == null || !variation.inStock) {
        return ProductBlockReason.outOfStock;
      }
    }
    return ProductBlockReason.none;
  }

  bool get canAddToCart => blockReason == ProductBlockReason.none;

  ProductDetailState copyWith({
    LoadStatus? status,
    StoreProduct? product,
    List<StoreProduct>? relatedProducts,
    String? Function()? selectedSize,
    int? quantity,
    String? Function()? personalizedName,
    int? Function()? personalizedNumber,
    bool? showSizeRequired,
  }) => ProductDetailState(
    status: status ?? this.status,
    product: product ?? this.product,
    relatedProducts: relatedProducts ?? this.relatedProducts,
    selectedSize: selectedSize != null ? selectedSize() : this.selectedSize,
    quantity: quantity ?? this.quantity,
    personalizedName: personalizedName != null
        ? personalizedName()
        : this.personalizedName,
    personalizedNumber: personalizedNumber != null
        ? personalizedNumber()
        : this.personalizedNumber,
    showSizeRequired: showSizeRequired ?? this.showSizeRequired,
  );

  @override
  List<Object?> get props => [
    status,
    product,
    relatedProducts,
    selectedSize,
    quantity,
    personalizedName,
    personalizedNumber,
    showSizeRequired,
  ];
}

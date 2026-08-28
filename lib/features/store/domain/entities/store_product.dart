import 'package:equatable/equatable.dart';

enum StoreAudience { masculine, feminine, kids, unisex }

enum ProductType {
  matchJersey,
  goalkeeper,
  training,
  casual,
  accessory,
  souvenir,
}

/// Uma combinação vendável (tamanho + cor, quando houver) — cada uma com
/// seu próprio estoque. Nunca há "tamanhos disponíveis" solto no produto,
/// só a lista de variações; disponibilidade é sempre derivada daqui.
class ProductVariation extends Equatable {
  const ProductVariation({
    required this.sku,
    required this.size,
    this.colorLabel,
    required this.stock,
  });

  final String sku;
  final String size;
  final String? colorLabel;
  final int stock;

  bool get inStock => stock > 0;

  factory ProductVariation.fromJson(Map<String, dynamic> json) =>
      ProductVariation(
        sku: json['sku'] as String,
        size: json['size'] as String,
        colorLabel: json['colorLabel'] as String?,
        stock: json['stock'] as int,
      );

  @override
  List<Object?> get props => [sku, size, colorLabel, stock];
}

/// Regras de personalização (nome/número) do produto — `null` em
/// `StoreProduct.personalization` significa que o produto não aceita.
class ProductPersonalization extends Equatable {
  const ProductPersonalization({
    this.allowsName = false,
    this.allowsNumber = false,
    this.nameCost = 30.0,
    this.numberCost = 40.0,
    this.maxNameLength = 12,
    this.minNumber = 0,
    this.maxNumber = 99,
  });

  final bool allowsName;
  final bool allowsNumber;
  final double nameCost;
  final double numberCost;
  final int maxNameLength;
  final int minNumber;
  final int maxNumber;

  factory ProductPersonalization.fromJson(Map<String, dynamic> json) =>
      ProductPersonalization(
        allowsName: json['allowsName'] as bool? ?? false,
        allowsNumber: json['allowsNumber'] as bool? ?? false,
        nameCost: (json['nameCost'] as num?)?.toDouble() ?? 30.0,
        numberCost: (json['numberCost'] as num?)?.toDouble() ?? 40.0,
        maxNameLength: json['maxNameLength'] as int? ?? 12,
        minNumber: json['minNumber'] as int? ?? 0,
        maxNumber: json['maxNumber'] as int? ?? 99,
      );

  @override
  List<Object?> get props => [
    allowsName,
    allowsNumber,
    nameCost,
    numberCost,
    maxNameLength,
    minNumber,
    maxNumber,
  ];
}

class ProductSpecification extends Equatable {
  const ProductSpecification({required this.label, required this.value});

  final String label;
  final String value;

  factory ProductSpecification.fromJson(Map<String, dynamic> json) =>
      ProductSpecification(
        label: json['label'] as String,
        value: json['value'] as String,
      );

  @override
  List<Object?> get props => [label, value];
}

class StoreProduct extends Equatable {
  const StoreProduct({
    required this.id,
    required this.slug,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.brand,
    required this.reference,
    required this.categoryIds,
    required this.collectionIds,
    required this.audience,
    required this.type,
    this.uniformEdition,
    required this.price,
    this.originalPrice,
    this.maxInstallments = 1,
    required this.images,
    required this.thumbnail,
    required this.variations,
    this.isFeatured = false,
    this.isNew = false,
    this.personalization,
    this.relatedProductIds = const [],
    this.specifications = const [],
    this.sourceUrl,
  });

  final String id;
  final String slug;
  final String name;
  final String shortDescription;
  final String description;
  final String brand;
  final String reference;

  final List<String> categoryIds;
  final List<String> collectionIds;
  final StoreAudience audience;
  final ProductType type;

  /// Qual uniforme (01/02/03) — `null` pra itens que não são um dos kits
  /// numerados (acessório, souvenir, treino).
  final String? uniformEdition;

  final double price;

  /// Preço "de" — quando presente e maior que [price], o produto está em
  /// promoção. Nunca guarde o percentual: [discountPercentage] é derivado.
  final double? originalPrice;

  final int maxInstallments;

  final List<String> images;
  final String thumbnail;
  final List<ProductVariation> variations;

  final bool isFeatured;
  final bool isNew;

  final ProductPersonalization? personalization;
  final List<String> relatedProductIds;
  final List<ProductSpecification> specifications;
  final String? sourceUrl;

  bool get allowsPersonalization => personalization != null;

  bool get isOnSale => originalPrice != null && originalPrice! > price;

  int get discountPercentage {
    if (!isOnSale) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  bool get isAvailable => variations.any((v) => v.inStock);

  bool get requiresSizeSelection =>
      variations.map((v) => v.size).toSet().length > 1 ||
      (variations.length == 1 && variations.first.size != 'ÚNICO');

  List<String> get availableSizes => variations
      .where((v) => v.inStock)
      .map((v) => v.size)
      .toSet()
      .toList(growable: false);

  ProductVariation? variationForSize(String size) {
    for (final v in variations) {
      if (v.size == size) return v;
    }
    return null;
  }

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    shortDescription: json['shortDescription'] as String,
    description: json['description'] as String,
    brand: json['brand'] as String,
    reference: json['reference'] as String,
    categoryIds: (json['categories'] as List).cast<String>(),
    collectionIds: (json['collections'] as List? ?? const []).cast<String>(),
    audience: StoreAudience.values.byName(json['audience'] as String),
    type: ProductType.values.byName(json['productType'] as String),
    uniformEdition: json['uniformNumber'] as String?,
    price: (json['price'] as num).toDouble(),
    originalPrice: (json['originalPrice'] as num?)?.toDouble(),
    maxInstallments: json['installments'] as int? ?? 1,
    images: (json['images'] as List).cast<String>(),
    thumbnail: json['thumbnail'] as String,
    variations: (json['variations'] as List)
        .map((e) => ProductVariation.fromJson(e as Map<String, dynamic>))
        .toList(),
    isFeatured: json['isFeatured'] as bool? ?? false,
    isNew: json['isNew'] as bool? ?? false,
    personalization: json['personalizationOptions'] != null
        ? ProductPersonalization.fromJson(
            json['personalizationOptions'] as Map<String, dynamic>,
          )
        : null,
    relatedProductIds: (json['relatedProductIds'] as List? ?? const [])
        .cast<String>(),
    specifications: (json['specifications'] as List? ?? const [])
        .map((e) => ProductSpecification.fromJson(e as Map<String, dynamic>))
        .toList(),
    sourceUrl: json['sourceUrl'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    shortDescription,
    description,
    brand,
    reference,
    categoryIds,
    collectionIds,
    audience,
    type,
    uniformEdition,
    price,
    originalPrice,
    maxInstallments,
    images,
    thumbnail,
    variations,
    isFeatured,
    isNew,
    personalization,
    relatedProductIds,
    specifications,
    sourceUrl,
  ];
}

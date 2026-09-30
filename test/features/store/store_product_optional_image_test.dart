import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';

/// F7 (2026-09-30): `images`/`thumbnail` viraram opcionais — um produto de
/// pacote parcial (Vila Nova, 12/125 sem foto capturada) precisa continuar
/// representável sem inventar URL de imagem nenhuma. Ver
/// `ProductImagePlaceholder`/`product_card.dart`/`product_detail_page.dart`
/// pra onde a UI trata `null`/vazio.
void main() {
  StoreProduct baseProduct({List<String>? images, String? thumbnail}) =>
      StoreProduct(
        id: 'p1',
        slug: 'produto-1',
        name: 'Produto 1',
        shortDescription: '',
        description: '',
        brand: '',
        reference: 'REF1',
        categoryIds: const [],
        collectionIds: const [],
        audience: StoreAudience.unisex,
        type: ProductType.accessory,
        price: 10,
        images: images ?? const [],
        thumbnail: thumbnail,
        variations: const [],
      );

  group('StoreProduct — imagem/thumbnail opcionais', () {
    test('produto SEM foto: thumbnail null, images vazio — não lança', () {
      final product = baseProduct();
      expect(product.thumbnail, isNull);
      expect(product.images, isEmpty);
    });

    test('produto COM foto: thumbnail/images preservados normalmente', () {
      final product = baseProduct(
        images: const ['assets/store/goias/p1_0.png'],
        thumbnail: 'assets/store/goias/p1_thumb.png',
      );
      expect(product.thumbnail, 'assets/store/goias/p1_thumb.png');
      expect(product.images, ['assets/store/goias/p1_0.png']);
    });

    test('fromJson tolera "images"/"thumbnail" ausentes no JSON', () {
      final product = StoreProduct.fromJson({
        'id': 'p1',
        'slug': 'produto-1',
        'name': 'Produto 1',
        'shortDescription': '',
        'description': '',
        'brand': '',
        'reference': 'REF1',
        'categories': <String>[],
        'audience': 'unisex',
        'productType': 'accessory',
        'price': 10,
        'variations': <Map<String, dynamic>>[],
        // 'images' e 'thumbnail' propositalmente ausentes.
      });
      expect(product.images, isEmpty);
      expect(product.thumbnail, isNull);
    });

    test('fromJson preserva "images"/"thumbnail" quando presentes', () {
      final product = StoreProduct.fromJson({
        'id': 'p1',
        'slug': 'produto-1',
        'name': 'Produto 1',
        'shortDescription': '',
        'description': '',
        'brand': '',
        'reference': 'REF1',
        'categories': <String>[],
        'audience': 'unisex',
        'productType': 'accessory',
        'price': 10,
        'variations': <Map<String, dynamic>>[],
        'images': ['a.png'],
        'thumbnail': 'thumb.png',
      });
      expect(product.images, ['a.png']);
      expect(product.thumbnail, 'thumb.png');
    });
  });
}

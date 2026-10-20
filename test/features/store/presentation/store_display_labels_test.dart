import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/presentation/store_display_labels.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/l10n/app_localizations_en.dart';
import 'package:goias_app/l10n/app_localizations_es.dart';
import 'package:goias_app/l10n/app_localizations_pt.dart';

const _knownIds = [
  'launches',
  'uniforms',
  'masculine',
  'feminine',
  'kids',
  'training',
  'personalizable',
  'accessories',
  'souvenirs',
  'kit_01',
  'kit_02',
  'kit_03',
  'goalkeeper',
  'fan',
  'player',
  'casual',
  'training_travel',
  'socks_gloves',
];

void main() {
  final locales = <String, AppLocalizations>{
    'pt': AppLocalizationsPt(),
    'en': AppLocalizationsEn(),
    'es': AppLocalizationsEs(),
  };

  group('categoryDisplayName', () {
    for (final entry in locales.entries) {
      test('todo id conhecido tem texto traduzido em ${entry.key}', () {
        for (final id in _knownIds) {
          final text = categoryDisplayName(entry.value, id);
          expect(text.trim(), isNotEmpty, reason: id);
          expect(
            text,
            isNot(id),
            reason: '$id caiu no fallback em ${entry.key}',
          );
        }
      });
    }

    test('id desconhecido volta como veio (nunca quebra a tela)', () {
      expect(
        categoryDisplayName(locales['pt']!, 'novidade_2027'),
        'novidade_2027',
      );
    });

    test('o texto muda de idioma', () {
      expect(
        categoryDisplayName(locales['pt']!, 'kids'),
        isNot(categoryDisplayName(locales['en']!, 'kids')),
      );
    });
  });

  group('enums viram texto nos 3 idiomas', () {
    for (final entry in locales.entries) {
      final l10n = entry.value;
      test('público, tipo e frete em ${entry.key}', () {
        final labels = <String>[
          for (final a in StoreAudience.values) audienceDisplayName(l10n, a),
          for (final t in ProductType.values) productTypeDisplayName(l10n, t),
          for (final s in ShippingSpeed.values) shippingSpeedLabel(l10n, s),
          for (final s in ShippingSpeed.values) shippingEtaLabel(l10n, s),
        ];
        expect(labels, everyElement(isNotEmpty));
      });

      test(
        'os rótulos de frete são distintos entre as velocidades em ${entry.key}',
        () {
          final labels = {
            for (final s in ShippingSpeed.values) shippingSpeedLabel(l10n, s),
          };
          expect(labels, hasLength(ShippingSpeed.values.length));
          final etas = {
            for (final s in ShippingSpeed.values) shippingEtaLabel(l10n, s),
          };
          expect(etas, hasLength(ShippingSpeed.values.length));
        },
      );
    }

    test('cada tipo de produto tem rótulo próprio', () {
      final l10n = locales['pt']!;
      final labels = {
        for (final t in ProductType.values) productTypeDisplayName(l10n, t),
      };
      expect(labels, hasLength(ProductType.values.length));
    });
  });
}

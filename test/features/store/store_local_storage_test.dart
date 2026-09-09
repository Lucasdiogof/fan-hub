import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/store/data/store_local_storage.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/club/synthetic_club_config.dart';

const _legacyKey = 'store_cart';
const _valueA =
    '{"items":[{"id":"a","productId":"pa","productName":"A","thumbnail":"a.jpg","size":"M","unitPrice":10.0,"quantity":1,"personalizedName":null,"personalizedNumber":null,"personalizationSurcharge":0.0}],"coupon":null}';
const _valueB =
    '{"items":[{"id":"b","productId":"pb","productName":"B","thumbnail":"b.jpg","size":"G","unitPrice":20.0,"quantity":2,"personalizedName":null,"personalizedNumber":null,"personalizationSurcharge":0.0}],"coupon":null}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'StoreLocalStorage — matriz de club scope real (SharedPreferences de verdade)',
    () {
      test(
        'Goiás — legacy sem namespace migra: lê valor A e grava goias:store_cart',
        () async {
          SharedPreferences.setMockInitialValues({_legacyKey: _valueA});
          final prefs = await SharedPreferences.getInstance();
          final storage = StoreLocalStorage(goiasClubConfig);

          final cart = await storage.loadCart();

          expect(cart?.items.single.id, 'a');
          expect(prefs.getString('goias:$_legacyKey'), _valueA);
        },
      );

      test(
        'Goiás — namespaced já existente vence, nunca sobrescrito pela legacy',
        () async {
          SharedPreferences.setMockInitialValues({
            _legacyKey: _valueA,
            'goias:$_legacyKey': _valueB,
          });
          final prefs = await SharedPreferences.getInstance();
          final storage = StoreLocalStorage(goiasClubConfig);

          final cart = await storage.loadCart();

          expect(cart?.items.single.id, 'b');
          // A legacy nunca é tocada quando o namespaced já existe.
          expect(prefs.getString(_legacyKey), _valueA);
        },
      );

      test('club-b — NUNCA lê a chave legacy do Goiás (isolamento)', () async {
        SharedPreferences.setMockInitialValues({_legacyKey: _valueA});
        final prefs = await SharedPreferences.getInstance();
        final storage = StoreLocalStorage(syntheticClubBConfig);

        final cart = await storage.loadCart();

        expect(cart, isNull);
        // E nunca migra/cria uma chave namespaçada com o dado do Goiás.
        expect(prefs.getString('club-b:$_legacyKey'), isNull);
      });

      test(
        'club-b — lê o próprio valor namespaçado, mesmo com a legacy do Goiás presente',
        () async {
          SharedPreferences.setMockInitialValues({
            _legacyKey: _valueA,
            'club-b:$_legacyKey': _valueB,
          });
          final storage = StoreLocalStorage(syntheticClubBConfig);

          final cart = await storage.loadCart();

          expect(cart?.items.single.id, 'b');
        },
      );

      test(
        'saveCart grava sempre na chave namespaçada, nunca na legacy',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final storage = StoreLocalStorage(goiasClubConfig);

          await storage.saveCart(
            const Cart(
              items: [
                CartItem(
                  id: 'z',
                  productId: 'pz',
                  productName: 'Z',
                  thumbnail: 't.jpg',
                  size: 'M',
                  unitPrice: 5,
                ),
              ],
            ),
          );

          expect(prefs.getString('goias:$_legacyKey'), isNotNull);
          expect(prefs.getString(_legacyKey), isNull);
        },
      );
    },
  );
}

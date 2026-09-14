// Carousel do banner de topo da Loja — genérico por quantidade de itens
// em `banners` (nunca `if (club == ...)`, ver ClubAssets.storeHomeBanners).
// 1 item = banner fixo, sem PageView/Timer/dots (comportamento idêntico ao
// banner único de sempre do Goiás); >1 = carousel com autoplay de 5s.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/store/presentation/widgets/store_banner_carousel.dart';

const _bragantinoBanners = [
  'lib/assets/store/banners/bragantino/banner_1.png',
  'lib/assets/store/banners/bragantino/banner_2.png',
  'lib/assets/store/banners/bragantino/banner_3.png',
];

double _dotWidth(WidgetTester tester, int index) {
  final container = tester.widget<Container>(
    find.byKey(ValueKey('store_banner_dot_$index')),
  );
  return container.constraints!.maxWidth;
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
  // Deixa o Image.asset decodificar antes de qualquer hit-test/asserção —
  // sem isso a imagem ainda está em tamanho zero neste primeiro frame.
  await tester.pump();
}

/// Um ciclo de autoplay: o tick do Timer aos 5s + a duração da animação de
/// troca de página, em dois pumps separados (funciona; um único pump
/// combinando os dois tempos não dispara a animação corretamente aqui).
Future<void> _advanceOneAutoplayCycle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  group('0 banners', () {
    testWidgets('não renderiza nada', (tester) async {
      await _pump(tester, const StoreBannerCarousel(banners: []));

      expect(find.byType(Image), findsNothing);
      expect(find.byType(PageView), findsNothing);
    });
  });

  group('1 banner — fixo, sem carousel', () {
    testWidgets('renderiza a imagem única, sem PageView e sem dots', (
      tester,
    ) async {
      await _pump(
        tester,
        const StoreBannerCarousel(
          banners: ['lib/assets/store/banners/goias/goias_store.png'],
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(const ValueKey('store_banner_dot_0')), findsNothing);
    });

    testWidgets('toque aciona onTap', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        // Altura explícita: em teste o Image.asset ainda não decodificou
        // (por isso não tem altura própria) no momento do tap — em
        // produção a imagem real sempre define a própria altura antes de
        // qualquer toque possível.
        SizedBox(
          height: 200,
          child: StoreBannerCarousel(
            banners: const ['lib/assets/store/banners/goias/goias_store.png'],
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets(
      'não cria Timer — esperar 5s+ não gera exception nem muda nada',
      (tester) async {
        await _pump(
          tester,
          const StoreBannerCarousel(
            banners: ['lib/assets/store/banners/goias/goias_store.png'],
          ),
        );

        await tester.pump(const Duration(seconds: 6));

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('3 banners — carousel + dots', () {
    testWidgets('renderiza PageView e exatamente 3 dots', (tester) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byKey(const ValueKey('store_banner_dot_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_banner_dot_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_banner_dot_2')), findsOneWidget);
    });

    testWidgets('dot 0 começa ativo (mais largo que os outros)', (
      tester,
    ) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      expect(_dotWidth(tester, 0), 18);
      expect(_dotWidth(tester, 1), 6);
      expect(_dotWidth(tester, 2), 6);
    });

    testWidgets('swipe manual muda o dot ativo', (tester) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      expect(_dotWidth(tester, 0), 6);
      expect(_dotWidth(tester, 1), 18);
    });

    testWidgets('autoplay avança pra próxima página após 5s', (tester) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      expect(_dotWidth(tester, 0), 18);

      await _advanceOneAutoplayCycle(tester);

      expect(_dotWidth(tester, 1), 18);
    });

    testWidgets('do último slide, autoplay volta pro primeiro', (tester) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      // 2 ciclos de autoplay: 0 -> 1 -> 2 (último).
      await _advanceOneAutoplayCycle(tester);
      await _advanceOneAutoplayCycle(tester);
      expect(_dotWidth(tester, 2), 18);

      // 3º ciclo: 2 -> volta pro 0.
      await _advanceOneAutoplayCycle(tester);
      expect(_dotWidth(tester, 0), 18);
    });

    testWidgets(
      'após swipe manual, autoplay continua a partir da página atual',
      (tester) async {
        await _pump(
          tester,
          const StoreBannerCarousel(banners: _bragantinoBanners),
        );

        await tester.drag(find.byType(PageView), const Offset(-800, 0));
        await tester.pumpAndSettle();
        expect(_dotWidth(tester, 1), 18);

        await _advanceOneAutoplayCycle(tester);
        expect(_dotWidth(tester, 2), 18);
      },
    );

    testWidgets('dispose cancela o Timer — sem exception depois de sair', (
      tester,
    ) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      // Desmonta o carousel (troca a árvore inteira).
      await tester.pumpWidget(const SizedBox());

      // Se o Timer não tivesse sido cancelado, este tick chamaria
      // animateToPage num PageController já destruído.
      await tester.pump(const Duration(seconds: 6));

      expect(tester.takeException(), isNull);
    });

    testWidgets('sair e voltar pra Loja reinicia no primeiro slide', (
      tester,
    ) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(_dotWidth(tester, 1), 18);

      // "Sai da Loja" (desmonta) e "volta" (widget novo, mesmo tipo).
      await tester.pumpWidget(const SizedBox());
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      expect(_dotWidth(tester, 0), 18);
    });
  });

  group('lista muda em runtime', () {
    testWidgets('de 1 pra 3 banners: some o fixo, aparece o carousel', (
      tester,
    ) async {
      await _pump(
        tester,
        const StoreBannerCarousel(
          banners: ['lib/assets/store/banners/goias/goias_store.png'],
        ),
      );
      expect(find.byType(PageView), findsNothing);

      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );
      expect(find.byType(PageView), findsOneWidget);
      expect(_dotWidth(tester, 0), 18);

      // Não deixou timer velho vivo gerando exception.
      await tester.pump(const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('de 3 pra 1 banner: some o carousel/dots, sem exception', (
      tester,
    ) async {
      await _pump(
        tester,
        const StoreBannerCarousel(banners: _bragantinoBanners),
      );

      await _pump(
        tester,
        const StoreBannerCarousel(
          banners: ['lib/assets/store/banners/goias/goias_store.png'],
        ),
      );

      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(const ValueKey('store_banner_dot_0')), findsNothing);

      await tester.pump(const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
    });
  });
}

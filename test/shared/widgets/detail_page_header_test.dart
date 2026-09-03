import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';

Widget _harness({VoidCallback? onBack}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: DetailPageHeader(
        title: 'Nossa Gente',
        onBack: onBack,
        heroTitle: const SizedBox(
          height: 500,
          child: Align(
            alignment: Alignment.topLeft,
            child: Text('NOSSA GENTE', style: TextStyle(fontSize: 26)),
          ),
        ),
        body: Column(
          children: List.generate(
            20,
            (i) => SizedBox(height: 60, child: Text('item $i')),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('at the top, the back button shows but the bar title does not', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(opacity.opacity, 0);
  });

  testWidgets(
    'once the hero title scrolls away, the bar title fades in',
    (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 1);
      expect(find.text('Nossa Gente'), findsOneWidget);
    },
  );

  testWidgets('scrolling back to the top hides the bar title again', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 800));
    await tester.pumpAndSettle();

    final opacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(opacity.opacity, 0);
  });

  testWidgets('the back button calls onBack', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_harness(onBack: () => tapped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(tapped, isTrue);
  });
}

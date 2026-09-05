import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/shared/widgets/demo_disclaimer_banner.dart';

void main() {
  testWidgets('renderiza título e corpo recebidos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: DemoDisclaimerBanner(
            title: 'Demonstração',
            body: 'Esta compra é simulada. Nenhuma cobrança será realizada.',
          ),
        ),
      ),
    );

    expect(find.text('Demonstração'), findsOneWidget);
    expect(
      find.text('Esta compra é simulada. Nenhuma cobrança será realizada.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
  });
}

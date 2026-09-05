import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/shared/widgets/demo_tag.dart';

void main() {
  testWidgets('renderiza o label em maiúsculas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: DemoTag(label: 'Ingresso demonstrativo')),
      ),
    );

    expect(find.text('INGRESSO DEMONSTRATIVO'), findsOneWidget);
  });

  testWidgets('onDark muda a cor do texto pra branco', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: DemoTag(label: 'Demonstração', onDark: true),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('DEMONSTRAÇÃO'));
    expect(text.style?.color, Colors.white);
  });
}
